#!/usr/bin/env bash
#===============================================================================
# create-worktree.sh - 创建或恢复 git worktree (Bash)
#===============================================================================

set -euo pipefail

# 计算脚本所在目录，处理 Windows 路径格式
_normalize_script_dir() {
    local raw_dir
    raw_dir=$(dirname "${BASH_SOURCE[0]}")
    # Windows 兼容性：确保路径使用正斜杠
    raw_dir="${raw_dir//\\//}"
    # 如果是相对路径（不以 / 开头，也不是 Windows 绝对路径如 D:/...），转换为绝对路径
    if [[ ! "$raw_dir" =~ ^(/|[A-Za-z]:/) ]]; then
        raw_dir="$(pwd)/$raw_dir"
    fi
    echo "$raw_dir"
}

SCRIPT_DIR=$(_normalize_script_dir)
source "$SCRIPT_DIR/lib/common.sh"

# 跳转到 Git 仓库根目录，解决从子目录调用时相对路径解析错误
cd_to_git_root

#-------------------------------------------------------------------------------
# 参数解析
#-------------------------------------------------------------------------------

usage() {
    cat <<EOF
用法: $(basename "$0") <base_name> [task_id] [output_file]

创建或恢复一个 git worktree。

参数:
  base_name    功能名称 (例如: user-auth)
  task_id      可选，parallel 模式的任务 ID
  output_file  可选，输出 JSON 结果到文件

示例:
  $(basename "$0") user-auth
  $(basename "$0") user-auth 1
  $(basename "$0") user-auth 1 /tmp/result.json
EOF
}

# 参数检查
if [[ $# -lt 1 ]] || [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
    usage
    exit 0
fi

BASE_NAME="$1"
TASK_ID=""
OUTPUT_FILE=""

shift
while [[ $# -gt 0 ]]; do
    case "$1" in
        [0-9]*)
            TASK_ID="$1"
            ;;
        *)
            OUTPUT_FILE="$1"
            ;;
    esac
    shift
done

# 计算分支名和路径
read -r BRANCH_NAME WORKTREE_PATH <<< "$(compute_names "$BASE_NAME" "$TASK_ID")"

echo "📦 创建 worktree: $WORKTREE_PATH (分支: $BRANCH_NAME)"

#-------------------------------------------------------------------------------
# 前置检查
#-------------------------------------------------------------------------------

# 确保是 git 仓库
ensure_git_repo

# 确保 .worktrees 被 gitignore
ensure_gitignore

# 确保目录存在
prepare_worktrees_dir

#-------------------------------------------------------------------------------
# 创建或恢复 worktree
#-------------------------------------------------------------------------------

IS_NEW=false

if git worktree add "$WORKTREE_PATH" -b "$BRANCH_NAME" 2>/dev/null; then
    echo "✅ 新建 worktree 成功"
    IS_NEW=true
    MESSAGE="Created new worktree"
else
    echo "⚠️  创建失败，尝试智能恢复..."

    if [[ -d "$WORKTREE_PATH" ]]; then
        # Case 1: 目录已存在 → 复用
        echo "📂 目录已存在，复用已有 worktree"
        IS_NEW=false
        MESSAGE="Reused existing worktree"
    elif branch_exists "$BRANCH_NAME"; then
        # Case 2: 分支存在但目录不存在 → 尝试重新 attach
        echo "🔗 分支已存在，重新 attach worktree"
        ATTACH_ERROR=$(git worktree add "$WORKTREE_PATH" "$BRANCH_NAME" 2>&1) && ATTACH_RC=$? || ATTACH_RC=$?
        if [[ $ATTACH_RC -eq 0 ]]; then
            echo "✅ Re-attach 成功"
            IS_NEW=false
            MESSAGE="Re-attached existing worktree"
        elif echo "$ATTACH_ERROR" | grep -q "already used by worktree"; then
            # 分支已被主 worktree 检出，无法创建隔离 worktree
            echo "⚠️  分支 '$BRANCH_NAME' 已被当前 worktree 检出"
            echo "💡 Git 不允许同一分支同时被多个 worktree 检出"
            echo "💡 建议：直接在当前 worktree 的分支上继续开发，无需创建隔离 worktree"
            [[ -n "$OUTPUT_FILE" ]] && output_error_json "$OUTPUT_FILE" "Branch already checked out in current worktree, use current workspace directly"
            exit 1
        else
            echo "❌ 重新 attach 失败: $ATTACH_ERROR"
            [[ -n "$OUTPUT_FILE" ]] && output_error_json "$OUTPUT_FILE" "Failed to re-attach: $ATTACH_ERROR"
            exit 1
        fi
    else
        # Case 3: 其他错误
        echo "❌ 创建 worktree 失败"
        [[ -n "$OUTPUT_FILE" ]] && output_error_json "$OUTPUT_FILE" "Failed to create worktree: unknown error"
        exit 1
    fi
fi

#-------------------------------------------------------------------------------
# 清理不需要的目录
#-------------------------------------------------------------------------------

# 删除 worktree 中的 docs 目录
# 设计：计划文档和设计文档保存在主仓库，由主代理维护，子代理不需要
if [[ -d "$WORKTREE_PATH/docs" ]]; then
    echo "🧹 清理: 删除 worktree 中不需要的 docs 目录"
    rm -rf "$WORKTREE_PATH/docs"
fi

#-------------------------------------------------------------------------------
# 输出结果
#-------------------------------------------------------------------------------

echo "📍 Worktree 路径: $PWD/$WORKTREE_PATH"

if [[ -n "$OUTPUT_FILE" ]]; then
    output_success_json "$OUTPUT_FILE" "$WORKTREE_PATH" "$BRANCH_NAME" "$IS_NEW" "$MESSAGE"
    echo "✅ 结果已输出到: $OUTPUT_FILE"
else
    if [[ "$IS_NEW" = true ]]; then
        echo "🎉 Worktree 创建成功"
    else
        echo "🔄 Worktree 复用成功"
    fi
fi
