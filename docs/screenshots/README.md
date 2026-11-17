# Screenshots

Real captures of the setup on Ubuntu (X11), referenced from the main README:

| File | Shows |
|---|---|
| `alacritty-tmux.png` | Alacritty + tmux (stats status bar) + starship, catppuccin-mocha |
| `kitty-gruvbox.png` | kitty with the gruvbox-dark theme |
| `vim.png` | vim with fern, lightline and gitgutter |
| `fzf.png` | `Alt+C` smart_cd with preview |
| `tmux-status.png` | close-up of the status bar |

To retake one on X11 (ImageMagick): focus the window, then

```bash
import -window "$(xdotool getactivewindow)" docs/screenshots/<name>.png
```
