local helper = require("spec.helper")

describe("GearSets", function()
    local GearSets, db

    before_each(function()
        GearSets = helper.loadAddonFile("Core/GearSets.lua").GearSets
        db = { gearSets = {} }
    end)

    describe("Create", function()
        it("creates an empty set and selects it", function()
            assert.are.equal("Leveling 40", GearSets.Create(db, "  Leveling 40 "))
            assert.are.same({ items = {} }, db.gearSets["Leveling 40"])
            assert.are.equal("Leveling 40", db.selectedGearSet)
        end)

        it("refuses a blank name", function()
            assert.is_nil(GearSets.Create(db, "   "))
            assert.is_nil(GearSets.Create(db, nil))
            assert.are.same({}, GearSets.List(db))
        end)

        it("gives a taken name the next free number", function()
            GearSets.Create(db, "Leveling 40")
            assert.are.equal("Leveling 40 (2)", GearSets.Create(db, "Leveling 40"))
            assert.are.equal("Leveling 40 (3)", GearSets.Create(db, "Leveling 40"))
        end)

        it("numbers from the base name when a numbered name is taken", function()
            GearSets.Create(db, "Holy")
            GearSets.Create(db, "Holy (2)")
            assert.are.equal("Holy (3)", GearSets.Create(db, "Holy (2)"))
        end)

        it("strips color codes and caps the length", function()
            assert.are.equal("Bad name", GearSets.Create(db, "Bad| name"))
            local long = GearSets.Create(db, string.rep("a", 60))
            assert.are.equal(40, #long)
        end)
    end)

    describe("Rename", function()
        it("renames and keeps the selection on the renamed set", function()
            GearSets.Create(db, "Old")
            db.gearSets.Old.items.head = 123
            assert.are.equal("New", GearSets.Rename(db, "Old", "New"))
            assert.is_nil(db.gearSets.Old)
            assert.are.equal(123, db.gearSets.New.items.head)
            assert.are.equal("New", db.selectedGearSet)
        end)

        it("keeps the same name when renamed to itself", function()
            GearSets.Create(db, "Holy")
            assert.are.equal("Holy", GearSets.Rename(db, "Holy", "Holy"))
        end)

        it("numbers a name that clashes with another set", function()
            GearSets.Create(db, "Holy")
            GearSets.Create(db, "Shadow")
            assert.are.equal("Holy (2)", GearSets.Rename(db, "Shadow", "Holy"))
        end)
    end)

    describe("Delete and Selected", function()
        it("selects the next set after deleting the selected one", function()
            GearSets.Create(db, "A")
            GearSets.Create(db, "B")
            GearSets.Create(db, "C")
            GearSets.Select(db, "B")
            GearSets.Delete(db, "B")
            assert.are.equal("C", db.selectedGearSet)
            GearSets.Delete(db, "C")
            assert.are.equal("A", db.selectedGearSet)
            GearSets.Delete(db, "A")
            assert.is_nil(GearSets.Selected(db))
        end)

        it("falls back to the first set when the saved selection is gone", function()
            db.gearSets = { Zed = { items = {} }, alpha = { items = {} } }
            db.selectedGearSet = "Missing"
            assert.are.equal("alpha", GearSets.Selected(db))
        end)
    end)

    it("counts chosen items", function()
        assert.are.equal(0, GearSets.ItemCount({ items = {} }))
        assert.are.equal(2, GearSets.ItemCount({ items = { head = 1, neck = 2 } }))
    end)
end)
