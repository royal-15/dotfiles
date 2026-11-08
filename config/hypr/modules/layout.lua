-- =============================================================================
-- WINDOW LAYOUTS
-- =============================================================================
-- Documentation: https://wiki.hypr.land/Configuring/Layouts/

-- -----------------------------------------------------------------------------
-- Default Layout
-- -----------------------------------------------------------------------------
hl.config({
    general = {
        layout = "dwindle",
    },
})

-- -----------------------------------------------------------------------------
-- Dwindle Layout Settings
-- -----------------------------------------------------------------------------
-- See https://wiki.hypr.land/Configuring/Layouts/Dwindle-Layout/
hl.config({
    dwindle = {
        preserve_split = true,
    },
})

-- -----------------------------------------------------------------------------
-- Master Layout Settings
-- -----------------------------------------------------------------------------
-- See https://wiki.hypr.land/Configuring/Layouts/Master-Layout/
hl.config({
    master = {
        new_status = "master",
    },
})

-- -----------------------------------------------------------------------------
-- Scrolling Layout Settings
-- -----------------------------------------------------------------------------
-- See https://wiki.hypr.land/Configuring/Layouts/Scrolling-Layout/
hl.config({
    scrolling = {
        fullscreen_on_one_column = true,
        column_width             = 0.8,
        explicit_column_widths   = "0.35, 0.5, 0.7, 1.0",
    },
})
