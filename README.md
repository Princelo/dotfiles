# Dotfiles

Personal dotfiles and small CLI helpers.

## What’s in here

- Shell: `zsh` via Oh My Zsh (`.zshrc`, `.oh-my-zsh/`)
- Editor:
  - Neovim config in `.config/nvim/`
  - Vim config in `.vimrc` (with a `vi` alias that starts `nvim` using `.vimrc`)
  - IntelliJ IdeaVim config in `.ideavimrc`
- Terminal / multiplexer:
  - `tmux` config in `.config/tmux/`
  - Ghostty config in `.config/ghostty/`
- Misc app config:
  - `mpv` config in `.config/mpv/`
- Utilities in `Tools/` (mostly Python scripts)
- Neovim plugins vendored as git submodules under `.local/share/nvim/site/pack/plugins/`

## Quick start

Clone with submodules (recommended for Neovim plugins):

```sh
git clone --recurse-submodules <repo-url> ~/.dotfiles
```

If you already cloned without submodules:

```sh
cd ~/.dotfiles
git submodule update --init --recursive
```

Symlink configs into place (pick what you want):

```sh
ln -sfn ~/.dotfiles/.zshrc ~/.zshrc
ln -sfn ~/.dotfiles/.vimrc ~/.vimrc
ln -sfn ~/.dotfiles/.ideavimrc ~/.ideavimrc

mkdir -p ~/.config
ln -sfn ~/.dotfiles/.config/nvim ~/.config/nvim
ln -sfn ~/.dotfiles/.config/tmux ~/.config/tmux
ln -sfn ~/.dotfiles/.config/ghostty ~/.config/ghostty
ln -sfn ~/.dotfiles/.config/mpv ~/.config/mpv

ln -sfn ~/.dotfiles/Tools ~/Tools
```

## Notes

- `.zshrc` expects `~/.zshrc_custom` to exist.
  - If you don’t have one, create an empty file: `touch ~/.zshrc_custom`.
  - This file is meant for machine-local overrides and paths. Currently `.zshrc` relies on these variables:
    - `JAVA_HOME`: used to add `"$JAVA_HOME/bin"` to `PATH`.
    - `M2_HOME`: used to add `"$M2_HOME/bin"` to `PATH` (Maven).
    - `PROXY_PORT`: used by the `proxy` alias (`127.0.0.1:$PROXY_PORT`).
  - Minimal template:

    ```sh
    # ~/.zshrc_custom
    export JAVA_HOME="/path/to/jdk/Contents/Home"
    export M2_HOME="$HOME/path/to/apache-maven"
    export PROXY_PORT=7890
    ```

- Some aliases in `.zshrc` assume tools are installed (examples: `fzf`, `jq`, `yazi`, `zoxide`).
- Safety: `rm` is aliased to a warning; use `/bin/rm` if you really mean it.

## Tools

See `Tools/` for helper scripts. A few are wired up in `.zshrc`:

- `rmmd`: delete unreferenced “trash” images from a Markdown note
- `mdimg`: rewrite/upload images for Markdown notes
