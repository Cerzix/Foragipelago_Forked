#define init_filler //Filler items and traps received from AP, ids from the apworld's items.json
	global.fillerReceived = [] //Every filler/trap id received, in order, from the Items request
	global.linkedTraps = [] //Traps received through TrapLink, waiting to be played
	global.filler_interval = 3 //System steps between two filler items, about one per second
	reset_filler_state()

#define reset_filler_state //Reset everything that belongs to one save file
	global.fillerApplied = 0 //How many of fillerReceived were already given on this save
	global.fillerTimer = 0
	global.linkedTraps = []
	global.speedBoostUntil = 0 //current_time in ms when each effect ends
	global.slownessUntil = 0
	global.regenUntil = 0
	global.regenNext = 0
	global.energyUntil = 0
	global.energyFloor = 0
	global.baseSpd = undefined //Player speed without the effects, while a speed effect is active
	global.baseAccel = undefined
	global.appliedSpd = undefined

#define filler_name(fid)
	switch(fid){
		case 400: return "Small Coin Bag"
		case 401: return "Medium Coin Bag"
		case 402: return "Large Coin Bag"
		case 410: return "Wood Bundle"
		case 411: return "Stone Bundle"
		case 412: return "Coal Bundle"
		case 413: return "Ore Bundle"
		case 414: return "Fiber Bundle"
		case 415: return "Sand Bundle"
		case 420: return "Food Basket"
		case 421: return "Feast"
		case 430: return "Gem Pouch"
		case 431: return "Legendary Gem"
		case 440: return "Seed Pack"
		case 450: return "Random Potion"
		case 451: return "Healing Potions"
		case 460: return "Bug Jar"
		case 461: return "Bottled Fairy"
		case 470: return "Fish Bucket"
		case 480: return "Speed Boost"
		case 481: return "Regeneration"
		case 482: return "Boundless Energy"
		case 500: return "Energy Drain Trap"
		case 501: return "Slowness Trap"
		case 502: return "Tax Trap"
	}
	return "Unknown filler " + string(fid)

#define is_trap(fid)
	return fid >= 500 && fid < 600

#define drop_filler(item, quantity) //Dropped like the progressive gear, nothing is lost with a full inventory
	DropItem(objPlayer.x, objPlayer.y, item, quantity)

#define drop_random(items, quantity) //Drops quantity items picked at random from the array
	var counts = []
	for(var i = 0; i < array_length(items); i++){
		counts[i] = 0
	}
	for(var i = 0; i < quantity; i++){
		var pick = irandom(array_length(items) - 1)
		counts[pick] = counts[pick] + 1
	}
	for(var i = 0; i < array_length(items); i++){
		if(counts[i] > 0){
			drop_filler(items[i], counts[i])
		}
	}

#define apply_filler(fid, linked) //Gives a filler item or plays a trap, linked : it came from TrapLink
	var level = objPlayer.level
	var now = current_time
	switch(fid){
		//Coin bags, they scale with the level to stay useful
		case 400: drop_filler(Item.Coin, 20 + 5 * level); break
		case 401: drop_filler(Item.Coin, 50 + 15 * level); break
		case 402: drop_filler(Item.Coin, 100 + 40 * level); break
		//Resource bundles
		case 410: drop_filler(Item.Wood, 25); break
		case 411: drop_filler(Item.Stone, 25); break
		case 412: drop_filler(Item.Coal, 15); break
		case 413: drop_filler(Item.IronOre, 10); drop_filler(Item.GoldOre, 6); break
		case 414: drop_filler(Item.Fiber, 20); break
		case 415: drop_filler(Item.Sand, 15); break
		//Food
		case 420: drop_random([Item.Berry, Item.Citrus, Item.Bread, Item.CookedFish, Item.CookedMeat], 3); break
		case 421: drop_random([Item.Pizza, Item.Sushi, Item.Soup, Item.Sandwich, Item.FruitSalad, Item.IceCream, Item.MeatSkewer, Item.Cookies], 3); break
		//Gems
		case 430: drop_random([Item.Ruby, Item.Emerald, Item.Topaz, Item.Amethyst], 3); break
		case 431: drop_filler(Item.LegendaryGem, 1); break
		//Seeds
		case 440: drop_random([Item.SeedTree, Item.SeedCotton, Item.SeedBeet, Item.SeedWheat, Item.SeedHotPepper, Item.SeedPumpkin, Item.SeedBerry, Item.SeedFlower], 5); break
		//Potions, bugs and fish
		case 450: drop_random([Item.Thunderbolt, Item.AnasDelight, Item.LiquidLuck, Item.DraughtOfWisdom, Item.BloodFuryCocktail, Item.DragonPhiltre, Item.GreedyMixture], 1); break
		case 451: drop_filler(Item.HealingPotion, 2); break
		case 460: drop_random([Item.BottledTorchbug, Item.BottledBeetle, Item.BottledButterfly, Item.BottledDeathMoth], 2); break
		case 461: drop_filler(Item.BottledFairy, 1); break
		case 470: drop_random([Item.Fish, Item.SkeletonFish, Item.FrozenSquid, Item.LavaEel], 3); break
		//Temporary buffs, a second one adds its time
		case 480: global.speedBoostUntil = max(global.speedBoostUntil, now) + 60000; break
		case 481:
			global.regenUntil = max(global.regenUntil, now) + 60000
			global.regenNext = now
			break
		case 482:
			if(global.energyUntil <= now){
				global.energyFloor = objPlayer.energy
			}
			global.energyUntil = max(global.energyUntil, now) + 60000
			break
		//Traps
		case 500:
			objPlayer.energy = 0
			global.energyUntil = 0 //Also ends Boundless Energy
			break
		case 501: global.slownessUntil = max(global.slownessUntil, now) + 30000; break
		case 502:
			var tax = floor(ItemCount(Item.Coin, false) * 0.25)
			if(tax > 0){
				RemoveItem(Item.Coin, tax)
				Trace("Taxes : you paid " + string(tax) + " coins")
			}
			break
		default:
			Trace("Foragipelago : unknown filler " + string(fid) + ", update the mod")
			return
	}
	if(linked){
		Trace("TrapLink : " + filler_name(fid))
	}
	else{
		Trace("Received " + filler_name(fid))
		if(is_trap(fid)){
			send_trap(fid) //For the other TrapLink players, the client only sends it if TrapLink is on
		}
	}

#define update_filler //System step : give the next filler item or trap, one at a time
	global.fillerTimer++
	if(global.fillerTimer < global.filler_interval){
		return
	}
	if(objPlayer.hp <= 0){ //Wait for the respawn
		return
	}
	global.fillerTimer = 0
	if(array_length(global.linkedTraps) > 0){
		var trap = global.linkedTraps[0]
		var rest = []
		for(var i = 1; i < array_length(global.linkedTraps); i++){
			rest[i - 1] = global.linkedTraps[i]
		}
		global.linkedTraps = rest
		apply_filler(trap, true)
	}
	else if(global.fillerApplied < array_length(global.fillerReceived)){
		var next_filler = global.fillerReceived[global.fillerApplied]
		global.fillerApplied++
		apply_filler(next_filler, false)
	}

	//Regeneration : 1 hp every 3 seconds
	var now = current_time
	if(now < global.regenUntil && now >= global.regenNext){
		objPlayer.hp = min(objPlayer.hp + 1, objPlayer.hpMax)
		global.regenNext = now + 3000
	}

#define update_effects //Every frame : speed effects and Boundless Energy
	var now = current_time
	if(now < global.energyUntil){
		global.energyFloor = max(global.energyFloor, objPlayer.energy) //Eating still raises it
		if(objPlayer.energy < global.energyFloor){
			objPlayer.energy = global.energyFloor
		}
	}

	var mult = 1
	if(now < global.speedBoostUntil){
		mult *= 1.5
	}
	if(now < global.slownessUntil){
		mult *= 0.5
	}
	if(mult != 1){
		if(is_undefined(global.baseSpd) || objPlayer.maxSpd != global.appliedSpd){
			//An effect starts, or the game changed the speed itself (new boots...) : that's the new base speed
			global.baseSpd = objPlayer.maxSpd
			global.baseAccel = objPlayer.accel
		}
		global.appliedSpd = global.baseSpd * mult
		objPlayer.maxSpd = global.appliedSpd
		objPlayer.accel = global.baseAccel * mult
	}
	else if(!is_undefined(global.baseSpd)){
		restore_speed()
	}

#define restore_speed //Puts the speed back without the effects, they're reapplied on the next frame if still active
	if(is_undefined(global.baseSpd)){
		return
	}
	if(objPlayer.maxSpd == global.appliedSpd){ //Don't overwrite a speed the game changed itself
		objPlayer.maxSpd = global.baseSpd
		objPlayer.accel = global.baseAccel
	}
	global.baseSpd = undefined
	global.appliedSpd = undefined
