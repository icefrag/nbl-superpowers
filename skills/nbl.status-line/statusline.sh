#!/bin/bash
# Custom multi-line status line with model, git, context usage, cost, and worktree info

input=$(cat)

# ── Colors ──
GREEN=$(printf '\033[32m')
YELLOW=$(printf '\033[33m')
RED=$(printf '\033[31m')
CYAN=$(printf '\033[36m')
RESET=$(printf '\033[0m')

# ── Extract data from input ──
model=$(echo "$input" | jq -r '.model.display_name // .model.id // "unknown"')
current_dir=$(echo "$input" | jq -r '.workspace.current_dir // empty')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
total_cost=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')
duration_ms=$(echo "$input" | jq -r '.cost.total_duration_ms // 0')

# ── Project name ──
# Use basename to handle both forward slash (Linux/macOS) and backslash (Windows)
proj_name=$(basename "$current_dir")

# ── Git status ──
git_status_output=""
branch=""
if [ -n "$current_dir" ] && cd "$current_dir" 2>/dev/null && git rev-parse --git-dir > /dev/null 2>&1; then
  # 获取主 worktree 路径（worktree list 的第一个项）
  # 确保第一行始终显示主 worktree 的分支，即使当前工作目录在子 worktree 中
  main_wt_path=$(git worktree list --porcelain 2>/dev/null | grep "^worktree" | head -1 | sed 's/^worktree //')
  if [ -n "$main_wt_path" ]; then
    cd "$main_wt_path" 2>/dev/null || cd "$current_dir" 2>/dev/null
  fi

  branch=$(git --no-optional-locks branch --show-current 2>/dev/null)
  [ -z "$branch" ] && branch=$(git --no-optional-locks rev-parse --short HEAD 2>/dev/null)

  staged=$(git --no-optional-locks diff --cached --numstat 2>/dev/null | wc -l | tr -d ' ')
  modified=$(git --no-optional-locks diff --numstat 2>/dev/null | wc -l | tr -d ' ')
  untracked=$(git --no-optional-locks ls-files --others --exclude-standard 2>/dev/null | wc -l | tr -d ' ')

  git_status_output=""
  [ "$staged" -gt 0 ]    && git_status_output="${git_status_output}${GREEN}+${staged}${RESET}"
  [ "$modified" -gt 0 ]  && git_status_output="${git_status_output}${YELLOW}~${modified}${RESET}"
  [ "$untracked" -gt 0 ] && git_status_output="${git_status_output}${RED}?${untracked}${RESET}"

  if [ -z "$git_status_output" ]; then
    git_status_output="${GREEN}clean${RESET}"
  fi
fi

# ── First line: Model + Project + Branch + Git Status ──
first_line="${CYAN}[${model}]${RESET} 📁 ${proj_name}"
if [ -n "$branch" ]; then
  first_line="${first_line} | 🌿 ${CYAN}${branch}${RESET} ${git_status_output}"
fi
echo -e "$first_line"

# ── Second line: Progress bar + Percentage + Cost + Duration ──
if [ -n "$used_pct" ]; then
  used_int=$(printf "%.0f" "$used_pct")

  # Color based on usage
  if [ "$used_int" -ge 90 ]; then
    bar_color="$RED"
  elif [ "$used_int" -ge 70 ]; then
    bar_color="$YELLOW"
  else
    bar_color="$GREEN"
  fi

  # Create progress bar (10 characters wide)
  bar_width=10
  filled=$(( (used_int * bar_width + 99) / 100 ))
  empty=$((bar_width - filled))

  bar=""
  for ((i=0; i<filled; i++)); do
    bar="${bar}█"
  done
  for ((i=0; i<empty; i++)); do
    bar="${bar}░"
  done

  # Format cost
  cost_fmt=$(printf "$%.2f" "$total_cost")

  # Format duration
  if [ "$duration_ms" -gt 0 ]; then
    mins=$((duration_ms / 60000))
    secs=$(((duration_ms % 60000) / 1000))
    duration_fmt="${mins}m ${secs}s"
  else
    duration_fmt="0m 0s"
  fi

  second_line="${bar_color}${bar}${RESET} ${bar_color}${used_int}%${RESET} | ${YELLOW}${cost_fmt}${RESET} | ⏱️ ${duration_fmt}"
  echo -e "$second_line"
fi

# ── Worktree colors (独立于第一行的颜色方案) ──
BLUE=$(printf '\033[34m')
MAGENTA=$(printf '\033[35m')

# ── Worktree List (从第三行开始输出) ──
worktree_output=""

if [ -n "$current_dir" ] && cd "$current_dir" 2>/dev/null && git rev-parse --git-dir > /dev/null 2>&1; then
  # 使用 --porcelain 格式获取 worktree 列表
  worktree_list=$(git worktree list --porcelain 2>/dev/null)

  if [ -n "$worktree_list" ]; then
    # 获取主工作区路径（第一个 worktree），然后定位 .worktrees 目录
    main_worktree_path=$(echo "$worktree_list" | grep "^worktree" | head -1 | sed 's/^worktree //')
    main_worktree_path_normalized=$(echo "$main_worktree_path" | sed 's/\\/\//g')
    worktrees_root="${main_worktree_path_normalized}/.worktrees/"

    # 解析 porcelain 格式，提取路径和分支
    worktree_index=0
    while IFS= read -r line; do
      if [[ "$line" == worktree\ * ]]; then
        wt_path="${line#worktree }"
        wt_path_normalized=$(echo "$wt_path" | sed 's/\\/\//g')
      elif [[ "$line" == branch\ * ]]; then
        branch_full="${line#branch }"
        # 去除 refs/heads/ 前缀
        branch_name="${branch_full#refs/heads/}"
        # 检查路径是否在主工作区的 .worktrees/ 目录下
        if [[ "$wt_path_normalized" == "$worktrees_root"* ]]; then
          # 提取 worktree 目录名
          wt_name=$(basename "$wt_path")
          worktree_index=$((worktree_index + 1))

          # 获取 worktree 的 git 状态
          wt_status=""
          if cd "$wt_path" 2>/dev/null; then
            wt_staged=$(git --no-optional-locks diff --cached --numstat 2>/dev/null | wc -l | tr -d ' ')
            wt_modified=$(git --no-optional-locks diff --numstat 2>/dev/null | wc -l | tr -d ' ')
            wt_untracked=$(git --no-optional-locks ls-files --others --exclude-standard 2>/dev/null | wc -l | tr -d ' ')
            [ "$wt_staged" -gt 0 ]    && wt_status="${wt_status}${GREEN}+${wt_staged}${RESET}"
            [ "$wt_modified" -gt 0 ]  && wt_status="${wt_status}${YELLOW}~${wt_modified}${RESET}"
            [ "$wt_untracked" -gt 0 ] && wt_status="${wt_status}${RED}?${wt_untracked}${RESET}"
            if [ -z "$wt_status" ]; then
              wt_status="${GREEN}clean${RESET}"
            fi
            cd "$current_dir" 2>/dev/null
          fi

          worktree_output="${worktree_output}  ${BLUE}${worktree_index}. ${wt_name} ${MAGENTA}→${RESET} ${MAGENTA}${branch_name}${RESET} ${wt_status}\n"
        fi
      fi
    done <<< "$worktree_list"

    # 如果有 worktree，输出标题和列表
    if [ "$worktree_index" -gt 0 ]; then
      echo -e " Worktrees:"
      echo -ne "$worktree_output"
    fi
  fi
fi
