-- The item picker and the filled-Slot view, shown in the window's right panel.
-- Layout follows the "Step 4: Item picker states" mockup.
local _, ns = ...

local W = ns.Widgets
local C = ns.Theme.colors

local ItemPicker = {}
ns.ItemPicker = ItemPicker

local ROWS, ROW_H, ROW_GAP = 9, 36, 4
local unobtainable = {} -- itemID -> bool, cached for the session

local function slotLabel(slotId)
    for _, s in ipairs(ns.Slots) do if s.id == slotId then return s.label end end
    return slotId
end

--- r, g, b for an item's quality, white until the client has the item cached.
function ItemPicker.QualityColor(itemID)
    local q = C_Item and C_Item.GetItemQualityByID and C_Item.GetItemQualityByID(itemID)
    if q == nil and C_Item and C_Item.RequestLoadItemDataByID then
        C_Item.RequestLoadItemDataByID(itemID)
    end
    local color = q and ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[q]
    if color then return color.r, color.g, color.b end
    return 1, 1, 1
end

local function isUnobtainable(itemID, player)
    if unobtainable[itemID] == nil then
        unobtainable[itemID] = ns.ItemFilter.Unobtainable(itemID, player, ns.Data)
    end
    return unobtainable[itemID]
end

---------------------------------------------------------------------------
-- Building
---------------------------------------------------------------------------

local function chip(parent, onClick)
    local b = CreateFrame("Button", nil, parent, W.BACKDROP)
    b:SetHeight(22)
    b.label = W.Text(b, "GameFontHighlightSmall", C.text)
    b.label:SetPoint("CENTER")
    b:SetScript("OnClick", onClick)
    function b:SetOn(on)
        self.on = on
        if on then
            W.Paint(self, C.highlight, C.highlightBorder)
            self.label:SetTextColor(unpack(C.gold))
        else
            W.Paint(self, { 0, 0, 0, 0 }, C.panelBorder)
            self.label:SetTextColor(unpack(C.faint))
        end
    end
    function b:SetDisabled()
        self.on = false
        W.Paint(self, { 0, 0, 0, 0 }, C.divider)
        self.label:SetTextColor(unpack(C.emptyIcon))
    end
    return b
end

local function checkbox(parent, label, onClick)
    local b = CreateFrame("Button", nil, parent)
    b:SetHeight(18)
    b.box = CreateFrame("Frame", nil, b, W.BACKDROP)
    b.box:SetSize(14, 14)
    b.box:SetPoint("LEFT")
    W.Paint(b.box, C.black, C.windowBorder)
    b.tick = b.box:CreateTexture(nil, "OVERLAY")
    b.tick:SetColorTexture(unpack(C.gold))
    b.tick:SetPoint("TOPLEFT", 3, -3)
    b.tick:SetPoint("BOTTOMRIGHT", -3, 3)
    b.label = W.Text(b, "GameFontHighlightSmall", C.muted, label)
    b.label:SetPoint("LEFT", b.box, "RIGHT", 6, 0)
    b:SetWidth(20 + b.label:GetStringWidth())
    b:SetScript("OnClick", onClick)
    function b:SetChecked(on) self.tick:SetShown(on) end
    return b
end

local function resultRow(parent, picker)
    local r = CreateFrame("Frame", nil, parent, W.BACKDROP)
    r:SetHeight(ROW_H)
    W.Paint(r, C.rowBg, C.panelBorder)
    r.iconFrame = CreateFrame("Frame", nil, r, W.BACKDROP)
    r.iconFrame:SetSize(28, 28)
    r.iconFrame:SetPoint("LEFT", 6, 0)
    W.Paint(r.iconFrame, C.buttonPlain, C.panelBorder)
    r.icon = r.iconFrame:CreateTexture(nil, "ARTWORK")
    r.icon:SetPoint("TOPLEFT", 1, -1)
    r.icon:SetPoint("BOTTOMRIGHT", -1, 1)
    r.add = W.Button(r, "Add to Slot", "red", nil, 26)
    r.add:SetPoint("RIGHT", -6, 0)
    r.add:SetScript("OnClick", function() picker:Choose(r.itemID) end)
    r.name = W.Text(r, "GameFontHighlight", C.text)
    r.name:SetPoint("TOPLEFT", r.iconFrame, "TOPRIGHT", 10, 0)
    r.name:SetPoint("RIGHT", r.add, "LEFT", -8, 0)
    r.name:SetJustifyH("LEFT")
    r.sub = W.Text(r, "GameFontHighlightSmall", C.faint)
    r.sub:SetPoint("BOTTOMLEFT", r.iconFrame, "BOTTOMRIGHT", 10, 0)
    r.sub:SetPoint("RIGHT", r.add, "LEFT", -8, 0)
    r.sub:SetJustifyH("LEFT")
    r:EnableMouse(true)
    r:SetScript("OnEnter", function(self)
        if not self.itemID then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetItemByID(self.itemID)
        GameTooltip:Show()
    end)
    r:SetScript("OnLeave", function() GameTooltip:Hide() end)
    return r
end

function ItemPicker:Build(panel, window)
    self.window = window
    local f = CreateFrame("Frame", nil, panel)
    f:SetPoint("TOPLEFT", 16, -14)
    f:SetPoint("BOTTOMRIGHT", -16, 12)
    f:Hide()
    self.frame = f

    f.title = W.Text(f, "GameFontNormalLarge", C.gold)
    f.title:SetPoint("TOPLEFT")

    local searchLabel = W.Text(f, "GameFontHighlightSmall", C.muted, "Search items")
    searchLabel:SetPoint("TOPLEFT", f.title, "BOTTOMLEFT", 0, -10)
    f.search = W.EditBox(f, 100)
    f.search:SetPoint("TOPLEFT", searchLabel, "BOTTOMLEFT", 0, -4)
    f.search:SetPoint("RIGHT", f, "RIGHT")
    f.search:SetMaxLetters(60)
    f.search:SetScript("OnTextChanged", function(e)
        self.query = e:GetText()
        self.offset = 0
        self:Update()
    end)
    f.search:SetScript("OnEscapePressed", function(e) e:ClearFocus() end)
    f.search:SetScript("OnEnterPressed", function(e) e:ClearFocus() end)

    f.typeLabel = W.Text(f, "GameFontHighlightSmall", C.muted, "Type")
    f.typeLabel:SetPoint("TOPLEFT", f.search, "BOTTOMLEFT", 0, -12)
    f.chips = {}

    f.levelBox = checkbox(f, "Hide items above my level", function()
        self.hideHigh = not self.hideHigh
        self.offset = 0
        self:Update()
    end)
    f.levelBox:SetPoint("TOPRIGHT", f.search, "BOTTOMRIGHT", 0, -10)

    f.count = W.Text(f, "GameFontHighlightSmall", C.faint)
    f.count:SetPoint("TOPLEFT", f.search, "BOTTOMLEFT", 0, -40)

    local list = CreateFrame("Frame", nil, f)
    list:SetPoint("TOPLEFT", f.count, "BOTTOMLEFT", 0, -6)
    list:SetPoint("RIGHT", f, "RIGHT")
    list:SetHeight(ROWS * (ROW_H + ROW_GAP))
    list:EnableMouseWheel(true)
    list:SetScript("OnMouseWheel", function(_, delta)
        local maxOffset = math.max(0, #self.results - ROWS)
        self.offset = math.min(maxOffset, math.max(0, self.offset - delta * 3))
        self:UpdateRows()
    end)
    f.rows = {}
    for i = 1, ROWS do
        local r = resultRow(list, self)
        r:SetPoint("TOPLEFT", 0, -(i - 1) * (ROW_H + ROW_GAP))
        r:SetPoint("RIGHT", list, "RIGHT")
        f.rows[i] = r
    end
    f.list = list

    f.tip = W.Text(f, "GameFontHighlightSmall", C.muted,
        "Scroll for more. Tip: Shift-click any item link to put it in this Slot.")
    f.tip:SetPoint("BOTTOMLEFT")

    f.empty = W.Text(f, "GameFontHighlight", C.text)
    f.empty:SetPoint("TOP", list, "TOP", 0, -80)
    f.emptyNote = W.Text(f, "GameFontHighlightSmall", C.faint)
    f.emptyNote:SetPoint("TOP", f.empty, "BOTTOM", 0, -8)

    -- First open: sorting items into Slots.
    local loading = CreateFrame("Frame", nil, f)
    loading:SetPoint("TOPLEFT", f.title, "BOTTOMLEFT", 0, -10)
    loading:SetPoint("BOTTOMRIGHT")
    loading.text = W.Text(loading, "GameFontHighlight", C.text, "Sorting items into Slots…")
    loading.text:SetPoint("CENTER", 0, 30)
    local track = CreateFrame("Frame", nil, loading, W.BACKDROP)
    track:SetSize(260, 8)
    track:SetPoint("TOP", loading.text, "BOTTOM", 0, -12)
    W.Paint(track, C.black, C.panelBorder)
    loading.fill = track:CreateTexture(nil, "ARTWORK")
    loading.fill:SetColorTexture(unpack(C.label))
    loading.fill:SetPoint("TOPLEFT", 1, -1)
    loading.fill:SetPoint("BOTTOMLEFT", 1, 1)
    loading.fill:SetWidth(1)
    loading.note = W.Text(loading, "GameFontHighlightSmall", C.faint,
        "This happens once per session and takes a few seconds.")
    loading.note:SetPoint("TOP", track, "BOTTOM", 0, -12)
    f.loading = loading

    self.offset, self.results, self.typeOff = 0, {}, {}

    -- Repaint names once the client loads item data (quality colors).
    local events = CreateFrame("Frame")
    for _, event in ipairs({ "GET_ITEM_INFO_RECEIVED", "ITEM_DATA_LOAD_RESULT" }) do
        pcall(events.RegisterEvent, events, event)
    end
    events:SetScript("OnEvent", function()
        if self.pending or not f:IsVisible() then return end
        self.pending = true
        C_Timer.After(0.2, function()
            self.pending = false
            if f:IsVisible() then self:UpdateRows() end
        end)
    end)
end

---------------------------------------------------------------------------
-- Showing a Slot
---------------------------------------------------------------------------

function ItemPicker:Show(slotId)
    local f = self.frame
    if self.slotId ~= slotId then
        self.slotId = slotId
        self.query, self.offset, self.typeOff = "", 0, {}
        f.search:SetText("")
    end
    f.title:SetText("Choose an item for " .. slotLabel(slotId))
    f:Show()
    if not ns.ItemIndex.IsReady() then
        ns.ItemIndex.Build(function()
            if f:IsVisible() then self:Update() end
        end)
    end
    self:Update()
end

function ItemPicker:Hide()
    if self.frame then self.frame:Hide() end
end

local function setShown(frames, shown)
    for _, frame in ipairs(frames) do frame:SetShown(shown) end
end

function ItemPicker:Update()
    local f = self.frame
    if not f or not self.slotId then return end
    local ready = ns.ItemIndex.IsReady()
    f.loading:SetShown(not ready)
    setShown({ f.search, f.typeLabel, f.levelBox, f.count, f.list, f.tip }, ready)
    for _, c in ipairs(f.chips) do c:SetShown(ready and c.inUse) end
    f.empty:SetShown(false)
    f.emptyNote:SetShown(false)
    if not ready then
        f.loading.fill:SetWidth(math.max(1, 258 * ns.ItemIndex.Progress()))
        return
    end

    local player = ns.ItemIndex.Player()
    f.levelBox.label:SetText(("Hide items above my level (%d)"):format(player.level))
    f.levelBox:SetWidth(20 + f.levelBox.label:GetStringWidth())
    f.levelBox:SetChecked(self.hideHigh)

    -- Candidates for this Slot, minus Unobtainable items.
    local candidates = {}
    local armorSlot = ns.ItemFilter.ARMOR_SLOTS[self.slotId]
    for _, itemID in ipairs(ns.ItemIndex.ForSlot(self.slotId)) do
        local item = ns.Data.Item(itemID)
        if item and item.name and not isUnobtainable(itemID, player) then
            local info = ns.ItemIndex.Info(itemID)
            local key = armorSlot and ns.ItemFilter.ArmorFilterKey(info and info.classID, info and info.subClassID) or nil
            candidates[#candidates + 1] = { id = itemID, name = item.name, level = item.requiredLevel, typeKey = key }
        end
    end
    self:LayoutChips(armorSlot, player.classFile)

    local results = {}
    for _, e in ipairs(candidates) do
        if not (e.typeKey and self.typeOff[e.typeKey])
            and not (self.hideHigh and (e.level or 0) > player.level)
            and ns.ItemFilter.MatchesSearch(e.name, self.query) then
            results[#results + 1] = e
        end
    end
    self.results = ns.ItemFilter.Sort(results)
    self.playerLevel = player.level

    local className = UnitClass("player")
    local label = slotLabel(self.slotId)
    f.count:SetText(("%d %s items a %s can use · highest level first"):format(#results, label, className))
    if #results == 0 then
        f.empty:SetText(self.query ~= "" and ('No %s items match "%s".'):format(label, self.query)
            or ("No %s items to show with these filters."):format(label))
        f.emptyNote:SetText(("Items a %s can never use are hidden, and so are other Slots' items."):format(className))
        f.empty:Show()
        f.emptyNote:Show()
    end
    self:UpdateRows()
end

--- The five fixed armor filters, shown only on Slots that take armor types.
--- Types this class can't wear are greyed out and can't be clicked.
function ItemPicker:LayoutChips(show, classFile)
    local f = self.frame
    f.typeLabel:SetShown(show)
    local x = f.typeLabel:GetStringWidth() + 10
    for i, filter in ipairs(ns.ItemFilter.ARMOR_FILTERS) do
        local c = f.chips[i]
        if not c then
            c = chip(f, function(b)
                self.typeOff[b.key] = not self.typeOff[b.key] or nil
                self.offset = 0
                self:Update()
            end)
            c.key = filter.key
            c.label:SetText(filter.label)
            c:SetWidth(c.label:GetStringWidth() + 20)
            c:ClearAllPoints()
            c:SetPoint("LEFT", f.typeLabel, "LEFT", x, 0)
            f.chips[i] = c
        end
        x = x + c:GetWidth() + 6
        local usable = ns.ItemFilter.ArmorFilterUsable(classFile, filter)
        c:EnableMouse(usable)
        if usable then c:SetOn(not self.typeOff[filter.key]) else c:SetDisabled() end
        c.inUse = show
        c:SetShown(show)
    end
end

function ItemPicker:UpdateRows()
    local f = self.frame
    for i, r in ipairs(f.rows) do
        local e = self.results[self.offset + i]
        r:SetShown(e ~= nil)
        if e then
            r.itemID = e.id
            local info = ns.ItemIndex.Info(e.id)
            r.icon:SetTexture(info and info.icon or 134400)
            local red, green, blue = ItemPicker.QualityColor(e.id)
            r.name:SetText(e.name)
            r.name:SetTextColor(red, green, blue)
            r.iconFrame:SetBackdropBorderColor(red, green, blue)
            local parts = {}
            if e.level then parts[#parts + 1] = "Level " .. e.level end
            if e.level and e.level > self.playerLevel then parts[#parts + 1] = "Locked" end
            parts[#parts + 1] = ns.ItemFilter.SourceSummary(ns.Data.ItemSources(e.id))
            r.sub:SetText(table.concat(parts, " · "))
        end
    end
end

function ItemPicker:Choose(itemID)
    self.window:SetSlotItem(self.slotId, itemID)
end

--- Shift-clicked item link while the picker is open. Returns true if it was used.
function ItemPicker:TakeLink(link)
    local f = self.frame
    if not f or not f:IsVisible() or not self.slotId then return false end
    local itemID = ns.Data.ParseItemID(link)
    if not itemID then return false end
    local say = function(msg) print("|cffffd100Gear Path|r: " .. msg) end
    local fn = (C_Item and C_Item.GetItemInfoInstant) or GetItemInfoInstant
    if not fn then return false end
    local _, _, _, equipLoc, _, classID, subClassID = fn(itemID)
    local player = ns.ItemIndex.Player()
    local fits = false
    for _, s in ipairs(ns.ItemFilter.SlotsFor(equipLoc or "", player.classFile)) do
        if s == self.slotId then fits = true end
    end
    if not fits then
        say(("%s doesn't go in your %s Slot."):format(link, slotLabel(self.slotId)))
    elseif not ns.ItemFilter.CanUseType(player.classFile, classID, subClassID) then
        say(("%s wasn't added: a %s can't use it."):format(link, (UnitClass("player"))))
    elseif isUnobtainable(itemID, player) then
        say(("%s wasn't added: your character can't get it."):format(link))
    else
        self:Choose(itemID)
    end
    return true
end

---------------------------------------------------------------------------
-- Filled Slot view
---------------------------------------------------------------------------

function ItemPicker:BuildDetail(panel)
    local d = CreateFrame("Frame", nil, panel)
    d:SetPoint("TOPLEFT", 16, -14)
    d:SetPoint("BOTTOMRIGHT", -16, 12)
    d:Hide()

    d.iconFrame = CreateFrame("Frame", nil, d, W.BACKDROP)
    d.iconFrame:SetSize(40, 40)
    d.iconFrame:SetPoint("TOPLEFT")
    W.Paint(d.iconFrame, C.buttonPlain, C.panelBorder, 2)
    d.icon = d.iconFrame:CreateTexture(nil, "ARTWORK")
    d.icon:SetPoint("TOPLEFT", 2, -2)
    d.icon:SetPoint("BOTTOMRIGHT", -2, 2)
    d.iconFrame:EnableMouse(true)
    d.iconFrame:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetItemByID(d.itemID)
        GameTooltip:Show()
    end)
    d.iconFrame:SetScript("OnLeave", function() GameTooltip:Hide() end)

    d.remove = W.Button(d, "Remove", "plain", nil, 28)
    d.remove:SetPoint("TOPRIGHT", 0, -6)
    d.change = W.Button(d, "Change item", "red", nil, 28)
    d.change:SetPoint("RIGHT", d.remove, "LEFT", -8, 0)

    d.name = W.Text(d, "GameFontNormalLarge", C.text)
    d.name:SetPoint("TOPLEFT", d.iconFrame, "TOPRIGHT", 12, -2)
    d.name:SetPoint("RIGHT", d.change, "LEFT", -8, 0)
    d.name:SetJustifyH("LEFT")
    d.meta = W.Text(d, "GameFontHighlight", C.muted)
    d.meta:SetPoint("BOTTOMLEFT", d.iconFrame, "BOTTOMRIGHT", 12, 2)

    d.sources = W.Text(d, "GameFontHighlight", C.muted)
    d.sources:SetPoint("TOPLEFT", d.iconFrame, "BOTTOMLEFT", 0, -16)
    d.sources:SetPoint("RIGHT", d, "RIGHT")
    d.sources:SetJustifyH("LEFT")
    self.detail = d
end

function ItemPicker:ShowDetail(slotId, itemID)
    local d = self.detail
    d.itemID = itemID
    local item = ns.Data.Item(itemID)
    local info = ns.ItemIndex.Info(itemID)
    d.icon:SetTexture(info and info.icon or 134400)
    local red, green, blue = ItemPicker.QualityColor(itemID)
    d.name:SetText(item and item.name or ("Item " .. itemID))
    d.name:SetTextColor(red, green, blue)
    d.iconFrame:SetBackdropBorderColor(red, green, blue)
    local meta = { slotLabel(slotId) }
    if info and info.subType and info.subType ~= "" and info.subType ~= "Miscellaneous" then
        meta[#meta + 1] = info.subType
    end
    if item and item.requiredLevel then meta[#meta + 1] = "Requires level " .. item.requiredLevel end
    d.meta:SetText(table.concat(meta, " · "))
    d.sources:SetText("Source: " .. ns.ItemFilter.SourceSummary(ns.Data.ItemSources(itemID)))
    d.change:SetScript("OnClick", function() self.window:ChangeSlot(slotId) end)
    d.remove:SetScript("OnClick", function() self.window:SetSlotItem(slotId, nil) end)
    d:Show()
end

function ItemPicker:HideDetail()
    if self.detail then self.detail:Hide() end
end
