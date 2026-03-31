#!/usr/bin/env bash
#===============================================================================
# create-worktree.sh - 创建或恢复 git worktree (Bash)
#===============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

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
if [ $# -lt 1 ] || [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
    usage
    exit 0
fi

BASE_NAME="$1"
TASK_ID=""
OUTPUT_FILE=""

shift
while [ $# -gt 0 ]; do
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

    if [ -d "$WORKTREE_PATH" ]; then
        # Case 1: 目录已存在 → 复用
        echo "📂 目录已存在，复用已有 worktree"
        IS_NEW=false
        MESSAGE="Reused existing worktree"
    elif git show-ref --verify --quiet "refs/heads/$BRANCH_NAME"; then
        # Case 2: 分支存在但目录不存在 → 重新 attach
        echo "🔗 分支已存在，尝试 attach worktree"
        if git worktree add "$WORKTREE_PATH" "$BRANCH_NAME"; then
            echo "✅ Re-attach 成功"
            IS_NEW=false
            MESSAGE="Re-attached existing worktree"
        else
            # Case 2a: 重新 attach 失败 → 分支已被其他 worktree 占用（主工作区）
            # 自动创建新分支 BRANCH_NAME-worktree 从原分支分叉
            echo "⚠️  分支已被占用，自动创建新分支: ${BRANCH_NAME}-worktree"
            NEW_BRANCH="${BRANCH_NAME}-worktree"
            if git worktree add "$WORKTREE_PATH" -b "$NEW_BRANCH" "$BRANCH_NAME"; then
                echo "✅ 新建 worktree 成功 (从 ${BRANCH_NAME} 分叉)"
                IS_NEW=true
                MESSAGE="Created new worktree from existing branch (forked)"
                BRANCH_NAME="$NEW_BRANCH"
            else
                echo "❌ 创建分叉分支失败"
                [ -n "$OUTPUT_FILE" ] && output_error_json "$OUTPUT_FILE" "Failed to create forked branch ${NEW_BRANCH} from ${BRANCH_NAME}"
                exit 1
            fi
        fi
    else
        # Case 3: 其他错误
        echo "❌ 创建 worktree 失败"
        [ -n "$OUTPUT_FILE" ] && output_error_json "$OUTPUT_FILE" "Failed to create worktree: unknown error"
        exit 1
    fi
fi

#-------------------------------------------------------------------------------
# 清理不需要的目录
#-------------------------------------------------------------------------------

# 删除 worktree 中的 docs 目录
# 设计：计划文档和设计文档保存在主仓库，由主代理维护，子代理不需要
if [ -d "$WORKTREE_PATH/docs" ]; then
    echo "🧹 清理: 删除 worktree 中不需要的 docs 目录"
    rm -rf "$WORKTREE_PATH/docs"
fi

#-------------------------------------------------------------------------------
# 输出结果
#-------------------------------------------------------------------------------

echo "📍 Worktree 路径: $PWD/$WORKTREE_PATH"

if [ -n "$OUTPUT_FILE" ]; then
    output_success_json "$OUTPUT_FILE" "$WORKTREE_PATH" "$BRANCH_NAME" "$IS_NEW" "$MESSAGE"
    echo "✅ 结果已输出到: $OUTPUT_FILE"
else
    if [ "$IS_NEW" = true ]; then
        echo "🎉 Worktree 创建成功"
    else
        echo "🔄 Worktree 复用成功"
    fi
fi
