

/material/plasteel/generate_recipes()
	..()
	recipes += new/datum/stack_recipe("Metal crate", /obj/structure/closet/crate, 10, _time = 35, _one_per_turf = TRUE)
	recipes += new/datum/stack_recipe("dark floor tile", /obj/item/stack/tile/floor/dark, TRUE, 4, 20)

/material/sandstone/generate_recipes()
	..()

/material/plastic/generate_recipes()
	..()
	recipes += new/datum/stack_recipe("plastic bag", /obj/item/weapon/storage/bag/plasticbag, 3, _on_floor = TRUE)

	recipes += new/datum/stack_recipe("white floor tile", /obj/item/stack/tile/floor/white, TRUE, 4, 20)


/material/cardboard/generate_recipes()
	..()
	recipes += new/datum/stack_recipe("box", /obj/item/weapon/storage/box)
	recipes += new/datum/stack_recipe("donut box", /obj/item/weapon/storage/box/donut/empty)
	recipes += new/datum/stack_recipe("egg box", /obj/item/weapon/storage/fancy/egg_box)
//	recipes += new/datum/stack_recipe("cardborg suit", /obj/item/clothing/suit/cardborg, 3)
//	recipes += new/datum/stack_recipe("cardborg helmet", /obj/item/clothing/head/cardborg)
//	recipes += new/datum/stack_recipe("pizza box", /obj/item/pizzabox)
	recipes += new/datum/stack_recipe_list("folders",list( \
		new/datum/stack_recipe("blue folder", /obj/item/weapon/folder/blue), \
		new/datum/stack_recipe("grey folder", /obj/item/weapon/folder), \
		new/datum/stack_recipe("red folder", /obj/item/weapon/folder/red), \
		new/datum/stack_recipe("white folder", /obj/item/weapon/folder/white), \
		new/datum/stack_recipe("yellow folder", /obj/item/weapon/folder/yellow), \
		))

//	recipes += new/datum/stack_recipe("light fixture frame", /obj/item/frame/light, 2)
//	recipes += new/datum/stack_recipe("small light fixture frame", /obj/item/frame/light/small, TRUE)
