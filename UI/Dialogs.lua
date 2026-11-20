-- Name and confirm dialogs for Gear Sets, styled like the window (see the step 2 mockup).
local _, ns = ...

local W = ns.Widgets
local C = ns.Theme.colors

local Dialogs = {}
ns.Dialogs = Dialogs

local WIDTH, PAD, INNER = 340, 18, 304

local function base(name, border)
    local f = CreateFrame("Frame", name, UIParent, W.BACKDROP)
    f:SetWidth(WIDTH)
    f:SetFrameStrata("DIALOG")
    f:SetToplevel(true)
    f:EnableMouse(true)
    f:SetClampedToScreen(true)
    W.Paint(f, C.window, border, 2)
    f:Hide()
    tinsert(UISpecialFrames, name)

    f.title = W.Text(f, "GameFontNormalLarge", C.gold)
    f.title:SetPoint("TOP", 0, -PAD)
    f.title:SetWidth(INNER)
    return f
end

local function place(f)
    f:ClearAllPoints()
    local main = _G.GearPathFrame
    if main and main:IsShown() then
        f:SetPoint("CENTER", main, "CENTER", 0, 40)
    else
        f:SetPoint("CENTER", UIParent, "CENTER", 0, 120)
    end
end

local function wrapped(f, color)
    local fs = W.Text(f, "GameFontHighlight", color)
    fs:SetWidth(INNER)
    fs:SetJustifyH("CENTER")
    fs:SetWordWrap(true)
    return fs
end

-- Name dialog: New set, and Rename (with the delete link).
local nameDialog

local function buildNameDialog()
    local f = base("GearPathNameDialog", C.windowBorder)

    f.label = W.Text(f, "GameFontHighlightSmall", C.muted)
    f.label:SetPoint("TOPLEFT", PAD, -50)

    f.edit = W.EditBox(f, INNER)
    f.edit:SetMaxLetters(40)
    f.edit:SetPoint("TOPLEFT", f.label, "BOTTOMLEFT", 0, -4)

    f.hint = wrapped(f, C.warning)
    f.hint:SetJustifyH("LEFT")
    f.hint:SetPoint("TOPLEFT", f.edit, "BOTTOMLEFT", 0, -10)

    f.confirm = W.Button(f, "Create", "red", 96)
    f.cancel = W.Button(f, "Cancel", "plain", 96)
    f.cancel:SetScript("OnClick", function() f:Hide() end)

    f.divider = f:CreateTexture(nil, "ARTWORK")
    f.divider:SetColorTexture(unpack(C.panelBorder))
    f.divider:SetSize(INNER, 1)

    f.link = W.Link(f, "", C.deleteLink)

    local function submit()
        if not f.confirm:IsEnabled() then return end
        local name = f.edit:GetText()
        f:Hide()
        if f.onConfirm then f.onConfirm(name) end
    end
    f.confirm:SetScript("OnClick", submit)
    f.edit:SetScript("OnEnterPressed", submit)
    f.edit:SetScript("OnEscapePressed", function() f:Hide() end)
    f.edit:SetScript("OnTextChanged", function() f:Refresh() end)

    function f:Refresh()
        local typed = self.edit:GetText()
        local clean = ns.GearSets.CleanName(typed)
        if clean then self.confirm:Enable() else self.confirm:Disable() end
        local hint = clean and self.hintFor and self.hintFor(clean) or nil

        local height = 50 + 12 + 4 + 30
        local below = self.edit
        if hint then
            self.hint:SetText(hint)
            self.hint:Show()
            height = height + 10 + self.hint:GetStringHeight()
            below = self.hint
        else
            self.hint:Hide()
        end

        self.confirm:ClearAllPoints()
        self.confirm:SetPoint("TOPRIGHT", below, "BOTTOM", -4, -14)
        self.cancel:ClearAllPoints()
        self.cancel:SetPoint("LEFT", self.confirm, "RIGHT", 8, 0)
        height = height + 14 + 28

        if self.linkAction then
            self.divider:ClearAllPoints()
            self.divider:SetPoint("TOP", self.confirm, "BOTTOMRIGHT", 4, -14)
            self.divider:Show()
            self.link:ClearAllPoints()
            self.link:SetPoint("TOP", self.divider, "BOTTOM", 0, -8)
            self.link:Show()
            height = height + 14 + 1 + 8 + 22
        else
            self.divider:Hide()
            self.link:Hide()
        end
        self:SetHeight(height + 16)
    end

    return f
end

--- opts: title, label, text, confirmText, hintFor(cleanName) -> string|nil,
---       onConfirm(name), linkText, onLink()
function Dialogs.ShowName(opts)
    nameDialog = nameDialog or buildNameDialog()
    local f = nameDialog
    if Dialogs.confirmDialog then Dialogs.confirmDialog:Hide() end
    f.title:SetText(opts.title)
    f.label:SetText(opts.label or "Name")
    f.confirm.label:SetText(opts.confirmText or "OK")
    f.hintFor = opts.hintFor
    f.onConfirm = opts.onConfirm
    f.linkAction = opts.onLink
    if opts.onLink then
        f.link.label:SetText(opts.linkText)
        f.link:SetWidth(f.link.label:GetStringWidth() + 12)
        f.link:SetScript("OnClick", function()
            f:Hide()
            opts.onLink()
        end)
    end
    f.edit:SetText(opts.text or "")
    place(f)
    f:Show()
    f:Refresh()
    f.edit:SetFocus()
    f.edit:HighlightText()
end

-- Confirm dialog: Delete Gear Set.
local function buildConfirmDialog()
    local f = base("GearPathConfirmDialog", C.dangerBorder)
    f.body = wrapped(f, C.text)
    f.body:SetPoint("TOP", f.title, "BOTTOM", 0, -12)
    f.tip = wrapped(f, C.muted)
    f.tip:SetFontObject(GameFontHighlightSmall)
    f.tip:SetTextColor(unpack(C.muted))
    f.tip:SetPoint("TOP", f.body, "BOTTOM", 0, -10)

    f.confirm = W.Button(f, "Delete", "danger", 96)
    f.confirm:SetPoint("TOPRIGHT", f.tip, "BOTTOM", -4, -14)
    f.cancel = W.Button(f, "Cancel", "plain", 96)
    f.cancel:SetPoint("LEFT", f.confirm, "RIGHT", 8, 0)
    f.cancel:SetScript("OnClick", function() f:Hide() end)
    f.confirm:SetScript("OnClick", function()
        f:Hide()
        if f.onConfirm then f.onConfirm() end
    end)
    return f
end

--- opts: title, body, tip, confirmText, onConfirm()
function Dialogs.ShowConfirm(opts)
    Dialogs.confirmDialog = Dialogs.confirmDialog or buildConfirmDialog()
    local f = Dialogs.confirmDialog
    if nameDialog then nameDialog:Hide() end
    f.title:SetText(opts.title)
    f.body:SetText(opts.body)
    f.tip:SetText(opts.tip or "")
    f.confirm.label:SetText(opts.confirmText or "OK")
    f.onConfirm = opts.onConfirm
    local height = 18 + f.title:GetStringHeight() + 12 + f.body:GetStringHeight()
        + 10 + f.tip:GetStringHeight() + 14 + 28 + 16
    f:SetHeight(height)
    place(f)
    f:Show()
end

function Dialogs.HideAll()
    if nameDialog then nameDialog:Hide() end
    if Dialogs.confirmDialog then Dialogs.confirmDialog:Hide() end
end
