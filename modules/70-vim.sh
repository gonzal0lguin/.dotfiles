# shellcheck shell=bash
module vim on "vim with plugins (themes, lightline, fzf, git, fern) + clipboard"

vim_install() {
  apt_install vim-gtk3          # vim with +clipboard
  # an old ~/.vimrc would win over ~/.vim/vimrc
  if [[ -e $HOME/.vimrc || -L $HOME/.vimrc ]] && ! _points_to_repo "$HOME/.vimrc"; then
    backup_path "$HOME/.vimrc"
  fi
  link_pkg vim
  local plug="$HOME/.vim/autoload/plug.vim"
  if [[ ! -f $plug ]]; then
    run curl -fsSLo "$plug" --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  fi
  if has vim && (( ! DRY_RUN )); then
    vim -es -u "$HOME/.vim/vimrc" -i NONE -c 'PlugInstall --sync' -c 'qa' >/dev/null 2>&1 || true
    ok "vim plugins installed"
  fi
}
