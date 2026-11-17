#!/usr/bin/env bash
# dotfiles installer — see README.md
#
#   ./install.sh                 interactive: pick modules + options (arrow-key menus)
#   ./install.sh --all [-y]      install every default module, no questions with -y
#   ./install.sh zsh tmux        install only these modules
#   ./install.sh --dry-run ...   show what would happen
#   ./install.sh --list          list modules
set -Eeuo pipefail

DOTFILES_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd -P)"
export DOTFILES_DIR
# shellcheck source=lib/common.sh
source "$DOTFILES_DIR/lib/common.sh"
# shellcheck source=lib/theme.sh
[[ -f $DOTFILES_DIR/lib/theme.sh ]] && source "$DOTFILES_DIR/lib/theme.sh"
# shellcheck source=lib/ui.sh
source "$DOTFILES_DIR/lib/ui.sh"

MODULES=()               # registration order
declare -A MOD_DESC=() MOD_DEFAULT=()

# Called by each modules/*.sh file.
module() { # name default(on|off) description
  MODULES+=("$1"); MOD_DEFAULT[$1]=$2; MOD_DESC[$1]=$3
}

usage() {
  sed -n '2,9p' "$0" | sed 's/^# \{0,1\}//'
  cat <<EOF

Options:
  -a, --all          select all default modules
  -y, --yes          don't ask; use defaults / saved choices
  -n, --dry-run      print actions without changing anything
      --no-packages  skip apt/sudo steps (only links + user-level installs)
  -l, --list         list modules
  -h, --help         this help

Choices can be preset with env vars, e.g.
  THEME=gruvbox-dark TMUX_STATUS=minimal ./install.sh --all -y
EOF
}

for f in "$DOTFILES_DIR"/modules/*.sh; do
  # shellcheck source=/dev/null
  source "$f"
done

SELECT_ALL=0
REQUESTED=()
while (( $# )); do
  case $1 in
    -a|--all) SELECT_ALL=1 ;;
    -y|--yes) ASSUME_YES=1 ;;
    -n|--dry-run) DRY_RUN=1 ;;
    --no-packages) NO_PACKAGES=1 ;;
    -l|--list)
      for m in "${MODULES[@]}"; do printf '  %-10s %-4s %s\n' "$m" "${MOD_DEFAULT[$m]}" "${MOD_DESC[$m]}"; done
      exit 0 ;;
    -h|--help) usage; exit 0 ;;
    -*) die "unknown option: $1 (see --help)" ;;
    *) [[ -n ${MOD_DESC[$1]:-} ]] || die "unknown module: $1 (see --list)"; REQUESTED+=("$1") ;;
  esac
  shift
done
export DRY_RUN ASSUME_YES NO_PACKAGES

check_os

# ------------------------------------------------------------- selection ---
SELECTED=()
if (( ${#REQUESTED[@]} )); then
  SELECTED=("${REQUESTED[@]}")
elif (( SELECT_ALL )) || (( ASSUME_YES )); then
  for m in "${MODULES[@]}"; do [[ ${MOD_DEFAULT[$m]} == on ]] && SELECTED+=("$m"); done
elif [[ -t 0 ]]; then
  trap '_ui_cleanup; printf "\n"; exit 130' INT
  items=()
  for m in "${MODULES[@]}"; do items+=("$m" "${MOD_DESC[$m]}" "${MOD_DEFAULT[$m]}"); done
  choice=$(ui_multi "What should be installed?" "${items[@]}") || die "cancelled"
  mapfile -t SELECTED <<<"$choice"
else
  usage; exit 1
fi

# keep registration order and always include base
declare -A _want=([base]=1)
for m in "${SELECTED[@]}"; do [[ -n $m ]] && _want[$m]=1; done
ORDERED=()
for m in "${MODULES[@]}"; do [[ -n ${_want[$m]:-} ]] && ORDERED+=("$m"); done

step "Modules: ${ORDERED[*]}"
(( DRY_RUN )) && warn "dry-run: nothing will be changed"
(( NO_PACKAGES )) && warn "--no-packages: apt/sudo steps are skipped"

MANUAL_FILE=$(mktemp)
export MANUAL_FILE
trap 'rm -f "$MANUAL_FILE"' EXIT

# ------------------------------------------------------ configure (asks) ---
for m in "${ORDERED[@]}"; do
  if declare -F "${m}_configure" >/dev/null; then "${m}_configure"; fi
done

sudo_init

# --------------------------------------------------------------- install ---
FAILED=()
for m in "${ORDERED[@]}"; do
  step "$m — ${MOD_DESC[$m]}"
  if ! ( set -Eeuo pipefail; "${m}_install" ); then
    err "module $m failed (continuing)"
    FAILED+=("$m")
  fi
done
# Modules run in subshells, so manual steps are collected in a file.
[[ -s $MANUAL_FILE ]] && mapfile -t MANUAL_STEPS <"$MANUAL_FILE"

# --------------------------------------------------------------- summary ---
step "Done"
(( ${#FAILED[@]} )) && err "failed modules: ${FAILED[*]} (re-run: ./install.sh ${FAILED[*]})"
[[ -d $BACKUP_DIR ]] && info "backups of replaced files: $BACKUP_DIR"
if (( ${#MANUAL_STEPS[@]} )); then
  printf '\n%sThings left for you to do:%s\n' "$_c_bold" "$_c_reset"
  for s in "${MANUAL_STEPS[@]}"; do printf '  [ ] %s\n' "$s"; done
fi
printf '\nOpen a new terminal (or run: exec zsh) to load everything.\n'
(( ${#FAILED[@]} == 0 ))
