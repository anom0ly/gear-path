-- Builds what the Source panel shows for one item: quest rewards, drops and vendors.
-- Pure Lua: game data comes in through `data` (ns.Data) and names through `names`,
-- so it can be unit tested.
local _, ns = ...

local SourceDetails = {}
ns.SourceDetails = SourceDetails

SourceDetails.SHORT_VENDORS = 3

local ALLIANCE, HORDE = 77, 178 -- race bits of each faction's starting races

local function lowBits(mask)
    return mask % 4294967296 -- QuestieDB adds 2^32 / 2^33 to whole-faction masks
end

--- Race and class limits of a quest, as text. names = { race(id), class(id), faction(id) }.
function SourceDetails.Requires(quest, names)
    local parts = {}
    if quest.requiredRaces then
        local races = lowBits(quest.requiredRaces)
        if races == ALLIANCE then
            parts[#parts + 1] = "Alliance"
        elseif races == HORDE then
            parts[#parts + 1] = "Horde"
        elseif races ~= 0 and races ~= ALLIANCE + HORDE then
            local list = {}
            for i = 1, 16 do
                local flag = 2 ^ (i - 1)
                if races % (flag * 2) >= flag then list[#list + 1] = names.race(i) or ("race " .. i) end
            end
            parts[#parts + 1] = table.concat(list, ", ") .. " only"
        end
    end
    if quest.requiredClasses then
        local list = {}
        for i = 1, 16 do
            local flag = 2 ^ (i - 1)
            if quest.requiredClasses % (flag * 2) >= flag then list[#list + 1] = names.class(i) or ("class " .. i) end
        end
        if #list > 0 then parts[#parts + 1] = table.concat(list, ", ") .. " only" end
    end
    if quest.requiredMinRep then
        local faction = names.faction(quest.requiredMinRep.id) or "a faction"
        parts[#parts + 1] = "Reputation with " .. faction
    end
    if #parts == 0 then return "None" end
    return table.concat(parts, " · ")
end

local function levelRange(minLevel, maxLevel)
    if not minLevel and not maxLevel then return nil end
    if not maxLevel or minLevel == maxLevel then return "level " .. (minLevel or maxLevel) end
    if not minLevel then return "level " .. maxLevel end
    return ("level %d–%d"):format(minLevel, maxLevel)
end

--- Name, giver, zone, level and limits of one quest, for a card.
function SourceDetails.QuestInfo(q, data, names)
    local giver = q.startNpcs and data.Npc(q.startNpcs[1])
    local where = giver and giver.zoneID and names.zone(giver.zoneID)
        or (q.zoneID and names.zone(q.zoneID))
    local level
    if q.level then
        level = "Quest level " .. q.level
        if q.requiredLevel then level = level .. " · you can take it at " .. q.requiredLevel end
    elseif q.requiredLevel then
        level = "You can take it at " .. q.requiredLevel
    end
    return {
        id = q.id, name = q.name or ("Quest " .. tostring(q.id)),
        giver = giver and giver.name, where = where, level = level,
        requires = SourceDetails.Requires(q, names),
    }
end

--- Sections for the Source panel, in the order Quest, Drop, Vendor.
--- player = { raceMask, classMask, faction = "A"|"H", zone = current zone name }.
--- names = { zone(areaID), race(id), class(id), faction(id) }.
function SourceDetails.Build(itemID, player, data, names)
    local item = data.Item(itemID)
    local sections = {}
    if not item then return sections end

    local quests = {}
    for _, questID in ipairs(item.questRewards or {}) do
        local q = data.Quest(questID)
        if q and ns.ItemFilter.QuestOpen(q, player) then
            local info = SourceDetails.QuestInfo(q, data, names)
            info.id = questID
            quests[#quests + 1] = info
        end
    end
    if #quests > 0 then sections[#sections + 1] = { kind = "quest", quests = quests } end

    local drops = {}
    local function addDrop(entity, kind)
        local zone = entity.zoneID and names.zone(entity.zoneID)
        local range = levelRange(entity.minLevel, entity.maxLevel)
        local sub = {}
        if zone then sub[#sub + 1] = zone end
        if range then sub[#sub + 1] = range end
        drops[#drops + 1] = { id = entity.id, kind = kind, name = entity.name or "?",
                              sub = table.concat(sub, " · "), level = entity.maxLevel or entity.minLevel or 0 }
    end
    for _, npcID in ipairs(item.npcDrops or {}) do
        local npc = data.Npc(npcID)
        if npc then addDrop(npc, "npc") end
    end
    for _, objectID in ipairs(item.objectDrops or {}) do
        local object = data.Object(objectID)
        if object then addDrop(object, "object") end
    end
    table.sort(drops, function(a, b)
        if a.level ~= b.level then return a.level > b.level end
        return a.name < b.name
    end)
    if #drops > 0 then sections[#sections + 1] = { kind = "drop", drops = drops } end

    local vendors, hidden = {}, 0
    for _, npcID in ipairs(item.vendors or {}) do
        local npc = data.Npc(npcID)
        if npc then
            local friendly = npc.friendlyTo
            if friendly and not friendly:find(player.faction, 1, true) then
                hidden = hidden + 1
            else
                local zone = npc.zoneID and names.zone(npc.zoneID)
                vendors[#vendors + 1] = { id = npcID, name = npc.name or "?", zone = zone,
                                          here = zone ~= nil and zone == player.zone }
            end
        end
    end
    table.sort(vendors, function(a, b)
        if a.here ~= b.here then return a.here end
        if (a.zone or "~") ~= (b.zone or "~") then return (a.zone or "~") < (b.zone or "~") end
        return a.name < b.name
    end)
    if #vendors > 0 then
        sections[#sections + 1] = { kind = "vendor", vendors = vendors, hidden = hidden }
    end
    return sections
end
