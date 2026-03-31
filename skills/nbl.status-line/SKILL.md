---
name: nbl.status-line
description: 一键安装自定义状态行脚本到 ~/.claude，显示模型、Git状态、上下文使用率、成本和worktree信息
---

# nbl.status-line

一键安装自定义 Claude Code 状态行。

## 安装

> **AI执行方式**：按步骤分步执行 Bash 脚本。遇到需要用户确认的场景，使用 AskUserQuestion 工具询问用户，不要在 Bash 中使用 read 命令。

### 步骤 1：复制 statusline.sh 并检测配置状态

将以下脚本作为Bash工具直接执行：

```bash
# 检查 jq
if ! command -v jq >/dev/null 2>&1; then
  echo "错误: jq 未安装"
  echo "Windows (Git Bash): 通常已预装"
  echo "Ubuntu/Debian: sudo apt install jq"
  echo "macOS: brew install jq"
  exit 1
fi

# 定位源文件：尝试多个可能的路径
SOURCE_FILE=""
for dir in \
  "$HOME/.claude/plugins/marketplaces/nbl-dev/skills/nbl.status-line" \
  "$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"; do
  if [ -f "$dir/statusline.sh" ]; then
    SOURCE_FILE="$dir/statusline.sh"
    break
  fi
done

if [ -z "$SOURCE_FILE" ]; then
  echo "错误: 找不到 statusline.sh 源文件"
  exit 1
fi

TARGET_DIR="$HOME/.claude"
TARGET_FILE="$TARGET_DIR/statusline.sh"

# 复制文件
mkdir -p "$TARGET_DIR"
cp -f "$SOURCE_FILE" "$TARGET_FILE"
chmod +x "$TARGET_FILE"
echo "已复制 statusline.sh"

# 检测配置状态并输出标记供 AI 判断
SETTINGS_FILE="$TARGET_DIR/settings.json"
if [ ! -f "$SETTINGS_FILE" ]; then
  echo "::CONFIG_STATUS=no_settings"
  exit 0
fi

if ! jq . "$SETTINGS_FILE" >/dev/null 2>&1; then
  echo "错误: settings.json JSON 格式无效"
  exit 1
fi

EXISTING_CMD=$(jq -r '.statusLine.command // ""' "$SETTINGS_FILE")
if [ -z "$EXISTING_CMD" ]; then
  echo "::CONFIG_STATUS=no_statusline"
elif [ "$EXISTING_CMD" = "~/.claude/statusline.sh" ]; then
  echo "::CONFIG_STATUS=correct"
  echo "安装完成! statusline.sh 已更新，请重启 Claude Code 生效"
else
  echo "::CONFIG_STATUS=different"
  echo "当前配置路径: $EXISTING_CMD"
fi
```

### 步骤 2：根据配置状态决定下一步

根据步骤 1 输出的 `::CONFIG_STATUS` 值：

| CONFIG_STATUS | AI 操作 |
|---|---|
| `no_settings` | 直接执行下方"更新配置"脚本（先创建 settings.json） |
| `no_statusline` | 直接执行下方"更新配置"脚本 |
| `correct` | 无需操作，安装完成 |
| `different` | **使用 AskUserQuestion 询问用户**是否将配置路径更新为 `~/.claude/statusline.sh`，根据用户回答决定是否执行下方脚本 |

### 更新配置脚本

当需要写入 statusLine 配置时，执行：

```bash
SETTINGS_FILE="$HOME/.claude/settings.json"
[ ! -f "$SETTINGS_FILE" ] && echo "{}" > "$SETTINGS_FILE"
TEMP_SETTINGS=$(mktemp)
jq '. + {
  "statusLine": {
    "type": "command",
    "command": "~/.claude/statusline.sh"
  }
}' "$SETTINGS_FILE" > "$TEMP_SETTINGS" && mv "$TEMP_SETTINGS" "$SETTINGS_FILE"
echo "已更新 statusLine 配置"
echo "安装完成! 请重启 Claude Code 使状态行生效"
```

## 卸载

手动操作：
1. 删除 `~/.claude/statusline.sh`
2. 从 `~/.claude/settings.json` 中删除 `statusLine` 配置
