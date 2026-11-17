# shellcheck shell=bash
module claude on "Claude Code: settings, commands, plugins, MCP servers, ccmcp presets"

claude_configure() {
  local cur; cur=${CLAUDE_AUTOCOMPACT:-$(state_get CLAUDE_AUTOCOMPACT yes)}
  if ask "Enable the auto-compact plugin (runs claude inside a dedicated tmux server)?" "${cur:0:1}"; then
    CLAUDE_AUTOCOMPACT=yes
  else
    CLAUDE_AUTOCOMPACT=no
  fi
  cur=${CLAUDE_CONTEXT7:-$(state_get CLAUDE_CONTEXT7 yes)}
  if ask "Add the context7 MCP server (up-to-date library docs) for all projects?" "${cur:0:1}"; then
    CLAUDE_CONTEXT7=yes
  else
    CLAUDE_CONTEXT7=no
  fi
  export CLAUDE_AUTOCOMPACT CLAUDE_CONTEXT7
}

# Merge repo settings into ~/.claude/settings.json (Claude Code rewrites that
# file itself, so it is merged, never linked).
_claude_settings() {
  local target="$HOME/.claude/settings.json" overlays=("$DOTFILES_DIR/claude/settings.base.json")
  [[ $1 == yes ]] && overlays+=("$DOTFILES_DIR/claude/settings.autocompact.json")
  if (( DRY_RUN )); then info "[dry-run] merge ${overlays[*]##*/} into $target"; return 0; fi
  mkdir -p "$HOME/.claude"
  [[ -f $target ]] || echo '{}' >"$target"
  cp "$target" "$target.bak"
  local merged
  merged=$(jq -n --arg home "$HOME" -L "$DOTFILES_DIR/lib" '
    include "json";
    reduce inputs as $o ({};
      deepmerge(.; $o | walk(if type == "string" then gsub("__HOME__"; $home) else . end)))' \
    "$target" "${overlays[@]}") || { err "could not merge $target (left unchanged)"; return 1; }
  printf '%s\n' "$merged" >"$target"
  ok "merged settings into $target (previous: settings.json.bak)"
}

claude_install() {
  local autocompact=${CLAUDE_AUTOCOMPACT:-$(state_get CLAUDE_AUTOCOMPACT yes)}
  local context7=${CLAUDE_CONTEXT7:-$(state_get CLAUDE_CONTEXT7 yes)}
  state_set CLAUDE_AUTOCOMPACT "$autocompact"
  state_set CLAUDE_TMUX_WRAPPER "$autocompact"
  state_set CLAUDE_CONTEXT7 "$context7"

  if ! has claude && [[ ! -x $HOME/.local/bin/claude ]]; then
    info "installing Claude Code (native installer)"
    if (( DRY_RUN )); then info "[dry-run] curl -fsSL https://claude.ai/install.sh | bash"
    else curl -fsSL https://claude.ai/install.sh | bash; fi
    manual "Start Claude Code and log in: claude  (then /login)"
  fi
  local cc=claude; has claude || cc=$HOME/.local/bin/claude

  link_pkg claude
  _claude_settings "$autocompact"

  if (( ! DRY_RUN )) && [[ -x $(command -v "$cc") ]]; then
    if [[ $autocompact == yes ]] && ! "$cc" plugin list 2>/dev/null | grep -q claude-code-auto-compact; then
      "$cc" plugin marketplace add sure-scale/claude-code-auto-compact >/dev/null 2>&1 || true
      "$cc" plugin install claude-code-auto-compact@sure-scale >/dev/null 2>&1 \
        && ok "installed auto-compact plugin" \
        || manual "Install the auto-compact plugin inside claude: /plugin install claude-code-auto-compact@sure-scale"
    fi
    if [[ $context7 == yes ]] && ! "$cc" mcp get context7 >/dev/null 2>&1; then
      "$cc" mcp add --scope user --transport http context7 https://mcp.context7.com/mcp >/dev/null 2>&1 \
        && ok "added context7 MCP (user scope)" || warn "could not add context7 MCP"
    fi
  fi
  info "project MCP presets: ccmcp list   (e.g. 'ccmcp kicad' inside a KiCad repo)"
  return 0
}
