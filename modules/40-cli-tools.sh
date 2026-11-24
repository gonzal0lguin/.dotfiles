# shellcheck shell=bash
module cli on "CLI tools: eza ripgrep fd bat zoxide btop delta jq tldr ncdu gh lazygit"

cli_install() {
  apt_install eza ripgrep fd-find bat zoxide btop git-delta jq tealdeer ncdu gh xclip bc

  # Ubuntu renames bat/fd; add the usual names
  mkdir -p "$LOCAL_BIN"
  [[ -x /usr/bin/batcat && ! -e $LOCAL_BIN/bat ]] && run ln -s /usr/bin/batcat "$LOCAL_BIN/bat"
  [[ -x /usr/bin/fdfind && ! -e $LOCAL_BIN/fd ]] && run ln -s /usr/bin/fdfind "$LOCAL_BIN/fd"

  # bat: Catppuccin theme needs a cache rebuild
  link_pkg bat
  local bat=bat; has bat || bat=batcat
  if has "$bat" && (( ! DRY_RUN )); then "$bat" cache --build >/dev/null && ok "bat theme cache built"; fi

  # btop: catppuccin theme file (gruvbox ships with btop)
  local bt="${XDG_CONFIG_HOME:-$HOME/.config}/btop/themes/catppuccin_mocha.theme"
  if [[ ! -f $bt ]] && (( ! DRY_RUN )); then
    mkdir -p "$(dirname "$bt")"
    if curl -fsSL https://raw.githubusercontent.com/catppuccin/btop/main/themes/catppuccin_mocha.theme -o "$bt"; then
      ok "btop catppuccin theme"
    else
      warn "could not download btop theme"
    fi
  fi

  # lazygit (not packaged for Ubuntu 24.04)
  if ! has lazygit; then
    local tag; tag=$(gh_latest_tag jesseduffield/lazygit) && install_release_bin lazygit \
      "https://github.com/jesseduffield/lazygit/releases/download/${tag}/lazygit_${tag#v}_linux_$(arch_name).tar.gz"
  fi

  has tldr && (( ! DRY_RUN )) && { tldr --update >/dev/null 2>&1 || true; }
  has gh && ! gh auth status >/dev/null 2>&1 && manual "Log in to GitHub CLI: gh auth login  (then secrets.zsh can use 'gh auth token')"
  return 0
}
