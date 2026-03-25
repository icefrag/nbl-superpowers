---
name: test-coverage
description: >
  测试覆盖率分析，识别缺口，生成缺失的测试以达到80%+覆盖率。
  触发条件：用户请求测试覆盖率分析、提升测试覆盖率、编写测试。
rules:
  - rules/common/architecture.md
  - rules/common/naming.md
  - rules/common/coding-conventions.md
---

# Test Coverage Skill

分析测试覆盖率，识别缺口，生成缺失的测试以达到80%+覆盖率。

## 激活时机

- 用户请求测试覆盖率分析
- 提升测试覆盖率
- 编写缺失的测试

## 步骤0：识别测试范围（关键）

### ✅ 必须测试（100%覆盖目标）

| 类型 | 包路径模式 | 测试方式 | 原因 |
|------|-----------|----------|------|
| **Service层** | `**/service/impl/*Impl.java` | 单元测试 | 核心业务逻辑 |
| **Manager层** | `**/service/manager/impl/*Impl.java` | 单元测试 | 外部集成逻辑 |
| **Controller层** | `**/controller/*.java` | 集成测试 | API契约验证 |
| **工具类** | `**/utils/*.java`（含复杂逻辑） | 单元测试 | 跨服务复用 |
| **财务计算** | 所有含计算逻辑的类 | 单元测试 | 高风险 |
| **认证授权** | `**/security/**/*.java` | 单元测试 | 安全关键 |

### 🚫 排除测试（不计入覆盖率）

| 类型 | 包路径模式 | 原因 |
|------|-----------|------|
| **Entity类** | `**/model/entity/*.java` | 纯数据载体，无逻辑 |
| **DTO类** | `**/model/dto/*.java` | 纯数据载体，通过其他测试间接覆盖 |
| **Req/Resp/Query** | `**/model/request/*.java`<br>`**/model/response/*.java`<br>`**/model/query/*.java` | POJO，通过Controller测试间接覆盖 |
| **枚举类** | `**/enums/*.java` | 纯定义，无业务逻辑 |
| **常量类** | `**/constants/*.java` | 仅静态常量 |
| **配置类** | `**/config/**` | Spring管理，无业务逻辑 |
| **Mapper层** | `**/mapper/**/*.java` | 框架生成实现，通过集成测试间接覆盖 |
| **MyBatis拦截器** | `**/*.java`（implements Interceptor） | MyBatis插件框架，通过集成测试覆盖 |
| **定时任务** | `**/job/*.java` | 通过集成测试覆盖 |
| **启动类** | `*Application.java` | 无测试价值 |
| **事件类** | `**/*Event.java` | 纯数据载体，无业务逻辑 |
| **事件监听器** | `**/listener/*Listener.java` | Spring框架管理，通过集成测试覆盖 |
| **消息队列监听器** | `**/messagequeue/**`<br>`**/mq/**` | MQ框架管理，需要真实环境 |

### JaCoCo排除配置

在`pom.xml`中配置排除：

```xml
<plugin>
    <groupId>org.jacoco</groupId>
    <artifactId>jacoco-maven-plugin</artifactId>
    <configuration>
        <excludes>
            <!-- Entity/DTO/VO -->
            <exclude>**/model/entity/**</exclude>
            <exclude>**/model/dto/**</exclude>
            <exclude>**/model/enums/**</exclude>
            <exclude>**/model/request/**</exclude>
            <exclude>**/model/response/**</exclude>
            <exclude>**/model/query/**</exclude>
            <!-- Mapper层 -->
            <exclude>**/mapper/**</exclude>
            <!-- MyBatis拦截器 -->
            <exclude>**/*Interceptor.class</exclude>
            <!-- 事件类 -->
            <exclude>**/*Event.class</exclude>
            <!-- 监听器 -->
            <exclude>**/listener/**</exclude>
            <!-- 消息队列 -->
            <exclude>**/messagequeue/**</exclude>
            <exclude>**/mq/**</exclude>
            <!-- 配置类 -->
            <exclude>**/config/**</exclude>
            <!-- 常量类 -->
            <exclude>**/constants/**</exclude>
            <!-- 启动类 -->
            <exclude>**/*Application.class</exclude>
        </excludes>
    </configuration>
</plugin>
```

## 步骤1：检测测试框架

| 标识 | 覆盖率命令 |
|------|-----------|
| `pom.xml` with JaCoCo | `mvn test jacoco:report` |
| `build.gradle` with JaCoCo | `./gradlew test jacocoTestReport` |

## 步骤2：分析覆盖率报告

1. 运行覆盖率命令
2. 解析输出（target/site/jacoco/jacoco.xml 或终端输出）
3. **过滤排除类后**，列出低于80%覆盖率的文件，按最差优先排序
4. 对于每个覆盖率不足的文件，识别：
   - 未测试的方法
   - 缺失的分支覆盖（if/else、switch、异常路径）
   - 死代码（膨胀分母）

## 步骤3：生成缺失测试

### 测试优先级

| 优先级 | 测试类型 | 覆盖目标 |
|--------|----------|----------|
| P0 | 成功路径 | 核心功能使用有效输入 |
| P0 | 异常处理 | 无效输入、业务异常 |
| P1 | 边界案例 | 空集合、null、边界值 |
| P1 | 分支覆盖 | 每个if/else、switch case |

### 测试生成规则

- **Service/Manager/Utils**：单元测试放在 `src/test/java/.../`
- **Controller**：集成测试放在 `src/test/java/.../controller/`
- 使用项目现有的测试模式（import风格、断言库、Mock方式）
- Mock外部依赖（数据库、外部API、文件系统）
- 每个测试应该独立 — 测试之间不共享可变状态

## 步骤4：验证

1. 运行完整测试套件 — 所有测试必须通过
2. 重新运行覆盖率 — 验证改进
3. 如果仍低于80%，重复步骤3处理剩余缺口

## 步骤5：报告

```
覆盖率报告（已排除Entity/DTO/Mapper/Config类）
──────────────────────────────────────────────────
文件                          之前   之后   状态
──────────────────────────────────────────────────
DiscountServiceImpl.java      45%    88%   ✅
OrderServiceImpl.java         32%    82%   ✅
OrderManagerImpl.java         55%    85%   ✅
──────────────────────────────────────────────────
总体覆盖率:                    46%    87%   ✅
```

## 覆盖率目标

| 代码类型 | 目标覆盖率 | 测试方式 |
|----------|-----------|----------|
| 财务计算、认证、安全 | **100%** | 单元测试 |
| Service/Manager业务逻辑 | **80%+** | 单元测试 |
| Controller层 | **80%+** | 集成测试 |
| 工具类 | **80%+** | 单元测试 |
