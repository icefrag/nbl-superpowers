---
name: update-codemaps
description: >
  更新代码地图，分析代码库结构并生成 token 精简的架构文档。
  触发条件：完成重大功能新增后、重构会话后、用户请求更新代码地图。
---

# Update Codemaps Skill

分析代码库结构并生成 token 精简的架构文档。

## 激活时机

- 完成重大功能新增后
- 重构会话后
- 用户请求更新代码地图

## 步骤1：扫描项目结构

1. 识别项目类型（monorepo、单应用、库、微服务）
2. 查找所有源代码目录（src/、lib/、app/、packages/）
3. 映射入口点（main.ts、index.ts、app.py、main.go 等）

## 步骤2：生成代码地图

在 `docs/CODEMAPS/`中创建或更新代码地图：

| 文件 | 内容 |
|------|------|
| `architecture.md` | 高层系统图、服务边界、数据流 |
| `backend.md` | API 路由、中间件链、服务 → 仓库映射 |
| `frontend.md` | 页面树、组件层级、状态管理流 |
| `data.md` | 数据库表、关系、迁移历史 |
| `dependencies.md` | 外部服务、第三方集成、共享库 |

### 代码地图格式

每个代码地图应保持 token 精简 —— 针对 AI 上下文消费进行优化：

```markdown
# 后端架构

## 路由
POST /api/users → UserController.create → UserService.create → UserRepo.insert
GET  /api/users/:id → UserController.get → UserService.findById → UserRepo.findById

## 关键文件
src/services/user.ts (业务逻辑, 120 行)
src/repos/user.ts (数据库访问, 80 行)

## 依赖
- PostgreSQL (主数据存储)
- Redis (会话缓存, 限流)
- Stripe (支付处理)
```

## 步骤3：差异检测

1. 如果存在之前的代码地图，计算差异百分比
2. 如果变更 > 30%，显示差异并在覆盖前请求用户确认
3. 如果变更 <= 30%，直接原地更新

## 步骤4：添加元数据

为每个代码地图添加新鲜度标头：

```markdown
<!-- 生成时间: 2026-03-25 | 扫描文件: 142 | Token 估算: ~800 -->
```

## 步骤5：保存分析报告

将摘要写入 `.reports/codemap-diff.txt`：
- 自上次扫描以来新增/删除/修改的文件
- 检测到的新依赖
- 架构变更（新路由、新服务等）
- 超过 90 天未更新文档的过期警告

## 提示

- 聚焦**高层结构**，而非实现细节
- 优先使用**文件路径和函数签名**，而非完整代码块
- 每个代码地图保持在 **1000 token 以内**，便于高效加载上下文
- 使用 ASCII 图表展示数据流，替代冗长的文字描述
- 在完成重大功能新增或重构会话后运行
