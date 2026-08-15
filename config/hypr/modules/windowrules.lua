--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------
-- See https://wiki.hypr.land/Configuring/Basics/Window-Rules/
-- and https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/
-- Normal
hl.window_rule({
    match = {class = "google-chrome", title = "New Tab.*"},
    workspace = "3"
})
hl.window_rule({match = {class = "zen", title = "Zen Browser"}, workspace = "3"})
hl.window_rule({match = {class = "firefox"}, workspace = "3"})
hl.window_rule({
    match = {class = "jetbrains-studio", title = "Agent.*"},
    workspace = "4"
})
hl.window_rule({
    match = {class = "jetbrains-studio", title = "Logcat.*"},
    workspace = "5"
})

-- Special
hl.window_rule({
    match = {class = "obsidian"},
    -- opacity = "0.8 override 0.8 override",
    workspace = "special:s1"
})
hl.window_rule({
    match = {class = "Spotify"},
    opacity = "0.8 override 0.8 override",
    workspace = "special:s2"
})
hl.window_rule({match = {class = "kew-kitty"}, workspace = "special:s2"})

-- Ignore maximize requests from all apps. You'll probably like this.
hl.window_rule({
    name = "suppress-maximize-events",
    match = {class = ".*"},

    suppress_event = "maximize"
})

-- Fix some dragging issues with XWayland
hl.window_rule({
    name = "fix-xwayland-drags",
    match = {
        class = "^$",
        title = "^$",
        xwayland = true,
        float = true,
        fullscreen = false,
        pin = false
    },

    no_focus = true
})

-- Layer rules also return a handle.
-- local overlayLayerRule = hl.layer_rule({
--     name  = "no-anim-overlay",
--     match = { namespace = "^my-overlay$" },
--     no_anim = true,
-- })
-- overlayLayerRule:set_enabled(false)

-- Hyprland-run windowrule
hl.window_rule({
    name = "move-hyprland-run",
    match = {class = "hyprland-run"},

    move = "20 monitor_h-120",
    float = true
})

-- Ref https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/
-- "Smart gaps" / "No gaps when only"
-- uncomment all if you wish to use that.
-- hl.workspace_rule({ workspace = "w[tv1]", gaps_out = 0, gaps_in = 0 })
-- hl.workspace_rule({ workspace = "f[1]",   gaps_out = 0, gaps_in = 0 })
-- hl.window_rule({
--     name  = "no-gaps-wtv1",
--     match = { float = false, workspace = "w[tv1]" },
--     border_size = 0,
--     rounding    = 0,
-- })
-- hl.window_rule({
--     name  = "no-gaps-f1",
--     match = { float = false, workspace = "f[1]" },
--     border_size = 0,
--     rounding    = 0,
-- })
