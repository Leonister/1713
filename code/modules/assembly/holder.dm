/obj/item/assembly_holder
	name = "Assembly"
	icon = 'icons/obj/assemblies/new_assemblies.dmi'
	icon_state = "holder"
	item_state = "assembly"
	flags = CONDUCT | PROXMOVE
	throwforce = 5
	w_class = 2.0
	throw_speed = 3
	throw_range = 10

	var/secured = FALSE
	var/obj/item/assembly/a_left = null
	var/obj/item/assembly/a_right = null
	var/obj/special_assembly = null

	proc/attach(var/obj/item/D, var/obj/item/D2, var/mob/user)
		return

	proc/attach_special(var/obj/O, var/mob/user)
		return

	proc/process_activation(var/obj/item/D)
		return

	proc/detached()
		return

	attach(var/obj/item/D, var/obj/item/D2, var/mob/user)
		if ((!D)||(!D2))	return FALSE
		if ((!isassembly(D))||(!isassembly(D2)))	return FALSE
		if ((D:secured)||(D2:secured))	return FALSE
		if (user)
			user.remove_from_mob(D)
			user.remove_from_mob(D2)
		D:holder = src
		D2:holder = src
		D.loc = src
		D2.loc = src
		a_left = D
		a_right = D2
		name = "[D.name]-[D2.name] assembly"
		update_icon()
		usr.put_in_hands(src)

		return TRUE


	attach_special(var/obj/O, var/mob/user)
		if (!O)	return
		if (!O.IsSpecialAssembly())	return FALSE

/*		if (O:Attach_Holder())
			special_assembly = O
			update_icon()
			name = "[a_left.name] [a_right.name] [special_assembly.name] assembly"
*/
		return


	update_icon()
		overlays.Cut()
		if (a_left)
			overlays += "[a_left.icon_state]_left"
			for (var/O in a_left.attached_overlays)
				overlays += "[O]_l"
		if (a_right)
			overlays += "[a_right.icon_state]_right"
			for (var/O in a_right.attached_overlays)
				overlays += "[O]_r"
		if (master)
			master.update_icon()

/*		if (special_assembly)
			special_assembly.update_icon()
			if (special_assembly:small_icon_state)
				overlays += special_assembly:small_icon_state
				for (var/O in special_assembly:small_icon_state_overlays)
					overlays += O
*/

	examine(mob/user)
		..(user)
		if ((in_range(src, user) || loc == user))
			if (secured)
				user << "\The [src] is ready!"
			else
				user << "\The [src] can be attached!"
		return


	HasProximity(atom/movable/AM as mob|obj)
		if (a_left)
			a_left.HasProximity(AM)
		if (a_right)
			a_right.HasProximity(AM)
		if (special_assembly)
			special_assembly.HasProximity(AM)


	Crossed(atom/movable/AM as mob|obj)
		if (a_left)
			a_left.Crossed(AM)
		if (a_right)
			a_right.Crossed(AM)
		if (special_assembly)
			special_assembly.Crossed(AM)


	on_found(mob/finder as mob)
		if (a_left)
			a_left.on_found(finder)
		if (a_right)
			a_right.on_found(finder)
		if (special_assembly)
			if (istype(special_assembly, /obj/item))
				var/obj/item/S = special_assembly
				S.on_found(finder)


	Move()
		..()
		if (a_left && a_right)
			a_left.holder_movement()
			a_right.holder_movement()
//		if (special_assembly)
//			special_assembly:holder_movement()
		return


	attack_hand()//Perhapse this should be a holder_pickup proc instead, can add if needbe I guess
		if (a_left && a_right)
			a_left.holder_movement()
			a_right.holder_movement()
//		if (special_assembly)
//			special_assembly:Holder_Movement()
		..()
		return


	attackby(obj/item/weapon/W as obj, mob/user as mob)
		if (isscrewdriver(W))
			if (!a_left || !a_right)
				user << "<span class = 'red'>BUG: Assembly part missing, please report this!</span>"
				return
			a_left.toggle_secure()
			a_right.toggle_secure()
			secured = !secured
			if (secured)
				user << "<span class = 'notice'>\The [src] is ready!</span>"
			else
				user << "<span class = 'notice'>\The [src] can now be taken apart!</span>"
			update_icon()
			return
		else if (W.IsSpecialAssembly())
			attach_special(W, user)
		else
			..()
		return


	attack_self(mob/user as mob)
		add_fingerprint(user)
		if (secured)
			if (!a_left || !a_right)
				user << "<span class = 'red'>Assembly part missing!</span>"
				return
			if (istype(a_left,a_right.type))//If they are the same type it causes issues due to window code
				switch(WWinput(user, "Which side would you like to use?", "Assembly", "Left", list("Left","Right")))
					if ("Left")	a_left.attack_self(user)
					if ("Right")	a_right.attack_self(user)
				return
		else
			var/turf/T = get_turf(src)
			if (!T)	return FALSE
			if (a_left)
				a_left:holder = null
				a_left.loc = T
			if (a_right)
				a_right:holder = null
				a_right.loc = T
			spawn(0)
				qdel(src)
		return


	process_activation(var/obj/D, var/normal = TRUE, var/special = TRUE)
		if (!D)	return FALSE
		if (!secured)
			visible_message("\icon[src] *beep* *beep*", "*beep* *beep*")
		if ((normal) && (a_right) && (a_left))
			if (a_right != D)
				a_right.pulsed(0)
			if (a_left != D)
				a_left.pulsed(0)
	//	if (master)
		//	master.receive_signal()
//		if (special && special_assembly)
//			if (!special_assembly == D)
//				special_assembly.dothings()
		return TRUE


/obj/item/assembly_holder/hear_talk(mob/living/M as mob, msg, verb, datum/language/speaking)
	if (a_right)
		a_right.hear_talk(M,msg,verb,speaking)
	if (a_left)
		a_left.hear_talk(M,msg,verb,speaking)