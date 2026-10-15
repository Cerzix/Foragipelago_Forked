
#define send_check(id) //Sends a POST to the server when a check is completed.
    var found = false
    for(var i = 0; i < array_length(global.sentChecks); i++){
        if(global.sentChecks[i] == id){
            found = true
            break
        }
    }
    if(!found){ //Remember it, so it can be resent if the client wasn't there to catch it
        global.sentChecks[array_length(global.sentChecks)] = id
    }
    var json = "{\"Locations\": [" + string(id) + "]}"
    http_post_string(global.URL + "Locations",json)

#define resync_checks //Resends every check of this save, the client ignores the ones the server already has
    var ids = ""
    for(var i = 0; i < array_length(global.sentChecks); i++){
        ids += string(global.sentChecks[i]) + ","
    }
    //Level checks can be rebuilt from the level, which also recovers ones missed before checks were remembered
    var last_level = global.Level
    if(global.GoalLevel != -1){
        last_level = min(last_level, global.GoalLevel - 1)
    }
    for(var l = 2; l <= last_level; l++){
        ids += string(300 + l) + ","
    }
    if(ids == ""){
        return
    }
    ids = string_copy(ids, 1, string_length(ids) - 1) //Remove the last comma
    http_post_string(global.URL + "Locations", "{\"Locations\": [" + ids + "]}")

#define send_get_items
    http_get(global.URL + "Items")

#define send_get_datapackage
    http_get(global.URL + "Datapackage")

#define get_items(str_json) //Grabs and updates the obtained items recieved by the server.
    if is_undefined(str_json){
        global.errorcounter = global.errorcounter + 1
        if(global.errorcounter > 5){
            Trace("A value seems to be constantly wrong, report this to Olixx")
            global.errorcounter = 0
        }
        return
    }
    global.errorcounter = 0
    if !is_string(str_json){
        Trace("Something's off with this value, report this to Olixx")
        Trace(str_json)
        return
    }
    variable_global_set("json",json_decode(str_json))
    global.json = variable_global_get("json","map")
    variable_global_set("gear", ds_map_find_value(global.json,"Gear"))
    var gear = variable_global_get("gear","map")
    if(is_undefined(gear)){
        Trace("Something is wrong : get_items")
        return;
    }
    for(var i = 0; i < array_length(global.AP_Gear_Name); i++){
        var name = global.AP_Gear_Name[i]
        if(ds_map_exists(gear,name)){
            var progressive_tier = ds_map_find_value(gear,name)
            var tier = ds_map_find_value(global.f_Gear,name)
            if(progressive_tier > tier){
                ds_map_set(global.f_Gear,name,progressive_tier)
            }
        }
    }
    variable_global_set("skills",ds_map_find_value(global.json,"Skills"))
    var skills = variable_global_get("skills","list")
    if(is_undefined(skills)){
        Trace("Something is wrong : get_items skills")
        return;
    }
    skills = ds_list_to_array(skills)
    for(var i = 0; i < min(64, array_length(skills)); i++){
        if(skills[i] == 1 && global.f_skills[i] == 0){
            global.f_skills[i] = skills[i]
            global.f_skill_count++
            global.pendingSkillPoints++
        }
    }

#define get_datapackage(str_json)
    if is_undefined(str_json) || !is_string(str_json){
        return
    }
    variable_global_set("json",json_decode(str_json))
    global.json = variable_global_get("json","map")
    variable_global_set("gear", ds_map_find_value(global.json,"Gear"))
    var gear = variable_global_get("gear","map")
    if(is_undefined(gear)){
        Trace("Something is wrong : get_datapackage")
        return;
    }
    for(var i = 0; i < array_length(global.AP_Gear_Name); i++){
        var name = global.AP_Gear_Name[i]
        if(ds_map_exists(gear,name)){
            var tier = ds_map_find_value(gear,name) //Amount of checks done, so the next one to craft
            setCraftTier(name,tier)
        }
    }

    var goal = ds_map_find_value(global.json, "Goal")
    if !is_undefined(goal){
        global.goal = goal
        if(global.goal != "level") {
            global.GoalLevel = -1
            Trace("something's wrong with the goal")
        }
        else{
            var goal_level = ds_map_find_value(global.json, "GoalLevel")
            if(!is_undefined(goal_level)){
                global.GoalLevel = goal_level
            }
        }
    }

    var easierCraft = ds_map_find_value(global.json, "EasierCraft")
    if (easierCraft == 1 && global.easierCraft == 0){
        global.easierCraft = 1
        ItemEdit(Item.Coal, ItemData.Blueprint, [Item.Wood,1])
        ItemEdit(Item.IronIngot, ItemData.Blueprint, [Item.IronOre,1,Item.Coal,1])
        ItemEdit(Item.GoldIngot, ItemData.Blueprint, [Item.GoldOre,1,Item.Coal,1])
        ItemEdit(Item.Glass, ItemData.Blueprint, [Item.Sand,1,Item.Coal,1])
    }

    if(!global.datapackageLoaded){
        global.datapackageLoaded = true
        Trace("Datapackage Loaded, enjoy your foragipelago experience")
    }

#define send_goal()
    http_post_string(global.URL + "Goal","test") //TODO : Maybe have an actual message

#define send_death() //The player died, the client sends it to the other DeathLink players if it's enabled
    http_post_string(global.URL + "Death","")

#define send_deathpoll
    http_get(global.URL + "Deathpoll")

#define get_deathpoll(str_json) //{"Death" : 1, "Cause" : "..."} when another DeathLink player died
    if is_undefined(str_json) || !is_string(str_json){
        return
    }
    variable_global_set("deathjson",json_decode(str_json))
    var death = variable_global_get("deathjson","map")
    if(is_undefined(death) || ds_map_find_value(death,"Death") != 1){
        return
    }
    var cause = ds_map_find_value(death,"Cause")
    if(!is_string(cause)){
        cause = ""
    }
    global.pendingDeath = cause //Applied on the next system step, when the player exists

#define OnHTTPAsync(async_load)
    var result = async_load[? "result"]
    var url = async_load[? "url"]
    var http_status = async_load[? "http_status"]
    var status = async_load[? "status"]
    if(status < 0 && url == "http://127.0.0.1:8000/Deathpoll"){ //Polled often, the Items request already warns about the connection
        return
    }
    if(status < 0){
        Trace("Connection with archipelago failed")
        Trace("Please connect to client before compiling the mod")
        Trace("If the client is connected, type /recompile or boot up the game again")
        Trace("status : " + string(status))
        global.get = -60 //Try to send another get command later, to not flood.
        return
    }
    if(status != 0){ //Still downloading, the full result comes with a later event
        return
    }
    var http_ok = is_undefined(http_status) || http_status == 200 //Error pages from the client aren't valid json

    switch (url)
    {
        case "http://127.0.0.1:8000/Items":
            if(http_ok){
                get_items(result)
            }
            break
        case "http://127.0.0.1:8000/Datapackage":
            if(http_ok){
                get_datapackage(result)
            }
            break
        case "http://127.0.0.1:8000/Deathpoll":
            if(http_ok){
                get_deathpoll(result)
            }
            break
        default:
            //Trace(url)
    }
