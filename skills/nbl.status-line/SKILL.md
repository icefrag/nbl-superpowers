---
name: nbl.status-line
description: 一键安装自定义状态行脚本到 ~/.claude，显示模型、Git状态、上下文使用率、成本和worktree信息
---

# nbl.status-line

一键安装自定义 Claude Code 状态行。

## 安装

执行以下 Bash 脚本完成安装：

```bash
# 检查 jq 是否可用
if ! command -v jq >/dev/null 2>&1; then
  echo "错误: jq 未安装，请先安装 jq 后重试"
  echo "Windows (Git Bash): 通常已预装"
  echo "Ubuntu/Debian: sudo apt install jq"
  echo "macOS: brew install jq"
  exit 1
fi

# 获取脚本源路径
SKILL_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
SOURCE_FILE="$SKILL_DIR/statusline.sh"
TARGET_DIR="$HOME/.claude"
TARGET_FILE="$TARGET_DIR/statusline.sh"
SETTINGS_FILE="$TARGET_DIR/settings.json"

# 检查源文件存在
if [ ! -f "$SOURCE_FILE" ]; then
  echo "错误: 源文件 $SOURCE_FILE 不存在"
  exit 1
fi

# 创建 ~/.claude 目录如果不存在
mkdir -p "$TARGET_DIR"

# 检查 settings.json 是否存在，不存在创建空对象
if [ ! -f "$SETTINGS_FILE" ]; then
  echo "{}" > "$SETTINGS_FILE"
  echo "创建新的 settings.json: $SETTINGS_FILE"
fi

# 检查 settings.json 格式是否有效
if ! jq . "$SETTINGS_FILE" >/dev/null 2>&1; then
  echo "错误: settings.json JSON 格式无效，请修复后重试"
  exit 1
fi

# 检查是否已有 statusLine 配置
if jq -e '.statusLine' "$SETTINGS_FILE" >/dev/null 2>&1; then
  echo "提示: statusLine 配置已存在于 $SETTINGS_FILE，跳过安装"
  echo "如需重新安装，请手动删除 statusLine 配置后重试"
  exit 0
fi

# 复制 statusline.sh 到 ~/.claude (覆盖已存在文件)
cp -f "$SOURCE_FILE" "$TARGET_FILE"
chmod +x "$TARGET_FILE"
echo "已复制 statusline.sh 到 $TARGET_FILE"

# 添加 statusLine 配置
TEMP_SETTINGS=$(mktemp)
jq '. + {
  "statusLine": {
    "type": "command",
    "command": "~/.claude/statusline.sh"
  }
}' "$SETTINGS_FILE" > "$TEMP_SETTINGS" && mv "$TEMP_SETTINGS" "$SETTINGS_FILE"

echo "已在 settings.json 中添加 statusLine 配置"
echo ""
echo "安装完成! 请重启 Claude Code 使状态行生效"
```

## 卸载

手动操作：
1. 删除 `~/.claude/statusline.sh`
2. 从 `~/.claude/settings.json` 中删除 `statusLine` 配置
