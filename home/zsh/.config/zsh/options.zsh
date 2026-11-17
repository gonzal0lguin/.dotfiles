# Shell options and history (what oh-my-zsh's lib used to set for us).

HISTFILE=$HOME/.zsh_history
HISTSIZE=100000
SAVEHIST=100000
setopt extended_history       # save timestamps
setopt share_history          # share history between open shells
setopt hist_expire_dups_first
setopt hist_ignore_dups
setopt hist_ignore_space      # " cmd" is not saved (handy for secrets)
setopt hist_verify            # !! expands into the prompt instead of running

setopt auto_cd                # `dir` == `cd dir`
setopt auto_pushd pushd_ignore_dups pushd_minus pushd_silent
setopt interactive_comments
setopt complete_in_word always_to_end
setopt no_beep
setopt no_flow_control        # free ctrl-s / ctrl-q

WORDCHARS=${WORDCHARS//[\/.-]/}   # ctrl-w / alt-backspace stop at / . -
