/obj/effect/blob/floor
	name = "blob floor"
	icon = 'icons/mob/blob.dmi'
	icon_state = "blob_damaged2"
	default_icon_state = "blob_damaged2"
	desc = "Some blob creature thingy"
	density = 0
	opacity = 0
	anchored = 1
	health = 50
	maxhealth = 50
	brute_resist = 2
	fire_resist = 1
	blob_type = BLOB_TYPE_FLOOR


	update_icon()
		if(health <= 0)
			playsound(src.loc, 'sound/effects/splat.ogg', 50, 1)
			qdel(src)
			return
		return


	CanPass(atom/movable/mover, turf/target, height=0, air_group=0)
		return 1
