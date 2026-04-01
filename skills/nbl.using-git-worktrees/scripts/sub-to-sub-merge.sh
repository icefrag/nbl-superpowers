#!/usr/bin/env bash
#===============================================================================
# sub-to-sub-merge.sh - 合并任务 worktree 到合并 worktree (并行模式专用)
#
# 功能:
#   1. 在任务 worktree 内 rebase 任务分支到合并分支
#   2. 在合并 worktree 内 ff-only 合并任务分支
#   3. 调用 cleanup-worktree 清理任务 worktree (除非 --no-cleanup)
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
. "$SCRIPT_DIR/lib/common.sh"

# 跳转到 Git 仓库根目录，解决从子目录调用时相对路径解析错误
cd_to_git_root

#-------------------------------------------------------------------------------
# 参数解析
#-------------------------------------------------------------------------------

if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    cat <<EOF
用法: sub-to-sub-merge.sh <base_name> <task_id> [--no-cleanup]

并行模式专用：合并任务 worktree 到合并 worktree。

参数:
  base_name    功能名称 (例如: log-analyzer)
  task_id      任务ID (例如: 1)
  --no-cleanup 不清理任务 worktree (用于调试)

说明:
  自动约定推导:
  - 任务分支: feature/{base_name}-task{task_id}
  - 任务路径: .worktrees/{base_name}-task{task_id}
  - 合并分支: feature/{base_name}-merge
  - 合并路径: .worktrees/{base_name}-merge

EOF
    exit 0
fi

if [[ $# -lt 2 ]]; then
    echo "❌ 缺少参数。用法: sub-to-sub-merge.sh <base_name> <task_id> [--no-cleanup]"
    exit 1
fi

BASE_NAME="$1"
TASK_ID="$2"
NO_CLEANUP=false

if [[ "${3:-}" == "--no-cleanup" ]]; then
    NO_CLEANUP=true
fi

#-------------------------------------------------------------------------------
# 推导名称和路径
#-------------------------------------------------------------------------------

read -r TASK_BRANCH TASK_PATH <<< "$(compute_names "$BASE_NAME" "$TASK_ID")"
MERGE_BRANCH="feature/${BASE_NAME}-merge"
MERGE_PATH=".worktrees/${BASE_NAME}-merge"

echo "🔄 合并任务到合并 worktree:"
echo "   base_name:   $BASE_NAME"
echo "   task_id:     $TASK_ID"
echo "   task_branch: $TASK_BRANCH"
echo "   task_path:   $TASK_PATH"
echo "   merge_branch: $MERGE_BRANCH"
echo "   merge_path:   $MERGE_PATH"
echo

#-------------------------------------------------------------------------------
# 前置检查
#-------------------------------------------------------------------------------

ensure_git_repo

if [[ ! -d "$TASK_PATH" ]]; then
    echo "❌ 任务 worktree 不存在: $TASK_PATH"
    exit 1
fi

if [[ ! -d "$MERGE_PATH" ]]; then
    echo "❌ 合并 worktree 不存在: $MERGE_PATH"
    exit 1
fi

# 检查分支是否存在
if ! branch_exists "$TASK_BRANCH"; then
    echo "❌ 任务分支不存在: $TASK_BRANCH"
    exit 1
fi

if ! branch_exists "$MERGE_BRANCH"; then
    echo "❌ 合并分支不存在: $MERGE_BRANCH"
    exit 1
fi

#-------------------------------------------------------------------------------
# Step 1: Rebase 任务分支到合并分支
#-------------------------------------------------------------------------------

echo "📝 Step 1: Rebase 任务分支 ($TASK_BRANCH) 到 $MERGE_BRANCH..."

git -C "$TASK_PATH" rebase "$MERGE_BRANCH"
REBASE_EXIT=$?

if [[ $REBASE_EXIT -ne 0 ]]; then
    echo
    echo "❌ Rebase 失败，请解决冲突后重试。任务 worktree 保留: $TASK_PATH"
    exit $REBASE_EXIT
fi

echo "✅ Rebase 完成"
echo

#-------------------------------------------------------------------------------
# Step 2: 在合并 worktree 内合并任务分支
#-------------------------------------------------------------------------------

echo "🔀 Step 2: Merge 任务分支 ($TASK_BRANCH) 到 $MERGE_BRANCH..."

git -C "$MERGE_PATH" merge --ff-only "$TASK_BRANCH"
MERGE_EXIT=$?

if [[ $MERGE_EXIT -ne 0 ]]; then
    echo
    echo "❌ Merge 失败。任务 worktree 保留: $TASK_PATH"
    exit $MERGE_EXIT
fi

echo "✅ Merge 完成"
echo

#-------------------------------------------------------------------------------
# Step 3: 清理任务 worktree
#-------------------------------------------------------------------------------

if [[ "$NO_CLEANUP" = true ]]; then
    echo "⏭️  Step 3: --no-cleanup 指定，跳过清理"
    echo
    echo "🎉 合并完成，任务 worktree 保留用于调试"
    exit 0
fi

echo "🧹 Step 3: 清理任务 worktree..."
"$SCRIPT_DIR/cleanup-worktree.sh" "$BASE_NAME" "$TASK_ID" --force
CLEANUP_EXIT=$?

if [[ $CLEANUP_EXIT -ne 0 ]]; then
    echo "⚠️  清理完成但有警告，不影响合并结果"
fi

echo
echo "🎉 合并流程完成!"
exit 0
