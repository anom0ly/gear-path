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

    ns.Minimap:Init(ns.accountDB)
end)

SLASH_GEARPATH1 = "/gearpath"
SlashCmdList.GEARPATH = function(msg)
    msg = strtrim(msg or ""):lower()
    if msg == "minimap" then
        local hide = not ns.accountDB.minimap.hide
        ns.Minimap:SetHidden(ns.accountDB, hide)
        print("|cffffd100Gear Path|r: minimap button " .. (hide and "hidden" or "shown") .. ".")
    else
        ns.MainWindow:Toggle()
    end
end
