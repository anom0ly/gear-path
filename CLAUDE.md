# Gear Path

WoW: Forever addon (Lua, Interface 16001). Read before working:

- `CONTEXT.md`: the glossary. Use its terms exactly in code, UI text and docs; avoid the words listed under _Avoid_.
- `docs/DESIGN.md`: what v1 does and does not do.
- `docs/adr/`: decisions already made. Don't reverse one without a new ADR.

Rules:

- Game data comes from QuestieDB at runtime through `LibQuestieDB` (ADR 0001). Don't copy QuestieDB data into this repo.
- Next Steps is out of scope for v1.
- Design before code: when a new feature or a change is described, mock it up first and get approval before writing code.
