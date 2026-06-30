extends Node

signal status_changed(status_text: String)
signal players_changed(players: Dictionary)
signal game_state_changed(game_state: Dictionary)
signal action_log_changed(action_log: Array)
signal chat_changed(chat_history: Array)
signal server_error(message: String)

const DEFAULT_PORT: int = 9999
const MAX_PLAYERS: int = 10
const SERVER_ID: int = 1
const TEAM_NAMES: Array[String] = ["White", "Red", "Blue", "Observer"]
const POINT_POOLS: Array[String] = ["MP", "PP", "IP"]
const SAVE_DIR: String = "user://saves"

var is_running: bool = false
var is_connected: bool = false
var is_host: bool = false
var current_port: int = DEFAULT_PORT
var local_player_name: String = "Player"
var peer: ENetMultiplayerPeer = null

var players: Dictionary = {}
var game_state: Dictionary = {}
var action_log: Array = []
var chat_history: Array = []


func _ready() -> void:
	_reset_game_state()
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)


func start_server(player_name: String = "Host", port: int = DEFAULT_PORT) -> bool:
	if is_running:
		_emit_status()
		return true

	_disconnect_without_signals()

	peer = ENetMultiplayerPeer.new()
	var error: Error = peer.create_server(port, MAX_PLAYERS)

	if error != OK:
		peer = null
		is_running = false
		is_connected = false
		is_host = false
		_emit_error("Server failed to start. Error code: %d" % error)
		return false

	multiplayer.multiplayer_peer = peer
	current_port = port
	local_player_name = _clean_player_name(player_name)
	is_running = true
	is_connected = true
	is_host = true

	_reset_game_state()
	action_log.clear()
	chat_history.clear()
	_register_player_local(SERVER_ID, local_player_name, true)
	_add_log_local("SERVER", "%s started the server on port %d." % [local_player_name, current_port])
	_broadcast_everything()
	_emit_status()
	return true


func stop_server() -> void:
	if not is_running and not is_connected:
		_emit_status()
		return

	if is_host:
		_add_log_local("SERVER", "Server stopped.")

	_disconnect_without_signals()
	players.clear()
	chat_history.clear()
	is_running = false
	is_connected = false
	is_host = false
	_emit_all_state()


func connect_to_server(ip_address: String, player_name: String = "Player", port: int = DEFAULT_PORT) -> bool:
	var cleaned_ip: String = ip_address.strip_edges()
	if cleaned_ip.is_empty():
		_emit_error("Enter a server IP address first.")
		return false

	_disconnect_without_signals()

	peer = ENetMultiplayerPeer.new()
	var error: Error = peer.create_client(cleaned_ip, port)

	if error != OK:
		peer = null
		is_connected = false
		is_host = false
		_emit_error("Could not connect to %s:%d. Error code: %d" % [cleaned_ip, port, error])
		return false

	multiplayer.multiplayer_peer = peer
	current_port = port
	local_player_name = _clean_player_name(player_name)
	is_running = false
	is_connected = true
	is_host = false
	_emit_status("CONNECTING - %s:%d" % [cleaned_ip, current_port])
	return true


func disconnect_from_server() -> void:
	_disconnect_without_signals()
	players.clear()
	chat_history.clear()
	is_running = false
	is_connected = false
	is_host = false
	_emit_all_state()


func choose_team(team_name: String) -> void:
	if not TEAM_NAMES.has(team_name):
		_emit_error("Unknown team: %s" % team_name)
		return

	if not is_connected:
		_emit_error("Connect or start a server before choosing a team.")
		return

	if multiplayer.is_server():
		_set_player_team(SERVER_ID, team_name)
	else:
		request_team.rpc_id(SERVER_ID, team_name)


func start_new_game() -> void:
	if not _require_server("Only the host can start a new game."):
		return

	_reset_game_state()
	action_log.clear()
	chat_history.clear()
	_add_log_local("SERVER", "New game initialized.")
	_broadcast_everything()


func advance_turn() -> void:
	if not _require_server("Only the host can advance the turn."):
		return

	var team_order: Array[String] = ["White", "Red", "Blue"]
	var current_team: String = str(game_state.get("current_team", "White"))
	var current_index: int = team_order.find(current_team)
	if current_index == -1:
		current_index = 0

	current_index += 1
	if current_index >= team_order.size():
		current_index = 0
		game_state["move"] = int(game_state.get("move", 0)) + 1

		if int(game_state["move"]) > 3:
			game_state["move"] = 1
			game_state["day"] = int(game_state.get("day", 0)) + 1
			_advance_phase()

	game_state["current_team"] = team_order[current_index]
	_add_log_local("TURN", "Advanced to Day %d - %s - Move %d - %s Team." % [
		int(game_state.get("day", 0)),
		str(game_state.get("phase", "Prep")),
		int(game_state.get("move", 0)),
		str(game_state.get("current_team", "White"))
	])
	_broadcast_everything()


func add_points(team_name: String, pool_name: String, amount: int, reason: String = "Manual adjustment") -> void:
	if not is_connected:
		_emit_error("Server is not active.")
		return

	if multiplayer.is_server():
		_add_points_local(team_name, pool_name, amount, reason)
	else:
		request_add_points.rpc_id(SERVER_ID, team_name, pool_name, amount, reason)


func send_chat_message(message: String) -> void:
	var cleaned_message: String = _clean_chat_message(message)
	if cleaned_message.is_empty():
		return

	if not is_connected:
		_emit_error("Connect or start a server before sending chat.")
		return

	if multiplayer.is_server():
		_add_chat_message_local(SERVER_ID, cleaned_message)
	else:
		request_chat_message.rpc_id(SERVER_ID, cleaned_message)


func save_game(file_name: String = "autosave") -> bool:
	if not _require_server("Only the host can save the game."):
		return false

	var save_path: String = _get_save_path(file_name)
	var save_root: Dictionary = {
		"players": players,
		"game_state": game_state,
		"action_log": action_log,
		"chat_history": chat_history
	}

	_ensure_save_dir()
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		_emit_error("Could not open save file: %s" % save_path)
		return false

	file.store_string(JSON.stringify(save_root, "\t"))
	_add_log_local("SAVE", "Game saved to %s." % save_path)
	_broadcast_everything()
	return true


func load_game(file_name: String = "autosave") -> bool:
	if not _require_server("Only the host can load the game."):
		return false

	var save_path: String = _get_save_path(file_name)
	if not FileAccess.file_exists(save_path):
		_emit_error("Save file not found: %s" % save_path)
		return false

	var file := FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		_emit_error("Could not read save file: %s" % save_path)
		return false

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		_emit_error("Save file is not valid JSON.")
		return false

	players = (parsed as Dictionary).get("players", {}).duplicate(true)
	game_state = (parsed as Dictionary).get("game_state", _create_default_game_state()).duplicate(true)
	action_log = (parsed as Dictionary).get("action_log", []).duplicate(true)
	chat_history = (parsed as Dictionary).get("chat_history", []).duplicate(true)
	_add_log_local("LOAD", "Game loaded from %s." % save_path)
	_broadcast_everything()
	return true


func get_status_text() -> String:
	if is_host and is_running:
		return "HOST ONLINE - Port %d" % current_port
	if is_connected:
		return "CLIENT CONNECTED - Port %d" % current_port
	return "OFFLINE"


func get_players_text() -> String:
	if players.is_empty():
		return "No players connected yet."

	var lines: Array[String] = []
	for player_id in players.keys():
		var player: Dictionary = players[player_id]
		lines.append("%s | %s | ID %s" % [
			str(player.get("name", "Player")),
			str(player.get("team", "Observer")),
			str(player_id)
		])
	return "\n".join(lines)


func get_game_state_summary() -> String:
	return "Day %d | %s | Move %d | Current Team: %s" % [
		int(game_state.get("day", 0)),
		str(game_state.get("phase", "Prep")),
		int(game_state.get("move", 0)),
		str(game_state.get("current_team", "White"))
	]


func get_points_summary() -> String:
	var points: Dictionary = game_state.get("points", {})
	var red: Dictionary = points.get("Red", {})
	var blue: Dictionary = points.get("Blue", {})
	return "Red MP %d PP %d IP %d\nBlue MP %d PP %d IP %d" % [
		int(red.get("MP", 0)),
		int(red.get("PP", 0)),
		int(red.get("IP", 0)),
		int(blue.get("MP", 0)),
		int(blue.get("PP", 0)),
		int(blue.get("IP", 0))
	]


func get_chat_text() -> String:
	if chat_history.is_empty():
		return "No chat messages yet."

	var lines: Array[String] = []
	for entry in chat_history:
		lines.append("[%s] %s: %s" % [
			str(entry.get("team", "Observer")),
			str(entry.get("sender", "Player")),
			str(entry.get("message", ""))
		])
	return "\n".join(lines)


@rpc("any_peer", "reliable")
func request_join(player_name: String) -> void:
	if not multiplayer.is_server():
		return

	var sender_id: int = multiplayer.get_remote_sender_id()
	_register_player_local(sender_id, player_name, false)
	_add_log_local("SERVER", "%s joined the server." % _clean_player_name(player_name))
	_broadcast_everything()


@rpc("any_peer", "reliable")
func request_team(team_name: String) -> void:
	if not multiplayer.is_server():
		return

	var sender_id: int = multiplayer.get_remote_sender_id()
	_set_player_team(sender_id, team_name)


@rpc("any_peer", "reliable")
func request_add_points(team_name: String, pool_name: String, amount: int, reason: String) -> void:
	if not multiplayer.is_server():
		return

	_add_points_local(team_name, pool_name, amount, reason)


@rpc("any_peer", "reliable")
func request_chat_message(message: String) -> void:
	if not multiplayer.is_server():
		return

	var sender_id: int = multiplayer.get_remote_sender_id()
	_add_chat_message_local(sender_id, message)


@rpc("authority", "call_local", "reliable")
func sync_players(new_players: Dictionary) -> void:
	players = new_players.duplicate(true)
	players_changed.emit(players)


@rpc("authority", "call_local", "reliable")
func sync_game_state(new_game_state: Dictionary) -> void:
	game_state = new_game_state.duplicate(true)
	game_state_changed.emit(game_state)


@rpc("authority", "call_local", "reliable")
func sync_action_log(new_action_log: Array) -> void:
	action_log = new_action_log.duplicate(true)
	action_log_changed.emit(action_log)


@rpc("authority", "call_local", "reliable")
func sync_chat_history(new_chat_history: Array) -> void:
	chat_history = new_chat_history.duplicate(true)
	chat_changed.emit(chat_history)


func _on_peer_connected(peer_id: int) -> void:
	if multiplayer.is_server():
		_add_log_local("SERVER", "Peer %d connected." % peer_id)
		_broadcast_everything()


func _on_peer_disconnected(peer_id: int) -> void:
	if multiplayer.is_server():
		var player_name: String = "Peer %d" % peer_id
		if players.has(peer_id):
			player_name = str(players[peer_id].get("name", player_name))
			players.erase(peer_id)
		_add_log_local("SERVER", "%s disconnected." % player_name)
		_broadcast_everything()


func _on_connected_to_server() -> void:
	is_connected = true
	request_join.rpc_id(SERVER_ID, local_player_name)
	_emit_status()


func _on_connection_failed() -> void:
	_disconnect_without_signals()
	_emit_error("Connection failed.")
	_emit_all_state()


func _on_server_disconnected() -> void:
	_disconnect_without_signals()
	players.clear()
	_emit_error("Disconnected from server.")
	_emit_all_state()


func _register_player_local(player_id: int, player_name: String, host_player: bool) -> void:
	players[player_id] = {
		"id": player_id,
		"name": _clean_player_name(player_name),
		"team": "White" if host_player else "Observer",
		"is_host": host_player
	}
	players_changed.emit(players)


func _set_player_team(player_id: int, team_name: String) -> void:
	if not TEAM_NAMES.has(team_name):
		_emit_error("Unknown team: %s" % team_name)
		return

	if not players.has(player_id):
		_emit_error("Player %d is not registered yet." % player_id)
		return

	players[player_id]["team"] = team_name
	_add_log_local("SERVER", "%s joined %s Team." % [players[player_id]["name"], team_name])
	_broadcast_everything()


func _add_points_local(team_name: String, pool_name: String, amount: int, reason: String) -> void:
	if not ["Red", "Blue"].has(team_name):
		_emit_error("Only Red and Blue have point pools.")
		return

	if not POINT_POOLS.has(pool_name):
		_emit_error("Unknown point pool: %s" % pool_name)
		return

	var points: Dictionary = game_state["points"]
	var team_points: Dictionary = points[team_name]
	team_points[pool_name] = max(0, int(team_points.get(pool_name, 0)) + amount)
	points[team_name] = team_points
	game_state["points"] = points

	_add_log_local("POINTS", "%s %s changed by %+d. Reason: %s." % [team_name, pool_name, amount, reason])
	_broadcast_everything()


func _add_chat_message_local(sender_id: int, message: String) -> void:
	var cleaned_message: String = _clean_chat_message(message)
	if cleaned_message.is_empty():
		return

	var sender_name: String = "Player %d" % sender_id
	var sender_team: String = "Observer"
	if players.has(sender_id):
		sender_name = str(players[sender_id].get("name", sender_name))
		sender_team = str(players[sender_id].get("team", sender_team))

	var entry: Dictionary = {
		"index": chat_history.size() + 1,
		"sender_id": sender_id,
		"sender": sender_name,
		"team": sender_team,
		"message": cleaned_message,
		"day": int(game_state.get("day", 0)),
		"phase": str(game_state.get("phase", "Prep")),
		"move": int(game_state.get("move", 0))
	}
	chat_history.append(entry)
	_add_log_local("CHAT", "%s sent a chat message." % sender_name)
	_broadcast_everything()


func _add_log_local(category: String, message: String) -> void:
	var entry: Dictionary = {
		"index": action_log.size() + 1,
		"category": category,
		"message": message,
		"day": int(game_state.get("day", 0)),
		"phase": str(game_state.get("phase", "Prep")),
		"move": int(game_state.get("move", 0)),
		"team": str(game_state.get("current_team", "White"))
	}
	action_log.append(entry)
	action_log_changed.emit(action_log)


func _broadcast_everything() -> void:
	if multiplayer.is_server():
		sync_players.rpc(players)
		sync_game_state.rpc(game_state)
		sync_action_log.rpc(action_log)
		sync_chat_history.rpc(chat_history)
	_emit_all_state()


func _emit_all_state() -> void:
	_emit_status()
	players_changed.emit(players)
	game_state_changed.emit(game_state)
	action_log_changed.emit(action_log)
	chat_changed.emit(chat_history)


func _emit_status(forced_text: String = "") -> void:
	if forced_text.is_empty():
		status_changed.emit(get_status_text())
	else:
		status_changed.emit(forced_text)


func _emit_error(message: String) -> void:
	server_error.emit(message)
	print(message)


func _require_server(message: String) -> bool:
	if not multiplayer.is_server():
		_emit_error(message)
		return false
	return true


func _disconnect_without_signals() -> void:
	multiplayer.multiplayer_peer = null
	if peer != null:
		peer.close()
		peer = null


func _reset_game_state() -> void:
	game_state = _create_default_game_state()
	game_state_changed.emit(game_state)


func _create_default_game_state() -> Dictionary:
	return {
		"session_name": "Persian Incursion",
		"status": "lobby",
		"day": 0,
		"phase": "Prep",
		"move": 0,
		"current_team": "White",
		"points": {
			"Red": {"MP": 0, "PP": 0, "IP": 0},
			"Blue": {"MP": 0, "PP": 0, "IP": 0}
		},
		"political_tracks": _create_default_political_tracks(),
		"cards": {
			"Red": {"deck": [], "river": [], "discard": []},
			"Blue": {"deck": [], "river": [], "discard": []}
		},
		"orders": [],
		"targets": {},
		"combat": {
			"aircraft": {},
			"sams": {},
			"ballistic_missiles": {}
		}
	}


func _create_default_political_tracks() -> Dictionary:
	return {
		"Israel": {"position": 0, "status": "Neutral"},
		"PRC": {"position": 0, "status": "Neutral"},
		"Russia": {"position": 0, "status": "Neutral"},
		"Saudi": {"position": 0, "status": "Neutral"},
		"UN": {"position": 0, "status": "Neutral"},
		"Jordan": {"position": 0, "status": "Neutral"},
		"Turkey": {"position": 0, "status": "Neutral"},
		"US_Iraq": {"position": 0, "status": "Neutral"},
		"Iran": {"position": 0, "status": "Neutral"}
	}


func _advance_phase() -> void:
	var phase_order: Array[String] = ["Prep", "Day", "Night"]
	var phase_index: int = phase_order.find(str(game_state.get("phase", "Prep")))
	if phase_index == -1:
		phase_index = 0

	phase_index += 1
	if phase_index >= phase_order.size():
		phase_index = 1

	game_state["phase"] = phase_order[phase_index]


func _clean_player_name(player_name: String) -> String:
	var cleaned: String = player_name.strip_edges()
	if cleaned.is_empty():
		return "Player"
	return cleaned.substr(0, 24)


func _clean_chat_message(message: String) -> String:
	var cleaned: String = message.strip_edges()
	if cleaned.length() > 300:
		cleaned = cleaned.substr(0, 300)
	return cleaned


func _ensure_save_dir() -> void:
	var root := DirAccess.open("user://")
	if root != null and not root.dir_exists("saves"):
		root.make_dir_recursive("saves")


func _get_save_path(file_name: String) -> String:
	var safe_name: String = file_name.strip_edges()
	if safe_name.is_empty():
		safe_name = "autosave"
	safe_name = safe_name.replace("\\", "_").replace("/", "_").replace(":", "_")
	if not safe_name.ends_with(".json"):
		safe_name += ".json"
	return "%s/%s" % [SAVE_DIR, safe_name]
