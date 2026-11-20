-- Small building blocks shared by the window and dialogs, styled like the mockup.
local _, ns = ...

local C = ns.Theme.colors

local Widgets = {}
ns.Widgets = Widgets

local FLAT = "Interface\\Buttons\\WHITE8x8"
-- Newer clients need BackdropTemplate for SetBackdrop; older ones have it built in.
Widgets.BACKDROP = BackdropTemplateMixin and "BackdropTemplate" or nil

function Widgets.Paint(frame, bg, border, edgeSize)
    frame:SetBackdrop({ bgFile = FLAT, edgeFile = FLAT, edgeSize = edgeSize or 1 })
    frame:SetBackdropColor(unpack(bg))
    frame:SetBackdropBorderColor(unpack(border))
end

function Widgets.Text(parent, template, color, value)
    local fs = parent:CreateFontString(nil, "OVERLAY", template)
    if color then fs:SetTextColor(unpack(color)) end
    if value then fs:SetText(value) end
    return fs
end

function Widgets.Panel(parent)
    local p = CreateFrame("Frame", nil, parent, Widgets.BACKDROP)
    Widgets.Paint(p, C.panel, C.panelBorder)
    return p
end

function Widgets.Divider(parent, y)
    local line = parent:CreateTexture(nil, "ARTWORK")
    line:SetColorTexture(unpack(C.divider))
    line:SetHeight(1)
    line:SetPoint("TOPLEFT", parent, "TOPLEFT", 2, y)
    line:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -2, y)
    return line
end

-- Button styles from the mockup.
local STYLES = {
    red    = { bg = C.buttonRed, border = C.buttonBorder, text = C.buttonText, hover = C.gold },
    plain  = { bg = C.buttonPlain, border = C.windowBorder, text = C.text, hover = C.label },
    danger = { bg = C.dangerRed, border = C.gold, text = C.white, hover = C.white },
}

--- A text button. style is "red" (default), "plain" or "danger".
function Widgets.Button(parent, label, style, width, height)
    local s = STYLES[style or "red"]
    local b = CreateFrame("Button", nil, parent, Widgets.BACKDROP)
    b:SetSize(width or 96, height or 28)
    Widgets.Paint(b, s.bg, s.border)
    b.label = Widgets.Text(b, "GameFontNormal", s.text, label)
    b.label:SetPoint("CENTER")
    if not width then b:SetWidth(math.max(96, b.label:GetStringWidth() + 28)) end

    b:SetScript("OnEnter", function(self)
        if self:IsEnabled() then self:SetBackdropBorderColor(unpack(s.hover)) end
    end)
    b:SetScript("OnLeave", function(self) self:SetBackdropBorderColor(unpack(s.border)) end)
    b:SetScript("OnMouseDown", function(self)
        if self:IsEnabled() then self.label:SetPoint("CENTER", 1, -1) end
    end)
    b:SetScript("OnMouseUp", function(self) self.label:SetPoint("CENTER") end)
    b:SetScript("OnDisable", function(self) self:SetAlpha(0.45) end)
    b:SetScript("OnEnable", function(self) self:SetAlpha(1) end)
    return b
end

--- An underlined text link, used for "Delete this Gear Set…".
function Widgets.Link(parent, label, color)
    local b = CreateFrame("Button", nil, parent)
    b.label = Widgets.Text(b, "GameFontNormal", color, label)
    b.label:SetPoint("CENTER")
    b:SetSize(b.label:GetStringWidth() + 12, 22)
    local underline = b:CreateTexture(nil, "ARTWORK")
    underline:SetColorTexture(unpack(color))
    underline:SetHeight(1)
    underline:SetPoint("TOPLEFT", b.label, "BOTTOMLEFT", 0, -1)
    underline:SetPoint("TOPRIGHT", b.label, "BOTTOMRIGHT", 0, -1)
    return b
end

--- Square red button with a gold border and a thin gold X.
function Widgets.CloseButton(parent)
    local b = CreateFrame("Button", nil, parent, Widgets.BACKDROP)
    b:SetSize(26, 26)
    Widgets.Paint(b, C.buttonRed, C.buttonBorder)

    local strokes = {}
    for i, angle in ipairs({ math.pi / 4, -math.pi / 4 }) do
        local line = b:CreateTexture(nil, "OVERLAY")
        line:SetColorTexture(unpack(C.buttonText))
        line:SetSize(2, 14)
        line:SetPoint("CENTER")
        line:SetRotation(angle)
        strokes[i] = line
    end

    local function setX(color)
        for _, line in ipairs(strokes) do line:SetColorTexture(unpack(color)) end
    end
    b:SetScript("OnEnter", function()
        b:SetBackdropBorderColor(unpack(C.gold))
        setX(C.gold)
    end)
    b:SetScript("OnLeave", function()
        b:SetBackdropBorderColor(unpack(C.buttonBorder))
        setX(C.buttonText)
    end)
    b:SetScript("OnMouseDown", function() b:SetBackdropColor(unpack(C.buttonRedPressed)) end)
    b:SetScript("OnMouseUp", function() b:SetBackdropColor(unpack(C.buttonRed)) end)
    return b
end

--- A single-line text box.
function Widgets.EditBox(parent, width)
    local e = CreateFrame("EditBox", nil, parent, Widgets.BACKDROP)
    e:SetSize(width, 30)
    Widgets.Paint(e, C.black, C.windowBorder)
    e:SetFontObject(ChatFontNormal)
    e:SetTextColor(unpack(C.text))
    e:SetTextInsets(10, 10, 0, 0)
    e:SetAutoFocus(false)
    e:SetScript("OnEditFocusGained", function(self) self:SetBackdropBorderColor(unpack(C.gold)) end)
    e:SetScript("OnEditFocusLost", function(self) self:SetBackdropBorderColor(unpack(C.windowBorder)) end)
    return e
end
