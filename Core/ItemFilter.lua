-- Rules for which items belong in which Slot and which items a character can use.
-- Pure Lua (no game calls), so it can be unit tested.
local _, ns = ...

local ItemFilter = {}
ns.ItemFilter = ItemFilter

local ARMOR, WEAPON = 4, 2

-- Armor and weapon subclass IDs each class can use (Classic proficiencies).
-- Armor: 0 misc, 1 cloth, 2 leather, 3 mail, 4 plate, 6 shield, 7 libram, 8 idol, 9 totem.
-- Weapon: 0/1 axe 1H/2H, 2 bow, 3 gun, 4/5 mace 1H/2H, 6 polearm, 7/8 sword 1H/2H,
--         10 staff, 13 fist, 14 misc, 15 dagger, 16 thrown, 18 crossbow, 19 wand.
local function set(list)
    local s = {}
    for _, v in ipairs(list) do s[v] = true end
    return s
end

ItemFilter.CLASSES = {
    WARRIOR = { armor = set { 0, 1, 2, 3, 4, 6 }, weapon = set { 0, 1, 2, 3, 4, 5, 6, 7, 8, 10, 13, 14, 15, 16, 18 }, dualWield = true },
    PALADIN = { armor = set { 0, 1, 2, 3, 4, 6, 7 }, weapon = set { 0, 1, 4, 5, 6, 7, 8, 14 } },
    HUNTER  = { armor = set { 0, 1, 2, 3 }, weapon = set { 0, 1, 2, 3, 6, 7, 8, 10, 13, 14, 15, 16, 18 }, dualWield = true },
    ROGUE   = { armor = set { 0, 1, 2 }, weapon = set { 2, 3, 4, 7, 13, 14, 15, 16, 18 }, dualWield = true },
    PRIEST  = { armor = set { 0, 1 }, weapon = set { 4, 10, 14, 15, 19 } },
    SHAMAN  = { armor = set { 0, 1, 2, 3, 6, 9 }, weapon = set { 0, 1, 4, 5, 10, 13, 14, 15 } },
    MAGE    = { armor = set { 0, 1 }, weapon = set { 7, 10, 14, 15, 19 } },
    WARLOCK = { armor = set { 0, 1 }, weapon = set { 7, 10, 14, 15, 19 } },
    DRUID   = { armor = set { 0, 1, 2, 8 }, weapon = set { 4, 5, 10, 13, 14, 15 } },
}

-- Game equip location -> Slot ids it can go in. "dw" marks Slots that need dual wield.
local EQUIP = {
    INVTYPE_HEAD = { "head" },
    INVTYPE_NECK = { "neck" },
    INVTYPE_SHOULDER = { "shoulder" },
    INVTYPE_CLOAK = { "back" },
    INVTYPE_CHEST = { "chest" },
    INVTYPE_ROBE = { "chest" },
    INVTYPE_WRIST = { "wrist" },
    INVTYPE_HAND = { "hands" },
    INVTYPE_WAIST = { "waist" },
    INVTYPE_LEGS = { "legs" },
    INVTYPE_FEET = { "feet" },
    INVTYPE_FINGER = { "finger1", "finger2" },
    INVTYPE_TRINKET = { "trinket1", "trinket2" },
    INVTYPE_WEAPON = { "mainhand", { "offhand", dw = true } },
    INVTYPE_WEAPONMAINHAND = { "mainhand" },
    INVTYPE_WEAPONOFFHAND = { { "offhand", dw = true } },
    INVTYPE_2HWEAPON = { "mainhand" },
    INVTYPE_SHIELD = { "offhand" },
    INVTYPE_HOLDABLE = { "offhand" },
    INVTYPE_RANGED = { "ranged" },
    INVTYPE_RANGEDRIGHT = { "ranged" },
    INVTYPE_THROWN = { "ranged" },
    INVTYPE_RELIC = { "ranged" },
}

--- Slot ids an equip location fits, for this class. Empty for shirts, tabards, bags.
function ItemFilter.SlotsFor(equipLoc, classFile)
    local out = {}
    local class = ItemFilter.CLASSES[classFile] or {}
    for _, entry in ipairs(EQUIP[equipLoc] or {}) do
        if type(entry) == "string" then
            out[#out + 1] = entry
        elseif class.dualWield then
            out[#out + 1] = entry[1]
        end
    end
    return out
end

--- Whether this class can use an item's armor or weapon type.
function ItemFilter.CanUseType(classFile, classID, subClassID)
    local class = ItemFilter.CLASSES[classFile]
    if not class then return true end
    if classID == ARMOR then return class.armor[subClassID] == true end
    if classID == WEAPON then return class.weapon[subClassID] == true end
    return true
end

-- Type filters in the item picker. Only Slots that take armor types get them.
ItemFilter.ARMOR_SLOTS = set { "head", "shoulder", "back", "chest", "wrist", "hands", "waist", "legs", "feet" }
ItemFilter.ARMOR_FILTERS = {
    { key = "cloth", label = "Cloth", subClassID = 1 },
    { key = "leather", label = "Leather", subClassID = 2 },
    { key = "mail", label = "Mail", subClassID = 3 },
    { key = "plate", label = "Plate", subClassID = 4 },
    { key = "other", label = "Other" },
}
local FILTER_BY_SUBCLASS = { [1] = "cloth", [2] = "leather", [3] = "mail", [4] = "plate" }

--- Which of the five armor filters an item falls under.
function ItemFilter.ArmorFilterKey(classID, subClassID)
    return classID == ARMOR and FILTER_BY_SUBCLASS[subClassID] or "other"
end

--- Whether this class can wear an armor filter's type ("other" is always usable).
function ItemFilter.ArmorFilterUsable(classFile, filter)
    if not filter.subClassID then return true end
    local class = ItemFilter.CLASSES[classFile]
    return not class or class.armor[filter.subClassID] == true
end

local function hasBit(mask, flag)
    return mask % (flag * 2) >= flag
end

--- Whether a quest is open to this character. player = { raceMask, classMask }.
local function questOpen(quest, player)
    if not quest then return false end
    if quest.requiredRaces and not hasBit(quest.requiredRaces, player.raceMask) then return false end
    if quest.requiredClasses and not hasBit(quest.requiredClasses, player.classMask) then return false end
    return true
end

--- True when every known Source is closed to this character (other faction or class),
--- so the item is Unobtainable and hidden. Items with no known Source stay visible.
--- player = { raceMask, classMask, faction = "A"|"H" }; data = ns.Data.
function ItemFilter.Unobtainable(itemID, player, data)
    local sources = data.ItemSources(itemID)
    if #sources == 0 then return false end
    for _, s in ipairs(sources) do
        if s.kind == "quest" then
            if questOpen(data.Quest(s.id), player) then return false end
        elseif s.kind == "vendor" then
            local npc = data.Npc(s.id)
            local friendly = npc and npc.friendlyTo
            if not friendly or friendly:find(player.faction, 1, true) then return false end
        else
            return false -- drops can be looted by anyone
        end
    end
    return true
end

--- Case-insensitive plain substring match.
function ItemFilter.MatchesSearch(name, query)
    if not query or query == "" then return true end
    if not name then return false end
    return name:lower():find(query:lower(), 1, true) ~= nil
end

--- Sorts entries { name, level } highest level first, then by name.
function ItemFilter.Sort(entries)
    table.sort(entries, function(a, b)
        local la, lb = a.level or 0, b.level or 0
        if la ~= lb then return la > lb end
        return (a.name or "") < (b.name or "")
    end)
    return entries
end

local SOURCE_LABEL = { quest = "Quest reward", drop = "Drop", objectDrop = "Drop", vendor = "Vendor" }
local SOURCE_SHORT = { quest = "Quest", drop = "Drop", objectDrop = "Drop", vendor = "Vendor" }

--- "Quest reward, Drop" style summary of Source kinds, in a stable order.
function ItemFilter.SourceSummary(sources, short)
    local labels = short and SOURCE_SHORT or SOURCE_LABEL
    local seen, out = {}, {}
    for _, kind in ipairs({ "quest", "drop", "objectDrop", "vendor" }) do
        for _, s in ipairs(sources) do
            local label = labels[kind]
            if s.kind == kind and not seen[label] then
                seen[label] = true
                out[#out + 1] = label
            end
        end
    end
    if #out == 0 then return short and "Source unknown" or "Source not yet known" end
    return table.concat(out, ", ")
end
