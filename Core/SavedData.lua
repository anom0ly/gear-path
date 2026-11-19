-- Saved data: account-wide settings (GearPathDB) and per-character data (GearPathCharDB).
-- Pure Lua, no game API calls, so it can be unit tested.
local _, ns = ...

local SavedData = {}
ns.SavedData = SavedData

SavedData.SCHEMA_VERSION = 1

SavedData.ACCOUNT_DEFAULTS = {
    schemaVersion = SavedData.SCHEMA_VERSION,
    minimap = { hide = false },
}

SavedData.CHARACTER_DEFAULTS = {
    schemaVersion = SavedData.SCHEMA_VERSION,
    gearSets = {},          -- filled in by the Gear Set work
    selectedGearSet = nil,  -- name of the Selected Gear Set
    ownedHistory = {},      -- itemID -> true for every item ever Owned
    bankContents = {},      -- itemID -> true, from the last bank visit
}

local function copyDefaults(target, defaults)
    for key, value in pairs(defaults) do
        if type(value) == "table" then
            if type(target[key]) ~= "table" then
                target[key] = {}
            end
            copyDefaults(target[key], value)
        elseif target[key] == nil then
            target[key] = value
        end
    end
    return target
end

--- Fills in any missing keys from defaults without touching existing values.
--- Returns the table to store (a new one when saved is nil).
function SavedData.ApplyDefaults(saved, defaults)
    if type(saved) ~= "table" then
        saved = {}
    end
    return copyDefaults(saved, defaults)
end
