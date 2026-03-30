#!/usr/bin/env bash
#===============================================================================
# common.sh - Git Worktree 操作公共函数库 (Bash)
#===============================================================================

set -euo pipefail

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

#-------------------------------------------------------------------------------
# 输出函数
#-------------------------------------------------------------------------------

# 输出 JSON 格式结果到文件
output_json() {
    local file="$1"
    shift
    printf '%s\n' "$*" > "$file"
}

# 输出成功 JSON
output_success_json() {
    local file="$1"
    local worktree_path="$2"
    local branch_name="$3"
    local is_new="$4"
    local message="$5"

    cat > "$file" <<EOF
{
  "success": true,
  "worktree_path": "$worktree_path",
  "branch_name": "$branch_name",
  "is_new": $is_new,
  "message": "$message"
}
EOF
}

# 输出失败 JSON
output_error_json() {
    local file="$1"
    local error="$2"
    local exit_code="${3:-1}"

    cat > "$file" <<EOF
{
  "success": false,
  "error": "$error",
  "exit_code": $exit_code
}
EOF
}

#-------------------------------------------------------------------------------
# Git 仓库检查
#-------------------------------------------------------------------------------

# 确保是 git 仓库，如果不是则初始化
ensure_git_repo() {
    if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
        echo "ℹ️  当前目录不是 git 仓库，正在自动初始化..."
        git init

        # 设置默认用户信息
        git config user.name "Claude Code" 2>/dev/null || true
        git config user.email "claude@anthropic.com" 2>/dev/null || true

        # 初始提交
        git add .
        if git commit -m "Initial commit by nbl.using-git-worktrees" > /dev/null 2>&1; then
            echo "✅ Git 仓库初始化完成"
        fi
    fi
}

#-------------------------------------------------------------------------------
# Gitignore 检查
#-------------------------------------------------------------------------------

# 确保 .worktrees/ 和 docs/ 目录被 gitignore
ensure_gitignore() {
    local changed=false

    if ! git check-ignore -q .worktrees 2>/dev/null; then
        echo "ℹ️  .worktrees/ 未被 gitignore，正在添加..."
        echo ".worktrees/" >> .gitignore
        changed=true
    fi

    if ! git check-ignore -q docs/ 2>/dev/null; then
        echo "ℹ️  docs/ 未被 gitignore，正在添加..."
        echo "docs/" >> .gitignore
        changed=true
    fi

    if [ "$changed" = true ]; then
        git add .gitignore
        git commit -m "chore: update .gitignore" > /dev/null 2>&1 || true
        echo "✅ .gitignore 已更新"
    fi
}

#-------------------------------------------------------------------------------
# 命名计算
#-------------------------------------------------------------------------------

# 根据 base_name 和 task_id 计算分支名和路径
# 输出: branch_name worktree_path
compute_names() {
    local base_name="$1"
    local task_id="${2:-}"

    local branch_name
    local worktree_path

    if [ -n "$task_id" ]; then
        branch_name="feature/${base_name}-task${task_id}"
        worktree_path=".worktrees/${base_name}-task${task_id}"
    else
        branch_name="feature/${base_name}"
        worktree_path=".worktrees/${base_name}"
    fi

    echo "$branch_name $worktree_path"
}

#-------------------------------------------------------------------------------
# 工作目录准备
#-------------------------------------------------------------------------------

# 准备工作目录（确保存在）
prepare_worktrees_dir() {
    if [ ! -d ".worktrees" ]; then
        mkdir -p .worktrees
    fi
}
