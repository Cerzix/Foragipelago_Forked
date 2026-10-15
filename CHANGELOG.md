# Changelog

## v0.3.0-alpha (fork)

**Update both the apworld and the mod**, and create a new seed with the new `Forager.yaml`.

### New
- **Filler items**, dropped at your feet one at a time:
  - Coin bags (small, medium, large), scaling with your level
  - Resource bundles: wood, stone, coal, ore, fiber, sand
  - Food Basket and Feast
  - Gem Pouch and Legendary Gem
  - Seed Pack
  - Random Potion and Healing Potions
  - Bug Jar and Bottled Fairy
  - Fish Bucket
  - 60 second buffs: Speed Boost, Regeneration, Boundless Energy (energy can't go down)
- **Traps**: Energy Drain (energy to 0), Slowness (half speed for 30 seconds), Taxes (lose 25% of your coins).
- **Trap Link**: traps you receive are sent to the other Trap Link players, and you get theirs when Forager has something similar (slow, freeze, stun, exhaustion, tax, money traps...).
- New options:
  - `filler_slots` (default 10): how many locations hold filler and traps. There are more tools and skills than locations, so each slot leaves out a skill that isn't needed to win. Set it to 0 to keep every possible skill.
  - `trap_percentage` (default 20): how many of the filler items are traps.
  - `trap_link` (default off).
- The mock `Server.py` can send filler (`filler <name>`, `filler all`) and Trap Link traps (`traplink <name>`).

### Needs in-game testing
- Coins are dropped as coin items and taxes count your coins with the item count. Check that coin bags give money and that taxes take some.
- Speed effects change the player's max speed and acceleration, like other Forager speed potion mods.

## v0.2.2-alpha (fork)

Based on the 0.1.2 mod and the unreleased 0.2 apworld from the author's [Archipelago fork](https://github.com/olixx12/Archipelago/tree/forager/worlds/forager).
The apworld source is now in this repo (`apworld/forager`).

**Update both the apworld and the mod.** They changed together and older versions won't work with this release. Create a new seed with the new `Forager.yaml`.

### New
- **DeathLink**: enable `death_link` in your yaml. When you die, everyone with DeathLink dies, and the other way around. Incoming deaths are checked every ~5 seconds.

### Apworld
- **Every progressive tool tier is now always in the item pool** (fixes [#3](https://github.com/olixx12/Foragipelago/issues/3)).
  Before, only Progression items got their full count and every other slot was a random pick, so Backpacks (0.1.1), Bows, Amulets, Gloves, Boots, Rods and the Hammer could be missing or show up too often.
  The pool is now: every progression item, then every other tool tier, then each remaining skill once in a random order, then filler.
  - There are more items than locations, so some non-progression skills are always left out (9 at level 65, more at lower goal levels).
  - At goal levels 40 and 41 there aren't even enough locations for every tool tier, so 2 (level 40) or 1 (level 41) random non-progression tool tiers are left out.
- No more duplicate skills in the pool.
- Filler items are always "Nothing!" now, instead of random tools or skills (item links, plando).
- The client no longer logs an error every time the goal is sent.
- Added the `archipelago.json` manifest. Without it, Archipelago 0.6 logs an error, and Archipelago 0.7 won't load the apworld at all.
- Added tests for the item pool and DeathLink.

### Mod
- **Obliterator check can now be completed.** The Factory was never set up, so the check could never be sent.
- **Checks are no longer lost when the client is closed or disconnected.** The mod saves every check it sends and resends them about once a minute. Missed level checks on existing saves are recovered too.
- **Rods work again.** The apworld has no rod checks, but the Spirit Crystal still turned rods into Archipelago items, so crafting one gave you nothing. It crafts rods normally now. Progressive rods are still received from Archipelago.
- Fixed a crash when loading a save once every tier of a tool was crafted (same kind of "out of bounds" error as #1 and #2).
- Goal level and crafting progress are refreshed regularly, so starting Forager before the client is connected no longer leaves you with the default goal or resets the crafting stations.
- Tool deliveries no longer get stuck forever if a dropped tool is left behind (for example in a dungeon). It's dropped again when you change room or reload.
- Skills, tools and level progress no longer carry over when switching to another save or a new world.
- Incomplete or failed responses from the client are ignored instead of being read as data.
- Smaller fixes: uninitialized loop counters, rods using the wrong item for their "unlocked" state, a duplicated shovel entry.

### Tools
- `Server.py` is now a mock of the Forager Client, to test the mod without Archipelago. Run `python Server.py` instead of the client and type `help`. It can send gear, skills and DeathLinks, and shows the checks and deaths the mod sends.
- `python build_release.py` builds `dist/forager.apworld`, `dist/Foragipelago.zip` and `dist/Forager.yaml`.

### Needs in-game testing
- Getting killed by DeathLink: the mod sets your health to 0 and relies on the game's own death check.
- Crafting the Obliterator and receiving its check.
