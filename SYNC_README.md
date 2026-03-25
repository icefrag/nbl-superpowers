# Guozhi Claude Code 同步工具

同步 `commands`/`skills`/`rules`/`agents` 目录到用户的 `.claude` 目录。

这是一个跨平台的 Node.js 版本，替代了原来的 PowerShell 脚本，可以在 Windows、macOS 和 Linux 上运行。

## 功能特性

- 🔄 交互式菜单界面
- 📁 支持全量同步或选择性同步
- 📄 文件浏览和选择功能
- 💾 覆盖模式同步
- ⌨️ 非交互模式（自动化使用）

## 系统要求

- Node.js >= 18.0.0

## 安装依赖

```bash
npm install
```

## 使用方式

### 交互模式

```bash
# 方式1：直接运行
node sync.mjs

# 方式2：如果已全局安装
npm install -g
guozhi-sync
```

### 非交互模式（全量同步）

```bash
# 方式1：命令行参数
node sync.mjs --non-interactive

# 方式2：npm script
npm run sync-non-interactive

# 方式3：全局安装后
guozhi-sync --non-interactive
```

## 功能说明

1. **全量同步** - 同步所有目录
2. **单项同步** - 选择同步 commands/skills/rules/agents 其中之一
3. **浏览同步** - 浏览并选择特定文件或子目录
4. **覆盖模式** - 自动覆盖目标目录中的文件

## 目录映射

| 源目录 | 目标目录 |
|--------|----------|
| ./commands | ~/.claude/commands |
| ./skills | ~/.claude/skills |
| ./rules | ~/.claude/rules |
| ./agents | ~/.claude/agents |

## npm 脚本

- `npm run sync` - 运行交互式同步
- `npm run sync-non-interactive` - 运行非交互式全量同步

## 故障排除

如果遇到权限问题：

1. 确保目标目录 `~/.claude` 可写
2. 在某些系统上可能需要管理员权限

如果遇到 Node.js 版本问题：

1. 确保安装了 Node.js 18 或更高版本
2. 使用 Node 版本管理器（如 nvm）切换版本

## 贡献

欢迎提交 Issue 和 Pull Request 来改进此工具。