
#define send_check(id) //Sends a POST to the server when a check is completed.
    var json = "{\"Locations\": [" + string(id) + "]}"
    http_post_string(global.URL + "Locations",json)

#define send_get_items
    http_get(global.URL + "Items")

#define get_items(str_json) //Grabs and updates the obtained items recieved by the server.
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
    
#define send_goal()
    http_post_string(global.URL + "Goal","test") //TODO : Maybe have an actual message
    

#define OnHTTPAsync(async_load)
    result = async_load[? "result"]
    url = async_load[? "url"]
    http_status = async_load[? "http_status"]
    status = async_load[? "status"]
    if(status < 0){
        Trace("Connection with archipelago failed")
        Trace("Please connect to Forager Client before compiling the mod")
        Trace("If the client is connected, recompile in the main menu or boot up the game again")
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