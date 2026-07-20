#!/usr/bin/env bash
# Godot Git Merge Manager — TUI for merging two dev branches into main
# without stepping on each other's HEAD.
set -uo pipefail

# ---- CONFIG: edit these to match your actual branch names (case sensitive) ----
MAIN_BRANCH="master"
BRANCH_A="Filip"
BRANCH_B="serdar-changes"
# --------------------------------------------------------------------------------

RED=$'\033[0;31m'; GREEN=$'\033[0;32m'; YELLOW=$'\033[1;33m'
BLUE=$'\033[0;34m'; CYAN=$'\033[0;36m'; BOLD=$'\033[1m'; RESET=$'\033[0m'

pause() { read -rp "$(printf "%sPress Enter to continue...%s" "$CYAN" "$RESET")"; }

header() {
  clear
  echo -e "${BOLD}${BLUE}╔══════════════════════════════════════════════╗${RESET}"
  echo -e "${BOLD}${BLUE}║        Godot Git Merge Manager (macOS)        ║${RESET}"
  echo -e "${BOLD}${BLUE}╚══════════════════════════════════════════════╝${RESET}"
  echo -e "${CYAN}Repo:${RESET} $(basename "$(git rev-parse --show-toplevel 2>/dev/null)")"
  echo -e "${CYAN}Current branch:${RESET} $(git branch --show-current)"
  echo
}

check_repo() {
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo -e "${RED}Not a git repository. cd into your project first.${RESET}"
    exit 1
  fi
}

branch_exists() { git show-ref --verify --quiet "refs/heads/$1"; }

ensure_branches() {
  for b in "$MAIN_BRANCH" "$BRANCH_A" "$BRANCH_B"; do
    if ! branch_exists "$b"; then
      echo -e "${RED}Branch '$b' does not exist locally. Edit the CONFIG section at the top of this script, or run: git branch $b${RESET}"
      exit 1
    fi
  done
}

# Shows a colorized summary + full diff of whatever's currently uncommitted.
view_changes() {
  echo
  echo -e "${BOLD}Files changed:${RESET}"
  git status --short | while IFS= read -r line; do
    code="${line:0:2}"
    file="${line:3}"
    case "$code" in
      "??") echo -e "  ${CYAN}[new]${RESET}      $file" ;;
      *D*)  echo -e "  ${RED}[deleted]${RESET}  $file" ;;
      *M*)  echo -e "  ${YELLOW}[modified]${RESET} $file" ;;
      *A*)  echo -e "  ${GREEN}[added]${RESET}    $file" ;;
      *)    echo -e "  [${code}] $file" ;;
    esac
  done
  echo
  read -rp "View full line-by-line diff (green=added, red=removed)? [y/N]: " d
  if [[ "$d" =~ ^[Yy]$ ]]; then
    # Force color even though output isn't a tty, page with less -R to keep colors
    if command -v less >/dev/null 2>&1; then
      git -c color.ui=always diff | less -R
      echo
      # untracked new files have no diff, show their content separately if any
      new_files=$(git status --short | awk '/^\?\?/{print $2}')
      if [[ -n "$new_files" ]]; then
        echo -e "${CYAN}New (untracked) files aren't shown in 'git diff'. Preview them? [y/N]:${RESET}"
        read -rp "" nf
        if [[ "$nf" =~ ^[Yy]$ ]]; then
          for f in $new_files; do
            echo -e "${GREEN}${BOLD}--- $f (new file) ---${RESET}"
            [[ -f "$f" ]] && git -c color.ui=always diff --no-index -- /dev/null "$f" | less -R
          done
        fi
      fi
    else
      git -c color.ui=always diff
    fi
  fi
}

check_clean() {
  if [[ -n "$(git status --porcelain)" ]]; then
    echo -e "${YELLOW}You have uncommitted changes.${RESET}"
    while true; do
      echo "1) View what changed"
      echo "2) Stash changes and continue"
      echo "3) Commit changes now"
      echo "4) Abort"
      read -rp "Choose [1-4]: " c
      case "$c" in
        1) view_changes ;;
        2) git stash push -m "auto-stash before merge $(date)" && echo -e "${GREEN}Stashed.${RESET}"; break ;;
        3) git add -A && read -rp "Commit message: " m && git commit -m "$m"; break ;;
        4) exit 0 ;;
        *) echo "Invalid" ;;
      esac
    done
  fi
}

fetch_all() {
  echo -e "${CYAN}Fetching from origin...${RESET}"
  git fetch --all --prune
}

# Returns 0 if fully resolved, 1 if aborted
resolve_conflicts() {
  local incoming_branch="$1"
  while true; do
    local files
    files=$(git diff --name-only --diff-filter=U)
    if [[ -z "$files" ]]; then
      echo -e "${GREEN}No more conflicts.${RESET}"
      return 0
    fi
    echo -e "${RED}${BOLD}Merge conflicts:${RESET}"
    echo "$files" | sed 's/^/  - /'
    echo
    echo "1) Open conflicted files in \$EDITOR (resolve manually)"
    echo "2) Take ${MAIN_BRANCH}'s version for ALL conflicts (ours)"
    echo "3) Take ${incoming_branch}'s version for ALL conflicts (theirs)"
    echo "4) Decide per file (with colorized diff preview)"
    echo "5) Abort merge"
    read -rp "Choose [1-5]: " choice
    case "$choice" in
      1) "${EDITOR:-nano}" $files ;;
      2) for f in $files; do git checkout --ours -- "$f"; git add "$f"; done ;;
      3) for f in $files; do git checkout --theirs -- "$f"; git add "$f"; done ;;
      4)
        for f in $files; do
          echo -e "${YELLOW}File:${RESET} $f"
          echo "   d) show conflict diff   o) ours ($MAIN_BRANCH)   t) theirs ($incoming_branch)   e) edit manually   s) skip"
          read -rp "   Choice: " fc
          case "$fc" in
            d)
              git -c color.ui=always diff -- "$f" | less -R
              echo "   o) ours   t) theirs   e) edit manually   s) skip"
              read -rp "   Choice: " fc2
              case "$fc2" in
                o) git checkout --ours -- "$f"; git add "$f" ;;
                t) git checkout --theirs -- "$f"; git add "$f" ;;
                e) "${EDITOR:-nano}" "$f" ;;
                *) ;;
              esac
              ;;
            o) git checkout --ours -- "$f"; git add "$f" ;;
            t) git checkout --theirs -- "$f"; git add "$f" ;;
            e) "${EDITOR:-nano}" "$f" ;;
            *) ;;
          esac
        done
        ;;
      5) git merge --abort; echo -e "${YELLOW}Merge aborted.${RESET}"; return 1 ;;
      *) echo "Invalid choice" ;;
    esac
    if [[ -z "$(git diff --name-only --diff-filter=U)" ]]; then
      return 0
    fi
  done
}

do_merge() {
  local branch="$1"
  echo -e "${CYAN}Merging ${branch} into ${MAIN_BRANCH}...${RESET}"
  git checkout "$MAIN_BRANCH" || return 1
  git pull origin "$MAIN_BRANCH" --ff-only 2>/dev/null || echo -e "${YELLOW}(no fast-forward pull available, continuing with local $MAIN_BRANCH)${RESET}"

  if git merge --no-ff "$branch" -m "Merge $branch into $MAIN_BRANCH"; then
    echo -e "${GREEN}Merged ${branch} cleanly, no conflicts.${RESET}"
  else
    if resolve_conflicts "$branch"; then
      if git commit --no-edit; then
        echo -e "${GREEN}Conflicts resolved, merge committed.${RESET}"
      else
        echo -e "${RED}Commit failed — check 'git status'.${RESET}"
        return 1
      fi
    else
      return 1
    fi
  fi

  read -rp "Push ${MAIN_BRANCH} to origin now? [y/N]: " p
  [[ "$p" =~ ^[Yy]$ ]] && git push origin "$MAIN_BRANCH"
  return 0
}

sync_branch_from_main() {
  local branch="$1"
  read -rp "Update ${branch} with the latest ${MAIN_BRANCH} now (recommended, keeps it conflict-free next time)? [y/N]: " r
  if [[ "$r" =~ ^[Yy]$ ]]; then
    git checkout "$branch"
    if git merge "$MAIN_BRANCH" -m "Sync $MAIN_BRANCH into $branch"; then
      echo -e "${GREEN}${branch} synced.${RESET}"
    else
      resolve_conflicts "$MAIN_BRANCH" && git commit --no-edit
    fi
    read -rp "Push ${branch} to origin? [y/N]: " p2
    [[ "$p2" =~ ^[Yy]$ ]] && git push origin "$branch"
    git checkout "$MAIN_BRANCH"
  fi
}

full_sync() {
  do_merge "$BRANCH_A" && sync_branch_from_main "$BRANCH_B"
  do_merge "$BRANCH_B" && sync_branch_from_main "$BRANCH_A"
}

show_status() {
  header
  echo -e "${BOLD}Branch status vs origin:${RESET}"
  for b in "$MAIN_BRANCH" "$BRANCH_A" "$BRANCH_B"; do
    ahead=$(git rev-list --count "origin/$b..$b" 2>/dev/null || echo "?")
    behind=$(git rev-list --count "$b..origin/$b" 2>/dev/null || echo "?")
    echo -e "  $b: ahead $ahead / behind $behind"
  done
  echo
  echo -e "${BOLD}Recent history (all branches):${RESET}"
  git log --oneline --graph --decorate -n 12 --all
  echo
  pause
}

main_menu() {
  while true; do
    header
    echo "1) Merge ${BRANCH_A} -> ${MAIN_BRANCH}"
    echo "2) Merge ${BRANCH_B} -> ${MAIN_BRANCH}"
    echo "3) Full sync (${BRANCH_A} then ${BRANCH_B} into ${MAIN_BRANCH}, then sync branches back)"
    echo "4) Show branch status / log"
    echo "5) Fetch from origin"
    echo "6) View uncommitted changes"
    echo "7) Exit"
    echo
    read -rp "Choose an option [1-7]: " opt
    case "$opt" in
      1) check_clean; do_merge "$BRANCH_A"; pause ;;
      2) check_clean; do_merge "$BRANCH_B"; pause ;;
      3) check_clean; full_sync; pause ;;
      4) show_status ;;
      5) fetch_all; pause ;;
      6) header; view_changes; pause ;;
      7) echo "Bye!"; exit 0 ;;
      *) echo "Invalid option"; pause ;;
    esac
  done
}

check_repo
ensure_branches
main_menu