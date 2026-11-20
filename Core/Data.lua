-- The one place Gear Path reads game data, through QuestieDB's LibQuestieDB (ADR 0001).
-- Lookups run on first use and are cached for the session; nothing is read at login.
-- QuestieDB returns 0 for unknown numbers; this module turns those into nil.
local _, ns = ...

local Data = {}
ns.Data = Data

Data.REQUIRED_CONTRACT = 1

local cache = { item = {}, quest = {}, npc = {}, object = {} }

local function lib()
    return Data.lib or _G.LibQuestieDB
end

local function num(v)
    if v == nil or v == 0 then return nil end
    return v
end

local function list(v)
    if type(v) ~= "table" or #v == 0 then return nil end
    return v
end

--- Checks that QuestieDB is loaded and new enough. Returns ok, message.
function Data.Check()
    local L = lib()
    if not L then
        return false, "QuestieDB isn't loaded, so Gear Path can't look up items or quests."
    end
    if L.RequireContract then
        local ok, message = L.RequireContract(Data.REQUIRED_CONTRACT)
        if not ok then
            return false, "Your QuestieDB version doesn't work with Gear Path: " .. tostring(message)
        end
    end
    return true
end

local function cached(kind, id, build)
    id = tonumber(id)
    if not id then return nil end
    local hit = cache[kind][id]
    if hit ~= nil then return hit or nil end
    local value = build(id) or false
    cache[kind][id] = value
    return value or nil
end

function Data.Item(id)
    return cached("item", id, function(itemID)
        local E = lib() and lib().Item
        if not E or not E.Exists(itemID) then return nil end
        return {
            id = itemID,
            name = E.name(itemID),
            itemLevel = num(E.itemLevel(itemID)),
            requiredLevel = num(E.requiredLevel(itemID)),
            class = E.class(itemID),
            subClass = E.subClass(itemID),
            questRewards = list(E.questRewards(itemID)),
            npcDrops = list(E.npcDrops(itemID)),
            objectDrops = list(E.objectDrops(itemID)),
            vendors = list(E.vendors(itemID)),
        }
    end)
end

local function pair(p)
    if type(p) ~= "table" or num(p[1]) == nil then return nil end
    return { id = p[1], value = p[2] }
end

function Data.Quest(id)
    return cached("quest", id, function(questID)
        local E = lib() and lib().Quest
        if not E or not E.Exists(questID) then return nil end
        local startedBy = E.startedBy(questID) or {}
        local finishedBy = E.finishedBy(questID) or {}
        local zone = E.zoneOrSort(questID)
        return {
            id = questID,
            name = E.name(questID),
            level = num(E.questLevel(questID)),
            requiredLevel = num(E.requiredLevel(questID)),
            requiredRaces = num(E.requiredRaces(questID)),
            requiredClasses = num(E.requiredClasses(questID)),
            startNpcs = list(startedBy[1]),
            startObjects = list(startedBy[2]),
            startItems = list(startedBy[3]),
            endNpcs = list(finishedBy[1]),
            endObjects = list(finishedBy[2]),
            preQuestGroup = list(E.preQuestGroup(questID)),   -- all of these first
            preQuestSingle = list(E.preQuestSingle(questID)), -- any one of these first
            exclusiveTo = list(E.exclusiveTo(questID)),
            breadcrumbs = list(E.breadcrumbs(questID)),
            breadcrumbFor = num(E.breadcrumbForQuestId(questID)),
            nextQuestInChain = num(E.nextQuestInChain(questID)),
            requiredMinRep = pair(E.requiredMinRep(questID)),
            zoneID = (zone and zone > 0) and zone or nil,
            objectivesText = list(E.objectivesText(questID)),
        }
    end)
end

function Data.Npc(id)
    return cached("npc", id, function(npcID)
        local E = lib() and lib().Npc
        if not E or not E.Exists(npcID) then return nil end
        return {
            id = npcID,
            name = E.name(npcID),
            subName = E.subName(npcID),
            zoneID = num(E.zoneID(npcID)),
            minLevel = num(E.minLevel(npcID)),
            maxLevel = num(E.maxLevel(npcID)),
            friendlyTo = E.friendlyToFaction(npcID),
            spawns = E.spawns(npcID),
        }
    end)
end

function Data.Object(id)
    return cached("object", id, function(objectID)
        local E = lib() and lib().Object
        if not E or not E.Exists(objectID) then return nil end
        return {
            id = objectID,
            name = E.name(objectID),
            zoneID = num(E.zoneID(objectID)),
            spawns = E.spawns(objectID),
        }
    end)
end

--- Every Source of an item, as { kind = "quest"|"drop"|"objectDrop"|"vendor", id = n }.
--- An empty list means "Source not yet known".
function Data.ItemSources(itemID)
    local item = Data.Item(itemID)
    local sources = {}
    if not item then return sources end
    local function add(kind, ids)
        for _, id in ipairs(ids or {}) do sources[#sources + 1] = { kind = kind, id = id } end
    end
    add("quest", item.questRewards)
    add("drop", item.npcDrops)
    add("objectDrop", item.objectDrops)
    add("vendor", item.vendors)
    return sources
end

function Data.ClearCache()
    for kind in pairs(cache) do cache[kind] = {} end
end

--- Pulls an item ID out of an item link or a plain number.
function Data.ParseItemID(text)
    if type(text) ~= "string" then return tonumber(text) end
    return tonumber(text:match("item:(%d+)") or text:match("^%s*(%d+)%s*$"))
end

local KIND_LABEL = { quest = "Quest reward", drop = "Drop", objectDrop = "Found in", vendor = "Vendor" }

--- Chat lines describing an item and its Sources, for /gearpath item.
function Data.DescribeItem(itemID)
    local item = Data.Item(itemID)
    if not item then
        return { ("Item %s isn't in QuestieDB."):format(tostring(itemID)) }
    end
    local lines = {}
    local header = ("%s (item %d)"):format(item.name or "?", item.id)
    local facts = {}
    if item.itemLevel then facts[#facts + 1] = "item level " .. item.itemLevel end
    if item.requiredLevel then facts[#facts + 1] = "requires level " .. item.requiredLevel end
    if #facts > 0 then header = header .. ", " .. table.concat(facts, ", ") end
    lines[1] = header

    local sources = Data.ItemSources(itemID)
    if #sources == 0 then
        lines[#lines + 1] = "  Source not yet known."
    end
    for _, s in ipairs(sources) do
        local name
        if s.kind == "quest" then
            local q = Data.Quest(s.id)
            name = q and q.name
        elseif s.kind == "objectDrop" then
            local o = Data.Object(s.id)
            name = o and o.name
        else
            local n = Data.Npc(s.id)
            name = n and n.name
        end
        lines[#lines + 1] = ("  %s: %s (%d)"):format(KIND_LABEL[s.kind], name or "unknown", s.id)
    end
    return lines
end
