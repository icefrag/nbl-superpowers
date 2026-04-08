#!/usr/bin/env bash
#===============================================================================
# cleanup-worktree.sh - 清理 git worktree (Bash)
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
用法: $(basename "$0") <base_name> [task_id] [--force]

清理 git worktree 和相关分支。

参数:
  base_name    功能名称 (例如: user-auth)
  task_id      可选，parallel 模式的任务 ID
  --force      可选，强制删除跳过合并检查

示例:
  $(basename "$0") user-auth
  $(basename "$0") user-auth 1 --force
EOF
}

BASE_NAME=""
TASK_ID=""
FORCE=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            usage
            exit 0
            ;;
        --force)
            FORCE=true
            ;;
        [0-9]*)
            TASK_ID="$1"
            ;;
        *)
            if [[ -z "$BASE_NAME" ]]; then
                BASE_NAME="$1"
            fi
            ;;
    esac
    shift
done

if [[ -z "$BASE_NAME" ]]; then
    usage
    exit 1
fi

# 计算分支名和路径
read -r BRANCH_NAME WORKTREE_PATH <<< "$(compute_names "$BASE_NAME" "$TASK_ID")"

echo "🧹 清理 worktree: $WORKTREE_PATH (分支: $BRANCH_NAME)"

#-------------------------------------------------------------------------------
# 前置检查
#-------------------------------------------------------------------------------

# 确保是 git 仓库
ensure_git_repo

#-------------------------------------------------------------------------------
# 检查未合并的提交
#-------------------------------------------------------------------------------

# 获取默认分支名 (main 或 master)
BASE_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's/refs\/remotes\/origin\///') || BASE_BRANCH="main"

# 检查是否有未合并到 base 分支的提交
if git log "$BASE_BRANCH..$BRANCH_NAME" --oneline -n 1 >/dev/null 2>&1; then
    # 有未合并提交
    if [[ "$FORCE" = false ]]; then
        echo "⚠️  检测到未合并的提交:"
        git log "$BASE_BRANCH..$BRANCH_NAME" --oneline 2>/dev/null
        echo ""
        echo "请使用 --force 参数强制删除"
        exit 1
    else
        echo "⚠️  警告: 继续删除未合并的提交"
    fi
fi

#-------------------------------------------------------------------------------
# 清理 worktree
#-------------------------------------------------------------------------------

if [[ -d "$WORKTREE_PATH" ]]; then
    if ! git worktree remove --force "$WORKTREE_PATH"; then
        echo "❌ Worktree 删除失败，请检查上述错误后重试"
        exit 1
    fi
    echo "✅ Worktree 已删除"
    # Windows 兼容处理：git worktree remove 有时因文件锁定无法删除空目录，手动再删一次
    if [[ -d "$WORKTREE_PATH" ]]; then
        echo "🧹 清理残留空目录..."
        rmdir "$WORKTREE_PATH" 2>/dev/null || true
        # 如果 rmdir 失败，尝试强制删除
        if [[ -d "$WORKTREE_PATH" ]]; then
            rm -rf "$WORKTREE_PATH" 2>/dev/null || true
        fi
    fi
else
    echo "📂 Worktree 目录不存在，跳过删除"
fi

#-------------------------------------------------------------------------------
# 删除分支
#-------------------------------------------------------------------------------

if branch_exists "$BRANCH_NAME"; then
    if git branch -d "$BRANCH_NAME" 2>/dev/null; then
        echo "✅ 分支 $BRANCH_NAME 已删除"
    else
        echo "⚠️  分支删除失败 (可能未合并)，尝试强制删除"
        git branch -D "$BRANCH_NAME" 2>/dev/null || true
        echo "✅ 分支 $BRANCH_NAME 已强制删除"
    fi
else
    echo "📂 分支不存在，跳过删除"
fi

#-------------------------------------------------------------------------------
# Prune 清理git内部失效worktree记录
#-------------------------------------------------------------------------------
echo "🧹 Prune 清理git内部失效worktree记录..."
git worktree prune
echo "✅ Prune 完成"

echo "✅ Worktree 清理完成"
