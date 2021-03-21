/obj/effect/blob/node
	name = "blob node"
	icon = 'icons/mob/blob.dmi'
	icon_state = "blob_node"
	health = 100
	maxhealth = 100
	brute_resist = 2
	fire_resist = 0.5


	New(loc, var/h = maxhealth)
		blobs += src
		blob_nodes += src
		processing_objects.Add(src)
		..(loc, h)


	Destroy()
		blob_nodes -= src
		processing_objects.Remove(src)
		..()
		return


	update_icon()
		if(health <= 0)
			playsound(src.loc, 'sound/effects/splat.ogg', 50, 1)
			qdel(src)
			return
		return


	run_action()
		return 0