# Gear Path

An addon for World of Warcraft: Forever that lets a player pick a gear set, shows where each item comes from, and tracks progress through the quest chains that award them.

## Language

### Gear sets

**Gear Set**:
A player-chosen collection of items with at most one Item per Slot.
_Avoid_: Wishlist, BiS list, loadout, plan

**Selected Gear Set**:
The Gear Set the player is currently viewing. A character can have many Gear Sets, and none of them is special; Next Steps and Quest Chain progress are shown for whichever set is selected.
_Avoid_: Active set, current set, main set

**Slot**:
An equipment position on a character (Head, Neck, Finger 1, Trinket 2, and so on). Paired positions count as separate Slots.
_Avoid_: Gear slot, equipment slot

**Owned**:
An Item is Owned when it is anywhere in the character's inventory: equipped, in bags, or in the bank.
_Avoid_: Collected, obtained, have

**Previously Owned**:
An Item the character Owned at some point but no longer does, for example after selling or deleting it. Takes precedence over Missed.
_Avoid_: Sold, lost, formerly owned

**Missed**:
A Quest Reward Item the character can no longer get: either its Quest Chain is finished without the Item being Owned (a different reward was chosen), or a mutually exclusive quest has blocked the path to it.
_Avoid_: Failed, lost, unavailable

**Unobtainable**:
An Item this character can never get at any point, because of its faction or class. Unobtainable Items are never shown and can't be added to a Gear Set.
_Avoid_: Unavailable, restricted, hidden

**Locked**:
An Item the character can't get yet but will be able to later, for example because of level or reputation.
_Avoid_: Unavailable, gated

**Share String**:
A text string that encodes a Gear Set's name, its Item per Slot, and a format version, so it can be copied, pasted, and imported by another player or character. An imported name that already exists on the character gets the next free number, such as "(2)" or "(3)". Gear Sets belong to one character, so a Share String is the only way to move a set between characters.
_Avoid_: Export code, import string

### Sources and quests

**Source**:
One way an Item can be obtained: a quest reward, a boss drop, a vendor, a recipe, a reputation reward, a PvP reward, or a world drop.
_Avoid_: Origin, drop location

**Quest Chain**:
The ordered set of quests a character must complete to reach the quest that awards an Item.
_Avoid_: Questline, quest path

**Step**:
One position in a Quest Chain. Usually a single quest, but it can hold Alternatives.
_Avoid_: Stage, link

**Next Step**:
Something the character can do right now that progresses the Selected Gear Set: a quest to pick up or turn in, a dungeon to run, or a vendor to visit. Next Steps are ranked by how many Items they progress, then by lowest level.
_Avoid_: To-do, task, objective

**Alternative**:
One of several quests within a Step where finishing any one of them completes the Step.
_Avoid_: Option, branch

**Breadcrumb**:
An optional quest that leads the character to the start of a Quest Chain. It can be skipped.
_Avoid_: Lead-in, intro quest
