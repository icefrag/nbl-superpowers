---
name: update-docs
description: >
  更新文档，从代码库的"真实来源"文件同步文档，自动生成保持一致性。
  触发条件：用户请求更新文档、同步代码与文档。
---

# Update Docs Skill

从代码库的"真实来源"文件同步文档，自动生成保持一致性。

## 激活时机

- 用户请求更新文档
- 同步代码与文档
- 生成构建/配置参考

## 步骤1：识别真实来源

| 来源 | 生成内容 |
|------|----------|
| `pom.xml` / `build.gradle` | 可用命令参考 |
| `application.yml` / `application.properties` | 配置属性文档 |
| `openapi.yaml` / Controller文件 | API端点参考 |
| 源代码导出 | 公共API文档 |
| `Dockerfile` / `docker-compose.yml` | 基础设施部署文档 |

## 步骤2：生成构建命令参考

1. 读取 `pom.xml`（或 `build.gradle`、`Makefile`）
2. 提取所有构建命令及其描述
3. 生成参考表：

```markdown
| 命令 | 描述 |
|------|------|
| `mvn spring-boot:run` | 启动开发服务器（支持热重载） |
| `mvn clean package` | 生产构建（跳过测试） |
| `mvn clean install` | 完整构建并安装到本地仓库 |
| `mvn test` | 运行测试套件并生成覆盖率报告 |
| `mvn compile` | 编译源代码 |
| `gradle bootRun` | 启动开发服务器 |
| `gradle build` | 生产构建 |
| `gradle test` | 运行测试套件 |
```

## 步骤3：生成配置文档

1. 读取 `application.yml`（或 `application.properties`、`application-example.yml`）
2. 提取所有配置属性及其用途
3. 分类为必需和可选
4. 文档化期望格式和有效值

```markdown
| 属性 | 必需 | 描述 | 示例 |
|------|------|------|------|
| `spring.datasource.url` | 是 | 数据库连接字符串 | `jdbc:mysql://localhost:3306/db` |
| `spring.datasource.username` | 是 | 数据库用户名 | `root` |
| `spring.datasource.password` | 是 | 数据库密码 | `******` |
| `logging.level.root` | 否 | 日志级别（默认：info） | `debug`, `info`, `warn`, `error` |
| `server.port` | 否 | 服务端口（默认：8080） | `8081` |
```

## 步骤4：更新贡献指南

生成或更新 `docs/CONTRIBUTING.md`，包含：
- 开发环境搭建（前置条件、安装步骤）
- 可用构建命令及其用途
- 测试流程（如何运行、如何编写新测试）
- 代码规范执行（Checkstyle、SpotBugs、pre-commit钩子）
- PR提交检查清单

## 步骤5：更新运维手册

生成或更新 `docs/RUNBOOK.md`，包含：
- 部署流程（分步骤说明）
- 健康检查端点和监控指标
- 常见问题及其解决方案
- 回滚流程
- 告警和升级路径

## 步骤6：过期检查

1. 查找90天以上未修改的文档文件
2. 与最近的源代码变更交叉比对
3. 标记可能过时的文档供人工审查

## 步骤7：显示摘要

```
文档更新
──────────────────────────────────
已更新:  docs/CONTRIBUTING.md (构建命令表)
已更新:  docs/CONFIG.md (3个新配置项)
已标记:  docs/DEPLOY.md (过期142天)
已跳过:  docs/API.md (未检测到变更)
──────────────────────────────────
```

## 规则

- **单一真实来源**：始终从代码生成，切勿手动编辑生成部分
- **保留手动内容**：只更新生成部分；保留手写的说明文字
- **标记生成内容**：在生成部分周围使用 `<!-- AUTO-GENERATED -->` 标记
- **不要主动创建文档**：仅当命令明确请求时才创建新文档文件
