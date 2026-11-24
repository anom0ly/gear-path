-- The Source panel: where the item in a filled Slot comes from (step 5 mockup).
-- Sections stack as Quest, Drop, Vendor. Vendors are filtered to the player's faction,
-- the current zone comes first, and long lists start short with "Show all N vendors".
local _, ns = ...

local C = ns.Theme.colors
local W = ns.Widgets

local SourcePanel = {}
ns.SourcePanel = SourcePanel

local GAP = 8

local function zoneName(areaID)
    if C_Map and C_Map.GetAreaInfo then
        local name = C_Map.GetAreaInfo(areaID)
        if name and name ~= "" then return name end
    end
    return nil
end

local function raceName(raceID)
    local info = C_CreatureInfo and C_CreatureInfo.GetRaceInfo and C_CreatureInfo.GetRaceInfo(raceID)
    return info and info.raceName
end

local function className(classID)
    local name = GetClassInfo and GetClassInfo(classID)
    return name
end

local function factionName(factionID)
    if C_Reputation and C_Reputation.GetFactionDataByID then
        local data = C_Reputation.GetFactionDataByID(factionID)
        if data and data.name then return data.name end
    end
    if GetFactionInfoByID then return (GetFactionInfoByID(factionID)) end
    return nil
end

SourcePanel.names = { zone = zoneName, race = raceName, class = className, faction = factionName }

--- Builds the scrolling area inside the detail view, below the item header.
function SourcePanel:Build(parent, anchor)
    local scroll = CreateFrame("ScrollFrame", nil, parent)
    scroll:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -14)
    scroll:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT")
    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(1, 1)
    scroll:SetScrollChild(content)
    scroll:EnableMouseWheel(true)
    scroll:SetScript("OnMouseWheel", function(s, delta)
        local max = math.max(0, content:GetHeight() - s:GetHeight())
        s:SetVerticalScroll(math.min(max, math.max(0, s:GetVerticalScroll() - delta * 40)))
    end)
    scroll:SetScript("OnSizeChanged", function(s, width) content:SetWidth(width) end)
    self.scroll, self.content = scroll, content
    self.pools = { heading = {}, card = {}, row = {}, link = {}, note = {}, step = {}, banner = {}, alts = {} }
    self.used = {}
end

-- Widget pools, so re-rendering reuses frames instead of creating new ones.
local function take(self, kind, make)
    local pool = self.pools[kind]
    self.used[kind] = (self.used[kind] or 0) + 1
    local w = pool[self.used[kind]]
    if not w then
        w = make()
        pool[self.used[kind]] = w
    end
    w:ClearAllPoints()
    w:Show()
    return w
end

function SourcePanel:Place(w, height)
    w:SetPoint("TOPLEFT", self.content, "TOPLEFT", 0, -self.y)
    w:SetPoint("RIGHT", self.content, "RIGHT")
    self.y = self.y + height + GAP
end

function SourcePanel:Heading(text)
    local fs = take(self, "heading", function() return W.Text(self.content, "GameFontNormal", C.label) end)
    fs:SetJustifyH("LEFT")
    fs:SetText(text)
    self:Place(fs, 16)
end

function SourcePanel:Note(text, color)
    local fs = take(self, "note", function() return W.Text(self.content, "GameFontHighlightSmall", C.muted) end)
    fs:SetJustifyH("LEFT")
    fs:SetTextColor(unpack(color or C.muted))
    fs:SetText(text)
    self:Place(fs, 14)
    fs:SetHeight(0)
    local h = fs:GetStringHeight()
    if h > 14 then self.y = self.y + h - 14 end
end

--- A card of label/value lines; the first value is gold.
function SourcePanel:Card(lines)
    local card = take(self, "card", function()
        local f = CreateFrame("Frame", nil, self.content, W.BACKDROP)
        W.Paint(f, C.rowBg, C.windowBorder)
        f.keys, f.values = {}, {}
        return f
    end)
    for i = 1, math.max(#lines, #card.keys) do
        local line = lines[i]
        local k, v = card.keys[i], card.values[i]
        if not k then
            k = W.Text(card, "GameFontHighlight", C.muted)
            k:SetPoint("TOPLEFT", 12, -10 - (i - 1) * 18)
            v = W.Text(card, "GameFontHighlight", C.text)
            v:SetPoint("TOPLEFT", 108, -10 - (i - 1) * 18)
            v:SetPoint("RIGHT", card, "RIGHT", -10, 0)
            v:SetJustifyH("LEFT")
            v:SetWordWrap(false)
            card.keys[i], card.values[i] = k, v
        end
        k:SetShown(line ~= nil)
        v:SetShown(line ~= nil)
        if line then
            k:SetText(line[1])
            v:SetText(line[2])
            v:SetTextColor(unpack(i == 1 and C.gold or C.text))
        end
    end
    local h = 20 + #lines * 18 - 4
    card:SetHeight(h)
    self:Place(card, h)
end

--- A list row: gold name, grey line under it, optional green "In your zone" tag.
function SourcePanel:Row(name, sub, here)
    local row = take(self, "row", function()
        local f = CreateFrame("Frame", nil, self.content, W.BACKDROP)
        W.Paint(f, C.rowBg, C.panelBorder)
        f:SetHeight(38)
        f.name = W.Text(f, "GameFontHighlight", C.gold)
        f.name:SetPoint("TOPLEFT", 10, -5)
        f.sub = W.Text(f, "GameFontHighlightSmall", C.faint)
        f.sub:SetPoint("TOPLEFT", f.name, "BOTTOMLEFT", 0, -2)
        f.tag = W.Text(f, "GameFontHighlightSmall", C.ownedBar, "In your zone")
        f.tag:SetPoint("RIGHT", -10, 0)
        return f
    end)
    row.name:SetText(name)
    row.sub:SetText(sub or "")
    row.tag:SetShown(here == true)
    self:Place(row, 38)
end

function SourcePanel:LinkLine(label, onClick, aside)
    local l = take(self, "link", function()
        local b = W.Link(self.content, "", C.buttonText)
        b.aside = W.Text(self.content, "GameFontHighlightSmall", C.faint)
        return b
    end)
    l.label:SetText(label)
    l:SetSize(l.label:GetStringWidth() + 12, 20)
    l:SetScript("OnClick", onClick)
    l:SetPoint("TOPLEFT", self.content, "TOPLEFT", -6, -self.y)
    l.aside:ClearAllPoints()
    l.aside:SetPoint("RIGHT", self.content, "TOPRIGHT", 0, -self.y - 10)
    l.aside:SetText(aside or "")
    l.aside:Show()
    self.y = self.y + 20 + GAP
end

function SourcePanel:Begin()
    for kind, pool in pairs(self.pools) do
        for _, w in ipairs(pool) do
            w:Hide()
            if w.aside then w.aside:Hide() end
        end
        self.used[kind] = 0
    end
    self.y = 0
end

local STATE_LABEL = {
    done = { "Done", { 0.56, 0.89, 0.53, 1 } },
    next = { "Next", C.gold },
    locked = { "Locked", { 0.72, 0.72, 0.72, 1 } },
    optional = { "Breadcrumb · optional", C.faint },
    missed = { "Closed", C.deleteLink },
}
local STATE_ICON = {
    done = "Interface\\RaidFrame\\ReadyCheck-Ready",
    missed = "Interface\\RaidFrame\\ReadyCheck-NotReady",
}

local function isDone(questID)
    return C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted
        and C_QuestLog.IsQuestFlaggedCompleted(questID) == true or false
end

--- A colored banner: bold title and one line of text.
function SourcePanel:Banner(title, text, color)
    local b = take(self, "banner", function()
        local f = CreateFrame("Frame", nil, self.content, W.BACKDROP)
        W.Paint(f, C.window, C.windowBorder)
        f.bar = f:CreateTexture(nil, "ARTWORK")
        f.bar:SetPoint("TOPLEFT")
        f.bar:SetPoint("BOTTOMLEFT")
        f.bar:SetWidth(3)
        f.title = W.Text(f, "GameFontNormal", C.warning)
        f.title:SetPoint("TOPLEFT", 12, -7)
        f.text = W.Text(f, "GameFontHighlightSmall", C.text)
        f.text:SetPoint("TOPLEFT", f.title, "BOTTOMLEFT", 0, -3)
        f.text:SetPoint("RIGHT", -10, 0)
        f.text:SetJustifyH("LEFT")
        return f
    end)
    b.bar:SetColorTexture(unpack(color))
    b.title:SetTextColor(unpack(color))
    b.title:SetText(title)
    b.text:SetText(text)
    self:Place(b, 42)
end

--- One Step row; click selects it.
function SourcePanel:StepRow(step, meta, selected, onClick)
    local r = take(self, "step", function()
        local f = CreateFrame("Button", nil, self.content, W.BACKDROP)
        f:SetHeight(34)
        f.icon = f:CreateTexture(nil, "ARTWORK")
        f.icon:SetSize(14, 14)
        f.icon:SetPoint("LEFT", 8, 0)
        f.n = W.Text(f, "GameFontHighlightSmall", C.muted)
        f.n:SetPoint("LEFT", 28, 0)
        f.name = W.Text(f, "GameFontHighlight", C.text)
        f.name:SetPoint("TOPLEFT", 48, -3)
        f.name:SetPoint("RIGHT", -130, 0)
        f.name:SetJustifyH("LEFT")
        f.name:SetWordWrap(false)
        f.meta = W.Text(f, "GameFontHighlightSmall", C.faint)
        f.meta:SetPoint("TOPLEFT", f.name, "BOTTOMLEFT", 0, -2)
        f.meta:SetPoint("RIGHT", -10, 0)
        f.meta:SetJustifyH("LEFT")
        f.meta:SetWordWrap(false)
        f.label = W.Text(f, "GameFontHighlightSmall", C.faint)
        f.label:SetPoint("TOPRIGHT", -8, -5)
        return f
    end)
    local st = step.state
    if selected then W.Paint(r, C.highlight, C.highlightBorder) else W.Paint(r, { 0, 0, 0, 0 }, { 0, 0, 0, 0 }) end
    local tex = STATE_ICON[st]
    if tex then
        r.icon:SetTexture(tex)
        r.icon:SetVertexColor(1, 1, 1, 1)
    else
        r.icon:SetColorTexture(unpack((st == "next" and C.gold) or (st == "locked" and C.muted) or C.emptyIcon))
    end
    r.n:SetText(step.n)
    r.name:SetText(step.name)
    local nameColor = (st == "next" and C.white) or ((st == "optional" or st == "missed") and C.faint)
        or ((st == "todo" or st == "locked") and C.statusText) or C.text
    r.name:SetTextColor(unpack(nameColor))
    r.meta:SetText(meta)
    local label = STATE_LABEL[st]
    r.label:SetText(label and label[1] or "")
    if label then r.label:SetTextColor(unpack(label[2])) end
    r:SetScript("OnClick", onClick)
    self:Place(r, 34)
end

--- The Alternatives box under a Step.
function SourcePanel:AltsBox(alts, stepDone)
    local box = take(self, "alts", function()
        local f = CreateFrame("Frame", nil, self.content, W.BACKDROP)
        W.Paint(f, { 0, 0, 0, 0 }, C.emptyIcon)
        f.head = W.Text(f, "GameFontHighlightSmall", C.muted, "Alternatives: finishing any one completes this Step")
        f.head:SetPoint("TOPLEFT", 10, -6)
        f.lines = {}
        return f
    end)
    for i = 1, math.max(#alts, #box.lines) do
        local line = box.lines[i]
        if not line then
            line = { name = W.Text(box, "GameFontHighlightSmall", C.text), state = W.Text(box, "GameFontHighlightSmall", C.faint) }
            line.name:SetPoint("TOPLEFT", 10, -6 - i * 16)
            line.state:SetPoint("TOPRIGHT", -10, -6 - i * 16)
            box.lines[i] = line
        end
        local a = alts[i]
        line.name:SetShown(a ~= nil)
        line.state:SetShown(a ~= nil)
        if a then
            line.name:SetText(a.name)
            line.name:SetTextColor(unpack(a.done and C.text or C.faint))
            line.state:SetText(a.done and "Done" or (stepDone and "Not needed" or ""))
            line.state:SetTextColor(unpack(a.done and STATE_LABEL.done[2] or C.faint))
        end
    end
    local h = 12 + (#alts + 1) * 16
    box:SetHeight(h)
    box:SetPoint("TOPLEFT", self.content, "TOPLEFT", 48, -self.y)
    box:SetPoint("RIGHT", self.content, "RIGHT")
    self.y = self.y + h + GAP
end

--- The Quest Chain for a reward quest, with the selected Step's details under it.
function SourcePanel:Chain(rewardQuestID, itemID)
    local player = ns.ItemIndex.Player()
    local chain = ns.QuestChain.Build(rewardQuestID, ns.Data, isDone, player)
    if #chain.steps < 2 then return end

    if chain.missed then
        self:Banner("Missed", ("You finished %s, which closes this chain. The item can't be earned on this character.")
            :format(chain.missed.by), C.deleteLink)
    elseif chain.locked then
        self:Banner("Locked", ("Step %d %s"):format(chain.locked.step, chain.locked.reason), C.warning)
    end
    self:Heading("Quest Chain")
    local summary = take(self, "note", function() return W.Text(self.content, "GameFontHighlightSmall", C.muted) end)
    summary:SetPoint("TOPRIGHT", self.content, "TOPRIGHT", 0, -(self.y - 16 - GAP) - 2)
    summary:SetText(chain.missed and "Closed" or ("%d of %d Steps done"):format(chain.done, chain.total))

    local selected = self.selectedStep
    if not selected then
        for _, s in ipairs(chain.steps) do
            if s.state == "next" or s.state == "locked" then selected = s.questID break end
        end
        selected = selected or chain.steps[#chain.steps].questID
    end

    local fold = self.unfold and 0 or ns.QuestChain.FoldCount(chain)
    if fold > 0 then
        self:LinkLine(("Show %d earlier Steps (all done)"):format(fold), function()
            self.unfold = true
            self:Show(itemID)
        end)
    end
    local selectedStep
    for i = fold + 1, #chain.steps do
        local s = chain.steps[i]
        local meta = {}
        local zone = s.zoneID and SourcePanel.names.zone(s.zoneID)
        if zone then meta[#meta + 1] = zone end
        if s.level then meta[#meta + 1] = "level " .. s.level end
        if i == #chain.steps then meta[#meta + 1] = "rewards this item" end
        local isSel = s.questID == selected
        if isSel then selectedStep = s end
        self:StepRow(s, table.concat(meta, " · "), isSel, function()
            self.selectedStep, self.showObjectives = s.questID, false
            self:Show(itemID)
        end)
        if s.alts then self:AltsBox(s.alts, s.state == "done") end
    end

    if selectedStep then
        local q = ns.Data.Quest(selectedStep.questID)
        if q then
            local info = ns.SourceDetails.QuestInfo(q, ns.Data, SourcePanel.names)
            local lines = { { "Step " .. selectedStep.n, info.name } }
            if info.giver then lines[#lines + 1] = { "Quest giver", info.giver } end
            if info.where then lines[#lines + 1] = { "Where", info.where } end
            if info.level then lines[#lines + 1] = { "Level", info.level } end
            lines[#lines + 1] = { "Requires", selectedStep.breadcrumb and "None. A Breadcrumb can be skipped." or info.requires }
            self:Card(lines)
            if q.objectivesText then
                self:LinkLine(self.showObjectives and "Hide objectives" or "Show objectives", function()
                    self.showObjectives = not self.showObjectives
                    self:Show(itemID)
                end)
                if self.showObjectives then
                    self:Note(table.concat(q.objectivesText, " "), C.text)
                end
            end
        end
    end
end

--- Shows the Sources of an item. Resets the vendor list to short when the item changes.
function SourcePanel:Show(itemID)
    if self.itemID ~= itemID then
        self.itemID = itemID
        self.allVendors = false
        self.selectedStep, self.showObjectives, self.unfold = nil, false, false
        self.scroll:SetVerticalScroll(0)
    end
    local player = ns.ItemIndex.Player()
    player.zone = GetRealZoneText and GetRealZoneText() or nil
    local sections = ns.SourceDetails.Build(itemID, player, ns.Data, SourcePanel.names)

    self:Begin()
    if #sections == 0 then
        if #ns.Data.ItemSources(itemID) > 0 then
            self:Heading("No Source open to your character")
            self:Note("Every Source QuestieDB lists for this item is for the other faction or another class.")
        else
            self:Heading("Source not yet known")
            self:Note("QuestieDB has no Source for this item on WoW: Forever yet. It stays in your Gear Set, and its Source shows here once the data exists.", C.text)
            self:Note("Crafted, reputation and PvP Sources come in a later phase.")
        end
    end
    for _, section in ipairs(sections) do
        if section.kind == "quest" then
            self:Heading(#section.quests > 1 and ("Source: quest reward (%d quests)"):format(#section.quests)
                or "Source: quest reward")
            for _, q in ipairs(section.quests) do
                local lines = { { "Quest", q.name } }
                if q.giver then lines[#lines + 1] = { "Quest giver", q.giver } end
                if q.where then lines[#lines + 1] = { "Where", q.where } end
                if q.level then lines[#lines + 1] = { "Level", q.level } end
                lines[#lines + 1] = { "Requires", q.requires }
                self:Card(lines)
            end
            self:Chain(section.quests[1].id, itemID)
        elseif section.kind == "drop" then
            self:Heading("Source: drop")
            for _, d in ipairs(section.drops) do
                local sub = d.sub
                if d.kind == "object" then sub = (sub ~= "" and ("Found in · " .. sub) or "Found in") end
                self:Row(d.name, sub)
            end
            self:Note("QuestieDB doesn't record drop chances, so these are listed by level, highest first.")
        elseif section.kind == "vendor" then
            local list, total = section.vendors, #section.vendors
            local short = not self.allVendors and total > ns.SourceDetails.SHORT_VENDORS
            self:Heading(self.allVendors and ("Source: vendor (%d)"):format(total) or "Source: vendor")
            for i = 1, short and ns.SourceDetails.SHORT_VENDORS or total do
                local v = list[i]
                self:Row(v.name, v.zone or "Zone unknown", v.here)
            end
            local factionWord = UnitFactionGroup("player") == "Horde" and "Alliance" or "Horde"
            local aside = section.hidden > 0 and ("%d %s vendors hidden"):format(section.hidden, factionWord) or nil
            if short then
                self:LinkLine(("Show all %d vendors"):format(total), function()
                    self.allVendors = true
                    self:Show(itemID)
                end, aside)
            elseif self.allVendors and total > ns.SourceDetails.SHORT_VENDORS then
                self:LinkLine("Show fewer", function()
                    self.allVendors = false
                    self.scroll:SetVerticalScroll(0)
                    self:Show(itemID)
                end, aside)
            elseif aside then
                self:Note(aside, C.faint)
            end
        end
    end
    self.content:SetHeight(math.max(1, self.y))
end
