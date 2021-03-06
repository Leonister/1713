#define SOLID TRUE
#define LIQUID 2
#define GAS 3

#define chemical_dispenser_ENERGY_COST	0.1	//How many energy points do we use per unit of chemical?
#define BOTTLE_SPRITES list("bottle-1", "bottle-2", "bottle-3", "bottle-4") //list of available bottle sprites
#define REAGENTS_PER_SHEET 20


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


/obj/structure/chemical_dispenser
	name = "chem dispenser"
	density = TRUE
	anchored = TRUE
	icon = 'icons/obj/chemical.dmi'
	icon_state = "dispenser"
//	use_power = FALSE
//	idle_power_usage = 40
	var/ui_title = "Chem Dispenser 5000"
	var/energy = 100
	var/max_energy = 100
	var/amount = 30
	var/accept_glass = FALSE //At FALSE ONLY accepts glass containers. Kinda misleading varname.
	var/atom/beaker = null
	var/hackedcheck = FALSE
	var/list/dispensable_reagents = list("hydrazine","lithium","carbon","ammonia","acetone",
	"sodium","aluminum","silicon","phosphorus","sulfur","hclacid","potassium","iron",
	"copper","mercury","radium","water","ethanol","sugar","sacid","tungsten")
	var/stat = 0

/obj/structure/chemical_dispenser/New()
	..()
	processing_objects += src

/obj/structure/chemical_dispenser/proc/recharge()
	if (stat & BROKEN)
		return
	if (!processes.obj)
		return
	var/addenergy = 1
	var/oldenergy = energy
	energy = min(energy + addenergy, max_energy)
	if (energy != oldenergy)
//		use_power(CHEM_SYNTH_ENERGY / chemical_dispenser_ENERGY_COST) // This thing uses up "alot" of power (this is still low as shit for creating reagents from thin air)
		nanomanager.update_uis(src) // update all UIs attached to src

/*
/obj/structure/chemical_dispenser/power_change()
	..()
	nanomanager.update_uis(src) // update all UIs attached to src
*/

/obj/structure/chemical_dispenser/process()
	recharge()

	if (stat & BROKEN)
		icon_state = "dispenser_broken"
	else
		icon_state = initial(icon_state)

/obj/structure/chemical_dispenser/New()
	..()
	recharge()
	dispensable_reagents = sortList(dispensable_reagents)

/obj/structure/chemical_dispenser/ex_act(severity)
	switch(severity)
		if (1.0)
			del(src)
			return
		if (2.0)
			if (prob(50))
				del(src)
				return


 /**
  * The ui_interact proc is used to open and update Nano UIs
  * If ui_interact is not used then the UI will not update correctly
  * ui_interact is currently defined for /atom/movable
  *
  * @param user /mob The mob who is interacting with this ui
  * @param ui_key string A string key to use for this ui. Allows for multiple unique uis on one obj/mob (defaut value "main")
  *
  * @return nothing
  */
/obj/structure/chemical_dispenser/ui_interact(mob/user, ui_key = "main",var/datum/nanoui/ui = null, var/force_open = TRUE)
	if (stat & (BROKEN|NOPOWER)) return
	if (user.stat || user.restrained()) return
	var/mob/living/carbon/human/H = user
	if (istype(H) && H.getStatCoeff("medical") < GET_MIN_STAT_COEFF(STAT_MEDIUM_HIGH))
		H << "<span class = 'danger'>This machinery is too complex for you to understand.</span>"
		return
	// this is the data which will be sent to the ui
	var/data[0]
	data["amount"] = amount
	data["energy"] = round(energy)
	data["maxEnergy"] = round(max_energy)
	data["isBeakerLoaded"] = beaker ? TRUE : FALSE
	data["glass"] = accept_glass
	var beakerContents[0]
	var beakerCurrentVolume = FALSE
	if (beaker && beaker:reagents && beaker:reagents.reagent_list.len)
		for (var/datum/reagent/R in beaker:reagents.reagent_list)
			beakerContents.Add(list(list("name" = R.name, "volume" = R.volume))) // list in a list because Byond merges the first list...
			beakerCurrentVolume += R.volume
	data["beakerContents"] = beakerContents

	if (beaker)
		data["beakerCurrentVolume"] = beakerCurrentVolume
		data["beakerMaxVolume"] = beaker:volume
	else
		data["beakerCurrentVolume"] = null
		data["beakerMaxVolume"] = null

	var chemicals[0]
	for (var/re in dispensable_reagents)
		var/datum/reagent/temp = chemical_reagents_list[re]
		if (temp)
			chemicals.Add(list(list("title" = temp.name, "id" = temp.id, "commands" = list("dispense" = temp.id)))) // list in a list because Byond merges the first list...
	data["chemicals"] = chemicals

	// update the ui if it exists, returns null if no ui is passed/found
	ui = nanomanager.try_update_ui(user, src, ui_key, ui, data, force_open)
	if (!ui)
		// the ui does not exist, so we'll create a new() one
        // for a list of parameters and their descriptions see the code docs in \code\modules\nano\nanoui.dm
		ui = new(user, src, ui_key, "chem_disp.tmpl", ui_title, 390, 655)
		// when the ui is first opened this is the data it will use
		ui.set_initial_data(data)
		// open the new ui window
		ui.open()

/obj/structure/chemical_dispenser/Topic(href, href_list)
	if (stat & (NOPOWER|BROKEN))
		return FALSE // don't update UIs attached to this object

	if (href_list["amount"])
		amount = round(text2num(href_list["amount"]), 5) // round to nearest 5
		if (amount < 0) // Since the user can actually type the commands himself, some sanity checking
			amount = FALSE
		if (amount > 120)
			amount = 120

	if (href_list["dispense"])
		if (dispensable_reagents.Find(href_list["dispense"]) && beaker != null && beaker.is_open_container())
			var/obj/item/weapon/reagent_containers/B = beaker
			var/datum/reagents/R = B.reagents
			var/space = R.maximum_volume - R.total_volume

			//uses TRUE energy per 10 units.
			var/added_amount = min(amount, energy / chemical_dispenser_ENERGY_COST, space)
			R.add_reagent(href_list["dispense"], added_amount)
			energy = max(energy - added_amount * chemical_dispenser_ENERGY_COST, FALSE)

	if (href_list["ejectBeaker"])
		if (beaker)
			var/obj/item/weapon/reagent_containers/B = beaker
			B.loc = loc
			beaker = null

	add_fingerprint(usr)
	return TRUE // update UIs attached to this object

/obj/structure/chemical_dispenser/attackby(var/obj/item/weapon/reagent_containers/B as obj, var/mob/user as mob)
	if (beaker)
		user << "Something is already loaded into the machine."
		return
	if (istype(B, /obj/item/weapon/reagent_containers/glass) || istype(B, /obj/item/weapon/reagent_containers/food))
		if (!accept_glass && istype(B,/obj/item/weapon/reagent_containers/food))
			user << "<span class='notice'>This machine only accepts beakers</span>"
		beaker =  B
		user.drop_item()
		B.loc = src
		user << "You set [B] on the machine."
		nanomanager.update_uis(src) // update all UIs attached to src
		return

/obj/structure/chemical_dispenser/attack_hand(mob/user as mob)
	if (stat & BROKEN)
		return
	ui_interact(user)
/*
/obj/structure/chemical_dispenser/soda
	icon_state = "soda_dispenser"
	name = "soda fountain"
	desc = "A drink fabricating machine, capable of producing many sugary drinks with just one touch."
	ui_title = "Soda Dispens-o-matic"
	energy = 100
	accept_glass = TRUE
	max_energy = 100
	dispensable_reagents = list("water","ice","coffee","cream","tea","icetea","cola","spacemountainwind","dr_gibb","space_up","tonic","sodawater","lemon_lime","sugar","orangejuice","limejuice","watermelonjuice")

/obj/structure/chemical_dispenser/soda/attackby(var/obj/item/weapon/B as obj, var/mob/user as mob)
	..()
	if (istype(B, /obj/item/multitool))
		if (hackedcheck == FALSE)
			user << "You change the mode from 'McNano' to 'Pizza King'."
			dispensable_reagents += list("thirteenloko","grapesoda")
			hackedcheck = TRUE
			return

		else
			user << "You change the mode from 'Pizza King' to 'McNano'."
			dispensable_reagents -= list("thirteenloko","grapesoda")
			hackedcheck = FALSE
			return
*/
/obj/structure/chemical_dispenser/beer
	icon_state = "booze_dispenser"
	name = "booze dispenser"
	ui_title = "Booze Portal 9001"
	energy = 100
	accept_glass = TRUE
	max_energy = 100
	desc = "A technological marvel, supposedly able to mix just the mixture you'd like to drink the moment you ask for one."
	dispensable_reagents = list("lemon_lime","sugar","orangejuice","limejuice","sodawater","tonic","beer","kahlua","whiskey","wine","vodka","gin","rum","tequilla","vermouth","cognac","ale","mead")

/obj/structure/chemical_dispenser/beer/attackby(var/obj/item/weapon/B as obj, var/mob/user as mob)
	..()
/*
	if (istype(B, /obj/item/multitool))
		if (hackedcheck == FALSE)
			user << "You disable the 'nanotrasen-are-cheap-bastards' lock, enabling hidden and very expensive boozes."
			dispensable_reagents += list("goldschlager","patron","watermelonjuice","berryjuice")
			hackedcheck = TRUE
			return

		else
			user << "You re-enable the 'nanotrasen-are-cheap-bastards' lock, disabling hidden and very expensive boozes."
			dispensable_reagents -= list("goldschlager","patron","watermelonjuice","berryjuice")
			hackedcheck = FALSE
			return*/

/obj/structure/chemical_dispenser/meds
	name = "chem dispenser magic"
	density = TRUE
	anchored = TRUE
	icon = 'icons/obj/chemical.dmi'
	icon_state = "dispenser"
//	use_power = FALSE
//	idle_power_usage = 40
	ui_title = "Chem Dispenser 9000"
	energy = 100
	max_energy = 100
	amount = 30
	accept_glass = FALSE //At FALSE ONLY accepts glass containers. Kinda misleading varname.
	beaker = null
	hackedcheck = FALSE
	dispensable_reagents = list("inaprovaline","ryetalyn","paracetamol","tramadol","oxycodone","sterilizine","leporazine","kelotane","dermaline","dexalin","dexalinp","tricordrazine","anti_toxin","synaptizine","hyronalin","arithrazine","alkysine","imidazoline","peridaxon","bicaridine","hyperzine","rezadone","penicillin","ethylredoxrazine","stoxin","chloralhydrate","cryoxadone","clonexadone")

/obj/structure/chem_master
	name = "ChemMaster 3000"
	density = TRUE
	anchored = TRUE
	icon = 'icons/obj/chemical.dmi'
	icon_state = "mixer0"
//	use_power = TRUE
//	idle_power_usage = 20
	var/beaker = null
	var/obj/item/weapon/storage/pill_bottle/loaded_pill_bottle = null
	var/mode = FALSE
	var/condi = FALSE
	var/useramount = 30 // Last used amount
	var/pillamount = 10
	var/bottlesprite = "bottle" //yes, strings
	var/pillsprite = "1"
	var/client/has_sprites = list()
	var/max_pill_count = 20
	flags = OPENCONTAINER

/obj/structure/chem_master/New()
	..()
	var/datum/reagents/R = new/datum/reagents(120)
	reagents = R
	R.my_atom = src

/obj/structure/chem_master/ex_act(severity)
	switch(severity)
		if (1.0)
			qdel(src)
			return
		if (2.0)
			if (prob(50))
				qdel(src)
				return

/obj/structure/chem_master/attackby(var/obj/item/weapon/B as obj, var/mob/user as mob)

	if (istype(B, /obj/item/weapon/reagent_containers/glass))

		if (beaker)
			user << "A beaker is already loaded into the machine."
			return
		beaker = B
		user.drop_item()
		B.loc = src
		user << "You add the beaker to the machine!"
		updateUsrDialog()
		icon_state = "mixer1"

	else if (istype(B, /obj/item/weapon/storage/pill_bottle))

		if (loaded_pill_bottle)
			user << "A pill bottle is already loaded into the machine."
			return

		loaded_pill_bottle = B
		user.drop_item()
		B.loc = src
		user << "You add the pill bottle into the dispenser slot!"
		updateUsrDialog()
	return

/obj/structure/chem_master/Topic(href, href_list)
	if (..())
		return TRUE

	if (href_list["ejectp"])
		if (loaded_pill_bottle)
			loaded_pill_bottle.loc = loc
			loaded_pill_bottle = null
	else if (href_list["close"])
		usr << browse(null, "window=chemmaster")
		usr.unset_using_object()
		return

	if (beaker)
		var/datum/reagents/R = beaker:reagents
		if (href_list["analyze"])
			var/dat = ""
			if (!condi)
				if (href_list["name"] == "Blood")
					var/datum/reagent/blood/G
					for (var/datum/reagent/F in R.reagent_list)
						if (F.name == href_list["name"])
							G = F
							break
					var/A = G.name
					var/B = G.data["blood_type"]
					var/C = G.data["blood_DNA"]
					dat += "<TITLE>Chemmaster 3000</TITLE>Chemical infos:<BR><BR>Name:<BR>[A]<BR><BR>Description:<BR>Blood Type: [B]<br>DNA: [C]<BR><BR><BR><A href='?src=\ref[src];main=1'>(Back)</A>"
				else
					dat += "<TITLE>Chemmaster 3000</TITLE>Chemical infos:<BR><BR>Name:<BR>[href_list["name"]]<BR><BR>Description:<BR>[href_list["desc"]]<BR><BR><BR><A href='?src=\ref[src];main=1'>(Back)</A>"
			else
				dat += "<TITLE>Condimaster 3000</TITLE>Condiment infos:<BR><BR>Name:<BR>[href_list["name"]]<BR><BR>Description:<BR>[href_list["desc"]]<BR><BR><BR><A href='?src=\ref[src];main=1'>(Back)</A>"
			usr << browse(dat, "window=chem_master;size=575x400")
			return

		else if (href_list["add"])

			if (href_list["amount"])
				var/id = href_list["add"]
				var/amount = Clamp((text2num(href_list["amount"])), FALSE, 200)
				R.trans_id_to(src, id, amount)

		else if (href_list["addcustom"])

			var/id = href_list["addcustom"]
			useramount = input("Select the amount to transfer.", 30, useramount) as num
			useramount = Clamp(useramount, FALSE, 200)
			Topic(null, list("amount" = "[useramount]", "add" = "[id]"))

		else if (href_list["remove"])

			if (href_list["amount"])
				var/id = href_list["remove"]
				var/amount = Clamp((text2num(href_list["amount"])), FALSE, 200)
				if (mode)
					reagents.trans_id_to(beaker, id, amount)
				else
					reagents.remove_reagent(id, amount)


		else if (href_list["removecustom"])

			var/id = href_list["removecustom"]
			useramount = input("Select the amount to transfer.", 30, useramount) as num
			useramount = Clamp(useramount, FALSE, 200)
			Topic(null, list("amount" = "[useramount]", "remove" = "[id]"))

		else if (href_list["toggle"])
			mode = !mode

		else if (href_list["main"])
			attack_hand(usr)
			return
		else if (href_list["eject"])
			if (beaker)
				beaker:loc = loc
				beaker = null
				reagents.clear_reagents()
				icon_state = "mixer0"
		else if (href_list["createpill"] || href_list["createpill_multiple"])
			var/count = TRUE

			if (reagents.total_volume/count < 1) //Sanity checking.
				return

			if (href_list["createpill_multiple"])
				count = input("Select the number of pills to make.", "Max [max_pill_count]", pillamount) as num
				count = Clamp(count, TRUE, max_pill_count)

			if (reagents.total_volume/count < 1) //Sanity checking.
				return

			var/amount_per_pill = reagents.total_volume/count
			if (amount_per_pill > 60) amount_per_pill = 60

			var/name = sanitizeSafe(input(usr,"Name:","Name your pill!","[reagents.get_master_reagent_name()] ([amount_per_pill] units)"), MAX_NAME_LEN)

			if (reagents.total_volume/count < 1) //Sanity checking.
				return
			while (count--)
				var/obj/item/weapon/reagent_containers/pill/P = new/obj/item/weapon/reagent_containers/pill(loc)
				if (!name) name = reagents.get_master_reagent_name()
				P.name = "[name] pill"
				P.pixel_x = rand(-7, 7) //random position
				P.pixel_y = rand(-7, 7)
				P.icon_state = "pill"+pillsprite
				reagents.trans_to_obj(P,amount_per_pill)
				if (loaded_pill_bottle)
					if (loaded_pill_bottle.contents.len < loaded_pill_bottle.storage_slots)
						P.loc = loaded_pill_bottle
						updateUsrDialog()

		else if (href_list["createbottle"])
			if (!condi)
				var/name = sanitizeSafe(input(usr,"Name:","Name your bottle!",reagents.get_master_reagent_name()), MAX_NAME_LEN)
				var/obj/item/weapon/reagent_containers/glass/bottle/P = new/obj/item/weapon/reagent_containers/glass/bottle(loc)
				if (!name) name = reagents.get_master_reagent_name()
				P.name = "[name] bottle"
				P.pixel_x = rand(-7, 7) //random position
				P.pixel_y = rand(-7, 7)
				P.icon_state = bottlesprite
				reagents.trans_to_obj(P,60)
				P.update_icon()
			else
				var/obj/item/weapon/reagent_containers/food/condiment/P = new/obj/item/weapon/reagent_containers/food/condiment(loc)
				reagents.trans_to_obj(P,50)
		else if (href_list["change_pill"])
			#define MAX_PILL_SPRITE 20 //max icon state of the pill sprites
			var/dat = "<table>"
			for (var/i = TRUE to MAX_PILL_SPRITE)
				dat += "<tr><td><a href=\"?src=\ref[src]&pill_sprite=[i]\"><img src=\"pill[i].png\" /></a></td></tr>"
			dat += "</table>"
			usr << browse(dat, "window=chem_master")
			return
		else if (href_list["change_bottle"])
			var/dat = "<table>"
			for (var/sprite in BOTTLE_SPRITES)
				dat += "<tr><td><a href=\"?src=\ref[src]&bottle_sprite=[sprite]\"><img src=\"[sprite].png\" /></a></td></tr>"
			dat += "</table>"
			usr << browse(dat, "window=chem_master")
			return
		else if (href_list["pill_sprite"])
			pillsprite = href_list["pill_sprite"]
		else if (href_list["bottle_sprite"])
			bottlesprite = href_list["bottle_sprite"]

	playsound(loc, 'sound/machines/button.ogg', 100, TRUE)
	updateUsrDialog()
	return

/obj/structure/chem_master/attack_hand(mob/user as mob)
	user.set_using_object(src)
	if (!(user.client in has_sprites))
		spawn()
			has_sprites += user.client
			for (var/i = TRUE to MAX_PILL_SPRITE)
				usr << browse_rsc(icon('icons/obj/chemical.dmi', "pill" + num2text(i)), "pill[i].png")
			for (var/sprite in BOTTLE_SPRITES)
				usr << browse_rsc(icon('icons/obj/chemical.dmi', sprite), "[sprite].png")
	var/dat = ""
	if (!beaker)
		dat = "Please insert beaker.<BR>"
		if (loaded_pill_bottle)
			dat += "<A href='?src=\ref[src];ejectp=1'>Eject Pill Bottle \[[loaded_pill_bottle.contents.len]/[loaded_pill_bottle.storage_slots]\]</A><BR><BR>"
		else
			dat += "No pill bottle inserted.<BR><BR>"
		dat += "<A href='?src=\ref[src];close=1'>Close</A>"
	else
		var/datum/reagents/R = beaker:reagents
		dat += "<A href='?src=\ref[src];eject=1'>Eject beaker and Clear Buffer</A><BR>"
		if (loaded_pill_bottle)
			dat += "<A href='?src=\ref[src];ejectp=1'>Eject Pill Bottle \[[loaded_pill_bottle.contents.len]/[loaded_pill_bottle.storage_slots]\]</A><BR><BR>"
		else
			dat += "No pill bottle inserted.<BR><BR>"
		if (!R.total_volume)
			dat += "Beaker is empty."
		else
			dat += "Add to buffer:<BR>"
			for (var/datum/reagent/G in R.reagent_list)
				dat += "[G.name] , [G.volume] Units - "
				dat += "<A href='?src=\ref[src];analyze=1;desc=[G.description];name=[G.name]'>(Analyze)</A> "
				dat += "<A href='?src=\ref[src];add=[G.id];amount=1'>(1)</A> "
				dat += "<A href='?src=\ref[src];add=[G.id];amount=5'>(5)</A> "
				dat += "<A href='?src=\ref[src];add=[G.id];amount=10'>(10)</A> "
				dat += "<A href='?src=\ref[src];add=[G.id];amount=[G.volume]'>(All)</A> "
				dat += "<A href='?src=\ref[src];addcustom=[G.id]'>(Custom)</A><BR>"

		dat += "<HR>Transfer to <A href='?src=\ref[src];toggle=1'>[(!mode ? "disposal" : "beaker")]:</A><BR>"
		if (reagents.total_volume)
			for (var/datum/reagent/N in reagents.reagent_list)
				dat += "[N.name] , [N.volume] Units - "
				dat += "<A href='?src=\ref[src];analyze=1;desc=[N.description];name=[N.name]'>(Analyze)</A> "
				dat += "<A href='?src=\ref[src];remove=[N.id];amount=1'>(1)</A> "
				dat += "<A href='?src=\ref[src];remove=[N.id];amount=5'>(5)</A> "
				dat += "<A href='?src=\ref[src];remove=[N.id];amount=10'>(10)</A> "
				dat += "<A href='?src=\ref[src];remove=[N.id];amount=[N.volume]'>(All)</A> "
				dat += "<A href='?src=\ref[src];removecustom=[N.id]'>(Custom)</A><BR>"
		else
			dat += "Empty<BR>"
		if (!condi)
			dat += "<HR><BR><A href='?src=\ref[src];createpill=1'>Create pill (60 units max)</A><a href=\"?src=\ref[src]&change_pill=1\"><img src=\"pill[pillsprite].png\" /></a><BR>"
			dat += "<A href='?src=\ref[src];createpill_multiple=1'>Create multiple pills</A><BR>"
			dat += "<A href='?src=\ref[src];createbottle=1'>Create bottle (60 units max)<a href=\"?src=\ref[src]&change_bottle=1\"><img src=\"[bottlesprite].png\" /></A>"
		else
			dat += "<A href='?src=\ref[src];createbottle=1'>Create bottle (50 units max)</A>"
	if (!condi)
		user << browse("<TITLE>Chemmaster 3000</TITLE>Chemmaster menu:<BR><BR>[dat]", "window=chem_master;size=575x400")
	else
		user << browse("<TITLE>Condimaster 3000</TITLE>Condimaster menu:<BR><BR>[dat]", "window=chem_master;size=575x400")
	onclose(user, "chem_master")
	return

/obj/structure/chem_master/condimaster
	name = "CondiMaster 3000"
	condi = TRUE

#undef REAGENTS_PER_SHEET
