#define NO_WINNER "No ship has been captured."
/obj/map_metadata/naval
	ID = MAP_NAVAL
	title = "Naval Battle (75x75x4)"
//	lobby_icon_state = "pirates"
	caribbean_blocking_area_types = list(/area/caribbean/no_mans_land/invisible_wall/)
	respawn_delay = 0
	squad_spawn_locations = FALSE
	reinforcements = FALSE
//	min_autobalance_players = 90
	faction_organization = list(
		BRITISH,
		PIRATES)
	available_subfactions = list(
		)
	roundend_condition_sides = list(
		list(BRITISH) = /area/caribbean/british/ship/lower,
		list(PIRATES) = /area/caribbean/pirates/ship/lower
		)
	front = "Pacific"
	faction_distribution_coeffs = list(BRITISH = 0.4, PIRATES = 0.6)
//	songs = list(
//		"He's a Pirate:1" = 'sound/music/hes_a_pirate.ogg')
//	meme = TRUE
	battle_name = "Naval boarding"
	mission_start_message = "<font size=4>All factions have <b>5 minutes</b> to prepare before the combat starts.</font>"
/*	var/done = FALSE
/obj/map_metadata/naval/check_events()
	if ((world.time >= 300) && !done)
		world << "Pirates are approaching!"
		for (var/obj/effect/area_teleporter/AT)
			AT.Activated()
			world << "Pirates are trying to board the ship!"
			done = TRUE
			return TRUE
	else return FALSE
*/
/obj/map_metadata/naval/british_can_cross_blocks()
	return (processes.ticker.playtime_elapsed >= 3000 || admin_ended_all_grace_periods)

/obj/map_metadata/naval/pirates_can_cross_blocks()
	return (processes.ticker.playtime_elapsed >= 3000 || admin_ended_all_grace_periods)

/obj/map_metadata/naval/reinforcements_ready()
	return (british_can_cross_blocks() && pirates_can_cross_blocks())

#undef NO_WINNER