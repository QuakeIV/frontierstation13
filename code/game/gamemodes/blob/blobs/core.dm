/obj/effect/blob/core
	name = "blob core"
	icon = 'icons/mob/blob.dmi'
	icon_state = "blob_core"
	health = 200
	max_health = 200
	brute_resist = 2
	fire_resist = 2


	New(loc, var/h = 200)
		blobs += src
		blob_cores += src
		processing_objects.Add(src)
		..(loc, h)


	Destroy()
		blob_cores -= src
		processing_objects.Remove(src)
		..()
		return


	// special pulse behavior for core, which will drive other blubs
	// any pulsed blob will add additional pulse-able blobs into the unpulsed blobs list, to be iterated over
	// this logic exists to flatten out the recursion so that we dont hit the recursion limiter in byond (honestly probably more effecient anyways, maybe not though)
	Pulse(var/p)
		unpulsed_blobs = new/list()
		..() //call parent version of function on self to populate initial list

		while (unpulsed_blobs.len)
			var/derp = unpulsed_blobs.len
			var/obj/effect/blob/B = unpulsed_blobs[unpulsed_blobs.len]
			unpulsed_blobs.Remove(B)
			world << "before " << derp << "after" << unpulsed_blobs.len
			B.Pulse(p)




	update_icon()
		if(health <= 0)
			playsound(src.loc, 'sound/effects/splat.ogg', 50, 1)
			qdel(src)
			return
		return


	run_action()
		//TODO: should have the fragments in here somewhere (no idea why, but added a TODO to it to find it later)
		return 1


	proc/create_fragments(var/wave_size = 1)
		var/list/candidates = list()
		for(var/mob/dead/observer/G in player_list)
			if(G.client.prefs.be_special & BE_ALIEN)
				if(!(G.mind && G.mind.current && G.mind.current.stat != DEAD))
					candidates += G.key

		if(candidates.len)
			for(var/i = 0 to wave_size)
				var/mob/living/blob/B = new/mob/living/blob(src.loc)
				B.key = pick(candidates)
				candidates -= B.key