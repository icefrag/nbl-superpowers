#!/usr/bin/env bash
#===============================================================================
# sub-to-sub-merge.sh - 合并任务 worktree 到合并 worktree (并行模式专用)
#
# 功能:
#   1. 在任务 worktree 内 rebase 任务分支到合并分支
#   2. 在合并 worktree 内 ff-only 合并任务分支
#   3. 调用 cleanup-worktree 清理任务 worktree (除非 --no-cleanup)
#===============================================================================

#-------------------------------------------------------------------------------
# 参数解析
#-------------------------------------------------------------------------------

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
PROJECT_ROOT=$(pwd)
. "$SCRIPT_DIR/lib/common.sh"

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
NO_CLEANUP=0

if [[ "$3" == "--no-cleanup" ]]; then
    NO_CLEANUP=1
fi

#-------------------------------------------------------------------------------
# 推导名称和路径
#-------------------------------------------------------------------------------

TASK_BRANCH="feature/${BASE_NAME}-task${TASK_ID}"
TASK_PATH=".worktrees/${BASE_NAME}-task${TASK_ID}"
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
git show-ref --verify --quiet "refs/heads/$TASK_BRANCH" 2>/dev/null
if [[ $? -ne 0 ]]; then
    echo "❌ 任务分支不存在: $TASK_BRANCH"
    exit 1
fi

git show-ref --verify --quiet "refs/heads/$MERGE_BRANCH" 2>/dev/null
if [[ $? -ne 0 ]]; then
    echo "❌ 合并分支不存在: $MERGE_BRANCH"
    exit 1
fi

#-------------------------------------------------------------------------------
# Step 1: Rebase 任务分支到合并分支
#-------------------------------------------------------------------------------

echo "📝 Step 1: Rebase 任务分支 ($TASK_BRANCH) 到 $MERGE_BRANCH..."

cd "$TASK_PATH"
git rebase "$MERGE_BRANCH"
REBASE_EXIT=$?

if [[ $REBASE_EXIT -ne 0 ]]; then
    echo
    echo "❌ Rebase 失败，请解决冲突后重试。任务 worktree 保留: $TASK_PATH"
    exit $REBASE_EXIT
fi

cd "$PROJECT_ROOT"
echo "✅ Rebase 完成"
echo

#-------------------------------------------------------------------------------
# Step 2: 在合并 worktree 内合并任务分支
#-------------------------------------------------------------------------------

echo "🔀 Step 2: Merge 任务分支 ($TASK_BRANCH) 到 $MERGE_BRANCH..."

cd "$MERGE_PATH"
git merge --ff-only "$TASK_BRANCH"
MERGE_EXIT=$?

if [[ $MERGE_EXIT -ne 0 ]]; then
    echo
    echo "❌ Merge 失败。任务 worktree 保留: $TASK_PATH"
    exit $MERGE_EXIT
fi

cd "$PROJECT_ROOT"
echo "✅ Merge 完成"
echo

#-------------------------------------------------------------------------------
# Step 3: 清理任务 worktree
#-------------------------------------------------------------------------------

if [[ $NO_CLEANUP -eq 1 ]]; then
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
