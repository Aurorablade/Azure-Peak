/datum/round_event_control/graggar_punch
	name = "Graggar's Rage"
	track = EVENT_TRACK_PERSONAL
	typepath = /datum/round_event/graggar_punch
	weight = 7
	earliest_start = 20 MINUTES
	max_occurrences = 1
	min_players = 30

	tags = list(
		TAG_BLOOD,
		TAG_BATTLE,
	)

/datum/round_event_control/graggar_punch/canSpawnEvent(players_amt, gamemode, fake_check)
	. = ..()
	if(!.)
		return FALSE

	for(var/mob/living/carbon/human/H in GLOB.player_list)
		if(!istype(H) || H.stat == DEAD || !H.client)
			continue
		if(!H.patron || !istype(H.patron, /datum/patron/inhumen/graggar))
			continue
		return TRUE

	return FALSE

/datum/round_event/graggar_punch/start()
	var/list/valid_targets = list()

	for(var/mob/living/carbon/human/human_mob in GLOB.player_list)
		if(!istype(human_mob) || human_mob.stat == DEAD || !human_mob.client)
			continue
		if(!human_mob.patron || !istype(human_mob.patron, /datum/patron/inhumen/graggar))
			continue
		valid_targets += human_mob

	if(!valid_targets.len)
		return

	var/mob/living/carbon/human/chosen_one = pick(valid_targets)

	var/datum/objective/punch_people/new_objective = new(owner = chosen_one.mind)
	chosen_one.mind.add_personal_objective(new_objective)

	to_chat(chosen_one, span_userdanger("YOU ARE GOD'S CHOSEN!"))
	to_chat(chosen_one, span_biginfo("[new_objective.explanation_text]"))
	chosen_one.playsound_local(chosen_one, 'sound/ambience/noises/genspooky (1).ogg', 100)

	chosen_one.mind.announce_personal_objectives()
