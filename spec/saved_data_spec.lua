local helper = require("spec.helper")

describe("SavedData.ApplyDefaults", function()
    local SavedData

    before_each(function()
        SavedData = helper.loadAddonFile("Core/SavedData.lua").SavedData
    end)

    it("creates a fresh table when nothing was saved", function()
        local db = SavedData.ApplyDefaults(nil, SavedData.CHARACTER_DEFAULTS)
        assert.are.same({}, db.gearSets)
        assert.are.equal(SavedData.SCHEMA_VERSION, db.schemaVersion)
    end)

    it("keeps existing values and fills in missing keys", function()
        local saved = { minimap = { hide = true, minimapPos = 200 } }
        local db = SavedData.ApplyDefaults(saved, SavedData.ACCOUNT_DEFAULTS)
        assert.are.equal(saved, db)
        assert.is_true(db.minimap.hide)
        assert.are.equal(200, db.minimap.minimapPos)
        assert.are.equal(SavedData.SCHEMA_VERSION, db.schemaVersion)
    end)

    it("does not share default tables between characters", function()
        local a = SavedData.ApplyDefaults(nil, SavedData.CHARACTER_DEFAULTS)
        local b = SavedData.ApplyDefaults(nil, SavedData.CHARACTER_DEFAULTS)
        a.gearSets["Leveling 40"] = {}
        assert.is_nil(b.gearSets["Leveling 40"])
        assert.is_nil(SavedData.CHARACTER_DEFAULTS.gearSets["Leveling 40"])
    end)
end)
