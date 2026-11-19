-- Minimap button through LibDataBroker + LibDBIcon.
local addonName, ns = ...

local Minimap = {}
ns.Minimap = Minimap

local ICON = "Interface\\Icons\\INV_Chest_Cloth_17"

function Minimap:Init(accountDB)
    local LDB = LibStub("LibDataBroker-1.1")
    local DBIcon = LibStub("LibDBIcon-1.0")

    local launcher = LDB:NewDataObject(addonName, {
        type = "launcher",
        text = "Gear Path",
        icon = ICON,
        OnClick = function(_, button)
            if button == "LeftButton" then
                ns.MainWindow:Toggle()
            end
        end,
        OnTooltipShow = function(tooltip)
            tooltip:AddLine("Gear Path", 1, 0.82, 0)
            tooltip:AddLine("Click to open or close the window.", 1, 1, 1)
            tooltip:AddLine("/gearpath minimap to hide this button.", 0.7, 0.7, 0.7)
        end,
    })

    DBIcon:Register(addonName, launcher, accountDB.minimap)
end

function Minimap:SetHidden(accountDB, hidden)
    local DBIcon = LibStub("LibDBIcon-1.0")
    accountDB.minimap.hide = hidden
    if hidden then
        DBIcon:Hide(addonName)
    else
        DBIcon:Show(addonName)
    end
end
