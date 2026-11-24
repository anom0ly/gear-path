-- Builds the Quest Chain that leads to a reward quest, walking prerequisites back
-- from it (DESIGN.md). Pure Lua: quest data comes from `data` (ns.Data) and quest
-- history from `isDone(questID)`, so it can be unit tested.
local _, ns = ...

local QuestChain = {}
ns.QuestChain = QuestChain

QuestChain.FOLD_OVER = 6 -- chains longer than this fold their finished Steps
local MAX_STEPS = 40

--- Ordered Steps from the first quest to rewardQuestID.
--- Each Step: { questID, alts = {questID,...} or nil, breadcrumb = true or nil }.
local function walk(rewardQuestID, data, isDone)
    local steps, seen = {}, {}

    local function addBreadcrumbs(q)
        for _, b in ipairs(q.breadcrumbs or {}) do
            if not seen[b] and data.Quest(b) then
                seen[b] = true
                steps[#steps + 1] = { questID = b, breadcrumb = true }
            end
        end
    end

    local visit
    visit = function(questID)
        if seen[questID] or #steps >= MAX_STEPS then return end
        local q = data.Quest(questID)
        if not q then return end
        seen[questID] = true
        for _, pre in ipairs(q.preQuestGroup or {}) do visit(pre) end
        local single = q.preQuestSingle
        if single and #single == 1 then
            visit(single[1])
        elseif single and #single > 1 then
            -- Alternatives: follow the one already done, else the first, for earlier Steps.
            local pick = single[1]
            for _, alt in ipairs(single) do
                if isDone(alt) then pick = alt break end
            end
            local pq = data.Quest(pick)
            if pq and not seen[pick] then
                for _, alt in ipairs(single) do seen[alt] = true end
                for _, pre in ipairs(pq.preQuestGroup or {}) do visit(pre) end
                if pq.preQuestSingle and #pq.preQuestSingle == 1 then visit(pq.preQuestSingle[1]) end
                addBreadcrumbs(pq)
                steps[#steps + 1] = { questID = pick, alts = single }
            end
        end
        addBreadcrumbs(q)
        steps[#steps + 1] = { questID = questID }
    end

    visit(rewardQuestID)
    return steps
end

--- The Quest Chain for a reward quest, with a state for each Step.
--- player = { level }. Returns {
---   steps = { { n = 1|"B", questID, name, level, requiredLevel, state, alts = { {questID, name, done} } } },
---   done, total, locked = { step, reason } or nil, missed = { by = quest name } or nil }.
--- States: done, next, todo, locked, optional (Breadcrumb), missed.
function QuestChain.Build(rewardQuestID, data, isDone, player)
    local raw = walk(rewardQuestID, data, isDone)
    local chain = { steps = {}, done = 0, total = 0 }

    -- A chain closes when a quest exclusive to one of its unfinished Steps is done.
    for _, r in ipairs(raw) do
        local q = data.Quest(r.questID)
        if not r.breadcrumb and not isDone(r.questID) then
            for _, ex in ipairs(q.exclusiveTo or {}) do
                local inAlts = false
                for _, alt in ipairs(r.alts or {}) do if alt == ex then inAlts = true end end
                if isDone(ex) and not inAlts then
                    local eq = data.Quest(ex)
                    chain.missed = { by = eq and eq.name or ("quest " .. ex), questID = r.questID }
                    break
                end
            end
        end
        if chain.missed then break end
    end

    local n, blocked, closed, nextFound = 0, false, false, false
    for _, r in ipairs(raw) do
        local q = data.Quest(r.questID)
        local step = { questID = r.questID, name = q.name or ("Quest " .. r.questID),
                       level = q.level, requiredLevel = q.requiredLevel, zoneID = q.zoneID }
        local done = isDone(r.questID)
        if r.alts then
            step.alts = {}
            for _, alt in ipairs(r.alts) do
                local aq = data.Quest(alt)
                local altDone = isDone(alt)
                done = done or altDone
                step.alts[#step.alts + 1] = { questID = alt, name = aq and aq.name or ("Quest " .. alt), done = altDone }
            end
        end
        if r.breadcrumb then
            step.n, step.breadcrumb = "B", true
            step.state = done and "done" or "optional"
        else
            n = n + 1
            step.n = n
            chain.total = chain.total + 1
            if chain.missed and r.questID == chain.missed.questID then closed = true end
            if done then
                step.state = "done"
                chain.done = chain.done + 1
            elseif closed then
                step.state = "missed"
            elseif blocked or (q.requiredLevel and player.level and q.requiredLevel > player.level) then
                step.state = "locked"
                if not blocked then
                    chain.locked = { step = n, name = step.name,
                                     reason = ("needs level %d. You are level %d."):format(q.requiredLevel, player.level) }
                end
                blocked = true
            elseif not nextFound then
                step.state = "next"
                nextFound = true
            else
                step.state = "todo"
            end
        end
        chain.steps[#chain.steps + 1] = step
    end
    return chain
end

--- How many leading Steps to fold into "Show N earlier Steps": the finished Steps
--- before the last done one, only on chains longer than FOLD_OVER.
function QuestChain.FoldCount(chain)
    if #chain.steps <= QuestChain.FOLD_OVER then return 0 end
    local lastDone = 0
    for i, s in ipairs(chain.steps) do
        if s.state == "done" then lastDone = i end
    end
    local fold = 0
    for i = 1, lastDone - 1 do
        local st = chain.steps[i].state
        if st ~= "done" and st ~= "optional" then break end
        fold = i
    end
    return fold
end
