-- Startup: saved data, slash command and minimap button. Builds nothing heavy at login.
local addonName, ns = ...

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:SetScript("OnEvent", function(self, event, name)
    if event ~= "ADDON_LOADED" or name ~= addonName then return end
    self:UnregisterEvent("ADDON_LOADED")

    GearPathDB = ns.SavedData.ApplyDefaults(GearPathDB, ns.SavedData.ACCOUNT_DEFAULTS)
    GearPathCharDB = ns.SavedData.ApplyDefaults(GearPathCharDB, ns.SavedData.CHARACTER_DEFAULTS)
    ns.accountDB = GearPathDB
    ns.charDB = GearPathCharDB

    local ok, message = ns.Data.Check()
    ns.dataReady = ok
    if not ok then
        print("|cffffd100Gear Path|r: " .. message)
    end

    ns.Minimap:Init(ns.accountDB)
end)

local function say(line)
    print("|cffffd100Gear Path|r: " .. line)
end

local function itemCommand(arg)
    local itemID = ns.Data.ParseItemID(arg)
    if not itemID then
        say("Usage: /gearpath item <item link or item ID>")
        return
    end
    if not ns.dataReady then
        say("QuestieDB isn't available, so items can't be looked up.")
        return
    end
    for _, line in ipairs(ns.Data.DescribeItem(itemID)) do say(line) end
    -- Step 4 sorts items into Slots with the client's equip location. Report which call works here.
    local instant = (C_Item and C_Item.GetItemInfoInstant) or GetItemInfoInstant
    if instant then
        local _, _, _, equipLoc = instant(itemID)
        say("  Slot (instant lookup): " .. ((equipLoc and equipLoc ~= "") and equipLoc or "none"))
    else
        say("  No instant item lookup on this client.")
    end
    local getInfo = (C_Item and C_Item.GetItemInfo) or GetItemInfo
    if getInfo then
        local equipLoc = select(9, getInfo(itemID))
        say("  Slot (cached lookup): " .. (equipLoc == nil and "not cached yet, try again" or (equipLoc ~= "" and equipLoc or "none")))
    end
end

-- Shift-clicking an item link while the item picker is open puts it in the Slot.
local function onModifiedItemClick(link)
    if type(link) == "string" and IsModifiedClick("CHATLINK") and ns.ItemPicker.frame then
        ns.ItemPicker:TakeLink(link)
    end
end
if HandleModifiedItemClick then
    hooksecurefunc("HandleModifiedItemClick", onModifiedItemClick)
elseif ChatEdit_InsertLink then
    hooksecurefunc("ChatEdit_InsertLink", onModifiedItemClick)
end

SLASH_GEARPATH1 = "/gearpath"
SlashCmdList.GEARPATH = function(msg)
    msg = strtrim(msg or "")
    local command, rest = msg:match("^(%S*)%s*(.-)$")
    command = command:lower()
    if command == "item" then
        itemCommand(rest)
    elseif command == "minimap" then
        local hide = not ns.accountDB.minimap.hide
        ns.Minimap:SetHidden(ns.accountDB, hide)
        print("|cffffd100Gear Path|r: minimap button " .. (hide and "hidden" or "shown") .. ".")
    else
        ns.MainWindow:Toggle()
    end
end
