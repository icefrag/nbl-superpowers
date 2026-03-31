#!/usr/bin/env pwsh
#===============================================================================
# sub-to-sub-merge.ps1 - 合并任务 worktree 到合并 worktree (并行模式专用)
#
# 功能:
#   1. 在任务 worktree 内 rebase 任务分支到合并分支
#   2. 在合并 worktree 内 ff-only 合并任务分支
#   3. 调用 cleanup-worktree 清理任务 worktree (除非 -NoCleanup)
#===============================================================================

#-------------------------------------------------------------------------------
# 参数解析
#-------------------------------------------------------------------------------

param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$BaseName,

    [Parameter(Mandatory=$true, Position=1)]
    [string]$TaskId,

    [switch]$NoCleanup
)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$ScriptDir/lib/common.ps1"

if ($BaseName -eq "-h" -or $BaseName -eq "--help") {
    Write-Host @"
用法: sub-to-sub-merge.ps1 <base_name> <task_id> [-NoCleanup]

并行模式专用：合并任务 worktree 到合并 worktree。

参数:
  BaseName    功能名称 (例如: log-analyzer)
  TaskId      任务ID (例如: 1)
  -NoCleanup   不清理任务 worktree (用于调试)

说明:
  自动约定推导:
  - 任务分支: feature/{base_name}-task{task_id}
  - 任务路径: .worktrees/{base_name}-task{task_id}
  - 合并分支: feature/{base_name}-merge
  - 合并路径: .worktrees/{base_name}-merge

"@
    exit 0
}

#-------------------------------------------------------------------------------
# 推导名称和路径
#-------------------------------------------------------------------------------

$TaskBranch = "feature/$BaseName-task$TaskId"
$TaskPath = ".worktrees/$BaseName-task$TaskId"
$MergeBranch = "feature/$BaseName-merge"
$MergePath = ".worktrees/$BaseName-merge"

Write-Host "🔄 合并任务到合并 worktree:"
Write-Host "   base_name:   $BaseName"
Write-Host "   task_id:     $TaskId"
Write-Host "   task_branch: $TaskBranch"
Write-Host "   task_path:   $TaskPath"
Write-Host "   merge_branch: $MergeBranch"
Write-Host "   merge_path:   $MergePath"
Write-Host ""

#-------------------------------------------------------------------------------
# 前置检查
#-------------------------------------------------------------------------------

Ensure-GitRepo

if (-not (Test-Path $TaskPath)) {
    Write-Host "❌ 任务 worktree 不存在: $TaskPath"
    exit 1
}

if (-not (Test-Path $MergePath)) {
    Write-Host "❌ 合并 worktree 不存在: $MergePath"
    exit 1
}

# 检查分支是否存在
$taskBranchExists = git show-ref --verify --quiet "refs/heads/$TaskBranch" 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ 任务分支不存在: $TaskBranch"
    exit 1
}

$mergeBranchExists = git show-ref --verify --quiet "refs/heads/$MergeBranch" 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ 合并分支不存在: $MergeBranch"
    exit 1
}

#-------------------------------------------------------------------------------
# Step 1: Rebase 任务分支到合并分支
#-------------------------------------------------------------------------------

Write-Host "📝 Step 1: Rebase 任务分支 ($TaskBranch) 到 $MergeBranch..."

Push-Location $TaskPath
git rebase $MergeBranch
$rebaseExit = $LASTEXITCODE

if ($rebaseExit -ne 0) {
    Write-Host ""
    Write-Host "❌ Rebase 失败，请解决冲突后重试。任务 worktree 保留: $TaskPath"
    Pop-Location
    exit $rebaseExit
}

Pop-Location
Write-Host "✅ Rebase 完成"
Write-Host ""

#-------------------------------------------------------------------------------
# Step 2: 在合并 worktree 内合并任务分支
#-------------------------------------------------------------------------------

Write-Host "🔀 Step 2: Merge 任务分支 ($TaskBranch) 到 $MergeBranch..."

Push-Location $MergePath
git merge --ff-only $TaskBranch
$mergeExit = $LASTEXITCODE

if ($mergeExit -ne 0) {
    Write-Host ""
    Write-Host "❌ Merge 失败。任务 worktree 保留: $TaskPath"
    Pop-Location
    exit $mergeExit
}

Pop-Location
Write-Host "✅ Merge 完成"
Write-Host ""

#-------------------------------------------------------------------------------
# Step 3: 清理任务 worktree
#-------------------------------------------------------------------------------

if ($NoCleanup) {
    Write-Host "⏭️  Step 3: -NoCleanup 指定，跳过清理"
    Write-Host ""
    Write-Host "🎉 合并完成，任务 worktree 保留用于调试"
    exit 0
}

Write-Host "🧹 Step 3: 清理任务 worktree..."
& "$ScriptDir/cleanup-worktree.ps1" $BaseName $TaskId -Force
$cleanupExit = $LASTEXITCODE

if ($cleanupExit -ne 0) {
    Write-Host "⚠️  清理完成但有警告，不影响合并结果"
}

Write-Host ""
Write-Host "🎉 合并流程完成!"
exit 0
