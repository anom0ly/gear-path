# Read quest and item data from QuestieDB at runtime

Gear Path declares QuestieDB as a required dependency and reads quests, items, NPCs and vendors from its public API (`LibQuestieDB`) while the game runs, instead of shipping its own copy of the data. QuestieDB is the main open source of WoW: Forever data, players already install it alongside Questie, and its updates reach us for free. Reading it at runtime also avoids its unsettled licensing: it is GPLv3 with an "all rights reserved" caveat for some historic contributions, so copying its data would bind our data package to that license.

## Consequences

- QuestieDB has no crafting recipes, reputation-vendor standing, PvP rank gear or equipment slots. Slot and class restrictions come from the game client. Other Source types show as "not yet known" until we ship our own data.
- Room is reserved for a separate Gear Path data addon. It would hold our corrections, registered through QuestieDB's Registrar, plus the Source types QuestieDB lacks. If QuestieDB ever stops being viable, that data addon becomes the replacement.

## Considered Options

- Generate and ship our own GPL-3.0 data addon from QuestieDB, the way Forever Solo does. Rejected for v1 because of the republishing burden and the license ambiguity.
- Depend on ForeverDB, a wrapper around QuestieDB. Rejected because it has a single maintainer and little adoption.
