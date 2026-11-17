#!/usr/bin/env bash
# Replace tmux's red "<" / ">" (more windows off-screen) with nicer chevrons.
# Edits the default status-format[0] in place; safe to run more than once.
fmt=$(tmux show -gv 'status-format[0]')
fmt=${fmt//'#[list=left-marker]<'/'#[list=left-marker]#[fg=blue]󰄽 '}
fmt=${fmt//'#[list=right-marker]>'/'#[list=right-marker]#[fg=blue] 󰄾'}
tmux set -g 'status-format[0]' "$fmt"
