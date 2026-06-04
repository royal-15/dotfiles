-------------------
---- AUTOSTART ----
-------------------

-- See https://wiki.hypr.land/Configuring/Basics/Autostart/

hl.on("hyprland.start", function () 
  hl.exec_cmd("awww-daemon & waybar & swaync & nm-applet")
  hl.exec_cmd("awww img ~/.config/theme-switcher/state/current_wallpaper")
  
  hl.exec_cmd("hyprctl setcursor macOS 24")

  -- Clipboard History
  hl.exec_cmd("wl-paste --type text --watch cliphist store")
  hl.exec_cmd("wl-paste --type image --watch cliphist store")

  -- gnome keyring
  hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
  hl.exec_cmd("/usr/bin/gnome-keyring-daemon --start --components=secrets")
  
  hl.exec_cmd("eval $(gnome-keyring-daemon --start --components=secrets)")
  hl.exec_cmd("dbus-update-activation-environment --all")
end)