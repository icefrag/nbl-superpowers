# nbl.superpowers 开发项目

## 项目概述

本项目是 Claude Code Skills 的设计与开发仓库，基于官方 superpowers 扩展。

### 本地开发参考

本项目基于官方 superpowers 技能体系扩展开发，本地开发参考源码地址：

- 官方 superpowers 源码：`D:\workspace\superpowers`
- skills 目录：`D:\workspace\superpowers\skills`

### 版本更新

更新版本号时，需要同时修改 `.claude-plugin` 目录下的两个文件中的版本号：

| 文件 | 字段位置 |
|------|----------|
| `.claude-plugin/plugin.json` | `plugins[0].version` |
| `.claude-plugin/marketplace.json` | `version` |

版本号格式：`X.Y.Z`（语义化版本）
