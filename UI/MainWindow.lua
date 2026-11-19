-- The single Gear Path window: set picker bar, Slot list, Source panel and Share bar.
-- Step 1 builds the empty frame; later steps fill each area.
local addonName, ns = ...

local Theme = ns.Theme
local C = Theme.colors
local S = Theme.size

local MainWindow = {}
ns.MainWindow = MainWindow

local FLAT = "Interface\\Buttons\\WHITE8x8"
-- Newer clients need BackdropTemplate for SetBackdrop; older ones have it built in.
local BACKDROP = BackdropTemplateMixin and "BackdropTemplate" or nil

local function paint(frame, bg, border, edgeSize)
    frame:SetBackdrop({ bgFile = FLAT, edgeFile = FLAT, edgeSize = edgeSize or 1 })
    frame:SetBackdropColor(unpack(bg))
    frame:SetBackdropBorderColor(unpack(border))
end

local function text(parent, template, color, value)
    local fs = parent:CreateFontString(nil, "OVERLAY", template)
    if color then fs:SetTextColor(unpack(color)) end
    if value then fs:SetText(value) end
    return fs
end

local function divider(parent, anchorTo, y)
    local line = parent:CreateTexture(nil, "ARTWORK")
    line:SetColorTexture(unpack(C.divider))
    line:SetHeight(1)
    line:SetPoint("TOPLEFT", anchorTo, "TOPLEFT", 2, y)
    line:SetPoint("TOPRIGHT", anchorTo, "TOPRIGHT", -2, y)
    return line
end

local function panel(parent)
    local p = CreateFrame("Frame", nil, parent, BACKDROP)
    paint(p, C.panel, C.panelBorder)
    return p
end

local function build()
    local f = CreateFrame("Frame", "GearPathFrame", UIParent, BACKDROP)
    f:SetSize(S.width, S.height)
    f:SetPoint("CENTER")
    f:SetFrameStrata("HIGH")
    f:SetToplevel(true)
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:EnableMouse(true)
    paint(f, C.window, C.windowBorder, 2)
    f:Hide()

    -- Close with Escape like Blizzard panels.
    tinsert(UISpecialFrames, f:GetName())

    -- Title bar (drag to move).
    local title = CreateFrame("Frame", nil, f)
    title:SetPoint("TOPLEFT", 2, -2)
    title:SetPoint("TOPRIGHT", -2, -2)
    title:SetHeight(S.titleBar - 2)
    local titleBg = title:CreateTexture(nil, "BACKGROUND")
    titleBg:SetAllPoints()
    titleBg:SetColorTexture(unpack(C.titleBar))
    title:EnableMouse(true)
    title:RegisterForDrag("LeftButton")
    title:SetScript("OnDragStart", function() f:StartMoving() end)
    title:SetScript("OnDragStop", function() f:StopMovingOrSizing() end)

    local titleText = text(title, "GameFontNormalLarge", C.gold, "Gear Path")
    titleText:SetPoint("LEFT", 14, 0)

    local close = CreateFrame("Button", nil, title, "UIPanelCloseButton")
    close:SetPoint("RIGHT", 2, 0)
    close:SetScript("OnClick", function() f:Hide() end)

    divider(f, f, -S.titleBar)

    -- Set picker bar (filled in by the Gear Set work).
    local setBar = CreateFrame("Frame", nil, f)
    setBar:SetPoint("TOPLEFT", 0, -S.titleBar)
    setBar:SetPoint("TOPRIGHT", 0, -S.titleBar)
    setBar:SetHeight(S.setBar)
    local setLabel = text(setBar, "GameFontHighlight", C.muted, "Gear Set")
    setLabel:SetPoint("LEFT", S.padding, 0)
    local setName = text(setBar, "GameFontNormal", C.muted, "No Gear Sets yet")
    setName:SetPoint("LEFT", setLabel, "RIGHT", 10, 0)
    f.setName = setName

    divider(f, f, -(S.titleBar + S.setBar))

    -- Body: Slot list on the left, Source panel on the right.
    local bodyTop = S.titleBar + S.setBar + S.gap
    local bodyBottom = S.footer + S.gap

    local slots = panel(f)
    slots:SetPoint("TOPLEFT", S.padding, -bodyTop)
    slots:SetPoint("BOTTOMLEFT", S.padding, bodyBottom)
    slots:SetWidth(S.slotPanelWidth)
    local slotsHeader = text(slots, "GameFontNormalSmall", C.label, "SLOTS")
    slotsHeader:SetPoint("TOPLEFT", 10, -8)
    f.slotPanel = slots

    local source = panel(f)
    source:SetPoint("TOPLEFT", slots, "TOPRIGHT", S.gap, 0)
    source:SetPoint("BOTTOMRIGHT", -S.padding, bodyBottom)
    local sourceHint = text(source, "GameFontHighlight", C.muted, "Choose a Slot to see where its item comes from.")
    sourceHint:SetPoint("CENTER")
    f.sourcePanel = source

    -- Share bar.
    divider(f, f, -(S.height - S.footer))
    local shareLabel = text(f, "GameFontNormalSmall", C.label, "SHARE")
    shareLabel:SetPoint("BOTTOMLEFT", S.padding, S.footer - 26)
    local shareHint = text(f, "GameFontHighlight", C.muted,
        "Export this Gear Set as a Share String, or import one from another character or player.")
    shareHint:SetPoint("TOPLEFT", shareLabel, "BOTTOMLEFT", 0, -10)

    return f
end

function MainWindow:Get()
    if not self.frame then
        self.frame = build()
    end
    return self.frame
end

function MainWindow:Toggle()
    local f = self:Get()
    f:SetShown(not f:IsShown())
end
