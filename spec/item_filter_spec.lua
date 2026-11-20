local helper = require("spec.helper")

describe("ItemFilter", function()
    local F

    before_each(function()
        F = helper.loadAddonFile("Core/ItemFilter.lua").ItemFilter
    end)

    describe("SlotsFor", function()
        it("maps paired Slots to both positions", function()
            assert.are.same({ "finger1", "finger2" }, F.SlotsFor("INVTYPE_FINGER", "PRIEST"))
            assert.are.same({ "chest" }, F.SlotsFor("INVTYPE_ROBE", "PRIEST"))
        end)

        it("only offers one-hand weapons for the off hand to dual wielders", function()
            assert.are.same({ "mainhand" }, F.SlotsFor("INVTYPE_WEAPON", "PRIEST"))
            assert.are.same({ "mainhand", "offhand" }, F.SlotsFor("INVTYPE_WEAPON", "ROGUE"))
        end)

        it("leaves out shirts and tabards", function()
            assert.are.same({}, F.SlotsFor("INVTYPE_BODY", "PRIEST"))
            assert.are.same({}, F.SlotsFor("INVTYPE_TABARD", "PRIEST"))
        end)
    end)

    describe("CanUseType", function()
        it("follows armor proficiency", function()
            assert.is_true(F.CanUseType("PRIEST", 4, 1))   -- cloth
            assert.is_false(F.CanUseType("PRIEST", 4, 2))  -- leather
            assert.is_true(F.CanUseType("WARRIOR", 4, 4))  -- plate
            assert.is_true(F.CanUseType("PRIEST", 4, 0))   -- rings, necks, trinkets
        end)

        it("follows weapon proficiency", function()
            assert.is_true(F.CanUseType("PRIEST", 2, 19))  -- wand
            assert.is_false(F.CanUseType("PRIEST", 2, 7))  -- sword
            assert.is_true(F.CanUseType("MAGE", 2, 7))
        end)

        it("allows anything that isn't armor or a weapon", function()
            assert.is_true(F.CanUseType("PRIEST", 15, 0))
        end)
    end)

    describe("Unobtainable", function()
        local alliancePriest = { raceMask = 1, classMask = 16, faction = "A" }
        local data

        before_each(function()
            data = {
                sources = {},
                quests = {
                    [1] = { requiredRaces = 2 + 16 }, -- Horde races only
                    [2] = {},                         -- anyone
                    [3] = { requiredClasses = 1 },    -- warriors only
                },
                npcs = { [10] = { friendlyTo = "H" }, [11] = { friendlyTo = "AH" }, [12] = {} },
            }
            data.ItemSources = function(id) return data.sources[id] or {} end
            data.Quest = function(id) return data.quests[id] end
            data.Npc = function(id) return data.npcs[id] end
        end)

        it("keeps items with no known Source", function()
            assert.is_false(F.Unobtainable(1, alliancePriest, data))
        end)

        it("hides items only rewarded by other-faction or other-class quests", function()
            data.sources[1] = { { kind = "quest", id = 1 }, { kind = "quest", id = 3 } }
            assert.is_true(F.Unobtainable(1, alliancePriest, data))
            data.sources[1][3] = { kind = "quest", id = 2 }
            assert.is_false(F.Unobtainable(1, alliancePriest, data))
        end)

        it("hides items only sold by other-faction vendors", function()
            data.sources[1] = { { kind = "vendor", id = 10 } }
            assert.is_true(F.Unobtainable(1, alliancePriest, data))
            data.sources[1][2] = { kind = "vendor", id = 11 }
            assert.is_false(F.Unobtainable(1, alliancePriest, data))
        end)

        it("keeps drops", function()
            data.sources[1] = { { kind = "quest", id = 1 }, { kind = "drop", id = 99 } }
            assert.is_false(F.Unobtainable(1, alliancePriest, data))
        end)
    end)

    it("searches without case and without patterns", function()
        assert.is_true(F.MatchesSearch("Tunic of Westfall", "tunic"))
        assert.is_true(F.MatchesSearch("Robe (Heroic)", "(heroic"))
        assert.is_false(F.MatchesSearch("Tunic", "robe"))
        assert.is_true(F.MatchesSearch("Anything", ""))
    end)

    it("sorts highest level first, then by name", function()
        local sorted = F.Sort({ { name = "B", level = 10 }, { name = "A", level = 10 }, { name = "C", level = 30 }, { name = "D" } })
        assert.are.same({ "C", "A", "B", "D" }, { sorted[1].name, sorted[2].name, sorted[3].name, sorted[4].name })
    end)

    it("summarises Sources", function()
        local sources = { { kind = "vendor" }, { kind = "quest" }, { kind = "vendor" }, { kind = "objectDrop" } }
        assert.are.equal("Quest reward, Drop, Vendor", F.SourceSummary(sources))
        assert.are.equal("Quest, Drop, Vendor", F.SourceSummary(sources, true))
        assert.are.equal("Source not yet known", F.SourceSummary({}))
    end)
end)
