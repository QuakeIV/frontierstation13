
#define BLOB_TYPE_NORMAL  1
#define BLOB_TYPE_NODE    2
#define BLOB_TYPE_CORE    3
#define BLOB_TYPE_FACTORY 4
#define BLOB_TYPE_WALL    5

// the blob cannot expand into space:
// this is justified under the notion that the blob is essentially a loose pile of cells that requires
// some kind of cellular lattice to support it and provide it with a structure to follow.  the blob
// will attempt to fill out the structure and form an airtight 'blob', using the station as a
// skeleton.

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
	var/maxhealth = 30
	var/brute_resist = 2 //originally 4
	var/fire_resist  = 1 //originally 1
	var/blob_type = BLOB_TYPE_NORMAL

	var/qdel_underway = FALSE //bug testing tool
	var/pulsed_ever   = FALSE //bug testing tool

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
	Wall
		*/


	New(loc, var/h = maxhealth)
		blobs += src
		src.health = min(h, maxhealth)
		src.update_icon()
		//check space adjacency
		check_space()
		..(loc)
		return


	Destroy()
		blobs -= src

		unpulsed_blobs -= src

		if (src in unpulsed_blobs)
			message_admins("ERROR: blob still in unpulsed_blobs somehow, report")

		//TODO: check isnull gcDestroyed for north/south/east/west
		if (north)
			north.south = null
			north = null

		if (south)
			south.north = null
			south = null

		if (east)
			east.west = null
			east = null

		if (west)
			west.east = null
			west = null
		..()
		//del src //fuck it

		return 0


	CanPass(atom/movable/mover, turf/target, height=0, air_group=0)
		if (air_group && !adjacent_to_space)
			return 1
		else
			return 0
		if(height==0)
			return 1
		if(istype(mover) && mover.checkpass(PASSBLOB))	return 1
		return 0


	blob_act() //blobs dont get hurt by blobs
		message_admins("ERROR: blob hit by other blob, this shouldnt happen, report this please")
		return


	proc/check_space()
		adjacent_to_space = FALSE
		for (var/d in alldirs)
			var/turf/T = get_step(src.loc, d)
			if (!T)
				message_admins("ERROR: blob got null turf when trying to check for space, report this please. turf:[T]")
			if (istype(T, /turf/space))
				adjacent_to_space = TRUE


	proc/Pulse(var/list/p = FALSE)
		pulsed_ever = TRUE
		//TODO: this appears to be a matter of garbage collection needing help for some reason, this needs investigation
		if (!src.loc)
			if (qdel_underway)
				message_admins("ERROR: invalid blob being QDEL'd more than once, somehow")
			qdel(src)
			qdel_underway = TRUE
			return

		//are we toggling for the first time this tick?
		if (p != propogation)
			//check if we are adjacent to space
			check_space()
			//heal (total heal time of 100 seconds effectively, currently) TODO: balance
			health = min(health + maxhealth/1000, maxhealth)

		propogation = p //update propogation to latest

		run_action()

		//TODO: move this into an oview call from core, let core manage giving itself shield blubs
		//if (!istype(src,/obj/effect/blob/shield) && istype(from, /obj/effect/blob/core) && prob(30))
			//change_to(BLOB_TYPE_WALL)

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
		if (adjacent_to_space && blob_type != BLOB_TYPE_WALL)
			change_to(BLOB_TYPE_WALL)

		return


	// inspect a given direction, try to expand if given the chance
	proc/poke_dir(var/d)
		var/turf/T = get_step(src.loc, d)
		if (!T)
			message_admins("ERROR: turf null in blob/poke_dir")
		if (istype(T, /turf/space))
			return null
		var/obj/effect/blob/B = (locate(/obj/effect/blob) in T)
		if(!B)
			//No blob here so try and expand
			if(!prob((health/maxhealth)*10))
				return null // 10% chance to expand each tick

			B = new /obj/effect/blob(src.loc, src.health)
			if (!B)
				message_admins("ERROR: new blob is null in blob/poke_dir")
			if (!B.loc)
				message_admins("ERROR: new blob.loc is null in blob/poke_dir")
			if(T.Enter(B,src))//Attempt to move into the tile
				for(var/atom/A in T)//Hit everything in the turf
					A.blob_act()
				B.loc = T
				playsound(B.loc, 'sound/effects/splat.ogg', 50, 1)
			else
				T.blob_act() //If we cant move in hit the turf
				for(var/atom/A in T)//Hit everything in the turf
					A.blob_act()
				if(T.Enter(B,src))//try again
					B.loc = T
					playsound(B.loc, 'sound/effects/splat.ogg', 50, 1)
				else
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
		if(health <= maxhealth/2)
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
				if(istype(W, /obj/item/weapon/weldingtool))
					playsound(src.loc, 'sound/items/Welder.ogg', 100, 1)
					damage = (W.force / src.fire_resist) * 2 //double damage for welder
				else
					damage = (W.force / src.fire_resist)
			if("brute")
				damage = (W.force / src.brute_resist)

		health -= damage
		update_icon()
		return


	proc/change_to(var/type = BLOB_TYPE_NORMAL)
		var/obj/effect/blob/B
		switch(type)
			if(BLOB_TYPE_NORMAL)
				B = new/obj/effect/blob(src.loc,src.health)
			if(BLOB_TYPE_NODE)
				B = new/obj/effect/blob/node(src.loc,src.health*2)
			if(BLOB_TYPE_FACTORY)
				B = new/obj/effect/blob/factory(src.loc,src.health)
			if(BLOB_TYPE_WALL)
				B = new/obj/effect/blob/wall(src.loc,src.health*2)
		//re-wire references
		B.north = src.north
		B.south = src.south
		B.east  = src.east
		B.west  = src.west
		if (src.north)
			src.north.south = B
		if (src.south)
			src.south.north = B
		if (src.west)
			src.west.east = B
		if (src.east)
			src.east.west = B
		qdel(src)
		return

//////////////////////////////****IDLE BLOB***/////////////////////////////////////

/obj/effect/blob/idle
	name = "blob"
	desc = "it looks... tasty"
	icon_state = "blobidle0"
	maxhealth = 10


	New(loc, var/h = maxhealth)
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


