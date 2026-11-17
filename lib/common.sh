# shellcheck shell=bash
# Shared helpers for install.sh, modules/*.sh and the `dot` command.
# Expects DOTFILES_DIR to be set by the caller.

: "${DOTFILES_DIR:?DOTFILES_DIR must be set}"
: "${DRY_RUN:=0}"
: "${ASSUME_YES:=0}"
: "${NO_PACKAGES:=0}"

STATE_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles"
STATE_FILE="$STATE_DIR/config"
LOCAL_BIN="$HOME/.local/bin"
BACKUP_DIR="${BACKUP_DIR:-$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)}"
MANUAL_STEPS=()

# ---------------------------------------------------------------- logging ---
if [[ -t 1 ]]; then
  _c_reset=$'\e[0m' _c_bold=$'\e[1m' _c_dim=$'\e[2m'
  _c_red=$'\e[31m' _c_green=$'\e[32m' _c_yellow=$'\e[33m' _c_blue=$'\e[34m' _c_mag=$'\e[35m'
else
  _c_reset='' _c_bold='' _c_dim='' _c_red='' _c_green='' _c_yellow='' _c_blue='' _c_mag=''
fi
step() { printf '\n%s==>%s %s%s%s\n' "$_c_mag$_c_bold" "$_c_reset" "$_c_bold" "$*" "$_c_reset"; }
info() { printf '%s  ->%s %s\n' "$_c_blue" "$_c_reset" "$*"; }
ok()   { printf '%s  ok%s %s\n' "$_c_green" "$_c_reset" "$*"; }
warn() { printf '%s  !!%s %s\n' "$_c_yellow" "$_c_reset" "$*" >&2; }
err()  { printf '%s  xx%s %s\n' "$_c_red" "$_c_reset" "$*" >&2; }
die()  { err "$*"; exit 1; }
# Remember something the user must do by hand (printed at the end).
manual() {
  if [[ -n ${MANUAL_FILE:-} ]]; then echo "$*" >>"$MANUAL_FILE"; else MANUAL_STEPS+=("$*"); fi
}

# ---------------------------------------------------------------- helpers ---
has() { command -v "$1" >/dev/null 2>&1; }

# Run a command, or just print it in dry-run mode.
run() {
  if (( DRY_RUN )); then
    printf '%s  [dry-run]%s %s\n' "$_c_dim" "$_c_reset" "$*"
  else
    "$@"
  fi
}

# Yes/no question. Returns default without asking when ASSUME_YES=1 or no tty.
# usage: ask "Question?" [y|n]
ask() {
  local q=$1 def=${2:-y} reply
  if (( ASSUME_YES )) || [[ ! -t 0 ]]; then [[ $def == y ]]; return; fi
  if has whiptail; then
    local args=(--title "dotfiles" --yesno "$q" 10 70)
    [[ $def == n ]] && args=(--defaultno "${args[@]}")
    whiptail "${args[@]}" 3>&1 1>&2 2>&3
    return
  fi
  read -r -p "$q [$( [[ $def == y ]] && echo Y/n || echo y/N )] " reply
  reply=${reply:-$def}
  [[ $reply =~ ^[Yy] ]]
}

# Pick one value out of a list. Prints the chosen value.
# usage: choose "Question" default opt1 "desc1" opt2 "desc2" ...
choose() {
  local q=$1 def=$2; shift 2
  if (( ASSUME_YES )) || [[ ! -t 0 ]]; then echo "$def"; return; fi
  if has whiptail; then
    local items=() tag desc
    while (( $# )); do
      tag=$1 desc=$2; shift 2
      items+=("$tag" "$desc" "$([[ $tag == "$def" ]] && echo ON || echo OFF)")
    done
    whiptail --title "dotfiles" --radiolist "$q" 18 76 8 "${items[@]}" 3>&1 1>&2 2>&3 || echo "$def"
    return
  fi
  local opts=() i=1 reply
  printf '%s\n' "$q" >&2
  while (( $# )); do
    opts+=("$1"); printf '  %d) %s - %s%s\n' "$i" "$1" "$2" "$([[ $1 == "$def" ]] && echo ' (default)')" >&2
    shift 2; ((i++))
  done
  read -r -p "Choice: " reply
  if [[ $reply =~ ^[0-9]+$ ]] && (( reply >= 1 && reply <= ${#opts[@]} )); then
    echo "${opts[reply-1]}"
  else
    echo "$def"
  fi
}

# ------------------------------------------------------------------ state ---
# Persisted choices (theme, tmux status, ...) live in ~/.config/dotfiles/config
state_get() { # key [default]
  local v
  [[ -f $STATE_FILE ]] && v=$(sed -n "s/^$1=//p" "$STATE_FILE" | tail -1)
  echo "${v:-${2:-}}"
}
state_set() { # key value
  (( DRY_RUN )) && { info "[dry-run] state $1=$2"; return; }
  mkdir -p "$STATE_DIR"
  touch "$STATE_FILE"
  if grep -q "^$1=" "$STATE_FILE"; then
    sed -i "s|^$1=.*|$1=$2|" "$STATE_FILE"
  else
    echo "$1=$2" >>"$STATE_FILE"
  fi
}

# ------------------------------------------------------------------- sudo ---
SUDO=""
sudo_init() {
  (( NO_PACKAGES )) && return
  if (( EUID == 0 )); then SUDO=""; return; fi
  has sudo || die "sudo is required to install packages (or use --no-packages)"
  SUDO="sudo"
  (( DRY_RUN )) && return
  info "Asking for sudo password once (kept alive while installing)"
  sudo -v || die "sudo authentication failed"
  ( while kill -0 "$$" 2>/dev/null; do sudo -n true; sleep 50; done ) 2>/dev/null &
}

# ------------------------------------------------------------------- apt ----
_APT_UPDATED=0
apt_update() {
  (( _APT_UPDATED )) && return
  run $SUDO apt-get update -qq
  _APT_UPDATED=1
}
pkg_installed() { dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q "install ok installed"; }

# Install apt packages that are not yet installed.
apt_install() {
  if (( NO_PACKAGES )); then info "skipping apt (--no-packages): $*"; return; fi
  local missing=() p
  for p in "$@"; do pkg_installed "$p" || missing+=("$p"); done
  (( ${#missing[@]} == 0 )) && { ok "apt: already installed: $*"; return; }
  apt_update
  info "apt install ${missing[*]}"
  run $SUDO env DEBIAN_FRONTEND=noninteractive apt-get install -y -qq --no-install-recommends "${missing[@]}"
}

# ------------------------------------------------------------- downloads ---
arch_name() { # style: x86_64|amd64
  local m; m=$(uname -m)
  case "$1:$m" in
    amd64:x86_64) echo amd64 ;; amd64:aarch64) echo arm64 ;;
    *:x86_64) echo x86_64 ;; *:aarch64) echo arm64 ;; *) echo "$m" ;;
  esac
}

# Latest release tag of a GitHub repo, without using the (rate limited) API.
gh_latest_tag() {
  local url
  url=$(curl -fsSLI -o /dev/null -w '%{url_effective}' "https://github.com/$1/releases/latest") || return 1
  echo "${url##*/}"
}

# Download a release tarball and install one binary from it into ~/.local/bin
# usage: install_release_bin <binary> <url>
install_release_bin() {
  local bin=$1 url=$2 tmp
  if (( DRY_RUN )); then info "[dry-run] download $url -> $LOCAL_BIN/$bin"; return; fi
  tmp=$(mktemp -d)
  local found="" rc=0
  if ! curl -fsSL "$url" -o "$tmp/archive"; then
    err "download failed: $url"; rc=1
  elif ! tar -xf "$tmp/archive" -C "$tmp"; then
    err "extract failed: $url"; rc=1
  else
    found=$(find "$tmp" -type f -name "$bin" -perm -u+x | head -1)
    if [[ -z $found ]]; then
      err "binary $bin not found in $url"; rc=1
    else
      mkdir -p "$LOCAL_BIN"
      install -m 0755 "$found" "$LOCAL_BIN/$bin"
      ok "installed $bin -> $LOCAL_BIN/$bin"
    fi
  fi
  rm -rf "$tmp"
  return "$rc"
}

# Shallow clone, or fast-forward if it already exists.
git_sync() { # url dir
  if [[ -d $2/.git ]]; then
    run git -C "$2" pull --ff-only -q || warn "could not update $2"
  else
    run mkdir -p "$(dirname "$2")"
    run git clone -q --depth=1 "$1" "$2"
  fi
}

# --------------------------------------------------------------- linking ---
# Move a path into the backup dir (keeps the relative layout under $HOME).
backup_path() {
  local p=$1 rel dest
  rel=${p#"$HOME"/}
  dest="$BACKUP_DIR/$rel"
  if (( DRY_RUN )); then info "[dry-run] backup $p -> $dest"; return; fi
  mkdir -p "$(dirname "$dest")"
  mv "$p" "$dest"
  info "backed up $p -> $dest"
}

# True if $1 is a symlink that already points into this repo.
_points_to_repo() {
  [[ -L $1 ]] && [[ $(readlink -f "$1") == "$DOTFILES_DIR"/* ]]
}

# Link a package from home/<pkg> into $HOME with GNU stow (no folding, so
# untracked local files never end up inside the repo). Conflicting files
# and stale links (e.g. into the old ~/.dotfiles) are backed up first.
link_pkg() {
  local pkg=$1 src="$DOTFILES_DIR/home/$1"
  [[ -d $src ]] || die "unknown package: $pkg"
  has stow || { (( DRY_RUN )) && { info "[dry-run] stow $pkg"; return; }; die "stow is not installed"; }

  local rel target parent
  while IFS= read -r -d '' rel; do
    rel=${rel#./}
    target="$HOME/$rel"
    # Any parent directory that is a symlink (e.g. ~/.config/alacritty -> old repo)
    parent=$(dirname "$target")
    while [[ $parent != "$HOME" && $parent != / ]]; do
      if [[ -L $parent ]] && ! _points_to_repo "$parent"; then backup_path "$parent"; fi
      parent=$(dirname "$parent")
    done
    if [[ -L $target ]]; then
      _points_to_repo "$target" || backup_path "$target"
    elif [[ -e $target ]]; then
      backup_path "$target"
    fi
  done < <(cd "$src" && find . \( -type f -o -type l \) -print0)

  run stow --no-folding --restow -d "$DOTFILES_DIR/home" -t "$HOME" "$pkg"
  state_set "linked_$pkg" 1
  ok "linked $pkg"
}

unlink_pkg() {
  run stow --no-folding --delete -d "$DOTFILES_DIR/home" -t "$HOME" "$1"
  state_set "linked_$1" 0
  ok "unlinked $1"
}

# Copy a template to a destination only if the destination doesn't exist.
seed_file() { # src dest [mode]
  [[ -e $2 ]] && { ok "kept existing $2"; return; }
  run mkdir -p "$(dirname "$2")"
  run cp "$1" "$2"
  [[ -n ${3:-} ]] && run chmod "$3" "$2"
  ok "created $2"
}

# --------------------------------------------------------------- distro ----
check_os() {
  [[ -r /etc/os-release ]] || die "cannot detect OS"
  # shellcheck disable=SC1091
  . /etc/os-release
  case " ${ID:-} ${ID_LIKE:-} " in
    *" ubuntu "*|*" debian "*) OS_CODENAME=${VERSION_CODENAME:-${UBUNTU_CODENAME:-}} ;;
    *) warn "Only Ubuntu/Debian are supported (found ${ID:-unknown}); continuing anyway" ;;
  esac
  OS_ID=${ID:-unknown}
  export OS_ID OS_CODENAME
}
