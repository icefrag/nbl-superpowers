---
name: springboot-tdd
description: Spring Boot测试驱动开发，使用JUnit 5、Mockito、MockMvc、Testcontainers和JaCoCo。在添加功能、修复bug或重构时使用。
---

# Spring Boot TDD工作流

Spring Boot服务的TDD指南，要求80%以上覆盖率（单元测试 + 集成测试）。

## 使用时机

- 新功能或新端点
- Bug修复或重构
- 添加数据访问逻辑或安全规则

- 编写Service/Manager单元测试
- 编写Controller集成测试

## 项目结构与测试策略

### 测试文件位置（与生产代码同包）
```
app/src/test/java/com/guozhi/api/[项目名称]/[业务名称]/
├── controller/
│   └── [业务名称]ControllerTest.java      # Controller集成测试
└── service/
    ├── [业务名称]ServiceTest.java          # Service单元测试
    └── manager/
        └── [业务名称]ManagerTest.java       # Manager单元测试
```

### 测试类型分配

| 层级 | 测试类型 | 框架 | 说明 |
|------|---------|------|------|
| **Controller** | 集成测试 | @SpringBootTest + MockMvc | 测试API契约、参数验证、HTTP状态 |
| **Service** | 单元测试 | @ExtendWith(MockitoExtension.class) | Mock依赖，测试业务逻辑 |
| **Manager** | 单元测试 | @ExtendWith(MockitoExtension.class) | Mock依赖，测试数据组装逻辑 |

### 命名规范
- 单元测试：`{ClassName}Test`
- 集成测试：`{ClassName}Test`（Controller层）

## 工作流

1) 先写测试（应该失败）
2) 实现最小代码使其通过
3) 在测试通过的前提下重构
4) 强制覆盖率（JaCoCo）

## 单元测试（JUnit 5 + Mockito）

适用于：**Service层** 和 **Manager层**

```java
@ExtendWith(MockitoExtension.class)
class MarketServiceTest {
  @Mock MarketRepository repo;
  @InjectMocks MarketService service;

  @Test
  void createsMarket() {
    CreateMarketRequest req = new CreateMarketRequest("name", "desc", Instant.now(), List.of("cat"));
    when(repo.save(any())).thenAnswer(inv -> inv.getArgument(0));

    Market result = service.create(req);

    assertThat(result.name()).isEqualTo("name");
    verify(repo).save(any());
  }
}
```

模式：
- Arrange-Act-Assert（准备-执行-断言）
- 避免部分Mock；优先显式stub
- 变体场景使用 `@ParameterizedTest`

## 集成测试（SpringBootTest）

适用于：**Controller层**

```java
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("dev")
class MarketIntegrationTest {
  @Autowired MockMvc mockMvc;

  @Test
  void createsMarket() throws Exception {
    mockMvc.perform(post("/api/markets")
        .contentType(MediaType.APPLICATION_JSON)
        .content("""
          {"name":"Test","description":"Desc","endDate":"2030-01-01T00:00:00Z","categories":["general"]}
        """))
      .andExpect(status().isCreated());
  }
}
```

## Testcontainers

- 使用可复用容器运行Postgres/Redis，模拟生产环境
- 通过 `@DynamicPropertySource` 将JDBC URL注入Spring上下文

## 覆盖率（JaCoCo）

Maven配置：
```xml
<plugin>
  <groupId>org.jacoco</groupId>
  <artifactId>jacoco-maven-plugin</artifactId>
  <version>0.8.14</version>
  <executions>
    <execution>
      <goals><goal>prepare-agent</goal></goals>
    </execution>
    <execution>
      <id>report</id>
      <phase>verify</phase>
      <goals><goal>report</goal></goals>
    </execution>
  </executions>
</plugin>
```

## 断言

- 优先使用AssertJ（`assertThat`）以提高可读性
- JSON响应使用 `jsonPath`
- 异常使用：`assertThatThrownBy(...)`

## 测试数据构建器

```java
class MarketBuilder {
  private String name = "Test";
  MarketBuilder withName(String name) { this.name = name; return this; }
  Market build() { return new Market(null, name, MarketStatus.ACTIVE); }
}
```

## CI命令

- Maven: `mvn -T 4 test` 或 `mvn verify`
- Gradle: `./gradlew test jacocoTestReport`

**记住**：保持测试快速、隔离、确定性。测试行为，而非实现细节。
