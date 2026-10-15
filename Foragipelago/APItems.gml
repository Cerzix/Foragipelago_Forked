#define create_APItems //Create every AP items to replace the unrandomized ones
    gearAP = GearCategoryCreate(undefined, "AP", false, false)
    global.AP_Logo = sprite_add("Resources\\Sprites\\logo.png", 1, false, false, 12, 12)
    global.AP_Gear_Name = ["pickaxe","shovel","sword","bow","ice rod","fire rod","thunder rod","amulet","boots","gloves","book","backpack","wallet","necro rod","obliterator","hammer","fishing rod"] 
    global.AP_Gear_IDs = ds_map_create();
    var AP_base_IDs = [202,211,221,231,-1,-1,-1,241,10,261,271,282,251,-1,301,299,300] //Base ids for the locations in ap, for each type of gear (-1 : no location, rods)
    global.Toolbar_IDs = [];
    for(var i = 0; i < 13; i++){
        global.Toolbar_IDs[i] = i;
    }
    global.Toolbar_IDs[13] = 34 //Necro rod
    global.Toolbar_IDs[14] = 35; //Obliterator
    global.Toolbar_IDs[15] = 39; //Hammer
    global.Toolbar_IDs[16] = 40; //Fishing rod
    global.AP_Items = ds_map_create();
    global.AP_Gear_Source = ds_map_create(); //Vanilla item each AP item copies its recipe and unlock state from
    global.AP_Gear_Tiers = ds_map_create();
    ds_map_set(global.AP_Gear_Tiers,"shovel",5)
    ds_map_set(global.AP_Gear_Tiers,"sword",8)
    ds_map_set(global.AP_Gear_Tiers,"bow",8)
    ds_map_set(global.AP_Gear_Tiers,"pickaxe",8)
    ds_map_set(global.AP_Gear_Tiers,"hammer",1)
    ds_map_set(global.AP_Gear_Tiers,"gloves",8)
    ds_map_set(global.AP_Gear_Tiers,"boots",8)
    ds_map_set(global.AP_Gear_Tiers,"wallet",8)
    ds_map_set(global.AP_Gear_Tiers,"backpack",5)
    ds_map_set(global.AP_Gear_Tiers,"book",8)
    ds_map_set(global.AP_Gear_Tiers,"amulet",8)
    ds_map_set(global.AP_Gear_Tiers,"ice rod",1)
    ds_map_set(global.AP_Gear_Tiers,"fire rod",1)
    ds_map_set(global.AP_Gear_Tiers,"thunder rod",1)
    ds_map_set(global.AP_Gear_Tiers, "necro rod",1)
    ds_map_set(global.AP_Gear_Tiers,"fishing rod",1)
    ds_map_set(global.AP_Gear_Tiers,"obliterator",1)
    for(var k = 0; k < array_length(global.AP_Gear_Name); k++){
        var AP_Gear = []
        var AP_Source = []
        var tier = ds_map_find_value(global.AP_Gear_Tiers,global.AP_Gear_Name[k])
        for (var i = 0; i < tier; i++){
            var craft_tier = i+1
            if((k >= 4 && k <= 6) || k == 13){
                craft_tier++ //Hacky way to handle rods, we want to craft the upgraded version
            }
            var item = global.playerGearMap[? global.AP_Gear_Name[k]][craft_tier]
            var data = Data.items[item]
            var AP_Item = ItemCreate(
            undefined, // Index
            "AP" + global.AP_Gear_Name[k] + string(i), // Name
            "Hope it's good!", // Description
            global.AP_Logo, // Sprite
            ItemType.Gear, // Item Type
            ItemSubType.None, // Sub Type
            0, // Sell Value
            0, // Healing Value
            0, // Energy Value
            data[6], // Crafting Materials
            ScriptWrap(NoUse), // On Use Effect
            60 * 1, // Frames To Craft
            true // Unlocked, this is changed later.
            )
            GearCategoryAddItems(gearAP, AP_Item)
            AP_Gear[i] = AP_Item
            AP_Source[i] = item
        }
        ds_map_set(global.AP_Gear_IDs, global.AP_Gear_Name[k], AP_base_IDs[k])
        ds_map_set(global.AP_Items, global.AP_Gear_Name[k], AP_Gear)
        ds_map_set(global.AP_Gear_Source, global.AP_Gear_Name[k], AP_Source)
    }
    global.AP_Gear_Index = ds_map_create();
    var AP_Forge_Index = ds_map_create();
    global.AP_Gear_Station = ds_map_create();
    ds_map_set(AP_Forge_Index,"shovel",3)
    ds_map_set(global.AP_Gear_Station,"shovel", "forge")
    ds_map_set(AP_Forge_Index,"hammer",4)
    ds_map_set(global.AP_Gear_Station,"hammer", "forge")
    ds_map_set(AP_Forge_Index,"fishing rod",5)
    ds_map_set(global.AP_Gear_Station,"fishing rod", "forge")
    ds_map_set(AP_Forge_Index,"pickaxe",6)
    ds_map_set(global.AP_Gear_Station,"pickaxe", "forge")
    ds_map_set(AP_Forge_Index,"sword",8)
    ds_map_set(global.AP_Gear_Station,"sword", "forge")
    ds_map_set(AP_Forge_Index,"bow",9)
    ds_map_set(global.AP_Gear_Station,"bow", "forge")
    ds_map_set(AP_Forge_Index,"amulet",10)
    ds_map_set(global.AP_Gear_Station,"amulet", "forge")
    ds_map_set(global.AP_Gear_Index, "forge", AP_Forge_Index)
    
    var AP_Sewing_Index = ds_map_create();
    ds_map_set(AP_Sewing_Index, "gloves", 3)
    ds_map_set(global.AP_Gear_Station, "gloves", "sewing")
    ds_map_set(AP_Sewing_Index, "boots", 4)
    ds_map_set(global.AP_Gear_Station, "boots", "sewing")
    ds_map_set(AP_Sewing_Index, "backpack", 5)
    ds_map_set(global.AP_Gear_Station, "backpack", "sewing")
    ds_map_set(AP_Sewing_Index, "wallet", 6)
    ds_map_set(global.AP_Gear_Station, "wallet", "sewing")
    ds_map_set(global.AP_Gear_Index, "sewing", AP_Sewing_Index)
    
    var AP_Inscription_Index = ds_map_create();
    ds_map_set(AP_Inscription_Index, "book", 1)
    ds_map_set(global.AP_Gear_Station, "book", "inscription")
    ds_map_set(global.AP_Gear_Index, "inscription", AP_Inscription_Index)
    
    //Rods have no crafting locations in the apworld (it skips Fire/Meteor/Thunder/Storm/Ice/Blizzard/Necro/Death Rod),
    //so they get no station entry and the Spirit Crystal stays vanilla. Progressive rods are still received and dropped.
    //Their old spirit crystal indexes were fire 4, thunder 5, ice 6, necro 7.

    var AP_Factory_Index = ds_map_create();
    ds_map_set(AP_Factory_Index, "obliterator",8)
    ds_map_set(global.AP_Gear_Station,"obliterator","factory")
    ds_map_set(global.AP_Gear_Index, "factory",AP_Factory_Index)
    
    global.AP_Chests = []  //Array of ap items for chest contents
    for(var k = 0; k < 46; k++){
        var AP_Item = ItemCreate(
            undefined, // Index
            "Chest #" + string(k), // Name
            "Hope it's good!", // Description
            global.AP_Logo, // Sprite
            ItemType.Gear, // Item Type
            ItemSubType.None, // Sub Type
            0, // Sell Value
            0, // Healing Value
            0, // Energy Value
            [], // Crafting Materials
            ScriptWrap(NoUse), // On Use Effect
            60 * 1, // Frames To Craft
            false // Unlocked, this is changed later.
        )
        global.AP_Chests[k] = AP_Item
    }
    
    