//I will need to recode parts of this but I am way too tired atm
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
		src.set_dir(pick(1,2,4,8))
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
		spawn(-1)
			Life()
		return


	proc/Pulse(var/from = 0, var/list/pulsed = new/list())//Todo: Fix spaceblob expand
		set background = 1
		pulsed.Add(src) //we have just been pulsed, add to list
		if(!istype(src,/obj/effect/blob/core) && !istype(src,/obj/effect/blob/node))//Ill put these in the children later
			if(run_action())//If we can do something here then we dont need to pulse more
				return

		//TODO: figure out good way to get corners
		if (!istype(src,/obj/effect/blob/shield) && istype(from, /obj/effect/blob/core) && prob(30))
			change_to("Shield")

		//Looking for another blob to pulse
		var/list/dirs = list(NORTH,SOUTH,EAST,WEST)
		for(var/i in dirs)
			var/turf/T = get_step(src, i)
			if (istype(T, /turf/space))
				continue
			var/obj/effect/blob/B = (locate(/obj/effect/blob) in T)
			if(!B)
				expand(T)//No blob here so try and expand
			else
				if (B in pulsed)
					world << "skippidy doodle"
					continue
				B.Pulse(src, pulsed)


	proc/run_action()
		return 0


	proc/Life()
		update_icon()
		if(run_action())
			return 1
		return 0

	fire_act(datum/gas_mixture/air, temperature, volume)
		if(temperature > T0C+200)
			health -= 0.01 * temperature
			update_icon()

	proc/expand(var/turf/T)
		if(!prob((health/max_health)*100))	return
		var/obj/effect/blob/B = new /obj/effect/blob(src.loc, min(src.health, 30))
		if(T.Enter(B,src))//Attempt to move into the tile
			B.loc = T
		else
			T.blob_act()//If we cant move in hit the turf
			qdel(B)
		for(var/atom/A in T)//Hit everything in the turf
			A.blob_act()
		return 1


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
		if(health <= 15)
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
		src.set_dir(pick(1,2,4,8))
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
		var/obj/effect/blob/B = new /obj/effect/blob( src.loc )
		spawn(30)
			B.Life()
		..()


