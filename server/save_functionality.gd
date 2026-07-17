class_name SaveFunctionality
extends RefCounted

const GameRules = preload("res://server/game_rules.gd")
const SAVE_ROOT: String = "user://phantom_arrow_saves"
const SAVE_FILE_NAME: String = "path.json"
const SAVE_SCHEMA_VERSION: int = 2
const MAX_HISTORY_SNAPSHOTS: int = 1
const TEMP_SUFFIX: String = ".tmp"
const BACKUP_SUFFIX: String = ".bak"


static func create_new_game(raw_name: String) -> Dictionary:
	var game_name := sanitize_game_name(raw_name)
	if game_name.is_empty():
		return _error("Enter a valid game name.")

	ensure_save_root()
	var session_dir := get_session_dir(game_name)
	if DirAccess.dir_exists_absolute(session_dir):
		return _error("A save named \"%s\" already exists. Choose a different name or load it." % game_name)

	var dir_error := DirAccess.make_dir_recursive_absolute(session_dir)
	if dir_error != OK:
		return _error("Could not create save folder. Error code: %d" % dir_error)

	var history: Array = [make_default_save_data()]
	var write_result := write_json(game_name, history)
	if not bool(write_result.get("ok", false)):
		return write_result

	return write_result


static func get_files() -> Array:
	ensure_save_root()

	var saved_games: Array = []
	var dir := DirAccess.open(SAVE_ROOT)
	if dir == null:
		return saved_games

	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		if dir.current_is_dir() and not entry.begins_with("."):
			var read_result := read_json(entry)
			var history: Array = read_result.get("history", [])
			var snapshot: Dictionary = history[history.size() - 1] if not history.is_empty() else make_default_save_data()
			saved_games.append({
				"name": entry,
				"has_save_data": FileAccess.file_exists(get_session_save_path(entry)),
				"summary": snapshot_summary(snapshot)
			})
		entry = dir.get_next()
	dir.list_dir_end()

	saved_games.sort_custom(_compare_saved_game_names)
	return saved_games


static func read_json(raw_name: String) -> Dictionary:
	var game_name := sanitize_game_name(raw_name)
	if game_name.is_empty():
		return _error("Choose a saved game to load.")

	var save_path := get_session_save_path(game_name)
	if not FileAccess.file_exists(save_path):
		if FileAccess.file_exists(save_path + BACKUP_SUFFIX):
			return _read_backup_or_error(game_name, "Primary save file is missing.")
		return _ok(game_name, [])

	var raw := FileAccess.get_file_as_string(save_path).strip_edges()
	if raw.is_empty():
		return _read_backup_or_error(game_name, "Save file is empty.")

	var parsed = _parse_json(raw)
	var history: Array = []

	if typeof(parsed) == TYPE_ARRAY:
		for item in parsed:
			if typeof(item) == TYPE_DICTIONARY:
				history.append(normalize_save_snapshot(item))
	elif typeof(parsed) == TYPE_DICTIONARY:
		if parsed.get("history", null) is Array:
			for item in parsed.get("history", []):
				if typeof(item) == TYPE_DICTIONARY:
					history.append(normalize_save_snapshot(item))
		elif parsed.get("latest", null) is Dictionary:
			history.append(normalize_save_snapshot(parsed.get("latest", {})))
		elif parsed.get("snapshot", null) is Dictionary:
			history.append(normalize_save_snapshot(parsed.get("snapshot", {})))
		else:
			history.append(normalize_save_snapshot(parsed))
	else:
		return _read_backup_or_error(game_name, "Save file is not valid JSON save data.")

	return _ok(game_name, history)


static func load_game(raw_name: String) -> Dictionary:
	var game_name := sanitize_game_name(raw_name)
	if game_name.is_empty():
		return _error("Choose a saved game to load.")

	if not DirAccess.dir_exists_absolute(get_session_dir(game_name)):
		return _error("Save \"%s\" was not found." % game_name)

	var read_result := read_json(game_name)
	if not bool(read_result.get("ok", false)):
		return read_result

	var history: Array = read_result.get("history", [])
	if history.is_empty():
		history = [make_default_save_data()]
		return write_json(game_name, history)

	return _ok(game_name, history)


static func import_game(raw_name: String, history: Array) -> Dictionary:
	var game_name := sanitize_game_name(raw_name)
	if game_name.is_empty():
		return _error("Choose a saved game to load.")

	return write_json(game_name, history)


static func write_json(raw_name: String, history: Array) -> Dictionary:
	var game_name := sanitize_game_name(raw_name)
	if game_name.is_empty():
		return _error("Enter a valid game name.")

	ensure_save_root()
	var session_dir := get_session_dir(game_name)
	var dir_error := DirAccess.make_dir_recursive_absolute(session_dir)
	if dir_error != OK:
		return _error("Could not prepare save folder. Error code: %d" % dir_error)

	var normalized_history := _normalized_history_or_default(history)

	var save_path := get_session_save_path(game_name)
	var temp_path := save_path + TEMP_SUFFIX
	var backup_path := save_path + BACKUP_SUFFIX
	if FileAccess.file_exists(temp_path):
		DirAccess.remove_absolute(temp_path)
	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		return _error("Could not write save file. Error code: %d" % FileAccess.get_open_error())

	var payload := {
		"schema_version": SAVE_SCHEMA_VERSION,
		"game_name": game_name,
		"updated_at": Time.get_datetime_string_from_system(false, true),
		"history": normalized_history
	}
	file.store_string(JSON.stringify(payload, "\t"))
	file.flush()
	file = null

	if FileAccess.file_exists(backup_path):
		DirAccess.remove_absolute(backup_path)
	if FileAccess.file_exists(save_path):
		var backup_error := DirAccess.rename_absolute(save_path, backup_path)
		if backup_error != OK:
			DirAccess.remove_absolute(temp_path)
			return _error("Could not prepare the previous save for replacement. Error code: %d" % backup_error)

	var replace_error := DirAccess.rename_absolute(temp_path, save_path)
	if replace_error != OK:
		if FileAccess.file_exists(backup_path):
			DirAccess.rename_absolute(backup_path, save_path)
		DirAccess.remove_absolute(temp_path)
		return _error("Could not replace save file. Error code: %d" % replace_error)
	return _ok(game_name, normalized_history)


static func append_snapshot(raw_name: String, history: Array, snapshot: Dictionary) -> Dictionary:
	return write_json(raw_name, [normalize_save_snapshot(snapshot)])


static func white_add_data(raw_name: String, history: Array, turn_day: int, turn_time: int, current_team: String) -> Dictionary:
	var snapshot := latest_snapshot(history)
	snapshot["TurnDay"] = turn_day
	snapshot["TurnTime"] = turn_time
	snapshot["ChangeTeam"] = current_team
	return append_snapshot(raw_name, history, snapshot)


static func rb_add_data(raw_name: String, history: Array, team: int, ip: int, mp: int, pp: int) -> Dictionary:
	var snapshot := latest_snapshot(history)
	if team == 0:
		snapshot["IranIP"] = ip
		snapshot["IranMP"] = mp
		snapshot["IranPP"] = pp
	else:
		snapshot["IsrealIP"] = ip
		snapshot["IsrealMP"] = mp
		snapshot["IsrealPP"] = pp
	return append_snapshot(raw_name, history, snapshot)


static func political_track_data(raw_name: String, history: Array, country_name: String, track_place: int) -> Dictionary:
	var snapshot := latest_snapshot(history)
	snapshot["CountryName"] = country_name
	snapshot["TrackPlace"] = track_place
	return append_snapshot(raw_name, history, snapshot)


static func add_river(
	raw_name: String,
	history: Array,
	blue_card_river: String,
	blue_card_deck: String,
	blue_card_discard: String,
	red_card_deck: String,
	red_card_river: String,
	red_card_discard: String
) -> Dictionary:
	var snapshot := latest_snapshot(history)
	snapshot["_blueCardRiver"] = blue_card_river
	snapshot["_blueCardDeck"] = blue_card_deck
	snapshot["_blueCardDiscard"] = blue_card_discard
	snapshot["_redCardDeck"] = red_card_deck
	snapshot["_redCardRiver"] = red_card_river
	snapshot["_redCardDiscard"] = red_card_discard
	return append_snapshot(raw_name, history, snapshot)


static func latest_snapshot(history: Array) -> Dictionary:
	if history.is_empty():
		return make_default_save_data()

	var latest = history[history.size() - 1]
	if typeof(latest) != TYPE_DICTIONARY:
		return make_default_save_data()

	return normalize_save_snapshot(latest)


static func make_default_save_data() -> Dictionary:
	return GameRules.make_default_snapshot()


static func normalize_save_snapshot(snapshot: Dictionary) -> Dictionary:
	var normalized := make_default_save_data()
	for key in snapshot.keys():
		normalized[str(key)] = snapshot[key]

	for key in ["TurnDay", "TurnTime", "Move", "PassCounter", "TimeRemaining", "OverallTime", "LastPlayedCard", "IsrealIP", "IsrealMP", "IsrealPP", "IranIP", "IranMP", "IranPP", "TrackPlace", "RedPOW", "RedGCI", "RedSAM", "RedGCIMapTurn", "BluePOW", "BlueHitChance", "RedRiverRightmostCard", "BlueRiverRightmostCard", "CampaignDays", "StraitCooldown", "LastMorningUpkeepDay", "LastStrategicEventDay", "IsraeliStrategicMissilesDestroyed", "BlueAircraftLosses", "SuterAttackCount"]:
		normalized[key] = int(normalized.get(key, 0))

	for key in ["ChangeTeam", "ActionTeam", "LastCardTeam", "LastRollSummary", "CountryName", "ScenarioName", "StraitStatus", "RiverRevealForTeam", "LastRedBreakdownTurn", "_blueCardRiver", "_blueCardDeck", "_blueCardDiscard", "_redCardRiver", "_redCardDeck", "_redCardDiscard", "BlueUpgrades", "RedUpgrades"]:
		normalized[key] = str(normalized.get(key, ""))

	for key in ["TimerRunning", "TimerStarted", "ActionPending", "RedLastCardDirty", "RedLastCardCovert", "RedLastActionOvert", "RedPRCSupport", "RedRussiaSupport", "BlueLastCardDirty", "BlueLastCardCovert", "BlueLastActionOvert", "BlueAirStrikeThisTurn", "BlueTurkeySupport", "BlueUSSupport", "BlueSaudiSupport", "StrategicEventCancelled", "BlueBunkerHill", "BlueBurkeDestroyer", "ConflictStarted", "GameOver"]:
		normalized[key] = bool(normalized.get(key, false))

	for dictionary_key in ["PendingCard", "TrackLocks", "SleeperAgentReady", "CardCounterTokens", "LastAircraftRepairDay", "NightPointGains", "PoliticalPressureDays", "WeatherRestriction", "LastOvertMapTurn", "BallisticDefenseUsage", "IsraeliTargetDamage", "OverflightUsed", "TargetLastStrikeTurn", "TargetVictoryLevels", "TargetFractionalDamage", "StrategyVictory"]:
		var dictionary_value = normalized.get(dictionary_key, {})
		normalized[dictionary_key] = dictionary_value.duplicate(true) if typeof(dictionary_value) == TYPE_DICTIONARY else {}
	normalized["CampaignDays"] = maxi(1, int(normalized.get("CampaignDays", GameRules.MAX_DAY)))

	var game_over_summary = normalized.get("GameOverSummary", {})
	normalized["GameOverSummary"] = game_over_summary.duplicate(true) if typeof(game_over_summary) == TYPE_DICTIONARY else {}

	normalized["Targets"] = GameRules.merge_targets_with_defaults(normalized.get("Targets", {}))

	normalized = GameRules.ensure_card_decks(normalized)

	var default_track: Dictionary = make_default_save_data().get("PoliticalTrack", {})
	var track_value = normalized.get("PoliticalTrack", default_track)
	var normalized_track := default_track.duplicate()
	if typeof(track_value) == TYPE_DICTIONARY:
		for country_code in normalized_track.keys():
			normalized_track[country_code] = int(track_value.get(country_code, normalized_track[country_code]))
	if not normalized.get("CountryName", "").is_empty():
		var country_name := str(normalized.get("CountryName", ""))
		if normalized_track.has(country_name):
			normalized_track[country_name] = int(normalized.get("TrackPlace", normalized_track[country_name]))
	normalized["PoliticalTrack"] = normalized_track

	var action_log_value = normalized.get("ActionLog", [])
	var normalized_log: Array = []
	if typeof(action_log_value) == TYPE_ARRAY:
		for entry in action_log_value:
			normalized_log.append(str(entry))
	elif not str(action_log_value).is_empty():
		normalized_log.append(str(action_log_value))
	normalized["ActionLog"] = normalized_log

	for array_key in ["PlannedActions", "Notifications", "AircraftEvents", "RedAircraft", "BlueAircraft", "StrategicEventQueue", "StrategicEventHistory", "BallisticBattalionCooldowns", "BallisticAttackHistory", "AirstrikeHistory", "AirCombatHistory", "NuclearVictoryResults", "NuclearDecisiveSites", "OilVictoryResults", "VictoryRollHistory", "DestroyedRadars"]:
		var raw_array = normalized.get(array_key, [])
		var clean_array: Array = []
		if typeof(raw_array) == TYPE_ARRAY:
			for entry in raw_array:
				if typeof(entry) == TYPE_DICTIONARY:
					clean_array.append((entry as Dictionary).duplicate(true))
				else:
					clean_array.append(str(entry))
		normalized[array_key] = clean_array

	var changed_indices_value = normalized.get("RedAircraftChangedIndices", [])
	var changed_indices: Array = []
	if typeof(changed_indices_value) == TYPE_ARRAY:
		for raw_index in changed_indices_value:
			var clean_index := int(raw_index)
			if clean_index >= 0 and not changed_indices.has(clean_index):
				changed_indices.append(clean_index)
	normalized["RedAircraftChangedIndices"] = changed_indices

	for array_key in ["DiceLog", "AircraftEvents"]:
		var raw_text_array = normalized.get(array_key, [])
		var clean_text_array: Array = []
		if typeof(raw_text_array) == TYPE_ARRAY:
			for entry in raw_text_array:
				clean_text_array.append(str(entry))
		elif not str(raw_text_array).is_empty():
			clean_text_array.append(str(raw_text_array))
		normalized[array_key] = clean_text_array

	var selected_upgrades := {
		"Blue": [],
		"Red": [],
		"RedExtra": []
	}
	var raw_selected = normalized.get("SelectedUpgrades", {})
	if typeof(raw_selected) == TYPE_DICTIONARY:
		for team_name in selected_upgrades.keys():
			var raw_team_upgrades = raw_selected.get(team_name, [])
			var clean_team_upgrades: Array = []
			if typeof(raw_team_upgrades) == TYPE_ARRAY:
				for entry in raw_team_upgrades:
					if typeof(entry) == TYPE_DICTIONARY:
						clean_team_upgrades.append((entry as Dictionary).duplicate(true))
			selected_upgrades[team_name] = clean_team_upgrades
	normalized["SelectedUpgrades"] = selected_upgrades

	var upgrade_points := {
		"Blue": 100,
		"Red": 100,
		"RedExtra": 40
	}
	var raw_upgrade_points = normalized.get("UpgradePoints", {})
	if typeof(raw_upgrade_points) == TYPE_DICTIONARY:
		for team_name in upgrade_points.keys():
			upgrade_points[team_name] = max(0, int(raw_upgrade_points.get(team_name, upgrade_points[team_name])))
	normalized["UpgradePoints"] = upgrade_points

	return normalized


static func snapshot_summary(snapshot: Dictionary) -> String:
	var normalized := normalize_save_snapshot(snapshot)
	var turn_day := int(normalized.get("TurnDay", 0))
	var turn_time := int(normalized.get("TurnTime", 0))
	var team := str(normalized.get("ChangeTeam", "White"))
	var iran_points := "Iran IP/MP/PP %d/%d/%d" % [
		int(normalized.get("IranIP", 0)),
		int(normalized.get("IranMP", 0)),
		int(normalized.get("IranPP", 0))
	]
	var israel_points := "Israel IP/MP/PP %d/%d/%d" % [
		int(normalized.get("IsrealIP", 0)),
		int(normalized.get("IsrealMP", 0)),
		int(normalized.get("IsrealPP", 0))
	]

	return "Day %d, Turn %d, %s to act | %s | %s" % [turn_day, turn_time, team, iran_points, israel_points]


static func sanitize_game_name(raw_name: String) -> String:
	var trimmed := raw_name.strip_edges()
	var cleaned := ""

	for index in range(trimmed.length()):
		var character := trimmed.substr(index, 1)
		var code := character.unicode_at(0)
		var is_letter := (code >= 65 and code <= 90) or (code >= 97 and code <= 122)
		var is_number := code >= 48 and code <= 57
		var is_allowed_symbol := character == " " or character == "-" or character == "_"

		if is_letter or is_number or is_allowed_symbol:
			cleaned += character
		else:
			cleaned += "_"

	cleaned = cleaned.strip_edges()
	while cleaned.contains("  "):
		cleaned = cleaned.replace("  ", " ")

	if cleaned == "." or cleaned == "..":
		return ""

	return cleaned


static func ensure_save_root() -> void:
	if not DirAccess.dir_exists_absolute(SAVE_ROOT):
		DirAccess.make_dir_recursive_absolute(SAVE_ROOT)


static func get_session_dir(game_name: String) -> String:
	return "%s/%s" % [SAVE_ROOT, game_name]


static func get_session_save_path(game_name: String) -> String:
	if game_name.is_empty():
		return ""

	return "%s/%s" % [get_session_dir(game_name), SAVE_FILE_NAME]


static func _normalized_history_or_default(history: Array) -> Array:
	var normalized_history: Array = []
	var first_index := maxi(0, history.size() - MAX_HISTORY_SNAPSHOTS)
	for index in range(first_index, history.size()):
		var snapshot = history[index]
		if typeof(snapshot) == TYPE_DICTIONARY:
			normalized_history.append(normalize_save_snapshot(snapshot))

	if normalized_history.is_empty():
		normalized_history.append(make_default_save_data())

	return normalized_history


static func _read_backup_or_error(game_name: String, reason: String) -> Dictionary:
	var backup_path := get_session_save_path(game_name) + BACKUP_SUFFIX
	if not FileAccess.file_exists(backup_path):
		return _error("%s Save: %s" % [reason, get_session_save_path(game_name)])
	var raw := FileAccess.get_file_as_string(backup_path).strip_edges()
	var parsed = _parse_json(raw)
	var history: Array = []
	if typeof(parsed) == TYPE_ARRAY:
		for item in parsed:
			if typeof(item) == TYPE_DICTIONARY:
				history.append(normalize_save_snapshot(item))
	elif typeof(parsed) == TYPE_DICTIONARY:
		var backup_history = parsed.get("history", [])
		if backup_history is Array:
			for item in backup_history:
				if typeof(item) == TYPE_DICTIONARY:
					history.append(normalize_save_snapshot(item))
		elif parsed.get("latest", null) is Dictionary:
			history.append(normalize_save_snapshot(parsed.get("latest", {})))
		elif parsed.get("snapshot", null) is Dictionary:
			history.append(normalize_save_snapshot(parsed.get("snapshot", {})))
		else:
			history.append(normalize_save_snapshot(parsed))
	if history.is_empty():
		return _error("%s The backup is also invalid." % reason)
	return _ok(game_name, history)


static func _parse_json(raw: String):
	var parser := JSON.new()
	if parser.parse(raw) != OK:
		return null
	return parser.data


static func _ok(game_name: String, history: Array) -> Dictionary:
	var latest := latest_snapshot(history)
	return {
		"ok": true,
		"game_name": game_name,
		"history": _normalized_history_or_default(history),
		"latest": latest,
		"error": ""
	}


static func _error(message: String) -> Dictionary:
	return {
		"ok": false,
		"game_name": "",
		"history": [],
		"latest": make_default_save_data(),
		"error": message
	}


static func _compare_saved_game_names(left, right) -> bool:
	return str(left.get("name", "")).to_lower() < str(right.get("name", "")).to_lower()
