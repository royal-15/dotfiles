-- =============================================================================
-- WINDOW RULES & BEHAVIOR
-- =============================================================================
-- Documentation: https://wiki.hypr.land/Configuring/Window-Rules/

-- =============================================================================
-- 1. WORKSPACE ASSIGNMENTS (BROWSERS & EDITORS)
-- =============================================================================

-- Web Browsers
hl.window_rule({
    match     = {class = "google-chrome", title = "New Tab.*"},
    workspace = "3",
})
hl.window_rule({
    match     = {class = "zen", title = "Zen Browser"},
    workspace = "3",
})
hl.window_rule({
    match     = {class = "firefox"},
    workspace = "special:s2",
})

-- Android Studio & Development Environments
hl.window_rule({
    match     = {class = "jetbrains-studio", title = ""},
    workspace = "1",
})
hl.window_rule({
    match     = {class = "antigravity", title = "Antigravity"},
    workspace = "1",
})
hl.window_rule({
    match     = {class = "jetbrains-studio", title = "Agent.*"},
    workspace = "2",
})
hl.window_rule({
    match     = {class = "jetbrains-studio", title = "Logcat.*"},
    workspace = "4",
})

-- =============================================================================
-- 2. SPECIAL WORKSPACES / SCRATCHPADS (WITH OPACITY OVERRIDES)
-- =============================================================================

-- Obsidian (Scratchpad s1)
hl.window_rule({
    match     = {class = "md.obsidian.Obsidian"},
    opacity   = "0.8 override 0.8 override",
    workspace = "special:s1",
})

-- Media & Audio Apps (Scratchpad s2)
hl.window_rule({
    match     = {class = "Spotify"},
    opacity   = "0.8 override 0.8 override",
    workspace = "special:s2",
})
hl.window_rule({
    match     = {class = "youtube-music-desktop-app"},
    opacity   = "0.8 override 0.8 override",
    workspace = "special:s2",
})
hl.window_rule({
    match     = {class = "com.github.wwmm.easyeffects"},
    opacity   = "0.8 override 0.8 override",
    workspace = "special:s2",
})
hl.window_rule({
    match     = {class = "kew-kitty"},
    opacity   = "0.8 override 0.8 override",
    workspace = "special:s2",
})

-- =============================================================================
-- 3. WINDOW MANAGEMENT & COMPOSITOR BEHAVIOR FIXES
-- =============================================================================

-- Suppress maximize events across all applications
hl.window_rule({
    name           = "suppress-maximize-events",
    match          = {class = ".*"},
    suppress_event = "maximize",
})

-- Fix XWayland empty drag/drop windows stealing focus
hl.window_rule({
    name       = "fix-xwayland-drags",
    match      = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },
    no_focus   = true,
})

-- Waydroid Emulation
hl.window_rule({
    name       = "Waydroid fullscreen",
    match      = {class = "Waydroid"},
    fullscreen = true,
    workspace  = "4",
})

-- =============================================================================
-- 4. UTILITY DIALOGS & RUNNERS
-- =============================================================================

-- Hyprland Run Menu Placement
hl.window_rule({
    name  = "move-hyprland-run",
    match = {class = "hyprland-run"},
    move  = "20 monitor_h-120",
    float = true,
})
