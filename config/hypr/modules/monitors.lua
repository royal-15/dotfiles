
------------------
---- MONITORS ----
------------------

-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
hl.monitor({
    output   = "eDP-1",
    mode     = "1366x768@59.99",
    position = "auto",
    scale    = "1",
})

hl.monitor({
    output   = "HDMI-A-1",
    mode     = "1366x768@75",
    position = "auto",
    scale    = "1",
})

--------------------
---- WORKSPACES ----
local monitor_bindings = {
    { monitor = "eDP-1", workspaces = { 4, 5, 6 } },
    { monitor = "HDMI-A-1", workspaces = { 1, 2, 3 } }
}

for _, binding in ipairs(monitor_bindings) do
    for _, ws in ipairs(binding.workspaces) do
        hl.workspace_rule({
            workspace = tostring(ws),
            monitor = binding.monitor,
            -- persistent = true
        })
    end
end