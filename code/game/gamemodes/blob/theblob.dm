
#define BLOB_TYPE_NORMAL  1
#define BLOB_TYPE_NODE    2
#define BLOB_TYPE_CORE    3
#define BLOB_TYPE_FACTORY 4
#define BLOB_TYPE_WALL    5
#define BLOB_TYPE_FLOOR   6

// the blob cannot expand into space:
// this is justified under the notion that the blob is essentially a loose pile of cells that requires
// some kind of cellular lattice to support it and provide it with a structure to follow.  the blob
// will attempt to fill out the structure and form an airtight 'blob', using the station as a
// skeleton.

/obj/effect/blob
	name = "blob"
	icon = 'icons/mob/blob.dmi'
	icon_state = "blob"
	var/default_icon_state = "blob"
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

	var/pulsed_qdel   = FALSE //bug testing tool
	var/pulsed_ever   = FALSE //bug testing tool
	var/multiple_del  = FALSE //bug testing tool

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
		if (multiple_del)
			message_admins("trying to del object multiple times")
		multiple_del = TRUE



		//rip
		blobs -= src

		//unpulsed_blobs -= src

		//if (src in unpulsed_blobs)
		//	message_admins("ERROR: blob still in unpulsed_blobs somehow, report")

		//clean up our references to other blobs
		north = null
		south = null
		east = null
		west = null



		..()
		//del src //fuck it

		return 0


	CanPass(atom/movable/mover, turf/target, height=1, air_group=0)
		if(istype(mover) && mover.checkpass(PASSBLOB))
			return 1
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


	proc/Pulse(var/p = FALSE, var/list/unpulsed)
		pulsed_ever = TRUE //debugging tool

		//TODO: this appears to be a matter of garbage collection needing help for some reason, this needs investigation
		if (!isnull(gcDestroyed))
			if (pulsed_qdel)
				message_admins("ERROR: dead blob being pulsed")
			pulsed_qdel = TRUE
			return

		//are we toggling for the first time this tick?
		if (p != propogation)
			//check if we are adjacent to space
			check_space()
			//heal (full heal time of 120 seconds currently) TODO: balance
			health = min(health + maxhealth/1200, maxhealth)

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
			if (isnull(north.gcDestroyed))
				unpulsed.Add(north) //TODO: |= perhaps
			else
				north = null //clean up references to dead stuff

		//SOUTH
		if (!south)
			south = poke_dir(SOUTH)
		else if (south.propogation != propogation)
			if (isnull(south.gcDestroyed))
				unpulsed.Add(south)
			else
				south = null //clean up references to dead stuff

		//EAST
		if (!east)
			east = poke_dir(EAST)
		else if (east.propogation != propogation)
			if (isnull(east.gcDestroyed))
				unpulsed.Add(east)
			else
				east = null //clean up references to dead stuff

		//WEST
		if (!west)
			west = poke_dir(WEST)
		else if (west.propogation != propogation)
			if (isnull(west.gcDestroyed)) //clean up references to dead stuff
				unpulsed.Add(west)
			else
				west = null


		//check if we are adjacent to space, if so turn into wall if we arent already
		if (adjacent_to_space && blob_type != BLOB_TYPE_WALL)
			change_to(BLOB_TYPE_WALL)

		return


	// inspect a given direction, try to expand
	proc/poke_dir(var/d)
		var/turf/T = get_step(src.loc, d)
		if (!T)
			message_admins("ERROR: turf null in blob/poke_dir")

		// 50% chance to expand each pulse * percent current health
		if(!prob((health/maxhealth)*70))
			return null

		// check if we can reach out of tile before expanding network or checking if there is space
		// turf.Enter had a nice system for acting on objects in order of precedence, using that here

		// First, check objects to block exit that are not on the border of source tile
		for(var/obj/obstacle in src.loc)
			if(!(obstacle.flags & ON_BORDER) && (src != obstacle))
				if(!obstacle.CheckExit(src, T))
					src.Bump(obstacle, 1)
					obstacle.blob_act()
					//check twice, only return if we fail to smash through
					if (obstacle && !obstacle.CheckExit(src, T))
						return null

		// Now, check objects to block exit that are on the border of source tile
		for(var/obj/border_obstacle in src.loc)
			if((border_obstacle.flags & ON_BORDER))
				if(!border_obstacle.CheckExit(src, T))
					src.Bump(border_obstacle, 1)
					border_obstacle.blob_act()
					//check twice, only return if we fail to smash through
					if(border_obstacle  && !border_obstacle.CheckExit(src, T))
						return null

		//Next, check objects to block entry that are on the border of target tile
		for(var/obj/border_obstacle in T)
			if(border_obstacle.flags & ON_BORDER)
				if(!border_obstacle.CanPass(src, src.loc, 1, 0))
					border_obstacle.blob_act()
					src.Bump(border_obstacle, 1)
					//check twice, only return if we fail to smash through
					if(border_obstacle && !border_obstacle.CanPass(src, src.loc, 1, 0))
						return null

		if (istype(T, /turf/space))
			return null

		//Then, check the target tile itself
		if (!T.CanPass(src, T))
			src.Bump(T, 1)
			T.blob_act()
			//check twice, only return if we fail to smash through
			if (T && !T.CanPass(src, T))
				return null

		var/obj/effect/blob/B = (locate(/obj/effect/blob) in T)

		if(!B)
			// No blob here so try and expand

			//Finally, check objects/mobs to block entry that are not on the border of target tile
			for(var/atom/movable/obstacle in T)
				if(!(obstacle.flags & ON_BORDER))
					if(!obstacle.CanPass(src, src.loc, 1, 0))
						obstacle.blob_act()
						src.Bump(obstacle, 1)
						//check twice, only return if we fail to smash through
						if(obstacle && !obstacle.CanPass(src, src.loc, 1, 0))
							return null

			// if we still havent returned, there are no obstacles and we can enter the tile
			// make a new blub and place it in the destination tile
			B = new /obj/effect/blob(src.loc, src.health)
			B.loc = T
			B.propogation = propogation
			playsound(B.loc, 'sound/effects/splat.ogg', 50, 1)
		return B


	proc/run_action()
		return 0


	//TODO: balance
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


	update_icon() //Needs to be updated with the types
		if(health <= 0)
			playsound(src.loc, 'sound/effects/splat.ogg', 50, 1)
			qdel(src)
			return
		if(health <= maxhealth/2)
			icon_state = "blob_damaged"
			return
		if(health >= maxhealth * 3 / 4)
			icon_state = default_icon_state
		return


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
		if (type == blob_type)
			message_admins("for some reason a blob tried to turn into its own type")
		var/obj/effect/blob/B
		switch(type)
			if(BLOB_TYPE_NORMAL)
				B = new/obj/effect/blob(src.loc,src.health)
			if(BLOB_TYPE_NODE)
				B = new/obj/effect/blob/node(src.loc,src.health*2)
			if(BLOB_TYPE_FACTORY)
				B = new/obj/effect/blob/factory(src.loc,src.health)
			if(BLOB_TYPE_WALL)
				B = new/obj/effect/blob/wall(src.loc,src.health)
			if(BLOB_TYPE_FLOOR)
				B = new/obj/effect/blob/floor(src.loc,src.health)
		B.propogation = propogation
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
