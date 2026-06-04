-- Improved Hyprland animations
-- Philosophy: snappy entries, graceful exits, spring-driven windows, smooth workspace glides
-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Animations/
-- === Curves ===
-- Standard bezier curves
hl.curve("easeOutQuint", {type = "bezier", points = {{0.23, 1}, {0.32, 1}}})
hl.curve("easeInOutCubic", {type = "bezier", points = {{0.65, 0.05}, {0.36, 1}}})
hl.curve("linear", {type = "bezier", points = {{0, 0}, {1, 1}}})
hl.curve("almostLinear", {type = "bezier", points = {{0.5, 0.5}, {0.75, 1}}})
hl.curve("quick", {type = "bezier", points = {{0.15, 0}, {0.1, 1}}})
hl.curve("easeInOut", {type = "bezier", points = {{0.42, 0}, {0.58, 1}}})

-- Overshoot curve for snappy open feel
hl.curve("overshoot", {type = "bezier", points = {{0.05, 0.9}, {0.1, 1.1}}})

-- Springs
hl.curve("easy", {
    type = "spring",
    mass = 1,
    stiffness = 71.2633,
    dampening = 15.8273644
})

-- Bouncier spring for window open — perceptibly alive, not wobbly
hl.curve("windowSpring",
         {type = "spring", mass = 1, stiffness = 120, dampening = 20})

-- Tight spring for layers / panels (no overshooting UI chrome)
hl.curve("layerSpring",
         {type = "spring", mass = 1, stiffness = 200, dampening = 28})

-- === Animations ===

-- Global fallback
hl.animation({leaf = "global", enabled = true, speed = 10, bezier = "default"})

-- Border glow — fast enough to not lag focus switches
hl.animation({
    leaf = "border",
    enabled = true,
    speed = 3.5,
    bezier = "easeOutQuint"
})

-- Windows: spring for all, but tune In/Out separately
hl.animation({
    leaf = "windows",
    enabled = true,
    speed = 4.5,
    spring = "windowSpring"
})

-- Open: pop in with slight overshoot — feels alive
hl.animation({
    leaf = "windowsIn",
    enabled = true,
    speed = 1.8,
    bezier = "overshoot",
    style = "popin 80%"
})

-- Close: quick fade-slide out — don't linger
hl.animation({
    leaf = "windowsOut",
    enabled = true,
    speed = 1.2,
    bezier = "easeInOut",
    style = "popin 80%"
})

-- Fade: slightly quicker for snappiness
hl.animation({
    leaf = "fadeIn",
    enabled = true,
    speed = 1.5,
    bezier = "almostLinear"
})
hl.animation({
    leaf = "fadeOut",
    enabled = true,
    speed = 1.2,
    bezier = "almostLinear"
})
hl.animation({leaf = "fade", enabled = true, speed = 2.8, bezier = "quick"})

-- Layers (e.g. waybar, rofi, notifications): spring-driven, no style jank
hl.animation({
    leaf = "layers",
    enabled = true,
    speed = 3.2,
    spring = "layerSpring"
})
hl.animation({
    leaf = "layersIn",
    enabled = true,
    speed = 2.5,
    bezier = "easeOutQuint",
    style = "fade"
})
hl.animation({
    leaf = "layersOut",
    enabled = true,
    speed = 1.4,
    bezier = "easeInOut",
    style = "fade"
})

hl.animation({
    leaf = "fadeLayersIn",
    enabled = true,
    speed = 1.6,
    bezier = "almostLinear"
})
hl.animation({
    leaf = "fadeLayersOut",
    enabled = true,
    speed = 1.2,
    bezier = "almostLinear"
})

-- Workspaces: smooth directional slide, not a raw fade
hl.animation({
    leaf = "workspaces",
    enabled = true,
    speed = 2.2,
    bezier = "easeInOutCubic",
    style = "slidefade 7%"
})
hl.animation({
    leaf = "workspacesIn",
    enabled = true,
    speed = 1.8,
    bezier = "easeInOutCubic",
    style = "slidefade 10%"
})
hl.animation({
    leaf = "workspacesOut",
    enabled = true,
    speed = 1.5,
    bezier = "easeInOut",
    style = "slidefade 10%"
})

-- Special workspace (scratchpad): drops in from above, fades out
hl.animation({
    leaf = "specialWorkspaceIn",
    enabled = true,
    speed = 1.6,
    bezier = "easeOutQuint",
    style = "slidefadevert 17%"
})
hl.animation({
    leaf = "specialWorkspaceOut",
    enabled = true,
    speed = 1.3,
    bezier = "easeInOut",
    style = "slidefadevert 7%"
})

-- Zoom: slightly softer so it doesn't feel like a snap
hl.animation({
    leaf = "zoomFactor",
    enabled = true,
    speed = 5,
    bezier = "easeOutQuint"
})
