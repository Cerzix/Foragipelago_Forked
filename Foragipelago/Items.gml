#define create_items //Create data structures to store items sent by AP.
    global.f_Gear = ds_map_create(); //Store recieved progressive Gear, and how many
    for(var i = 0; i < array_length(global.AP_Gear_Name); i++){
        ds_map_set(global.f_Gear,global.AP_Gear_Name[i],0);
    }
    global.f_skills = []; //Store recieved skills
    global.f_skill_count = 0 //Store how many skills were recieved.
    for(var i = 0; i < 64; i++){
        global.f_skills[i] = 0;
    }

#define load_items //Load the forager gear into a data structure, for use later.
    global.playerGearMap = ds_map_create();
    //Very scuffed, surely there's something better
    var pickaxes = []
    pickaxes[0] = Item.BasicPickaxe
    pickaxes[1] = Item.SlimePickaxe
    pickaxes[2] = Item.GoldenPickaxe
    pickaxes[3] = Item.SkullPickaxe
    pickaxes[4] = Item.CrystalPickaxe
    pickaxes[5] = Item.DemonPickaxe
    pickaxes[6] = Item.VoidPickaxe
    pickaxes[7] = Item.CosmicPickaxe
    pickaxes[8] = Item.NuclearPickaxe
    ds_map_set(global.playerGearMap, "pickaxe",pickaxes)
    var swords = []
    swords[0] = undefined
    swords[1] = Item.SlimeSword
    swords[2] = Item.GoldenSword
    swords[3] = Item.SkullSword
    swords[4] = Item.CrystalSword
    swords[5] = Item.DemonSword
    swords[6] = Item.VoidSword
    swords[7] = Item.CosmicSword
    swords[8] = Item.NuclearSword
    ds_map_set(global.playerGearMap, "sword",swords)
    var bows = []
    bows[0] = undefined
    bows[1] = Item.SlimeBow
    bows[2] = Item.GoldenBow
    bows[3] = Item.SkullBow
    bows[4] = Item.CrystalBow
    bows[5] = Item.DemonBow
    bows[6] = Item.VoidBow
    bows[7] = Item.CosmicBow
    bows[8] = Item.NuclearBow
    ds_map_set(global.playerGearMap, "bow",bows)
    var shovels = []
    shovels[0] = undefined
    shovels[1] = Item.BasicShovel
    shovels[2] = Item.WaterShovel
    shovels[3] = Item.NomadShovel
    shovels[4] = Item.RoyalShovel
    shovels[5] = Item.RoboticShovel
    ds_map_set(global.playerGearMap, "shovel",shovels)
    var amulets = []
    amulets[0] = undefined
    amulets[1] = Item.SlimeAmulet
    amulets[2] = Item.GoldenAmulet
    amulets[3] = Item.SkullAmulet
    amulets[4] = Item.CrystalAmulet
    amulets[5] = Item.DemonAmulet
    amulets[6] = Item.VoidAmulet
    amulets[7] = Item.CosmicAmulet
    amulets[8] = Item.NuclearAmulet
    ds_map_set(global.playerGearMap, "amulet",amulets)
    var gloves = []
    gloves[0] = undefined
    gloves[1] = Item.SlimeGloves
    gloves[2] = Item.GoldenGloves
    gloves[3] = Item.SkullGloves
    gloves[4] = Item.CrystalGloves
    gloves[5] = Item.DemonGloves
    gloves[6] = Item.VoidGloves
    gloves[7] = Item.CosmicGloves
    gloves[8] = Item.NuclearGloves
    ds_map_set(global.playerGearMap, "gloves",gloves)
    var boots = []
    boots[0] = undefined
    boots[1] = Item.SlimeBoots
    boots[2] = Item.GoldenBoots
    boots[3] = Item.SkullBoots
    boots[4] = Item.CrystalBoots
    boots[5] = Item.DemonBoots
    boots[6] = Item.VoidBoots
    boots[7] = Item.CosmicBoots
    boots[8] = Item.NuclearBoots
    ds_map_set(global.playerGearMap, "boots",boots)
    var wallet = []
    wallet[0] = Item.BasicWallet
    wallet[1] = Item.SlimeWallet
    wallet[2] = Item.GoldenWallet
    wallet[3] = Item.SkullWallet
    wallet[4] = Item.CrystalWallet
    wallet[5] = Item.DemonWallet
    wallet[6] = Item.VoidWallet
    wallet[7] = Item.CosmicWallet
    wallet[8] = Item.NuclearWallet
    ds_map_set(global.playerGearMap, "wallet",wallet)
    var book = []
    book[0] = undefined
    book[1] = Item.MoldyBook
    book[2] = Item.SlimyTome
    book[3] = Item.Necronomicon
    book[4] = Item.GlacialScriptures
    book[5] = Item.HellfireGlyphs
    book[6] = Item.VoidGuide
    book[7] = Item.MagnumOpus
    book[8] = Item.NuclearCodex
    ds_map_set(global.playerGearMap, "book",book)
    var hammer = [undefined,Item.Hammer]
    ds_map_set(global.playerGearMap, "hammer",hammer)
    var fishing = [undefined,Item.FishingRod]
    ds_map_set(global.playerGearMap, "fishing rod",fishing)
    var obliterator = [undefined,Item.Obliterator]
    ds_map_set(global.playerGearMap, "obliterator",obliterator)
    var backpack = []
    backpack[0] = Item.BasicBackpack
    backpack[1] = Item.SmallBackpack
    backpack[2] = Item.MediumBackpack
    backpack[3] = Item.BigBackpack
    backpack[4] = Item.HugeBackpack
    backpack[5] = Item.TycoonBackpack
    ds_map_set(global.playerGearMap, "backpack",backpack)
    var fire_rod = [undefined,Item.FireRod,Item.MeteorRod]
    ds_map_set(global.playerGearMap, "fire rod",fire_rod)
    var ice_rod = [undefined,Item.IceRod,Item.BlizzardRod]
    ds_map_set(global.playerGearMap, "ice rod",ice_rod)
    var thunder_rod = [undefined,Item.ThunderRod,Item.StormRod]
    ds_map_set(global.playerGearMap, "thunder rod",thunder_rod)
    var necro_rod = [undefined,Item.NecroRod,Item.DeathRod]
    ds_map_set(global.playerGearMap,"necro rod",necro_rod)

#define sync_items //Sync the player toolbar with received items