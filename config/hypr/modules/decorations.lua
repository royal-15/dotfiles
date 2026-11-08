-- =============================================================================
-- DECORATIONS & WINDOW STYLING
-- =============================================================================
-- Documentation: https://wiki.hypr.land/Configuring/Variables/

-- Dynamic theme colors (managed by theme-switcher)
require("modules.theme_decorations")

hl.config({
    general = {
        gaps_in          = 4,
        gaps_out         = 7,
        border_size      = 1,
        resize_on_border = false,
        allow_tearing    = false,
    },

    decoration = {
        rounding         = 15,
        rounding_power   = 3,

        -- Opacity
        active_opacity   = 0.93,
        inactive_opacity = 0.90,

        -- Drop Shadows
        shadow = {
            enabled      = true,
            range        = 9,
            render_power = 3,
        },

        -- Background Blur
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
