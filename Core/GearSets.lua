-- Gear Sets for one character: create, rename, delete, select.
-- Pure Lua over the saved character table, so it can be unit tested.
-- Stored as charDB.gearSets[name] = { items = { [slotId] = itemID } }.
local _, ns = ...

local GearSets = {}
ns.GearSets = GearSets

local MAX_NAME_LENGTH = 40

local function trim(s)
    return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

--- Cleans a typed name. Returns nil when nothing usable is left.
function GearSets.CleanName(name)
    if type(name) ~= "string" then return nil end
    name = trim(name:gsub("[%c|]", ""))
    if name == "" then return nil end
    if #name > MAX_NAME_LENGTH then
        name = trim(name:sub(1, MAX_NAME_LENGTH))
    end
    return name
end

--- Returns name, or the next free "name (2)", "name (3)"... on this character.
--- `ignore` is a set name that doesn't count as taken (the one being renamed).
function GearSets.UniqueName(db, name, ignore)
    local function taken(n) return n ~= ignore and db.gearSets[n] ~= nil end
    if not taken(name) then return name end
    local base = name:match("^(.-) %(%d+%)$") or name
    local n = 2
    while taken(base .. " (" .. n .. ")") do n = n + 1 end
    return base .. " (" .. n .. ")"
end

--- Names of all Gear Sets, sorted case-insensitively.
function GearSets.List(db)
    local names = {}
    for name in pairs(db.gearSets) do names[#names + 1] = name end
    table.sort(names, function(a, b)
        local la, lb = a:lower(), b:lower()
        if la == lb then return a < b end
        return la < lb
    end)
    return names
end

function GearSets.Get(db, name)
    return name and db.gearSets[name] or nil
end

--- The Selected Gear Set's name, falling back to the first set if the saved one is gone.
function GearSets.Selected(db)
    if db.selectedGearSet and db.gearSets[db.selectedGearSet] then
        return db.selectedGearSet
    end
    local first = GearSets.List(db)[1]
    db.selectedGearSet = first
    return first
end

function GearSets.Select(db, name)
    if db.gearSets[name] then db.selectedGearSet = name end
end

--- Creates an empty Gear Set and selects it. Returns the name it was saved under, or nil.
function GearSets.Create(db, name)
    name = GearSets.CleanName(name)
    if not name then return nil end
    name = GearSets.UniqueName(db, name)
    db.gearSets[name] = { items = {} }
    db.selectedGearSet = name
    return name
end

--- Renames a Gear Set. Returns the name it was saved under, or nil.
function GearSets.Rename(db, oldName, newName)
    local set = db.gearSets[oldName]
    newName = GearSets.CleanName(newName)
    if not set or not newName then return nil end
    newName = GearSets.UniqueName(db, newName, oldName)
    if newName == oldName then return oldName end
    db.gearSets[oldName] = nil
    db.gearSets[newName] = set
    if db.selectedGearSet == oldName then db.selectedGearSet = newName end
    return newName
end

--- Deletes a Gear Set. If it was selected, the next set in the list is selected.
function GearSets.Delete(db, name)
    if not db.gearSets[name] then return end
    local names = GearSets.List(db)
    local index
    for i, n in ipairs(names) do if n == name then index = i end end
    db.gearSets[name] = nil
    if db.selectedGearSet == name then
        db.selectedGearSet = names[index + 1] or names[index - 1]
    end
end

--- How many Slots have an item chosen.
function GearSets.ItemCount(set)
    local count = 0
    for _ in pairs(set and set.items or {}) do count = count + 1 end
    return count
end
