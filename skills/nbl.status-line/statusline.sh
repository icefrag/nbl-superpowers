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
# Use here-string to avoid echo subshell for each jq call
model=$(jq -r '.model.display_name // .model.id // "unknown"' <<< "$input")
current_dir=$(jq -r '.workspace.current_dir // empty' <<< "$input")
used_pct=$(jq -r '.context_window.used_percentage // empty' <<< "$input")
total_cost=$(jq -r '.cost.total_cost_usd // 0' <<< "$input")
duration_ms=$(jq -r '.cost.total_duration_ms // 0' <<< "$input")

# ── Helper Functions ──

# Get git status (staged/modified/untracked counts with colored output)
# Args:
#   $1 - repository path
# Output:
#   printed colored git status string (e.g. "~2" or "+1~3?2" or "clean")
get_git_status() {
  local repo_path="$1"
  local staged modified untracked output
  staged=$(git --no-optional-locks -C "$repo_path" diff --cached --numstat 2>/dev/null | wc -l | xargs)
  modified=$(git --no-optional-locks -C "$repo_path" diff --numstat 2>/dev/null | wc -l | xargs)
  untracked=$(git --no-optional-locks -C "$repo_path" ls-files --others --exclude-standard 2>/dev/null | wc -l | xargs)
  output=""
  [ "$staged" -gt 0 ]    && output="${output}${GREEN}+${staged}${RESET}"
  [ "$modified" -gt 0 ]  && output="${output}${YELLOW}~${modified}${RESET}"
  [ "$untracked" -gt 0 ] && output="${output}${RED}?${untracked}${RESET}"
  if [ -z "$output" ]; then
    output="${GREEN}clean${RESET}"
  fi
  printf "%s" "$output"
}

# Get current branch name for a repository
# Args:
#   $1 - repository path
# Output:
#   printed branch name or short commit hash
get_branch() {
  local repo_path="$1"
  local branch
  branch=$(git --no-optional-locks -C "$repo_path" branch --show-current 2>/dev/null)
  if [ -z "$branch" ]; then
    branch=$(git --no-optional-locks -C "$repo_path" rev-parse --short HEAD 2>/dev/null)
  fi
  printf "%s" "$branch"
}

# ── Project name and main worktree branch ──
# Always get project name from main worktree (first in worktree list)
proj_name=$(basename "$current_dir")
git_status_output=""
branch=""
worktree_list=""

# Check if we're in a git repository
if [ -n "$current_dir" ] && git rev-parse --git-dir >/dev/null 2>&1 -C "$current_dir"; then
  # Try to get worktree list once (reused later for worktree listing)
  worktree_list=$(git worktree list --porcelain 2>/dev/null)

  if [ -n "$worktree_list" ]; then
    # Extract main worktree path (first entry)
    main_wt_path=$(echo "$worktree_list" | grep "^worktree" | head -1 | sed 's/^worktree //')
    if [ -n "$main_wt_path" ] && git rev-parse --git-dir >/dev/null 2>&1 -C "$main_wt_path"; then
      # Found valid main worktree - use it
      proj_name=$(basename "$main_wt_path")
      branch=$(get_branch "$main_wt_path")
      git_status_output=$(get_git_status "$main_wt_path")
    else
      # Main worktree not valid - fall back to current directory
      branch=$(get_branch "$current_dir")
      git_status_output=$(get_git_status "$current_dir")
    fi
  else
    # git worktree not supported - fall back to current directory
    branch=$(get_branch "$current_dir")
    git_status_output=$(get_git_status "$current_dir")
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

if [ -n "$current_dir" ] && git rev-parse --git-dir >/dev/null 2>&1 -C "$current_dir"; then
  # Use cached worktree_list from earlier (only one git invocation total)
  if [ -n "$worktree_list" ]; then
    # Get main worktree path and normalize for .worktrees root detection
    main_worktree_path=$(echo "$worktree_list" | grep "^worktree" | head -1 | sed 's/^worktree //')
    # Replace backslashes with forward slashes using bash parameter expansion (no subshell)
    main_worktree_path_normalized=${main_worktree_path//\\//}
    worktrees_root="${main_worktree_path_normalized}/.worktrees/"

    # Parse porcelain format, extract path and branch
    worktree_index=0
    wt_path=""
    while IFS= read -r line; do
      if [[ "$line" == worktree\ * ]]; then
        wt_path="${line#worktree }"
      elif [[ "$line" == branch\ * ]]; then
        branch_full="${line#branch }"
        # Remove refs/heads/ prefix
        branch_name="${branch_full#refs/heads/}"
        # Replace backslashes with forward slashes using bash parameter expansion
        wt_path_normalized=${wt_path//\\//}
        # Only list worktrees under .worktrees/ directory (user-created sub worktrees)
        if [[ "$wt_path_normalized" == "$worktrees_root"* ]]; then
          wt_name=$(basename "$wt_path")
          worktree_index=$((worktree_index + 1))
          # Get worktree git status using git -C (no cd needed)
          wt_status=$(get_git_status "$wt_path")
          worktree_output="${worktree_output}  ${BLUE}${worktree_index}. ${wt_name} ${MAGENTA}→${RESET} ${MAGENTA}${branch_name}${RESET} ${wt_status}\n"
        fi
      fi
    done <<< "$worktree_list"

    # If we found worktrees, output the list
    if [ "$worktree_index" -gt 0 ]; then
      echo -e " Worktrees:"
      echo -ne "$worktree_output"
    fi
  fi
fi
