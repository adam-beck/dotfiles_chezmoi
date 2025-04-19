#!/usr/bin/zsh

for i in {1..9}
do
  echo "unsetting shortcut Super+<number> for item ${i}"
  gsettings set org.gnome.shell.extensions.dash-to-dock app-hotkey-${i} '[]'
done
