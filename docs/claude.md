# Claude Code setup

What `./install.sh claude` does and how to extend it.

| Piece | Where it lives in the repo | How it gets to `~/.claude` |
|---|---|---|
| Settings (model, theme, effort per model, ...) | `claude/settings.base.json` | **merged** into `~/.claude/settings.json` |
| Auto-compact plugin settings | `claude/settings.autocompact.json` | merged when you enable auto-compact |
| Slash commands | `home/claude/.claude/commands/*.md` | linked (stow) |
| Skills / agents (add your own) | `home/claude/.claude/skills/`, `home/claude/.claude/agents/` | linked (stow) |
| MCP presets for projects | `claude/mcp-presets/*.json` | `ccmcp <preset>` writes `./.mcp.json` |
| `claude` tmux wrapper | `home/zsh/.config/zsh/claude.zsh` + `home/tmux/.config/tmux/claude.conf` | linked |

## Why settings are merged, not linked

Claude Code writes to `~/.claude/settings.json` itself (`/model`, `/config`, accepting
permissions...). A symlink would either keep the repo dirty or be replaced by a
normal file. So the installer **deep-merges** the repo files into it:

- objects are merged key by key, lists (like `permissions.allow`) are unioned,
- values from the repo win for keys the repo defines, everything else is kept,
- `__HOME__` in the repo files becomes your real home path (no hardcoded `/home/<user>`),
- the previous file is saved as `settings.json.bak`.

Re-apply after editing the repo: `dot install claude`.
Want a setting you changed in Claude to become the default everywhere? Copy that key
from `~/.claude/settings.json` into `claude/settings.base.json`.

## Slash commands

A command is a Markdown file; the file name is the command:

```bash
$EDITOR "$(dot cd)/home/claude/.claude/commands/review-ros.md"
dot link claude          # links new files
```

Then use `/review-ros` in Claude. `$ARGUMENTS` in the file is replaced by what you type
after the command.

## Skills

A skill is a folder with a `SKILL.md` (front matter `name` + `description`, then
instructions). Claude loads it when the description matches the task.

```
home/claude/.claude/skills/colcon-build/SKILL.md
```

```markdown
---
name: colcon-build
description: Build and test ROS 2 workspaces with colcon. Use when building, testing or fixing build errors in a ROS 2 workspace.
---
1. Source /opt/ros/$ROS_DISTRO/setup.zsh ...
```

Run `dot link claude` after adding it.

## Subagents

Markdown files with front matter in `home/claude/.claude/agents/` (`name`, `description`,
optional `tools`, `model`). Create one interactively with `/agents`, then move the file
from `~/.claude/agents/` into the repo and run `dot link claude`.

## Plugins

Plugins bundle commands, skills, agents, hooks and MCP servers.

```bash
claude plugin marketplace add <owner>/<repo>    # a marketplace (GitHub repo)
claude plugin install <plugin>@<marketplace>
claude plugin list
```

To make a plugin part of your dotfiles, add it to `enabledPlugins` (and its marketplace
to `extraKnownMarketplaces`) in `claude/settings.base.json`, like the auto-compact
plugin in `claude/settings.autocompact.json`.

### auto-compact

The plugin types `/compact` into Claude's tmux pane. That's why, when it is enabled,
`claude` started outside tmux runs inside a dedicated tmux server (`tmux -L claude`, config
`~/.config/tmux/claude.conf`). Inside your normal tmux it just runs `claude`.

## MCP servers

Scopes: **user** (every project, stored in `~/.claude.json`), **project** (`.mcp.json` in the
repo, shared through git), **local** (this project, only you).

- User scope, added by the installer: **context7** (current library docs).
- Project presets, added with `ccmcp`:

```bash
ccmcp list               # kicad, ros, github, context7
ccmcp kicad              # in a KiCad repo -> .mcp.json with kicad-pro (uvx kicad-mcp-pro)
ccmcp ros                # ros-mcp through rosbridge (can publish commands: be careful)
ccmcp github             # GitHub MCP, reads $GITHUB_TOKEN from your environment
```

Equivalent by hand: `claude mcp add kicad-pro --scope project -- uvx kicad-mcp-pro`.

Add a preset: drop a JSON file in `claude/mcp-presets/` with `_description` and an
`mcpServers` object (same format as `.mcp.json`; `${VAR}` is expanded from the environment).

Tip: Claude can already run `gh`, `docker`, `ros2` and `colcon` through the shell, so an MCP
server is mostly worth it when it gives access to something the CLI can't (live docs,
a running robot, a design review tool).

## Hooks and status line

Both are settings: add a `hooks` or `statusLine` block to `claude/settings.base.json`
(scripts can live in `home/claude/.claude/` and be referenced as `__HOME__/.claude/...`).
See https://docs.claude.com/en/docs/claude-code/hooks and `/statusline` inside Claude.

## Global instructions

`~/.claude/CLAUDE.md` is read in every session. To manage it here, create
`home/claude/.claude/CLAUDE.md` and run `dot link claude`.
