-- =============================================================================
-- KEYBINDINGS & SHORTCUTS
-- =============================================================================
-- Documentation: https://wiki.hypr.land/Configuring/Binds/
-- =============================================================================
-- 1. MODIFIERS & DEFAULT PROGRAMS
-- =============================================================================
local mainMod = "ALT"
local mod = "SUPER"

local terminal = "kitty"
local fileManager = "thunar"

-- =============================================================================
-- 2. WINDOW MANAGEMENT
-- =============================================================================
hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + V", hl.dsp.window.float({action = "toggle"}))
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))
hl.bind(mainMod .. " + SHIFT + V", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen())

-- Directional Focus (mainMod + Arrows)
hl.bind(mainMod .. " + left", hl.dsp.focus({direction = "left"}))
hl.bind(mainMod .. " + right", hl.dsp.focus({direction = "right"}))
hl.bind(mainMod .. " + up", hl.dsp.focus({direction = "up"}))
hl.bind(mainMod .. " + down", hl.dsp.focus({direction = "down"}))

-- Swap Windows (mainMod + Shift + Arrows)
hl.bind(mainMod .. " + SHIFT + left", hl.dsp.window.swap({direction = "left"}))
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.swap({direction = "right"}))
hl.bind(mainMod .. " + SHIFT + up", hl.dsp.window.swap({direction = "up"}))
hl.bind(mainMod .. " + SHIFT + down", hl.dsp.window.swap({direction = "down"}))

-- Move / Resize with Mouse Dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), {mouse = true})
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), {mouse = true})

-- =============================================================================
-- 3. WORKSPACES & SCRATCHPADS
-- =============================================================================

-- Numeric Workspaces 1-10 (Focus: mainMod + [0-9], Move: mainMod + SHIFT + [0-9])
for i = 1, 10 do
    local key = i % 10 -- 10 maps to key '0'
    hl.bind(mainMod .. " + " .. key, hl.dsp.focus({workspace = i}))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({workspace = i}))
end

-- Special Workspaces (Scratchpads)
hl.bind(mainMod .. " + A", hl.dsp.workspace.toggle_special("s1"))
hl.bind(mainMod .. " + SHIFT + A",
        hl.dsp.window.move({workspace = "special:s1"}))

hl.bind(mainMod .. " + S", hl.dsp.workspace.toggle_special("s2"))
hl.bind(mainMod .. " + SHIFT + S",
        hl.dsp.window.move({workspace = "special:s2"}))

hl.bind(mainMod .. " + X", hl.dsp.workspace.toggle_special("s3"))
hl.bind(mainMod .. " + SHIFT + X",
        hl.dsp.window.move({workspace = "special:s3"}))

-- Workspace Navigation via Mouse Wheel
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({workspace = "e+1"}))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({workspace = "e-1"}))

-- =============================================================================
-- 4. APPLICATION SHORTCUTS
-- =============================================================================
hl.bind(mainMod .. " + C", hl.dsp.exec_cmd("google-chrome-stable"))
hl.bind(mainMod .. " + SHIFT + B", hl.dsp.exec_cmd("blueman-manager"))
hl.bind(mainMod .. " + H", hl.dsp.exec_cmd("kitty -e htop"))
hl.bind(mainMod .. " + SHIFT + N", hl.dsp.exec_cmd("~/.local/bin/night-mode.sh"))
hl.bind(mainMod .. " + K", hl.dsp.exec_cmd("kitty --class \"kew-kitty\" -e kew"))
hl.bind(mainMod .. " + SHIFT + K", hl.dsp.exec_cmd("hyprctl kill"))

-- =============================================================================
-- 5. QUICKSHELL DESKTOP INTEGRATION
-- =============================================================================
hl.bind(mainMod .. " + T", hl.dsp.exec_cmd("qs -c ashell ipc call theme toggle"))
hl.bind(mod .. " + N",
        hl.dsp.exec_cmd("qs -c ashell ipc call notifications toggle"))
hl.bind(mainMod .. " + N",
        hl.dsp.exec_cmd("qs -c ashell ipc call network openWifi"))
hl.bind(mainMod .. " + B",
        hl.dsp.exec_cmd("qs -c ashell ipc call network openBluetooth"))
hl.bind(mainMod .. " + M",
        hl.dsp.exec_cmd("qs -c ashell ipc call powerprofile open"))
hl.bind(mainMod .. " + SHIFT + M",
        hl.dsp.exec_cmd("qs -c ashell ipc call media toggle"))
hl.bind(mainMod .. " + D",
        hl.dsp.exec_cmd("qs -c ashell ipc call launcher toggle"))
hl.bind(mainMod .. " + P",
        hl.dsp.exec_cmd("qs -c ashell ipc call commandpalette toggle"))

-- =============================================================================
-- 6. UTILITIES (EMOJI, CLIPBOARD, SCREENSHOTS)
-- =============================================================================
-- Emoji Selector
hl.bind(mainMod .. " + PERIOD", hl.dsp.exec_cmd(
            "pkill rofi || rofimoji --selector-args=\"-theme ~/.config/rofi/themes/applets/clipboard-compact.rasi\""))

-- Clipboard History
hl.bind(mod .. " + V",
        hl.dsp.exec_cmd("pkill rofi || ~/.local/bin/clipboard.sh history"))

-- Region Screenshots
hl.bind("Print", hl.dsp.exec_cmd(
            "grim -g \"$(slurp)\" - | wl-copy # Region → copy to clipboard"))
hl.bind("SHIFT + Print", hl.dsp.exec_cmd(
            "grim -g \"$(slurp)\" - | swappy -f - # Region → edit with swappy"))

-- =============================================================================
-- 7. HARDWARE KEYS & MEDIA CONTROLS
-- =============================================================================
local volumeStep = "3"
local brightnessStep = "5"

-- Audio Volume & Mic Mute (Laptop Keys)
hl.bind("XF86AudioRaiseVolume",
        hl.dsp
            .exec_cmd(
            "wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ " .. volumeStep .. "%+"),
        {locked = true, repeating = true})
hl.bind("XF86AudioLowerVolume", hl.dsp
            .exec_cmd(
            "wpctl set-volume @DEFAULT_AUDIO_SINK@ " .. volumeStep .. "%-"),
        {locked = true, repeating = true})
hl.bind("XF86AudioMute",
        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),
        {locked = true, repeating = true})
hl.bind("XF86AudioMicMute",
        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),
        {locked = true, repeating = true})

-- Alternate Audio Volume Keys
hl.bind(mainMod .. " + F3",
        hl.dsp
            .exec_cmd(
            "wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ " .. volumeStep .. "%+"))
hl.bind(mainMod .. " + F2", hl.dsp
            .exec_cmd(
            "wpctl set-volume @DEFAULT_AUDIO_SINK@ " .. volumeStep .. "%-"))

-- Screen Brightness (Laptop Keys & Alternate Binds)
hl.bind("XF86MonBrightnessUp", hl.dsp
            .exec_cmd("brightnessctl -e4 -n2 set " .. brightnessStep .. "%+"),
        {locked = true, repeating = true})
hl.bind("XF86MonBrightnessDown", hl.dsp
            .exec_cmd("brightnessctl -e4 -n2 set " .. brightnessStep .. "%-"),
        {locked = true, repeating = true})

hl.bind(mod .. " + SHIFT + up",
        hl.dsp.exec_cmd("brightnessctl -e4 -n4 set " .. brightnessStep .. "%+"))
hl.bind(mod .. " + SHIFT + down", hl.dsp
            .exec_cmd("brightnessctl -e4 -n25 set " .. brightnessStep .. "%-"))

-- Media Player Controls (via playerctl)
local function audioctl(key, command)
    hl.bind(key, hl.dsp.exec_cmd("playerctl " .. command), {locked = true})
end

audioctl("XF86AudioNext", "next")
audioctl("XF86AudioPause", "play-pause")
audioctl("XF86AudioPlay", "play-pause")
audioctl("XF86AudioPrev", "previous")

-- =============================================================================
-- 8. ADVANCED LOGIC & DYNAMIC HANDLERS
-- =============================================================================

-- Game Mode Toggle
hl.bind(mainMod .. " + G", function()
    local game_mode = (hl.get_config("animations.enabled") == false)

    if game_mode then
        hl.exec_cmd("hyprctl reload")
        hl.exec_cmd("notify-send \"Game Mode\" \"Disabled\"")
        return
    end

    hl.config({
        general = {gaps_in = 0, gaps_out = 0, border_size = 0},
        animations = {enabled = false},
        decoration = {
            active_opacity = 1,
            inactive_opacity = 1,
            shadow = {enabled = false},
            blur = {enabled = false},
            rounding = 0
        }
    })

    hl.window_rule({
        match = {class = "Spotify"},
        opacity = "1.0 override 1.0 override"
    })

    hl.window_rule({
        match = {class = "md.obsidian.Obsidian"},
        opacity = "1.0 override 1.0 override"
    })

    hl.exec_cmd("notify-send \"Game Mode\" \"Enabled\"")
end)

-- Dynamic Layout Switcher (Dwindle <-> Scrolling)
local previous_layout = {}

hl.bind(mod .. " + S", function()
    local workspace = hl.get_active_special_workspace() or
                          hl.get_active_workspace()
    if not workspace then return end

    local ws_id = tostring(workspace.id)

    if workspace.tiled_layout == "scrolling" then
        -- Restore previous layout before scrolling
        local layout = previous_layout[ws_id] or "dwindle"
        hl.workspace_rule({workspace = ws_id, layout = layout})
        previous_layout[ws_id] = nil
    else
        -- Remember current layout before switching to scrolling
        previous_layout[ws_id] = workspace.tiled_layout
        hl.workspace_rule({workspace = ws_id, layout = "scrolling"})
    end
end)

-- Scrolling Layout Column Resizing
hl.bind(mod .. " + equal", hl.dsp.layout("colresize +0.1"))
hl.bind(mod .. " + minus", hl.dsp.layout("colresize -0.1"))
hl.bind(mod .. " + 0", hl.dsp.layout("colresize +conf"))
