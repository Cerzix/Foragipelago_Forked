# Foragipelago
A Forager mod for Archipelago. 
This mod adds [Forager](https://store.steampowered.com/app/751780/Forager/) to [Archipelago](https://archipelago.gg/) multi-world randomizers. 
The mod works on Steam and probably on GOG. 

## Installation

### Apworld & Multiworld Setup
1. Download the [forager.apworld](https://github.com/olixx12/Foragipelago/releases) from the releases page
2. Double click the [forager.apworld](https://github.com/olixx12/Foragipelago/releases) file or move it to Archipelago/custom_worlds/ (Requires Archipelago to be already downloaded)
3. Follow the [instructions](https://archipelago.gg/tutorial/Archipelago/setup_en), to install Archipelago and host a game

> This fork keeps the apworld source in `apworld/forager` (based on the 0.2 apworld, with every progressive tool tier now always in the item pool).
> Run `python build_release.py` to build `dist/forager.apworld`, `dist/Foragipelago.zip` and `dist/Forager.yaml`, and use them instead of the ones from the releases page.

### Steam (Workshop Install)
**Warning:** The Steam workshop automatically updates the mod when a new version is available. 
If you need an older version, then you will need to follow the manual installation instruction below.
1. Open the mod on the [Steam workshop for Forager](https://steamcommunity.com/sharedfiles/filedetails/?id=3760668082)
2. Click on subscribe to install the mod

### Manual Install
1. Download the [Foragipelago.zip](https://github.com/olixx12/Foragipelago/releases)
2. Open `%LOCALAPPDATA%\Forager\mods\` on Windows (Linux instructions below)
   > If the `mods` folder isn't there, start Forager and close it again
3. Move the .zip file to the location and unzip it 
   > Once unzipped, you can delete the .zip file
4. The mod is successfully installed!

### Playing Forager with the mod
1. Launch the Archipelago Launcher
2. Search for `Forager Client`. Then open and connect to it **BEFORE** starting Forager
3. Start Forager, click on `modding`, enable Foragipelago and click `Compile`
4. Then you can click on `Play` and create a new **classic** world
5. Once in the world, you can press `T` to open the chat and see if you're connected
6. You're done with the entire setup!

### Linux Instructions
The Linux version of Forager is outdated by default! To get the latest version you need to use proton, which is usually built into the Steam client. 
1. Rightclick the game -> Properties -> Compability
2. Enable `Force the use of a specific Steam Play compability tool` and choose Proton
   > I used 9.0-4 for testing, but other versions should also work
3. The game should now update to the current version 4.1.9

After updating your game, you can continue at the Steam Workshop or manual install.

The mods folder for Linux should be located at: `~/.steam/steam/steamapps/compatdata/751780/pfx/drive_c/users/steamuser/AppData/Local/Forager/mods/`

---

### Further Information
- You can not run 2 instances of the Forager Client on the same PC at once or it will break
- To transfer the save to another PC, you need to either transfer the save file (located at `%LOCALAPPDATA%\Forager\`)
  > If you are on the same steam account on another PC, then it can be done automatically with cloud save from Steam
- If you have skill points, then a specific skill is buyable
- If you have no skill points, all skills are visible, helps with knowing what skill to hint for.
- Never, EVER, type /recompile while inside a save. Stuff will break.
- Checks done while the Forager Client is closed or disconnected are remembered in the save and resent about once a minute, so they aren't lost anymore.
- Rods (Fire, Thunder, Ice, Necro) have no crafting checks in the apworld, so the Spirit Crystal crafts them normally. Progressive rods are still received from Archipelago.
- DeathLink: enable `death_link` in your yaml. When you die in Forager, everyone with DeathLink dies, and the other way around. Deaths are checked every few seconds.
- Filler items (coin bags, resource bundles, food, gems, seed packs, potions, bugs, fish and 60 second buffs) and traps (Energy Drain, Slowness, Taxes) are dropped at your feet one by one. `filler_slots` sets how many locations get them, each one leaves out a skill that isn't needed to win. `trap_percentage` sets how many of them are traps, and `trap_link` shares your traps with other Trap Link players.
- If a received tool is dropped and left behind (for example in a dungeon), it is dropped again once you change room or reload the save.
- For any questions or issues, just write a message in the [Discord channel](https://discord.com/channels/731205301247803413/1196567161691443220) :)



---

### Current Goal & Randomization
Items:
- Skills
- Progressive Tools and Accessories

Checks: 
- Levels
- Crafting Tools and Accessories

Goals:
- Reach level 65

---

### Testing without Archipelago
`Server.py` is a mock of the Forager Client's local HTTP API (port 8000). Run `python Server.py` instead of the Forager Client, then start Forager.
Type `help` in its console to send gear and skills, change the goal level, and see the checks the mod sends.
`kill` sends a DeathLink to the game, and deaths in the game are printed in the console.
`filler <name>` sends a filler item or trap (`filler all` sends every one), `traplink <name>` sends a trap through Trap Link.
