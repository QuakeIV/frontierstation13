/obj/item/clothing/under/deempisi
	name = "fancy uniform"
	desc = "It looks like it was tailored for a monkey."
	icon_state = "deempisi"
	worn_state = "deempisi"
	species_restricted = list("Monkey")

/mob/living/carbon/human/monkey/deempisi/New()
	..()
	spawn(1)
		name = "Mr. Deempisi"
		real_name = name
		w_uniform = new /obj/item/clothing/under/deempisi(src)