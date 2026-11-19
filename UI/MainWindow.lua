-- The single Gear Path window: set picker bar, Slot list, Source panel and Share bar.
local _, ns = ...

local W = ns.Widgets
local C = ns.Theme.colors
local S = ns.Theme.size

local MainWindow = {}
ns.MainWindow = MainWindow

local SLOT_COUNT = #ns.Slots

local function db() return ns.charDB end

-- Down chevron drawn from two short lines.
local function chevron(parent)
    local holder = CreateFrame("Frame", nil, parent)
    holder:SetSize(12, 12)
    for _, spec in ipairs({ { -2.5, math.pi / 4 }, { 2.5, -math.pi / 4 } }) do
        local line = holder:CreateTexture(nil, "OVERLAY")
        line:SetColorTexture(unpack(C.label))
        line:SetSize(2, 8)
        line:SetPoint("CENTER", spec[1], 0)
        line:SetRotation(spec[2])
    end
    return holder
end

---------------------------------------------------------------------------
-- Gear Set actions (dialogs from the step 2 mockup)
---------------------------------------------------------------------------

local function takenHint(clean, ignore)
    local final = ns.GearSets.UniqueName(db(), clean, ignore)
    if final ~= clean then
        return ("You already have a Gear Set called %s. This one will be saved as |cffffd100%s|r.")
            :format(clean, final)
    end
end

function MainWindow:NewSet()
    self:CloseMenu()
    ns.Dialogs.ShowName({
        title = "New Gear Set",
        label = "Name",
        confirmText = "Create",
        hintFor = function(clean) return takenHint(clean) end,
        onConfirm = function(name)
            if ns.GearSets.Create(db(), name) then
                self.selectedSlot = nil
                self:Refresh()
            end
        end,
    })
end

function MainWindow:DeleteSet(name)
    local count = ns.GearSets.ItemCount(ns.GearSets.Get(db(), name))
    local what = count == 1 and "its 1 chosen item" or ("its %d chosen items"):format(count)
    local body = count > 0
        and ("Delete |cffffd100%s|r and %s? This can't be undone."):format(name, what)
        or ("Delete |cffffd100%s|r? This can't be undone."):format(name)
    ns.Dialogs.ShowConfirm({
        title = "Delete Gear Set?",
        body = body,
        tip = "Tip: Export it as a Share String first if you might want it back.",
        confirmText = "Delete",
        onConfirm = function()
            ns.GearSets.Delete(db(), name)
            self.selectedSlot = nil
            self:Refresh()
        end,
    })
end

function MainWindow:RenameSet()
    self:CloseMenu()
    local current = ns.GearSets.Selected(db())
    if not current then return end
    ns.Dialogs.ShowName({
        title = current,
        label = "New name",
        text = current,
        confirmText = "Rename",
        hintFor = function(clean) return takenHint(clean, current) end,
        onConfirm = function(name)
            ns.GearSets.Rename(db(), current, name)
            self:Refresh()
        end,
        linkText = "Delete this Gear Set…",
        onLink = function() self:DeleteSet(current) end,
    })
end

---------------------------------------------------------------------------
-- Set picker menu
---------------------------------------------------------------------------

local MENU_ROW = 30

local function menuRow(menu, onClick)
    local b = CreateFrame("Button", nil, menu)
    b:SetSize(212, MENU_ROW)
    b.bg = b:CreateTexture(nil, "BACKGROUND")
    b.bg:SetAllPoints()
    b.bg:SetColorTexture(0, 0, 0, 0)
    b:SetHighlightTexture("Interface\\Buttons\\WHITE8x8")
    b:GetHighlightTexture():SetVertexColor(1, 0.82, 0, 0.06)
    b.name = W.Text(b, "GameFontHighlight", C.text)
    b.name:SetPoint("LEFT", 10, 0)
    b.name:SetPoint("RIGHT", -60, 0)
    b.name:SetJustifyH("LEFT")
    b.count = W.Text(b, "GameFontHighlightSmall", C.muted)
    b.count:SetPoint("RIGHT", -10, 0)
    b:SetScript("OnClick", onClick)
    return b
end

function MainWindow:BuildMenu(anchor)
    local menu = CreateFrame("Frame", nil, self.frame, W.BACKDROP)
    menu:SetWidth(220)
    menu:SetFrameStrata("DIALOG")
    menu:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -4)
    W.Paint(menu, C.panel, C.windowBorder)
    menu:Hide()
    menu.rows = {}

    menu.separator = menu:CreateTexture(nil, "ARTWORK")
    menu.separator:SetColorTexture(unpack(C.panelBorder))
    menu.separator:SetSize(204, 1)

    menu.new = menuRow(menu, function() self:NewSet() end)
    menu.new.name:SetText("+ New set…")
    menu.new.name:SetTextColor(unpack(C.buttonText))

    menu.manage = menuRow(menu, function() self:RenameSet() end)
    menu.manage.name:SetText("Rename or delete this set…")
    menu.manage.name:SetTextColor(unpack(C.muted))
    menu.manage.name:SetPoint("RIGHT", -10, 0)

    self.menu = menu
end

function MainWindow:RefreshMenu()
    local menu = self.menu
    local names = ns.GearSets.List(db())
    local selected = ns.GearSets.Selected(db())
    local y = -4
    for i, name in ipairs(names) do
        local row = menu.rows[i]
        if not row then
            row = menuRow(menu, function(b)
                ns.GearSets.Select(db(), b.setName)
                self.selectedSlot = nil
                self:CloseMenu()
                self:Refresh()
            end)
            menu.rows[i] = row
        end
        row.setName = name
        row.name:SetText(name)
        row.count:SetText(("0 of %d"):format(SLOT_COUNT))
        local on = name == selected
        row.name:SetTextColor(unpack(on and C.gold or C.text))
        row.bg:SetColorTexture(unpack(on and C.highlight or { 0, 0, 0, 0 }))
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", 4, y)
        row:Show()
        y = y - MENU_ROW
    end
    for i = #names + 1, #menu.rows do menu.rows[i]:Hide() end

    menu.separator:ClearAllPoints()
    menu.separator:SetPoint("TOPLEFT", 8, y - 3)
    y = y - 7
    menu.new:SetPoint("TOPLEFT", 4, y)
    menu.manage:SetPoint("TOPLEFT", 4, y - MENU_ROW)
    menu:SetHeight(-y + 2 * MENU_ROW + 4)
end

function MainWindow:ToggleMenu()
    if self.menu:IsShown() then
        self:CloseMenu()
    else
        self:RefreshMenu()
        self.menu:Show()
    end
end

function MainWindow:CloseMenu()
    if self.menu then self.menu:Hide() end
end

---------------------------------------------------------------------------
-- Slot list and Source panel
---------------------------------------------------------------------------

function MainWindow:BuildSlotRows(panel)
    self.slotRows = {}
    for i, slot in ipairs(ns.Slots) do
        local row = CreateFrame("Button", nil, panel, W.BACKDROP)
        row:SetHeight(S.slotRow)
        row:SetPoint("TOPLEFT", 4, -26 - (i - 1) * S.slotRow)
        row:SetPoint("RIGHT", panel, "RIGHT", -4, 0)
        row.slot = slot

        local icon = CreateFrame("Frame", nil, row, W.BACKDROP)
        icon:SetSize(22, 22)
        icon:SetPoint("LEFT", 6, 0)
        W.Paint(icon, { 0, 0, 0, 0 }, C.emptyIcon)

        row.slotLabel = W.Text(row, "GameFontHighlightSmall", C.muted, slot.label)
        row.slotLabel:SetPoint("TOPLEFT", icon, "TOPRIGHT", 8, 1)
        row.itemLabel = W.Text(row, "GameFontDisable", C.faint, "Empty")
        row.itemLabel:SetPoint("BOTTOMLEFT", icon, "BOTTOMRIGHT", 8, -1)
        row.status = W.Text(row, "GameFontHighlightSmall", C.faint, "Choose item")
        row.status:SetPoint("RIGHT", -8, 0)

        row:SetScript("OnClick", function()
            self.selectedSlot = slot.id
            self:Refresh()
        end)
        row:SetScript("OnEnter", function(r)
            if self.selectedSlot ~= slot.id then r:SetBackdropBorderColor(unpack(C.panelBorder)) end
        end)
        row:SetScript("OnLeave", function() self:RefreshSlotRows() end)
        self.slotRows[i] = row
    end
end

function MainWindow:RefreshSlotRows()
    for _, row in ipairs(self.slotRows) do
        if row.slot.id == self.selectedSlot then
            W.Paint(row, C.highlight, C.highlightBorder)
        else
            W.Paint(row, { 0, 0, 0, 0 }, { 0, 0, 0, 0 })
        end
    end
end

function MainWindow:RefreshSource()
    local f = self.frame
    local slot
    for _, s in ipairs(ns.Slots) do if s.id == self.selectedSlot then slot = s end end
    if slot then
        f.sourceHint:Hide()
        f.sourceTitle:SetText("Choose an item for " .. slot.label)
        f.sourceTitle:Show()
        f.sourceBody:SetText("No item chosen for this Slot yet.")
        f.sourceBody:Show()
    else
        f.sourceHint:Show()
        f.sourceTitle:Hide()
        f.sourceBody:Hide()
    end
end

---------------------------------------------------------------------------
-- Window
---------------------------------------------------------------------------

function MainWindow:Build()
    local f = CreateFrame("Frame", "GearPathFrame", UIParent, W.BACKDROP)
    self.frame = f
    f:SetSize(S.width, S.height)
    f:SetPoint("CENTER")
    f:SetFrameStrata("HIGH")
    f:SetToplevel(true)
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:EnableMouse(true)
    W.Paint(f, C.window, C.windowBorder, 2)
    f:Hide()
    f:SetScript("OnHide", function()
        self:CloseMenu()
        ns.Dialogs.HideAll()
    end)
    f:SetScript("OnMouseDown", function() self:CloseMenu() end)
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
    W.Text(title, "GameFontNormalLarge", C.gold, "Gear Path"):SetPoint("LEFT", 14, 0)
    local close = W.CloseButton(title)
    close:SetPoint("RIGHT", -8, 0)
    close:SetScript("OnClick", function() f:Hide() end)
    W.Divider(f, -S.titleBar)

    -- Set picker bar.
    local bar = CreateFrame("Frame", nil, f)
    bar:SetPoint("TOPLEFT", 0, -S.titleBar)
    bar:SetPoint("TOPRIGHT", 0, -S.titleBar)
    bar:SetHeight(S.setBar)
    local setLabel = W.Text(bar, "GameFontHighlight", C.muted, "Gear Set")
    setLabel:SetPoint("LEFT", S.padding, 0)

    local picker = CreateFrame("Button", nil, bar, W.BACKDROP)
    picker:SetSize(220, 30)
    picker:SetPoint("LEFT", setLabel, "RIGHT", 10, 0)
    W.Paint(picker, C.panel, C.windowBorder)
    picker.label = W.Text(picker, "GameFontNormal", C.gold)
    picker.label:SetPoint("LEFT", 10, 0)
    picker.label:SetPoint("RIGHT", -28, 0)
    picker.label:SetJustifyH("LEFT")
    chevron(picker):SetPoint("RIGHT", -10, 0)
    picker:SetScript("OnClick", function() self:ToggleMenu() end)
    picker:SetScript("OnEnter", function(p) p:SetBackdropBorderColor(unpack(C.label)) end)
    picker:SetScript("OnLeave", function(p) p:SetBackdropBorderColor(unpack(C.windowBorder)) end)
    f.picker = picker

    local newButton = W.Button(bar, "New set", "red", nil, 30)
    newButton:SetPoint("LEFT", picker, "RIGHT", 10, 0)
    newButton:SetScript("OnClick", function() self:NewSet() end)
    f.newButton = newButton

    f.noSets = W.Text(bar, "GameFontDisable", C.faint, "None yet")
    f.noSets:SetPoint("LEFT", setLabel, "RIGHT", 10, 0)

    f.ownedText = W.Text(bar, "GameFontHighlight", C.text)
    f.ownedText:SetPoint("TOPRIGHT", -S.padding, -12)
    local track = CreateFrame("Frame", nil, bar, W.BACKDROP)
    track:SetSize(160, 6)
    track:SetPoint("TOPRIGHT", f.ownedText, "BOTTOMRIGHT", 0, -4)
    W.Paint(track, C.panel, C.panelBorder)
    f.ownedFill = track:CreateTexture(nil, "ARTWORK")
    f.ownedFill:SetColorTexture(unpack(C.ownedBar))
    f.ownedFill:SetPoint("TOPLEFT", 1, -1)
    f.ownedFill:SetPoint("BOTTOMLEFT", 1, 1)
    f.ownedTrack = track

    self:BuildMenu(picker)
    W.Divider(f, -(S.titleBar + S.setBar))

    -- Body: Slot list on the left, Source panel on the right.
    local bodyTop = S.titleBar + S.setBar + S.gap
    local bodyBottom = S.footer + S.gap

    local slots = W.Panel(f)
    slots:SetPoint("TOPLEFT", S.padding, -bodyTop)
    slots:SetPoint("BOTTOMLEFT", S.padding, bodyBottom)
    slots:SetWidth(S.slotPanelWidth)
    W.Text(slots, "GameFontNormalSmall", C.label, "SLOTS"):SetPoint("TOPLEFT", 10, -8)
    self:BuildSlotRows(slots)
    f.slotPanel = slots

    local source = W.Panel(f)
    source:SetPoint("TOPLEFT", slots, "TOPRIGHT", S.gap, 0)
    source:SetPoint("BOTTOMRIGHT", -S.padding, bodyBottom)
    f.sourceHint = W.Text(source, "GameFontHighlight", C.muted, "Choose a Slot to see where its item comes from.")
    f.sourceHint:SetPoint("CENTER")
    f.sourceTitle = W.Text(source, "GameFontNormalLarge", C.gold)
    f.sourceTitle:SetPoint("TOPLEFT", 16, -16)
    f.sourceBody = W.Text(source, "GameFontHighlight", C.muted)
    f.sourceBody:SetPoint("TOPLEFT", f.sourceTitle, "BOTTOMLEFT", 0, -10)
    f.sourcePanel = source

    -- First open: no Gear Sets yet.
    local empty = W.Panel(f)
    empty:SetPoint("TOPLEFT", S.padding, -bodyTop)
    empty:SetPoint("BOTTOMRIGHT", -S.padding, bodyBottom)
    local emptyTitle = W.Text(empty, "GameFontNormalLarge", C.gold, "Start your first Gear Set")
    emptyTitle:SetPoint("CENTER", 0, 40)
    local emptyBody = W.Text(empty, "GameFontHighlight", C.muted,
        "Pick the items you want for each Slot, and Gear Path shows where each one comes from.")
    emptyBody:SetPoint("TOP", emptyTitle, "BOTTOM", 0, -12)
    local emptyNew = W.Button(empty, "New set", "red", nil, 30)
    emptyNew:SetPoint("TOPRIGHT", emptyBody, "BOTTOM", -4, -16)
    emptyNew:SetScript("OnClick", function() self:NewSet() end)
    local emptyImport = W.Button(empty, "Import a Share String", "plain", nil, 30)
    emptyImport:SetPoint("LEFT", emptyNew, "RIGHT", 8, 0)
    emptyImport:Disable() -- Share Strings arrive in a later step.
    f.emptyPanel = empty

    -- Share bar.
    W.Divider(f, -(S.height - S.footer))
    local shareLabel = W.Text(f, "GameFontNormalSmall", C.label, "SHARE")
    shareLabel:SetPoint("BOTTOMLEFT", S.padding, S.footer - 26)
    W.Text(f, "GameFontHighlight", C.muted,
        "Export this Gear Set as a Share String, or import one from another character or player.")
        :SetPoint("TOPLEFT", shareLabel, "BOTTOMLEFT", 0, -10)
end

function MainWindow:Refresh()
    local f = self.frame
    if not f then return end
    local selected = ns.GearSets.Selected(db())
    local hasSets = selected ~= nil

    f.picker:SetShown(hasSets)
    f.newButton:SetShown(hasSets)
    f.noSets:SetShown(not hasSets)
    f.ownedText:SetShown(hasSets)
    f.ownedTrack:SetShown(hasSets)
    f.slotPanel:SetShown(hasSets)
    f.sourcePanel:SetShown(hasSets)
    f.emptyPanel:SetShown(not hasSets)

    if hasSets then
        f.picker.label:SetText(selected)
        local owned = 0 -- Owned status comes with item status.
        f.ownedText:SetText(("|cff8fe388%d|r of %d Slots Owned"):format(owned, SLOT_COUNT))
        f.ownedFill:SetWidth(math.max(0.01, 158 * owned / SLOT_COUNT))
        self:RefreshSlotRows()
        self:RefreshSource()
    else
        self:CloseMenu()
    end
    if self.menu:IsShown() then self:RefreshMenu() end
end

function MainWindow:Get()
    if not self.frame then self:Build() end
    return self.frame
end

function MainWindow:Toggle()
    local f = self:Get()
    if f:IsShown() then
        f:Hide()
    else
        self:Refresh()
        f:Show()
    end
end
