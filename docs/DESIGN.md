# Gear Path — Addon Design Doc

Nov 18, 2026 · Living version: https://claude.ai/artifact/YQvEZAg2UUxXHiFUn5xPT3

## Summary and goals

Gear Path is an in-game addon for World of Warcraft: Forever. You pick your own gear set, and it tells you where every piece comes from. For quest rewards, it walks the whole quest chain and checks off the steps you've finished.

Goals for v1:

- **Your sets, not a ranked list.** Each character can keep several Gear Sets with one item per Slot. You choose every item, and the addon never decides for you.
- **One place for where it comes from.** Every item shows its Source: quest, boss drop or vendor in v1.
- **Full quest chains with progress.** A quest reward shows every Step from the start, in order, with finished Steps checked. Breadcrumbs and Alternatives are shown, too.
- **A clear status for every item.** Each item reads Owned, Previously Owned, Missed or Locked. You decide what to go after.

Out of scope for v1: a ranked Next Steps list (Phase 2), crafted, reputation and PvP Sources, automatic gear ranking or stat weights, auction house pricing, and retail WoW.

## Prior art

No current addon combines a custom gear set with quest-chain tracking. GearedForever comes closest, but it picks the gear for you.

| Addon | Custom set / wishlist | Item sources | Full quest chain | Tracks completed quests |
| --- | --- | --- | --- | --- |
| [GearedForever](https://www.curseforge.com/wow/addons/gearedforever) | No (ranked lists) | Yes | Yes | Yes, marks next quest |
| [Lootwise](https://www.curseforge.com/projects/1747991) | Yes, multiple shareable lists | Yes | No | No |
| [AtlasLoot Classic Forever](https://www.curseforge.com/wow/addons/atlasloot-forever) | BiS lists, favorites | Yes | No | No |
| [ForeverQuest](https://www.curseforge.com/wow/addons/foreverquest) | No | No | Quest log only | Map and tracker guidance |

The gap is the join: a set you build yourself, linked to quest chains that track your progress.

## Core features

1. **Set builder.** Each character can have several named Gear Sets, such as "Leveling 40" or "Pre-raid Holy". A set holds one item per Slot, and paired Slots (rings, trinkets, weapons) count separately. Fill a Slot by searching, browsing, or Shift-clicking an item link. Items the character can never get (wrong faction or class) are hidden.
2. **Set picker.** Switch between sets freely. No set is "active": the window shows whichever set you have selected.
3. **Source lookup.** Each item shows every way to get it. In v1 that means quest rewards, boss and object drops, and vendors, all from QuestieDB. Other Sources show as "Source not yet known."
4. **Quest chain view.** A quest reward opens its chain from the first Step. Breadcrumbs show as optional Steps. A Step that any one of several quests completes lists them as Alternatives. Each Step shows the quest giver, zone, level and any requirement.
5. **Item status.** Every item reads Owned (equipped, bags or bank), Previously Owned, Missed, or Locked with the reason. The set header counts Slots owned.
6. **Share Strings.** Export a set as a string holding its name, its items per Slot and a format version. Importing never overwrites: a clashing name gets the next free number. Items the character can't use are dropped, with a message naming each one and why.
7. **Map pins.** Pin a quest giver, vendor or dungeon entrance on the world map.
8. **Tooltip line.** Hovering an item lists every set on this character that holds it.

## User flows

**Build a set**

1. Type `/gearpath` or click the minimap button, then choose New set.
2. Click a slot, then search or browse items for it, filtered to your class and faction.
3. Pick an item. Its source and quest chain appear right away.
4. Repeat for each slot you care about. Empty slots are fine.

**Share a set**

1. Open the set and choose Export. Copy the Share String.
2. On another character, or another player's, choose Import and paste it.
3. The set appears under its own name, or with "(2)", "(3)" and so on if that name is taken.
4. Any item that character can never get is left out, with a message such as "Item X wasn't added: it's Horde only and you're Alliance."

**Follow a quest chain**

1. Click a quest-reward item to open its chain.
2. Steps you've finished are checked, and the next one is marked.
3. Click a step to see its objective and quest giver, or pin it on the map.
4. When you turn in a step, the chain updates. When you loot the item, the slot shows as owned.

## UI layout

One window holds everything: the set picker across the top, the slot list on the left, the selected item's Source and chain on the right, and Share String export and import along the bottom.

```
+---------------------------------------------------------------+
| Set: Pre-raid Holy   switch set / new set  6 of 17 slots owned |
+---------------------------+-----------------------------------+
| SLOTS                     | Chest: quest reward               |
| Head          Owned       | Source: quest chain, 4 steps      |
| Neck          Vendor      |  (x) 1. First quest      Done     |
| Shoulder      Missed      |  (x) 2. Second quest     Done     |
| > Chest  Quest: step 2/4  |  ( ) 3. Third quest      Next     |
| Waist  Previously owned   |  ( ) 4. Reward quest     Locked   |
| Legs   Locked: level 42   |  [Pin on map] [Show objective]    |
| Main hand     Owned       |                                   |
| + 10 more slots           |                                   |
+---------------------------+-----------------------------------+
| Share: Export this set as a Share String, or import one       |
+---------------------------------------------------------------+
```

Chain Steps show as done (green), current (accent), or locked (empty, with the reason). Breadcrumbs appear as optional, greyed-out Steps. Other Source types reuse the right panel: a drop shows the boss and instance, and a vendor shows the NPC, the price and a map pin.

## Data model and sources

Gear Path ships no game data of its own in v1. It reads quests, items, NPCs and vendors from [QuestieDB](https://github.com/Questie/QuestieDB) at runtime (see [ADR 0001](adr/0001-read-questiedb-at-runtime.md)), and saves only what the player creates.

| What | Where it comes from | Holds |
| --- | --- | --- |
| Quests | QuestieDB | name, level, races and classes allowed, giver, prerequisites (all of, any one of), next quest, breadcrumbs, mutually exclusive quests, reputation and skill requirements |
| Items (Sources) | QuestieDB | quests that reward it, NPCs and objects that drop it, vendors that sell it, item level, required level |
| Slot and class limits | Game client | equipment slot, armor or weapon type, class restrictions |
| Quest completion | Game client | read live, never saved |
| Gear Sets | Saved per character | set name, item per Slot |
| Owned history | Saved per character | every item ID the character has ever Owned, for Previously Owned |
| Bank contents | Saved per character | item IDs seen at the last bank visit |

Quest Chains are assembled when a chain is opened, by walking prerequisites back from the reward quest. Room is reserved for a Gear Path data addon later: it would add crafted, reputation and PvP Sources, and register corrections into QuestieDB through its Registrar.

## Technical constraints

The biggest risk is the data, not the code. Forever content is still being discovered.

- **Client version.** WoW Forever addons target Interface 16001 with a max level of 60 ([GearQuest Forever](https://www.curseforge.com/wow/addons/gearquest-forever)).
- **QuestieDB dependency.** Gear Path lists QuestieDB as a required dependency and reads it through `LibQuestieDB`. Its numeric getters return 0 instead of nil, and every table read returns a fresh copy. QuestieDB is GPLv3 with some unsettled historic contributions, which is why we read it rather than copy it.
- **Quest completion.** The Forever client exposes `C_QuestLog.IsQuestFlaggedCompleted(questID)` (confirmed in game on Nov 19, 2026). The client can't tell which quest reward a player picked, so Missed is inferred: chain done and item never Owned.
- **Refresh triggers.** Re-check chains on `QUEST_TURNED_IN`, `QUEST_ACCEPTED` and login. Re-check Owned items on `BAG_UPDATE`, `PLAYER_EQUIPMENT_CHANGED` and `BANKFRAME_OPENED`.
- **Incomplete data.** QuestieDB's Forever data is still being filled in. The UI must show "Source not yet known" cleanly.
- **Performance.** Build nothing at login. Look up data when the window opens or a chain is clicked.

## Scope phases and open questions

- **Phase 1 (v1):** set builder and set picker, quest, drop and vendor Sources from QuestieDB, quest chains with Breadcrumbs and Alternatives, item status (Owned, Previously Owned, Missed, Locked), Share Strings, map pins, tooltip line.
- **Phase 2:** Gear Path data addon for crafted, reputation and PvP Sources plus QuestieDB corrections. Possibly a ranked Next Steps list, if it still seems useful.
- **Phase 3:** imports from AtlasLoot or Lootwise, a companion page on the WoW tools hub, and a look at Classic and retail.

The design review on Nov 18 settled the earlier open questions: the name is Gear Path (`/gearpath`), QuestieDB is the data source, items for the other faction or class are hidden, and sets stay per character. Terms are defined in the project glossary ([CONTEXT.md](../CONTEXT.md)).

Still open:

- [x] Confirm the Forever client's quest-completion API before building on it. Settled Nov 19: `C_QuestLog.IsQuestFlaggedCompleted` works on the Forever client.
- [ ] Decide whether Next Steps returns in Phase 2.
