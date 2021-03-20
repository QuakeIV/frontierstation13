

//used for graph traversals
/var/list/unpulsed_blobs

/obj/effect/blob
	name = "blob"
	icon = 'icons/mob/blob.dmi'
	icon_state = "blob"
	light_range = 3
	desc = "Some blob creature thingy"
	density = 1
	opacity = 0
	anchored = 1
	var/active = 1
	var/health = 30
	var/max_health = 30
	var/brute_resist = 4
	var/fire_resist = 1
	var/blob_type = "blob"

	var/adjacent_to_space = FALSE

	//blob graph data
	var/propogation = FALSE //if someone else is different from us, pulse them
	var/obj/effect/blob/north = null
	var/obj/effect/blob/south = null
	var/obj/effect/blob/east  = null
	var/obj/effect/blob/west  = null
	/*Types
	Blob
	Node
	Core
	Factory
	Shield
		*/


	New(loc, var/h = 30)
		blobs += src
		src.health = h
		src.update_icon()
		..(loc)
		return


	Destroy()
		blobs -= src
		..()
		return


	CanPass(atom/movable/mover, turf/target, height=0, air_group=0)
		if(air_group || (height==0))	return 1
		if(istype(mover) && mover.checkpass(PASSBLOB))	return 1
		return 0


	process()
		..()
		//TODO: add healing here if this actually fires
		world << "proc"


	proc/Pulse(var/list/p = FALSE)
		propogation = p //update propogation to latest

		run_action()

		//TODO: move this into an oview call from core, let core manage giving itself shield blubs
		//if (!istype(src,/obj/effect/blob/shield) && istype(from, /obj/effect/blob/core) && prob(30))
			//change_to("Shield")

		//check if we should turn into a wall (re-set every round and try to disprove
		adjacent_to_space = FALSE

		//Looking for another blob to pulse

		//NORTH
		if (!north)
			north = poke_dir(NORTH)
		else if (north.propogation != propogation)
			unpulsed_blobs.Add(north) //add to list to be pulsed by parent

		//SOUTH
		if (!south)
			south = poke_dir(SOUTH)
		else if (south.propogation != propogation)
			unpulsed_blobs.Add(south)

		//EAST
		if (!east)
			east = poke_dir(EAST)
		else if (east.propogation != propogation)
			unpulsed_blobs.Add(east)

		//WEST
		if (!west)
			west = poke_dir(WEST)
		else if (west.propogation != propogation)
			unpulsed_blobs.Add(west)


		//check if we are adjacent to space, if so turn into wall if we arent already

		return


	// inspect a given direction, try to expand if given the chance
	proc/poke_dir(var/d)
		var/turf/T = get_step(src.loc, d)
		if (istype(T, /turf/space))
			adjacent_to_space = TRUE
			return null
		var/obj/effect/blob/B = (locate(/obj/effect/blob) in T)
		if(!B)
			//No blob here so try and expand
			if(!prob((health/max_health)*10))	return null // 10% chance to expand each tick
			for(var/atom/A in T)//Hit everything in the turf
				A.blob_act()

			B = new /obj/effect/blob(src.loc, min(src.health, 30))
			if(T.Enter(B,src))//Attempt to move into the tile
				B.loc = T
				playsound(B.loc, 'sound/effects/splat.ogg', 50, 1)
			else
				T.blob_act() //If we cant move in hit the turf
				qdel(B)
				return null
		return B

	proc/run_action()
		return 0

	fire_act(datum/gas_mixture/air, temperature, volume)
		if(temperature > T0C+200)
			health -= 0.01 * temperature
			update_icon()
		return


	ex_act(severity)
		var/damage = 50
		switch(severity)
			if(1)
				src.health -= rand(100,120)
			if(2)
				src.health -= rand(60,100)
			if(3)
				src.health -= rand(20,60)

		health -= (damage/brute_resist)
		update_icon()
		return


	update_icon()//Needs to be updated with the types
		if(health <= 0)
			playsound(src.loc, 'sound/effects/splat.ogg', 50, 1)
			qdel(src)
			return
		if(health <= max_health/2)
			icon_state = "blob_damaged"
			return
//		if(health <= 20)
//			icon_state = "blob_damaged2"
//			return


	bullet_act(var/obj/item/projectile/Proj)
		if(!Proj)	return
		switch(Proj.damage_type)
		 if(BRUTE)
			 health -= (Proj.damage/brute_resist)
		 if(BURN)
			 health -= (Proj.damage/fire_resist)

		update_icon()
		return 0


	attackby(var/obj/item/weapon/W, var/mob/user)
		playsound(src.loc, 'sound/effects/attackblob.ogg', 50, 1)
		src.visible_message("<span class='danger'>The [src.name] has been attacked with \the [W][(user ? " by [user]." : ".")]</span>")
		var/damage = 0
		switch(W.damtype)
			if("fire")
				damage = (W.force / max(src.fire_resist,1))
				if(istype(W, /obj/item/weapon/weldingtool))
					playsound(src.loc, 'sound/items/Welder.ogg', 100, 1)
			if("brute")
				damage = (W.force / max(src.brute_resist,1))

		health -= damage
		update_icon()
		return

	proc/change_to(var/type = "Normal")
		switch(type)
			if("Normal")
				new/obj/effect/blob(src.loc,src.health)
			if("Node")
				new/obj/effect/blob/node(src.loc,src.health*2)
			if("Factory")
				new/obj/effect/blob/factory(src.loc,src.health)
			if("Shield")
				new/obj/effect/blob/shield(src.loc,src.health*2)
		qdel(src)
		return

//////////////////////////////****IDLE BLOB***/////////////////////////////////////

/obj/effect/blob/idle
	name = "blob"
	desc = "it looks... tasty"
	icon_state = "blobidle0"


	New(loc, var/h = 10)
		src.health = h
		src.update_idle()


	proc/update_idle()
		if(health<=0)
			qdel(src)
			return
		if(health<4)
			icon_state = "blobc0"
			return
		if(health<10)
			icon_state = "blobb0"
			return
		icon_state = "blobidle0"


	Destroy()
		//TODO: the fuck does this even do
		new /obj/effect/blob( src.loc )
		..()


