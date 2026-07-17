extends Node

const GameRules = preload("res://server/game_rules.gd")

signal status_changed(status_text: String)
signal players_changed(players: Dictionary)
signal server_error(message: String)
signal teams_changed(selected_teams: Dictionary)
signal team_selection_rejected(team_name: String, message: String)
signal lobby_changed(host_peer_id: int, lobby_player_ids: Array, selected_teams: Dictionary, game_starting: bool)
signal game_start_rejected(message: String)
signal session_changed(session_info: Dictionary, save_data: Dictionary)
signal save_list_changed(saved_games: Array)
signal game_started(session_info: Dictionary, save_data: Dictionary)
signal session_request_completed(success: bool, message: String)
signal team_selection_confirmed(team_name: String)
signal chat_message_received(message_data: Dictionary)

const DEFAULT_PORT: int = 9000
const MAX_PLAYERS: int = 10
const REQUIRED_PLAYERS: int = 3
const TEAM_NAMES: Array[String] = ["White", "Blue", "Red"]
const CHAT_CHANNEL_ANNOUNCEMENT: String = "Announcement"
const CHAT_CHANNEL_RED: String = "Red"
const CHAT_CHANNEL_BLUE: String = "Blue"
const CHAT_CHANNELS: Array[String] = [CHAT_CHANNEL_ANNOUNCEMENT, CHAT_CHANNEL_RED, CHAT_CHANNEL_BLUE]
const MAX_CHAT_HISTORY: int = 120
const MAX_CHAT_MESSAGE_LENGTH: int = 280
const SESSION_MODE_NONE: String = "None"
const SESSION_MODE_NEW: String = "New Game"
const SESSION_MODE_LOAD: String = "Loaded Game"
const CLIENT_SESSION_ACTION_NONE: String = ""
const CLIENT_SESSION_ACTION_NEW: String = "new_game"
const CLIENT_SESSION_ACTION_LOAD: String = "load_game"
const TIMER_AUTOSAVE_SECONDS: float = 15.0

const WHITE_ONLY_ACTIONS: Array[String] = [
	"start_timer", "reset_timer", "change_day", "change_turn", "set_team", "swap_team",
	"approve_action", "draw_river", "reset_card_decks", "send_rivers",
	"set_political_track", "reset_political_track", "adjust_points", "set_upgrades",
	"damage_target", "end_game", "resume_game", "clear_log"
]
const TEAM_SCOPED_ACTIONS: Array[String] = [
	"take_action", "pass", "discard_card", "play_card", "roll_card_country",
	"resolve_card_action",
	"purchase_upgrade", "refund_upgrade", "add_planned_action", "remove_planned_action",
	"resolve_planned_action", "aircraft_adjust", "aircraft_set", "aircraft_roll"
]
const CURRENT_TEAM_ACTIONS: Array[String] = [
	"take_action", "pass", "discard_card", "play_card", "add_planned_action",
	"remove_planned_action", "resolve_planned_action"
]

var is_running: bool = false
var current_port: int = DEFAULT_PORT
var peer: ENetMultiplayerPeer = null
var players: Dictionary = {}
var selected_teams: Dictionary = {}
var lobby_player_ids: Array[int] = []
var host_peer_id: int = 0
var is_game_starting: bool = false
var active_session_name: String = ""
var active_session_mode: String = SESSION_MODE_NONE
var active_save_data: Dictionary = {}
var save_history: Array = []
var local_team_name: String = ""
var chat_history: Array = []
var pending_client_session_action: String = CLIENT_SESSION_ACTION_NONE
var pending_client_session_name: String = ""
var pending_client_save_history: Array = []
var timer_accumulator: float = 0.0
var timer_autosave_accumulator: float = 0.0


func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)


func _process(delta: float) -> void:
	if not is_running or not multiplayer.is_server() or not has_active_session():
		timer_accumulator = 0.0
		return
	if not bool(active_save_data.get("TimerRunning", false)):
		timer_accumulator = 0.0
		return

	timer_accumulator += delta
	if timer_accumulator < 1.0:
		return

	var elapsed := int(floor(timer_accumulator))
	timer_accumulator -= float(elapsed)
	var tick_result := GameRules.apply_action(active_save_data, "tick_timer", {"elapsed": elapsed})
	if not bool(tick_result.get("ok", false)):
		return

	active_save_data = (tick_result.get("snapshot", active_save_data) as Dictionary).duplicate(true)
	timer_autosave_accumulator += float(elapsed)
	var timer_finished := not bool(active_save_data.get("TimerRunning", false))
	if timer_autosave_accumulator >= TIMER_AUTOSAVE_SECONDS or timer_finished:
		timer_autosave_accumulator = 0.0
		var save_result := SaveFunctionality.append_snapshot(active_session_name, save_history, active_save_data)
		if _apply_save_result(save_result, "", false, false):
			_broadcast_session_state()
			return

	_emit_session_state_locally()
	receive_session_state.rpc(get_session_info(), get_active_save_data())


func start_server(port: int = DEFAULT_PORT) -> bool:
	if is_running:
		_emit_status()
		players_changed.emit(players)
		_emit_lobby_state_locally()
		return true

	_close_peer()

	peer = ENetMultiplayerPeer.new()
	var error: Error = peer.create_server(port, MAX_PLAYERS)

	if error != OK:
		peer = null
		is_running = false
		server_error.emit("Server failed to start. Error code: %d" % error)
		_emit_status()
		players_changed.emit(players)
		return false

	multiplayer.multiplayer_peer = peer
	current_port = port
	is_running = true
	players.clear()
	selected_teams.clear()
	lobby_player_ids.clear()
	local_team_name = ""
	chat_history.clear()
	host_peer_id = 0
	is_game_starting = false

	_emit_status()
	players_changed.emit(players)
	_emit_lobby_state_locally()
	_emit_session_state_locally()
	return true


func stop_server() -> void:
	if not is_running:
		_emit_status()
		players_changed.emit(players)
		return

	_close_peer()
	players.clear()
	selected_teams.clear()
	lobby_player_ids.clear()
	local_team_name = ""
	chat_history.clear()
	host_peer_id = 0
	is_game_starting = false
	is_running = false

	_emit_status()
	players_changed.emit(players)
	_emit_lobby_state_locally()


func create_new_game_session(raw_name: String) -> bool:
	return _apply_save_result(SaveFunctionality.create_new_game(raw_name), SESSION_MODE_NEW, true, true)


func load_game_session(raw_name: String) -> bool:
	return _apply_save_result(SaveFunctionality.load_game(raw_name), SESSION_MODE_LOAD, true, true)


func append_save_snapshot(snapshot: Dictionary) -> bool:
	if not has_active_session():
		server_error.emit("No active game session to save.")
		return false

	return _apply_save_result(SaveFunctionality.append_snapshot(active_session_name, save_history, snapshot))


func save_snapshot(snapshot: Dictionary, success_message: String = "Game saved.") -> bool:
	if not has_active_session():
		server_error.emit("No active game session to save.")
		session_request_completed.emit(false, "No active game session to save.")
		return false

	var save_result := SaveFunctionality.append_snapshot(active_session_name, save_history, snapshot)
	if not _apply_save_result(save_result, "", false, false):
		session_request_completed.emit(false, str(save_result.get("error", "Save operation failed.")))
		return false

	_broadcast_session_state()
	session_request_completed.emit(true, success_message)
	return true


func perform_game_action(action_name: String, args: Dictionary = {}) -> bool:
	var result := _apply_game_action(action_name, args)
	return bool(result.get("ok", false))


func request_game_action_locally(action_name: String, args: Dictionary = {}) -> Dictionary:
	return _apply_game_action(action_name, args)


func save_white_turn_data(turn_day: int, turn_time: int, current_team: String) -> bool:
	if not has_active_session():
		server_error.emit("No active game session to save.")
		return false

	return _apply_save_result(SaveFunctionality.white_add_data(active_session_name, save_history, turn_day, turn_time, current_team))


func save_red_blue_points(team: int, ip: int, mp: int, pp: int) -> bool:
	if not has_active_session():
		server_error.emit("No active game session to save.")
		return false

	return _apply_save_result(SaveFunctionality.rb_add_data(active_session_name, save_history, team, ip, mp, pp))


func save_political_track_data(country_name: String, track_place: int) -> bool:
	if not has_active_session():
		server_error.emit("No active game session to save.")
		return false

	return _apply_save_result(SaveFunctionality.political_track_data(active_session_name, save_history, country_name, track_place))


func save_card_state(
	blue_card_river: String,
	blue_card_deck: String,
	blue_card_discard: String,
	red_card_deck: String,
	red_card_river: String,
	red_card_discard: String
) -> bool:
	if not has_active_session():
		server_error.emit("No active game session to save.")
		return false

	return _apply_save_result(SaveFunctionality.add_river(
		active_session_name,
		save_history,
		blue_card_river,
		blue_card_deck,
		blue_card_discard,
		red_card_deck,
		red_card_river,
		red_card_discard
	))


func get_saved_games() -> Array:
	return SaveFunctionality.get_files()


func refresh_saved_games() -> void:
	save_list_changed.emit(get_saved_games())


func set_pending_client_session_action(action: String) -> void:
	if action == CLIENT_SESSION_ACTION_NEW or action == CLIENT_SESSION_ACTION_LOAD:
		pending_client_session_action = action
	else:
		pending_client_session_action = CLIENT_SESSION_ACTION_NONE


func set_pending_client_session(game_name: String, history: Array) -> void:
	pending_client_session_name = SaveFunctionality.sanitize_game_name(game_name)
	pending_client_save_history = history.duplicate(true)


func clear_pending_client_session_action() -> void:
	pending_client_session_action = CLIENT_SESSION_ACTION_NONE
	pending_client_session_name = ""
	pending_client_save_history.clear()


func reset_client_connection_state() -> void:
	if is_running and multiplayer.is_server():
		return
	active_session_name = ""
	active_session_mode = SESSION_MODE_NONE
	active_save_data.clear()
	save_history.clear()
	players.clear()
	selected_teams.clear()
	lobby_player_ids.clear()
	local_team_name = ""
	chat_history.clear()
	host_peer_id = 0
	is_game_starting = false
	timer_accumulator = 0.0
	timer_autosave_accumulator = 0.0
	clear_pending_client_session_action()
	players_changed.emit(players)
	teams_changed.emit(selected_teams)
	lobby_changed.emit(host_peer_id, [], selected_teams, is_game_starting)
	session_changed.emit(get_session_info(), {})
	save_list_changed.emit([])


func has_active_session() -> bool:
	return not active_session_name.is_empty()


func get_session_info() -> Dictionary:
	return {
		"name": active_session_name,
		"mode": active_session_mode,
		"save_root": ProjectSettings.globalize_path(SaveFunctionality.SAVE_ROOT),
		"save_file": SaveFunctionality.get_session_save_path(active_session_name) if has_active_session() else ""
	}


func get_active_save_data() -> Dictionary:
	return active_save_data.duplicate(true)


func get_chat_history() -> Array:
	return chat_history.duplicate(true)


func get_local_team() -> String:
	if not local_team_name.is_empty():
		return local_team_name

	return get_team_for_peer(multiplayer.get_unique_id())


func set_local_team(team_name: String) -> void:
	if team_name.is_empty():
		local_team_name = ""
		return
	if not TEAM_NAMES.has(team_name):
		return

	local_team_name = team_name
	var peer_id := multiplayer.get_unique_id()
	if peer_id != 0:
		selected_teams[str(peer_id)] = team_name


func get_session_status_text() -> String:
	if not has_active_session():
		return "No game session selected."

	return "%s: %s" % [active_session_mode, active_session_name]


func get_status_text() -> String:
	if is_running:
		return "SERVER ONLINE - Port %d" % current_port
	return "OFFLINE"


func get_connection_summary() -> String:
	if not is_running:
		return "Server offline."

	if not has_active_session():
		return "Server online. Waiting for a game session."

	if players.is_empty():
		return "%s online. Waiting for players..." % active_session_name

	if players.size() == 1:
		return "%s online. 1 player connected." % active_session_name

	return "%s online. %d players connected." % [active_session_name, players.size()]


func get_players_text() -> String:
	if players.is_empty():
		return "Waiting for players..."

	var lines: Array[String] = []
	for player_id in players.keys():
		lines.append("Player ID %s connected" % str(player_id))
	return "\n".join(lines)


func get_lan_ip_share_text() -> String:
	var addresses := get_lan_ip_addresses()
	if addresses.is_empty():
		return "No local IPv4 found"

	if addresses.size() == 1:
		return addresses[0]

	var backup_addresses := addresses.duplicate()
	backup_addresses.remove_at(0)
	return "%s  |  Also try: %s" % [addresses[0], ", ".join(backup_addresses)]


func get_lan_ip_addresses() -> Array[String]:
	var addresses: Array[String] = []
	for address in IP.get_local_addresses():
		if not _is_shareable_ipv4(address):
			continue
		if not addresses.has(address):
			addresses.append(address)

	addresses.sort_custom(_compare_lan_ip_priority)
	return addresses


func _on_peer_connected(peer_id: int) -> void:
	if not is_running:
		return

	players[peer_id] = {
		"id": peer_id
	}
	if not lobby_player_ids.has(peer_id):
		lobby_player_ids.append(peer_id)
	if host_peer_id == 0:
		host_peer_id = peer_id

	players_changed.emit(players)
	call_deferred("_send_session_state", peer_id)
	call_deferred("_send_chat_history", peer_id)
	call_deferred("_broadcast_lobby_state")


func _on_peer_disconnected(peer_id: int) -> void:
	if players.has(peer_id):
		players.erase(peer_id)

	if lobby_player_ids.has(peer_id):
		lobby_player_ids.erase(peer_id)
	if host_peer_id == peer_id:
		host_peer_id = lobby_player_ids[0] if not lobby_player_ids.is_empty() else 0

	_release_team_for_peer(peer_id)
	players_changed.emit(players)
	call_deferred("_broadcast_lobby_after_disconnect")


@rpc("any_peer", "call_remote", "reliable")
func request_save_list() -> void:
	if not multiplayer.is_server():
		return

	var requester_id := _get_requester_id()
	receive_save_list.rpc_id(requester_id, get_saved_games())


@rpc("any_peer", "call_remote", "reliable")
func request_create_game_session(raw_name: String) -> void:
	if not multiplayer.is_server():
		return

	var requester_id := _get_requester_id()
	if not _can_manage_session(requester_id):
		receive_session_request_result.rpc_id(requester_id, false, "Only White can replace the active campaign.")
		return
	var save_result := SaveFunctionality.create_new_game(raw_name)
	if _apply_save_result(save_result, SESSION_MODE_NEW, false, true):
		_broadcast_session_state()
		_send_session_success(requester_id, "New game created.")
	else:
		receive_session_request_result.rpc_id(requester_id, false, str(save_result.get("error", "Could not create game.")))


@rpc("any_peer", "call_remote", "reliable")
func request_load_game_session(raw_name: String) -> void:
	if not multiplayer.is_server():
		return

	var requester_id := _get_requester_id()
	if not _can_manage_session(requester_id):
		receive_session_request_result.rpc_id(requester_id, false, "Only White can load a different campaign.")
		return
	var save_result := SaveFunctionality.load_game(raw_name)
	if _apply_save_result(save_result, SESSION_MODE_LOAD, false, true):
		_broadcast_session_state()
		_send_session_success(requester_id, "Save loaded.")
	else:
		receive_session_request_result.rpc_id(requester_id, false, str(save_result.get("error", "Could not load save.")))


@rpc("any_peer", "call_remote", "reliable")
func request_save_snapshot(snapshot: Dictionary, success_message: String = "Game saved.") -> void:
	if not multiplayer.is_server():
		return

	var requester_id := _get_requester_id()
	if get_team_for_peer(requester_id) != "White":
		receive_session_request_result.rpc_id(requester_id, false, "Only White can save the campaign.")
		return
	if not has_active_session():
		receive_session_request_result.rpc_id(requester_id, false, "Server has no active game session.")
		return

	var save_result := SaveFunctionality.append_snapshot(active_session_name, save_history, snapshot)
	if _apply_save_result(save_result, "", false, false):
		_broadcast_session_state()
		receive_session_request_result.rpc_id(requester_id, true, success_message)
	else:
		receive_session_request_result.rpc_id(requester_id, false, str(save_result.get("error", "Save operation failed.")))


@rpc("any_peer", "call_remote", "reliable")
func request_game_action(action_name: String, args: Dictionary = {}) -> void:
	if not multiplayer.is_server():
		return

	var requester_id := _get_requester_id()
	var authorization := _authorize_game_action(requester_id, action_name, args)
	if not bool(authorization.get("ok", false)):
		receive_session_request_result.rpc_id(requester_id, false, str(authorization.get("message", "Action denied.")))
		return
	var safe_args := (authorization.get("args", args) as Dictionary).duplicate(true)
	var result := _apply_game_action(action_name, safe_args)
	receive_session_request_result.rpc_id(requester_id, bool(result.get("ok", false)), str(result.get("message", "")))


@rpc("any_peer", "call_remote", "reliable")
func request_team_selection(team_name: String) -> void:
	if not multiplayer.is_server():
		return

	var requester_id := _get_requester_id()

	if not has_active_session():
		_send_team_rejection(requester_id, team_name, "Server has no active game session.")
		return

	if not TEAM_NAMES.has(team_name):
		_send_team_rejection(requester_id, team_name, "Unknown team.")
		return

	if is_team_taken_by_other(team_name, requester_id):
		_send_team_rejection(requester_id, team_name, "%s team is already taken." % team_name)
		return

	_release_team_for_peer(requester_id)
	selected_teams[str(requester_id)] = team_name
	receive_team_selection_confirmed.rpc_id(requester_id, team_name)
	_broadcast_lobby_state()
	_send_chat_history(requester_id)


@rpc("any_peer", "call_remote", "reliable")
func request_game_start() -> void:
	if not multiplayer.is_server():
		return

	var requester_id := _get_requester_id()

	if not has_active_session():
		_send_game_start_rejection(requester_id, "Server has no active game session.")
		return

	is_game_starting = true
	_broadcast_lobby_state()
	_broadcast_game_started()


func send_chat_message(channel: String, message: String) -> void:
	if multiplayer.multiplayer_peer == null:
		return

	if multiplayer.is_server():
		_handle_chat_message(multiplayer.get_unique_id(), channel, message)
	else:
		request_chat_message.rpc_id(1, channel, message)


@rpc("any_peer", "call_remote", "reliable")
func request_chat_message(channel: String, message: String) -> void:
	if not multiplayer.is_server():
		return

	_handle_chat_message(_get_requester_id(), channel, message)


@rpc("authority", "call_remote", "reliable")
func receive_lobby_state(new_host_peer_id: int, new_lobby_player_ids: Array, team_state: Dictionary, new_is_game_starting: bool) -> void:
	host_peer_id = new_host_peer_id
	lobby_player_ids.clear()
	for player_id in new_lobby_player_ids:
		lobby_player_ids.append(int(player_id))

	players.clear()
	for player_id in lobby_player_ids:
		players[player_id] = {
			"id": player_id
		}

	selected_teams = team_state.duplicate()
	is_game_starting = new_is_game_starting
	local_team_name = str(selected_teams.get(str(multiplayer.get_unique_id()), local_team_name))

	players_changed.emit(players)
	teams_changed.emit(selected_teams)
	lobby_changed.emit(host_peer_id, get_connected_player_ids(), selected_teams, is_game_starting)


@rpc("authority", "call_remote", "reliable")
func receive_session_state(session_info: Dictionary, save_data: Dictionary) -> void:
	active_session_name = str(session_info.get("name", ""))
	active_session_mode = str(session_info.get("mode", SESSION_MODE_NONE))
	active_save_data = save_data.duplicate(true)
	session_changed.emit(get_session_info(), get_active_save_data())


@rpc("authority", "call_remote", "reliable")
func receive_game_started(session_info: Dictionary, save_data: Dictionary) -> void:
	receive_session_state(session_info, save_data)
	game_started.emit(get_session_info(), get_active_save_data())


@rpc("authority", "call_remote", "reliable")
func receive_save_list(saved_games: Array) -> void:
	save_list_changed.emit(saved_games)


@rpc("authority", "call_remote", "reliable")
func receive_session_request_result(success: bool, message: String) -> void:
	session_request_completed.emit(success, message)


@rpc("authority", "call_remote", "reliable")
func receive_team_selection_confirmed(team_name: String) -> void:
	local_team_name = team_name
	team_selection_confirmed.emit(team_name)


@rpc("authority", "call_remote", "reliable")
func receive_team_rejection(team_name: String, message: String) -> void:
	team_selection_rejected.emit(team_name, message)


@rpc("authority", "call_remote", "reliable")
func receive_game_start_rejection(message: String) -> void:
	game_start_rejected.emit(message)


@rpc("authority", "call_remote", "reliable")
func receive_chat_message(message_data: Dictionary) -> void:
	_receive_chat_message_locally(message_data)


@rpc("authority", "call_remote", "reliable")
func receive_chat_history(history: Array) -> void:
	chat_history.clear()
	for raw_entry in history:
		if raw_entry is Dictionary:
			chat_history.append((raw_entry as Dictionary).duplicate(true))
	chat_message_received.emit({})


func is_team_taken(team_name: String) -> bool:
	return selected_teams.values().has(team_name)


func is_team_taken_by_other(team_name: String, peer_id: int) -> bool:
	for selected_peer_id in selected_teams.keys():
		if int(selected_peer_id) == peer_id:
			continue
		if str(selected_teams[selected_peer_id]) == team_name:
			return true
	return false


func get_connected_player_ids() -> Array[int]:
	var ids: Array[int] = []
	for player_id in lobby_player_ids:
		ids.append(player_id)
	return ids


func get_team_for_peer(peer_id: int) -> String:
	return str(selected_teams.get(str(peer_id), ""))


func is_host_peer(peer_id: int) -> bool:
	return peer_id != 0 and peer_id == host_peer_id


func has_required_players_ready() -> bool:
	return not selected_teams.is_empty()


func _release_team_for_peer(peer_id: int) -> void:
	selected_teams.erase(str(peer_id))


func _emit_lobby_state_locally() -> void:
	teams_changed.emit(selected_teams)
	lobby_changed.emit(host_peer_id, get_connected_player_ids(), selected_teams, is_game_starting)


func _broadcast_lobby_state() -> void:
	_emit_lobby_state_locally()
	if multiplayer.multiplayer_peer == null or not multiplayer.is_server():
		return
	for peer_id in get_connected_player_ids():
		receive_lobby_state.rpc_id(peer_id, host_peer_id, get_connected_player_ids(), selected_teams, is_game_starting)


func _broadcast_lobby_after_disconnect() -> void:
	await get_tree().create_timer(0.1).timeout
	_broadcast_lobby_state()


func _get_requester_id() -> int:
	var requester_id := multiplayer.get_remote_sender_id()
	if requester_id == 0:
		requester_id = multiplayer.get_unique_id()
	return requester_id


func _apply_save_result(
	save_result: Dictionary,
	session_mode: String = "",
	emit_session: bool = true,
	refresh_save_list: bool = false
) -> bool:
	if not bool(save_result.get("ok", false)):
		server_error.emit(str(save_result.get("error", "Save operation failed.")))
		return false

	active_session_name = str(save_result.get("game_name", active_session_name))
	if not session_mode.is_empty():
		active_session_mode = session_mode

	save_history = save_result.get("history", []).duplicate(true)
	active_save_data = (save_result.get("latest", SaveFunctionality.make_default_save_data()) as Dictionary).duplicate(true)

	if emit_session:
		_emit_session_state_locally()
	if refresh_save_list:
		save_list_changed.emit(get_saved_games())
	return true


func _apply_game_action(action_name: String, args: Dictionary = {}) -> Dictionary:
	if not has_active_session():
		var message := "Server has no active game session."
		server_error.emit(message)
		session_request_completed.emit(false, message)
		return {
			"ok": false,
			"message": message
		}

	var action_result := GameRules.apply_action(active_save_data, action_name, args)
	if not bool(action_result.get("ok", false)):
		var failure_message := str(action_result.get("message", "Game action failed."))
		session_request_completed.emit(false, failure_message)
		return {
			"ok": false,
			"message": failure_message
		}

	var next_snapshot := action_result.get("snapshot", active_save_data) as Dictionary
	var save_result := SaveFunctionality.append_snapshot(active_session_name, save_history, next_snapshot)
	if not _apply_save_result(save_result, "", false, false):
		var save_message := str(save_result.get("error", "Save operation failed."))
		session_request_completed.emit(false, save_message)
		return {
			"ok": false,
			"message": save_message
		}

	_broadcast_session_state()
	var success_message := str(action_result.get("message", "Game updated."))
	session_request_completed.emit(true, success_message)
	return {
		"ok": true,
		"message": success_message
	}


func _authorize_game_action(requester_id: int, action_name: String, args: Dictionary) -> Dictionary:
	var actor_team := get_team_for_peer(requester_id)
	if actor_team.is_empty():
		return {"ok": false, "message": "Choose a team before using game controls."}

	if WHITE_ONLY_ACTIONS.has(action_name):
		if actor_team != "White":
			return {"ok": false, "message": "Only White can use this control."}
		return {"ok": true, "args": args}

	if action_name == "roll_dice" or action_name == "add_log":
		return {"ok": true, "args": args}
	if action_name == "red_resource":
		if actor_team != "Red":
			return {"ok": false, "message": "Only Red can change Red resources."}
		return {"ok": true, "args": args}

	if not TEAM_SCOPED_ACTIONS.has(action_name):
		return {"ok": false, "message": "This action is not available to a player."}
	if actor_team == "White":
		return {"ok": false, "message": "White cannot submit a combat-team action."}
	if CURRENT_TEAM_ACTIONS.has(action_name) and str(active_save_data.get("ChangeTeam", "")) != actor_team:
		return {"ok": false, "message": "It is not %s's move." % actor_team}

	var safe_args := args.duplicate(true)
	var requested_team := str(safe_args.get("team", actor_team))
	if action_name == "purchase_upgrade" or action_name == "refund_upgrade":
		var valid_upgrade_teams: Array[String] = [actor_team]
		if actor_team == "Red":
			valid_upgrade_teams.append("RedExtra")
		if not valid_upgrade_teams.has(requested_team):
			return {"ok": false, "message": "You can only change your own team's upgrades."}
	else:
		safe_args["team"] = actor_team

	if action_name == "remove_planned_action" or action_name == "resolve_planned_action":
		var planned_value = active_save_data.get("PlannedActions", [])
		var planned: Array = planned_value if planned_value is Array else []
		var action_index := int(safe_args.get("index", -1))
		if action_index < 0 or action_index >= planned.size():
			return {"ok": false, "message": "Choose one of your planned actions first."}
		var planned_action: Dictionary = planned[action_index] if planned[action_index] is Dictionary else {}
		if str(planned_action.get("team", "")) != actor_team:
			return {"ok": false, "message": "You can only change your own planned actions."}
		if action_name == "resolve_planned_action" and int(planned_action.get("wait_time", 0)) > 0:
			return {"ok": false, "message": "That action is not ready to resolve yet."}

	return {"ok": true, "args": safe_args}


func _can_manage_session(requester_id: int) -> bool:
	var requester_team := get_team_for_peer(requester_id)
	return requester_team.is_empty() or requester_team == "White"


func _emit_session_state_locally() -> void:
	session_changed.emit(get_session_info(), get_active_save_data())


func _send_session_state(peer_id: int) -> void:
	if peer_id == 0 or not has_active_session():
		return

	receive_session_state.rpc_id(peer_id, get_session_info(), get_active_save_data())


func _send_chat_history(peer_id: int) -> void:
	if peer_id == 0:
		return

	var peer_team := get_team_for_peer(peer_id)
	receive_chat_history.rpc_id(peer_id, _chat_history_for_team(peer_team))


func _broadcast_session_state() -> void:
	_emit_session_state_locally()
	if multiplayer.multiplayer_peer != null and multiplayer.is_server():
		receive_session_state.rpc(get_session_info(), get_active_save_data())


func _broadcast_game_started() -> void:
	var session_info := get_session_info()
	var save_data := get_active_save_data()
	game_started.emit(session_info, save_data)
	receive_game_started.rpc(session_info, save_data)


func _handle_chat_message(sender_peer_id: int, requested_channel: String, raw_message: String) -> void:
	var message := raw_message.strip_edges()
	if message.is_empty():
		return
	if message.length() > MAX_CHAT_MESSAGE_LENGTH:
		message = message.substr(0, MAX_CHAT_MESSAGE_LENGTH)

	var sender_team := get_team_for_peer(sender_peer_id)
	var channel := _allowed_chat_channel(sender_team, requested_channel)
	var message_data := {
		"from_peer_id": sender_peer_id,
		"sender_team": sender_team,
		"sender_name": _chat_sender_name(sender_peer_id, sender_team),
		"channel": channel,
		"message": message,
		"time": Time.get_datetime_string_from_system(false, true)
	}

	_receive_chat_message_locally(message_data)
	if multiplayer.multiplayer_peer != null and multiplayer.is_server():
		for peer_id in get_connected_player_ids():
			if _peer_can_receive_chat(peer_id, channel):
				receive_chat_message.rpc_id(peer_id, message_data)


func _receive_chat_message_locally(message_data: Dictionary) -> void:
	if message_data.is_empty():
		chat_message_received.emit(message_data)
		return

	chat_history.append(message_data.duplicate(true))
	while chat_history.size() > MAX_CHAT_HISTORY:
		chat_history.pop_front()
	chat_message_received.emit(message_data)


func _allowed_chat_channel(sender_team: String, requested_channel: String) -> String:
	var channel := requested_channel if CHAT_CHANNELS.has(requested_channel) else CHAT_CHANNEL_ANNOUNCEMENT

	if sender_team == "White":
		return channel
	if sender_team == "Red":
		return CHAT_CHANNEL_RED
	if sender_team == "Blue":
		return CHAT_CHANNEL_BLUE

	return CHAT_CHANNEL_ANNOUNCEMENT


func _peer_can_receive_chat(peer_id: int, channel: String) -> bool:
	if channel == CHAT_CHANNEL_ANNOUNCEMENT:
		return true
	var peer_team := get_team_for_peer(peer_id)
	return peer_team == "White" or peer_team == channel


func _chat_history_for_team(peer_team: String) -> Array:
	var visible_history: Array = []
	for raw_entry in chat_history:
		if not raw_entry is Dictionary:
			continue
		var entry := raw_entry as Dictionary
		var channel := str(entry.get("channel", CHAT_CHANNEL_ANNOUNCEMENT))
		if channel == CHAT_CHANNEL_ANNOUNCEMENT or peer_team == "White" or channel == peer_team:
			visible_history.append(entry.duplicate(true))
	return visible_history


func _chat_sender_name(sender_peer_id: int, sender_team: String) -> String:
	if not sender_team.is_empty():
		return "%s Team" % sender_team
	if sender_peer_id == 1 and multiplayer.is_server():
		return "Server"
	return "Player %d" % sender_peer_id


func _send_team_rejection(peer_id: int, team_name: String, message: String) -> void:
	receive_team_rejection.rpc_id(peer_id, team_name, message)


func _send_game_start_rejection(peer_id: int, message: String) -> void:
	receive_game_start_rejection.rpc_id(peer_id, message)


func _send_session_success(peer_id: int, message: String) -> void:
	receive_session_state.rpc_id(peer_id, get_session_info(), get_active_save_data())
	receive_session_request_result.rpc_id(peer_id, true, message)


func _emit_status() -> void:
	status_changed.emit(get_status_text())


func _close_peer() -> void:
	multiplayer.multiplayer_peer = null
	if peer != null:
		peer.close()
		peer = null


func _is_shareable_ipv4(address: String) -> bool:
	if address.contains(":"):
		return false
	if address.begins_with("127."):
		return false
	if address.begins_with("169.254."):
		return false
	if address == "0.0.0.0":
		return false

	var parts := address.split(".")
	if parts.size() != 4:
		return false

	for part in parts:
		if not part.is_valid_int():
			return false
		var value := int(part)
		if value < 0 or value > 255:
			return false

	return true


func _compare_lan_ip_priority(left: String, right: String) -> bool:
	return _lan_ip_priority(left) < _lan_ip_priority(right)


func _lan_ip_priority(address: String) -> int:
	if address.begins_with("10."):
		return 0
	if address.begins_with("192.168."):
		return 1
	if _is_private_172_address(address):
		return 2
	return 3


func _is_private_172_address(address: String) -> bool:
	var parts := address.split(".")
	if parts.size() < 2:
		return false
	if not parts[1].is_valid_int():
		return false

	var second_part := int(parts[1])
	return address.begins_with("172.") and second_part >= 16 and second_part <= 31
