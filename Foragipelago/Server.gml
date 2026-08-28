
#define send_check(id) //Sends a POST to the server when a check is completed.
    var json = "{\"Locations\": [" + string(id) + "]}"
    http_post_string(global.URL + "Locations",json)

#define send_get_items
    http_get(global.URL + "Items")

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
        if(is_undefined(gear)){
            Trace("Something is very wrong : get_items")
            return;
        }
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
    skills = ds_list_to_array(skills)
    for(var i = 0; i < 64; i++){
        if(skills[i] == 1 && global.f_skills[i] == 0){
            global.f_skills[i] = skills[i]
            global.f_skill_count++
            global.pendingSkillPoints++
        }
    }
    
#define get_datapackage(str_json)
    Trace(str_json)
    if is_undefined(str_json){
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
        if(is_undefined(gear)){
            Trace("Something is very wrong : get_datapackage")
            return;
        }
        if(ds_map_exists(gear,name)){
            var tier = ds_map_find_value(gear,name)
            setCraftTier(name,tier)
        }
    }
    
    global.goal = ds_map_find_value(global.json, "Goal")
    if !is_undefined(global.goal){
        if(global.goal != "level") {
            global.GoalLevel = -1
            Trace("something's wrong with the goal")
        }
        else{
            global.GoalLevel = ds_map_find_value(global.json, "GoalLevel")
        }
    }
    
    var easierCraft = ds_map_find_value(global.json, "EasierCraft")
    if (easierCraft == 1){
        global.easierCraft = 1
        ItemEdit(Item.Coal, ItemData.Blueprint, [Item.Wood,1])
        ItemEdit(Item.IronIngot, ItemData.Blueprint, [Item.IronOre,1,Item.Coal,1])
        ItemEdit(Item.GoldIngot, ItemData.Blueprint, [Item.GoldOre,1,Item.Coal,1])
        ItemEdit(Item.Glass, ItemData.Blueprint, [Item.Sand,1,Item.Coal,1])
    }
    
    
#define send_goal()
    http_post_string(global.URL + "Goal","test") //TODO : Maybe have an actual message
    

#define OnHTTPAsync(async_load)
    result = async_load[? "result"]
    url = async_load[? "url"]
    http_status = async_load[? "http_status"]
    status = async_load[? "status"]
    if(status < 0){
        Trace("Connection with archipelago failed")
        Trace("Please connect to client before compiling the mod")
        Trace("If the client is connected, type /recompile or boot up the game again")
        Trace("status : " + string(status))
        global.get = -60 //Try to send another get command later, to not flood.
        return
    }
    
    switch (url)
    {
        case "http://127.0.0.1:8000/updateGear": //Outdated
            Trace("gear")
            
            archigear = string_split(result,",")
            Trace(archigear)
            ToolbarRefresh(1)
            break
        case "http://127.0.0.1:8000/Items":
            get_items(result)
            break
        case "http://127.0.0.1:8000/Datapackage":
            get_datapackage(result)
            Trace("Datapackage Loaded, enjoy your foragipelago experience")
            break
        default:
            //Trace(url)
    }