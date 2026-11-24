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

local function bits(mask)
    local out = {}
    for i = 0, 15 do
        local f = 2 ^ i
        if mask % (f * 2) >= f then out[#out + 1] = i + 1 end
    end
    return table.concat(out, ",")
end

--- Why the item picker does or doesn't list an item, for checking in game.
local function pickerLines(itemID)
    local lines = {}
    local function add(text) lines[#lines + 1] = "  Picker: " .. text end
    local player = ns.ItemIndex.Player()
    local info = ns.ItemIndex.Info(itemID)
    if not info then
        add("the game client returned no item info for this item.")
        return lines
    end
    local slots = ns.ItemFilter.SlotsFor(info.equipLoc, player.classFile)
    add(("equip location %s, type %s:%s (%s)"):format(tostring(info.equipLoc),
        tostring(info.classID), tostring(info.subClassID), tostring(info.subType)))
    if #slots == 0 then add("doesn't fit a Slot for your class.") end
    if not ns.ItemFilter.CanUseType(player.classFile, info.classID, info.subClassID) then
        add("your class can't use this type.")
    end
    for _, s in ipairs(ns.Data.ItemSources(itemID)) do
        if s.kind == "quest" then
            local q = ns.Data.Quest(s.id)
            add(("quest %d races %s (bits %s), classes %s (bits %s)"):format(s.id,
                tostring(q and q.requiredRaces), q and q.requiredRaces and bits(q.requiredRaces) or "-",
                tostring(q and q.requiredClasses), q and q.requiredClasses and bits(q.requiredClasses) or "-"))
        end
    end
    local _, _, raceID = UnitRace("player")
    local _, _, classID = UnitClass("player")
    add(("you are race %s, class %s"):format(tostring(raceID), tostring(classID)))
    add(ns.ItemFilter.Unobtainable(itemID, player, ns.Data) and "hidden as Unobtainable." or "not Unobtainable.")
    if ns.ItemIndex.IsReady() then
        for _, slotId in ipairs(slots) do
            local found = false
            for _, id in ipairs(ns.ItemIndex.ForSlot(slotId)) do
                if id == itemID then found = true break end
            end
            add(("%s in the %s list."):format(found and "is" or "is NOT", slotId))
        end
    else
        add("the item list isn't built yet; open the picker once and run this again.")
    end
    return lines
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
    for _, line in ipairs(pickerLines(itemID)) do say(line) end
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
