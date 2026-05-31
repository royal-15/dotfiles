-----------------------
---- LOOK AND FEEL ----
-----------------------

-- Refer to https://wiki.hypr.land/Configuring/Basics/Variables/
hl.config({
    general = {
        gaps_in  = 5,
        gaps_out = 10,

        border_size = 1,

        col = {
            active_border   = { colors = {"rgba(33ccffee)", "rgba(00ff99ee)"}, angle = 45 },
            inactive_border = "rgba(595959aa)",
        },

        -- Set to true to enable resizing windows by clicking and dragging on borders and gaps
        resize_on_border = false,

        -- Please see https://wiki.hypr.land/Configuring/Advanced-and-Cool/Tearing/ before you turn this on
        allow_tearing = false,
    },

    decoration = {
        rounding       = 15,
        rounding_power = 3,

        -- Change transparency of focused and unfocused windows
        active_opacity   = 0.93,
        inactive_opacity = 0.9,

        shadow = {
            enabled      = true,
            range        = 9,
            render_power = 3,
            color        = 0xee121212,
        },

        blur = {
            enabled   = true,
            size      = 15,
            passes    = 3,
            vibrancy  = 0.1696,
        },
    },

    animations = {
        enabled = true,
    },
})