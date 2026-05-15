---
name: nbl.java-spring-integration-testing
description: Use when writing Java Spring Boot integration tests that perform real database CRUD operations with MockMvc and MyBatis-Plus
---

# nbl.java-spring-integration-testing

## Overview

> **背景**：管理功能（如部门、用户、角色、配置等）的核心是 CRUD 操作。这些功能的特殊性在于：
> - **多表关联**：主表 + 多种关联关系表（人员关系、业务关系等）
> - **数据持久化**：需要验证数据真正写入数据库，而不仅是 HTTP 响应
> - **回归风险高**：修改后需要确保已有功能不受影响
>
> 本 skill 提供一套经过验证的集成测试模式，覆盖以上场景。

使用 `BaseIntegrationTest` 作为测试基类，执行真实数据库 CRUD 操作，测试结束后自动回滚保证幂等性。

核心特点：
- **真实写库**：在真实数据库执行 CRUD，不使用 Mock
- **自动回滚**：`@Transactional` 保证测试结束后数据自动回滚
- **字段级验证**：新增操作验证所有必填字段都正确写入数据库
- **直接查询验证**：使用项目的 Mapper 直接查询数据库验证
- **多表关联验证**：主表和关联关系表都需要验证

## When to Use

Use when:
- 编写管理功能的 CRUD 集成测试（部门、用户、角色、配置等）
- 需要验证数据库写入操作正确性（包括主表 + 关联表）
- 确保管理功能的增删改查正常工作
- 希望测试可重复运行（幂等性）

When NOT to Use:
- 单元测试（只测单个方法逻辑）→ use nbl.test-driven-development
- 纯 Service 层单元测试 → use nbl.test-driven-development

## Core Technique

### 继承 BaseIntegrationTest

```java
class FormControllerTest extends BaseIntegrationTest {

    @Autowired
    private FormMapper formMapper;
```

`BaseIntegrationTest` 提供：
- `@SpringBootTest` + `@AutoConfigureMockMvc` + `@Transactional`
- `mockMvc` - 已注入，可直接使用
- `objectMapper` - 已注入，可直接使用
- `parseData(json, Class)` - 解析响应 data 字段为对象
- `parseDataAsLong(json)` - 解析响应 data 字段为 Long
- `TEST_TENANT_ID` / `OPERATOR_ID` - 测试用常量

### 测试数据常量

项目应提供 `BaseIntegrationTest` 基类，包含：
```java
protected static final Long TEST_TENANT_ID = 1L;
protected static final Long OPERATOR_ID = 1L;
```

## Complete CRUD Example

```java
class FormControllerTest extends BaseIntegrationTest {

    @Autowired
    private FormMapper formMapper;

    @Test
    void testCRUD() throws Exception {
        String formName = "TestForm-" + System.currentTimeMillis();
        String formKey = "FormKey_" + System.currentTimeMillis();

        // ========== 1. Create ==========
        Long formId = createForm(formName, formKey);
        assertNotNull(formId, "创建表单后应返回ID");

        // 验证主表字段
        Form form = formMapper.selectById(formId);
        assertNotNull(form, "表单创建后应存在于数据库");
        assertEquals(createdName, form.getFormName());
        assertEquals(TEST_TENANT_ID, form.getTenantId());
        assertEquals(OPERATOR_ID, form.getCreatedBy());

        // ========== 2. GetById ==========
        FormDetailResp detailResp = getFormById(formId);
        assertNotNull(detailResp);
        assertEquals(formId, detailResp.getId());

        // ========== 3. Update ==========
        String updatedName = "UpdatedForm-" + System.currentTimeMillis();
        updateForm(formId, updatedName);

        // 验证主表更新
        Form updated = formMapper.selectById(formId);
        assertEquals(updatedName, updated.getFormName());
        assertEquals(OPERATOR_ID, updated.getUpdatedBy());
    }

    // ==================== 辅助方法 ====================

    private Long createForm(String formName, String formKey) throws Exception {
        FormInsertReq insertReq = new FormInsertReq();
        insertReq.setFormName(formName);
        insertReq.setFormKey(formKey);
        insertReq.setBusinessTypeCode("LEAVE");
        insertReq.setTenantId(TEST_TENANT_ID);
        insertReq.setOperatorId(OPERATOR_ID);

        MvcResult result = performPost("/forms/insert", insertReq).andReturn();
        return parseDataAsLong(result.getResponse().getContentAsString());
    }

    private FormDetailResp getFormById(Long id) throws Exception {
        MvcResult result = mockMvc.perform(get("/forms/get-by-id")
                        .param("id", id.toString())
                        .param("tenantId", TEST_TENANT_ID.toString()))
                .andExpect(status().isOk())
                .andReturn();

        return parseData(result.getResponse().getContentAsString(), FormDetailResp.class);
    }

    private void updateForm(Long id, String updatedName) throws Exception {
        FormUpdateReq updateReq = new FormUpdateReq();
        updateReq.setId(id);
        updateReq.setFormName(updatedName);
        updateReq.setBusinessTypeCode("LEAVE");
        updateReq.setTenantId(TEST_TENANT_ID);
        updateReq.setOperatorId(OPERATOR_ID);

        performPost("/forms/update", updateReq);
    }

    private ResultActions performPost(String url, Object req) throws Exception {
        return mockMvc.perform(post(url)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isOk());
    }
}
```

## Key Principles

| 原则 | 说明 |
|------|------|
| **真实写库** | 不 Mock 数据层，真正写入数据库验证 |
| **自动回滚** | `@Transactional` 保证测试结束数据回滚 |
| **DB 验证** | 通过项目的 Mapper 直接查询数据库验证状态 |
| **继承基类** | 继承 `BaseIntegrationTest` 获取通用能力 |
| **时间戳命名** | `System.currentTimeMillis()` 避免数据冲突 |
| **幂等性** | 可重复运行多次，结果一致 |

## BaseIntegrationTest 参考实现

项目应提供类似以下基类：

```java
@SpringBootTest(
    classes = Application.class,
    webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT,
    properties = {
        "app.id=20005",
        "apollo.meta=http://172.20.0.138:38080",
        "apollo.bootstrap.enabled=true",
        "apollo.bootstrap.namespaces=application,GUOGUOTECH.APPLICATION2",
        "spring.application.name=xxx",
        "spring.cloud.bootstrap.enabled=true"
    }
)
@AutoConfigureMockMvc
@Transactional
public abstract class BaseIntegrationTest {

    protected static final Long TEST_TENANT_ID = 1L;
    protected static final Long OPERATOR_ID = 1L;

    @Autowired
    protected MockMvc mockMvc;

    @Autowired
    protected ObjectMapper objectMapper;

    protected <T> T parseData(String json, Class<T> clazz) throws Exception {
        JsonNode root = objectMapper.readTree(json);
        return objectMapper.readValue(root.get("data").toString(), clazz);
    }

    protected Long parseDataAsLong(String json) throws Exception {
        JsonNode root = objectMapper.readTree(json);
        return root.get("data").asLong();
    }
}
```

## Common Notes

### 事务回滚保证幂等性

- 所有写库操作都会在测试结束后自动回滚
- 测试不会污染数据库，可重复运行

### 查询不受 Controller 事务影响

- 使用 Mapper 直接查询，不走 Controller 事务
- 总能读取到最新提交的数据，验证准确

### 逻辑删除验证

- MyBatis-Plus 自动过滤 `is_deleted=1` 的记录
- 验证删除：`assertNull(mapper.selectById(id))`

### 多表验证

- 不仅验证主表，还要验证所有关联表（关系表）
- 创建、更新、删除都需要验证关联表变化

### 新增操作字段验证

- **必须验证所有必填字段**写入数据库后值正确
- 不能只验证 HTTP 状态码，必须通过数据库查询验证每个字段

## Common Mistakes

❌ **错误：不验证数据库，只依赖 HTTP 响应**

```java
// 只验证 status 200，不验证数据库状态 -> 不完整
mockMvc.perform(...).andExpect(status().isOk());
```

✅ **正确：验证 HTTP 状态，再查数据库验证真实状态**

```java
mockMvc.perform(...).andExpect(status().isOk());
Form form = formMapper.selectById(formId);
assertNotNull(form);
assertEquals(expectedName, form.getFormName());
```

❌ **错误：每次测试手动清理数据**

```java
// 不需要手动删除，@Transactional 自动回滚
@AfterEach
void cleanup() {
    formMapper.deleteById(formId);
}
```

✅ **正确：依赖 @Transactional 自动回滚**

```java
class FormControllerTest extends BaseIntegrationTest { ... }
```

❌ **错误：使用 @WebMvcTest + Mock Repository**

```java
@WebMvcTest(UserController.class)  // 只加载 Web 层
class UserControllerTest {
    @MockBean
    private UserRepository repository;  // Mock 不执行真实写库
}
```

✅ **正确：继承 BaseIntegrationTest 启动完整上下文**

```java
@SpringBootTest(...)
@AutoConfigureMockMvc
@Transactional
class UserControllerTest extends BaseIntegrationTest {
    @Autowired
    private UserRepository repository;  // 真实 Repository，真实写库
}
```

## Imports 参考

```java
import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;
import org.springframework.test.web.servlet.ResultActions;
import com.fasterxml.jackson.databind.ObjectMapper;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;
import static org.junit.jupiter.api.Assertions.*;
```