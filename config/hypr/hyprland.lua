-- =============================================================================
-- HYPRLAND MAIN CONFIGURATION
-- =============================================================================
-- Documentation: https://wiki.hypr.land/Configuring/Start/

-- -----------------------------------------------------------------------------
-- System & Environment
-- -----------------------------------------------------------------------------
require("modules.monitors")
require("modules.autostart")
require("modules.env")

-- -----------------------------------------------------------------------------
-- Visuals, Appearance & Layout
-- -----------------------------------------------------------------------------
require("modules.decorations")
require("modules.animations")
require("modules.layout")
require("modules.misc")

-- -----------------------------------------------------------------------------
-- Input, Keybindings & Window Rules
-- -----------------------------------------------------------------------------
require("modules.input")
require("modules.binds")
require("modules.windowrules")
require("modules.workspaces")
