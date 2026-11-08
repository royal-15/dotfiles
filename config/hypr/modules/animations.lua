-- =============================================================================
-- ANIMATIONS & TRANSITIONS
-- =============================================================================
-- Philosophy: Apple-like fluid motion — smooth easing curves, natural motion
-- timing, critically damped spring physics, and subtle spatial transitions.
-- Documentation: https://wiki.hypr.land/Configuring/Animations/

-- =============================================================================
-- 1. CURVES & SPRINGS
-- =============================================================================

-- Apple Core Animation Bézier Curves
-- Iconic fluid ease-out: rapid initial velocity that imperceptibly coasts into resting position
hl.curve("appleEase",      {type = "bezier", points = {{0.16, 1}, {0.3, 1}}})
-- Accelerated departure curve for clean, asymmetric exits
hl.curve("appleEaseIn",    {type = "bezier", points = {{0.32, 0}, {0.67, 0}}})
-- Balanced ease-in-out for symmetric transitions
hl.curve("appleEaseInOut", {type = "bezier", points = {{0.42, 0}, {0.58, 1}}})

-- Standard & Supporting Bézier Curves
hl.curve("easeOutQuint",   {type = "bezier", points = {{0.23, 1}, {0.32, 1}}})
hl.curve("easeInOutCubic", {type = "bezier", points = {{0.65, 0.05}, {0.36, 1}}})
hl.curve("linear",         {type = "bezier", points = {{0, 0}, {1, 1}}})
hl.curve("almostLinear",   {type = "bezier", points = {{0.5, 0.5}, {0.75, 1}}})
hl.curve("quick",          {type = "bezier", points = {{0.15, 0}, {0.1, 1}}})

-- Spring Curves
-- Critically Damped Spring (zeta = 1.0) for Window Move & Dynamic Tiling Settling
-- Mass = 1, Stiffness = 169, Dampening = 26 (2 * sqrt(1 * 169) = 26)
-- Provides weighted, velvety settling with zero bounce or oscillation
hl.curve("windowSpring", {
    type      = "spring",
    mass      = 1,
    stiffness = 169,
    dampening = 26,
})

-- Critically Damped Layer Spring (zeta = 1.0)
-- Mass = 1, Stiffness = 225, Dampening = 30 (2 * sqrt(1 * 225) = 30)
hl.curve("layerSpring", {
    type      = "spring",
    mass      = 1,
    stiffness = 225,
    dampening = 30,
})

-- Balanced auxiliary spring
hl.curve("easy", {
    type      = "spring",
    mass      = 1,
    stiffness = 238.1191,
    dampening = 24.21279333,
})

-- =============================================================================
-- 2. ANIMATION TREES
-- =============================================================================

-- Global Fallback
hl.animation({
    leaf    = "global",
    enabled = true,
    speed   = 10,
    bezier  = "default",
})

-- Border Glow
hl.animation({
    leaf    = "border",
    enabled = true,
    speed   = 3.5,
    bezier  = "easeOutQuint",
})

-- Windows (Spring-driven moving/tiling, subtle Apple popin for open/close)
hl.animation({
    leaf    = "windows",
    enabled = true,
    speed   = 4.2,
    spring  = "windowSpring",
})

hl.animation({
    leaf    = "windowsIn",
    enabled = true,
    speed   = 2.8,
    bezier  = "appleEase",
    style   = "popin 92%",
})

hl.animation({
    leaf    = "windowsOut",
    enabled = true,
    speed   = 1.8,
    bezier  = "appleEaseIn",
    style   = "popin 95%",
})

-- Window Fade
hl.animation({
    leaf    = "fadeIn",
    enabled = true,
    speed   = 2.0,
    bezier  = "appleEase",
})

hl.animation({
    leaf    = "fadeOut",
    enabled = true,
    speed   = 1.5,
    bezier  = "appleEaseIn",
})

hl.animation({
    leaf    = "fade",
    enabled = true,
    speed   = 2.5,
    bezier  = "appleEase",
})

-- Layer Shells (e.g. Quickshell, Waybar, Rofi, Notifications, Menus)
hl.animation({
    leaf    = "layers",
    enabled = true,
    speed   = 3.0,
    spring  = "layerSpring",
})

hl.animation({
    leaf    = "layersIn",
    enabled = true,
    speed   = 2.2,
    bezier  = "appleEase",
    style   = "popin 94%",
})

hl.animation({
    leaf    = "layersOut",
    enabled = true,
    speed   = 1.4,
    bezier  = "appleEaseIn",
    style   = "popin 97%",
})

hl.animation({
    leaf    = "fadeLayersIn",
    enabled = true,
    speed   = 1.8,
    bezier  = "appleEase",
})

hl.animation({
    leaf    = "fadeLayersOut",
    enabled = true,
    speed   = 1.2,
    bezier  = "appleEaseIn",
})

-- Workspaces (Smooth horizontal glide with gentle crossfade matching macOS Spaces)
hl.animation({
    leaf    = "workspaces",
    enabled = true,
    speed   = 3.2,
    bezier  = "easeInOutCubic",
    style   = "slidefade 18%",
})

hl.animation({
    leaf    = "workspacesIn",
    enabled = true,
    speed   = 3.0,
    bezier  = "appleEase",
    style   = "slidefade 18%",
})

hl.animation({
    leaf    = "workspacesOut",
    enabled = true,
    speed   = 2.4,
    bezier  = "appleEaseIn",
    style   = "slidefade 18%",
})

-- Special Workspaces / Scratchpads
hl.animation({
    leaf    = "specialWorkspaceIn",
    enabled = true,
    speed   = 2.6,
    bezier  = "appleEase",
    style   = "slidefadevert 12%",
})

hl.animation({
    leaf    = "specialWorkspaceOut",
    enabled = true,
    speed   = 2.0,
    bezier  = "appleEaseIn",
    style   = "slidefadevert 8%",
})

-- Zoom Factor
hl.animation({
    leaf    = "zoomFactor",
    enabled = true,
    speed   = 4.5,
    bezier  = "appleEase",
})
