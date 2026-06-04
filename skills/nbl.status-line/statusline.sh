#!/usr/bin/env bash
# Custom multi-line status line with model, git, context usage, cost, and worktree info

input=$(cat)

# ANSI colors - bash built-in, no printf process needed
GREEN=$'\033[32m'
YELLOW=$'\033[33m'
RED=$'\033[31m'
CYAN=$'\033[36m'
RESET=$'\033[0m'
BLUE=$'\033[34m'
MAGENTA=$'\033[35m'

# ── Extract data from input ──
# Extract all fields in one jq call, use @sh for proper shell quoting (handles spaces/special chars)
# Note: All values must be strings for shell variable assignment, so convert numbers with tostring
if ! command -v jq >/dev/null 2>&1; then
  model="unknown"
  current_dir=""
  used_pct=""
  total_cost="0"
  duration_ms="0"
else
  eval "$(jq -r '
  "model=" + ((.model.display_name // .model.id // "unknown") | tostring | @sh) + "\n" +
  "current_dir=" + ((.workspace.current_dir // "") | tostring | @sh) + "\n" +
  "used_pct=" + (.context_window.used_percentage // "" | tostring | @sh) + "\n" +
  "total_cost=" + (.cost.total_cost_usd // 0 | tostring | @sh) + "\n" +
  "duration_ms=" + (.cost.total_duration_ms // 0 | tostring | @sh)
  ' <<< "$input")"
fi

# Normalize Windows backslashes to forward slashes for cross-platform compatibility
current_dir=${current_dir//\\//}

# Default model name if empty
[[ -z "$model" ]] && model="unknown"

# ── Helper Functions ──

# Get git status (staged/modified/untracked counts with colored output)
# Args:
#   $1 - repository path
# Output:
#   printed colored git status string (e.g. "~2" or "+1~3?2" or "clean")
get_git_status() {
  local repo_path="$1"
  local staged=0 modified=0 untracked=0 line first_char

  # Single git invocation with porcelain format - count with bash builtin (no extra processes)
  while IFS= read -r line; do
    first_char=${line:0:1}
    case "$first_char" in
      ' ') ((modified++)) ;;  # Unstaged modification (first char is space)
      '?') ((untracked++)) ;; # Untracked file
      *) ((staged++)) ;;      # Staged change (first char non-space)
    esac
  done < <(git --no-optional-locks -C "$repo_path" status --porcelain=v1 2>/dev/null)

  output=""
  [[ "$staged" -gt 0 ]]    && output="${output}${GREEN}+${staged}${RESET}"
  [[ "$modified" -gt 0 ]]  && output="${output}${YELLOW}~${modified}${RESET}"
  [[ "$untracked" -gt 0 ]] && output="${output}${RED}?${untracked}${RESET}"
  if [[ -z "$output" ]]; then
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
  # Fallback if both commands fail (path issue on Windows)
  if [ -z "$branch" ]; then
    branch="unknown"
  fi
  printf "%s" "$branch"
}

# Always get project name from main worktree (first in worktree list)
proj_name="${current_dir##*/}"
git_status_output=""
branch=""
worktree_list=""
is_git_repo=false

# Check if we're in a git repository
if [[ -n "$current_dir" ]] && git -C "$current_dir" rev-parse --git-dir >/dev/null 2>&1; then
  is_git_repo=true
  # Try to get worktree list once (reused later for worktree listing)
  worktree_list=$(git -C "$current_dir" worktree list --porcelain 2>/dev/null)

  if [[ -n "$worktree_list" ]]; then
    # Extract main worktree path (first entry) - use bash native parsing to preserve backslashes
    main_wt_path=""
    while IFS= read -r line; do
      if [[ "$line" == worktree\ * ]]; then
        main_wt_path="${line#worktree }"
        break
      fi
    done <<< "$worktree_list"
    # Normalize Windows backslashes to forward slashes BEFORE git check
    main_wt_path=${main_wt_path//\\//}
    if [[ -n "$main_wt_path" ]] && git -C "$main_wt_path" rev-parse --git-dir >/dev/null 2>&1; then
      # Found valid main worktree - use it
      proj_name="${main_wt_path##*/}"
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
if [[ -n "$branch" ]]; then
  first_line="${first_line} | 🌿 ${CYAN}${branch}${RESET} ${git_status_output}"
fi
printf '%s\n' "$first_line"

# ── Second line: Progress bar + Percentage + Cost + Duration ──
if [[ -n "$used_pct" ]]; then
  used_int=$(printf "%.0f" "$used_pct")

  # Color based on usage
  if [[ "$used_int" -ge 90 ]]; then
    bar_color="$RED"
  elif [[ "$used_int" -ge 70 ]]; then
    bar_color="$YELLOW"
  else
    bar_color="$GREEN"
  fi

  # Create progress bar (10 characters wide)
  bar_width=10
  filled=$(( (used_int * bar_width + 99) / 100 ))
  empty=$((bar_width - filled))

  bar_filled=$(printf '%*s' "$filled" '')
  bar_filled=${bar_filled// /█}
  bar_empty=$(printf '%*s' "$empty" '')
  bar_empty=${bar_empty// /░}
  bar="${bar_filled}${bar_empty}"

  # Format cost
  cost_fmt=$(printf "%.2f" "$total_cost")

  # Format duration
  if [[ "$duration_ms" -gt 0 ]]; then
    mins=$((duration_ms / 60000))
    secs=$(((duration_ms % 60000) / 1000))
    duration_fmt="${mins}m ${secs}s"
  else
    duration_fmt="0m 0s"
  fi

  second_line="${bar_color}${bar}${RESET} ${bar_color}${used_int}%${RESET} | ${YELLOW}\$${cost_fmt}${RESET} | ⏱️ ${duration_fmt}"
  printf '%s\n' "$second_line"
fi

# ── Worktree List ──
worktree_output=""

if [[ "$is_git_repo" == "true" ]]; then
  # Use cached worktree_list from earlier (only one git invocation total)
  if [[ -n "$worktree_list" ]]; then
    # Get main worktree path from already-parsed variable (already normalized) - no re-extraction needed
    main_worktree_path_normalized="$main_wt_path"
    worktrees_root="${main_worktree_path_normalized}/.worktrees/"

    # Parse porcelain format, extract path and branch
    worktree_index=0
    wt_path=""
    while IFS= read -r line; do
      if [[ "$line" == worktree\ * ]]; then
        wt_path="${line#worktree }"
        wt_path=${wt_path//\\//}
      elif [[ "$line" == branch\ * ]]; then
        branch_full="${line#branch }"
        # Remove refs/heads/ prefix
        branch_name="${branch_full#refs/heads/}"
        # Already normalized path above
        # Only list worktrees under .worktrees/ directory (user-created sub worktrees)
        if [[ "$wt_path" == "$worktrees_root"* ]]; then
          wt_name="${wt_path##*/}"
          worktree_index=$((worktree_index + 1))
          # Get worktree git status using git -C (no cd needed)
          wt_status=$(get_git_status "$wt_path")
          worktree_output="${worktree_output}  ${BLUE}${worktree_index}. 📂 ${wt_name} ${MAGENTA}→${RESET} 🌿 ${MAGENTA}${branch_name}${RESET} ${wt_status}\n"
        fi
      fi
    done <<< "$worktree_list"

    # If we found worktrees, output the list
    if [[ "$worktree_index" -gt 0 ]]; then
      printf '%s\n' " Worktrees:"
      printf "$worktree_output"
    fi
  fi
fi
