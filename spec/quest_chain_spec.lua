local helper = require("spec.helper")

describe("QuestChain", function()
    local QC

    local function data(quests)
        for id, q in pairs(quests) do q.id = id end
        return { Quest = function(id) return quests[id] end }
    end
    local function doneSet(list)
        local s = {}
        for _, id in ipairs(list) do s[id] = true end
        return function(id) return s[id] == true end
    end
    local function states(chain)
        local out = {}
        for _, s in ipairs(chain.steps) do out[#out + 1] = s.n .. ":" .. s.state end
        return table.concat(out, " ")
    end
    local lvl20 = { level = 20 }

    before_each(function()
        QC = helper.loadAddonFile("Core/QuestChain.lua").QuestChain
    end)

    it("walks a linear chain back from the reward quest", function()
        local d = data({ [1] = { name = "A" }, [2] = { name = "B", preQuestSingle = { 1 } },
                         [3] = { name = "C", preQuestSingle = { 2 } } })
        local chain = QC.Build(3, d, doneSet({ 1 }), lvl20)
        assert.are.equal("1:done 2:next 3:todo", states(chain))
        assert.are.equal(1, chain.done)
        assert.are.equal(3, chain.total)
    end)

    it("follows preQuestGroup (all of) before the quest", function()
        local d = data({ [1] = {}, [2] = {}, [3] = { preQuestGroup = { 1, 2 } } })
        assert.are.equal("1:next 2:todo 3:todo", states(QC.Build(3, d, doneSet({}), lvl20)))
    end)

    it("puts Breadcrumbs before the Step they lead to, uncounted", function()
        local d = data({ [9] = { name = "Crumb" }, [1] = { breadcrumbs = { 9 } }, [2] = { preQuestSingle = { 1 } } })
        local chain = QC.Build(2, d, doneSet({}), lvl20)
        assert.are.equal("B:optional 1:next 2:todo", states(chain))
        assert.are.equal(2, chain.total)
    end)

    it("groups Alternatives into one Step and follows the done one", function()
        local d = data({ [5] = { name = "Early" }, [1] = { name = "Alt 1" }, [2] = { name = "Alt 2", preQuestSingle = { 5 } },
                         [3] = { preQuestSingle = { 1, 2 } } })
        local chain = QC.Build(3, d, doneSet({ 2, 5 }), lvl20)
        assert.are.equal("1:done 2:done 3:next", states(chain))
        local alts = chain.steps[2].alts
        assert.are.equal(2, #alts)
        assert.is_false(alts[1].done)
        assert.is_true(alts[2].done)
    end)

    it("locks a Step above the player's level and everything after it", function()
        local d = data({ [1] = {}, [2] = { name = "Hard", requiredLevel = 30, preQuestSingle = { 1 } },
                         [3] = { preQuestSingle = { 2 } } })
        local chain = QC.Build(3, d, doneSet({ 1 }), lvl20)
        assert.are.equal("1:done 2:locked 3:locked", states(chain))
        assert.are.same({ step = 2, name = "Hard", reason = "needs level 30. You are level 20." }, chain.locked)
    end)

    it("closes the chain when an exclusive quest is done", function()
        local d = data({ [1] = {}, [2] = { exclusiveTo = { 7 }, preQuestSingle = { 1 } }, [3] = { preQuestSingle = { 2 } },
                         [7] = { name = "Loyal to the Horde" } })
        local chain = QC.Build(3, d, doneSet({ 1, 7 }), lvl20)
        assert.are.equal("1:done 2:missed 3:missed", states(chain))
        assert.are.equal("Loyal to the Horde", chain.missed.by)
    end)

    it("stops on cycles", function()
        local d = data({ [1] = { preQuestSingle = { 2 } }, [2] = { preQuestSingle = { 1 } } })
        assert.are.equal("1:next 2:todo", states(QC.Build(1, d, doneSet({}), lvl20)))
    end)

    it("folds finished Steps before the last done one on long chains", function()
        local quests = { [1] = {} }
        for i = 2, 10 do quests[i] = { preQuestSingle = { i - 1 } } end
        local chain = QC.Build(10, data(quests), doneSet({ 1, 2, 3, 4, 5, 6, 7 }), lvl20)
        assert.are.equal(6, QC.FoldCount(chain))
        local short = QC.Build(3, data({ [1] = {}, [2] = { preQuestSingle = { 1 } }, [3] = { preQuestSingle = { 2 } } }),
            doneSet({ 1, 2 }), lvl20)
        assert.are.equal(0, QC.FoldCount(short))
    end)
end)
