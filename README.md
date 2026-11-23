# Dotfiles

Personal configuration for an Arch Linux desktop running Hyprland. The repository includes desktop configs, helper scripts, EasyEffects profiles, and package snapshots.

## Install

Clone the repository, then run:

```sh
./install.sh
```

The installer copies the repository's configuration and local files into their expected locations under `~/.config`, `~/.local`, and your home directory. It does not link those destinations to this checkout. Existing files that would be overwritten are moved into a timestamped directory under `~/.local/state/dotfiles-backups/`; files that exist only on the machine are kept. The run log is saved under `~/.local/state/dotfiles-installer/`.

By default, the installer also installs the packages in `packages/pacman.txt` and `packages/aur.txt`. It expects Arch Linux, `sudo`, `git`, and `makepkg`. If neither `yay` nor `paru` is installed, it builds `yay` from the AUR after installing the official packages. Package manager prompts remain interactive. Use `./install.sh --no-packages` to copy configs without installing packages. The package files are snapshots of explicitly installed packages from this machine and may include machine-specific tools.

The installer initializes the Oh My Zsh submodule if it is not populated. Spicetify themes in `vendor/spicetify-themes/` are copied into `~/.config/spicetify/Themes/`.

## Updating this repository

After changing a configuration in your home directory, run `scripts/sync.sh` to copy the listed files back into this repository. Review the resulting diff before committing. Directory sync uses `rsync --delete`, so files in the repository destination that are absent from the corresponding home directory will be removed.

To change a setting, edit the repository copy and rerun `./install.sh`, or edit the installed copy and run `scripts/sync.sh` to bring it back into the repository.

## Contents

- `config/` — application and desktop environment settings.
- `local/bin/` — personal command-line scripts installed under `~/.local/bin`.
- `local/share/easyeffects/` — EasyEffects presets and impulse responses.
- `home/` — selected home-directory files, including Zsh configuration and Oh My Zsh.
- `packages/` — pacman and AUR package snapshots.
- `vendor/spicetify-themes/` — Spicetify themes.

The setup is tailored to one Arch/Hyprland environment. Review hardware-specific settings, package lists, and scripts before applying it on another machine.
