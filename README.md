# Gear Path

A World of Warcraft: Forever addon. Build your own gear sets, see where every item comes from, and follow full quest chains with your progress tracked.

Status: building v1. Type `/gearpath` or click the minimap button to open the window.

## Development

- Unit tests: `busted` from the repo root (Lua 5.1).
- In game: the addon folder `GearPath` points at this repo; `/reload` after changes.

- [Design doc](docs/DESIGN.md)
- [Glossary](CONTEXT.md): the project's terms (Gear Set, Slot, Owned, Missed, Quest Chain…)
- [Decision records](docs/adr/)

Requires [QuestieDB](https://github.com/Questie/QuestieDB) (ships with the Forever Questie bundle).

## License

GPL-3.0. See [LICENSE](LICENSE).
