-- Colors and sizes from the approved window mockup.
local _, ns = ...

local Theme = {}
ns.Theme = Theme

local function rgb(hex, alpha)
    local r = tonumber(hex:sub(1, 2), 16) / 255
    local g = tonumber(hex:sub(3, 4), 16) / 255
    local b = tonumber(hex:sub(5, 6), 16) / 255
    return { r, g, b, alpha or 1 }
end
Theme.rgb = rgb

Theme.colors = {
    window = rgb("15120d"),
    windowBorder = rgb("6b5527"),
    titleBar = rgb("1f1a12"),
    divider = rgb("3d3220"),
    panel = rgb("0d0b08"),
    panelBorder = rgb("3a3020"),
    gold = rgb("ffd100"),
    label = rgb("d4b04a"),
    text = rgb("e8e0cc"),
    muted = rgb("b3a88f"),
    buttonRed = rgb("5c0f0f"),
    buttonRedPressed = rgb("3d0a0a"),
    buttonBorder = rgb("a8862f"),
    buttonText = rgb("ffd76a"),
}

Theme.size = {
    width = 900,
    height = 700,
    titleBar = 38,
    setBar = 50,
    footer = 84,
    slotPanelWidth = 300,
    padding = 16,
    gap = 12,
}
