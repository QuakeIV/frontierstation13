//TODO: needs rework to work with new pulse code

/proc/mini_blob_event()

	var/turf/T = pick(blobstart)
	var/obj/effect/blob/core/bl = new /obj/effect/blob/core(T, 200)
	spawn(0)
		bl.Pulse()
		bl.Pulse()
		bl.Pulse()
	blobevent = 1
	spawn(0)
		dotheblobbaby()
	spawn(3000)
		blobevent = 0
	spawn(rand(1000, 2000)) //Delayed announcements to keep the crew on their toes.
		command_announcement.Announce("Confirmed outbreak of level 5 biohazard aboard [station_name()]. All personnel must contain the outbreak.", "Biohazard Alert", new_sound = 'sound/AI/outbreak5.ogg')

/proc/dotheblobbaby()
	if (blobevent)
		if(blob_cores.len)
			for(var/i = 1 to 5)
				sleep(-1)
				if(!blob_cores.len)	break
				var/obj/effect/blob/B = pick(blob_cores)
				if(isNotStationLevel(B.z))
					continue
				B.Pulse()
		spawn(30)
			dotheblobbaby()