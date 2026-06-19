#define Main
    Trace("Loading Foragipelago...")
    global.URL = "http://127.0.0.1:8000/"
    CommandCreate("test_post", 0, ScriptWrap(test_post))
    CommandCreate("test_get", 0, ScriptWrap(test_get))
    CommandCreate("test_gear", 0, ScriptWrap(test_gear_get),"name")
    CommandCreate("skill_tests", 0, ScriptWrap(skill_test), "index")
    CommandCreate("test",0,ScriptWrap(random_texst))
    CommandCreate("apitem", 0, ScriptWrap(apitem_test))
    Trace("Loading Forager Items...")
    load_items();
    Trace("Creating Checks...")
    create_APItems();
    Trace("Creating Archipelago Items...")
    create_items();
	apitem_test()
    global.Level = 1;
    global.pendingSkillPoints = 0;
    global.estimatedskills = 0;
    global.get_interval = 45;
    global.get = 0;
    global.goaled = 0
    global.playerGear = []
    for(var i = 0; i < 41; i++){
    	global.playerGear[i] = 0;
    }
    Trace("Loaded Foragipelago!")
    if(room = rmGame){
    	Trace("WARNING: Do not recompile during a save")
    	Trace("Always leave the save then join back in")
    }
#define NoUse //Used for AP items

#define test_post() //Old test function, fairly useless now
    Trace("Testing Connection")
    Trace(objPlayer.gearCurrent)
    http_post_string("http://127.0.0.1:8000/gear", string(objPlayer.gearCurrent))
    
#define test_get() //Old test function, the code already periodically sends a GET request
    Trace("Testing get")
    
    send_get_items();

#define random_texst() //Old function to try and find where certain piece of data were located
    Trace(typeof(objPlayer.gearCurrent))
    Trace(objMuseumBundle.completed)

#define test_gear_get(arr) //Simulate having been sent a progressive check, test function.
	var name = arr[0]
    var tier = ds_map_find_value(global.f_Gear,name) + 1
    ds_map_set(global.f_Gear,name,tier)

#define apitem_test //Initialize structures with tier 1 of each craftable gear
	//Test function that has been integrated into the main code
	//TODO: What if the player joins during the middle of a sync ? Fix that
	global.stationItems = ds_map_create()
	global.stations = ds_map_create()
	ds_map_set(global.stations,"forge",Structure.Forge)
	ds_map_set(global.stations,"sewing",Structure.SewingStation)
	ds_map_set(global.stations,"inscription", Structure.InscriptionTable)
	ds_map_set(global.stations,"spirit",Structure.SpiritCrystal)
	var forgeItems = array_clone(StructureGet(Structure.Forge, StructureData.Items));
	ds_map_set(global.stationItems, "forge", forgeItems);
	var sewingItems = array_clone(StructureGet(Structure.SewingStation, StructureData.Items));
	ds_map_set(global.stationItems, "sewing", sewingItems);
	var inscriptionItems = array_clone(StructureGet(Structure.InscriptionTable, StructureData.Items));
	ds_map_set(global.stationItems, "inscription", inscriptionItems);
	var spiritItems = array_clone(StructureGet(Structure.SpiritCrystal, StructureData.Items));
	ds_map_set(global.stationItems, "spirit", spiritItems);
	var factoryItems = array_clone(StructureGet(Structure.Factory, StructureData.Items));
	ds_map_set(global.stationItems, "factory", factoryItems);
    for(var i = 0; i < array_length(global.AP_Gear_Name); i++){
    	var name = global.AP_Gear_Name[i]
    	var gear = ds_map_find_value(global.AP_Items, name)
    	var station = ds_map_find_value(global.AP_Gear_Station, name)
		var station_map = ds_map_find_value(global.AP_Gear_Index, station)
		var index = ds_map_find_value(station_map, name)
		var stationItems = ds_map_find_value(global.stationItems, station)
		stationItems[index] = gear[0]
		ds_map_set(global.stationItems,station,stationItems)
    }
    var stations = ds_map_keys(global.stations)
    for(var i = 0; i < array_length(stations); i++){
    	var station = ds_map_find_value(global.stations,stations[i])
    	var station_items = ds_map_find_value(global.stationItems,stations[i])
    	StructureEdit(station,StructureData.GearCategories,undefined);
    	StructureEdit(station, StructureData.Items,station_items)
    }
    
    
#define string_split(str, delimiter) //Because this api doesn't have access to something like that
	//I'm not sure if it's used rn
    ary = []
    num = ""
    index = 0
    for (var i = 0; i < string_length(str); i++){
        if string_char_at(str,i) != delimiter{
            if string_char_at(str,i) != "[" and string_char_at(str,i) != "]" {
                num += string_char_at(str,i)
            }
                
        }else{
            ary[index] = real(num)
            num = ""
            index++
        }
    }
    ary[index] = real(num)
    return ary
    
#define skill_test(arr) //Test function to simulate having been sent skills, fairly outdated
	var index = arr[0]
	for(var i = 0; i < 64; i++){
		if(i == index){
			global.f_skills[i] = 1
		}
	}
    
#define OnItemGet(item,quantity)
	for(var k = 0; k < array_length(global.AP_Gear_Name); k++){
		var name = global.AP_Gear_Name[k]
		var gear = ds_map_find_value(global.AP_Items, name)
		var tier = ds_map_find_value(global.AP_Gear_Tiers,global.AP_Gear_Name[k])
		for(var i = 0; i < tier; i++) {
			if(item == gear[i]){ //The item corresponds to an AP gear item
				var id = ds_map_find_value(global.AP_Gear_IDs, name) + i
				send_check(id) //Check will be missed forever if client fails to catch it
				if(i < tier - 1){ //There's other crafts behind this one, set the next one
				 	var station = ds_map_find_value(global.AP_Gear_Station, name)
				 	var station_map = ds_map_find_value(global.AP_Gear_Index, station)
				 	var index = ds_map_find_value(station_map, name)
				 	var stationItems = ds_map_find_value(global.stationItems, station)
					stationItems[index] = gear[i+1]
					ds_map_set(global.stationItems,station,stationItems)
					StructureEdit(global.stations[? station], StructureData.Items,stationItems)
				}
				RemoveItem(item,quantity)
			}
		}
	}

#define OnStep //Avoid using unless necessary, could cause performance issues
	if(room == rmSkillGrid) {//Skill menu
		handleSkill()
	}
#define OnSystemStep //API function called periodically
	//Anything to check constantly but not every frame should be here
	if(room == rmGame){
		objPlayer.skills += global.pendingSkillPoints; //Give the player skill points earned from skills items, to buy them
		global.pendingSkillPoints = 0;
		if(objPlayer.level > global.Level){ //The player leveled up in some way.
			global.Level++
			var id = 300 + global.Level
			objPlayer.skills = objPlayer.skills - 1
			send_check(id); //Missed check if client is disconnected
		}
		global.estimatedskills = objPlayer.skills
		if(objPlayer.level >= 65 && global.goaled == 0){
			//TODO, be careful when other goals are added.
			//Only do that when no other goals are added
			send_goal();
			global.goaled = 1;
		}
		
		handleSkill()
	    //Handle gear
	    //TODO : There's a function in Items that was supposed to do that, do that over there.
	    for(var i = 0; i < array_length(global.AP_Gear_Name);i++){
	    	var name = global.AP_Gear_Name[i]
	    	if(is_undefined(global.playerGearMap) || is_undefined(name)){
	    		Trace("Something is wrong : gearMap")
	    		return
	    	}
	    	if(ds_map_exists(global.playerGearMap,name)){
	    		var tier = ds_map_find_value(global.f_Gear,name)
	    		var item = ds_map_find_value(global.playerGearMap,name)[tier]
	    		if(!is_undefined(item)){
	    			if(i > array_length(global.playerGear)){
	    				Trace("Something is wrong : playerGear")
	    			}
	    			var index = global.Toolbar_IDs[i]
	    			var current_tier = global.playerGear[index];
	    			if(tier > current_tier){
	    				global.playerGear[index] = tier;
	    				DropItem(objPlayer.x,objPlayer.y,item,1)
	    			}
	    		}
	    	}
	    }
	    ToolbarRefresh(true)
	    
	    if(global.get >= global.get_interval){
	    	send_get_items(); //GET request for any items
	    	global.get = 0;
	    }
	    global.get++;
	}
#define handleSkill()
	global.skills = variable_global_get("skillUnlocked")
    if (global.estimatedskills == 0){ //No Skill Points, show everything
		for (var i = 0; i < 64; i++){
		    if(global.skills[i] != 2){ //Don't change bought skills status
		        global.skills[i] = 1
		    }
	    }
	}
	else{ //Skill points, only show skills that are meant to be bought
		for (var i = 0; i < 64; i++){
	    	if(global.skills[i] != 2){ //And don't hide already bought skills obviously
	    		if(global.f_skills[i] == 1){
	    			global.skills[i] = 1;
	    		}
	    		else{
	    			global.skills[i] = -1;
	    		}
	    	}
		}
	}
	variable_global_set("skillUnlocked", global.skills)
	
