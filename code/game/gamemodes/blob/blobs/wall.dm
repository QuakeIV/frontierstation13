/obj/effect/blob/wall
	name = "strong blob"
	icon = 'icons/mob/blob.dmi'
	icon_state = "blob_idle"
	desc = "Some blob creature thingy"
	density = 1
	opacity = 1
	anchored = 1
	health = 100
	maxhealth = 100
	brute_resist = 2
	fire_resist = 1
	blob_type = BLOB_TYPE_WALL


	update_icon()
		if(health <= 0)
			playsound(src.loc, 'sound/effects/splat.ogg', 50, 1)
			qdel(src)
			return
		return


	CanPass(atom/movable/mover, turf/target, height=0, air_group=0)
		if(istype(mover) && mover.checkpass(PASSBLOB))	return 1
		return 0
