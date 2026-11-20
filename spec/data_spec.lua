local helper = require("spec.helper")

-- A tiny fake LibQuestieDB with QuestieDB's nil/0 rules: unknown ids give nil,
-- missing numbers give 0, empty tables give nil (startedBy/finishedBy give {}).
local function entity(rows, defaults)
    local E = {}
    function E.Exists(id) return rows[id] ~= nil end
    setmetatable(E, { __index = function(_, field)
        return function(id)
            local row = rows[id]
            if not row then return nil end
            local v = row[field]
            if v == nil then return defaults[field] end
            return v
        end
    end })
    return E
end

local function fakeLib()
    return {
        RequireContract = function(v) return v <= 4, "too new" end,
        Item = entity({
            [100] = { name = "Tunic of Westfall", itemLevel = 24, questRewards = { 166 }, npcDrops = { 10 } },
            [200] = { name = "Boots of the Wanderer" },
        }, { itemLevel = 0, requiredLevel = 0, class = 0, subClass = 0 }),
        Quest = entity({
            [166] = { name = "The Defias Brotherhood", questLevel = 22, startedBy = { { 234 } },
                      preQuestSingle = { 165 }, zoneOrSort = 40, requiredMinRep = { 0, 0 } },
        }, { questLevel = 0, requiredLevel = 0, requiredRaces = 0, requiredClasses = 0,
             startedBy = {}, finishedBy = {}, zoneOrSort = 0, nextQuestInChain = 0, breadcrumbForQuestId = 0 }),
        Npc = entity({ [10] = { name = "Captain Greenskin", zoneID = 1581 } },
            { zoneID = 0, minLevel = 0, maxLevel = 0 }),
        Object = entity({}, {}),
    }
end

describe("Data", function()
    local Data

    before_each(function()
        Data = helper.loadAddonFile("Core/Data.lua").Data
        Data.lib = fakeLib()
    end)

    it("reports a missing QuestieDB", function()
        Data.lib = nil
        local ok, message = Data.Check()
        assert.is_false(ok)
        assert.matches("QuestieDB isn't loaded", message)
    end)

    it("passes the contract check", function()
        assert.is_true((Data.Check()))
    end)

    it("turns QuestieDB zeros into nil", function()
        local boots = Data.Item(200)
        assert.are.equal("Boots of the Wanderer", boots.name)
        assert.is_nil(boots.itemLevel)
        assert.is_nil(boots.requiredLevel)
        assert.is_nil(boots.questRewards)
        local quest = Data.Quest(166)
        assert.are.equal(22, quest.level)
        assert.is_nil(quest.requiredLevel)
        assert.is_nil(quest.requiredMinRep)
        assert.is_nil(quest.nextQuestInChain)
        assert.are.same({ 234 }, quest.startNpcs)
        assert.are.same({ 165 }, quest.preQuestSingle)
        assert.are.equal(40, quest.zoneID)
    end)

    it("returns nil for unknown ids and caches lookups", function()
        assert.is_nil(Data.Item(999))
        assert.is_nil(Data.Item("not a number"))
        local first = Data.Item(100)
        Data.lib = nil
        assert.are.equal(first, Data.Item(100))
        assert.is_nil(Data.Item(999))
    end)

    it("lists every Source of an item", function()
        assert.are.same({ { kind = "quest", id = 166 }, { kind = "drop", id = 10 } }, Data.ItemSources(100))
        assert.are.same({}, Data.ItemSources(200))
    end)

    it("parses item links and ids", function()
        assert.are.equal(2589, Data.ParseItemID("|cffffffff|Hitem:2589::::::::20:::::|h[Linen Cloth]|h|r"))
        assert.are.equal(2589, Data.ParseItemID(" 2589 "))
        assert.is_nil(Data.ParseItemID("linen"))
    end)

    it("describes an item for chat", function()
        assert.are.same({
            "Tunic of Westfall (item 100), item level 24",
            "  Quest reward: The Defias Brotherhood (166)",
            "  Drop: Captain Greenskin (10)",
        }, Data.DescribeItem(100))
        assert.are.same({ "Boots of the Wanderer (item 200)", "  Source not yet known." }, Data.DescribeItem(200))
        assert.are.same({ "Item 999 isn't in QuestieDB." }, Data.DescribeItem(999))
    end)
end)
