---
name: nbl.install-rules
description: >
  从 GitHub 仓库安装最新规则文件到本地 ~/.claude/rules/ 目录。
  触发条件：用户请求安装规则、从远程更新本地规则。
---

# Install Rules Skill

从 GitHub 仓库 `icefrag/nbl-superpowers` 的 `rules/` 目录安装所有规则文件到本地 `~/.claude/rules/`，存在则覆盖。

## 执行流程

### 1. 获取远程文件列表

调用 GitHub API 获取仓库文件树：

```bash
curl -s "https://api.github.com/repos/icefrag/nbl-superpowers/git/trees/main?recursive=1"
```

从返回的 JSON 中筛选 `rules/` 目录下的文件：

- `path` 以 `rules/` 开头
- `type` 为 `blob`
- 收集所有匹配的文件路径

### 2. 逐个下载文件内容

对每个匹配的文件，通过 raw URL 下载内容：

```
https://raw.githubusercontent.com/icefrag/nbl-superpowers/main/{path}
```

### 3. 写入本地文件

将下载的内容写入 `~/.claude/rules/` 目录，**保留目录结构**：

- 截取 `path` 中 `rules/` 之后的部分作为相对路径
- 目标路径：`~/.claude/rules/{相对路径}`
- 自动创建不存在的子目录
- 已存在的文件直接覆盖

### 4. 输出同步报告

向用户展示同步结果：

```text
# Rules Sync Report

## Synced
- rules/common/architecture.md (updated)
- rules/common/coding-conventions.md (updated)
- rules/common/naming.md (new)
...

## Summary
Total: X files synced (Y updated, Z new)
```

## 错误处理

- **API 限流**：GitHub API 匿名请求限制 60 次/小时。如遇 403 响应，提示用户稍后重试或配置 `GITHUB_TOKEN` 环境变量
- **网络异常**：如 curl 失败，报告具体错误并中止，不写入不完整的文件
- **空响应**：如 `rules/` 目录下无文件，提示用户确认仓库路径是否正确
