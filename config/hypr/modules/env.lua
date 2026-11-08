-- =============================================================================
-- ENVIRONMENT VARIABLES
-- =============================================================================
-- Documentation: https://wiki.hypr.land/Configuring/Environment-variables/

-- -----------------------------------------------------------------------------
-- Cursor
-- -----------------------------------------------------------------------------
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

-- -----------------------------------------------------------------------------
-- Wayland & Toolkit Backends
-- -----------------------------------------------------------------------------
hl.env("GDK_BACKEND", "wayland,x11,*")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("SDL_VIDEODRIVER", "wayland")
hl.env("CLUTTER_BACKEND", "wayland")

-- -----------------------------------------------------------------------------
-- XDG Desktop Session
-- -----------------------------------------------------------------------------
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")

-- -----------------------------------------------------------------------------
-- Qt Theming & Behavior
-- -----------------------------------------------------------------------------
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "1")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("QT_STYLE_OVERRIDE", "kvantum-dark")
hl.env("QT_LOGGING_RULES", "qt.qpa.wayland.textinput.warning=false")

-- -----------------------------------------------------------------------------
-- Electron / Chromium
-- -----------------------------------------------------------------------------
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")
