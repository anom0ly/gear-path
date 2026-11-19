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
    buttonPlain = rgb("2a2418"),
    dangerRed = rgb("8a1a1a"),
    dangerBorder = rgb("8a2a1a"),
    warning = rgb("d6c39a"),
    deleteLink = rgb("ff8a6b"),
    faint = rgb("a39a83"),
    highlight = { 1, 0.82, 0, 0.10 },
    highlightBorder = rgb("8a6d2b"),
    white = rgb("ffffff"),
    black = rgb("000000"),
    emptyIcon = rgb("5a4d33"),
    ownedBar = rgb("5fae55"),
}

Theme.size = {
    width = 900,
    height = 720,
    titleBar = 38,
    setBar = 50,
    footer = 84,
    slotPanelWidth = 300,
    padding = 16,
    gap = 12,
    slotRow = 29,
}
