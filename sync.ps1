# Guozhi Claude Code 同步脚本
# 同步 commands/skills/rules/agents 到用户 .claude 目录

param(
    [switch]$NonInteractive
)

$ErrorActionPreference = "Stop"

# 源目录（脚本所在目录）
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ClaudeUserDir = Join-Path $env:USERPROFILE ".claude"

# 目标映射
$Targets = @{
    "commands" = @{
        Source = Join-Path $ScriptDir "commands"
        Dest   = Join-Path $ClaudeUserDir "commands"
    }
    "skills" = @{
        Source = Join-Path $ScriptDir "skills"
        Dest   = Join-Path $ClaudeUserDir "skills"
    }
    "rules" = @{
        Source = Join-Path $ScriptDir "rules"
        Dest   = Join-Path $ClaudeUserDir "rules"
    }
}

# 颜色辅助函数
function Write-Info { param($msg) Write-Host "[信息] $msg" -ForegroundColor Cyan }
function Write-OK { param($msg) Write-Host "[完成] $msg" -ForegroundColor Green }
function Write-Warn { param($msg) Write-Host "[警告] $msg" -ForegroundColor Yellow }
function Write-Err { param($msg) Write-Host "[错误] $msg" -ForegroundColor Red }

# 显示文件树菜单
function Show-FileMenu {
    param($SourcePath, $Depth = 0)
    $items = @()

    if ($Depth -gt 0) {
        $items += @{
            Display = ".. (返回上级)"
            Path = (Split-Path $SourcePath -Parent)
            IsUp = $true
        }
    }

    $dirs = Get-ChildItem $SourcePath -Directory | Sort-Object Name
    foreach ($dir in $dirs) {
        $fileCount = (Get-ChildItem $dir.FullName -Recurse -File).Count
        $items += @{
            Display = $dir.Name + "/ (" + $fileCount + " 个文件)"
            Path = $dir.FullName
            IsDir = $true
        }
    }

    $files = Get-ChildItem $SourcePath -File | Sort-Object Name
    foreach ($file in $files) {
        $items += @{
            Display = $file.Name
            Path = $file.FullName
            IsFile = $true
        }
    }

    Write-Host ""
    Write-Host $SourcePath -ForegroundColor White
    Write-Host ("-" * 50) -ForegroundColor Gray

    for ($i = 0; $i -lt $items.Count; $i++) {
        $item = $items[$i]
        if ($item.IsDir) {
            Write-Host ("  {0}. {1}" -f ($i + 1), $item.Display) -ForegroundColor Cyan
        } elseif ($item.IsFile) {
            Write-Host ("  {0}. {1}" -f ($i + 1), $item.Display) -ForegroundColor Green
        } else {
            Write-Host ("  {0}. {1}" -f ($i + 1), $item.Display) -ForegroundColor Gray
        }
    }
    Write-Host "  0. 返回" -ForegroundColor Gray
    Write-Host ""

    do {
        $choice = Read-Host "请选择"
        if ($choice -eq "0") { return $null }
        $idx = [int]$choice - 1
    } while ($idx -lt 0 -or $idx -ge $items.Count)

    return $items[$idx]
}

# 复制单个文件
function Copy-SingleFile {
    param($SrcFilePath, $DestPath, $RelativeTo)

    if (-not $RelativeTo) {
        $RelativeTo = Split-Path $SrcFilePath -Parent
    }

    $relativePath = $SrcFilePath.Substring($RelativeTo.Length)
    $destFile = Join-Path $DestPath $relativePath
    $destDir = Split-Path -Parent $destFile

    if (-not (Test-Path $destDir)) {
        New-Item -ItemType Directory -Path $destDir -Force | Out-Null
    }

    Copy-Item $SrcFilePath -Destination $destFile -Force
    Write-OK "已复制: $relativePath"
}

# 同步目录（覆盖模式：先删除目标目录再复制）
function Sync-FullDirectory {
    param($Name, $SrcPath, $DestPath)

    if (-not (Test-Path $SrcPath)) {
        Write-Err "源目录不存在: $SrcPath"
        return 0
    }

    # 先删除目标目录（如果存在）
    if (Test-Path $DestPath) {
        Remove-Item -Path $DestPath -Recurse -Force
        Write-Info "已删除旧目录: $DestPath"
    }

    # 创建目标目录
    New-Item -ItemType Directory -Path $DestPath -Force | Out-Null
    Write-Info "已创建目录: $DestPath"

    $copied = 0
    $files = Get-ChildItem $SrcPath -Recurse -File

    foreach ($file in $files) {
        $relativePath = $file.FullName.Substring($SrcPath.Length)
        $destFile = Join-Path $DestPath $relativePath
        $destDir = Split-Path -Parent $destFile

        if (-not (Test-Path $destDir)) {
            New-Item -ItemType Directory -Path $destDir -Force | Out-Null
        }

        Copy-Item $file.FullName -Destination $destFile -Force
        $copied++
    }

    Write-OK ("{0}: 已复制 {1} 个文件（覆盖模式）" -f $Name, $copied)
    return $copied
}

# 同步指定目录或文件
function Sync-SpecificItem {
    param($SrcPath, $DestPath, $TargetName, $RootPath, $Depth = 0)

    if (-not $RootPath) { $RootPath = $SrcPath }

    $item = Show-FileMenu $SrcPath $Depth
    if ($null -eq $item) { return 0 }

    if ($item.IsUp) {
        $parentPath = Split-Path $SrcPath -Parent
        return Sync-SpecificItem -SrcPath $parentPath -DestPath $DestPath -TargetName $TargetName -RootPath $RootPath -Depth ($Depth - 1)
    }
    elseif ($item.IsDir) {
        Write-Host ""
        Write-Host "选择操作:" -ForegroundColor White
        Write-Host "  1. 同步整个文件夹（覆盖）" -ForegroundColor Cyan
        Write-Host "  2. 浏览文件夹内容" -ForegroundColor Yellow
        Write-Host "  0. 返回" -ForegroundColor Gray
        $subChoice = Read-Host "请选择"

        if ($subChoice -eq "1") {
            $dirName = Split-Path $item.Path -Leaf
            $destDir = Join-Path $DestPath $item.Path.Substring($RootPath.Length)
            return Sync-FullDirectory -Name $dirName -SrcPath $item.Path -DestPath $destDir
        }
        elseif ($subChoice -eq "2") {
            return Sync-SpecificItem -SrcPath $item.Path -DestPath $DestPath -TargetName $TargetName -RootPath $RootPath -Depth ($Depth + 1)
        }
        return 0
    }
    elseif ($item.IsFile) {
        Copy-SingleFile -SrcFilePath $item.Path -DestPath $DestPath -RelativeTo $RootPath
        return 1
    }

    return 0
}

# 获取文件数量
function Get-FileCounts {
    $counts = @{}
    foreach ($key in $Targets.Keys) {
        $src = $Targets[$key].Source
        if (Test-Path $src) {
            $counts[$key] = (Get-ChildItem $src -Recurse -File).Count
        } else {
            $counts[$key] = 0
        }
    }
    return $counts
}

# 主菜单
function Show-MainMenu {
    Write-Host ""
    Write-Host "=== Guozhi Claude Code 同步工具 ===" -ForegroundColor White
    Write-Host "目标目录: $ClaudeUserDir" -ForegroundColor Gray
    Write-Host ("=" * 40) -ForegroundColor Gray

    $counts = Get-FileCounts
    $total = ($counts.Values | Measure-Object -Sum).Sum

    Write-Host ("  1. 全量同步 - {0} 个文件" -f $total) -ForegroundColor Cyan
    Write-Host ("  2. commands - {0} 个文件" -f $counts["commands"]) -ForegroundColor Yellow
    Write-Host ("  3. skills - {0} 个文件" -f $counts["skills"]) -ForegroundColor Yellow
    Write-Host ("  4. rules - {0} 个文件" -f $counts["rules"]) -ForegroundColor Yellow
    Write-Host "  0. 退出" -ForegroundColor Gray
    Write-Host ""

    do {
        $choice = Read-Host "请选择"
    } while ($choice -notmatch "^[0-4]$")

    return $choice
}

# 非交互模式
if ($NonInteractive) {
    $total = 0
    foreach ($key in $Targets.Keys) {
        $config = $Targets[$key]
        $count = Sync-FullDirectory -Name $key -SrcPath $config.Source -DestPath $config.Dest
        $total += $count
    }
    Write-Host ""
    Write-Host "完成: 共 $total 个文件" -ForegroundColor Green
    exit 0
}

# 交互模式
while ($true) {
    $choice = Show-MainMenu

    if ($choice -eq "0") {
        Write-Host "再见!" -ForegroundColor Cyan
        break
    }

    if ($choice -eq "1") {
        $total = 0
        foreach ($key in $Targets.Keys) {
            $config = $Targets[$key]
            $count = Sync-FullDirectory -Name $key -SrcPath $config.Source -DestPath $config.Dest
            $total += $count
        }
        Write-Host ""
        Write-Host "全量同步完成: 共 $total 个文件" -ForegroundColor Green
    }
    else {
        $keys = @("commands", "skills", "rules")
        $idx = [int]$choice - 2
        $key = $keys[$idx]
        $config = $Targets[$key]

        Write-Host ""
        Write-Host "选择同步方式:" -ForegroundColor White
        Write-Host "  1. 同步整个 $key 目录（覆盖）" -ForegroundColor Cyan
        Write-Host "  2. 选择具体文件/文件夹" -ForegroundColor Yellow
        Write-Host "  0. 返回" -ForegroundColor Gray
        $subChoice = Read-Host "请选择"

        if ($subChoice -eq "1") {
            Sync-FullDirectory -Name $key -SrcPath $config.Source -DestPath $config.Dest
        }
        elseif ($subChoice -eq "2") {
            $count = Sync-SpecificItem -SrcPath $config.Source -DestPath $config.Dest -TargetName $key
            Write-Host ""
            Write-Host "已同步: $count 个文件" -ForegroundColor Green
        }
    }

    Write-Host ""
}
