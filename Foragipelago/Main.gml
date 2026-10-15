#define Main
    Trace("Loading Foragipelago...")
    global.URL = "http://127.0.0.1:8000/"
    Trace("Loading Forager Items...")
    load_items();
    Trace("Creating Checks...")
    create_APItems();
    Trace("Creating Archipelago Items...")
    create_items();
    init_filler();
	apitem_test();
    global.Level = 1;
    global.pendingSkillPoints = 0;
    global.estimatedskills = 0; //Skill points of the player, used by handleSkill
    global.get_interval = 45; //Used to slow down when the mod send a GET request to the mod
    global.get = 0; //The game crashes less often due to that interval.
    global.resync = 0 //Counts GET requests, to resend checks and refetch the datapackage every few of them
    global.resync_interval = 4 //Roughly once a minute
    global.datapackageLoaded = false
    global.inSave = false //True while a save is being played, used to reset the save state on the main menu
    global.goaled = 0
    global.errorcounter = 0 //Undefined values for get requests
    global.playerGear = []
    global.gearCollected = true
    global.gearDropRoom = undefined //Room the last progressive gear was dropped in
    global.sentChecks = [] //Every location sent on this save, resent periodically in case the client missed it
    global.deathpoll = 0 //Counts system steps between DeathLink polls
    global.deathpoll_interval = 15 //Roughly every 5 seconds
    global.pendingDeath = undefined //Cause of a received DeathLink, applied when the player exists
    global.playerAlive = true
    global.deathlinkKill = false //The current death comes from DeathLink, so it isn't sent back
    global.goal = "level"
    global.GoalLevel = 65
    global.easierCraft = 0
    for(var i = 0; i < 41; i++){
    	global.playerGear[i] = 0;
    }
    Trace("Loaded Foragipelago!")
    Trace("Fetching Datapackage from the AP server, wait before playing.")
    send_get_datapackage()
    if(room = rmGame){
    	Trace("WARNING: Do not recompile during a save")
    	Trace("Always leave the save then join back in")
    }
#define NoUse //Used for AP items

#define reset_save_state //Reset everything that belongs to one save file, so it doesn't leak into the next one
	global.Level = 1
	global.pendingSkillPoints = 0
	global.goaled = 0
	global.gearCollected = true
	global.gearDropRoom = undefined
	global.sentChecks = []
	global.pendingDeath = undefined
	global.playerAlive = true
	global.deathlinkKill = false
	reset_filler_state()
	for(var i = 0; i < 41; i++){
		global.playerGear[i] = 0;
	}
	for(var j = 0; j < 64; j++){
		global.f_skills[j] = 0;
	}
	global.f_skill_count = 0

#define apitem_test //Initialize structures with the valid tier of each craftable gear
	//Test function that has been integrated into the main code

	global.stationItems = ds_map_create()
	global.stations = ds_map_create()
	global.craftTier = ds_map_create() //Tier of the AP item currently craftable for each gear
	ds_map_set(global.stations,"forge",Structure.Forge)
	ds_map_set(global.stations,"sewing",Structure.SewingStation)
	ds_map_set(global.stations,"inscription", Structure.InscriptionTable)
	ds_map_set(global.stations,"factory",Structure.Factory)
	var forgeItems = array_clone(StructureGet(Structure.Forge, StructureData.Items));
	ds_map_set(global.stationItems, "forge", forgeItems);
	var sewingItems = array_clone(StructureGet(Structure.SewingStation, StructureData.Items));
	ds_map_set(global.stationItems, "sewing", sewingItems);
	var inscriptionItems = array_clone(StructureGet(Structure.InscriptionTable, StructureData.Items));
	ds_map_set(global.stationItems, "inscription", inscriptionItems);
	var factoryItems = array_clone(StructureGet(Structure.Factory, StructureData.Items));
	ds_map_set(global.stationItems, "factory", factoryItems);
    for(var i = 0; i < array_length(global.AP_Gear_Name); i++){
    	var name = global.AP_Gear_Name[i]
    	var station = ds_map_find_value(global.AP_Gear_Station, name)
    	if(is_undefined(station)){ //No crafting location for this gear (rods)
    		continue
    	}
    	var gear = ds_map_find_value(global.AP_Items, name)
		var station_map = ds_map_find_value(global.AP_Gear_Index, station)
		var stationItems = ds_map_find_value(global.stationItems, station)
		var sources = ds_map_find_value(global.AP_Gear_Source, name)
		var index = find_station_index(stationItems, sources[0], ds_map_find_value(station_map, name))
		if(index < 0 || index >= array_length(stationItems)){
			Trace("Foragipelago : could not find " + name + " in the " + station + ", report this")
			ds_map_delete(global.AP_Gear_Station, name)
			continue
		}
		ds_map_set(station_map, name, index)
		stationItems[index] = gear[0]
		ds_map_set(global.stationItems,station,stationItems)
		ds_map_set(global.craftTier, name, 0)
    }
    var stations = ds_map_keys(global.stations)
    for(var i = 0; i < array_length(stations); i++){
    	var station = ds_map_find_value(global.stations,stations[i])
    	var station_items = ds_map_find_value(global.stationItems,stations[i])
    	if(stations[i] != "factory"){ //The factory only gets its obliterator swapped, the rest stays vanilla
    		StructureEdit(station,StructureData.GearCategories,undefined);
    	}
    	StructureEdit(station, StructureData.Items,station_items)
    }

#define find_station_index(items, vanillaItem, fallback) //Where the vanilla gear sits in a station, the hardcoded index is only a fallback
	for(var i = 0; i < array_length(items); i++){
		if(items[i] == vanillaItem){
			return i
		}
	}
	if(is_undefined(fallback)){
		return -1
	}
	return fallback

#define setCraftTier(name,tier) //Make the station craft the AP item of the given tier, never goes back to a lower tier
	var station = ds_map_find_value(global.AP_Gear_Station, name)
	if(is_undefined(station)){ //No crafting location for this gear (rods)
		return
	}
	var gear = ds_map_find_value(global.AP_Items, name)
	tier = clamp(tier, 0, array_length(gear) - 1) //Everything crafted, the last one stays
	var current_tier = ds_map_find_value(global.craftTier, name)
	if(!is_undefined(current_tier) && tier <= current_tier){
		return
	}
	ds_map_set(global.craftTier, name, tier)
	var station_map = ds_map_find_value(global.AP_Gear_Index, station)
	var index = ds_map_find_value(station_map, name)
	var stationItems = ds_map_find_value(global.stationItems, station)
	stationItems[index] = gear[tier]
	ds_map_set(global.stationItems,station,stationItems)
	StructureEdit(global.stations[? station], StructureData.Items,stationItems)

#define string_split(str, delimiter) //Splits a string of numbers into an array of reals, brackets and spaces are ignored
	var ary = []
	var num = ""
	for (var i = 1; i <= string_length(str); i++){ //GML strings start at 1
		var c = string_char_at(str,i)
		if(c == delimiter){
			if(num != ""){
				ary[array_length(ary)] = real(num)
			}
			num = ""
		}
		else if(c != "[" && c != "]" && c != " "){
			num += c
		}
	}
	if(num != ""){
		ary[array_length(ary)] = real(num)
	}
	return ary

#define skill_test(arr) //Test function to simulate having been sent skills, fairly outdated
	var index = arr[0]
	for(var i = 0; i < 64; i++){
		if(i == index){
			global.f_skills[i] = 1
		}
	}

#define OnItemGet(item,quantity)
	//Used to check when an item has been picked up, whether it's an AP item or a Tool.
	for(var k = 0; k < array_length(global.AP_Gear_Name); k++){
		var name = global.AP_Gear_Name[k]
		var gear = ds_map_find_value(global.AP_Items, name)
		var base_id = ds_map_find_value(global.AP_Gear_IDs, name)
		for(var i = 0; i < array_length(gear); i++) {
			if(item == gear[i]){ //The item corresponds to an AP gear item
				if(base_id >= 0){
					send_check(base_id + i) //Resent later if the client misses it
				}
				setCraftTier(name, i + 1) //Set the next craft, if there's one
				RemoveItem(item,quantity)
			}
		}
		//Check when a tool or an accessory is collected, to allow dropping the next one.
		var index = global.Toolbar_IDs[k]
	    var current_tier = global.playerGear[index];
	    var items = ds_map_find_value(global.playerGearMap, name)
	   	if(current_tier + 1 < array_length(items) && items[current_tier+1] == item){
	   		global.playerGear[index] = current_tier + 1
	   		global.gearCollected = true
	   	}
	}

#define OnStep //Avoid using unless necessary, could cause performance issues (called every frame)
	if(room == rmSkillGrid) {//Skill menu
		handleSkill()
	}
	else if(room == rmMainMenu && global.inSave){ //Left the save, the next one starts clean
		reset_save_state()
		global.inSave = false
	}
	//DeathLink : checked every frame, so a quick respawn isn't missed
	if(global.inSave && instance_exists(objPlayer)){
		if(objPlayer.hp <= 0 && global.playerAlive){
			global.playerAlive = false
			if(global.deathlinkKill){ //Killed by DeathLink, don't send it back
				global.deathlinkKill = false
			}
			else{
				send_death()
			}
		}
		else if(objPlayer.hp > 0){
			global.playerAlive = true
		}
		update_effects() //Buffs and traps that last a while
	}
#define OnSystemStep //API function called periodically
	//Anything to check constantly but not every frame should be here
	if(instance_exists(objPlayer)){
		if(!global.inSave){ //First step in a save that OnLoad didn't set up (new world)
			global.inSave = true
			global.Level = objPlayer.level
			global.resync = global.resync_interval - 1 //Resync on the next GET request
		}
		objPlayer.skills += global.pendingSkillPoints; //Give the player skill points earned from skills items, to buy them
		global.pendingSkillPoints = 0;
		if(objPlayer.level > global.Level){ //The player leveled up in some way.
			global.Level++
			var id = 300 + global.Level
			objPlayer.skills = objPlayer.skills - 1
			if(global.Level < global.GoalLevel || global.GoalLevel == -1){
				send_check(id); //Resent later if the client misses it
			}
		}
		global.estimatedskills = objPlayer.skills
		if(objPlayer.level >= global.GoalLevel && global.GoalLevel != -1 && global.goaled == 0){
			//Level goal achieved, only if it's the correct goal
			send_goal();
			global.goaled = 1;
		}

		handleSkill()
	    //Handle gear
	    //TODO : There's a function in Items that was supposed to do that, do that over there.
	    if(!global.gearCollected && room != global.gearDropRoom){
	    	//The last drop was left behind in another room (dungeon...), drop it again instead of blocking every future drop
	    	global.gearCollected = true
	    }
	    for(var i = 0; i < array_length(global.AP_Gear_Name);i++){
	    	var name = global.AP_Gear_Name[i]
	    	if(is_undefined(global.playerGearMap) || is_undefined(name)){
	    		Trace("Something is wrong : gearMap")
	    		return
	    	}
	    	if(ds_map_exists(global.playerGearMap,name)){
	    		var tier = ds_map_find_value(global.f_Gear,name)
	    		var index = global.Toolbar_IDs[i]
	    		var current_tier = global.playerGear[index];
	    		var items = ds_map_find_value(global.playerGearMap, name)
	    		tier = min(tier,array_length(items)-1)
	    		var item = items[min(current_tier+1,array_length(items)-1)]
	    		if(!is_undefined(item)){
	    			if(i > array_length(global.playerGear)){
	    				Trace("Something is wrong : playerGear")
	    			}
	    			if(tier > current_tier && global.gearCollected){
	    				//The goal is to drop them one at a time, to avoid bugs.
	    				DropItem(objPlayer.x,objPlayer.y,item,1)
	    				global.gearCollected = false
	    				global.gearDropRoom = room
	    			}
	    		}
	    	}
	    	//Handle Unlocked bools of AP Gear, continuously match them with the vanilla gear they copy
	    	var apGears = global.AP_Items[? name]
	    	var sources = global.AP_Gear_Source[? name]
	    	for(var k = 0; k < array_length(apGears);k++){
	    		var unlock = ItemGet(sources[k],ItemData.Unlocked)
	    		ItemEdit(apGears[k],ItemData.Unlocked,unlock)
	    	}
	    }
	    ToolbarRefresh(true)

	    if(global.get >= global.get_interval){
	    	send_get_items(); //GET request for any items
	    	global.resync++
	    	if(global.resync >= global.resync_interval){
	    		resync_checks() //Checks missed while the client was down
	    		send_get_datapackage() //In case the client wasn't connected to AP when it was first asked
	    		global.resync = 0
	    	}
	    	global.get = 0;
	    }
	    global.get++;

	    //DeathLink
	    if(!is_undefined(global.pendingDeath)){
	    	if(global.playerAlive && objPlayer.hp > 0){ //Already dead : nothing to do
	    		Trace("DeathLink : " + global.pendingDeath)
	    		global.deathlinkKill = true
	    		objPlayer.hp = 0
	    	}
	    	global.pendingDeath = undefined
	    }
	    update_filler() //Filler items and traps
	    if(global.deathpoll >= global.deathpoll_interval){
	    	send_deathpoll()
	    	global.deathpoll = 0
	    }
	    global.deathpoll++
	}

#define OnLoad() //When a save file is loaded
	reset_save_state()
	global.inSave = true
	global.Level = objPlayer.level
	global.resync = global.resync_interval - 1 //Resync on the next GET request
	var _map = ModSaveDataFetch()
	if(is_undefined(_map)){ //No Foragipelago data in this save
		return
	}
	//Loading gear
	for(var i = 0; i < array_length(global.AP_Gear_Name);i++){
	    var name = global.AP_Gear_Name[i]
	    if(is_undefined(name)){
	    	Trace("Something is wrong : loading")
	    	return
	    }
	    var index = global.Toolbar_IDs[i]
	    var tier = _map[? name]
	    if(!is_undefined(tier)){
	    	global.playerGear[index] = tier
	    }
	}
	//Loading skills
	for(var i = 0; i < 64; i++){
		var name = "skill" + string(i)
		var skill = _map[? name]
		if(!is_undefined(skill)){
			global.f_skills[i] = _map[? name]
		}
	}

	//Loading sent checks
	var checks = _map[? "checks"]
	if(is_string(checks)){
		global.sentChecks = string_split(checks, ",")
	}
	var fillerApplied = _map[? "fillerApplied"]
	if(!is_undefined(fillerApplied)){
		global.fillerApplied = fillerApplied
	}
	//gearCollected isn't loaded on purpose : a drop that wasn't picked up is dropped again,
	//instead of blocking every future drop if it got lost.

#define OnSave() //When a file is being saved, before mod chunks are saved.
	var _map = ds_map_create()
	for(var i = 0; i < array_length(global.AP_Gear_Name);i++){
	    var name = global.AP_Gear_Name[i]
	    if(is_undefined(name)){
	    	Trace("Something is wrong : save")
	    	return
	    }
	    var index = global.Toolbar_IDs[i]
	    var tier = global.playerGear[index]
	    _map[? name] = tier
	}

	for(var i = 0; i < 64; i++){
		var name = "skill" + string(i)
		var skill = global.f_skills[i];
		_map[? name] = skill
	}
	_map[? "gearCollected"] = global.gearCollected
	var checks = ""
	for(var i = 0; i < array_length(global.sentChecks); i++){
		if(i > 0){
			checks += ","
		}
		checks += string(global.sentChecks[i])
	}
	_map[? "checks"] = checks
	_map[? "fillerApplied"] = global.fillerApplied
	if(instance_exists(objPlayer)){
		restore_speed() //Never save the boosted or slowed speed, the effect is reapplied on the next frame
	}

	ModSaveDataSubmit(_map)
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
