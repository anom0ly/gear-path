-- The 17 Slots in display order. Paired positions count as separate Slots.
-- inventorySlot is the game's inventory slot ID, used later for Owned checks.
local _, ns = ...

ns.Slots = {
    { id = "head",     label = "Head",      inventorySlot = 1 },
    { id = "neck",     label = "Neck",      inventorySlot = 2 },
    { id = "shoulder", label = "Shoulder",  inventorySlot = 3 },
    { id = "back",     label = "Back",      inventorySlot = 15 },
    { id = "chest",    label = "Chest",     inventorySlot = 5 },
    { id = "wrist",    label = "Wrist",     inventorySlot = 9 },
    { id = "hands",    label = "Hands",     inventorySlot = 10 },
    { id = "waist",    label = "Waist",     inventorySlot = 6 },
    { id = "legs",     label = "Legs",      inventorySlot = 7 },
    { id = "feet",     label = "Feet",      inventorySlot = 8 },
    { id = "finger1",  label = "Finger 1",  inventorySlot = 11 },
    { id = "finger2",  label = "Finger 2",  inventorySlot = 12 },
    { id = "trinket1", label = "Trinket 1", inventorySlot = 13 },
    { id = "trinket2", label = "Trinket 2", inventorySlot = 14 },
    { id = "mainhand", label = "Main Hand", inventorySlot = 16 },
    { id = "offhand",  label = "Off Hand",  inventorySlot = 17 },
    { id = "ranged",   label = "Ranged",    inventorySlot = 18 },
}
