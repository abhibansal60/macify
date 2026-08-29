#!/usr/bin/env bash
# Reskins Ubuntu GNOME to look like macOS: WhiteSur GTK/icon/cursor theme,
# Unite (top-bar app menu + traffic lights), themed dock, Inter font,
# Sonoma wallpaper, themed GDM login screen.
#
# Requires: Ubuntu + GNOME Shell (tested on 26.04 / GNOME Shell 50), sudo.
# NOT rootless like cyberdeck-setup — this touches system packages and the
# GDM login theme. Read before running.
set -euo pipefail

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

echo "== 1/6: apt dependencies (sudo) =="
sudo apt update
sudo apt install -y \
  gnome-tweaks gnome-shell-extension-manager gnome-shell-extensions \
  git curl sassc libglib2.0-dev-bin libxml2-utils fonts-inter

echo "== 2/6: WhiteSur GTK theme, icons, cursors =="
git clone --depth 1 https://github.com/vinceliuice/WhiteSur-gtk-theme.git "$WORK/gtk-theme"
"$WORK/gtk-theme/install.sh" -t all -c Dark -N glassy

git clone --depth 1 https://github.com/vinceliuice/WhiteSur-icon-theme.git "$WORK/icon-theme"
"$WORK/icon-theme/install.sh" -a

git clone --depth 1 https://github.com/vinceliuice/WhiteSur-cursors.git "$WORK/cursors"
"$WORK/cursors/install.sh"

echo "== 3/6: Unite extension (top-bar app menu + traffic lights) =="
git clone --depth 1 https://github.com/hardpixel/unite-shell.git "$WORK/unite"
mkdir -p ~/.local/share/gnome-shell/extensions
cp -r "$WORK/unite/unite@hardpixel.eu" ~/.local/share/gnome-shell/extensions/
glib-compile-schemas ~/.local/share/gnome-shell/extensions/unite@hardpixel.eu/schemas/

echo "== 4/6: wallpaper =="
git clone --depth 1 https://github.com/vinceliuice/WhiteSur-wallpapers.git "$WORK/wallpapers"
mkdir -p ~/Pictures/Wallpapers
cp "$WORK/wallpapers/4k/Sonoma-dark.jpg" "$WORK/wallpapers/4k/Sonoma-light.jpg" \
   "$WORK/wallpapers/4k/Ventura-light.jpg" "$WORK/wallpapers/4k/Monterey-light.jpg" \
   "$WORK/wallpapers/4k/WhiteSur-light.jpg" ~/Pictures/Wallpapers/

echo "== 5/6: apply settings (user-theme + Unite extensions need a re-login to load) =="
"$(dirname "$0")/bin/macify" mac || true  # first pass; GDM step below is separate

echo "== 6/6: GDM login screen theme (sudo) =="
git clone --depth 1 https://github.com/vinceliuice/WhiteSur-gtk-theme.git "$WORK/gtk-theme-gdm"
(cd "$WORK/gtk-theme-gdm" && ./tweaks.sh -g)
mkdir -p ~/.local/share/macify
GDM_LIVE="/usr/share/gnome-shell/theme/Yaru/gnome-shell-theme.gresource"
cp "$GDM_LIVE" ~/.local/share/macify/gdm-whitesur.gresource

mkdir -p ~/.local/bin
cp "$(dirname "$0")/bin/macify" ~/.local/bin/macify
chmod +x ~/.local/bin/macify

cat <<'EOF'

Done. Log out and back in, then run:
  gnome-extensions enable user-theme@gnome-shell-extensions.gcampax.github.com
  gnome-extensions enable unite@hardpixel.eu

From then on, toggle between this theme and stock Ubuntu any time with:
  macify          # flips based on current state
  macify mac
  macify ubuntu

Known ceiling: GTK4/libadwaita apps (Files, Settings, Text Editor) stay
stock Adwaita — no GTK3 theme touches them, on any distro.
EOF
