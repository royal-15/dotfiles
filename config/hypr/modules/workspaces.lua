--------------------
---- WORKSPACES ----
--------------------
local monitor_bindings = {
    {monitor = "eDP-1", workspaces = {4, 5, 6}},
    {monitor = "HDMI-A-1", workspaces = {1, 2, 3}}
}

for _, binding in ipairs(monitor_bindings) do
    for _, ws in ipairs(binding.workspaces) do
        hl.workspace_rule({
            workspace = tostring(ws),
            monitor = binding.monitor
            -- persistent = true
        })
    end
end

local special_workspaces = {
    {workspace = "special:s1", layout = "scrolling"},
    {workspace = "special:s2", layout = "scrolling"},
    {workspace = "special:s3", layout = "scrolling"}
}

for _, config in ipairs(special_workspaces) do
    hl.workspace_rule({
        workspace = tostring(config.workspace),
        layout = config.layout
    })
end
