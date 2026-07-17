class_name GameRules
extends RefCounted

const TIMER_SECONDS: int = 300
const MAX_DAY: int = 7
const RIVER_SIZE: int = 7
const TURN_NAMES: Array[String] = ["Morning", "Afternoon", "Night", "Prep"]
const COUNTRY_CODES: Array[String] = ["IR", "IL", "JO", "PRC", "RU", "SA", "TR", "UN", "US"]
const UNITY_COUNTRY_TO_CODE: Dictionary = {
	1: "IL",
	2: "PRC",
	3: "RU",
	4: "SA",
	5: "UN",
	6: "JO",
	7: "TR",
	8: "US",
	9: "IR"
}
const POINT_KEYS: Array[String] = ["PP", "IP", "MP"]
const RED_AIRCRAFT_MISSIONS: Array[String] = ["Ready", "Alert", "Patrol", "Stand Down", "Rebasing"]
const BLUE_AIRCRAFT_MISSIONS: Array[String] = ["Ready", "Fragged", "In Flight 1", "In Flight 2", "Resting"]
const STRATEGIC_EVENT_NAMES: Dictionary = {
	1: "Domestic Scandal",
	2: "Freak Weather",
	3: "Industrial Accident",
	4: "Military Accident",
	5: "Bad Targeting",
	6: "Political Pressure",
	7: "War Hero Scandal",
	8: "Espionage Arrest",
	9: "Third-Party Troubles",
	10: "Intifada Erupts"
}
const CARD_METADATA_PATH: String = "res://Art/Data/card_metadata.json"
const UPGRADE_METADATA_PATH: String = "res://Art/Data/upgrade_metadata.json"
const AIRCRAFT_METADATA_PATH: String = "res://Art/Data/aircraft_metadata.json"
const TARGET_METADATA_PATH: String = "res://Art/Data/targets_metadata.json"
const POLITICAL_STATS_PATH: String = "res://Art/Data/new_political_track_stats.txt"
const DICE_LOG_LIMIT: int = 80
const TEAM_CARD_DATA: Dictionary = {
	"Red": {
		"start": 101,
		"end": 155,
		"deck": "_redCardDeck",
		"river": "_redCardRiver",
		"discard": "_redCardDiscard",
		"point_prefix": "Iran"
	},
	"Blue": {
		"start": 201,
		"end": 255,
		"deck": "_blueCardDeck",
		"river": "_blueCardRiver",
		"discard": "_blueCardDiscard",
		"point_prefix": "Isreal"
	}
}
const ROUTE_COUNTRY: Dictionary = {
	"Northern": "TR",
	"Central": "US",
	"Southern": "SA"
}
const PGM_WEAPONS: Dictionary = {
	"AGM-88 HARM": {"guidance": "ARM", "generation": 3, "hits": 0, "armor_pen": 0, "thresholds": [8, 8, 8, 8, 8, 8, 8], "radar": true},
	"EGBU-28B (GPS 1st)": {"guidance": "GPS", "generation": 1, "hits": 2, "armor_pen": 44, "thresholds": [8, 8, 8, 8, 7, 6, 4]},
	"EGBU-28B (GPS 2nd)": {"guidance": "GPS", "generation": 2, "hits": 2, "armor_pen": 44, "thresholds": [8, 8, 8, 8, 7, 6, 4]},
	"EGBU-28B (Laser)": {"guidance": "Laser", "generation": 3, "hits": 2, "armor_pen": 44, "thresholds": [8, 8, 8, 8, 8, 7, 4]},
	"EGBU-28C (GPS 1st)": {"guidance": "GPS", "generation": 1, "hits": 2, "armor_pen": 53, "thresholds": [8, 8, 8, 8, 7, 6, 4]},
	"EGBU-28C (GPS 2nd)": {"guidance": "GPS", "generation": 2, "hits": 2, "armor_pen": 53, "thresholds": [8, 8, 8, 8, 7, 6, 4]},
	"EGBU-28C (Laser)": {"guidance": "Laser", "generation": 3, "hits": 2, "armor_pen": 53, "thresholds": [8, 8, 8, 8, 8, 7, 4]},
	"GBU-31 JDAM": {"guidance": "GPS", "generation": 1, "hits": 2, "armor_pen": 5, "thresholds": [8, 8, 8, 8, 7, 6, 4]},
	"GBU-32 JDAM": {"guidance": "GPS", "generation": 1, "hits": 1, "armor_pen": 5, "thresholds": [8, 8, 8, 8, 7, 6, 4]},
	"GBU-38 JDAM": {"guidance": "GPS", "generation": 1, "hits": 1, "armor_pen": 5, "thresholds": [8, 8, 8, 8, 7, 6, 4]},
	"GBU-39 SDB": {"guidance": "GPS", "generation": 2, "hits": 1, "armor_pen": 9, "thresholds": [8, 8, 8, 8, 8, 7, 6]},
	"GBU-57": {"guidance": "GPS", "generation": 2, "hits": 3, "armor_pen": 105, "thresholds": [8, 8, 8, 8, 8, 7, 6]},
	"Guillotine": {"guidance": "Laser", "generation": 3, "hits": 2, "armor_pen": 5, "thresholds": [8, 8, 8, 8, 8, 7, 5]},
	"SPICE 2000": {"guidance": "GPS&EO", "generation": 2, "hits": 2, "armor_pen": 7, "thresholds": [8, 8, 8, 8, 8, 7, 6]},
	"STAR-1": {"guidance": "ARM", "generation": 3, "hits": 0, "armor_pen": 0, "thresholds": [8, 8, 8, 8, 8, 8, 8], "radar": true}
}
const BLUE_LOADOUTS: Dictionary = {
	"F16I": {
		"Strike - SPICE 2000": {"role": "Strike", "weapons": [{"name": "SPICE 2000", "quantity": 2}]},
		"Strike - Guillotine": {"role": "Strike", "weapons": [{"name": "Guillotine", "quantity": 2}]},
		"Escort": {"role": "Escort", "weapons": []},
		"SEAD - AGM-88 HARM": {"role": "SEAD", "weapons": [{"name": "AGM-88 HARM", "quantity": 2}]},
		"SEAD - STAR-1": {"role": "SEAD", "weapons": [{"name": "STAR-1", "quantity": 2}]}
	},
	"F15I": {
		"Light Strike - GBU-39": {"role": "Strike", "weapons": [{"name": "GBU-39 SDB", "quantity": 8}]},
		"Light Strike - Guillotine": {"role": "Strike", "weapons": [{"name": "Guillotine", "quantity": 2}]},
		"Strike - GBU-31": {"role": "Strike", "weapons": [{"name": "GBU-31 JDAM", "quantity": 4}]},
		"Heavy Strike - EGBU-28C": {"role": "Strike", "weapons": [{"name": "EGBU-28C (GPS 2nd)", "quantity": 1}, {"name": "GBU-31 JDAM", "quantity": 2}]}
	}
}
const TANKERS_PER_SQUADRON: Dictionary = {
	"F16I": {
		"Escort": {"Northern": 2, "Central": 1, "Southern": 1},
		"SEAD": {"Northern": 2, "Central": 2, "Southern": 2},
		"Strike": {"Northern": 2, "Central": 2, "Southern": 2}
	},
	"F15I": {
		"Strike": {"Northern": 4, "Central": 2, "Southern": 3}
	}
}
const FIGHTER_SUPPRESSION_TABLE: Array = [
	[0, 0, 0, -1, -1, -2],
	[0, 0, -1, -1, -1, -2],
	[0, -1, -1, -1, -1, -2],
	[-1, -1, -1, -1, -2, -2],
	[-1, -1, -1, -2, -2, -2],
	[-1, -1, -2, -2, -2, -3],
	[-1, -2, -2, -2, -2, -3],
	[-2, -2, -2, -2, -3, -3],
	[-2, -2, -2, -3, -3, -3],
	[-2, -2, -3, -3, -3, -3],
	[-2, -3, -3, -3, -3, -3]
]
const SUTER_TABLE: Array = [
	["A", "A", "A"], ["A", "B", "B"], ["B", "B", "B"],
	["B", "B", "C"], ["B", "C", "C"], ["C", "C", "C"],
	["C", "C", "D"], ["C", "D", "D"], ["D", "D", "E"],
	["D", "E", "E"], ["E", "E", "F"]
]

static var _card_metadata_cache: Dictionary = {}
static var _political_stats_cache: Dictionary = {}
static var _upgrade_metadata_cache: Array = []
static var _aircraft_metadata_cache: Array = []
static var _target_metadata_cache: Array = []


static func make_default_snapshot() -> Dictionary:
	var snapshot := {
		"TurnDay": 0,
		"TurnTime": 3,
		"ChangeTeam": "White",
		"Move": 0,
		"PassCounter": 0,
		"TimerRunning": false,
		"TimerStarted": false,
		"TimeRemaining": TIMER_SECONDS,
		"OverallTime": 0,
		"ActionPending": false,
		"ActionTeam": "",
		"LastPlayedCard": 0,
		"LastCardTeam": "",
		"PendingCard": {},
		"RiverRevealForTeam": "",
		"SleeperAgentReady": {"Red": false, "Blue": false},
		"CardCounterTokens": {"RedIP": 0, "RedPP": 0, "BlueIP": 0, "BluePP": 0},
		"TrackLocks": {},
		"StrategicEventCancelled": false,
		"LastStrategicEventDay": -1,
		"StrategicEventQueue": [],
		"StrategicEventHistory": [],
		"PoliticalPressureDays": {"Red": 0, "Blue": 0},
		"WeatherRestriction": {},
		"LastOvertMapTurn": {"Red": -999, "Blue": -999},
		"BlueBunkerHill": false,
		"BlueBurkeDestroyer": false,
		"BallisticDefenseUsage": {
			"map_turn": -1,
			"sm3_missiles": 0,
			"arrow_missiles": 0,
			"pac3_missiles": 0
		},
		"BallisticBattalionCooldowns": [],
		"BallisticAttackHistory": [],
		"OverflightUsed": {"TR": false, "US": false, "SA": false},
		"TargetLastStrikeTurn": {},
		"TargetVictoryLevels": {},
		"TargetFractionalDamage": {},
		"AirstrikeHistory": [],
		"AirCombatHistory": [],
		"DestroyedRadars": [],
		"NuclearVictoryResults": [],
		"NuclearDecisiveSites": [],
		"OilVictoryResults": [],
		"VictoryRollHistory": [],
		"SuterAttackCount": 0,
		"StrategyVictory": {},
		"IsraeliTargetDamage": {
			"Urban": 0,
			"Airbase": 0,
			"Military Base": 0,
			"Missile Shelter": 0
		},
		"IsraeliStrategicMissilesDestroyed": 0,
		"BlueAircraftLosses": 0,
		"ConflictStarted": false,
		"StraitCooldown": 0,
		"StraitStatus": "Open",
		"LastMorningUpkeepDay": -1,
		"LastRedBreakdownTurn": "",
		"LastAircraftRepairDay": {"Red": -1, "Blue": -1},
		"NightPointGains": {
			"Red": {"IP": 0, "MP": 0, "PP": 0},
			"Blue": {"IP": 0, "MP": 0, "PP": 0}
		},
		"RedAircraftChangedIndices": [],
		"CampaignDays": MAX_DAY,
		"ScenarioName": "Standard",
		"LastRollSummary": "",
		"DiceLog": [],
		"IsrealIP": 0,
		"IsrealMP": 0,
		"IsrealPP": 0,
		"IranIP": 0,
		"IranMP": 0,
		"IranPP": 0,
		"TrackPlace": 0,
		"CountryName": "",
		"PoliticalTrack": _neutral_track(),
		"_blueCardRiver": "",
		"_blueCardDeck": "",
		"_blueCardDiscard": "",
		"_redCardRiver": "",
		"_redCardDeck": "",
		"_redCardDiscard": "",
		"RedRiverRightmostCard": 0,
		"BlueRiverRightmostCard": 0,
		"BlueUpgrades": "",
		"RedUpgrades": "",
		"SelectedUpgrades": {
			"Blue": [],
			"Red": [],
			"RedExtra": []
		},
		"UpgradePoints": {
			"Blue": 100,
			"Red": 100,
			"RedExtra": 40
		},
		"RedPOW": 0,
		"RedGCI": 0,
		"RedSAM": 0,
		"RedGCIMapTurn": 0,
		"RedLastCardDirty": false,
		"RedLastCardCovert": false,
		"RedLastActionOvert": false,
		"RedPRCSupport": false,
		"RedRussiaSupport": false,
		"BluePOW": 0,
		"BlueHitChance": 0,
		"BlueLastCardDirty": false,
		"BlueLastCardCovert": false,
		"BlueLastActionOvert": false,
		"BlueAirStrikeThisTurn": false,
		"BlueTurkeySupport": false,
		"BlueUSSupport": false,
		"BlueSaudiSupport": false,
		"PlannedActions": [],
		"RedAircraft": default_aircraft_for_team("Red"),
		"BlueAircraft": default_aircraft_for_team("Blue"),
		"AircraftEvents": [],
		"Notifications": [],
		"ActionLog": [],
		"Targets": default_targets_state(),
		"GameOver": false,
		"GameOverSummary": {}
	}
	return ensure_card_decks(snapshot, true)


static func apply_action(snapshot: Dictionary, action_name: String, args: Dictionary = {}) -> Dictionary:
	var next_snapshot := snapshot.duplicate(true)
	next_snapshot = ensure_card_decks(next_snapshot)
	var message := ""
	var ok := true

	match action_name:
		"start_timer":
			next_snapshot["TimerRunning"] = bool(args.get("running", true))
			next_snapshot["TimerStarted"] = true
			if bool(next_snapshot["TimerRunning"]) and int(next_snapshot.get("TimeRemaining", TIMER_SECONDS)) <= 0:
				next_snapshot["TimeRemaining"] = TIMER_SECONDS
			message = "Timer %s." % ("started" if bool(next_snapshot["TimerRunning"]) else "paused")
			_add_log(next_snapshot, "White %s the timer." % ("started" if bool(next_snapshot["TimerRunning"]) else "paused"))
		"reset_timer":
			_reset_timer(next_snapshot)
			message = "Timer reset."
			_add_log(next_snapshot, "White reset the timer.")
		"roll_dice":
			var dice_result := roll_dice(
				int(args.get("sides", 6)),
				int(args.get("count", 1)),
				str(args.get("label", "Dice"))
			)
			message = str(dice_result.get("summary", "Dice rolled."))
			next_snapshot["LastRollSummary"] = message
			_add_dice_log(next_snapshot, message)
			_add_log(next_snapshot, message)
		"tick_timer":
			var elapsed: int = maxi(0, int(args.get("elapsed", 0)))
			if bool(next_snapshot.get("TimerRunning", false)):
				next_snapshot["TimeRemaining"] = max(0, int(next_snapshot.get("TimeRemaining", TIMER_SECONDS)) - elapsed)
				next_snapshot["OverallTime"] = maxi(0, int(next_snapshot.get("OverallTime", 0)) + elapsed)
				if int(next_snapshot["TimeRemaining"]) <= 0:
					next_snapshot["TimerRunning"] = false
					_add_log(next_snapshot, "Timer reached 00:00.")
			message = "Timer updated."
		"change_day":
			if _has_unresolved_choice(next_snapshot):
				ok = false
				message = "Resolve the pending action or rules choice before changing the day."
			else:
				_change_day(next_snapshot, bool(args.get("next", true)))
				message = "Day changed."
				_add_log(next_snapshot, "White changed to %s." % turn_label(next_snapshot))
		"change_turn":
			if _has_unresolved_choice(next_snapshot):
				ok = false
				message = "Resolve the pending action or rules choice before changing the turn."
			else:
				_change_turn(next_snapshot, bool(args.get("next", true)))
				message = "Turn changed."
				_add_log(next_snapshot, "White changed to %s." % turn_label(next_snapshot))
		"set_team":
			var team_name := str(args.get("team", "White"))
			if not ["White", "Red", "Blue"].has(team_name):
				ok = false
				message = "Unknown team."
			else:
				_set_current_team(next_snapshot, team_name, bool(args.get("next_move", false)))
				message = "Current team set to %s." % team_name
				_add_log(next_snapshot, "White set current team to %s." % team_name)
		"swap_team":
			var current_team := str(next_snapshot.get("ChangeTeam", "White"))
			var next_team := "Red" if current_team == "Blue" else "Blue"
			_set_current_team(next_snapshot, next_team, true)
			message = "Team swapped to %s." % next_team
			_add_log(next_snapshot, "White swapped play to %s." % next_team)
		"take_action":
			var acting_team := str(args.get("team", next_snapshot.get("ChangeTeam", "")))
			var unresolved_card = next_snapshot.get("PendingCard", {})
			if unresolved_card is Dictionary and not (unresolved_card as Dictionary).is_empty():
				ok = false
				message = "Finish resolving the active card before submitting an action."
			elif acting_team != "Red" and acting_team != "Blue":
				ok = false
				message = "Only Red or Blue can submit an action."
			else:
				next_snapshot["ActionPending"] = true
				next_snapshot["ActionTeam"] = acting_team
				next_snapshot["TimerRunning"] = false
				next_snapshot["ChangeTeam"] = "White"
				message = "%s submitted an action for White review." % acting_team
				_add_log(next_snapshot, message)
		"approve_action":
			var approved := bool(args.get("approved", true))
			var action_team := str(next_snapshot.get("ActionTeam", next_snapshot.get("ChangeTeam", "Blue")))
			if action_team != "Red" and action_team != "Blue":
				action_team = "Blue"
			if approved:
				var next_team_after_approval := "Red" if action_team == "Blue" else "Blue"
				_set_current_team(next_snapshot, next_team_after_approval, true)
				message = "Action approved. %s to act." % next_team_after_approval
				_add_log(next_snapshot, "White approved %s's action." % action_team)
			else:
				_set_current_team(next_snapshot, action_team, false)
				message = "Action disapproved. %s keeps the move." % action_team
				_add_log(next_snapshot, "White disapproved %s's action." % action_team)
			next_snapshot["ActionPending"] = false
			next_snapshot["ActionTeam"] = ""
			next_snapshot["TimerRunning"] = true
			next_snapshot["TimerStarted"] = true
		"pass":
			var pass_team := str(args.get("team", next_snapshot.get("ChangeTeam", "")))
			var unresolved_card = next_snapshot.get("PendingCard", {})
			if unresolved_card is Dictionary and not (unresolved_card as Dictionary).is_empty():
				ok = false
				message = "Finish resolving the active card before passing."
			elif pass_team != "Red" and pass_team != "Blue":
				ok = false
				message = "Only Red or Blue can pass."
			else:
				_pass(next_snapshot, pass_team)
				message = "%s passed." % pass_team
				_add_log(next_snapshot, "%s passed the move." % pass_team)
		"draw_river":
			var draw_team := str(args.get("team", ""))
			var draw_result := draw_river(next_snapshot, draw_team)
			ok = bool(draw_result.get("ok", false))
			message = str(draw_result.get("message", ""))
			if ok:
				next_snapshot = draw_result.get("snapshot", next_snapshot)
				_add_log(next_snapshot, "White drew the %s card river." % draw_team)
		"reset_card_decks":
			next_snapshot = reset_card_decks(next_snapshot)
			message = "Card decks reset."
			_add_log(next_snapshot, "White reset both card decks.")
		"send_rivers":
			next_snapshot = draw_river(next_snapshot, "Red").get("snapshot", next_snapshot)
			next_snapshot = draw_river(next_snapshot, "Blue").get("snapshot", next_snapshot)
			message = "Red and Blue rivers sent."
			_add_log(next_snapshot, "White sent the current Red and Blue rivers.")
		"discard_card":
			var discard_result := discard_card(next_snapshot, str(args.get("team", "")), int(args.get("index", -1)))
			ok = bool(discard_result.get("ok", false))
			message = str(discard_result.get("message", ""))
			if ok:
				next_snapshot = discard_result.get("snapshot", next_snapshot)
		"play_card":
			var play_result := play_card(next_snapshot, str(args.get("team", "")), int(args.get("index", -1)))
			ok = bool(play_result.get("ok", false))
			message = str(play_result.get("message", ""))
			if ok:
				next_snapshot = play_result.get("snapshot", next_snapshot)
		"roll_card_country":
			var roll_result := roll_card_country(
				next_snapshot,
				str(args.get("team", "")),
				int(args.get("card_id", 0)),
				int(args.get("country_id", 0))
			)
			ok = bool(roll_result.get("ok", false))
			message = str(roll_result.get("message", ""))
			if ok:
				next_snapshot = roll_result.get("snapshot", next_snapshot)
		"resolve_card_action":
			var card_action_result := resolve_card_action(
				next_snapshot,
				str(args.get("team", "")),
				args
			)
			ok = bool(card_action_result.get("ok", false))
			message = str(card_action_result.get("message", ""))
			if ok:
				next_snapshot = card_action_result.get("snapshot", next_snapshot)
		"set_political_track":
			next_snapshot["PoliticalTrack"] = _clean_track(args.get("track", {}))
			_check_immediate_victory(next_snapshot)
			if bool(args.get("generate_points", false)):
				next_snapshot = generate_points_from_track(next_snapshot)
				message = "Political points generated."
				_add_log(next_snapshot, "White generated points from the political track.")
			else:
				message = "Political track saved."
				_add_log(next_snapshot, "White saved the political track.")
		"reset_political_track":
			next_snapshot["PoliticalTrack"] = _neutral_track()
			message = "Political track reset."
			_add_log(next_snapshot, "White reset the political track to neutral.")
		"adjust_points":
			var adjust_result := adjust_points(
				next_snapshot,
				str(args.get("team", "")),
				str(args.get("point", "")),
				int(args.get("amount", 0)),
				bool(args.get("set_value", false))
			)
			ok = bool(adjust_result.get("ok", false))
			message = str(adjust_result.get("message", ""))
			if ok:
				next_snapshot = adjust_result.get("snapshot", next_snapshot)
		"purchase_upgrade":
			var purchase_result := purchase_upgrade(next_snapshot, str(args.get("team", "")), str(args.get("upgrade", "")))
			ok = bool(purchase_result.get("ok", false))
			message = str(purchase_result.get("message", ""))
			if ok:
				next_snapshot = purchase_result.get("snapshot", next_snapshot)
		"refund_upgrade":
			var refund_result := refund_upgrade(next_snapshot, str(args.get("team", "")), int(args.get("index", -1)))
			ok = bool(refund_result.get("ok", false))
			message = str(refund_result.get("message", ""))
			if ok:
				next_snapshot = refund_result.get("snapshot", next_snapshot)
		"set_upgrades":
			next_snapshot["BlueUpgrades"] = str(args.get("blue", "")).strip_edges()
			next_snapshot["RedUpgrades"] = str(args.get("red", "")).strip_edges()
			message = "Upgrades confirmed." if bool(args.get("confirmed", false)) else "Upgrade review saved."
			_add_log(next_snapshot, "White confirmed final upgrades." if bool(args.get("confirmed", false)) else "White saved upgrade review.")
		"add_planned_action":
			var planned_result := add_planned_action(next_snapshot, args)
			ok = bool(planned_result.get("ok", false))
			message = str(planned_result.get("message", ""))
			if ok:
				next_snapshot = planned_result.get("snapshot", next_snapshot)
		"remove_planned_action":
			var remove_result := remove_planned_action(next_snapshot, int(args.get("index", -1)))
			ok = bool(remove_result.get("ok", false))
			message = str(remove_result.get("message", ""))
			if ok:
				next_snapshot = remove_result.get("snapshot", next_snapshot)
		"resolve_planned_action":
			var resolve_result := resolve_planned_action(next_snapshot, int(args.get("index", -1)))
			ok = bool(resolve_result.get("ok", false))
			message = str(resolve_result.get("message", ""))
			if ok:
				next_snapshot = resolve_result.get("snapshot", next_snapshot)
		"damage_target":
			var damage_result := adjust_target_damage(
				next_snapshot,
				str(args.get("target_id", "")),
				str(args.get("component_key", "")),
				int(args.get("amount", 0)),
				bool(args.get("set_value", false))
			)
			ok = bool(damage_result.get("ok", false))
			message = str(damage_result.get("message", ""))
			if ok:
				next_snapshot = damage_result.get("snapshot", next_snapshot)
		"end_game":
			var evaluation := evaluate_victory(next_snapshot)
			next_snapshot["GameOver"] = true
			next_snapshot["GameOverSummary"] = evaluation
			message = "Game over: %s wins. %s" % [str(evaluation.get("winner", "Draw")), str(evaluation.get("reason", ""))]
			_add_log(next_snapshot, message)
		"resume_game":
			next_snapshot["GameOver"] = false
			next_snapshot["GameOverSummary"] = {}
			message = "White resumed the game."
			_add_log(next_snapshot, message)
		"aircraft_adjust":
			var aircraft_adjust_result := adjust_aircraft(
				next_snapshot,
				str(args.get("team", "")),
				int(args.get("index", -1)),
				str(args.get("field", "")),
				int(args.get("amount", 0)),
				bool(args.get("set_value", false))
			)
			ok = bool(aircraft_adjust_result.get("ok", false))
			message = str(aircraft_adjust_result.get("message", ""))
			if ok:
				next_snapshot = aircraft_adjust_result.get("snapshot", next_snapshot)
		"aircraft_set":
			var aircraft_set_result := set_aircraft_field(
				next_snapshot,
				str(args.get("team", "")),
				int(args.get("index", -1)),
				str(args.get("field", "")),
				args.get("value", "")
			)
			ok = bool(aircraft_set_result.get("ok", false))
			message = str(aircraft_set_result.get("message", ""))
			if ok:
				next_snapshot = aircraft_set_result.get("snapshot", next_snapshot)
		"aircraft_roll":
			var aircraft_roll_result := roll_aircraft_event(next_snapshot, str(args.get("team", "")), str(args.get("mode", "")))
			ok = bool(aircraft_roll_result.get("ok", false))
			message = str(aircraft_roll_result.get("message", ""))
			if ok:
				next_snapshot = aircraft_roll_result.get("snapshot", next_snapshot)
		"red_resource":
			var resource_result := adjust_red_resource(
				next_snapshot,
				str(args.get("resource", "")),
				int(args.get("amount", 0)),
				bool(args.get("map_turn_only", false))
			)
			ok = bool(resource_result.get("ok", false))
			message = str(resource_result.get("message", ""))
			if ok:
				next_snapshot = resource_result.get("snapshot", next_snapshot)
		"add_log":
			var entry := str(args.get("entry", "")).strip_edges()
			if entry.is_empty():
				ok = false
				message = "Write a log entry first."
			else:
				_add_log(next_snapshot, entry)
				message = "Log updated."
		"clear_log":
			next_snapshot["ActionLog"] = []
			message = "Log cleared."
		_:
			ok = false
			message = "Unknown game action: %s" % action_name

	if ok and ["play_card", "resolve_card_action", "resolve_planned_action"].has(action_name):
		_record_night_point_gains(snapshot, next_snapshot)

	return {
		"ok": ok,
		"snapshot": next_snapshot,
		"message": message
	}


static func ensure_card_decks(snapshot: Dictionary, force_reset: bool = false) -> Dictionary:
	var next_snapshot := snapshot.duplicate(true)
	for team_name in TEAM_CARD_DATA.keys():
		var data: Dictionary = TEAM_CARD_DATA[team_name]
		var deck_key := str(data["deck"])
		var river_key := str(data["river"])
		var discard_key := str(data["discard"])
		if force_reset or str(next_snapshot.get(deck_key, "")).is_empty():
			next_snapshot[deck_key] = cards_to_string(make_deck(int(data["start"]), int(data["end"])))
		if force_reset:
			next_snapshot[river_key] = ""
			next_snapshot[discard_key] = ""
			next_snapshot["%sRiverRightmostCard" % team_name] = 0
	if force_reset:
		next_snapshot["PendingCard"] = {}
		next_snapshot["RiverRevealForTeam"] = ""
	return next_snapshot


static func reset_card_decks(snapshot: Dictionary) -> Dictionary:
	return ensure_card_decks(snapshot, true)


static func draw_river(snapshot: Dictionary, team_name: String) -> Dictionary:
	if not TEAM_CARD_DATA.has(team_name):
		return _result(false, snapshot, "Unknown card team.")

	var next_snapshot := ensure_card_decks(snapshot)
	var data: Dictionary = TEAM_CARD_DATA[team_name]
	var deck_key := str(data["deck"])
	var river_key := str(data["river"])
	var discard_key := str(data["discard"])
	var deck := cards_from_string(str(next_snapshot.get(deck_key, "")))
	var river := cards_from_string(str(next_snapshot.get(river_key, "")))
	var discard := cards_from_string(str(next_snapshot.get(discard_key, "")))
	var marker_key := "%sRiverRightmostCard" % team_name
	var previous_rightmost := int(next_snapshot.get(marker_key, 0))

	while river.size() > RIVER_SIZE:
		discard.append(int(river.pop_back()))
	# The physical seventh position is remembered at the start of the turn. If
	# that card was played, it is already gone and no second card is discarded.
	if previous_rightmost > 0:
		var rightmost_index := river.find(previous_rightmost)
		if rightmost_index >= 0:
			discard.append(int(river.pop_at(rightmost_index)))
	while river.size() < RIVER_SIZE:
		if deck.is_empty():
			if discard.is_empty():
				break
			deck = discard.duplicate()
			deck.shuffle()
			discard.clear()
		river.push_front(int(deck.pop_front()))

	next_snapshot[deck_key] = cards_to_string(deck)
	next_snapshot[river_key] = cards_to_string(river)
	next_snapshot[discard_key] = cards_to_string(discard)
	next_snapshot[marker_key] = int(river.back()) if not river.is_empty() else 0
	return _result(true, next_snapshot, "%s river drawn." % team_name)


static func discard_card(snapshot: Dictionary, team_name: String, card_index: int) -> Dictionary:
	if not TEAM_CARD_DATA.has(team_name):
		return _result(false, snapshot, "Unknown card team.")

	var next_snapshot := ensure_card_decks(snapshot)
	var data: Dictionary = TEAM_CARD_DATA[team_name]
	var river := cards_from_string(str(next_snapshot.get(data["river"], "")))
	var discard := cards_from_string(str(next_snapshot.get(data["discard"], "")))
	if card_index < 0 or card_index >= river.size():
		return _result(false, snapshot, "Choose a card from the river first.")

	var card_id := int(river.pop_at(card_index))
	discard.append(card_id)
	next_snapshot[data["river"]] = cards_to_string(river)
	next_snapshot[data["discard"]] = cards_to_string(discard)
	_add_log(next_snapshot, "%s discarded %s." % [team_name, card_display_name(card_id)])
	return _result(true, next_snapshot, "%s discarded." % card_display_name(card_id))


static func play_card(snapshot: Dictionary, team_name: String, card_index: int) -> Dictionary:
	if not TEAM_CARD_DATA.has(team_name):
		return _result(false, snapshot, "Only Red and Blue can play cards.")
	var existing_pending = snapshot.get("PendingCard", {})
	if existing_pending is Dictionary and not (existing_pending as Dictionary).is_empty():
		return _result(false, snapshot, "Finish resolving the current card first.")

	var next_snapshot := ensure_card_decks(snapshot)
	var data: Dictionary = TEAM_CARD_DATA[team_name]
	var river := cards_from_string(str(next_snapshot.get(data["river"], "")))
	var discard := cards_from_string(str(next_snapshot.get(data["discard"], "")))
	if card_index < 0 or card_index >= river.size():
		return _result(false, snapshot, "Choose a card from the river first.")

	var card_id := int(river[card_index])
	var metadata := card_metadata(card_id)
	if metadata.is_empty() or str(metadata.get("team", "")) != team_name:
		return _result(false, snapshot, "That card does not belong to %s." % team_name)
	var requirement_error := card_requirement_error(next_snapshot, team_name, metadata)
	if not requirement_error.is_empty():
		return _result(false, snapshot, requirement_error)
	var cost_result := _pay_card_cost(next_snapshot, team_name, metadata)
	if not bool(cost_result.get("ok", false)):
		return _result(false, snapshot, str(cost_result.get("message", "Not enough points.")))

	river.remove_at(card_index)
	discard.append(card_id)
	next_snapshot[data["river"]] = cards_to_string(river)
	next_snapshot[data["discard"]] = cards_to_string(discard)
	next_snapshot["LastPlayedCard"] = card_id
	next_snapshot["LastCardTeam"] = team_name
	next_snapshot["%sLastCardDirty" % team_name] = bool(metadata.get("dirty", false))
	next_snapshot["%sLastCardCovert" % team_name] = bool(metadata.get("covert", false))
	_add_log(next_snapshot, "%s played %s." % [team_name, card_display_name(card_id)])

	var resolving_team := team_name
	var backfire_threshold := int(metadata.get("backfire", 0))
	if backfire_threshold > 0:
		var backfire_roll := randi_range(1, 10)
		var backfire_message := "%s backfire check: %d (threshold %d)." % [card_display_name(card_id), backfire_roll, backfire_threshold]
		_add_dice_log(next_snapshot, backfire_message)
		_add_log(next_snapshot, backfire_message)
		if backfire_roll >= backfire_threshold:
			resolving_team = _opposing_team(team_name)
			_add_log(next_snapshot, "%s backfired; %s resolves its opinion dice." % [card_display_name(card_id), resolving_team])

	var effect_message := _begin_card_effect(next_snapshot, team_name, resolving_team, card_id, metadata)
	_check_immediate_victory(next_snapshot)
	var message := "%s played." % card_display_name(card_id)
	if not effect_message.is_empty():
		message += " " + effect_message
	return _result(true, next_snapshot, message)


static func roll_card_country(snapshot: Dictionary, team_name: String, card_id: int, country_id: int) -> Dictionary:
	if not TEAM_CARD_DATA.has(team_name):
		return _result(false, snapshot, "Only Red and Blue can roll cards.")
	var pending_value = snapshot.get("PendingCard", {})
	if not pending_value is Dictionary or (pending_value as Dictionary).is_empty():
		return _result(false, snapshot, "Play an opinion card before rolling its dice.")
	var pending := (pending_value as Dictionary).duplicate(true)
	if str(pending.get("type", "")) != "opinion":
		return _result(false, snapshot, "The current card is waiting for a different choice.")
	if int(pending.get("card_id", 0)) != card_id:
		return _result(false, snapshot, "Finish resolving the active card first.")
	if str(pending.get("resolving_team", "")) != team_name:
		return _result(false, snapshot, "%s must resolve this card." % str(pending.get("resolving_team", "The opposing team")))
	var metadata := card_metadata(card_id)
	if metadata.is_empty() and card_id != 0:
		return _result(false, snapshot, "Card data not found.")
	var group_options_value = pending.get("group_options", [])
	if not group_options_value is Array or (group_options_value as Array).is_empty():
		return _result(false, snapshot, "This card has no opinion-dice groups left.")
	var first_group = (group_options_value as Array)[0]
	var available_countries: Array = first_group if first_group is Array else []
	if not available_countries.has(country_id):
		return _result(false, snapshot, "That opinion-dice group cannot target this country.")
	if not UNITY_COUNTRY_TO_CODE.has(country_id):
		return _result(false, snapshot, "Unknown country.")
	var used_value = pending.get("used_country_ids", [])
	var used_country_ids: Array = used_value if used_value is Array else []
	var allow_repeat_country := bool(pending.get("allow_repeat_country", false))
	if not allow_repeat_country and used_country_ids.has(country_id):
		return _result(false, snapshot, "Each opinion-dice group must target a different track.")

	var next_snapshot := snapshot.duplicate(true)
	var track := _clean_track(next_snapshot.get("PoliticalTrack", {}))
	var country_code := str(UNITY_COUNTRY_TO_CODE[country_id])
	var track_locks_value = next_snapshot.get("TrackLocks", {})
	var track_locks: Dictionary = track_locks_value if track_locks_value is Dictionary else {}
	var lock_value = track_locks.get(country_code, {})
	if lock_value is Dictionary and int((lock_value as Dictionary).get("turns", 0)) > 0:
		return _result(false, snapshot, "%s is frozen for %d more map turn(s)." % [country_code, int((lock_value as Dictionary).get("turns", 0))])
	var rolls: int = maxi(1, int(pending.get("dice_per_group", metadata.get("numOfRolls", 1))))
	var successes := 0
	var roll_values: Array[String] = []
	var direction := -1 if team_name == "Red" else 1
	var current_position := int(track.get(country_code, 0))
	if current_position == (-10 if direction < 0 else 10):
		return _result(false, snapshot, "%s is already at the end of %s's opinion track." % [country_code, team_name])
	for _roll_index in range(rolls):
		var desired_position := clampi(current_position + direction, -10, 10)
		var difficulty := maxi(political_difficulty(current_position), political_difficulty(desired_position))
		var roll := randi_range(1, 10)
		roll_values.append("%d/%d" % [roll, difficulty])
		if roll >= difficulty:
			successes += 1

	if successes > 0:
		track[country_code] = clampi(int(track.get(country_code, 0)) + (direction * successes), -10, 10)
	next_snapshot["PoliticalTrack"] = track
	next_snapshot["CountryName"] = country_code
	next_snapshot["TrackPlace"] = int(track.get(country_code, 0))
	var summary := "%s rolled %s for %s: %d success%s (%s)." % [
		team_name,
		card_display_name(card_id),
		country_code,
		successes,
		"" if successes == 1 else "es",
		", ".join(roll_values)
	]
	next_snapshot["LastRollSummary"] = summary
	_add_log(next_snapshot, summary)
	_add_dice_log(next_snapshot, summary)
	var remaining_groups := (group_options_value as Array).duplicate(true)
	remaining_groups.pop_front()
	used_country_ids.append(country_id)
	if remaining_groups.is_empty():
		next_snapshot["PendingCard"] = {}
		_add_log(next_snapshot, "%s finished resolving %s." % [team_name, card_display_name(card_id)])
	else:
		pending["group_options"] = remaining_groups
		pending["groups_remaining"] = remaining_groups.size()
		pending["used_country_ids"] = used_country_ids
		next_snapshot["PendingCard"] = pending
	_check_immediate_victory(next_snapshot)
	return _result(true, next_snapshot, summary)


static func resolve_card_action(snapshot: Dictionary, team_name: String, args: Dictionary) -> Dictionary:
	if not TEAM_CARD_DATA.has(team_name):
		return _result(false, snapshot, "Only Red and Blue can resolve cards.")
	var pending_value = snapshot.get("PendingCard", {})
	if not pending_value is Dictionary or (pending_value as Dictionary).is_empty():
		return _result(false, snapshot, "There is no card choice waiting for you.")
	var pending := (pending_value as Dictionary).duplicate(true)
	if str(pending.get("resolving_team", "")) != team_name:
		return _result(false, snapshot, "%s must resolve this card." % str(pending.get("resolving_team", "The opposing team")))

	var next_snapshot := snapshot.duplicate(true)
	var pending_type := str(pending.get("type", ""))
	var card_id := int(pending.get("card_id", 0))
	var owner_team := str(pending.get("owner_team", team_name))
	match pending_type:
		"strategic_domestic_exchange":
			var prefix := _point_prefix(team_name)
			var mp_available := maxi(0, int(next_snapshot.get("%sMP" % prefix, 0)))
			var ip_available := maxi(0, int(next_snapshot.get("%sIP" % prefix, 0)))
			var required_units := maxi(0, int(pending.get("required_units", 0)))
			var spend_target := mini(required_units, mp_available + ip_available)
			var mp_spent := clampi(int(args.get("mp_spent", 0)), 0, mp_available)
			var ip_spent := clampi(int(args.get("ip_spent", 0)), 0, ip_available)
			if mp_spent + ip_spent != spend_target:
				return _result(false, snapshot, "Spend exactly %d combined MP/IP to finish the Domestic Scandal." % spend_target)
			next_snapshot["%sMP" % prefix] = mp_available - mp_spent
			next_snapshot["%sIP" % prefix] = ip_available - ip_spent
			next_snapshot["PendingCard"] = {}
			var exchange_message := "%s paid %d MP and %d IP toward the Domestic Scandal." % [team_name, mp_spent, ip_spent]
			_complete_strategic_event(next_snapshot, pending, exchange_message)
			_process_strategic_event_queue(next_snapshot)
			return _result(true, next_snapshot, exchange_message)
		"strategic_intifada":
			var max_spend := mini(12, int(floor(float(maxi(0, int(next_snapshot.get("IranMP", 0)))) / 3.0)) * 3)
			var military_spent := int(args.get("mp_spent", 0))
			if military_spent < 0 or military_spent > max_spend or military_spent % 3 != 0:
				return _result(false, snapshot, "Iran may spend 0-%d MP in groups of three." % max_spend)
			next_snapshot["IranMP"] = int(next_snapshot.get("IranMP", 0)) - military_spent
			var roll_count := 2 + int(floor(float(military_spent) / 3.0))
			var intifada_result := _roll_opinion_attempts(next_snapshot, "Red", "IL", roll_count, "Intifada Erupts")
			next_snapshot["PendingCard"] = {}
			var intifada_message := "Iran spent %d MP and rolled %d time(s) on Israel. %s" % [military_spent, roll_count, intifada_result]
			_complete_strategic_event(next_snapshot, pending, intifada_message)
			_process_strategic_event_queue(next_snapshot)
			return _result(true, next_snapshot, intifada_message)
		"strait_response":
			var blue_pp_spent := clampi(int(args.get("pp_spent", 0)), 0, 2)
			if int(next_snapshot.get("IsrealPP", 0)) < blue_pp_spent:
				return _result(false, snapshot, "Blue does not have enough PP to interfere with the blockade.")
			next_snapshot["IsrealPP"] = int(next_snapshot.get("IsrealPP", 0)) - blue_pp_spent
			var closure := str(pending.get("closure", "No Effect"))
			var red_pp_spent := clampi(int(pending.get("red_pp_spent", 0)), 0, 2)
			var base_roll := randi_range(1, 10)
			var modified_roll := clampi(base_roll + red_pp_spent - blue_pp_spent, 1, 10)
			var effect := _strait_effect_result(closure, modified_roll)
			var resolving_team := str(effect.get("team", "Blue"))
			var dice_count := int(effect.get("dice", 1))
			var country_options: Array = [2, 4, 5, 8]
			var groups: Array = []
			for _index in range(dice_count):
				groups.append(country_options.duplicate())
			next_snapshot["PendingCard"] = {
				"type": "opinion",
				"title": "Strait Blockade Effects",
				"card_id": 0,
				"owner_team": "Red",
				"resolving_team": resolving_team,
				"group_options": groups,
				"groups_remaining": groups.size(),
				"dice_per_group": 1,
				"used_country_ids": [],
				"allow_repeat_country": true
			}
			var strait_message := "Blockade effects: D10 %d + %d Red PP - %d Blue PP = %d; %s receives %d opinion die/dice." % [base_roll, red_pp_spent, blue_pp_spent, modified_roll, resolving_team, dice_count]
			_add_log(next_snapshot, strait_message)
			_add_dice_log(next_snapshot, strait_message)
			return _result(true, next_snapshot, strait_message)
		"set_choice":
			var metadata := card_metadata(card_id)
			var choice := str(args.get("choice", "set1"))
			if choice != "set1" and choice != "set2":
				return _result(false, snapshot, "Choose one of the card's two opinion sets.")
			var option_ids := _clean_country_ids(metadata.get("set1Countries" if choice == "set1" else "set2Countries", []))
			if option_ids.is_empty():
				return _result(false, snapshot, "That opinion set has no valid countries.")
			var dice_per_group := int(metadata.get("numOfRolls", 1))
			if choice == "set2":
				dice_per_group = maxi(1, int(metadata.get("optionalRolls", dice_per_group)))
			pending["type"] = "opinion"
			pending["group_options"] = [option_ids]
			pending["groups_remaining"] = 1
			pending["dice_per_group"] = maxi(1, dice_per_group)
			pending["used_country_ids"] = []
			next_snapshot["PendingCard"] = pending
			return _result(true, next_snapshot, "%s selected %s; choose an opinion track." % [team_name, choice.capitalize()])
		"retrieve":
			var retrieve_id := int(args.get("card_id", 0))
			var data: Dictionary = TEAM_CARD_DATA.get(owner_team, {})
			var discard := cards_from_string(str(next_snapshot.get(data.get("discard", ""), "")))
			var river := cards_from_string(str(next_snapshot.get(data.get("river", ""), "")))
			var retrieve_index := discard.find(retrieve_id)
			if retrieve_index < 0 or retrieve_id == card_id:
				return _result(false, snapshot, "Choose an eligible card from your discard pile.")
			if river.size() >= RIVER_SIZE:
				return _result(false, snapshot, "Your River has no open space for the retrieved card.")
			discard.remove_at(retrieve_index)
			river.push_front(retrieve_id)
			next_snapshot[data["discard"]] = cards_to_string(discard)
			next_snapshot[data["river"]] = cards_to_string(river)
			var refund_type := _first_cost_type(card_metadata(retrieve_id))
			if not refund_type.is_empty():
				var refund_key := "%s%s" % [_point_prefix(owner_team), refund_type]
				next_snapshot[refund_key] = int(next_snapshot.get(refund_key, 0)) + 1
			next_snapshot["PendingCard"] = {}
			var retrieve_message := "%s retrieved %s and gained 1 %s." % [owner_team, card_display_name(retrieve_id), refund_type]
			_add_log(next_snapshot, retrieve_message)
			return _result(true, next_snapshot, retrieve_message)
		"discard_choice":
			var discard_id := int(args.get("card_id", 0))
			var opponent := _opposing_team(owner_team)
			var opponent_data: Dictionary = TEAM_CARD_DATA.get(opponent, {})
			var opponent_river := cards_from_string(str(next_snapshot.get(opponent_data.get("river", ""), "")))
			var opponent_discard := cards_from_string(str(next_snapshot.get(opponent_data.get("discard", ""), "")))
			var discard_index := opponent_river.find(discard_id)
			if discard_index < 0:
				return _result(false, snapshot, "Choose a card that is still in the opposing River.")
			opponent_river.remove_at(discard_index)
			opponent_discard.append(discard_id)
			next_snapshot[opponent_data["river"]] = cards_to_string(opponent_river)
			next_snapshot[opponent_data["discard"]] = cards_to_string(opponent_discard)
			var choices_left := maxi(0, int(pending.get("choices_left", 1)) - 1)
			if choices_left == 0 or opponent_river.is_empty():
				next_snapshot["PendingCard"] = {}
			else:
				pending["choices_left"] = choices_left
				next_snapshot["PendingCard"] = pending
			var discard_message := "%s discarded %s from %s's River." % [owner_team, card_display_name(discard_id), opponent]
			_add_log(next_snapshot, discard_message)
			return _result(true, next_snapshot, discard_message)
		"convert":
			var source := str(args.get("source", "")).to_upper()
			var target := str(args.get("target", "")).to_upper()
			var spent := int(args.get("amount", 0))
			if not POINT_KEYS.has(source) or not POINT_KEYS.has(target) or source == target:
				return _result(false, snapshot, "Choose two different point types.")
			if spent < 3 or spent % 3 != 0:
				return _result(false, snapshot, "Black Market conversion spends points in groups of three.")
			var prefix := _point_prefix(owner_team)
			var source_key := "%s%s" % [prefix, source]
			var target_key := "%s%s" % [prefix, target]
			if int(next_snapshot.get(source_key, 0)) < spent:
				return _result(false, snapshot, "%s does not have %d %s to convert." % [owner_team, spent, source])
			next_snapshot[source_key] = int(next_snapshot.get(source_key, 0)) - spent
			next_snapshot[target_key] = int(next_snapshot.get(target_key, 0)) + (spent / 3)
			next_snapshot["PendingCard"] = {}
			var conversion_message := "%s converted %d %s into %d %s." % [owner_team, spent, source, spent / 3, target]
			_add_log(next_snapshot, conversion_message)
			return _result(true, next_snapshot, conversion_message)
		"freeze":
			var country_code := str(args.get("country", "")).to_upper()
			if not COUNTRY_CODES.has(country_code):
				return _result(false, snapshot, "Choose a political track to freeze.")
			var freeze_turns := randi_range(1, 6) + 3
			var locks_value = next_snapshot.get("TrackLocks", {})
			var locks: Dictionary = locks_value.duplicate(true) if locks_value is Dictionary else {}
			locks[country_code] = {"team": owner_team, "turns": freeze_turns}
			next_snapshot["TrackLocks"] = locks
			next_snapshot["PendingCard"] = {}
			var freeze_message := "%s froze %s for %d map turns." % [owner_team, country_code, freeze_turns]
			_add_log(next_snapshot, freeze_message)
			return _result(true, next_snapshot, freeze_message)
	return _result(false, snapshot, "This pending card choice is not supported.")


static func card_requirement_error(snapshot: Dictionary, team_name: String, metadata: Dictionary) -> String:
	var requirement := int(metadata.get("requirement", 0))
	if requirement == 0:
		return ""
	var opponent := _opposing_team(team_name)
	var requirement_met := false
	match requirement:
		1:
			requirement_met = bool(snapshot.get("%sLastCardDirty" % opponent, false))
		2:
			requirement_met = bool(snapshot.get("%sLastCardCovert" % opponent, false))
		3:
			requirement_met = bool(snapshot.get("%sLastCardDirty" % opponent, false)) or bool(snapshot.get("%sLastCardCovert" % opponent, false))
		4:
			requirement_met = bool(snapshot.get("%sLastActionOvert" % opponent, false))
		5:
			requirement_met = _has_damaged_nuclear_target(snapshot)
		6, 7:
			requirement_met = true
		8:
			requirement_met = _country_supports_team(snapshot, "US", team_name)
		9:
			requirement_met = _country_supports_team(snapshot, "PRC", team_name) or _country_supports_team(snapshot, "RU", team_name)
		10:
			for code in ["TR", "SA", "US"]:
				if _country_supports_team(snapshot, code, team_name):
					requirement_met = true
					break
		11:
			requirement_met = bool(snapshot.get("BlueAirStrikeThisTurn", false))
		12:
			requirement_met = int(snapshot.get("BluePOW" if team_name == "Red" else "RedPOW", 0)) > 0
	if requirement_met:
		return ""
	return "%s cannot be played: requirement not met (%s)." % [card_display_name(int(metadata.get("id", 0))), requirement_description(requirement)]


static func _begin_card_effect(snapshot: Dictionary, owner_team: String, resolving_team: String, card_id: int, metadata: Dictionary) -> String:
	var action_id := int(metadata.get("action", 0))
	match action_id:
		0:
			var group_count := maxi(0, int(metadata.get("numOfDice", 0)))
			if group_count == 0:
				return "No additional resolution is required."
			if bool(metadata.get("sets", false)) and bool(metadata.get("onlyOneSet", false)):
				snapshot["PendingCard"] = {
					"type": "set_choice",
					"card_id": card_id,
					"owner_team": owner_team,
					"resolving_team": resolving_team
				}
				return "%s must choose one opinion-dice set." % resolving_team
			var groups := _opinion_groups(metadata)
			if groups.is_empty():
				return "The card has no valid opinion tracks."
			snapshot["PendingCard"] = {
				"type": "opinion",
				"card_id": card_id,
				"owner_team": owner_team,
				"resolving_team": resolving_team,
				"group_options": groups,
				"groups_remaining": groups.size(),
				"dice_per_group": maxi(1, int(metadata.get("numOfRolls", 1))),
				"used_country_ids": []
			}
			return "%s must assign %d opinion-dice group(s)." % [resolving_team, groups.size()]
		1:
			snapshot["RiverRevealForTeam"] = owner_team
			var sleeper := _clean_team_flags(snapshot.get("SleeperAgentReady", {}))
			sleeper[owner_team] = true
			snapshot["SleeperAgentReady"] = sleeper
			return "%s may inspect the opposing River; its next River discard may be chosen." % owner_team
		2:
			var data: Dictionary = TEAM_CARD_DATA.get(owner_team, {})
			var discard := cards_from_string(str(snapshot.get(data.get("discard", ""), "")))
			var eligible: Array = []
			for discard_id in discard:
				if int(discard_id) != card_id:
					eligible.append(int(discard_id))
			if eligible.is_empty():
				return "There are no earlier cards in the discard pile to retrieve."
			snapshot["PendingCard"] = {
				"type": "retrieve",
				"card_id": card_id,
				"owner_team": owner_team,
				"resolving_team": owner_team,
				"eligible_cards": eligible
			}
			return "%s must choose a card to retrieve." % owner_team
		3, 4:
			var discard_count := 1 if action_id == 3 else 2
			var sleeper_flags := _clean_team_flags(snapshot.get("SleeperAgentReady", {}))
			if bool(sleeper_flags.get(owner_team, false)):
				sleeper_flags[owner_team] = false
				snapshot["SleeperAgentReady"] = sleeper_flags
				snapshot["PendingCard"] = {
					"type": "discard_choice",
					"card_id": card_id,
					"owner_team": owner_team,
					"resolving_team": owner_team,
					"choices_left": discard_count
				}
				return "%s may choose %d opposing River card(s) to discard." % [owner_team, discard_count]
			var removed := _discard_random_opponent_cards(snapshot, owner_team, discard_count)
			return "%s discarded %d random opposing River card(s)." % [owner_team, removed]
		5:
			snapshot["StrategicEventCancelled"] = true
			return "The current strategic event is cancelled."
		6:
			snapshot["PendingCard"] = {
				"type": "convert",
				"card_id": card_id,
				"owner_team": owner_team,
				"resolving_team": owner_team
			}
			return "%s may convert any three points into one point of another type." % owner_team
		7:
			snapshot["BlueBunkerHill"] = true
			return "Bunker Hill was added to Blue's available forces."
		8:
			snapshot["BlueBurkeDestroyer"] = true
			return "A Burke-class destroyer was added to Blue's available forces."
		9, 12:
			var counter_type := "IP" if action_id == 9 else "PP"
			var tokens_value = snapshot.get("CardCounterTokens", {})
			var tokens: Dictionary = tokens_value.duplicate(true) if tokens_value is Dictionary else {}
			var token_key := "%s%s" % [owner_team, counter_type]
			tokens[token_key] = int(tokens.get(token_key, 0)) + 1
			snapshot["CardCounterTokens"] = tokens
			return "%s gained a counter for an opposing card whose first cost is %s." % [owner_team, counter_type]
		10:
			snapshot["PendingCard"] = {
				"type": "freeze",
				"card_id": card_id,
				"owner_team": owner_team,
				"resolving_team": owner_team
			}
			return "%s must choose a political track to freeze." % owner_team
		11:
			var points_value = snapshot.get("UpgradePoints", {})
			var points: Dictionary = points_value.duplicate(true) if points_value is Dictionary else {}
			points[owner_team] = int(points.get(owner_team, 0)) + 40
			snapshot["UpgradePoints"] = points
			return "%s received 40 upgrade points." % owner_team
	return "Card effect recorded."


static func _opinion_groups(metadata: Dictionary) -> Array:
	var groups: Array = []
	var group_count := maxi(0, int(metadata.get("numOfDice", 0)))
	if bool(metadata.get("sets", false)):
		var set1 := _clean_country_ids(metadata.get("set1Countries", []))
		var set2 := _clean_country_ids(metadata.get("set2Countries", []))
		if not set1.is_empty():
			groups.append(set1)
		if not set2.is_empty():
			groups.append(set2)
		return groups
	var countries := _clean_country_ids(metadata.get("countries", []))
	for _group_index in range(group_count):
		groups.append(countries.duplicate())
	return groups


static func _clean_country_ids(value) -> Array:
	var result: Array = []
	if value is Array:
		for raw_id in value:
			var country_id := int(raw_id)
			if UNITY_COUNTRY_TO_CODE.has(country_id) and not result.has(country_id):
				result.append(country_id)
	return result


static func _clean_team_flags(value) -> Dictionary:
	var flags := {"Red": false, "Blue": false}
	if value is Dictionary:
		for team_name in flags.keys():
			flags[team_name] = bool((value as Dictionary).get(team_name, false))
	return flags


static func _discard_random_opponent_cards(snapshot: Dictionary, owner_team: String, count: int) -> int:
	var opponent := _opposing_team(owner_team)
	var data: Dictionary = TEAM_CARD_DATA.get(opponent, {})
	var river := cards_from_string(str(snapshot.get(data.get("river", ""), "")))
	var discard := cards_from_string(str(snapshot.get(data.get("discard", ""), "")))
	var removed := 0
	while removed < count and not river.is_empty():
		var index := randi_range(0, river.size() - 1)
		discard.append(int(river.pop_at(index)))
		removed += 1
	snapshot[data["river"]] = cards_to_string(river)
	snapshot[data["discard"]] = cards_to_string(discard)
	return removed


static func _first_cost_type(metadata: Dictionary) -> String:
	var metadata_keys := {"IP": "iPCost", "MP": "mPCost", "PP": "pPCost"}
	for point_type in ["IP", "MP", "PP"]:
		var metadata_key := str(metadata_keys[point_type])
		var raw_cost := str(metadata.get(metadata_key, "0")).strip_edges()
		if raw_cost == "X" or (raw_cost.is_valid_int() and int(raw_cost) > 0):
			return point_type
	return ""


static func _opposing_team(team_name: String) -> String:
	return "Blue" if team_name == "Red" else "Red"


static func _country_supports_team(snapshot: Dictionary, country_code: String, team_name: String) -> bool:
	var track := _clean_track(snapshot.get("PoliticalTrack", {}))
	var value := int(track.get(country_code, 0))
	return value <= -5 if team_name == "Red" else value >= 5


static func _has_damaged_nuclear_target(snapshot: Dictionary) -> bool:
	var state_value = snapshot.get("Targets", {})
	var targets_state: Dictionary = state_value if state_value is Dictionary else {}
	for target in all_target_metadata():
		if not target is Dictionary or str((target as Dictionary).get("type", "")) != "Nuclear":
			continue
		var target_id := str((target as Dictionary).get("id", ""))
		var target_state_value = targets_state.get(target_id, {})
		var target_state: Dictionary = target_state_value if target_state_value is Dictionary else {}
		for component in (target as Dictionary).get("components", []):
			if component is Dictionary and int(target_state.get(str((component as Dictionary).get("key", "")), 0)) > 0:
				return true
	return false


static func _check_immediate_victory(snapshot: Dictionary) -> void:
	if bool(snapshot.get("GameOver", false)):
		return
	var track := _clean_track(snapshot.get("PoliticalTrack", {}))
	var winner := ""
	var reason := ""
	if int(track.get("IR", 0)) >= 10:
		winner = "Blue"
		reason = "Iranian domestic opinion reached +10 and Iran sued for terms."
	elif int(track.get("IL", 0)) <= -10:
		winner = "Red"
		reason = "Israeli domestic opinion reached -10 and the campaign was called off."
	if winner.is_empty():
		return
	snapshot["GameOver"] = true
	snapshot["GameOverSummary"] = {"winner": winner, "reason": reason, "day": int(snapshot.get("TurnDay", 0))}
	_add_log(snapshot, "Immediate victory: %s wins. %s" % [winner, reason])


static func generate_points_from_track(snapshot: Dictionary) -> Dictionary:
	var next_snapshot := snapshot.duplicate(true)
	var totals := political_point_totals(next_snapshot.get("PoliticalTrack", {}))
	var blue: Dictionary = totals.get("Blue", {})
	var red: Dictionary = totals.get("Red", {})
	next_snapshot["IsrealIP"] = int(blue.get("IP", 0))
	next_snapshot["IsrealPP"] = int(blue.get("PP", 0))
	next_snapshot["IsrealMP"] = int(blue.get("MP", 0))
	next_snapshot["IranIP"] = int(red.get("IP", 0))
	next_snapshot["IranPP"] = int(red.get("PP", 0))
	next_snapshot["IranMP"] = int(red.get("MP", 0))
	return next_snapshot


static func political_point_totals(track_value) -> Dictionary:
	var totals := {
		"Blue": {"IP": 0, "MP": 0, "PP": 0},
		"Red": {"IP": 0, "MP": 0, "PP": 0}
	}
	for entry_value in political_point_breakdown(track_value):
		var entry: Dictionary = entry_value
		for team_name in ["Blue", "Red"]:
			var contribution: Dictionary = entry.get(team_name, {})
			var team_totals: Dictionary = totals[team_name]
			for point_name in ["IP", "MP", "PP"]:
				team_totals[point_name] = int(team_totals.get(point_name, 0)) + int(contribution.get(point_name, 0))
	return totals


static func political_point_breakdown(track_value) -> Array[Dictionary]:
	var stats := political_stats()
	var track := _clean_track(track_value)
	var breakdown: Array[Dictionary] = []
	for country_code in COUNTRY_CODES:
		var position := int(track.get(country_code, 0))
		var row: Dictionary = stats.get("%s:%d" % [country_code, position], {})
		breakdown.append({
			"code": country_code,
			"position": position,
			"Blue": {
				"IP": int(row.get("blue_ip", 0)),
				"MP": int(row.get("blue_mp", 0)),
				"PP": int(row.get("blue_pp", 0))
			},
			"Red": {
				"IP": int(row.get("red_ip", 0)),
				"MP": int(row.get("red_mp", 0)),
				"PP": int(row.get("red_pp", 0))
			}
		})
	return breakdown


static func adjust_points(snapshot: Dictionary, team_name: String, point_key: String, amount: int, set_value: bool = false) -> Dictionary:
	var prefix := _point_prefix(team_name)
	if prefix.is_empty():
		return _result(false, snapshot, "Unknown points team.")
	var normalized_point := point_key.to_upper()
	if not POINT_KEYS.has(normalized_point):
		return _result(false, snapshot, "Unknown point type.")
	var key := "%s%s" % [prefix, normalized_point]
	var next_snapshot := snapshot.duplicate(true)
	var value := amount if set_value else int(next_snapshot.get(key, 0)) + amount
	next_snapshot[key] = max(0, value)
	_add_log(next_snapshot, "%s %s changed to %d." % [team_name, normalized_point, int(next_snapshot[key])])
	return _result(true, next_snapshot, "%s %s updated." % [team_name, normalized_point])


static func adjust_red_resource(snapshot: Dictionary, resource: String, amount: int, map_turn_only: bool = false) -> Dictionary:
	var next_snapshot := snapshot.duplicate(true)
	var normalized_resource := resource.to_upper()
	match normalized_resource:
		"POW":
			next_snapshot["RedPOW"] = max(0, int(next_snapshot.get("RedPOW", 0)) + amount)
			_add_log(next_snapshot, "Red POW changed to %d." % int(next_snapshot["RedPOW"]))
			return _result(true, next_snapshot, "Red POW updated.")
		"GCI":
			if amount == 0:
				next_snapshot["RedGCI"] = max(0, int(next_snapshot.get("RedGCI", 0)) - int(next_snapshot.get("RedGCIMapTurn", 0)))
				next_snapshot["RedGCIMapTurn"] = 0
			else:
				next_snapshot["RedGCI"] = max(0, int(next_snapshot.get("RedGCI", 0)) + amount)
				if amount > 0 and map_turn_only:
					next_snapshot["RedGCIMapTurn"] = max(0, int(next_snapshot.get("RedGCIMapTurn", 0)) + amount)
			_add_log(next_snapshot, "Red GCI changed to %d." % int(next_snapshot["RedGCI"]))
			return _result(true, next_snapshot, "Red GCI updated.")
		"SAM":
			next_snapshot["RedSAM"] = max(0, int(next_snapshot.get("RedSAM", 0)) + amount)
			_add_log(next_snapshot, "Red SAM changed to %d." % int(next_snapshot["RedSAM"]))
			return _result(true, next_snapshot, "Red SAM updated.")
	return _result(false, snapshot, "Unknown Red resource.")


static func roll_dice(sides: int, count: int = 1, label: String = "Dice") -> Dictionary:
	var clean_sides: int = maxi(2, sides)
	var clean_count: int = clampi(count, 1, 8)
	var values: Array[int] = []
	var total := 0
	for _index in range(clean_count):
		var value := randi_range(1, clean_sides)
		values.append(value)
		total += value
	var summary := "%s rolled %s = %d" % [label, _int_array_to_string(values, " + "), total]
	return {
		"values": values,
		"total": total,
		"summary": summary
	}


static func _canonical_action_type(team_name: String, action_name: String) -> String:
	var normalized := action_name.strip_edges().to_lower()
	if team_name == "Blue":
		if normalized.contains("airstrike"):
			return "Airstrike"
		if normalized.contains("special") or normalized in ["civil economic", "weaken air defenses", "spot", "attack undamaged building", "finish damaged building"]:
			return "Special Warfare"
		return ""
	if normalized.contains("shahab") or normalized.contains("sejil") or normalized.contains("ballistic"):
		return "Ballistic Missile"
	if normalized.contains("terror") or normalized in ["civil economic", "weaken air defenses", "spot", "attack undamaged building", "finish damaged building"]:
		return "Terror Attack"
	if normalized.contains("reposition"):
		return "Reposition Air Defense"
	if normalized.contains("strait"):
		return "Close Strait"
	return ""


static func _special_warfare_chance(snapshot: Dictionary, team_name: String, point_total: int, wait_time: int) -> int:
	var base_chances := {2: 50, 3: 60, 4: 70, 5: 80, 6: 90, 7: 95}
	var chance := int(base_chances.get(clampi(point_total, 2, 7), 50))
	match clampi(wait_time, 1, 5):
		1:
			chance -= 50
		2:
			chance -= 30
	var execution_turn := (int(snapshot.get("TurnTime", 0)) + wait_time) % 3
	if team_name == "Blue" and (execution_turn == 0 or execution_turn == 1):
		chance -= 20
	if team_name == "Red" and _has_selected_upgrade(snapshot, "Blue", "Iron Dome"):
		chance -= 20
	return clampi(chance, 0, 95)


static func _has_selected_upgrade(snapshot: Dictionary, team_name: String, search_name: String) -> bool:
	var selected_value = snapshot.get("SelectedUpgrades", {})
	if not selected_value is Dictionary:
		return false
	var team_value = (selected_value as Dictionary).get(team_name, [])
	if not team_value is Array:
		return false
	for item in team_value:
		if item is Dictionary and str((item as Dictionary).get("name", "")).to_lower().contains(search_name.to_lower()):
			return true
	return false


static func _selected_upgrade_count(snapshot: Dictionary, team_name: String, search_name: String) -> int:
	var selected_value = snapshot.get("SelectedUpgrades", {})
	if not selected_value is Dictionary:
		return 0
	var count := 0
	var teams: Array[String] = [team_name]
	if team_name == "Red":
		teams.append("RedExtra")
	for selected_team in teams:
		var team_value = (selected_value as Dictionary).get(selected_team, [])
		if not team_value is Array:
			continue
		for item in team_value:
			if item is Dictionary and str((item as Dictionary).get("name", "")).to_lower().contains(search_name.to_lower()):
				count += 1
	return count


static func _available_ballistic_battalions(snapshot: Dictionary, missile_type: String) -> int:
	var maximum := 2
	if missile_type == "Sejil-2":
		maximum = mini(2, _selected_upgrade_count(snapshot, "Red", "Sejil-2"))
	var current_turn := _map_turn_number(snapshot)
	var unavailable := 0
	var cooldowns := _clean_dictionary_array(snapshot.get("BallisticBattalionCooldowns", []))
	for cooldown in cooldowns:
		if str(cooldown.get("missile_type", "")) == missile_type and int(cooldown.get("ready_turn", 0)) > current_turn:
			unavailable += int(cooldown.get("battalions", 0))
	var planned := _clean_dictionary_array(snapshot.get("PlannedActions", []))
	for action in planned:
		if str(action.get("action_type", "")) != "Ballistic Missile":
			continue
		if str(action.get("missile_type", "Shahab-3")) != missile_type:
			continue
		unavailable += int(action.get("battalions", action.get("missiles", 0)))
	return maxi(0, maximum - unavailable)


static func selected_upgrade_count(snapshot: Dictionary, team_name: String, search_name: String) -> int:
	return _selected_upgrade_count(snapshot, team_name, search_name)


static func available_ballistic_battalions(snapshot: Dictionary, missile_type: String) -> int:
	return _available_ballistic_battalions(snapshot, missile_type)


static func blue_loadouts_for_model(model: String) -> Array[String]:
	var names: Array[String] = []
	var model_value = BLUE_LOADOUTS.get(model, {})
	if model_value is Dictionary:
		for loadout_name in (model_value as Dictionary).keys():
			names.append(str(loadout_name))
	return names


static func _default_strike_loadout(model: String) -> String:
	match model:
		"F15I":
			return "Strike - GBU-31"
		"F16I":
			return "Strike - SPICE 2000"
	return ""


static func _find_ready_blue_aircraft_index(aircraft: Array, models: Array, count: int, excluded: Array = []) -> int:
	for index in range(aircraft.size()):
		if excluded.has(index):
			continue
		var row := aircraft[index] as Dictionary
		if not models.has(str(row.get("model", ""))):
			continue
		if str(row.get("mission", "Ready")) != "Ready":
			continue
		if int(row.get("operational", 0)) < count:
			continue
		return index
	return -1


static func _reserve_blue_assignment(aircraft: Array, index: int, count: int, role: String, loadout: String, operation_id: String) -> Dictionary:
	if index < 0 or index >= aircraft.size():
		return {}
	var row := (aircraft[index] as Dictionary).duplicate(true)
	row["mission"] = "Fragged"
	row["committed"] = count
	row["assignment"] = role
	row["loadout"] = loadout
	row["operation_id"] = operation_id
	aircraft[index] = row
	return {
		"index": index,
		"name": str(row.get("name", "Squadron")),
		"model": str(row.get("model", "")),
		"count": count,
		"role": role,
		"loadout": loadout
	}


static func _first_attackable_component(snapshot: Dictionary, target: Dictionary) -> String:
	var target_id := str(target.get("id", ""))
	var states := merge_targets_with_defaults(snapshot.get("Targets", {}))
	var state_value = states.get(target_id, {})
	var state: Dictionary = state_value if state_value is Dictionary else {}
	for preferred_role in ["Primary", "Secondary"]:
		for component in target.get("components", []):
			var component_dict := component as Dictionary
			if str(component_dict.get("role", "Primary")) != preferred_role:
				continue
			var key := str(component_dict.get("key", ""))
			var boxes := maxi(1, int(component_dict.get("boxes", 1)))
			if int(state.get(key, 0)) < boxes:
				return key
	return ""


static func _route_plan_error(snapshot: Dictionary, route: String) -> String:
	if not ROUTE_COUNTRY.has(route):
		return "Choose the Northern, Central or Southern ingress route."
	var country_code := str(ROUTE_COUNTRY.get(route, ""))
	var track := _clean_track(snapshot.get("PoliticalTrack", {}))
	var position := int(track.get(country_code, 0))
	if position <= 0:
		return "%s route is unavailable: %s is not cordial with Blue." % [route, country_code]
	if position < 5:
		var used_value = snapshot.get("OverflightUsed", {})
		var used: Dictionary = used_value if used_value is Dictionary else {}
		if bool(used.get(country_code, false)):
			return "%s already granted its one cordial overflight; it must become a Blue Supporter." % country_code
	return ""


static func _prepare_airstrike_plan(snapshot: Dictionary, args: Dictionary, target_id: String, strike_count: int) -> Dictionary:
	var target := _find_target_metadata(target_id)
	if target.is_empty():
		return {"ok": false, "message": "Choose a valid Iranian target for the airstrike."}
	var route := str(args.get("route", "Central")).strip_edges().capitalize()
	var allowed_routes_value = target.get("routes", [])
	var allowed_routes: Array = allowed_routes_value if allowed_routes_value is Array else []
	if not allowed_routes.is_empty() and not allowed_routes.has(route):
		return {"ok": false, "message": "%s cannot be reached through the %s route with the available mission plans." % [str(target.get("name", target_id)), route]}
	var route_error := _route_plan_error(snapshot, route)
	if not route_error.is_empty():
		return {"ok": false, "message": route_error}
	var last_turn_value = snapshot.get("TargetLastStrikeTurn", {})
	var last_turns: Dictionary = last_turn_value if last_turn_value is Dictionary else {}
	if int(last_turns.get(target_id, -999)) >= _map_turn_number(snapshot):
		return {"ok": false, "message": "A restrike against %s cannot be ordered until the next map turn." % str(target.get("name", target_id))}

	var component_key := str(args.get("component_key", "")).strip_edges()
	if component_key.is_empty():
		component_key = _first_attackable_component(snapshot, target)
	var component := _find_target_component(target, component_key)
	if component.is_empty():
		return {"ok": false, "message": "Choose a valid component on %s." % str(target.get("name", target_id))}
	var target_state_value = merge_targets_with_defaults(snapshot.get("Targets", {})).get(target_id, {})
	var target_state: Dictionary = target_state_value if target_state_value is Dictionary else {}
	if int(target_state.get(component_key, 0)) >= maxi(1, int(component.get("boxes", 1))):
		return {"ok": false, "message": "%s is already destroyed; choose another component." % str(component.get("name", component_key))}

	var aircraft := _aircraft_list(snapshot, "Blue")
	var selected_index := int(args.get("squadron_index", -1))
	if selected_index < 0:
		selected_index = _find_ready_blue_aircraft_index(aircraft, ["F16I", "F15I"], strike_count)
	if selected_index < 0 or selected_index >= aircraft.size():
		return {"ok": false, "message": "No ready Israeli strike squadron has %d operational aircraft." % strike_count}
	var selected_row := aircraft[selected_index] as Dictionary
	var selected_model := str(selected_row.get("model", ""))
	if not ["F16I", "F15I"].has(selected_model) or str(selected_row.get("mission", "Ready")) != "Ready" or int(selected_row.get("operational", 0)) < strike_count:
		return {"ok": false, "message": "The selected strike squadron is not ready or lacks enough aircraft."}
	var loadout := str(args.get("loadout", "")).strip_edges()
	if loadout.is_empty():
		loadout = _default_strike_loadout(selected_model)
	var model_loadouts_value = BLUE_LOADOUTS.get(selected_model, {})
	var model_loadouts: Dictionary = model_loadouts_value if model_loadouts_value is Dictionary else {}
	var loadout_value = model_loadouts.get(loadout, {})
	var loadout_data: Dictionary = loadout_value if loadout_value is Dictionary else {}
	if loadout_data.is_empty() or str(loadout_data.get("role", "")) != "Strike":
		return {"ok": false, "message": "%s is not a legal strike loadout for %s." % [loadout, selected_model]}

	var operation_id := "%d-%d-%s" % [_map_turn_number(snapshot), Time.get_ticks_msec(), target_id]
	var assignments: Array = []
	var excluded: Array = []
	var strike_assignment := _reserve_blue_assignment(aircraft, selected_index, strike_count, "Strike", loadout, operation_id)
	assignments.append(strike_assignment)
	excluded.append(selected_index)

	var escort_count := clampi(int(args.get("escort_aircraft", 0)), 0, 12)
	if escort_count > 0:
		var escort_index := _find_ready_blue_aircraft_index(aircraft, ["F16I"], escort_count, excluded)
		if escort_index < 0:
			return {"ok": false, "message": "No separate ready F-16I squadron can provide %d escort aircraft." % escort_count}
		assignments.append(_reserve_blue_assignment(aircraft, escort_index, escort_count, "Escort", "Escort", operation_id))
		excluded.append(escort_index)

	var sead_count := clampi(int(args.get("sead_aircraft", 0)), 0, 4)
	var sead_loadout := str(args.get("sead_loadout", "SEAD - AGM-88 HARM"))
	if sead_count > 0:
		if not ["SEAD - AGM-88 HARM", "SEAD - STAR-1"].has(sead_loadout):
			return {"ok": false, "message": "Choose AGM-88 HARM or STAR-1 for the SEAD element."}
		var sead_index := _find_ready_blue_aircraft_index(aircraft, ["F16I"], sead_count, excluded)
		if sead_index < 0:
			return {"ok": false, "message": "No separate ready F-16I squadron can provide %d SEAD aircraft." % sead_count}
		assignments.append(_reserve_blue_assignment(aircraft, sead_index, sead_count, "SEAD", sead_loadout, operation_id))
		excluded.append(sead_index)

	var shavit_count := clampi(int(args.get("shavit_aircraft", 0)), 0, 1)
	var eitan_count := clampi(int(args.get("eitan_aircraft", 0)), 0, 2)
	if eitan_count > 0 and shavit_count == 0:
		return {"ok": false, "message": "Eitan Suter support requires one Shavit aircraft."}
	if shavit_count > 0:
		var shavit_index := _find_ready_blue_aircraft_index(aircraft, ["Shavit"], 1, excluded)
		if shavit_index < 0:
			return {"ok": false, "message": "No Shavit aircraft is ready for the Suter attack."}
		assignments.append(_reserve_blue_assignment(aircraft, shavit_index, 1, "Suter", "Shavit network attack", operation_id))
		excluded.append(shavit_index)
	if eitan_count > 0:
		var eitan_index := _find_ready_blue_aircraft_index(aircraft, ["Eitan"], eitan_count, excluded)
		if eitan_index < 0:
			return {"ok": false, "message": "Fewer than %d Eitan aircraft are ready for Suter support." % eitan_count}
		assignments.append(_reserve_blue_assignment(aircraft, eitan_index, eitan_count, "Suter Support", "Eitan network support", operation_id))
		excluded.append(eitan_index)

	var tanker_count := 0
	for assignment_value in assignments:
		var assignment := assignment_value as Dictionary
		var role := str(assignment.get("role", ""))
		if not ["Strike", "Escort", "SEAD"].has(role):
			continue
		var model := str(assignment.get("model", ""))
		var model_table_value = TANKERS_PER_SQUADRON.get(model, {})
		var model_table: Dictionary = model_table_value if model_table_value is Dictionary else {}
		var role_table_value = model_table.get(role, {})
		var role_table: Dictionary = role_table_value if role_table_value is Dictionary else {}
		tanker_count += int(role_table.get(route, 0))
	if tanker_count > 0:
		var tanker_index := _find_ready_blue_aircraft_index(aircraft, ["KC707"], tanker_count, excluded)
		if tanker_index < 0:
			return {"ok": false, "message": "The mission requires %d KC-707 tankers, but that many are not ready." % tanker_count}
		assignments.append(_reserve_blue_assignment(aircraft, tanker_index, tanker_count, "Tanker", "%s route refueling" % route, operation_id))

	return {
		"ok": true,
		"route": route,
		"target_id": target_id,
		"component_key": component_key,
		"squadron_index": selected_index,
		"loadout": loadout,
		"strike_aircraft": strike_count,
		"escort_aircraft": escort_count,
		"sead_aircraft": sead_count,
		"sead_loadout": sead_loadout,
		"shavit_aircraft": shavit_count,
		"eitan_aircraft": eitan_count,
		"tanker_aircraft": tanker_count,
		"air_defense_mp": clampi(int(args.get("air_defense_mp", 0)), 0, 6),
		"assignments": assignments,
		"aircraft": aircraft,
		"operation_id": operation_id
	}


static func _release_airstrike_assignments(snapshot: Dictionary, action: Dictionary) -> void:
	var aircraft := _aircraft_list(snapshot, "Blue")
	var operation_id := str(action.get("operation_id", ""))
	for assignment_value in action.get("assignments", []):
		if not assignment_value is Dictionary:
			continue
		var index := int((assignment_value as Dictionary).get("index", -1))
		if index < 0 or index >= aircraft.size():
			continue
		var row := (aircraft[index] as Dictionary).duplicate(true)
		if not operation_id.is_empty() and str(row.get("operation_id", "")) != operation_id:
			continue
		if str(row.get("mission", "")) == "Fragged":
			row["mission"] = "Ready"
		row["committed"] = 0
		row["assignment"] = ""
		row["loadout"] = ""
		row["operation_id"] = ""
		aircraft[index] = row
	snapshot["BlueAircraft"] = aircraft


static func add_planned_action(snapshot: Dictionary, args: Dictionary) -> Dictionary:
	var team_name := str(args.get("team", "")).strip_edges()
	if team_name != "Red" and team_name != "Blue":
		return _result(false, snapshot, "Choose Red or Blue for the planned action.")

	var action_name := str(args.get("action_name", "")).strip_edges()
	if action_name.is_empty():
		action_name = str(args.get("type", "Action")).strip_edges()
	var action_type := _canonical_action_type(team_name, action_name)
	if action_type.is_empty():
		return _result(false, snapshot, "%s cannot perform %s." % [team_name, action_name if not action_name.is_empty() else "that action"])
	var weather_value = snapshot.get("WeatherRestriction", {})
	var weather: Dictionary = weather_value if weather_value is Dictionary else {}
	if action_type == "Airstrike" and str(weather.get("team", "")) == team_name:
		return _result(false, snapshot, "%s aircraft cannot operate this map turn because of freak weather (%s)." % [team_name, str(weather.get("sector", "affected airspace"))])
	var attack_name := str(args.get("attack_name", "")).strip_edges()
	var display_name := attack_name if not attack_name.is_empty() else action_name
	var target := str(args.get("target", "")).strip_edges()
	var mission_type := str(args.get("mission_type", action_name)).strip_edges()
	var missile_type := str(args.get("missile_type", "Shahab-3")).strip_edges()
	var coordination_mp := maxi(0, int(args.get("coordination_mp", 0)))
	var wait_time := maxi(0, int(args.get("wait_time", 0)))
	var units := maxi(0, int(args.get("missiles", args.get("units", 0))))
	var ip_cost := 0
	var mp_cost := 0
	var pp_cost := 0
	var success_chance := 0
	var airstrike_plan: Dictionary = {}

	match action_type:
		"Airstrike":
			if target.is_empty():
				return _result(false, snapshot, "Choose an Iranian target for the airstrike.")
			var target_id := find_target_id(target)
			if target_id.is_empty():
				return _result(false, snapshot, "Choose a valid Iranian target for the airstrike.")
			units = clampi(units, 1, 24)
			airstrike_plan = _prepare_airstrike_plan(snapshot, args, target_id, units)
			if not bool(airstrike_plan.get("ok", false)):
				return _result(false, snapshot, str(airstrike_plan.get("message", "The airstrike plan is invalid.")))
			target = target_id
			ip_cost = 3
			mp_cost = 3 + int(airstrike_plan.get("air_defense_mp", 0))
			wait_time = 1
		"Special Warfare", "Terror Attack":
			ip_cost = int(args.get("ip_cost", 1))
			mp_cost = int(args.get("mp_cost", 1))
			if ip_cost < 1 or ip_cost > 4 or mp_cost < 1 or mp_cost > 3:
				return _result(false, snapshot, "%s requires 1-4 IP and 1-3 MP." % action_type)
			if ip_cost + mp_cost < 2 or ip_cost + mp_cost > 7:
				return _result(false, snapshot, "%s must spend 2-7 total points." % action_type)
			wait_time = clampi(wait_time, 1, 5)
			if action_type == "Terror Attack":
				mission_type = "Civil Economic"
				target = "Civil Economic Target"
			elif mission_type.is_empty():
				mission_type = "Civil Economic"
			success_chance = _special_warfare_chance(snapshot, team_name, ip_cost + mp_cost, wait_time)
			if team_name == "Blue" and mission_type.to_lower().contains("attack undamaged"):
				success_chance = maxi(0, success_chance - 30)
		"Ballistic Missile":
			if not bool(snapshot.get("ConflictStarted", false)):
				return _result(false, snapshot, "Iranian ballistic missiles cannot launch until Israel has attacked Iran.")
			if target.is_empty():
				return _result(false, snapshot, "Choose a target for the ballistic missile attack.")
			if not ["Shahab-3", "Sejil-2"].has(missile_type):
				return _result(false, snapshot, "Choose Shahab-3 or Sejil-2 missiles.")
			if coordination_mp > 2:
				return _result(false, snapshot, "Missile coordination can use at most 2 additional MP.")
			var available_battalions := _available_ballistic_battalions(snapshot, missile_type)
			if available_battalions <= 0:
				if missile_type == "Sejil-2" and _selected_upgrade_count(snapshot, "Red", "Sejil-2") <= 0:
					return _result(false, snapshot, "Iran must purchase a Sejil-2 battalion before ordering Sejil-2 missiles.")
				return _result(false, snapshot, "No %s battalions are available this map turn." % missile_type)
			# Early clients submitted individual missiles (four per battalion). Keep
			# those saves/network requests playable while treating current UI values
			# and explicit battalion fields as battalion counts.
			if not args.has("battalions") and units > available_battalions and units % 4 == 0:
				units = ceili(float(units) / 4.0)
			if units < 1 or units > available_battalions:
				return _result(false, snapshot, "Choose 1-%d available %s battalion(s)." % [available_battalions, missile_type])
			mp_cost = units + coordination_mp
			wait_time = 0 if missile_type == "Sejil-2" else 1
		"Reposition Air Defense":
			wait_time = 1
			units = 0
		"Close Strait":
			if not bool(snapshot.get("ConflictStarted", false)):
				return _result(false, snapshot, "Iran cannot attempt to close the Strait before an Israeli or US attack.")
			if int(snapshot.get("StraitCooldown", 0)) > 0:
				return _result(false, snapshot, "The Strait cannot be challenged again for %d map turn(s)." % int(snapshot.get("StraitCooldown", 0)))
			mp_cost = int(args.get("mp_cost", 1))
			pp_cost = int(args.get("pp_cost", 0))
			if mp_cost < 1 or mp_cost > 7 or pp_cost < 0 or pp_cost > 2:
				return _result(false, snapshot, "A Strait attempt costs 1-7 MP and up to 2 PP.")
			wait_time = 0
			units = 0

	var point_prefix := _point_prefix(team_name)
	if int(snapshot.get("%sIP" % point_prefix, 0)) < ip_cost:
		return _result(false, snapshot, "%s does not have enough IP for this action." % team_name)
	if int(snapshot.get("%sMP" % point_prefix, 0)) < mp_cost:
		return _result(false, snapshot, "%s does not have enough MP for this action." % team_name)
	if int(snapshot.get("%sPP" % point_prefix, 0)) < pp_cost:
		return _result(false, snapshot, "%s does not have enough PP for this action." % team_name)
	var next_snapshot := snapshot.duplicate(true)
	if action_type == "Airstrike":
		next_snapshot["BlueAircraft"] = airstrike_plan.get("aircraft", _aircraft_list(next_snapshot, "Blue"))
	next_snapshot["%sIP" % point_prefix] = int(next_snapshot.get("%sIP" % point_prefix, 0)) - ip_cost
	next_snapshot["%sMP" % point_prefix] = int(next_snapshot.get("%sMP" % point_prefix, 0)) - mp_cost
	next_snapshot["%sPP" % point_prefix] = int(next_snapshot.get("%sPP" % point_prefix, 0)) - pp_cost
	var planned := _clean_dictionary_array(next_snapshot.get("PlannedActions", []))
	var planned_entry := {
		"team": team_name,
		"action_name": action_name,
		"action_type": action_type,
		"mission_type": mission_type,
		"missile_type": missile_type,
		"coordination_mp": coordination_mp,
		"attack_name": attack_name,
		"display": display_name,
		"target": target,
		"wait_time": wait_time,
		"planned_wait": wait_time,
		"missiles": units,
		"battalions": units if action_type == "Ballistic Missile" else 0,
		"ip_cost": ip_cost,
		"mp_cost": mp_cost,
		"pp_cost": pp_cost,
		"success_chance": success_chance,
		"created_at": Time.get_datetime_string_from_system(false, true)
	}
	if action_type == "Airstrike":
		for plan_key in airstrike_plan.keys():
			if plan_key not in ["ok", "message", "aircraft"]:
				planned_entry[plan_key] = airstrike_plan[plan_key]
	planned.append(planned_entry)
	next_snapshot["PlannedActions"] = planned
	var covert_action := action_type == "Special Warfare" or action_type == "Terror Attack"
	next_snapshot["%sLastActionOvert" % team_name] = not covert_action
	_add_log(next_snapshot, "%s planned %s." % [team_name, display_name])
	return _result(true, next_snapshot, "Planned action added.")


static func remove_planned_action(snapshot: Dictionary, index: int) -> Dictionary:
	var planned := _clean_dictionary_array(snapshot.get("PlannedActions", []))
	if index < 0 or index >= planned.size():
		return _result(false, snapshot, "Choose a planned action first.")
	var removed := planned.pop_at(index) as Dictionary
	var next_snapshot := snapshot.duplicate(true)
	next_snapshot["PlannedActions"] = planned
	if str(removed.get("action_type", "")) == "Airstrike":
		_release_airstrike_assignments(next_snapshot, removed)
	var team_name := str(removed.get("team", ""))
	if ["Red", "Blue"].has(team_name):
		var point_prefix := _point_prefix(team_name)
		next_snapshot["%sIP" % point_prefix] = int(next_snapshot.get("%sIP" % point_prefix, 0)) + maxi(0, int(removed.get("ip_cost", 0)))
		next_snapshot["%sMP" % point_prefix] = int(next_snapshot.get("%sMP" % point_prefix, 0)) + maxi(0, int(removed.get("mp_cost", 0)))
		next_snapshot["%sPP" % point_prefix] = int(next_snapshot.get("%sPP" % point_prefix, 0)) + maxi(0, int(removed.get("pp_cost", 0)))
	_add_log(next_snapshot, "Removed planned action: %s." % str(removed.get("display", removed.get("action_name", "Action"))))
	return _result(true, next_snapshot, "Planned action removed.")


static func purchase_upgrade(snapshot: Dictionary, team_name: String, upgrade_name: String) -> Dictionary:
	var clean_team := team_name.strip_edges()
	if not ["Red", "Blue", "RedExtra"].has(clean_team):
		return _result(false, snapshot, "Unknown upgrade team.")
	var upgrade := find_upgrade(clean_team, upgrade_name)
	if upgrade.is_empty():
		return _result(false, snapshot, "Upgrade not found.")
	var requirement_error := upgrade_requirement_error(snapshot, clean_team, upgrade)
	if not requirement_error.is_empty():
		return _result(false, snapshot, requirement_error)

	var next_snapshot := snapshot.duplicate(true)
	var selected := _clean_selected_upgrades(next_snapshot.get("SelectedUpgrades", {}))
	var points := _clean_upgrade_points(next_snapshot.get("UpgradePoints", {}))
	var team_selected: Array = selected.get(clean_team, [])
	var clean_name := str(upgrade.get("name", upgrade_name))
	if not bool(upgrade.get("stackable", false)):
		for item in team_selected:
			if item is Dictionary and str(item.get("name", "")) == clean_name:
				return _result(false, snapshot, "%s cannot be purchased twice." % clean_name)

	var cost := int(upgrade.get("cost", 0))
	if int(points.get(clean_team, 0)) < cost:
		return _result(false, snapshot, "Not enough upgrade points for %s." % clean_name)

	points[clean_team] = int(points.get(clean_team, 0)) - cost
	team_selected.append(upgrade.duplicate(true))
	selected[clean_team] = team_selected
	next_snapshot["SelectedUpgrades"] = selected
	next_snapshot["UpgradePoints"] = points
	_sync_upgrade_text(next_snapshot)
	_add_log(next_snapshot, "%s purchased upgrade: %s." % [clean_team, clean_name])
	return _result(true, next_snapshot, "%s purchased." % clean_name)


static func upgrade_requirement_error(snapshot: Dictionary, team_name: String, upgrade: Dictionary) -> String:
	var description := str(upgrade.get("description", "")).to_lower()
	var upgrade_name := str(upgrade.get("name", "")).to_lower()
	if not description.contains("require") and team_name != "RedExtra":
		return ""

	var country_code := ""
	var country_name := ""
	if description.contains("china") or description.contains("prc") or upgrade_name.contains("hq-9") or upgrade_name.contains("j-10") or upgrade_name.contains("j-11") or upgrade_name.contains("kj-2000") or upgrade_name.contains("pl-5"):
		country_code = "PRC"
		country_name = "PRC"
	elif description.contains("russia") or upgrade_name.contains("r-27") or upgrade_name.contains("a-50") or upgrade_name.contains("buk-m1") or upgrade_name.contains("mig-29smt") or upgrade_name.contains("mig-31") or upgrade_name.contains("su-27"):
		country_code = "RU"
		country_name = "Russia"
	elif description.contains("turkey"):
		country_code = "TR"
		country_name = "Turkey"
	elif description.contains("saudi"):
		country_code = "SA"
		country_name = "Saudi Arabia"
	elif description.contains("united states") or description.contains(" u.s") or description.contains(" us "):
		country_code = "US"
		country_name = "US & Iraq"

	if country_code.is_empty():
		return ""
	var required_position := 9 if description.contains("ally") or team_name == "RedExtra" else 5
	var track := _clean_track(snapshot.get("PoliticalTrack", {}))
	var position := int(track.get(country_code, 0))
	var purchasing_side := "Red" if team_name == "RedExtra" else team_name
	var requirement_met := position <= -required_position if purchasing_side == "Red" else position >= required_position
	if requirement_met:
		return ""
	var status_name := "Ally" if required_position >= 9 else "Supporter"
	return "%s must be a %s of %s before this upgrade can be purchased." % [country_name, status_name, purchasing_side]


static func refund_upgrade(snapshot: Dictionary, team_name: String, index: int) -> Dictionary:
	var clean_team := team_name.strip_edges()
	if not ["Red", "Blue", "RedExtra"].has(clean_team):
		return _result(false, snapshot, "Unknown upgrade team.")
	var selected := _clean_selected_upgrades(snapshot.get("SelectedUpgrades", {}))
	var team_selected: Array = selected.get(clean_team, [])
	if index < 0 or index >= team_selected.size():
		return _result(false, snapshot, "Choose an upgrade first.")
	var removed := team_selected.pop_at(index) as Dictionary
	var points := _clean_upgrade_points(snapshot.get("UpgradePoints", {}))
	points[clean_team] = int(points.get(clean_team, 0)) + int(removed.get("cost", 0))
	selected[clean_team] = team_selected

	var next_snapshot := snapshot.duplicate(true)
	next_snapshot["SelectedUpgrades"] = selected
	next_snapshot["UpgradePoints"] = points
	_sync_upgrade_text(next_snapshot)
	_add_log(next_snapshot, "%s refunded upgrade: %s." % [clean_team, str(removed.get("name", "Upgrade"))])
	return _result(true, next_snapshot, "Upgrade refunded.")


static func adjust_aircraft(snapshot: Dictionary, team_name: String, index: int, field: String, amount: int, set_value: bool = false) -> Dictionary:
	if not ["Red", "Blue"].has(team_name):
		return _result(false, snapshot, "Unknown aircraft team.")
	var field_name := field.strip_edges().to_lower()
	if not ["operational", "damaged", "downed", "missing", "kia", "total"].has(field_name):
		return _result(false, snapshot, "Unknown aircraft field.")
	var aircraft := _aircraft_list(snapshot, team_name)
	if index < 0 or index >= aircraft.size():
		return _result(false, snapshot, "Choose an aircraft squadron first.")

	var row := (aircraft[index] as Dictionary).duplicate(true)
	var current_value := int(row.get(field_name, 0))
	var next_value := amount if set_value else current_value + amount
	row[field_name] = maxi(0, next_value)
	if field_name == "operational":
		row["operational"] = mini(int(row.get("operational", 0)), int(row.get("total", row.get("operational", 0))))
	if field_name == "damaged":
		row["damaged"] = mini(int(row.get("damaged", 0)), int(row.get("total", row.get("damaged", 0))))
	if field_name == "downed":
		row["downed"] = mini(int(row.get("downed", 0)), int(row.get("total", row.get("downed", 0))))
	aircraft[index] = row

	var next_snapshot := snapshot.duplicate(true)
	next_snapshot[_aircraft_key(team_name)] = aircraft
	var message := "%s %s %s changed to %d." % [team_name, str(row.get("name", "Squadron")), field_name, int(row.get(field_name, 0))]
	_add_aircraft_event(next_snapshot, message)
	_add_log(next_snapshot, message)
	return _result(true, next_snapshot, "Aircraft status updated.")


static func set_aircraft_field(snapshot: Dictionary, team_name: String, index: int, field: String, value) -> Dictionary:
	if not ["Red", "Blue"].has(team_name):
		return _result(false, snapshot, "Unknown aircraft team.")
	var field_name := field.strip_edges().to_lower()
	if not ["mission", "location"].has(field_name):
		return _result(false, snapshot, "Unknown aircraft field.")
	var aircraft := _aircraft_list(snapshot, team_name)
	if index < 0 or index >= aircraft.size():
		return _result(false, snapshot, "Choose an aircraft squadron first.")

	var row := (aircraft[index] as Dictionary).duplicate(true)
	var requested_value := str(value).strip_edges()
	if requested_value.is_empty():
		requested_value = "Ready" if field_name == "mission" else "Home"
	var current_value := str(row.get(field_name, ""))
	if field_name == "mission":
		if requested_value == "StandDown":
			requested_value = "Stand Down"
		var legal_missions := RED_AIRCRAFT_MISSIONS if team_name == "Red" else BLUE_AIRCRAFT_MISSIONS
		if not legal_missions.has(requested_value):
			return _result(false, snapshot, "%s is not a legal %s aircraft status." % [requested_value, team_name])
		if team_name == "Blue":
			if not ["Ready", "Fragged"].has(requested_value):
				return _result(false, snapshot, "Blue in-flight and resting states advance automatically each map turn.")
			if requested_value == "Fragged" and not ["Ready", "Resting", "Fragged"].has(current_value):
				return _result(false, snapshot, "Only Ready or Resting Blue squadrons can receive new orders.")
			if requested_value == "Ready" and not ["Ready", "Fragged"].has(current_value):
				return _result(false, snapshot, "A Blue squadron already in flight must complete its mission cycle.")
	if team_name == "Red" and requested_value != current_value:
		if not bool(snapshot.get("ConflictStarted", false)):
			return _result(false, snapshot, "Iranian squadrons cannot change status or airfield until after the first Israeli attack.")
		var changed_value = snapshot.get("RedAircraftChangedIndices", [])
		var changed: Array = changed_value.duplicate() if changed_value is Array else []
		if not changed.has(index) and changed.size() >= 3:
			return _result(false, snapshot, "Red can change at most three squadron assignments per map turn.")
		if not changed.has(index):
			changed.append(index)
		snapshot = snapshot.duplicate(true)
		snapshot["RedAircraftChangedIndices"] = changed
	row[field_name] = requested_value
	aircraft[index] = row

	var next_snapshot := snapshot.duplicate(true)
	next_snapshot[_aircraft_key(team_name)] = aircraft
	var message := "%s %s %s set to %s." % [team_name, str(row.get("name", "Squadron")), field_name, str(row[field_name])]
	_add_aircraft_event(next_snapshot, message)
	_add_log(next_snapshot, message)
	return _result(true, next_snapshot, "Aircraft status updated.")


static func roll_aircraft_event(snapshot: Dictionary, team_name: String, mode: String) -> Dictionary:
	if not ["Red", "Blue"].has(team_name):
		return _result(false, snapshot, "Unknown aircraft team.")
	var clean_mode := mode.strip_edges().to_lower()
	if _aircraft_list(snapshot, team_name).is_empty():
		return _result(false, snapshot, "No aircraft are available.")

	var next_snapshot := snapshot.duplicate(true)
	var message := ""
	if clean_mode == "repair":
		var day := int(next_snapshot.get("TurnDay", 0))
		if day <= 0 or int(next_snapshot.get("TurnTime", 3)) != 0:
			return _result(false, snapshot, "Aircraft repairs are resolved once at the start of a Morning turn.")
		message = _repair_all_aircraft(next_snapshot, team_name, day)
		if message.is_empty():
			return _result(false, snapshot, "%s repairs were already resolved for Day %d." % [team_name, day])
	elif clean_mode == "breakdown":
		if team_name == "Red":
			message = _run_red_breakdowns(next_snapshot)
			if message.is_empty():
				return _result(false, snapshot, "Red squadron breakdowns were already resolved for this map turn.")
		else:
			message = _resolve_blue_return_breakdowns(next_snapshot)
			if message.is_empty():
				return _result(false, snapshot, "No Blue squadron is returning from an airstrike.")
	else:
		return _result(false, snapshot, "Unknown aircraft roll.")
	return _result(true, next_snapshot, message)


static func all_target_metadata() -> Array:
	if not _target_metadata_cache.is_empty():
		return _target_metadata_cache
	if not FileAccess.file_exists(TARGET_METADATA_PATH):
		return []
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(TARGET_METADATA_PATH))
	if parsed is Array:
		for item in parsed:
			if item is Dictionary:
				_target_metadata_cache.append((item as Dictionary).duplicate(true))
	return _target_metadata_cache


static func default_targets_state() -> Dictionary:
	var state := {}
	for target in all_target_metadata():
		var target_dict := target as Dictionary
		var target_id := str(target_dict.get("id", ""))
		if target_id.is_empty():
			continue
		var component_state := {}
		for component in target_dict.get("components", []):
			var key := str((component as Dictionary).get("key", ""))
			if not key.is_empty():
				component_state[key] = 0
		state[target_id] = component_state
	return state


static func clean_targets_state(value) -> Dictionary:
	var cleaned := {}
	if value is Dictionary:
		for target_id in value.keys():
			var component_value = value[target_id]
			var component_cleaned := {}
			if component_value is Dictionary:
				for key in component_value.keys():
					component_cleaned[str(key)] = int(component_value[key])
			cleaned[str(target_id)] = component_cleaned
	return cleaned


static func merge_targets_with_defaults(value) -> Dictionary:
	var defaults := default_targets_state()
	var cleaned := clean_targets_state(value)
	for target_id in defaults.keys():
		var default_components: Dictionary = defaults[target_id]
		var existing_components: Dictionary = cleaned.get(target_id, {})
		for component_key in default_components.keys():
			if not existing_components.has(component_key):
				existing_components[component_key] = default_components[component_key]
		cleaned[target_id] = existing_components
	return cleaned


static func target_status_rows(snapshot: Dictionary) -> Array:
	var rows: Array = []
	var targets_state := merge_targets_with_defaults(snapshot.get("Targets", {}))
	for target in all_target_metadata():
		var target_dict := target as Dictionary
		var target_id := str(target_dict.get("id", ""))
		var state: Dictionary = targets_state.get(target_id, {})
		var component_rows: Array = []
		var primary_count := 0
		var primary_damaged := true
		var all_destroyed := true
		for component in target_dict.get("components", []):
			var component_dict := component as Dictionary
			var key := str(component_dict.get("key", ""))
			var damaged_boxes := maxi(0, int(component_dict.get("damaged_boxes", component_dict.get("boxes", 1))))
			var destroyed_boxes := maxi(0, int(component_dict.get("destroyed_boxes", 0)))
			var boxes := maxi(1, int(component_dict.get("boxes", damaged_boxes + destroyed_boxes)))
			var damaged := int(state.get(key, 0))
			var role := str(component_dict.get("role", "Primary"))
			# A zero damaged band means this component has only an intact/destroyed
			# state. It must reach its full box count before it contributes to a
			# tactical target result.
			var damage_threshold := damaged_boxes if damaged_boxes > 0 else boxes
			var damage_threshold_met := damaged >= damage_threshold
			var destroyed := damaged >= boxes
			if role == "Primary":
				primary_count += 1
				if not damage_threshold_met:
					primary_damaged = false
			if not destroyed:
				all_destroyed = false
			component_rows.append({
				"key": key,
				"name": str(component_dict.get("name", key)),
				"role": role,
				"size_class": str(component_dict.get("size_class", "C")),
				"armor": int(component_dict.get("armor", 0)),
				"damaged": damaged,
				"damaged_boxes": damaged_boxes,
				"boxes": boxes,
				"damage_threshold_met": damage_threshold_met,
				"destroyed": destroyed
			})
		var tactical := primary_count > 0 and primary_damaged
		var decisive := not component_rows.is_empty() and all_destroyed
		var victory_level := "Decisive" if decisive else ("Tactical" if tactical else "None")
		var capacity := maxi(0, int(target_dict.get("capacity", 0)))
		var remaining_capacity := float(capacity)
		if victory_level == "Tactical":
			remaining_capacity *= 0.5
		elif victory_level == "Decisive":
			remaining_capacity = 0.0
		rows.append({
			"id": target_id,
			"name": str(target_dict.get("name", target_id)),
			"type": str(target_dict.get("type", "")),
			"oil_category": str(target_dict.get("oil_category", "")),
			"capacity": capacity,
			"remaining_capacity": remaining_capacity,
			"sector": str(target_dict.get("sector", "")),
			"routes": target_dict.get("routes", []),
			"components": component_rows,
			"tactical": tactical,
			"decisive": decisive,
			"victory_level": victory_level,
			"destroyed": decisive
		})
	return rows


static func find_target_id(query: String) -> String:
	var clean_query := query.strip_edges().to_lower()
	if clean_query.is_empty():
		return ""
	for target in all_target_metadata():
		var target_dict := target as Dictionary
		var target_id := str(target_dict.get("id", ""))
		var target_name := str(target_dict.get("name", "")).to_lower()
		if target_id.to_lower() == clean_query or target_name == clean_query:
			return target_id
		if target_name.contains(clean_query) or (not target_id.is_empty() and clean_query.contains(target_id.to_lower())):
			return target_id
	return ""


static func adjust_target_damage(snapshot: Dictionary, target_id: String, component_key: String, amount: int, set_value: bool = false) -> Dictionary:
	var target := _find_target_metadata(target_id)
	if target.is_empty():
		return _result(false, snapshot, "Unknown strategic target.")
	var component := _find_target_component(target, component_key)
	if component.is_empty():
		return _result(false, snapshot, "Unknown target component.")

	var next_snapshot := snapshot.duplicate(true)
	var targets_state := merge_targets_with_defaults(next_snapshot.get("Targets", {}))
	var target_state: Dictionary = targets_state.get(target_id, {})
	var boxes := maxi(1, int(component.get("boxes", 1)))
	var current_damage := int(target_state.get(component_key, 0))
	var next_damage: int = amount if set_value else current_damage + amount
	next_damage = clampi(next_damage, 0, boxes)
	target_state[component_key] = next_damage
	targets_state[target_id] = target_state
	next_snapshot["Targets"] = targets_state

	var component_name := str(component.get("name", component_key))
	var target_name := str(target.get("name", target_id))
	var status := "DESTROYED" if next_damage >= boxes else "%d/%d damaged" % [next_damage, boxes]
	var message := "%s - %s: %s" % [target_name, component_name, status]
	_add_log(next_snapshot, message)
	return _result(true, next_snapshot, message)


static func resolve_planned_action(snapshot: Dictionary, index: int) -> Dictionary:
	var planned := _clean_dictionary_array(snapshot.get("PlannedActions", []))
	if index < 0 or index >= planned.size():
		return _result(false, snapshot, "Choose a planned action first.")

	var next_snapshot := snapshot.duplicate(true)
	var summary := _resolve_planned_action_at(next_snapshot, index)
	return _result(true, next_snapshot, summary)


static func evaluate_victory(snapshot: Dictionary) -> Dictionary:
	var strategy_value = snapshot.get("StrategyVictory", {})
	if strategy_value is Dictionary and not (strategy_value as Dictionary).is_empty():
		return (strategy_value as Dictionary).duplicate(true)

	var track := _clean_track(snapshot.get("PoliticalTrack", {}))
	var day := int(snapshot.get("TurnDay", 0))
	if int(track.get("IR", 0)) >= 10:
		return {"winner": "Blue", "reason": "Iranian domestic opinion reached +10 and Iran sued for terms.", "day": day, "condition": "Iranian domestic opinion"}
	if int(track.get("IL", 0)) <= -10:
		return {"winner": "Red", "reason": "Israeli domestic opinion reached -10 and the campaign was called off.", "day": day, "condition": "Israeli domestic opinion"}

	var oil := _oil_capacity_summary(snapshot)
	if float(oil.get("refinery_remaining", 100.0)) <= 50.0 and float(oil.get("terminal_remaining", 100.0)) <= 15.0:
		return {
			"winner": "Blue",
			"reason": "Iranian refinery capacity fell to %.1f%% and terminal capacity to %.1f%%." % [float(oil.get("refinery_remaining", 0.0)), float(oil.get("terminal_remaining", 0.0))],
			"day": day,
			"condition": "Oil campaign"
		}

	var campaign_days := maxi(1, int(snapshot.get("CampaignDays", MAX_DAY)))
	if day >= campaign_days:
		return {"winner": "Red", "reason": "Israel did not achieve a victory condition within %d campaign days." % campaign_days, "day": day, "condition": "Campaign limit"}
	return {"winner": "Undecided", "reason": "No campaign victory condition has been met.", "day": day, "condition": "In progress"}


static func _find_target_metadata(target_id: String) -> Dictionary:
	if target_id.is_empty():
		return {}
	for target in all_target_metadata():
		if str((target as Dictionary).get("id", "")) == target_id:
			return (target as Dictionary).duplicate(true)
	return {}


static func _find_target_component(target: Dictionary, component_key: String) -> Dictionary:
	if component_key.is_empty():
		return {}
	for component in target.get("components", []):
		if str((component as Dictionary).get("key", "")) == component_key:
			return (component as Dictionary).duplicate(true)
	return {}


static func _target_victory_level(snapshot: Dictionary, target_id: String) -> String:
	for row in target_status_rows(snapshot):
		if str((row as Dictionary).get("id", "")) == target_id:
			return str((row as Dictionary).get("victory_level", "None"))
	return "None"


static func _victory_level_rank(level: String) -> int:
	match level:
		"Tactical":
			return 1
		"Decisive":
			return 2
	return 0


static func _oil_capacity_summary(snapshot: Dictionary) -> Dictionary:
	var refinery_total := 0.0
	var terminal_total := 0.0
	var refinery_remaining := 0.0
	var terminal_remaining := 0.0
	for row in target_status_rows(snapshot):
		var row_dict := row as Dictionary
		if str(row_dict.get("type", "")) != "Oil":
			continue
		var capacity := float(row_dict.get("capacity", 0.0))
		var remaining := float(row_dict.get("remaining_capacity", capacity))
		if str(row_dict.get("oil_category", "")) == "Refinery":
			refinery_total += capacity
			refinery_remaining += remaining
		elif str(row_dict.get("oil_category", "")) == "Terminal":
			terminal_total += capacity
			terminal_remaining += remaining
	return {
		"refinery_total": refinery_total,
		"terminal_total": terminal_total,
		"refinery_remaining": refinery_remaining,
		"terminal_remaining": terminal_remaining
	}


static func _set_strategy_victory(snapshot: Dictionary, winner: String, reason: String, condition: String) -> void:
	var result := {"winner": winner, "reason": reason, "day": int(snapshot.get("TurnDay", 0)), "condition": condition}
	snapshot["StrategyVictory"] = result
	snapshot["GameOver"] = true
	snapshot["GameOverSummary"] = result.duplicate(true)
	_add_log(snapshot, "%s victory: %s" % [winner, reason])


static func _process_target_victory_change(snapshot: Dictionary, target_id: String, before_level: String, after_level: String) -> String:
	if _victory_level_rank(after_level) <= _victory_level_rank(before_level):
		return ""
	var target := _find_target_metadata(target_id)
	if target.is_empty():
		return ""
	var levels_value = snapshot.get("TargetVictoryLevels", {})
	var levels: Dictionary = levels_value.duplicate(true) if levels_value is Dictionary else {}
	levels[target_id] = after_level
	snapshot["TargetVictoryLevels"] = levels
	if str(target.get("type", "")) == "Nuclear":
		return _resolve_nuclear_victory_result(snapshot, target, after_level)
	if str(target.get("type", "")) == "Oil":
		return _resolve_oil_victory_result(snapshot, target, after_level)
	return "%s achieved a %s result at %s." % ["Blue", after_level, str(target.get("name", target_id))]


static func _resolve_nuclear_victory_result(snapshot: Dictionary, target: Dictionary, victory_level: String) -> String:
	var target_id := str(target.get("id", ""))
	var decisive_sites := _clean_string_array(snapshot.get("NuclearDecisiveSites", []))
	if victory_level == "Decisive" and not decisive_sites.has(target_id):
		decisive_sites.append(target_id)
		snapshot["NuclearDecisiveSites"] = decisive_sites
	var track := _clean_track(snapshot.get("PoliticalTrack", {}))
	var iran_position := int(track.get("IR", 0))
	var modifier := 0
	if iran_position >= 5:
		modifier += 4
	elif iran_position >= 3:
		modifier += 2
	elif iran_position >= 1:
		modifier += 1
	modifier += maxi(0, decisive_sites.size() - 1) * 2
	modifier -= int(snapshot.get("BlueAircraftLosses", 0)) / 4
	if victory_level == "Tactical":
		modifier -= 2
	var raw_roll := randi_range(1, 6) + randi_range(1, 6)
	var modified_roll := raw_roll + modifier
	var effects: Array[String] = []
	if modified_roll <= 3:
		effects.append(_roll_opinion_attempts(snapshot, "Red", "IR", 3, "nuclear victory result"))
	elif modified_roll <= 5:
		effects.append(_roll_opinion_attempts(snapshot, "Blue", "IL", 1, "nuclear victory result"))
		effects.append(_roll_opinion_attempts(snapshot, "Red", "IR", 1, "nuclear victory result"))
	elif modified_roll <= 7:
		effects.append(_roll_opinion_attempts(snapshot, "Blue", "IL", 1, "nuclear victory result"))
		snapshot["IsrealPP"] = int(snapshot.get("IsrealPP", 0)) + 2
		snapshot["IranPP"] = maxi(0, int(snapshot.get("IranPP", 0)) - 2)
		effects.append("Blue +2 PP; Red -2 PP")
	elif modified_roll <= 9:
		effects.append(_roll_opinion_attempts(snapshot, "Blue", "IL", 2, "nuclear victory result"))
		snapshot["IsrealPP"] = int(snapshot.get("IsrealPP", 0)) + 3
		snapshot["IranPP"] = maxi(0, int(snapshot.get("IranPP", 0)) - 4)
		effects.append("Blue +3 PP; Red -4 PP")
	elif modified_roll <= 11:
		effects.append(_roll_opinion_attempts(snapshot, "Blue", "IL", 2, "nuclear victory result"))
		snapshot["IsrealPP"] = int(snapshot.get("IsrealPP", 0)) + 4
		snapshot["IranPP"] = maxi(0, int(snapshot.get("IranPP", 0)) - 6)
		effects.append("Blue +4 PP; Red -6 PP")
	elif modified_roll <= 13:
		effects.append(_roll_opinion_attempts(snapshot, "Blue", "IL", 3, "nuclear victory result"))
		snapshot["IsrealPP"] = int(snapshot.get("IsrealPP", 0)) + 5
		snapshot["IranPP"] = maxi(0, int(snapshot.get("IranPP", 0)) - 8)
		effects.append("Blue +5 PP; Red -8 PP")
	else:
		var reason := "%s earned a %s nuclear result; the modified victory roll was %d and Iran sued for terms." % [str(target.get("name", target_id)), victory_level, modified_roll]
		_set_strategy_victory(snapshot, "Blue", reason, "Nuclear campaign")
		effects.append("Iran sues for terms")
	var record := {"target_id": target_id, "level": victory_level, "raw_roll": raw_roll, "modifier": modifier, "total": modified_roll, "effects": effects}
	var history := _clean_dictionary_array(snapshot.get("NuclearVictoryResults", []))
	history.append(record)
	snapshot["NuclearVictoryResults"] = history
	var roll_history := _clean_dictionary_array(snapshot.get("VictoryRollHistory", []))
	roll_history.append(record.duplicate(true))
	snapshot["VictoryRollHistory"] = roll_history
	_check_immediate_victory(snapshot)
	var summary := "%s %s: nuclear victory 2D6 %d %+d = %d. %s" % [str(target.get("name", target_id)), victory_level, raw_roll, modifier, modified_roll, " ".join(effects)]
	_add_dice_log(snapshot, summary)
	_add_log(snapshot, summary)
	return summary


static func _resolve_oil_victory_result(snapshot: Dictionary, target: Dictionary, victory_level: String) -> String:
	var dice := 2 if victory_level == "Decisive" else 1
	var effects: Array[String] = []
	for country_code in ["IR", "PRC", "RU", "SA"]:
		effects.append(_roll_opinion_attempts(snapshot, "Blue", country_code, dice, "oil victory result"))
	var oil := _oil_capacity_summary(snapshot)
	var record := {
		"target_id": str(target.get("id", "")),
		"level": victory_level,
		"dice": dice,
		"refinery_remaining": float(oil.get("refinery_remaining", 100.0)),
		"terminal_remaining": float(oil.get("terminal_remaining", 100.0))
	}
	var history := _clean_dictionary_array(snapshot.get("OilVictoryResults", []))
	history.append(record)
	snapshot["OilVictoryResults"] = history
	if float(oil.get("refinery_remaining", 100.0)) <= 50.0 and float(oil.get("terminal_remaining", 100.0)) <= 15.0:
		_set_strategy_victory(snapshot, "Blue", "Iranian refinery capacity fell to %.1f%% and terminal capacity to %.1f%%." % [float(oil.get("refinery_remaining", 0.0)), float(oil.get("terminal_remaining", 0.0))], "Oil campaign")
	_check_immediate_victory(snapshot)
	var summary := "%s %s: Blue rolled %d opinion die/dice on IR, PRC, RU and SA. Capacity now refinery %.1f%%, terminal %.1f%%." % [str(target.get("name", "Oil target")), victory_level, dice, float(oil.get("refinery_remaining", 0.0)), float(oil.get("terminal_remaining", 0.0))]
	_add_log(snapshot, summary)
	return summary


static func _apply_target_damage(snapshot: Dictionary, target_id: String, hits: int) -> String:
	var target := _find_target_metadata(target_id)
	if target.is_empty() or hits <= 0:
		return ""

	var targets_state := merge_targets_with_defaults(snapshot.get("Targets", {}))
	var target_state: Dictionary = targets_state.get(target_id, {})
	var components: Array = target.get("components", [])
	var remaining_hits := hits
	var messages: Array[String] = []

	for component in components:
		if remaining_hits <= 0:
			break
		var component_dict := component as Dictionary
		var key := str(component_dict.get("key", ""))
		var boxes := maxi(1, int(component_dict.get("boxes", 1)))
		var damaged := int(target_state.get(key, 0))
		if damaged >= boxes:
			continue
		var applied := mini(remaining_hits, boxes - damaged)
		damaged += applied
		remaining_hits -= applied
		target_state[key] = damaged
		var component_name := str(component_dict.get("name", key))
		if damaged >= boxes:
			messages.append("%s DESTROYED" % component_name)
		else:
			messages.append("%s damaged %d/%d" % [component_name, damaged, boxes])

	targets_state[target_id] = target_state
	snapshot["Targets"] = targets_state

	var target_name := str(target.get("name", target_id))
	if messages.is_empty():
		return "%s: no further damage possible (fully destroyed)." % target_name
	return "%s: %s." % [target_name, ", ".join(messages)]


static func _resolve_planned_action_at(snapshot: Dictionary, index: int) -> String:
	var planned := _clean_dictionary_array(snapshot.get("PlannedActions", []))
	if index < 0 or index >= planned.size():
		return ""

	var action := (planned[index] as Dictionary).duplicate(true)
	planned.remove_at(index)
	snapshot["PlannedActions"] = planned
	var team_name := str(action.get("team", ""))
	var action_type := str(action.get("action_type", _canonical_action_type(str(action.get("team", "")), str(action.get("action_name", "")))))
	var summary := ""
	match action_type:
		"Ballistic Missile":
			summary = _resolve_ballistic_missile_action(snapshot, action)
		"Airstrike":
			summary = _resolve_strike_action(snapshot, action)
		"Special Warfare", "Terror Attack":
			summary = _resolve_special_warfare_action(snapshot, action)
		"Reposition Air Defense":
			summary = _resolve_reposition_action(snapshot, action)
		"Close Strait":
			summary = _resolve_close_strait_action(snapshot, action)
		_:
			summary = _resolve_strike_action(snapshot, action)
	if team_name in ["Red", "Blue"] and action_type not in ["Special Warfare", "Terror Attack"]:
		var overt_turns_value = snapshot.get("LastOvertMapTurn", {})
		var overt_turns: Dictionary = overt_turns_value.duplicate(true) if overt_turns_value is Dictionary else {"Red": -999, "Blue": -999}
		overt_turns[team_name] = _map_turn_number(snapshot)
		snapshot["LastOvertMapTurn"] = overt_turns
	return summary


static func _resolve_ballistic_missile_action(snapshot: Dictionary, action: Dictionary) -> String:
	var missile_type := str(action.get("missile_type", "Shahab-3"))
	var battalions := clampi(int(action.get("battalions", action.get("missiles", 1))), 1, 4)
	var target_type := _ballistic_target_type(str(action.get("target", "Urban")))
	var launch_counts: Array[int] = []
	var coordination_rolls: Array[int] = []
	var launch_notes: Array[String] = []
	for battalion_index in range(battalions):
		var failure_roll := randi_range(1, 6) + randi_range(1, 6)
		var failures := _ballistic_launch_failures(failure_roll)
		var launched := maxi(0, 4 - failures)
		launch_counts.append(launched)
		coordination_rolls.append(randi_range(1, 10))
		launch_notes.append("B%d 2D6=%d: %d launched" % [battalion_index + 1, failure_roll, launched])

	var coordination_mp := clampi(int(action.get("coordination_mp", 0)), 0, 2)
	var adjusted_rolls := _coordinate_ballistic_rolls(coordination_rolls, coordination_mp)
	var groups := {}
	for battalion_index in range(launch_counts.size()):
		var coordination_value := int(adjusted_rolls[battalion_index])
		groups[coordination_value] = int(groups.get(coordination_value, 0)) + launch_counts[battalion_index]

	var incoming_total := 0
	var intercepted_total := 0
	var impact_total := 0
	var defense_notes: Array[String] = []
	var impact_notes: Array[String] = []
	var group_keys: Array = groups.keys()
	group_keys.sort()
	for group_key in group_keys:
		var incoming := int(groups[group_key])
		if incoming <= 0:
			continue
		incoming_total += incoming
		var defense := _resolve_ballistic_defenses(snapshot, incoming, target_type)
		var survivors := int(defense.get("survivors", incoming))
		intercepted_total += incoming - survivors
		defense_notes.append("coord %d: %s" % [int(group_key), str(defense.get("summary", "no defense"))])
		for _missile_index in range(survivors):
			impact_total += 1
			impact_notes.append(_resolve_ballistic_damage(snapshot, target_type, missile_type))

	var cooldowns := _clean_dictionary_array(snapshot.get("BallisticBattalionCooldowns", []))
	cooldowns.append({
		"missile_type": missile_type,
		"battalions": battalions,
		"ready_turn": _map_turn_number(snapshot) + 1
	})
	snapshot["BallisticBattalionCooldowns"] = cooldowns
	var display := str(action.get("display", action.get("action_name", "Ballistic Missile")))
	var summary := "Red %s (%s) resolved against %s: %d battalion(s), %d launched, %d intercepted, %d impact(s)." % [
		display,
		missile_type,
		target_type,
		battalions,
		incoming_total,
		intercepted_total,
		impact_total
	]
	var coordination_text := "coordination %s" % _int_array_to_string(coordination_rolls, ", ")
	if adjusted_rolls != coordination_rolls:
		coordination_text += " -> %s (%d MP)" % [_int_array_to_string(adjusted_rolls, ", "), coordination_mp]
	var detail := "%s; %s; %s" % ["; ".join(launch_notes), coordination_text, "; ".join(defense_notes)]
	if not impact_notes.is_empty():
		detail += "; " + " ".join(impact_notes)
	_add_log(snapshot, "%s %s" % [summary, detail])
	_add_dice_log(snapshot, "%s %s" % [summary, detail])
	var history := _clean_dictionary_array(snapshot.get("BallisticAttackHistory", []))
	history.append({
		"map_turn": _map_turn_number(snapshot),
		"name": display,
		"missile_type": missile_type,
		"target": target_type,
		"battalions": battalions,
		"launched": incoming_total,
		"intercepted": intercepted_total,
		"impacts": impact_total,
		"summary": summary,
		"details": detail
	})
	while history.size() > 60:
		history.pop_front()
	snapshot["BallisticAttackHistory"] = history
	return summary


static func _ballistic_launch_failures(roll_2d6: int) -> int:
	if roll_2d6 <= 6:
		return 0
	if roll_2d6 <= 9:
		return 1
	if roll_2d6 <= 11:
		return 2
	return 3


static func _coordinate_ballistic_rolls(rolls: Array[int], coordination_mp: int) -> Array[int]:
	var adjusted := rolls.duplicate()
	if adjusted.size() < 2:
		return adjusted
	for _point in range(clampi(coordination_mp, 0, 2)):
		var best_rolls := adjusted.duplicate()
		var best_group := _largest_roll_group(adjusted)
		var best_spread := _roll_spread(adjusted)
		for index in range(adjusted.size()):
			for delta in [-1, 1]:
				var candidate_value: int = int(adjusted[index]) + int(delta)
				if candidate_value < 1 or candidate_value > 10:
					continue
				var candidate := adjusted.duplicate()
				candidate[index] = candidate_value
				var group_size := _largest_roll_group(candidate)
				var spread := _roll_spread(candidate)
				if group_size > best_group or (group_size == best_group and spread < best_spread):
					best_group = group_size
					best_spread = spread
					best_rolls = candidate
		if best_rolls == adjusted:
			break
		adjusted = best_rolls
	return adjusted


static func _largest_roll_group(rolls: Array[int]) -> int:
	var counts := {}
	var largest := 0
	for value in rolls:
		counts[value] = int(counts.get(value, 0)) + 1
		largest = maxi(largest, int(counts[value]))
	return largest


static func _roll_spread(rolls: Array[int]) -> int:
	if rolls.is_empty():
		return 0
	var minimum := int(rolls[0])
	var maximum := minimum
	for value in rolls:
		minimum = mini(minimum, int(value))
		maximum = maxi(maximum, int(value))
	return maximum - minimum


static func _resolve_ballistic_defenses(snapshot: Dictionary, incoming: int, target_type: String) -> Dictionary:
	var survivors := maxi(0, incoming)
	var summaries: Array[String] = []
	var aegis_targets := 0
	if bool(snapshot.get("BlueBunkerHill", false)):
		aegis_targets += 4
	if bool(snapshot.get("BlueBurkeDestroyer", false)):
		aegis_targets += 3
	if aegis_targets > 0 and survivors > 0:
		var aegis := _engage_ballistic_layer(snapshot, survivors, "SM-3", aegis_targets, 64, 7, 9, "sm3_missiles")
		survivors = int(aegis.get("survivors", survivors))
		summaries.append(str(aegis.get("summary", "")))

	if survivors > 0:
		var arrow_batteries := 2 if _has_selected_upgrade(snapshot, "Blue", "Third Arrow") else 1
		var arrow := _engage_ballistic_layer(snapshot, survivors, "Arrow-2", 6 * arrow_batteries, 36 * arrow_batteries, 7, 9, "arrow_missiles")
		survivors = int(arrow.get("survivors", survivors))
		summaries.append(str(arrow.get("summary", "")))

	if survivors > 0:
		var patriot := _engage_ballistic_layer(snapshot, survivors, "PAC-3 (%s)" % target_type, 2, 32, 6, 8, "pac3_missiles")
		survivors = int(patriot.get("survivors", survivors))
		summaries.append(str(patriot.get("summary", "")))
	return {"survivors": survivors, "summary": "; ".join(summaries)}


static func _engage_ballistic_layer(snapshot: Dictionary, incoming: int, system_name: String, max_targets: int, ammo_limit: int, single_hit: int, salvo_hit: int, usage_key: String) -> Dictionary:
	var current_turn := _map_turn_number(snapshot)
	var usage_value = snapshot.get("BallisticDefenseUsage", {})
	var usage: Dictionary = usage_value.duplicate(true) if usage_value is Dictionary else {}
	if int(usage.get("map_turn", -1)) != current_turn:
		usage = {"map_turn": current_turn, "sm3_missiles": 0, "arrow_missiles": 0, "pac3_missiles": 0}
	var available := maxi(0, ammo_limit - int(usage.get(usage_key, 0)))
	var engagements := mini(maxi(0, incoming), maxi(0, max_targets))
	var destroyed := 0
	var fired := 0
	var rolls: Array[String] = []
	for _target_index in range(engagements):
		if available <= 0:
			break
		var salvo_size := mini(2, available)
		available -= salvo_size
		fired += salvo_size
		var threshold := salvo_hit if salvo_size == 2 else single_hit
		var accuracy_bonus := int(ceil(float(maxi(0, int(snapshot.get("BlueHitChance", 0)))) / 10.0))
		threshold = clampi(threshold + accuracy_bonus, 0, 10)
		var roll := randi_range(1, 10)
		var hit := roll <= threshold
		rolls.append("%d/%d%s" % [roll, threshold, " hit" if hit else " miss"])
		if hit:
			destroyed += 1
	usage[usage_key] = int(usage.get(usage_key, 0)) + fired
	snapshot["BallisticDefenseUsage"] = usage
	return {
		"survivors": maxi(0, incoming - destroyed),
		"destroyed": destroyed,
		"fired": fired,
		"summary": "%s fired %d, destroyed %d/%d [%s]" % [system_name, fired, destroyed, incoming, ", ".join(rolls)]
	}


static func _ballistic_target_type(target: String) -> String:
	var normalized := target.strip_edges().to_lower()
	if normalized.contains("urban") or normalized.contains("civil"):
		return "Urban"
	if normalized.contains("shelter") or normalized.contains("dimona"):
		return "Missile Shelter"
	if normalized.contains("military"):
		return "Military Base"
	return "Airbase"


static func _resolve_ballistic_damage(snapshot: Dictionary, target_type: String, missile_type: String) -> String:
	var raw_roll := randi_range(1, 100)
	var roll := mini(100, raw_roll + (20 if missile_type == "Sejil-2" else 0))
	var damage_value = snapshot.get("IsraeliTargetDamage", {})
	var damage: Dictionary = damage_value.duplicate(true) if damage_value is Dictionary else {}
	var result := ""
	var pp_gain := 0
	var opinion_dice := 0
	match target_type:
		"Urban":
			if roll == 1:
				var overt_value = snapshot.get("LastOvertMapTurn", {})
				var overt: Dictionary = overt_value.duplicate(true) if overt_value is Dictionary else {}
				overt["Red"] = _map_turn_number(snapshot)
				snapshot["LastOvertMapTurn"] = overt
				var event := {"day": int(snapshot.get("TurnDay", 0)), "roller": "Red", "trigger_roll": 0, "event_roll": 5}
				var event_result := _begin_strategic_event(snapshot, event)
				result = "Humanitarian damage. %s" % str(event_result.get("message", "Bad Targeting resolved."))
				_record_strategic_history(snapshot, event, result)
			elif roll <= 60:
				result = "clean miss"
			elif roll <= 76:
				result = "urban hit, no casualties"
				damage[target_type] = int(damage.get(target_type, 0)) + 1
			elif roll <= 95:
				result = "light casualties"
				pp_gain = 1
				opinion_dice = 1
				damage[target_type] = int(damage.get(target_type, 0)) + 1
			elif roll <= 98:
				result = "major damage, moderate casualties"
				pp_gain = 3
				opinion_dice = 2
				damage[target_type] = int(damage.get(target_type, 0)) + 2
			else:
				result = "critical damage, severe casualties"
				pp_gain = 5
				opinion_dice = 3
				damage[target_type] = int(damage.get(target_type, 0)) + 3
		"Airbase":
			if roll <= 80:
				result = "clean miss"
			elif roll <= 95:
				result = "airbase structures damaged"
				damage[target_type] = int(damage.get(target_type, 0)) + 1
			elif roll <= 98:
				result = "airbase structures damaged; light casualties"
				pp_gain = 2
				damage[target_type] = int(damage.get(target_type, 0)) + 1
			elif roll == 99:
				result = "heavy airbase personnel casualties"
				pp_gain = 4
				damage[target_type] = int(damage.get(target_type, 0)) + 1
			else:
				result = "one Israeli aircraft destroyed at its airbase"
				pp_gain = 4
				damage[target_type] = int(damage.get(target_type, 0)) + 1
				_damage_random_blue_aircraft(snapshot, "Ballistic missile airbase hit")
		"Military Base":
			if roll <= 80:
				result = "clean miss"
			elif roll <= 90:
				result = "military structures damaged"
				damage[target_type] = int(damage.get(target_type, 0)) + 1
			elif roll <= 94:
				result = "military structures damaged; light casualties"
				pp_gain = 2
				damage[target_type] = int(damage.get(target_type, 0)) + 1
			else:
				result = "heavy military personnel casualties"
				pp_gain = 4
				damage[target_type] = int(damage.get(target_type, 0)) + 2
		"Missile Shelter":
			if roll <= 90:
				result = "clean miss"
			elif roll <= 99:
				result = "missile shelter facility lightly damaged"
				damage[target_type] = int(damage.get(target_type, 0)) + 1
			else:
				result = "missile shelter hit"
				pp_gain = 4
				opinion_dice = 2
				damage[target_type] = int(damage.get(target_type, 0)) + 2
				var shelter_roll := randi_range(1, 10)
				if shelter_roll >= 9:
					snapshot["IsraeliStrategicMissilesDestroyed"] = int(snapshot.get("IsraeliStrategicMissilesDestroyed", 0)) + 1
					pp_gain += 10
					result += "; one Israeli strategic missile destroyed (D10=%d)" % shelter_roll
				else:
					result += "; no strategic missile destroyed (D10=%d)" % shelter_roll
	snapshot["IsraeliTargetDamage"] = damage
	if pp_gain > 0:
		snapshot["IranPP"] = int(snapshot.get("IranPP", 0)) + pp_gain
		result += "; Red +%d PP" % pp_gain
	if opinion_dice > 0:
		var backfire_roll := randi_range(1, 10)
		var resolver := "Red" if backfire_roll < 6 else "Blue"
		var opinion_result := _roll_opinion_attempts(snapshot, resolver, "IL", opinion_dice, "ballistic damage")
		result += "; backfire D10=%d, %s" % [backfire_roll, opinion_result]
	_add_dice_log(snapshot, "%s %s D100=%d%s: %s" % [missile_type, target_type, raw_roll, " +20=%d" % roll if missile_type == "Sejil-2" else "", result])
	return "%s D100=%d: %s." % [missile_type, roll, result]


static func _damage_random_blue_aircraft(snapshot: Dictionary, reason: String) -> String:
	var aircraft := _aircraft_list(snapshot, "Blue")
	var candidates: Array[int] = []
	for index in range(aircraft.size()):
		if int((aircraft[index] as Dictionary).get("operational", 0)) > 0:
			candidates.append(index)
	if candidates.is_empty():
		return "No operational Israeli aircraft was available."
	var chosen_index := candidates[randi_range(0, candidates.size() - 1)]
	var row := (aircraft[chosen_index] as Dictionary).duplicate(true)
	row["operational"] = maxi(0, int(row.get("operational", 0)) - 1)
	row["downed"] = int(row.get("downed", 0)) + 1
	aircraft[chosen_index] = row
	snapshot["BlueAircraft"] = aircraft
	snapshot["BlueAircraftLosses"] = int(snapshot.get("BlueAircraftLosses", 0)) + 1
	var message := "%s: %s lost one %s." % [reason, str(row.get("name", "Israeli squadron")), str(row.get("model", "aircraft"))]
	_add_aircraft_event(snapshot, message)
	_add_log(snapshot, message)
	return message


static func _resolve_route_overflight(snapshot: Dictionary, route: String) -> Dictionary:
	if not ROUTE_COUNTRY.has(route):
		return {"ok": false, "message": "Unknown ingress route."}
	var country_code := str(ROUTE_COUNTRY.get(route, ""))
	var track := _clean_track(snapshot.get("PoliticalTrack", {}))
	var position := int(track.get(country_code, 0))
	if position >= 5:
		return {"ok": true, "message": "%s authorized the %s route as a Blue Supporter." % [country_code, route]}
	if position <= 0:
		return {"ok": false, "message": "%s denied the %s route because it is not cordial with Blue." % [country_code, route]}
	var used_value = snapshot.get("OverflightUsed", {})
	var used: Dictionary = used_value.duplicate(true) if used_value is Dictionary else {}
	if bool(used.get(country_code, false)):
		return {"ok": false, "message": "%s denied a second cordial overflight on the %s route." % [country_code, route]}
	used[country_code] = true
	snapshot["OverflightUsed"] = used
	var opinion := _roll_opinion_attempts(snapshot, "Red", country_code, 4, "cordial overflight")
	return {"ok": true, "message": "%s granted its one cordial overflight. %s" % [country_code, opinion]}


static func _red_aew_active(snapshot: Dictionary) -> bool:
	return _selected_upgrade_count(snapshot, "Red", "KJ-2000") > 0 or _selected_upgrade_count(snapshot, "Red", "A-50") > 0 or _selected_upgrade_count(snapshot, "Red", "Mainstay") > 0


static func _resolve_suter_attack(snapshot: Dictionary, action: Dictionary) -> Dictionary:
	var shavit := clampi(int(action.get("shavit_aircraft", 0)), 0, 1)
	var eitan := clampi(int(action.get("eitan_aircraft", 0)), 0, 2)
	if shavit <= 0:
		return {"used": false, "code": "A", "gci_modifier": 0, "sam_batteries_down": 0, "no_inbound_intercepts": false, "short_sam_half": false, "summary": "No Suter attack."}
	var attack_number := int(snapshot.get("SuterAttackCount", 0)) + 1
	var modifier := 1 if attack_number == 1 else (-1 if attack_number >= 3 else 0)
	if _red_aew_active(snapshot):
		modifier -= 1
	if _has_selected_upgrade(snapshot, "Red", "Air Defense Network"):
		modifier -= 2
	var raw_roll := randi_range(1, 6) + randi_range(1, 6)
	var modified_roll := clampi(raw_roll + modifier, 2, 12)
	var code := str((SUTER_TABLE[modified_roll - 2] as Array)[eitan])
	var result := {
		"used": true,
		"code": code,
		"raw_roll": raw_roll,
		"modifier": modifier,
		"total": modified_roll,
		"gci_modifier": 0,
		"sam_batteries_down": 0,
		"no_inbound_intercepts": false,
		"short_sam_half": false
	}
	match code:
		"B":
			result["gci_modifier"] = -2
			result["sam_batteries_down"] = 1
		"C":
			result["gci_modifier"] = -3
			result["sam_batteries_down"] = 2
		"D":
			result["gci_modifier"] = -4
			result["sam_batteries_down"] = 3
			result["short_sam_half"] = true
		"E", "F":
			result["no_inbound_intercepts"] = true
			result["sam_batteries_down"] = 99
			result["short_sam_half"] = true
	snapshot["SuterAttackCount"] = attack_number
	result["summary"] = "Suter #%d rolled %d %+d = %d: result %s." % [attack_number, raw_roll, modifier, modified_roll, code]
	_add_dice_log(snapshot, str(result["summary"]))
	return result


static func _fighter_suppression_modifier(snapshot: Dictionary, action: Dictionary) -> Dictionary:
	var aircraft_count := clampi(int(action.get("escort_aircraft", 0)), 0, 12)
	if aircraft_count < 2:
		return {"modifier": 0, "summary": "No fighter-suppression element."}
	var die_modifier := 0
	if _has_selected_upgrade(snapshot, "Blue", "Minature Air Launched Decoy"):
		die_modifier += 2
	if _red_aew_active(snapshot):
		die_modifier -= 2
	var route := str(action.get("route", "Central"))
	var track := _clean_track(snapshot.get("PoliticalTrack", {}))
	if (route == "Northern" or route == "Central") and int(track.get("TR", 0)) >= 9:
		die_modifier += 2
	if route == "Central" and int(track.get("US", 0)) >= 9:
		die_modifier += 2
	if (route == "Central" or route == "Southern") and int(track.get("SA", 0)) >= 9:
		die_modifier += 1
	var raw_roll := randi_range(1, 6) + randi_range(1, 6)
	var modified_roll := clampi(raw_roll + die_modifier, 2, 12)
	var column := clampi(ceili(float(aircraft_count) / 2.0) - 1, 0, 5)
	var result_modifier := int((FIGHTER_SUPPRESSION_TABLE[modified_roll - 2] as Array)[column])
	var summary := "Fighter suppression (%d aircraft) rolled %d %+d = %d: %d GCI." % [aircraft_count, raw_roll, die_modifier, modified_roll, result_modifier]
	_add_dice_log(snapshot, summary)
	return {"modifier": result_modifier, "raw_roll": raw_roll, "die_modifier": die_modifier, "total": modified_roll, "summary": summary}


static func _gci_interceptor_count(modified_roll: int) -> int:
	if modified_roll <= 2:
		return 0
	if modified_roll <= 4:
		return 2
	if modified_roll <= 6:
		return 4
	if modified_roll <= 8:
		return 4
	if modified_roll <= 10:
		return 6
	if modified_roll <= 12:
		return 8
	if modified_roll <= 14:
		return 6
	if modified_roll <= 16:
		return 8
	if modified_roll <= 18:
		return 8
	if modified_roll == 19:
		return 10
	return 12


static func _resolve_gci_intercept(snapshot: Dictionary, action: Dictionary, suppression_modifier: int, suter: Dictionary, outbound: bool) -> Dictionary:
	if not outbound and bool(suter.get("no_inbound_intercepts", false)):
		return {"interceptors": 0, "total": 0, "summary": "Suter result %s prevented inbound GCI interception." % str(suter.get("code", "E"))}
	var aircraft := _aircraft_list(snapshot, "Red")
	var alert_count := 0
	var patrol_count := 0
	var f14_patrol_count := 0
	for row_value in aircraft:
		var row := row_value as Dictionary
		var mission := str(row.get("mission", "Ready"))
		if mission == "Alert" and not outbound:
			alert_count += 1
		elif mission == "Patrol":
			patrol_count += 1
			if str(row.get("model", "")) == "F14AGR":
				f14_patrol_count += 1
	var modifier := int(snapshot.get("RedGCI", 0)) + alert_count + patrol_count * 2 + f14_patrol_count
	if _red_aew_active(snapshot):
		modifier += 1
	modifier += suppression_modifier + int(suter.get("gci_modifier", 0))
	if not outbound and str(action.get("route", "Central")) == "Northern":
		modifier -= 3
	modifier -= int(action.get("air_defense_mp", 0)) / 2
	if outbound:
		modifier += 3
		if bool(suter.get("no_inbound_intercepts", false)) and patrol_count <= 0:
			return {"interceptors": 0, "total": 0, "summary": "Suter disruption left no patrol squadron for an outbound intercept."}
	var raw_roll := randi_range(1, 6) + randi_range(1, 6)
	var total := clampi(raw_roll + modifier, 2, 20)
	var interceptors := _gci_interceptor_count(total)
	var phase := "outbound" if outbound else "inbound"
	var summary := "GCI %s: 2D6 %d %+d = %d, %d interceptor aircraft." % [phase, raw_roll, modifier, total, interceptors]
	_add_dice_log(snapshot, summary)
	return {"interceptors": interceptors, "raw_roll": raw_roll, "modifier": modifier, "total": total, "summary": summary}


static func _resolve_sam_suppression(snapshot: Dictionary, action: Dictionary, suter: Dictionary) -> Dictionary:
	var sead_aircraft := int(action.get("sead_aircraft", 0))
	var down := int(suter.get("sam_batteries_down", 0))
	var summary_parts: Array[String] = []
	if down > 0:
		summary_parts.append("Suter disabled %s long/medium SAM batteries" % ("all" if down >= 99 else str(down)))
	if sead_aircraft >= 2:
		var chance := 95 if sead_aircraft >= 4 else 70
		if _selected_upgrade_count(snapshot, "Red", "S-300") > 0 or _selected_upgrade_count(snapshot, "Red", "HQ-9") > 0:
			chance -= 25
		var roll := randi_range(1, 100)
		if roll <= chance:
			down += 1
			summary_parts.append("SEAD %d/%d succeeded" % [roll, chance])
		else:
			summary_parts.append("SEAD %d/%d failed" % [roll, chance])
	if summary_parts.is_empty():
		summary_parts.append("No SAM suppression")
	return {"batteries_down": down, "summary": "; ".join(summary_parts)}


static func _record_lost_aircraft(snapshot: Dictionary, row: Dictionary, phase: String) -> String:
	var roll := randi_range(1, 100)
	var outcome := ""
	if roll <= 25:
		row["operational"] = maxi(0, int(row.get("operational", 0)) - 1)
		row["downed"] = int(row.get("downed", 0)) + 1
		row["kia"] = int(row.get("kia", 0)) + 1
		snapshot["IranPP"] = int(snapshot.get("IranPP", 0)) + 1
		outcome = "KIA; Iran +1 PP"
	elif roll <= 50:
		row["operational"] = maxi(0, int(row.get("operational", 0)) - 1)
		row["downed"] = int(row.get("downed", 0)) + 1
		row["missing"] = int(row.get("missing", 0)) + 1
		snapshot["BluePOW"] = int(snapshot.get("BluePOW", 0)) + 1
		snapshot["IranPP"] = int(snapshot.get("IranPP", 0)) + 2
		outcome = "aircrew captured; Iran +2 PP"
	elif roll <= 66:
		row["operational"] = maxi(0, int(row.get("operational", 0)) - 1)
		row["downed"] = int(row.get("downed", 0)) + 1
		outcome = "crashed in a third country; aircrew safe"
	elif roll <= 83:
		row["operational"] = maxi(0, int(row.get("operational", 0)) - 1)
		row["downed"] = int(row.get("downed", 0)) + 1
		outcome = "emergency landing in a third country"
	else:
		row["operational"] = maxi(0, int(row.get("operational", 0)) - 1)
		row["damaged"] = int(row.get("damaged", 0)) + 1
		outcome = "damaged aircraft returned to base"
	snapshot["BlueAircraftLosses"] = int(snapshot.get("BlueAircraftLosses", 0)) + 1
	return "%s %s D100=%d: %s" % [str(row.get("name", "Israeli squadron")), phase, roll, outcome]


static func _apply_blue_raid_losses(snapshot: Dictionary, action: Dictionary, requested_losses: int, phase: String) -> Array[String]:
	var messages: Array[String] = []
	if requested_losses <= 0:
		return messages
	var aircraft := _aircraft_list(snapshot, "Blue")
	var operation_id := str(action.get("operation_id", ""))
	var assignment_order := ["Escort", "SEAD", "Strike"]
	var remaining := requested_losses
	for desired_role in assignment_order:
		for assignment_value in action.get("assignments", []):
			if remaining <= 0:
				break
			if not assignment_value is Dictionary or str((assignment_value as Dictionary).get("role", "")) != desired_role:
				continue
			var index := int((assignment_value as Dictionary).get("index", -1))
			if index < 0 or index >= aircraft.size():
				continue
			var row := (aircraft[index] as Dictionary).duplicate(true)
			if not operation_id.is_empty() and str(row.get("operation_id", "")) != operation_id:
				continue
			var available := mini(int(row.get("committed", 0)), int(row.get("operational", 0)))
			while remaining > 0 and available > 0:
				messages.append(_record_lost_aircraft(snapshot, row, phase))
				row["committed"] = maxi(0, int(row.get("committed", 0)) - 1)
				available -= 1
				remaining -= 1
			aircraft[index] = row
	snapshot["BlueAircraft"] = aircraft
	for message in messages:
		_add_aircraft_event(snapshot, message)
	return messages


static func _interception_losses(interceptors: int, escort_aircraft: int) -> int:
	if interceptors <= 0:
		return 0
	var attacking_elements := ceili(float(interceptors) / 2.0)
	var escort_screen := escort_aircraft / 2
	var effective_attacks := maxi(0, attacking_elements - escort_screen)
	var losses := 0
	for _attack in range(effective_attacks):
		if randi_range(1, 10) >= 8:
			losses += 1
	return losses


static func _pgm_target_modifier(snapshot: Dictionary, target: Dictionary, weapon: Dictionary) -> int:
	var guidance := str(weapon.get("guidance", ""))
	var target_type := str(target.get("type", ""))
	if guidance.begins_with("GPS"):
		var jammer := false
		if target_type == "Nuclear":
			jammer = _has_selected_upgrade(snapshot, "Red", "GPS Jammer Nuclear") or _has_selected_upgrade(snapshot, "Red", "GPS Jammer Oil & Nuclear")
		elif target_type == "Oil":
			jammer = _has_selected_upgrade(snapshot, "Red", "GPS Jammer Oil & Nuclear")
		if jammer:
			return -3 if int(weapon.get("generation", 1)) <= 1 else -1
	if guidance == "Laser":
		if target_type == "Nuclear" and _has_selected_upgrade(snapshot, "Red", "Nuclear Decoy"):
			return -4
		if target_type == "Oil" and _has_selected_upgrade(snapshot, "Red", "Oil Decoy"):
			return -4
		if target_type == "Military" and _has_selected_upgrade(snapshot, "Red", "Military Decoy"):
			return -4
	return 0


static func _apply_component_weapon_damage(snapshot: Dictionary, target_id: String, component: Dictionary, weapon_damage: int, armor_pen: int) -> Dictionary:
	var component_key := str(component.get("key", ""))
	var targets_state := merge_targets_with_defaults(snapshot.get("Targets", {}))
	var target_state_value = targets_state.get(target_id, {})
	var target_state: Dictionary = target_state_value if target_state_value is Dictionary else {}
	var boxes := maxi(1, int(component.get("boxes", 1)))
	var current := clampi(int(target_state.get(component_key, 0)), 0, boxes)
	if current >= boxes:
		return {"applied": 0, "fraction": 0.0, "message": "%s already destroyed" % str(component.get("name", component_key))}
	var fraction_value = snapshot.get("TargetFractionalDamage", {})
	var fractions: Dictionary = fraction_value.duplicate(true) if fraction_value is Dictionary else {}
	var fraction_key := "%s:%s" % [target_id, component_key]
	var existing_fraction := float(fractions.get(fraction_key, 0.0))
	var penetrated := armor_pen >= int(component.get("armor", 0))
	var damage := float(weapon_damage) if penetrated else float(weapon_damage) * 0.25
	var accumulated := existing_fraction + damage
	var whole_boxes := floori(accumulated)
	var remainder := accumulated - float(whole_boxes)
	var applied := mini(whole_boxes, boxes - current)
	target_state[component_key] = current + applied
	targets_state[target_id] = target_state
	snapshot["Targets"] = targets_state
	if current + applied >= boxes:
		remainder = 0.0
	fractions[fraction_key] = remainder
	snapshot["TargetFractionalDamage"] = fractions
	return {"applied": applied, "fraction": remainder, "penetrated": penetrated, "message": "%s %s%d box(es)" % [str(component.get("name", component_key)), "took " if penetrated else "armor reduced damage to ", applied]}


static func _remaining_committed_aircraft(snapshot: Dictionary, action: Dictionary, role: String) -> int:
	var aircraft := _aircraft_list(snapshot, "Blue")
	var operation_id := str(action.get("operation_id", ""))
	var remaining := 0
	for assignment_value in action.get("assignments", []):
		if not assignment_value is Dictionary:
			continue
		var assignment := assignment_value as Dictionary
		if str(assignment.get("role", "")) != role:
			continue
		var index := int(assignment.get("index", -1))
		if index < 0 or index >= aircraft.size():
			continue
		var row := aircraft[index] as Dictionary
		if not operation_id.is_empty() and str(row.get("operation_id", "")) != operation_id:
			continue
		remaining += mini(int(row.get("committed", 0)), int(row.get("operational", 0)))
	return remaining


static func _resolve_pgm_loadout(snapshot: Dictionary, action: Dictionary, target_id: String, component_key: String) -> Dictionary:
	var target := _find_target_metadata(target_id)
	var component := _find_target_component(target, component_key)
	if target.is_empty() or component.is_empty():
		return {"weapons": 0, "hits": 0, "boxes": 0, "summary": "Invalid target component."}
	var model := ""
	for assignment_value in action.get("assignments", []):
		if assignment_value is Dictionary and str((assignment_value as Dictionary).get("role", "")) == "Strike":
			model = str((assignment_value as Dictionary).get("model", ""))
			break
	var loadout_name := str(action.get("loadout", _default_strike_loadout(model)))
	var model_loadouts_value = BLUE_LOADOUTS.get(model, {})
	var model_loadouts: Dictionary = model_loadouts_value if model_loadouts_value is Dictionary else {}
	var loadout_value = model_loadouts.get(loadout_name, {})
	var loadout: Dictionary = loadout_value if loadout_value is Dictionary else {}
	if loadout.is_empty():
		return {"weapons": 0, "hits": 0, "boxes": 0, "summary": "Unknown %s loadout for %s." % [loadout_name, model]}
	var strike_aircraft := _remaining_committed_aircraft(snapshot, action, "Strike")
	if action.get("assignments", []).is_empty():
		strike_aircraft = maxi(0, int(action.get("strike_aircraft", action.get("missiles", 1))))
	if strike_aircraft <= 0:
		return {"weapons": 0, "hits": 0, "boxes": 0, "summary": "No strike aircraft survived to release weapons."}
	var weapon_count := 0
	var weapon_hits := 0
	var boxes_applied := 0
	var roll_parts: Array[String] = []
	var size_class := str(component.get("size_class", "G"))
	var size_index := clampi("ABCDEFG".find(size_class), 0, 6)
	for weapon_group_value in loadout.get("weapons", []):
		var weapon_group := weapon_group_value as Dictionary
		var weapon_name := str(weapon_group.get("name", ""))
		var weapon_value = PGM_WEAPONS.get(weapon_name, {})
		var weapon: Dictionary = weapon_value if weapon_value is Dictionary else {}
		if weapon.is_empty():
			continue
		var quantity := maxi(0, int(weapon_group.get("quantity", 0))) * strike_aircraft
		var thresholds_value = weapon.get("thresholds", [])
		var thresholds: Array = thresholds_value if thresholds_value is Array else []
		var base_threshold := int(thresholds[size_index]) if thresholds.size() > size_index else 0
		var target_modifier := _pgm_target_modifier(snapshot, target, weapon)
		var threshold := clampi(base_threshold + target_modifier, 1, 10)
		var rolls: Array[String] = []
		for _weapon_index in range(quantity):
			weapon_count += 1
			var roll := randi_range(1, 10)
			rolls.append(str(roll))
			if roll > threshold:
				continue
			weapon_hits += 1
			var damage_result := _apply_component_weapon_damage(snapshot, target_id, component, int(weapon.get("hits", 0)), int(weapon.get("armor_pen", 0)))
			boxes_applied += int(damage_result.get("applied", 0))
		roll_parts.append("%s %d/%d hit <=%d [%s]" % [weapon_name, weapon_hits, quantity, threshold, ",".join(rolls)])
	return {"weapons": weapon_count, "hits": weapon_hits, "boxes": boxes_applied, "summary": "; ".join(roll_parts)}


static func _resolve_strike_action(snapshot: Dictionary, action: Dictionary) -> String:
	var team_name := str(action.get("team", "Blue"))
	var action_type := str(action.get("action_type", "Airstrike"))
	var display := str(action.get("display", action.get("action_name", action_type)))
	var target_id := find_target_id(str(action.get("target_id", action.get("target", ""))))
	if team_name != "Blue" or action_type != "Airstrike" or target_id.is_empty():
		var legacy_hits := maxi(1, int(action.get("missiles", 1)))
		var legacy_target_message := _apply_target_damage(snapshot, target_id, legacy_hits) if not target_id.is_empty() else "No strategic target card."
		var legacy_summary := "%s %s resolved: %s. %s" % [team_name, action_type, display, legacy_target_message]
		_add_log(snapshot, legacy_summary)
		return legacy_summary

	snapshot["ConflictStarted"] = true
	snapshot["BlueAirStrikeThisTurn"] = true
	var route := str(action.get("route", "Central"))
	var overflight := _resolve_route_overflight(snapshot, route)
	if not bool(overflight.get("ok", false)):
		var denied_summary := "%s aborted: %s" % [display, str(overflight.get("message", "route denied"))]
		_add_log(snapshot, denied_summary)
		return denied_summary

	var target := _find_target_metadata(target_id)
	var component_key := str(action.get("component_key", _first_attackable_component(snapshot, target)))
	var before_level := _target_victory_level(snapshot, target_id)
	var suter := _resolve_suter_attack(snapshot, action)
	var fighter_suppression := _fighter_suppression_modifier(snapshot, action)
	var inbound := _resolve_gci_intercept(snapshot, action, int(fighter_suppression.get("modifier", 0)), suter, false)
	var inbound_losses := _interception_losses(int(inbound.get("interceptors", 0)), int(action.get("escort_aircraft", 0)))
	var loss_messages := _apply_blue_raid_losses(snapshot, action, inbound_losses, "inbound")
	var sam_suppression := _resolve_sam_suppression(snapshot, action, suter)
	var active_sam := maxi(0, int(snapshot.get("RedSAM", 0)) - int(sam_suppression.get("batteries_down", 0)))
	var sam_losses := 0
	if active_sam > 0:
		var sam_chance := clampi(active_sam * 8, 5, 65)
		if bool(suter.get("short_sam_half", false)):
			sam_chance = sam_chance / 2
		if randi_range(1, 100) <= sam_chance:
			sam_losses = 1
	loss_messages.append_array(_apply_blue_raid_losses(snapshot, action, sam_losses, "SAM engagement"))

	var pgm_result := _resolve_pgm_loadout(snapshot, action, target_id, component_key)
	var after_level := _target_victory_level(snapshot, target_id)
	var victory_summary := _process_target_victory_change(snapshot, target_id, before_level, after_level)
	var outbound := _resolve_gci_intercept(snapshot, action, int(fighter_suppression.get("modifier", 0)), suter, true)
	var outbound_losses := _interception_losses(int(outbound.get("interceptors", 0)), maxi(0, int(action.get("escort_aircraft", 0)) - inbound_losses))
	loss_messages.append_array(_apply_blue_raid_losses(snapshot, action, outbound_losses, "outbound"))

	var last_turn_value = snapshot.get("TargetLastStrikeTurn", {})
	var last_turns: Dictionary = last_turn_value.duplicate(true) if last_turn_value is Dictionary else {}
	last_turns[target_id] = _map_turn_number(snapshot)
	snapshot["TargetLastStrikeTurn"] = last_turns
	var history := _clean_dictionary_array(snapshot.get("AirstrikeHistory", []))
	var history_entry := {
		"operation": display,
		"target_id": target_id,
		"component_key": component_key,
		"route": route,
		"loadout": str(action.get("loadout", "")),
		"weapons": int(pgm_result.get("weapons", 0)),
		"weapon_hits": int(pgm_result.get("hits", 0)),
		"boxes_applied": int(pgm_result.get("boxes", 0)),
		"losses": loss_messages.size(),
		"victory_level": after_level,
		"map_turn": _map_turn_number(snapshot)
	}
	history.append(history_entry)
	while history.size() > 80:
		history.pop_front()
	snapshot["AirstrikeHistory"] = history
	var combat_history := _clean_dictionary_array(snapshot.get("AirCombatHistory", []))
	combat_history.append({"operation": display, "inbound": inbound, "outbound": outbound, "suter": suter, "fighter_suppression": fighter_suppression, "sam_suppression": sam_suppression, "losses": loss_messages})
	while combat_history.size() > 80:
		combat_history.pop_front()
	snapshot["AirCombatHistory"] = combat_history

	var summary := "%s resolved via %s: %s | %s | %s | PGM: %s | target result %s%s%s" % [
		display,
		route,
		str(overflight.get("message", "")),
		str(inbound.get("summary", "")),
		str(sam_suppression.get("summary", "")),
		str(pgm_result.get("summary", "")),
		after_level,
		(" | " + victory_summary) if not victory_summary.is_empty() else "",
		(" | losses: " + "; ".join(loss_messages)) if not loss_messages.is_empty() else ""
	]
	_add_log(snapshot, summary)
	_add_dice_log(snapshot, summary)
	return summary


static func _resolve_special_warfare_action(snapshot: Dictionary, action: Dictionary) -> String:
	var team_name := str(action.get("team", ""))
	var action_type := str(action.get("action_type", "Special Warfare"))
	var mission_type := str(action.get("mission_type", "Civil Economic"))
	var chance := clampi(int(action.get("success_chance", 0)), 0, 95)
	var roll := randi_range(1, 100)
	var critical_failure := roll >= 96 or (roll > chance and roll >= chance + 30)
	var success := roll <= chance
	var display := str(action.get("display", action_type))
	var summary := "%s %s (%s) rolled %d against %d%%: " % [team_name, display, mission_type, roll, chance]
	if critical_failure:
		var opponent := _opposing_team(team_name)
		var opponent_prefix := _point_prefix(opponent)
		snapshot["%sIP" % opponent_prefix] = int(snapshot.get("%sIP" % opponent_prefix, 0)) + 2
		snapshot["%sPP" % opponent_prefix] = int(snapshot.get("%sPP" % opponent_prefix, 0)) + 2
		if team_name == "Blue":
			snapshot["BluePOW"] = int(snapshot.get("BluePOW", 0)) + 1
		summary += "CRITICAL FAILURE. %s gained 2 IP and 2 PP%s." % [opponent, "; Iran captured one Israeli POW" if team_name == "Blue" else ""]
	elif not success:
		if team_name == "Blue" and mission_type.to_lower().contains("weaken"):
			snapshot["RedGCI"] = int(snapshot.get("RedGCI", 0)) + 2
			snapshot["RedGCIMapTurn"] = int(snapshot.get("RedGCIMapTurn", 0)) + 2
			summary += "failure; Iran gains +2 GCI for this map turn."
		else:
			summary += "failure."
	else:
		if team_name == "Blue":
			snapshot["ConflictStarted"] = true
		var mission_key := mission_type.to_lower()
		if mission_key.contains("civil"):
			var domestic_id := 9 if team_name == "Blue" else 1
			var resolver := team_name
			var backfire_roll := randi_range(1, 10)
			if backfire_roll >= 9:
				resolver = _opposing_team(team_name)
			_queue_opinion_resolution(snapshot, team_name, resolver, 0, [[domestic_id]], 3)
			summary += "success; %s receives 3 domestic opinion dice (backfire check %d)." % [resolver, backfire_roll]
		elif mission_key.contains("weaken"):
			if team_name == "Blue":
				snapshot["RedSAM"] = maxi(0, int(snapshot.get("RedSAM", 0)) - 1)
			else:
				snapshot["BlueHitChance"] = maxi(0, int(snapshot.get("BlueHitChance", 0)) - 10)
			summary += "success; the opposing air-defense rating was reduced."
		elif mission_key.contains("spot"):
			if team_name == "Blue":
				snapshot["BlueHitChance"] = clampi(int(snapshot.get("BlueHitChance", 0)) + 10, 0, 100)
			else:
				snapshot["RedGCI"] = int(snapshot.get("RedGCI", 0)) + 2
				snapshot["RedGCIMapTurn"] = int(snapshot.get("RedGCIMapTurn", 0)) + 2
			summary += "success; the next related attack gains its spotting modifier."
		else:
			var target_id := find_target_id(str(action.get("target", "")))
			var damage_message := _apply_target_damage(snapshot, target_id, 1)
			summary += "success%s" % [("; " + damage_message) if not damage_message.is_empty() else "."]
	_add_log(snapshot, summary)
	_add_dice_log(snapshot, summary)
	return summary


static func _resolve_reposition_action(snapshot: Dictionary, action: Dictionary) -> String:
	var destination := str(action.get("target", "")).strip_edges()
	if destination.is_empty():
		destination = "the selected sector"
	var summary := "Red repositioned air-defense units to %s; the move consumed one map turn." % destination
	_add_log(snapshot, summary)
	return summary


static func _resolve_close_strait_action(snapshot: Dictionary, action: Dictionary) -> String:
	var mp_spent := clampi(int(action.get("mp_cost", 1)), 1, 7)
	var pp_spent := clampi(int(action.get("pp_cost", 0)), 0, 2)
	var closure_modifier := 2 if _has_selected_upgrade(snapshot, "Red", "EM-55") else 0
	var closure_roll := randi_range(1, 10)
	var modified_closure_roll := clampi(closure_roll + closure_modifier, 1, 10)
	var closure := _strait_closure_result(mp_spent, modified_closure_roll)
	snapshot["StraitStatus"] = closure
	snapshot["StraitCooldown"] = 3
	snapshot["PendingCard"] = {
		"type": "strait_response",
		"title": "Strait Blockade Interference",
		"card_id": 0,
		"owner_team": "Red",
		"resolving_team": "Blue",
		"closure": closure,
		"red_pp_spent": pp_spent
	}
	var modifier_text := " + 2 EM-55" if closure_modifier > 0 else ""
	var summary := "Strait attempt: %d MP rolled %d%s = %s. Blue may now spend up to 2 PP to interfere." % [mp_spent, closure_roll, modifier_text, closure]
	_add_log(snapshot, summary)
	_add_dice_log(snapshot, summary)
	return summary


static func _strait_closure_result(mp_spent: int, roll: int) -> String:
	match clampi(mp_spent, 1, 7):
		1:
			return "No Effect" if roll <= 6 else "Nuisance"
		2:
			if roll <= 4: return "No Effect"
			if roll <= 9: return "Nuisance"
			return "Partial Closure"
		3:
			if roll <= 3: return "No Effect"
			if roll <= 7: return "Nuisance"
			if roll <= 9: return "Partial Closure"
			return "Complete Closure"
		4:
			if roll == 1: return "No Effect"
			if roll <= 5: return "Nuisance"
			if roll <= 8: return "Partial Closure"
			return "Complete Closure"
		5:
			if roll <= 3: return "Nuisance"
			if roll <= 8: return "Partial Closure"
			return "Complete Closure"
		6:
			if roll <= 2: return "Nuisance"
			if roll <= 7: return "Partial Closure"
			return "Complete Closure"
		7:
			return "Partial Closure" if roll <= 6 else "Complete Closure"
	return "No Effect"


static func _strait_effect_result(closure: String, roll: int) -> Dictionary:
	var clean_roll := clampi(roll, 1, 10)
	match closure:
		"Partial Closure":
			if clean_roll <= 2:
				return {"team": "Blue", "dice": 5}
			if clean_roll <= 5:
				return {"team": "Blue", "dice": 3}
			if clean_roll <= 8:
				return {"team": "Red", "dice": 3}
			return {"team": "Red", "dice": 5}
		"Complete Closure":
			if clean_roll <= 2:
				return {"team": "Blue", "dice": 6}
			if clean_roll <= 5:
				return {"team": "Blue", "dice": 5}
			if clean_roll <= 8:
				return {"team": "Red", "dice": 5}
			return {"team": "Red", "dice": 6}
		_:
			if clean_roll <= 2:
				return {"team": "Blue", "dice": 3}
			if clean_roll <= 5:
				return {"team": "Blue", "dice": 1}
			if clean_roll <= 8:
				return {"team": "Red", "dice": 1}
			return {"team": "Red", "dice": 3}


static func _queue_opinion_resolution(snapshot: Dictionary, owner_team: String, resolving_team: String, card_id: int, groups: Array, dice_per_group: int) -> void:
	var existing = snapshot.get("PendingCard", {})
	if existing is Dictionary and not (existing as Dictionary).is_empty():
		_add_log(snapshot, "Opinion dice are waiting, but another card resolution is already active.")
		return
	snapshot["PendingCard"] = {
		"type": "opinion",
		"card_id": card_id,
		"owner_team": owner_team,
		"resolving_team": resolving_team,
		"group_options": groups.duplicate(true),
		"groups_remaining": groups.size(),
		"dice_per_group": maxi(1, dice_per_group),
		"used_country_ids": []
	}


static func _resolve_due_planned_actions(snapshot: Dictionary) -> void:
	var guard := 0
	while guard < 50:
		guard += 1
		var planned := _clean_dictionary_array(snapshot.get("PlannedActions", []))
		var due_index := -1
		for index in range(planned.size()):
			if int((planned[index] as Dictionary).get("wait_time", 0)) <= 0:
				due_index = index
				break
		if due_index < 0:
			return
		_resolve_planned_action_at(snapshot, due_index)
		var pending_value = snapshot.get("PendingCard", {})
		if pending_value is Dictionary and not (pending_value as Dictionary).is_empty():
			return


static func _auto_end_game(snapshot: Dictionary) -> void:
	var evaluation := evaluate_victory(snapshot)
	snapshot["GameOver"] = true
	snapshot["GameOverSummary"] = evaluation
	var campaign_days := maxi(1, int(snapshot.get("CampaignDays", MAX_DAY)))
	var message := "Campaign ended after Day %d Night. %s wins - %s" % [campaign_days, str(evaluation.get("winner", "Draw")), str(evaluation.get("reason", ""))]
	_add_log(snapshot, message)


static func card_metadata(card_id: int) -> Dictionary:
	var metadata := all_card_metadata()
	return (metadata.get(str(card_id), {}) as Dictionary).duplicate(true)


static func all_card_metadata() -> Dictionary:
	if not _card_metadata_cache.is_empty():
		return _card_metadata_cache
	if not FileAccess.file_exists(CARD_METADATA_PATH):
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(CARD_METADATA_PATH))
	if parsed is Dictionary:
		_card_metadata_cache = parsed
	return _card_metadata_cache


static func political_stats() -> Dictionary:
	if not _political_stats_cache.is_empty():
		return _political_stats_cache
	if not FileAccess.file_exists(POLITICAL_STATS_PATH):
		return {}
	for line in FileAccess.get_file_as_string(POLITICAL_STATS_PATH).split("\n", false):
		var parts := line.strip_edges().split(",", false)
		if parts.size() < 8:
			continue
		var country_code := str(parts[0]).strip_edges()
		var track_place := int(str(parts[1]).strip_edges())
		_political_stats_cache["%s:%d" % [country_code, track_place]] = {
			"blue_ip": int(str(parts[2]).strip_edges()),
			"blue_pp": int(str(parts[3]).strip_edges()),
			"blue_mp": int(str(parts[4]).strip_edges()),
			"red_ip": int(str(parts[5]).strip_edges()),
			"red_pp": int(str(parts[6]).strip_edges()),
			"red_mp": int(str(parts[7]).strip_edges())
		}
	return _political_stats_cache


static func all_upgrade_metadata() -> Array:
	if not _upgrade_metadata_cache.is_empty():
		return _upgrade_metadata_cache
	if not FileAccess.file_exists(UPGRADE_METADATA_PATH):
		return []
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(UPGRADE_METADATA_PATH))
	if parsed is Array:
		for item in parsed:
			if item is Dictionary:
				_upgrade_metadata_cache.append((item as Dictionary).duplicate(true))
	return _upgrade_metadata_cache


static func upgrades_for_team(team_name: String) -> Array:
	var upgrades: Array = []
	for item in all_upgrade_metadata():
		if item is Dictionary and str(item.get("team", "")) == team_name:
			upgrades.append((item as Dictionary).duplicate(true))
	return upgrades


static func find_upgrade(team_name: String, upgrade_name: String) -> Dictionary:
	var clean_name := upgrade_name.strip_edges()
	for item in upgrades_for_team(team_name):
		if str((item as Dictionary).get("name", "")) == clean_name:
			return (item as Dictionary).duplicate(true)
	return {}


static func all_aircraft_metadata() -> Array:
	if not _aircraft_metadata_cache.is_empty():
		return _aircraft_metadata_cache
	if not FileAccess.file_exists(AIRCRAFT_METADATA_PATH):
		return []
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(AIRCRAFT_METADATA_PATH))
	if parsed is Array:
		for item in parsed:
			if item is Dictionary:
				_aircraft_metadata_cache.append(_normalize_aircraft_row(item as Dictionary))
	return _aircraft_metadata_cache


static func default_aircraft_for_team(team_name: String) -> Array:
	var aircraft: Array = []
	for item in all_aircraft_metadata():
		if item is Dictionary and str(item.get("team", "")) == team_name:
			aircraft.append((item as Dictionary).duplicate(true))
	return aircraft


static func make_deck(start_id: int, end_id: int) -> Array:
	var deck: Array = []
	for card_id in range(start_id, end_id + 1):
		deck.append(card_id)
	deck.shuffle()
	return deck


static func cards_from_string(card_string: String) -> Array:
	var cards: Array = []
	for part in card_string.split(",", false):
		var clean_part := part.strip_edges()
		if clean_part.is_valid_int():
			cards.append(int(clean_part))
	return cards


static func cards_to_string(cards: Array) -> String:
	if cards.is_empty():
		return ""
	var parts: Array[String] = []
	for card_id in cards:
		parts.append(str(int(card_id)))
	return ",".join(parts) + ","


static func card_display_name(card_id: int) -> String:
	var metadata := card_metadata(card_id)
	var card_name := str(metadata.get("name", "")).strip_edges()
	if card_name.is_empty():
		card_name = "Card %d" % card_id
	return "%s (#%d)" % [card_name, card_id]


static func action_description(action_id: int) -> String:
	match action_id:
		0:
			return "Roll dice"
		1:
			return "Look at opposing river"
		2:
			return "Retrieve from discard"
		3:
			return "Discard 1 opposing river card"
		4:
			return "Discard 2 opposing river cards"
		5:
			return "Cancel strategic event"
		6:
			return "Convert points"
		7:
			return "Add Bunker Hill"
		8:
			return "Add Burke Class Destroyer"
		9:
			return "Counter IP card"
		10:
			return "Freeze political track"
		11:
			return "Receive upgrades"
		12:
			return "Counter PP card"
	return "Action %d" % action_id


static func requirement_description(requirement_id: int) -> String:
	match requirement_id:
		0:
			return "None"
		1:
			return "Opponent last card dirty"
		2:
			return "Opponent last card covert"
		3:
			return "Opponent last card dirty/covert"
		4:
			return "Last action overt"
		5:
			return "Damaged nuclear target"
		6:
			return "Additional cost"
		7:
			return "Any point cost"
		8:
			return "US support/alliance"
		9:
			return "PRC/Russia support"
		10:
			return "Turkey/Saudi/US support"
		11:
			return "Israeli airstrike this turn"
		12:
			return "POW"
	return "Requirement %d" % requirement_id


static func political_difficulty(track_position: int) -> int:
	var absolute_position: int = absi(track_position)
	if absolute_position >= 9:
		return 9
	if absolute_position >= 5:
		return 8
	if absolute_position >= 1:
		return 7
	return 6


static func turn_label(snapshot: Dictionary) -> String:
	return "Day %d - %s - Move %d" % [
		int(snapshot.get("TurnDay", 0)),
		turn_name(int(snapshot.get("TurnTime", 3))),
		int(snapshot.get("Move", 0))
	]


static func turn_name(turn_index: int) -> String:
	if turn_index >= 0 and turn_index < TURN_NAMES.size():
		return TURN_NAMES[turn_index]
	return "Turn %d" % turn_index


static func _neutral_track() -> Dictionary:
	var track := {}
	for country_code in COUNTRY_CODES:
		track[country_code] = 0
	return track


static func _clean_track(track_value) -> Dictionary:
	var track := _neutral_track()
	if track_value is Dictionary:
		for country_code in COUNTRY_CODES:
			track[country_code] = clampi(int(track_value.get(country_code, 0)), -10, 10)
	return track


static func _card_country_ids(metadata: Dictionary) -> Array:
	var ids: Array = []
	for list_key in ["countries", "set1Countries", "set2Countries"]:
		var raw_list = metadata.get(list_key, [])
		if raw_list is Array:
			for raw_id in raw_list:
				var country_id := int(raw_id)
				if country_id > 0 and not ids.has(country_id):
					ids.append(country_id)
	return ids


static func _pay_card_cost(snapshot: Dictionary, team_name: String, metadata: Dictionary) -> Dictionary:
	var prefix := _point_prefix(team_name)
	if prefix.is_empty():
		return {"ok": false, "message": "Unknown team."}
	var costs := {
		"IP": str(metadata.get("iPCost", "0")),
		"MP": str(metadata.get("mPCost", "0")),
		"PP": str(metadata.get("pPCost", "0"))
	}
	for point_key in costs.keys():
		var raw_cost := str(costs[point_key]).strip_edges()
		if raw_cost == "X":
			continue
		var cost := int(raw_cost) if raw_cost.is_valid_int() else 0
		if cost > 0 and int(snapshot.get("%s%s" % [prefix, point_key], 0)) < cost:
			return {"ok": false, "message": "%s does not have enough %s for %s." % [team_name, point_key, card_display_name(int(metadata.get("id", 0)))]}
	for point_key in costs.keys():
		var raw_cost := str(costs[point_key]).strip_edges()
		if raw_cost == "X":
			continue
		var cost := int(raw_cost) if raw_cost.is_valid_int() else 0
		if cost > 0:
			var key := "%s%s" % [prefix, point_key]
			snapshot[key] = max(0, int(snapshot.get(key, 0)) - cost)
	return {"ok": true, "message": "Cost paid."}


static func _point_prefix(team_name: String) -> String:
	if team_name == "Red":
		return "Iran"
	if team_name == "Blue":
		return "Isreal"
	return ""


static func _change_day(snapshot: Dictionary, next_day: bool) -> void:
	var day := int(snapshot.get("TurnDay", 0))
	var campaign_days := maxi(1, int(snapshot.get("CampaignDays", MAX_DAY)))
	if next_day and day < campaign_days:
		if day > 0:
			_run_end_map_turn_aircraft(snapshot)
		day += 1
		_tick_planned_actions(snapshot, 3)
	elif not next_day and day > 0:
		day -= 1
		_tick_planned_actions(snapshot, -3)
	snapshot["TurnDay"] = day
	snapshot["TurnTime"] = 3 if day == 0 else 0
	snapshot["Move"] = 0 if day == 0 else 1
	snapshot["ChangeTeam"] = "White" if day == 0 else "Blue"
	snapshot["PassCounter"] = 0
	_reset_timer(snapshot)
	if day > 0:
		_clear_map_turn_gci(snapshot)
		if int(snapshot.get("TurnTime", 3)) == 0:
			_run_morning_upkeep(snapshot)
	_resolve_due_planned_actions(snapshot)


static func _change_turn(snapshot: Dictionary, next_turn: bool) -> void:
	var day := int(snapshot.get("TurnDay", 0))
	var turn := int(snapshot.get("TurnTime", 3))
	var campaign_days := maxi(1, int(snapshot.get("CampaignDays", MAX_DAY)))
	var changed := false
	if next_turn:
		if day > 0:
			_run_end_map_turn_aircraft(snapshot)
			_advance_all_rivers(snapshot)
			_finish_map_turn_card_state(snapshot)
		if day == 0:
			day = 1
			turn = 0
			changed = true
		elif turn >= 2:
			if day < campaign_days:
				day += 1
				turn = 0
				changed = true
			else:
				_tick_planned_actions(snapshot, 1)
				_resolve_due_planned_actions(snapshot)
				_auto_end_game(snapshot)
				snapshot["PassCounter"] = 0
				snapshot["ChangeTeam"] = "White"
				_reset_timer(snapshot)
				return
		else:
			turn += 1
			changed = true
	else:
		if day > 1 and turn == 0:
			day -= 1
			turn = 2
			changed = true
		elif day > 0 and turn > 0:
			turn -= 1
			changed = true
	if changed:
		_tick_planned_actions(snapshot, 1 if next_turn else -1)
	snapshot["TurnDay"] = day
	snapshot["TurnTime"] = turn
	snapshot["Move"] = 0 if day == 0 else 1
	snapshot["ChangeTeam"] = "White" if day == 0 else "Blue"
	snapshot["PassCounter"] = 0
	_reset_timer(snapshot)
	if day > 0:
		_clear_map_turn_gci(snapshot)
		if turn == 0:
			_run_morning_upkeep(snapshot)
	_resolve_due_planned_actions(snapshot)


static func _advance_all_rivers(snapshot: Dictionary) -> void:
	for team_name in ["Red", "Blue"]:
		var result := draw_river(snapshot, team_name)
		if not bool(result.get("ok", false)):
			continue
		var advanced := (result.get("snapshot", snapshot) as Dictionary).duplicate(true)
		snapshot.clear()
		snapshot.merge(advanced, true)


static func _finish_map_turn_card_state(snapshot: Dictionary) -> void:
	snapshot["RiverRevealForTeam"] = ""
	snapshot["SleeperAgentReady"] = {"Red": false, "Blue": false}
	snapshot["RedLastCardDirty"] = false
	snapshot["RedLastCardCovert"] = false
	snapshot["BlueLastCardDirty"] = false
	snapshot["BlueLastCardCovert"] = false
	snapshot["RedLastActionOvert"] = false
	snapshot["BlueLastActionOvert"] = false
	snapshot["BlueAirStrikeThisTurn"] = false
	snapshot["RedAircraftChangedIndices"] = []
	snapshot["WeatherRestriction"] = {}
	snapshot["StraitCooldown"] = maxi(0, int(snapshot.get("StraitCooldown", 0)) - 1)
	var locks_value = snapshot.get("TrackLocks", {})
	var locks: Dictionary = locks_value.duplicate(true) if locks_value is Dictionary else {}
	for country_code in locks.keys():
		var lock_value = locks[country_code]
		if not lock_value is Dictionary:
			locks.erase(country_code)
			continue
		var lock_data := (lock_value as Dictionary).duplicate(true)
		lock_data["turns"] = maxi(0, int(lock_data.get("turns", 0)) - 1)
		if int(lock_data["turns"]) <= 0:
			locks.erase(country_code)
		else:
			locks[country_code] = lock_data
	snapshot["TrackLocks"] = locks


static func _set_current_team(snapshot: Dictionary, team_name: String, next_move: bool) -> void:
	if next_move:
		snapshot["Move"] = int(snapshot.get("Move", 0)) + 1
	snapshot["ChangeTeam"] = team_name
	_reset_timer(snapshot)


static func _pass(snapshot: Dictionary, pass_team: String) -> void:
	var pass_counter := int(snapshot.get("PassCounter", 0))
	if pass_counter == 0:
		snapshot["PassCounter"] = 1
		var next_team := "Red" if pass_team == "Blue" else "Blue"
		_set_current_team(snapshot, next_team, true)
		snapshot["TimerRunning"] = true
		snapshot["TimerStarted"] = true
	else:
		snapshot["PassCounter"] = 0
		_change_turn(snapshot, true)
		snapshot["TimerRunning"] = true
		snapshot["TimerStarted"] = true


static func _reset_timer(snapshot: Dictionary) -> void:
	snapshot["TimerRunning"] = false
	snapshot["TimeRemaining"] = TIMER_SECONDS


static func _clear_map_turn_gci(snapshot: Dictionary) -> void:
	snapshot["RedGCI"] = max(0, int(snapshot.get("RedGCI", 0)) - int(snapshot.get("RedGCIMapTurn", 0)))
	snapshot["RedGCIMapTurn"] = 0


static func _has_unresolved_choice(snapshot: Dictionary) -> bool:
	if bool(snapshot.get("ActionPending", false)):
		return true
	var pending_value = snapshot.get("PendingCard", {})
	return pending_value is Dictionary and not (pending_value as Dictionary).is_empty()


static func _record_night_point_gains(before: Dictionary, after: Dictionary) -> void:
	if int(before.get("TurnDay", 0)) <= 0 or int(before.get("TurnTime", 3)) != 2:
		return
	if int(after.get("TurnDay", 0)) != int(before.get("TurnDay", 0)) or int(after.get("TurnTime", 3)) != 2:
		return
	var gains := _clean_night_point_gains(after.get("NightPointGains", {}))
	for team_name in ["Red", "Blue"]:
		var prefix := _point_prefix(team_name)
		var team_gains: Dictionary = gains.get(team_name, {})
		for point_type in POINT_KEYS:
			var key := "%s%s" % [prefix, point_type]
			var increase := int(after.get(key, 0)) - int(before.get(key, 0))
			if increase > 0:
				team_gains[point_type] = int(team_gains.get(point_type, 0)) + increase
		gains[team_name] = team_gains
	after["NightPointGains"] = gains


static func _clean_night_point_gains(value) -> Dictionary:
	var clean := {
		"Red": {"IP": 0, "MP": 0, "PP": 0},
		"Blue": {"IP": 0, "MP": 0, "PP": 0}
	}
	if value is Dictionary:
		for team_name in ["Red", "Blue"]:
			var raw_team = (value as Dictionary).get(team_name, {})
			if raw_team is Dictionary:
				for point_type in POINT_KEYS:
					clean[team_name][point_type] = maxi(0, int((raw_team as Dictionary).get(point_type, 0)))
	return clean


static func _run_morning_upkeep(snapshot: Dictionary) -> void:
	var day := int(snapshot.get("TurnDay", 0))
	if day <= 0 or int(snapshot.get("LastMorningUpkeepDay", -1)) == day:
		return
	var carryover := _clean_night_point_gains(snapshot.get("NightPointGains", {}))
	var generated := generate_points_from_track(snapshot)
	for team_name in ["Red", "Blue"]:
		var prefix := _point_prefix(team_name)
		var team_carry: Dictionary = carryover.get(team_name, {})
		for point_type in POINT_KEYS:
			var key := "%s%s" % [prefix, point_type]
			snapshot[key] = int(generated.get(key, 0)) + int(team_carry.get(point_type, 0))
	snapshot["NightPointGains"] = _clean_night_point_gains({})
	snapshot["LastMorningUpkeepDay"] = day
	var red_repairs := _repair_all_aircraft(snapshot, "Red", day)
	var blue_repairs := _repair_all_aircraft(snapshot, "Blue", day)
	_apply_morning_political_pressure(snapshot)
	_add_log(snapshot, "Day %d Morning upkeep generated political-track points and retained only Night action gains." % day)
	if not red_repairs.is_empty():
		_add_log(snapshot, red_repairs)
	if not blue_repairs.is_empty():
		_add_log(snapshot, blue_repairs)
	_run_morning_strategic_events(snapshot)


static func _apply_morning_political_pressure(snapshot: Dictionary) -> void:
	var pressure_value = snapshot.get("PoliticalPressureDays", {})
	var pressure: Dictionary = pressure_value.duplicate(true) if pressure_value is Dictionary else {"Red": 0, "Blue": 0}
	for team_name in ["Red", "Blue"]:
		var days_left := maxi(0, int(pressure.get(team_name, 0)))
		if days_left <= 0:
			continue
		var prefix := _point_prefix(team_name)
		snapshot["%sMP" % prefix] = maxi(0, int(snapshot.get("%sMP" % prefix, 0)) - 2)
		pressure[team_name] = days_left - 1
		_add_log(snapshot, "%s lost 2 MP to continuing political pressure (%d day(s) remain)." % [team_name, days_left - 1])
	snapshot["PoliticalPressureDays"] = pressure


static func _run_morning_strategic_events(snapshot: Dictionary) -> void:
	var day := int(snapshot.get("TurnDay", 0))
	if day <= 0 or int(snapshot.get("LastStrategicEventDay", -1)) == day:
		return
	snapshot["LastStrategicEventDay"] = day
	var queue: Array = []
	for team_name in ["Red", "Blue"]:
		var trigger_roll := randi_range(1, 6)
		var trigger_message := "%s Strategic Event check: D6=%d." % [team_name, trigger_roll]
		_add_log(snapshot, trigger_message)
		_add_dice_log(snapshot, trigger_message)
		if trigger_roll == 6:
			var event_roll := randi_range(1, 10)
			queue.append({"day": day, "roller": team_name, "trigger_roll": trigger_roll, "event_roll": event_roll})
			_add_dice_log(snapshot, "%s Strategic Event: D10=%d (%s)." % [team_name, event_roll, str(STRATEGIC_EVENT_NAMES.get(event_roll, "Unknown Event"))])
	snapshot["StrategicEventQueue"] = queue
	if bool(snapshot.get("StrategicEventCancelled", false)) and not queue.is_empty():
		var cancelled: Dictionary = queue.pop_front()
		snapshot["StrategicEventQueue"] = queue
		snapshot["StrategicEventCancelled"] = false
		var cancel_message := "%s's %s was cancelled by Official Coverup." % [str(cancelled.get("roller", "A team")), str(STRATEGIC_EVENT_NAMES.get(int(cancelled.get("event_roll", 0)), "strategic event"))]
		_record_strategic_history(snapshot, cancelled, cancel_message, true)
		_add_log(snapshot, cancel_message)
	_process_strategic_event_queue(snapshot)


static func _process_strategic_event_queue(snapshot: Dictionary) -> void:
	var pending_value = snapshot.get("PendingCard", {})
	if pending_value is Dictionary and not (pending_value as Dictionary).is_empty():
		return
	var queue := _clean_dictionary_array(snapshot.get("StrategicEventQueue", []))
	while not queue.is_empty():
		var event: Dictionary = queue.pop_front()
		snapshot["StrategicEventQueue"] = queue.duplicate(true)
		var result := _begin_strategic_event(snapshot, event)
		if bool(result.get("pending", false)):
			return
		var message := str(result.get("message", "Strategic event resolved."))
		_record_strategic_history(snapshot, event, message)
		_add_log(snapshot, message)
	snapshot["StrategicEventQueue"] = []


static func _begin_strategic_event(snapshot: Dictionary, event: Dictionary) -> Dictionary:
	var roller := str(event.get("roller", "Red"))
	var opponent := _opposing_team(roller)
	var event_roll := clampi(int(event.get("event_roll", 1)), 1, 10)
	var event_name := str(STRATEGIC_EVENT_NAMES.get(event_roll, "Strategic Event"))
	var prefix := _point_prefix(roller)
	match event_roll:
		1:
			var pp_key := "%sPP" % prefix
			var current_pp := maxi(0, int(snapshot.get(pp_key, 0)))
			var pp_loss := int(floor(float(current_pp) / 2.0)) if current_pp >= 6 else mini(3, current_pp)
			snapshot[pp_key] = current_pp - pp_loss
			_shift_all_tracks_against(snapshot, roller)
			var required_units := maxi(0, (3 - current_pp) * 3)
			var message := "%s - %s lost %d PP and every opinion track shifted one space against it." % [event_name, roller, pp_loss]
			if required_units > 0:
				snapshot["PendingCard"] = {
					"type": "strategic_domestic_exchange",
					"title": event_name,
					"card_id": 0,
					"owner_team": roller,
					"resolving_team": roller,
					"required_units": required_units,
					"event": event.duplicate(true),
					"result_prefix": message
				}
				_add_log(snapshot, "%s %s must exchange %d combined MP/IP at the 3:1 rate." % [message, roller, required_units])
				return {"pending": true, "message": message}
			return {"pending": false, "message": message}
		2:
			var affected_team := "Blue" if roller == "Red" else "Red"
			var sector := "Israeli airspace" if affected_team == "Blue" else "Sector %s" % ["I", "II", "III", "IV"][randi_range(0, 3)]
			snapshot["WeatherRestriction"] = {"team": affected_team, "sector": sector, "day": int(snapshot.get("TurnDay", 0)), "turn": int(snapshot.get("TurnTime", 0))}
			return {"pending": false, "message": "%s - aircraft assigned to %s cannot operate for this map turn." % [event_name, sector]}
		3:
			var nuclear_targets: Array = []
			for target_value in all_target_metadata():
				var target: Dictionary = target_value if target_value is Dictionary else {}
				if str(target.get("type", "")) == "Nuclear":
					nuclear_targets.append(target)
			var damage_message := "No nuclear target was available."
			if not nuclear_targets.is_empty():
				var chosen: Dictionary = nuclear_targets[randi_range(0, nuclear_targets.size() - 1)]
				damage_message = _apply_target_damage(snapshot, str(chosen.get("id", "")), 1)
			var track := _clean_track(snapshot.get("PoliticalTrack", {}))
			track["IR"] = clampi(int(track.get("IR", 0)) + 3, -10, 10)
			snapshot["PoliticalTrack"] = track
			var opinion_results: Array[String] = []
			for country_code in ["TR", "JO", "SA", "UN"]:
				opinion_results.append(_roll_opinion_attempts(snapshot, "Blue", country_code, 1, event_name))
			return {"pending": false, "message": "%s - %s Iran shifted 3 spaces against Red; %s" % [event_name, damage_message, " ".join(opinion_results)]}
		4:
			snapshot["%sMP" % prefix] = maxi(0, int(snapshot.get("%sMP" % prefix, 0)) - 5)
			var domestic_code := "IR" if roller == "Red" else "IL"
			var accident_roll := _roll_opinion_attempts(snapshot, opponent, domestic_code, 1, event_name)
			return {"pending": false, "message": "%s - %s lost 5 MP. %s" % [event_name, roller, accident_roll]}
		5:
			var overt_value = snapshot.get("LastOvertMapTurn", {})
			var overt_turns: Dictionary = overt_value if overt_value is Dictionary else {}
			if _map_turn_number(snapshot) - int(overt_turns.get(roller, -999)) > 3:
				return {"pending": false, "message": "%s - ignored because %s made no overt attack in the previous three map turns." % [event_name, roller]}
			snapshot["%sPP" % prefix] = maxi(0, int(snapshot.get("%sPP" % prefix, 0)) - 5)
			var affected_options: Array[String] = ["IR", "IL", "JO", "PRC", "RU", "SA", "TR", "US"]
			var affected := affected_options[randi_range(0, affected_options.size() - 1)]
			var target_roll := _roll_opinion_attempts(snapshot, opponent, affected, 1, event_name)
			var un_roll := _roll_opinion_attempts(snapshot, opponent, "UN", 1, event_name)
			return {"pending": false, "message": "%s - %s lost 5 PP; %s %s" % [event_name, roller, target_roll, un_roll]}
		6:
			var duration_roll := randi_range(1, 6)
			var duration_days := ceili(float(duration_roll) / 3.0)
			var pressure_value = snapshot.get("PoliticalPressureDays", {})
			var pressure: Dictionary = pressure_value.duplicate(true) if pressure_value is Dictionary else {"Red": 0, "Blue": 0}
			snapshot["%sMP" % prefix] = maxi(0, int(snapshot.get("%sMP" % prefix, 0)) - 2)
			pressure[roller] = maxi(int(pressure.get(roller, 0)), duration_days - 1)
			snapshot["PoliticalPressureDays"] = pressure
			return {"pending": false, "message": "%s - %s rolled D6=%d, lost 2 MP now, and will lose 2 MP at Morning for %d more day(s)." % [event_name, roller, duration_roll, duration_days - 1]}
		7:
			snapshot["%sPP" % prefix] = maxi(0, int(snapshot.get("%sPP" % prefix, 0)) - 5)
			return {"pending": false, "message": "%s - %s lost 5 PP." % [event_name, roller]}
		8:
			var opponent_prefix := _point_prefix(opponent)
			snapshot["%sIP" % opponent_prefix] = maxi(0, int(snapshot.get("%sIP" % opponent_prefix, 0)) - 5)
			var arrest_code := "IR" if roller == "Red" else "IL"
			var arrest_roll := _roll_opinion_attempts(snapshot, opponent, arrest_code, 1, event_name)
			return {"pending": false, "message": "%s - %s lost 5 IP. %s" % [event_name, opponent, arrest_roll]}
		9:
			var countries: Array[String] = ["PRC", "RU", "SA", "JO", "TR", "US"]
			var reset_country := countries[randi_range(0, countries.size() - 1)]
			var reset_track := _clean_track(snapshot.get("PoliticalTrack", {}))
			var previous := int(reset_track.get(reset_country, 0))
			reset_track[reset_country] = 0
			snapshot["PoliticalTrack"] = reset_track
			return {"pending": false, "message": "%s - %s reset from %+d to 0." % [event_name, reset_country, previous]}
		10:
			snapshot["PendingCard"] = {
				"type": "strategic_intifada",
				"title": event_name,
				"card_id": 0,
				"owner_team": roller,
				"resolving_team": "Red",
				"event": event.duplicate(true)
			}
			_add_log(snapshot, "%s - Red must choose whether to spend up to 12 MP before rolling on Israel." % event_name)
			return {"pending": true, "message": event_name}
	return {"pending": false, "message": "%s had no effect." % event_name}


static func _complete_strategic_event(snapshot: Dictionary, pending: Dictionary, resolution: String) -> void:
	var event_value = pending.get("event", {})
	var event: Dictionary = event_value if event_value is Dictionary else {}
	var prefix := str(pending.get("result_prefix", ""))
	var full_result := resolution if prefix.is_empty() else "%s %s" % [prefix, resolution]
	_record_strategic_history(snapshot, event, full_result)
	_add_log(snapshot, full_result)


static func _record_strategic_history(snapshot: Dictionary, event: Dictionary, result: String, cancelled: bool = false) -> void:
	var history := _clean_dictionary_array(snapshot.get("StrategicEventHistory", []))
	history.append({
		"day": int(event.get("day", snapshot.get("TurnDay", 0))),
		"roller": str(event.get("roller", "")),
		"trigger_roll": int(event.get("trigger_roll", 0)),
		"event_roll": int(event.get("event_roll", 0)),
		"name": str(STRATEGIC_EVENT_NAMES.get(int(event.get("event_roll", 0)), "Strategic Event")),
		"result": result,
		"cancelled": cancelled
	})
	while history.size() > 40:
		history.pop_front()
	snapshot["StrategicEventHistory"] = history


static func _shift_all_tracks_against(snapshot: Dictionary, team_name: String) -> void:
	var track := _clean_track(snapshot.get("PoliticalTrack", {}))
	var direction := 1 if team_name == "Red" else -1
	for country_code in COUNTRY_CODES:
		track[country_code] = clampi(int(track.get(country_code, 0)) + direction, -10, 10)
	snapshot["PoliticalTrack"] = track


static func _roll_opinion_attempts(snapshot: Dictionary, team_name: String, country_code: String, rolls: int, label: String) -> String:
	var track := _clean_track(snapshot.get("PoliticalTrack", {}))
	var direction := -1 if team_name == "Red" else 1
	var successes := 0
	var values: Array[String] = []
	for _index in range(maxi(1, rolls)):
		var current_position := int(track.get(country_code, 0))
		var desired_position := clampi(current_position + direction, -10, 10)
		if desired_position == current_position:
			values.append("limit")
			continue
		var difficulty := maxi(political_difficulty(current_position), political_difficulty(desired_position))
		var roll := randi_range(1, 10)
		values.append("%d/%d" % [roll, difficulty])
		if roll >= difficulty:
			successes += 1
			track[country_code] = desired_position
	snapshot["PoliticalTrack"] = track
	var summary := "%s rolled %s on %s: %d success(es) [%s]." % [team_name, label, country_code, successes, ", ".join(values)]
	_add_dice_log(snapshot, summary)
	return summary


static func _map_turn_number(snapshot: Dictionary) -> int:
	var day := maxi(0, int(snapshot.get("TurnDay", 0)))
	var turn := clampi(int(snapshot.get("TurnTime", 0)), 0, 2)
	return day * 3 + turn


static func _repair_all_aircraft(snapshot: Dictionary, team_name: String, day: int) -> String:
	var marker_value = snapshot.get("LastAircraftRepairDay", {})
	var markers: Dictionary = marker_value.duplicate(true) if marker_value is Dictionary else {"Red": -1, "Blue": -1}
	if int(markers.get(team_name, -1)) == day:
		return ""
	var aircraft := _aircraft_list(snapshot, team_name)
	var eligible := 0
	var repaired := 0
	var rolls: Array[String] = []
	for index in range(aircraft.size()):
		var row := (aircraft[index] as Dictionary).duplicate(true)
		var mission := str(row.get("mission", "Ready"))
		if team_name == "Red" and ["Alert", "Patrol"].has(mission):
			continue
		var damaged := int(row.get("damaged", 0))
		if damaged <= 0:
			continue
		var chance := _repair_chance(str(row.get("model", "")))
		if mission == "Stand Down":
			chance = mini(100, chance + 10)
		var row_repaired := 0
		for _damaged_index in range(damaged):
			eligible += 1
			var roll := randi_range(1, 100)
			if roll <= chance:
				row_repaired += 1
				repaired += 1
		row["damaged"] = maxi(0, damaged - row_repaired)
		row["operational"] = mini(int(row.get("total", 0)), int(row.get("operational", 0)) + row_repaired)
		aircraft[index] = row
		rolls.append("%s %d/%d" % [str(row.get("name", "Squadron")), row_repaired, damaged])
	snapshot[_aircraft_key(team_name)] = aircraft
	markers[team_name] = day
	snapshot["LastAircraftRepairDay"] = markers
	var message := "%s Morning repairs: %d/%d aircraft repaired" % [team_name, repaired, eligible]
	if not rolls.is_empty():
		message += " (%s)" % ", ".join(rolls)
	_add_aircraft_event(snapshot, message)
	return message


static func _run_end_map_turn_aircraft(snapshot: Dictionary) -> void:
	_run_red_breakdowns(snapshot)
	_advance_blue_aircraft_cycle(snapshot)


static func _run_red_breakdowns(snapshot: Dictionary) -> String:
	var turn_key := "%d:%d" % [int(snapshot.get("TurnDay", 0)), int(snapshot.get("TurnTime", 3))]
	if str(snapshot.get("LastRedBreakdownTurn", "")) == turn_key:
		return ""
	var aircraft := _aircraft_list(snapshot, "Red")
	var roll_total := randi_range(1, 6) + randi_range(1, 6)
	var total_down := 0
	var affected: Array[String] = []
	for index in range(aircraft.size()):
		var row := (aircraft[index] as Dictionary).duplicate(true)
		if str(row.get("mission", "Ready")) == "Stand Down" or int(row.get("operational", 0)) <= 0:
			continue
		var loss := _breakdown_loss("Red", str(row.get("model", "")), roll_total, int(row.get("total", 0)), str(row.get("mission", "Ready")))
		loss = mini(loss, int(row.get("operational", 0)))
		row["operational"] = maxi(0, int(row.get("operational", 0)) - loss)
		row["damaged"] = mini(int(row.get("total", 0)), int(row.get("damaged", 0)) + loss)
		aircraft[index] = row
		total_down += loss
		if loss > 0:
			affected.append("%s -%d" % [str(row.get("name", "Squadron")), loss])
	snapshot["RedAircraft"] = aircraft
	snapshot["LastRedBreakdownTurn"] = turn_key
	var message := "Red squadron breakdown D6+D6 = %d: %d aircraft down" % [roll_total, total_down]
	if not affected.is_empty():
		message += " (%s)" % ", ".join(affected)
	_add_aircraft_event(snapshot, message)
	_add_log(snapshot, message)
	return message


static func _resolve_blue_return_breakdowns(snapshot: Dictionary) -> String:
	var aircraft := _aircraft_list(snapshot, "Blue")
	var returning := 0
	var total_down := 0
	var details: Array[String] = []
	for index in range(aircraft.size()):
		var row := (aircraft[index] as Dictionary).duplicate(true)
		if str(row.get("mission", "Ready")) != "In Flight 2" or bool(row.get("return_breakdown_done", false)):
			continue
		returning += 1
		var roll_total := randi_range(1, 6) + randi_range(1, 6)
		var loss := mini(_breakdown_loss("Blue", str(row.get("model", "")), roll_total, int(row.get("total", 0)), ""), int(row.get("operational", 0)))
		row["operational"] = maxi(0, int(row.get("operational", 0)) - loss)
		row["damaged"] = mini(int(row.get("total", 0)), int(row.get("damaged", 0)) + loss)
		row["return_breakdown_done"] = true
		aircraft[index] = row
		total_down += loss
		details.append("%s %d (-%d)" % [str(row.get("name", "Squadron")), roll_total, loss])
	if returning == 0:
		return ""
	snapshot["BlueAircraft"] = aircraft
	var message := "Blue return breakdowns: %d squadron(s), %d aircraft down (%s)" % [returning, total_down, ", ".join(details)]
	_add_aircraft_event(snapshot, message)
	_add_log(snapshot, message)
	return message


static func _advance_blue_aircraft_cycle(snapshot: Dictionary) -> void:
	_resolve_blue_return_breakdowns(snapshot)
	var aircraft := _aircraft_list(snapshot, "Blue")
	var changes: Array[String] = []
	for index in range(aircraft.size()):
		var row := (aircraft[index] as Dictionary).duplicate(true)
		var current := str(row.get("mission", "Ready"))
		var next_status := current
		match current:
			"Fragged":
				next_status = "In Flight 1"
			"In Flight 1":
				next_status = "In Flight 2"
			"In Flight 2":
				next_status = "Resting"
			"Resting":
				next_status = "Ready"
		if next_status != current:
			row["mission"] = next_status
			if next_status == "Ready":
				row["committed"] = 0
				row["assignment"] = ""
				row["loadout"] = ""
				row["operation_id"] = ""
			if next_status != "In Flight 2":
				row["return_breakdown_done"] = false
			changes.append("%s: %s to %s" % [str(row.get("name", "Squadron")), current, next_status])
		aircraft[index] = row
	snapshot["BlueAircraft"] = aircraft
	if not changes.is_empty():
		var message := "Blue mission cycle: %s" % "; ".join(changes)
		_add_aircraft_event(snapshot, message)
		_add_log(snapshot, message)


static func _add_log(snapshot: Dictionary, entry: String) -> void:
	var clean_entry := entry.strip_edges()
	if clean_entry.is_empty():
		return
	var log_entries: Array = []
	var existing_log = snapshot.get("ActionLog", [])
	if existing_log is Array:
		for item in existing_log:
			log_entries.append(str(item))
	var prefix := turn_label(snapshot)
	log_entries.append("%s | %s" % [prefix, clean_entry])
	while log_entries.size() > 120:
		log_entries.pop_front()
	snapshot["ActionLog"] = log_entries


static func _add_dice_log(snapshot: Dictionary, entry: String) -> void:
	var dice_log := _clean_string_array(snapshot.get("DiceLog", []))
	dice_log.append("%s | %s" % [turn_label(snapshot), entry])
	while dice_log.size() > DICE_LOG_LIMIT:
		dice_log.pop_front()
	snapshot["DiceLog"] = dice_log


static func _add_aircraft_event(snapshot: Dictionary, entry: String) -> void:
	var events := _clean_string_array(snapshot.get("AircraftEvents", []))
	events.append("%s | %s" % [turn_label(snapshot), entry])
	while events.size() > DICE_LOG_LIMIT:
		events.pop_front()
	snapshot["AircraftEvents"] = events


static func _clean_string_array(value) -> Array:
	var cleaned: Array = []
	if value is Array:
		for item in value:
			cleaned.append(str(item))
	elif not str(value).is_empty():
		cleaned.append(str(value))
	return cleaned


static func _clean_dictionary_array(value) -> Array:
	var cleaned: Array = []
	if value is Array:
		for item in value:
			if item is Dictionary:
				cleaned.append((item as Dictionary).duplicate(true))
	return cleaned


static func _clean_selected_upgrades(value) -> Dictionary:
	var selected := {
		"Blue": [],
		"Red": [],
		"RedExtra": []
	}
	if value is Dictionary:
		for team_name in selected.keys():
			selected[team_name] = _clean_dictionary_array((value as Dictionary).get(team_name, []))
	return selected


static func _clean_upgrade_points(value) -> Dictionary:
	var points := {
		"Blue": 100,
		"Red": 100,
		"RedExtra": 40
	}
	if value is Dictionary:
		for team_name in points.keys():
			points[team_name] = maxi(0, int((value as Dictionary).get(team_name, points[team_name])))
	return points


static func _sync_upgrade_text(snapshot: Dictionary) -> void:
	var selected := _clean_selected_upgrades(snapshot.get("SelectedUpgrades", {}))
	var blue_names: Array[String] = []
	var red_names: Array[String] = []
	for item in selected.get("Blue", []):
		if item is Dictionary:
			blue_names.append(str((item as Dictionary).get("name", "")))
	for item in selected.get("Red", []):
		if item is Dictionary:
			red_names.append(str((item as Dictionary).get("name", "")))
	for item in selected.get("RedExtra", []):
		if item is Dictionary:
			red_names.append(str((item as Dictionary).get("name", "")))
	snapshot["BlueUpgrades"] = "\n".join(blue_names)
	snapshot["RedUpgrades"] = "\n".join(red_names)


static func _normalize_aircraft_row(row: Dictionary) -> Dictionary:
	var total := maxi(0, int(row.get("total", row.get("operational", 0))))
	var operational := clampi(int(row.get("operational", total)), 0, total)
	var damaged := clampi(int(row.get("damaged", 0)), 0, total)
	var downed := clampi(int(row.get("downed", 0)), 0, total)
	return {
		"team": str(row.get("team", "")),
		"name": str(row.get("name", "Squadron")),
		"model": str(row.get("model", "Unknown")),
		"total": total,
		"operational": operational,
		"damaged": damaged,
		"downed": downed,
		"missing": clampi(int(row.get("missing", 0)), 0, total),
		"kia": clampi(int(row.get("kia", 0)), 0, total),
		"mission": str(row.get("mission", "Ready")),
		"location": str(row.get("location", "Home")),
		"return_breakdown_done": bool(row.get("return_breakdown_done", false)),
		"committed": clampi(int(row.get("committed", 0)), 0, operational),
		"assignment": str(row.get("assignment", "")),
		"loadout": str(row.get("loadout", "")),
		"operation_id": str(row.get("operation_id", ""))
	}


static func _aircraft_key(team_name: String) -> String:
	return "RedAircraft" if team_name == "Red" else "BlueAircraft"


static func _aircraft_list(snapshot: Dictionary, team_name: String) -> Array:
	var raw_list = snapshot.get(_aircraft_key(team_name), [])
	var aircraft: Array = []
	if raw_list is Array:
		for item in raw_list:
			if item is Dictionary:
				var row := _normalize_aircraft_row(item as Dictionary)
				row["team"] = team_name
				aircraft.append(row)
	if aircraft.is_empty():
		aircraft = default_aircraft_for_team(team_name)
	return aircraft


static func _find_repair_aircraft(aircraft: Array) -> int:
	for index in range(aircraft.size()):
		var row := aircraft[index] as Dictionary
		var mission := str(row.get("mission", ""))
		if int(row.get("damaged", 0)) > 0 and mission != "Alert" and mission != "Patrol":
			return index
	return -1


static func _find_operational_aircraft(aircraft: Array) -> int:
	for index in range(aircraft.size()):
		var row := aircraft[index] as Dictionary
		if int(row.get("operational", 0)) > 0 and str(row.get("mission", "")) != "Stand Down":
			return index
	return -1


static func _repair_chance(model: String) -> int:
	match model:
		"F16I", "F15I", "Shavit", "Eitan":
			return 85
		"KC707":
			return 70
		"MIG29A", "F7MN":
			return 70
		"F5EF", "F4DE":
			return 55
		"F14AGR":
			return 40
		"MIG29SMT", "MIG31", "J10A", "J11A", "SU27":
			return 85
	return 60


static func _breakdown_loss(team_name: String, model: String, roll_total: int, total: int, mission: String) -> int:
	if roll_total < 2:
		return 0
	if team_name == "Blue":
		match roll_total:
			5, 6:
				return 1
			7, 8:
				return 2
			9, 10:
				return 3
			11:
				return 4
			12:
				return 5
		return 0

	var index := clampi(roll_total - 2, 0, 12)
	if mission == "Alert":
		index = clampi(index + 1, 0, 12)
	elif mission == "Patrol":
		index = clampi(index + 2, 0, 12)
	var table: Array[int] = []
	match model:
		"MIG29A":
			table = [0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6]
		"F14AGR":
			table = [0, 1, 1, 2, 2, 2, 3, 3, 3, 4, 4, 4, 4]
		"F7MN":
			table = [0, 0, 0, 0, 1, 1, 1, 2, 2, 3, 3, 3, 4]
		"F5EF", "F4DE":
			if total >= 10:
				table = [0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 5, 6]
			else:
				table = [0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6]
		"MIG29SMT", "MIG31", "J10A", "J11A", "SU27":
			table = [0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 2, 2, 3]
		_:
			table = [0, 0, 0, 0, 1, 1, 1, 2, 2, 2, 3, 3, 4]
	return int(table[index])


static func _tick_planned_actions(snapshot: Dictionary, amount: int) -> void:
	var planned := _clean_dictionary_array(snapshot.get("PlannedActions", []))
	for index in range(planned.size()):
		var row := (planned[index] as Dictionary).duplicate(true)
		row["wait_time"] = maxi(0, int(row.get("wait_time", 0)) - amount)
		planned[index] = row
	snapshot["PlannedActions"] = planned


static func _int_array_to_string(values: Array, separator: String) -> String:
	var parts: Array[String] = []
	for value in values:
		parts.append(str(int(value)))
	return separator.join(parts)


static func _result(ok: bool, snapshot: Dictionary, message: String) -> Dictionary:
	return {
		"ok": ok,
		"snapshot": snapshot,
		"message": message
	}
