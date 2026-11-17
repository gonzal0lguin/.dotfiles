# shellcheck shell=bash
module fonts on "0xProto Nerd Font (icons for prompt, eza, vim)"

fonts_install() {
  local font=${NERD_FONT:-0xProto} dir="${XDG_DATA_HOME:-$HOME/.local/share}/fonts"
  if fc-list 2>/dev/null | grep -qi "$font Nerd Font"; then
    ok "$font Nerd Font already installed"; return 0
  fi
  local url="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${font}.tar.xz"
  info "downloading $url"
  if (( DRY_RUN )); then info "[dry-run] extract to $dir/$font"; return 0; fi
  mkdir -p "$dir/$font"
  curl -fsSL "$url" | tar -xJ -C "$dir/$font"
  fc-cache -f "$dir" >/dev/null
  ok "installed $font Nerd Font"
}
