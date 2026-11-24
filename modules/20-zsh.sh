# shellcheck shell=bash
module zsh on "zsh + antidote plugins (autosuggestions, syntax highlighting, fzf-tab)"

zsh_install() {
  apt_install zsh command-not-found
  link_pkg zsh

  local zdir="$HOME/.config/zsh"
  seed_file "$DOTFILES_DIR/home/zsh/.config/zsh/local.zsh.example" "$zdir/local.zsh"
  seed_file "$DOTFILES_DIR/home/zsh/.config/zsh/secrets.zsh.example" "$zdir/secrets.zsh" 600
  manual "Add machine-specific aliases/ROS setup to ~/.config/zsh/local.zsh and tokens to ~/.config/zsh/secrets.zsh"

  git_sync https://github.com/mattmc3/antidote "${XDG_DATA_HOME:-$HOME/.local/share}/antidote"
  # Pre-fetch plugins so the first shell starts instantly.
  if has zsh && (( ! DRY_RUN )); then
    if zsh -ic 'exit' >/dev/null 2>&1; then
      ok "zsh plugins installed"
    else
      warn "first zsh start reported errors; run 'zsh' to see them"
    fi
  fi

  local login_shell
  login_shell=$(getent passwd "$USER" | cut -d: -f7)
  if [[ $login_shell != */zsh ]]; then
    if (( ! NO_PACKAGES )) && has zsh && ask "Make zsh your login shell?" y; then
      run $SUDO chsh -s "$(command -v zsh)" "$USER" && manual "Log out and back in so zsh becomes your login shell"
    else
      manual "Make zsh your login shell: chsh -s \$(command -v zsh)"
    fi
  fi
  [[ -d $HOME/.oh-my-zsh ]] && manual "oh-my-zsh is no longer used; remove it when happy: rm -rf ~/.oh-my-zsh"
  return 0
}
