/obj/effect/blob/node
	name = "blob node"
	icon = 'icons/mob/blob.dmi'
	icon_state = "blob_node"
	default_icon_state = "blob_node"
	health = 100
	maxhealth = 100
	brute_resist = 2
	fire_resist = 1


	New(loc, var/h = maxhealth)
		blobs += src
		blob_nodes += src
		processing_objects.Add(src)
		..(loc, h)


	Destroy()
		blobs -= src
		blob_nodes -= src
		processing_objects.Remove(src)
		..()
		return 0


	update_icon()
		if(health <= 0)
			playsound(src.loc, 'sound/effects/splat.ogg', 50, 1)
			qdel(src)
			return
		return


	run_action()
		return 0