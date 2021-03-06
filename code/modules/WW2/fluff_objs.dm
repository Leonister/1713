/* objects that don't actually do anything, used in a few areas on the map
 for flavor. It's mostly atmospherics stuff I removed - Kachnov */

// ores

/obj/item/weapon/ore
	name = "rock"
	icon = 'icons/obj/mining.dmi'
	icon_state = "ore2"
	w_class = 2

/obj/item/weapon/ore/iron
	name = "iron ore"
	icon_state = "ore_iron"
//	origin_tech = list(TECH_MATERIAL = TRUE)

/obj/item/weapon/ore/coal
	name = "mineral coal"
	icon_state = "ore_coal"
//	origin_tech = list(TECH_MATERIAL = TRUE)

/obj/item/weapon/ore/glass
	name = "sand"
	icon_state = "ore_glass"
//	origin_tech = list(TECH_MATERIAL = TRUE)
	slot_flags = SLOT_HOLSTER

/obj/item/weapon/ore/silver
	name = "silver ore"
	icon_state = "ore_silver"
//	origin_tech = list(TECH_MATERIAL = 3)

/obj/item/weapon/ore/gold
	name = "gold ore"
	icon_state = "ore_gold"
//	origin_tech = list(TECH_MATERIAL = 4)

/obj/item/weapon/ore/diamond
	name = "diamonds"
	icon_state = "ore_diamond"
//	origin_tech = list(TECH_MATERIAL = 6)

/obj/item/weapon/ore/New()
	pixel_x = rand(0,16)-8
	pixel_y = rand(0,8)-8