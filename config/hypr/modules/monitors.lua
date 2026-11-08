-- =============================================================================
-- MONITORS CONFIGURATION
-- =============================================================================
-- Documentation: https://wiki.hypr.land/Configuring/Monitors/

-- Built-in Laptop Display
hl.monitor({
    output   = "eDP-1",
    mode     = "1366x768@59.99",
    position = "auto",
    scale    = "1",
})

-- External Monitor
hl.monitor({
    output   = "HDMI-A-2",
    mode     = "1366x768@75",
    position = "auto",
    scale    = "1",
})
