# Custom functions and widgets.

# mkdir + cd
take() { mkdir -p -- "$1" && cd -- "$1"; }

# ------------------------------------------------------------------------
# smart_cd (Alt+C): fuzzy-find any file/dir below here.
#   enter  -> cd into it (or into the file's directory)
#   ctrl-o -> open the file in vim and come back to the list's shell
# ------------------------------------------------------------------------
smart_cd() {
  local finder target
  if (( $+commands[fd] )); then finder=fd
  elif (( $+commands[fdfind] )); then finder=fdfind
  else zle -M "smart_cd: fd is not installed"; return 1
  fi
  local viewer=bat; (( $+commands[bat] )) || viewer=batcat

  # '< /dev/tty > /dev/tty' lets vim talk to the real terminal from inside fzf
  target=$($finder --hidden --exclude .git --color=always 2>/dev/null | fzf \
    --ansi \
    --preview "[ -d {} ] && ls -la --color=always {} || $viewer --style=numbers --color=always --line-range :50 {}" \
    --bind 'ctrl-o:execute(vim {} < /dev/tty > /dev/tty)+abort')

  if [[ -n $target ]]; then
    if [[ -f $target ]]; then cd -- "${target:h}"; else cd -- "$target"; fi
  fi
  zle reset-prompt
}
zle -N smart_cd_widget smart_cd
# bound to Alt+C in fzf.zsh (after fzf's own bindings)

# ------------------------------------------------------------------------
# ds: colored disk usage, biggest last (top 15).
#   ds            -> entries of the current directory
#   ds <dir>      -> entries of <dir>
#   ds a b c      -> those paths
# Colors: >1G red, >700M orange, >300M amber, >50M yellow, else green.
# ------------------------------------------------------------------------
ds() {
  local -a targets
  if (( $# == 0 )); then targets=(*(N))
  elif (( $# == 1 )) && [[ -d $1 ]]; then targets=($1/*(N))
  else targets=("$@")
  fi
  (( ${#targets} )) || { print "ds: nothing here"; return 1; }

  local bytes name color mb
  du -s --block-size=1 -- $targets 2>/dev/null | sort -n | tail -n 15 |
  while IFS=$'\t' read -r bytes name; do
    mb=$(( bytes / 1048576 ))
    if   (( mb >= 1024 )); then color=196
    elif (( mb >= 700 ));  then color=208
    elif (( mb >= 300 ));  then color=214
    elif (( mb >= 50 ));   then color=220
    else color=118
    fi
    printf '\e[38;5;%dm%7s\e[0m  %s\n' $color "$(numfmt --to=iec $bytes)" "$(command ls -d --color=always -- "$name")"
  done
}
