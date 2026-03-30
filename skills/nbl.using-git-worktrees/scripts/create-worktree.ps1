#!/usr/bin/env pwsh
#===============================================================================
# create-worktree.ps1 - 创建或恢复 git worktree (PowerShell)
#===============================================================================

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$ScriptDir/lib/common.ps1"

#-------------------------------------------------------------------------------
# 参数解析
#-------------------------------------------------------------------------------

param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$BaseName,

    [Parameter(Position=1)]
    [string]$TaskId = "",

    [Parameter(Position=2)]
    [string]$OutputFile = ""
)

if ($BaseName -eq "-h" -or $BaseName -eq "--help") {
    Write-Host @"
用法: create-worktree.ps1 <base_name> [task_id] [output_file]

创建或恢复一个 git worktree。

参数:
  base_name    功能名称 (例如: user-auth)
  task_id      可选，parallel 模式的任务 ID
  output_file  可选，输出 JSON 结果到文件

示例:
  create-worktree.ps1 user-auth
  create-worktree.ps1 user-auth 1
  create-worktree.ps1 user-auth 1 result.json
"@
    exit 0
}

# 计算分支名和路径
$names = Compute-Names -BaseName $BaseName -TaskId $TaskId
$BranchName = $names.BranchName
$WorktreePath = $names.WorktreePath

Write-Host "📦 创建 worktree: $WorktreePath (分支: $BranchName)"

#-------------------------------------------------------------------------------
# 前置检查
#-------------------------------------------------------------------------------

Ensure-GitRepo
Ensure-Gitignore
Prepare-WorktreesDir

#-------------------------------------------------------------------------------
# 创建或恢复 worktree
#-------------------------------------------------------------------------------

$IsNew = $false

# 尝试创建
$addResult = git worktree add $WorktreePath -b $BranchName 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ 新建 worktree 成功"
    $IsNew = $true
    $Message = "Created new worktree"
} else {
    Write-Host "⚠️  创建失败，尝试智能恢复..."

    if (Test-Path $WorktreePath) {
        # Case 1: 目录已存在
        Write-Host "📂 目录已存在，复用已有 worktree"
        $IsNew = $false
        $Message = "Reused existing worktree"
    } else {
        # 检查分支是否存在
        $branchExists = git show-ref --verify --quiet "refs/heads/$BranchName" 2>$null
        if ($branchExists) {
            # Case 2: 分支存在但目录不存在
            Write-Host "🔗 分支已存在，重新 attach worktree"
            $attachResult = git worktree add $WorktreePath $BranchName 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✅ Re-attach 成功"
                $IsNew = $false
                $Message = "Re-attached existing worktree"
            } else {
                Write-Host "❌ 重新 attach 失败"
                if ($OutputFile) {
                    Output-ErrorJson -File $OutputFile -Error "Failed to re-attach existing worktree"
                }
                exit 1
            }
        } else {
            # Case 3: 其他错误
            Write-Host "❌ 创建 worktree 失败"
            if ($OutputFile) {
                Output-ErrorJson -File $OutputFile -Error "Failed to create worktree: unknown error"
            }
            exit 1
        }
    }
}

#-------------------------------------------------------------------------------
# 切换到 worktree
#-------------------------------------------------------------------------------

Set-Location $WorktreePath
Write-Host "📍 当前目录: $(Get-Location)"

#-------------------------------------------------------------------------------
# 输出结果
#-------------------------------------------------------------------------------

if ($OutputFile) {
    Output-SuccessJson -File $OutputFile -WorktreePath $WorktreePath -BranchName $BranchName -IsNew $IsNew -Message $Message
    Write-Host "✅ 结果已输出到: $OutputFile"
} else {
    if ($IsNew) {
        Write-Host "🎉 Worktree 创建成功"
    } else {
        Write-Host "🔄 Worktree 复用成功"
    }
}
