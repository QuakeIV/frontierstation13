// TODO: this file requires some rework to track the new pulse system

/datum/event/blob
	announceWhen	= 12
	endWhen			= 120

	var/obj/effect/blob/core/Blob


/datum/event/blob/announce()
	command_announcement.Announce("Confirmed outbreak of level 7 biohazard aboard [station_name()]. All personnel must contain the outbreak.", "Biohazard Alert", new_sound = 'sound/AI/outbreak7.ogg')


/datum/event/blob/start()
	var/turf/T = pick(blobstart)
	if(!T)
		kill()
		return
	Blob = new /obj/effect/blob/core(T, 120)
	for(var/i = 1; i < rand(3, 4), i++)
		Blob.Pulse()


/datum/event/blob/tick()
	if(!Blob)
		kill()
		return
	Blob.Pulse()