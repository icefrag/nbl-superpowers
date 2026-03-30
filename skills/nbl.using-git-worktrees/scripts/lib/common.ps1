#===============================================================================
# common.ps1 - Git Worktree 操作公共函数库 (PowerShell)
#===============================================================================

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent (Split-Path -Parent $ScriptDir)

#-------------------------------------------------------------------------------
# 输出函数
#-------------------------------------------------------------------------------

function Output-SuccessJson {
    param(
        [string]$File,
        [string]$WorktreePath,
        [string]$BranchName,
        [bool]$IsNew,
        [string]$Message
    )

    @{
        success = $true
        worktree_path = $WorktreePath
        branch_name = $BranchName
        is_new = $IsNew
        message = $Message
    } | ConvertTo-Json -Compress | Set-Content -Path $File -Encoding UTF8
}

function Output-ErrorJson {
    param(
        [string]$File,
        [string]$Error,
        [int]$ExitCode
    )

    if ($null -eq $ExitCode) { $ExitCode = 1 }

    @{
        success = $false
        error = $Error
        exit_code = $ExitCode
    } | ConvertTo-Json -Compress | Set-Content -Path $File -Encoding UTF8
}

#-------------------------------------------------------------------------------
# Git 仓库检查
#-------------------------------------------------------------------------------

function Ensure-GitRepo {
    $isInsideWorkTree = git rev-parse --is-inside-work-tree 2>$null

    if (-not $isInsideWorkTree) {
        Write-Host "ℹ️  当前目录不是 git 仓库，正在自动初始化..."

        git init

        # 设置默认用户信息
        git config user.name "Claude Code" 2>$null
        git config user.email "claude@anthropic.com" 2>$null

        # 初始提交
        git add .
        $commit = git commit -m "Initial commit by nbl.using-git-worktree" 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Git 仓库初始化完成"
        }
    }
}

#-------------------------------------------------------------------------------
# Gitignore 检查
#-------------------------------------------------------------------------------

function Ensure-Gitignore {
    $changed = $false

    $ignoredWorktrees = git check-ignore .worktrees 2>$null
    if (-not $ignoredWorktrees) {
        Write-Host "ℹ️  .worktrees/ 未被 gitignore，正在添加..."
        ".worktrees/" | Add-Content -Path ".gitignore" -Encoding UTF8
        $changed = $true
    }

    $ignoredDocs = git check-ignore docs/ 2>$null
    if (-not $ignoredDocs) {
        Write-Host "ℹ️  docs/ 未被 gitignore，正在添加..."
        "docs/" | Add-Content -Path ".gitignore" -Encoding UTF8
        $changed = $true
    }

    if ($changed) {
        git add .gitignore
        git commit -m "chore: update .gitignore" 2>$null
        Write-Host "✅ .gitignore 已更新"
    }
}

#-------------------------------------------------------------------------------
# 命名计算
#-------------------------------------------------------------------------------

function Compute-Names {
    param(
        [string]$BaseName,
        [string]$TaskId
    )

    if ($null -eq $TaskId) { $TaskId = "" }

    if ($TaskId) {
        @{
            BranchName = "feature/${BaseName}-task${TaskId}"
            WorktreePath = ".worktrees/${BaseName}-task${TaskId}"
        }
    } else {
        @{
            BranchName = "feature/${BaseName}"
            WorktreePath = ".worktrees/${BaseName}"
        }
    }
}

#-------------------------------------------------------------------------------
# 工作目录准备
#-------------------------------------------------------------------------------

function Prepare-WorktreesDir {
    if (-not (Test-Path ".worktrees")) {
        New-Item -ItemType Directory -Path ".worktrees" | Out-Null
    }
}
