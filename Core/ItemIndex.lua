-- Sorts QuestieDB's items into Slots using the game client's equip location.
-- Built once per session, on first use, in small batches so the game never freezes.
local _, ns = ...

local ItemIndex = {}
ns.ItemIndex = ItemIndex

local BATCH = 400

local state = "idle" -- idle | building | ready
local bySlot, info = {}, {}
local progress = 0
local listeners = {}

local function instant(itemID)
    local fn = (C_Item and C_Item.GetItemInfoInstant) or GetItemInfoInstant
    if fn then return fn(itemID) end
end

--- Client facts for one item: equipLoc, icon, classID, subClassID, subType.
function ItemIndex.Info(itemID)
    if info[itemID] == nil then
        local id, _, subType, equipLoc, icon, classID, subClassID = instant(itemID)
        info[itemID] = id and {
            equipLoc = equipLoc, icon = icon, classID = classID,
            subClassID = subClassID, subType = subType,
        } or false
    end
    return info[itemID] or nil
end

function ItemIndex.Player()
    local _, classFile, classID = UnitClass("player")
    local _, _, raceID = UnitRace("player")
    local faction = UnitFactionGroup("player")
    return {
        classFile = classFile,
        classMask = 2 ^ ((classID or 1) - 1),
        raceMask = 2 ^ ((raceID or 1) - 1),
        faction = faction == "Horde" and "H" or "A",
        level = UnitLevel("player"),
    }
end

function ItemIndex.IsReady() return state == "ready" end
function ItemIndex.Progress() return progress end

--- Item IDs that fit a Slot for this class, unsorted and unfiltered by faction.
function ItemIndex.ForSlot(slotId)
    return bySlot[slotId] or {}
end

--- Starts the build if needed. onChange() is called as progress moves and when done.
function ItemIndex.Build(onChange)
    if onChange then listeners[#listeners + 1] = onChange end
    if state ~= "idle" then return end
    state = "building"

    local lib = _G.LibQuestieDB
    local ids = lib and lib.Item and lib.Item.GetAllIds() or {}
    local classFile = ItemIndex.Player().classFile
    local i, total = 1, #ids

    local function notify()
        for _, fn in ipairs(listeners) do fn() end
    end

    local function step()
        local last = math.min(i + BATCH - 1, total)
        for n = i, last do
            local itemID = ids[n]
            local id, _, subType, equipLoc, icon, classID, subClassID = instant(itemID)
            local slots = id and equipLoc and ns.ItemFilter.SlotsFor(equipLoc, classFile) or {}
            if #slots > 0 and ns.ItemFilter.CanUseType(classFile, classID, subClassID) then
                info[itemID] = { equipLoc = equipLoc, icon = icon, classID = classID,
                                 subClassID = subClassID, subType = subType }
                for _, slotId in ipairs(slots) do
                    local list = bySlot[slotId] or {}
                    list[#list + 1] = itemID
                    bySlot[slotId] = list
                end
            end
        end
        i = last + 1
        progress = total > 0 and (i - 1) / total or 1
        if i > total then
            state = "ready"
            notify()
            listeners = {}
        else
            notify()
            C_Timer.After(0, step)
        end
    end

    C_Timer.After(0, step)
end
