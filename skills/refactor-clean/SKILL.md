---
name: refactor-clean
description: >
  Java Web 死代码清理和重构专家。安全识别并移除死代码，每一步都进行测试验证。
  触发条件：用户请求清理死代码、重构优化、移除未使用代码。
---

# Refactor Clean Skill

安全识别并移除死代码，每一步都进行测试验证。

## 激活时机

- 用户请求清理死代码
- 代码维护优化
- 移除未使用代码

## 步骤1：检测死代码

根据项目类型运行分析工具：

| 工具 | 检测内容 | 命令 |
|------|----------|------|
| Maven Dependency | 未使用的Maven依赖 | `mvn dependency:analyze` |
| SpotBugs | 静态代码分析 | `mvn spotbugs:check` |
| PMD | 代码质量检查+重复代码 | `mvn pmd:check` |
| JaCoCo | 测试覆盖率分析 | `mvn test jacoco:report` |
| Checkstyle | 代码规范检查 | `mvn checkstyle:check` |

如果没有专用工具，使用Grep查找零引用的公开方法：
```bash
# 查找类定义，然后检查是否被引用
grep -r "ClassName" --include="*.java" | grep -v "ClassName.java"
```

## 步骤2：分类检测结果

将检测结果按安全等级分类：

| 等级 | 示例 | 操作 |
|------|------|------|
| **安全** | 未使用的工具方法、私有方法、常量 | 可放心删除 |
| **谨慎** | Service方法、Controller方法、DTO类 | 验证无动态调用或外部消费者 |
| **危险** | Feign接口、Entity类、枚举类 | 调查后再决定 |
| **禁止** | api模块的公开接口、配置类 | 不允许删除 |

## 步骤3：安全删除循环

对于每个**安全**级别的项：

1. **运行完整测试套件** — 建立基线（全部通过）
   ```bash
   mvn clean test
   ```
2. **删除死代码** — 使用Edit工具精确移除
3. **重新运行测试** — 验证没有破坏
   ```bash
   mvn test
   ```
4. **如果测试失败** — 立即回滚 `git checkout -- <file>` 并跳过此项
5. **如果测试通过** — 移至下一项

## 步骤4：处理谨慎级别项

删除谨慎级别项之前：
- 搜索动态调用：反射 `Class.forName()`、`Method.invoke()`
- 搜索字符串引用：配置文件中的类名、Spring Bean名称
- 检查是否被Feign接口导出
- 检查api模块中是否有对应的Req/Resp/Query对象引用
- 验证无其他微服务调用（检查api模块接口）

## 步骤5：合并重复代码

移除死代码后，检查：

- 相似方法（>80%相似）— 合并为一个
- 重复的DTO转换逻辑 — 使用MapStruct或提取工具方法
- 无价值的包装方法 — 直接内联调用
- 多余的中间层 — 移除不必要的委托

## 步骤6：总结

输出结果报告：

```
死代码清理报告
──────────────────────────────
已删除:   12个未使用方法
          3个未使用类
          5个未使用依赖
已跳过:   2项（测试失败）
节省:     约450行代码
──────────────────────────────
编译通过 ✅
测试通过 ✅
覆盖率: 85% ✅
```

## Java Web项目特定规则

### 禁止删除

- **api模块的Feign接口** — 可能被其他微服务调用
- **Entity实体类** — MyBatis-Plus动态使用
- **枚举类（Enum后缀）** — 可能被序列化/反序列化
- **Mapper接口** — XML中的SQL可能动态调用
- **Spring配置类** — 影响应用启动

### 分层架构检查

删除前验证是否违反分层：
```bash
# Controller不能直接调用Mapper
grep -r "Mapper" --include="*Controller.java" | grep -v "//"

# Service层禁止直接使用QueryWrapper
grep -r "QueryWrapper\|LambdaQueryWrapper" --include="*ServiceImpl.java"
```

### Maven依赖清理

```bash
# 分析未使用的依赖
mvn dependency:analyze

# 关注输出：
# - Unused declared dependencies: 可安全移除
# - Used undeclared dependencies: 需要显式声明
```

## 核心规则

- **禁止不运行测试就删除**
- **一次只删一个** — 原子变更使回滚更容易
- **不确定就跳过** — 保留死代码比破坏生产环境好
- **清理与重构分开** — 先清理，后重构
- **每批次后编译验证** — `mvn compile`
