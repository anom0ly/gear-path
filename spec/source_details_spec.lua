local helper = require("spec.helper")

describe("SourceDetails", function()
    local S, ns
    local names = {
        zone = function(id) return ({ [1637] = "Orgrimmar", [14] = "Durotar", [17] = "The Barrens", [1519] = "Stormwind City", [85] = "Tirisfal Glades" })[id] end,
        race = function(id) return ({ "Human", "Orc", "Dwarf", "Night Elf", "Undead", "Tauren", "Gnome", "Troll" })[id] end,
        class = function(id) return ({ "Warrior", "Paladin", "Hunter", "Rogue", "Priest" })[id] end,
        faction = function() return "Argent Dawn" end,
    }
    local undeadWarrior = { raceMask = 16, classMask = 1, faction = "H", zone = "Durotar" }

    local function fakeData(items, quests, npcs, objects)
        return {
            Item = function(id) return items[id] end,
            Quest = function(id) return quests[id] end,
            Npc = function(id) return npcs[id] end,
            Object = function(id) return (objects or {})[id] end,
        }
    end

    before_each(function()
        ns = helper.loadAddonFile("Core/ItemFilter.lua")
        S = helper.loadAddonFile("Core/SourceDetails.lua", ns).SourceDetails
    end)

    it("describes quest limits", function()
        assert.are.equal("None", S.Requires({}, names))
        assert.are.equal("Horde", S.Requires({ requiredRaces = 8589934770 }, names))
        assert.are.equal("Alliance", S.Requires({ requiredRaces = 4294967373 }, names))
        assert.are.equal("Undead only", S.Requires({ requiredRaces = 16 }, names))
        assert.are.equal("Warrior, Paladin only", S.Requires({ requiredClasses = 3 }, names))
        assert.are.equal("Reputation with Argent Dawn", S.Requires({ requiredMinRep = { id = 529 } }, names))
    end)

    it("lists open quests with giver, zone and level", function()
        local data = fakeData(
            { [1] = { questRewards = { 10, 11 } } },
            { [10] = { name = "Night Web's Hollow", level = 7, requiredLevel = 4, requiredRaces = 16, startNpcs = { 100 } },
              [11] = { name = "Alliance only", requiredRaces = 4294967373 } },
            { [100] = { name = "Executor Zygand", zoneID = 85 } })
        local sections = S.Build(1, undeadWarrior, data, names)
        assert.are.equal(1, #sections)
        local q = sections[1].quests
        assert.are.equal(1, #q)
        assert.are.same({ id = 10, name = "Night Web's Hollow", giver = "Executor Zygand", where = "Tirisfal Glades",
                          level = "Quest level 7 · you can take it at 4", requires = "Undead only" }, q[1])
    end)

    it("sorts drops by level and marks objects", function()
        local data = fakeData(
            { [1] = { npcDrops = { 1, 2 }, objectDrops = { 3 } } }, {},
            { [1] = { id = 1, name = "Low", minLevel = 10, maxLevel = 11, zoneID = 17 },
              [2] = { id = 2, name = "High", minLevel = 40, maxLevel = 40 } },
            { [3] = { id = 3, name = "Chest" } })
        local drops = S.Build(1, undeadWarrior, data, names)[1].drops
        assert.are.same({ "High", "Low", "Chest" }, { drops[1].name, drops[2].name, drops[3].name })
        assert.are.equal("level 40", drops[1].sub)
        assert.are.equal("The Barrens · level 10–11", drops[2].sub)
        assert.are.equal("object", drops[3].kind)
    end)

    it("filters vendors by faction and puts the current zone first", function()
        local data = fakeData(
            { [1] = { vendors = { 1, 2, 3, 4 } } }, {},
            { [1] = { name = "Stormwind Guy", friendlyTo = "A", zoneID = 1519 },
              [2] = { name = "Org Guy", friendlyTo = "H", zoneID = 1637 },
              [3] = { name = "Goblin", friendlyTo = "AH", zoneID = 17 },
              [4] = { name = "Durotar Guy", friendlyTo = "H", zoneID = 14 } })
        local section = S.Build(1, undeadWarrior, data, names)[1]
        assert.are.equal(1, section.hidden)
        assert.are.same({ "Durotar Guy", "Org Guy", "Goblin" },
            { section.vendors[1].name, section.vendors[2].name, section.vendors[3].name })
        assert.is_true(section.vendors[1].here)
    end)

    it("orders sections Quest, Drop, Vendor and skips empty ones", function()
        local data = fakeData(
            { [1] = { questRewards = { 10 }, vendors = { 2 } } },
            { [10] = { name = "Q" } }, { [2] = { name = "V", friendlyTo = "AH" } })
        local sections = S.Build(1, undeadWarrior, data, names)
        assert.are.same({ "quest", "vendor" }, { sections[1].kind, sections[2].kind })
    end)
end)
