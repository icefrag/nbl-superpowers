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

使用 `@SpringBootTest` + `@AutoConfigureMockMvc` + `@Transactional` 组合执行真实数据库 CRUD 操作，测试结束后自动回滚保证幂等性。

核心特点：
- **真实写库**：在真实数据库执行 CRUD，不使用 Mock
- **自动回滚**：`@Transactional` 保证测试结束后数据自动回滚
- **字段级验证**：新增操作验证所有必填字段都正确写入数据库，每个字段值都需要断言
- **直接查询验证**：使用项目的 Mapper（如 MyBatis-Plus、TKMapper 等）直接查询数据库验证
- **多表关联验证**：主表和关联关系表都需要验证
- **一个方法完成 CRUD**：Create-Read-Update-Delete 在一个测试方法中完成

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

### 类注解

```java
@SpringBootTest
@AutoConfigureMockMvc
@Transactional
class DepartmentControllerTest {
```

| 注解 | 作用 |
|------|------|
| `@SpringBootTest` | 启动完整 Spring 上下文 |
| `@AutoConfigureMockMvc` | 自动配置 MockMvc |
| `@Transactional` | 测试结束后自动回滚事务 |

### 依赖注入

> **注意：** 测试类中使用 `@Autowired` 是标准做法（生产代码应使用 `@RequiredArgsConstructor` + `final` 字段）。

```java
@Autowired
private MockMvc mockMvc;

@Autowired
private ObjectMapper objectMapper;

@Autowired
private DepartmentMapper departmentMapper;

@Autowired
private DepartmentBusinessRelationMapper departmentBusinessRelationMapper;
```

### 测试数据常量

```java
private static final Long TEST_TENANT_ID = 1L;
private static final Long TEST_SCHOOL_ID = 100L;
private static final Long OPERATOR_ID = 1L;
```

## Complete CRUD Example

```java
@Test
void testCRUD() throws Exception {
    // ========== 1. Create ==========
    String deptName = "测试部门-" + System.currentTimeMillis();
    DepartmentInsertReq insertReq = DepartmentInsertReq.builder()
            .name(deptName)
            .deptType(DepartmentTypeEnum.DEPARTMENT)
            .schoolIds(List.of(TEST_SCHOOL_ID))
            .parentId(0L)
            .intro("测试部门介绍")
            .build();
    insertReq.setTenantId(TEST_TENANT_ID);
    insertReq.setOperatorId(OPERATOR_ID);

    performPost("/departments/insert", insertReq);

    // 验证主表字段
    Department dept = departmentMapper.selectOne(
            new LambdaQueryWrapper<Department>()
                    .eq(Department::getTenantId, TEST_TENANT_ID)
                    .eq(Department::getName, deptName)
                    .last("LIMIT 1")
    );
    assertNotNull(dept, "部门创建后应存在于数据库");
    assertEquals(deptName, dept.getName());
    assertEquals(TEST_TENANT_ID, dept.getTenantId());
    assertEquals(DepartmentTypeEnum.DEPARTMENT, dept.getDeptType());

    // 验证关联表
    assertRelationCount(dept.getId(), DepartmentBusinessTypeEnum.SCHOOL, 1);

    // ========== 2. Read (API) ==========
    mockMvc.perform(get("/departments/get-by-id")
                    .param("id", dept.getId().toString())
                    .param("tenantId", TEST_TENANT_ID.toString()))
            .andExpect(status().isOk());

    // ========== 3. Update ==========
    String updatedName = "更新后部门-" + System.currentTimeMillis();
    DepartmentUpdateReq updateReq = DepartmentUpdateReq.builder()
            .id(dept.getId())
            .name(updatedName)
            .intro("更新后的介绍")
            .schoolIds(List.of())  // 清空校区关联
            .build();
    updateReq.setTenantId(TEST_TENANT_ID);
    updateReq.setOperatorId(OPERATOR_ID);

    performPost("/departments/update", updateReq);

    // 验证主表更新
    Department updated = departmentMapper.selectById(dept.getId());
    assertEquals(updatedName, updated.getName());
    assertEquals("更新后的介绍", updated.getIntro());

    // 验证关联表变化
    assertRelationCount(dept.getId(), DepartmentBusinessTypeEnum.SCHOOL, 0);

    // ========== 4. Delete ==========
    IdsTenantReq deleteReq = IdsTenantReq.builder()
            .ids(List.of(dept.getId()))
            .build();
    deleteReq.setTenantId(TEST_TENANT_ID);

    performPost("/departments/batch-delete", deleteReq);

    // 验证删除（逻辑删除，MyBatis-Plus 自动过滤）
    assertNull(departmentMapper.selectById(dept.getId()), "删除后应查询不到");
}

// ==================== 辅助方法 ====================

private ResultActions performPost(String url, Object req) throws Exception {
    return mockMvc.perform(post(url)
            .contentType(MediaType.APPLICATION_JSON)
            .content(objectMapper.writeValueAsString(req)))
            .andExpect(status().isOk());
}

private void assertRelationCount(Long deptId, DepartmentBusinessTypeEnum type, int expected) {
    List<DepartmentBusinessRelation> relations =
            departmentBusinessRelationMapper.selectByDepartmentIdAndType(deptId, type);
    assertEquals(expected, relations.size());
}
```

## Key Principles

| 原则 | 说明 |
|------|------|
| **真实写库** | 不 Mock 数据层，真正写入数据库验证 |
| **自动回滚** | `@Transactional` 保证测试结束数据回滚 |
| **DB 验证** | 通过项目的 Mapper 直接查询数据库验证状态 |
| **不依赖特定 ORM** | 适配各种 Mapper 实现（MyBatis-Plus、TKMapper 等），根据项目技术栈自行调整查询方式 |
| **时间戳命名** | `System.currentTimeMillis()` 避免数据冲突 |
| **幂等性** | 可重复运行多次，结果一致 |

## Common Notes

### 事务回滚保证幂等性

- 所有写库操作都会在测试结束后自动回滚
- 测试不会污染数据库，可重复运行

### 查询不受 Controller 事务影响

- 使用 Mapper 直接查询，不走 Controller 事务
- 总能读取到最新提交的数据，验证准确

### 名称查询说明

- 使用 `System.currentTimeMillis()` 生成唯一名称 + 按名称 + 租户查询查找记录，这是插入后验证的可靠方式
- 如果你的 Create 接口返回创建后的 ID，可以直接使用 `selectById` 查询更简单

### 逻辑删除验证

- MyBatis-Plus 自动过滤 `is_deleted=1` 的记录
- 验证删除：`assertNull(departmentMapper.selectById(id))`

### 多表验证

- 不仅验证主表，还要验证所有关联表（关系表）
- 创建、更新、删除都需要验证关联表变化

### 新增操作字段验证

- **必须验证所有必填字段**写入数据库后值正确
- 不能只验证 HTTP 状态码，必须通过数据库查询验证每个字段
- 示例：
```java
assertNotNull(dept, "部门创建后应存在于数据库");
assertEquals(deptName, dept.getName());
assertEquals(TEST_TENANT_ID, dept.getTenantId());
assertEquals(DepartmentTypeEnum.DEPARTMENT, dept.getDeptType());
```

## Best Practices for Reducing Boilerplate

对于多个关联表，可以继续提取辅助方法。示例中已展示 `performPost` 和 `assertRelationCount`，如果你的项目需要多个 helper，可以继续提取类似方法：

```java
// 批量设置 tenantId 和 operatorId
private void setTestContext(BaseReq req) {
    req.setTenantId(TEST_TENANT_ID);
    req.setOperatorId(OPERATOR_ID);
}
```

## Imports 参考

> **注意**：以下 import 基于 MyBatis-Plus 示例。根据项目使用的 Mapper 框架（如 TKMapper、JPA 等）自行调整查询相关 import。

```java
// MyBatis-Plus 查询
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
// Spring 测试
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.test.web.servlet.MockMvc;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;
import static org.junit.jupiter.api.Assertions.*;
import java.util.List;
```

## Common Mistakes

❌ **错误：不验证数据库，只依赖 HTTP 响应**

```java
// 只验证 status 200，不验证数据库状态 -> 不完整
mockMvc.perform(...).andExpect(status().isOk());
```

✅ **正确：验证 HTTP 状态，再查数据库验证真实状态**

```java
mockMvc.perform(...).andExpect(status().isOk());
Department dept = departmentMapper.selectOne(...);
assertNotNull(dept);
assertEquals(expectedName, dept.getName());
```

❌ **错误：每次测试手动清理数据**

```java
// 不需要手动删除，@Transactional 自动回滚
@AfterEach
void cleanup() {
    departmentMapper.deleteById(deptId);
}
```

✅ **正确：依赖 @Transactional 自动回滚**

```java
@SpringBootTest
@AutoConfigureMockMvc
@Transactional  // 自动回滚，无需手动清理
class XxxControllerTest { ... }
```

❌ **错误：使用 @WebMvcTest + Mock Repository**

```java
@WebMvcTest(UserController.class)  // 只加载 Web 层，Repository 需要 Mock
class UserControllerTest {
    @MockBean
    private UserRepository repository;  // Mock 不执行真实写库
}
```

✅ **正确：使用 @SpringBootTest 启动完整上下文**

```java
@SpringBootTest  // 启动完整上下文，包含所有 Bean
@AutoConfigureMockMvc
@Transactional
class UserControllerTest {
    @Autowired
    private UserRepository repository;  // 真实 Repository，真实写库
}
```
