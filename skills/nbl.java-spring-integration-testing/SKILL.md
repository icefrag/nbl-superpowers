---
name: nbl.java-spring-integration-testing
description: Use when writing Java Spring Boot integration tests that perform real database CRUD operations with MockMvc and MyBatis-Plus
---

# nbl.java-spring-integration-testing

## Overview

Java Spring Boot 集成测试最佳实践，使用 `@SpringBootTest` + `@AutoConfigureMockMvc` + `@Transactional` 组合执行真实数据库 CRUD 操作，测试结束后自动回滚保证幂等性。

核心特点：
- **真实写库**：在真实数据库执行 CRUD，不使用 Mock
- **自动回滚**：`@Transactional` 保证测试结束后数据自动回滚
- **LambdaQueryWrapper 验证**：使用 MyBatis-Plus 直接查询数据库验证
- **多表关联验证**：主表和关联关系表都需要验证
- **一个方法完成 CRUD**：Create-Read-Update-Delete 在一个测试方法中完成

## When to Use

Use when:
- 需要验证 Controller 层完整业务流程
- 需要验证数据库写入操作正确性（包括关联表）
- 希望测试可重复运行（幂等性）
- 使用 MyBatis-Plus 作为 ORM 框架

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

> **注意：** 测试类中使用 `@Autowired` 是标准做法（生产代码应使用 `@RequiredArgsConstructor` + `final` 字段）。测试类不由 Spring 容器管理构造函数，因此字段注入是唯一选择。

```java
@Autowired
private MockMvc mockMvc;

@Autowired
private ObjectMapper objectMapper;

@Autowired
private DepartmentMapper departmentMapper;

@Autowired
private DepartmentBusinessRelationMapper departmentBusinessRelationMapper;

@Autowired
private DepartmentUserRelationMapper departmentUserRelationMapper;
```

### 测试数据常量

```java
private static final Long TEST_TENANT_ID = 1L;
private static final Long TEST_SCHOOL_ID_1 = 100L;
private static final Long TEST_SCHOOL_ID_2 = 101L;
private static final Long OPERATOR_ID = 1L;
private static final Long LEADER_USER_ID = 200L;
private static final Long MEMBER_USER_ID_1 = 201L;
private static final Long MEMBER_USER_ID_2 = 202L;
private static final Long LEARNING_AREA_ID = 300L;
```

## Complete CRUD Example

```java
@Test
void testCRUD() throws Exception {
    // 1. Create - 创建父部门
    String parentName = "测试父部门-" + System.currentTimeMillis();
    DepartmentInsertReq parentReq = DepartmentInsertReq.builder()
            .name(parentName)
            .deptType(DepartmentTypeEnum.DEPARTMENT)
            .schoolIds(List.of(TEST_SCHOOL_ID_1, TEST_SCHOOL_ID_2))
            .parentId(0L)
            .leaderUserIds(List.of(LEADER_USER_ID))
            .memberUserIds(List.of(MEMBER_USER_ID_1, MEMBER_USER_ID_2))
            .intro("父部门用于容纳子部门")
            .build();
    parentReq.setTenantId(TEST_TENANT_ID);
    parentReq.setOperatorId(OPERATOR_ID);

    mockMvc.perform(post("/departments/insert")
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(objectMapper.writeValueAsString(parentReq)))
            .andExpect(status().isOk());

    Department parentDept = departmentMapper.selectOne(
            new LambdaQueryWrapper<Department>()
                    .eq(Department::getTenantId, TEST_TENANT_ID)
                    .eq(Department::getName, parentName)
                    .last("LIMIT 1")
    );
    assertNotNull(parentDept, "父部门创建后应该存在于数据库");
    assertEquals(0L, parentDept.getParentId(), "父部门的parentId应该为0");

    // 验证父部门校区关系
    List<DepartmentBusinessRelation> parentSchoolRelations =
            departmentBusinessRelationMapper.selectByDepartmentIdAndType(
                    parentDept.getId(), DepartmentBusinessTypeEnum.SCHOOL);
    assertEquals(2, parentSchoolRelations.size(), "父部门应该关联2个校区");

    // 验证父部门人员关系
    List<DepartmentUserRelation> parentUserRelations =
            departmentUserRelationMapper.listByDepartmentId(parentDept.getId());
    assertEquals(3, parentUserRelations.size(), "父部门应该有3个人员关系");
    Map<Integer, Long> memberCounts = parentUserRelations.stream()
            .collect(Collectors.groupingBy(r -> r.getMemberType().getCode(), Collectors.counting()));
    assertEquals(1, memberCounts.getOrDefault(MemberTypeEnum.LEADER.getCode(), 0L), "应该有1个负责人");
    assertEquals(2, memberCounts.getOrDefault(MemberTypeEnum.MEMBER.getCode(), 0L), "应该有2个成员");

    // 2. Create - 创建子部门（后续会删除）
    String childName = "测试子部门-" + System.currentTimeMillis();
    String updatedName = "测试子部门-已更新-" + System.currentTimeMillis();

    DepartmentInsertReq insertReq = DepartmentInsertReq.builder()
            .name(childName)
            .deptType(DepartmentTypeEnum.TEACHING_RESEARCH_GROUP)
            .schoolIds(List.of(TEST_SCHOOL_ID_1, TEST_SCHOOL_ID_2))
            .parentId(parentDept.getId())
            .leaderUserIds(List.of(LEADER_USER_ID))
            .memberUserIds(List.of(MEMBER_USER_ID_1))
            .intro("这是一个测试子部门")
            .build();
    insertReq.setTenantId(TEST_TENANT_ID);
    insertReq.setOperatorId(OPERATOR_ID);

    mockMvc.perform(post("/departments/insert")
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(objectMapper.writeValueAsString(insertReq)))
            .andExpect(status().isOk());

    // 查询验证子部门创建成功
    Department childDept = departmentMapper.selectOne(
            new LambdaQueryWrapper<Department>()
                    .eq(Department::getTenantId, TEST_TENANT_ID)
                    .eq(Department::getName, childName)
                    .last("LIMIT 1")
    );

    assertNotNull(childDept, "新增后子部门应该存在于数据库");
    assertEquals(childName, childDept.getName());
    assertEquals(TEST_TENANT_ID, childDept.getTenantId());
    assertEquals(DepartmentTypeEnum.TEACHING_RESEARCH_GROUP, childDept.getDeptType());
    assertEquals(parentDept.getId(), childDept.getParentId(), "子部门parentId错误");

    // 验证关联表
    List<DepartmentBusinessRelation> childSchoolRelations =
            departmentBusinessRelationMapper.selectByDepartmentIdAndType(
                    childDept.getId(), DepartmentBusinessTypeEnum.SCHOOL);
    assertEquals(2, childSchoolRelations.size(), "子部门应该关联2个校区");

    List<DepartmentUserRelation> childUserRelations =
            departmentUserRelationMapper.listByDepartmentId(childDept.getId());
    assertEquals(2, childUserRelations.size(), "子部门应该有2个人员关系");

    // 4. GetById - 接口查询验证（只验证 HTTP 200，数据正确性已在数据库验证）
    mockMvc.perform(get("/departments/get-by-id")
                    .param("id", childDept.getId().toString())
                    .param("tenantId", TEST_TENANT_ID.toString()))
            .andExpect(status().isOk());

    // 5. Update - 更新子部门
    DepartmentUpdateReq updateReq = DepartmentUpdateReq.builder()
            .id(childDept.getId())
            .name(updatedName)
            .intro("这是更新后的测试部门介绍")
            .schoolIds(List.of(TEST_SCHOOL_ID_1))  // 减少到1个校区
            .parentId(parentDept.getId())
            .leaderUserIds(List.of())
            .memberUserIds(List.of())
            .build();
    updateReq.setTenantId(TEST_TENANT_ID);
    updateReq.setOperatorId(OPERATOR_ID);

    mockMvc.perform(post("/departments/update")
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(objectMapper.writeValueAsString(updateReq)))
            .andExpect(status().isOk());

    // 验证数据库更新
    Department updatedDepartment = departmentMapper.selectById(childDept.getId());
    assertNotNull(updatedDepartment);
    assertEquals(updatedName, updatedDepartment.getName());
    assertEquals("这是更新后的测试部门介绍", updatedDepartment.getIntro());

    // 验证关联表更新（减少到1个校区）
    List<DepartmentBusinessRelation> updatedSchoolRelations =
            departmentBusinessRelationMapper.selectByDepartmentIdAndType(
                    childDept.getId(), DepartmentBusinessTypeEnum.SCHOOL);
    assertEquals(1, updatedSchoolRelations.size(), "更新后应该关联1个校区");

    // 验证人员关系清空
    List<DepartmentUserRelation> updatedUserRelations =
            departmentUserRelationMapper.listByDepartmentId(childDept.getId());
    assertEquals(0, updatedUserRelations.size(), "更新后人员关系应该清空");

    // 6. Delete - 删除子部门
    IdsTenantReq deleteReq = IdsTenantReq.builder()
            .ids(List.of(childDept.getId()))
            .build();
    deleteReq.setTenantId(TEST_TENANT_ID);

    mockMvc.perform(post("/departments/batch-delete")
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(objectMapper.writeValueAsString(deleteReq)))
            .andExpect(status().isOk());

    // 验证删除成功（逻辑删除，MyBatis-Plus 自动过滤）
    Department deletedDepartment = departmentMapper.selectById(childDept.getId());
    assertNull(deletedDepartment, "删除后子部门查询应该不存在");
}
```

## Key Principles

| 原则 | 说明 |
|------|------|
| **真实写库** | 不 Mock 数据层，真正写入数据库验证 |
| **自动回滚** | `@Transactional` 保证测试结束数据回滚 |
| **DB 验证** | 通过 Mapper 直接查询数据库验证状态 |
| **LambdaQueryWrapper** | 使用 MyBatis-Plus 构造查询条件 |
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

- 使用 `System.currentTimeMillis()` 生成唯一名称 + `LambdaQueryWrapper` 查询查找记录，这是插入后验证的可靠方式
- 如果你的 Create 接口返回创建后的 ID，可以直接使用 `selectById` 查询更简单

### 逻辑删除验证

- MyBatis-Plus 自动过滤 `is_deleted=1` 的记录
- 验证删除：`assertNull(departmentMapper.selectById(id))`

### 多表验证

- 不仅验证主表，还要验证所有关联表（关系表）
- 创建、更新、删除都需要验证关联表变化

## Best Practices for Reducing Boilerplate

### Extract Helper Methods

在实际项目中，为了减少重复代码，可以提取通用的 helper 方法：

```java
// 封装 POST 请求
private ResultActions performPost(String url, Object req) throws Exception {
    return mockMvc.perform(post(url)
            .contentType(MediaType.APPLICATION_JSON)
            .content(objectMapper.writeValueAsString(req)))
            .andExpect(status().isOk());
}

// 封装关系表验证
private void assertRelationCount(Long deptId, DepartmentBusinessTypeEnum type, int expectedSize) {
    List<DepartmentBusinessRelation> relations =
            departmentBusinessRelationMapper.selectByDepartmentIdAndType(deptId, type);
    assertEquals(expectedSize, relations.size());
}

// 批量设置 tenantId 和 operatorId
private void setTestContext(BaseReq req) {
    req.setTenantId(TEST_TENANT_ID);
    req.setOperatorId(OPERATOR_ID);
}
```

这样可以大幅减少重复的 `mockMvc.perform` 和 `setTenantId/setOperatorId` 代码。

## Imports 参考

```java
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.test.web.servlet.MockMvc;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import java.util.stream.Collectors;
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
