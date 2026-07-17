extends Control

const SAVE_SELECT_SCENE: String = "res://UI/MainScenes/SaveSelect.tscn"
const CONNECT_SCENE: String = "res://UI/MainScenes/Connect.tscn"

@export var new_game_button: BaseButton
@export var load_game_button: BaseButton
@export var back_button: BaseButton

var game_server
var navigating_away: bool = false


func _ready() -> void:
	_resolve_ui_references()
	game_server = get_node_or_null("/root/GameServer")
	if game_server == null:
		push_error("ModeSelect scene could not find /root/GameServer.")
		return
	if not _is_connected_to_server():
		game_server.clear_pending_client_session_action()
		call_deferred("_open_connect_scene")
		return
	if not multiplayer.server_disconnected.is_connected(_on_server_disconnected):
		multiplayer.server_disconnected.connect(_on_server_disconnected)

	if new_game_button == null:
		push_error("ModeSelect scene is missing NewGameButton.")
	else:
		new_game_button.pressed.connect(_on_new_game_pressed)

	if load_game_button == null:
		push_error("ModeSelect scene is missing LoadGameButton.")
	else:
		load_game_button.pressed.connect(_on_load_game_pressed)

	if back_button == null:
		push_error("ModeSelect scene is missing BackButton.")
	else:
		back_button.pressed.connect(_on_back_pressed)


func _resolve_ui_references() -> void:
	if new_game_button == null:
		new_game_button = get_node_or_null("CanvasLayer/VBoxContainer/CenterContainer2/ButtonRow/NewGameButton") as BaseButton
	if load_game_button == null:
		load_game_button = get_node_or_null("CanvasLayer/VBoxContainer/CenterContainer2/ButtonRow/LoadGameButton") as BaseButton
	if back_button == null:
		back_button = get_node_or_null("CanvasLayer/VBoxContainer/TopSpacer/BackButton") as BaseButton


func _on_new_game_pressed() -> void:
	if game_server != null:
		game_server.set_pending_client_session_action(game_server.CLIENT_SESSION_ACTION_NEW)
	get_tree().change_scene_to_file(SAVE_SELECT_SCENE)


func _on_load_game_pressed() -> void:
	if game_server != null:
		game_server.set_pending_client_session_action(game_server.CLIENT_SESSION_ACTION_LOAD)
	get_tree().change_scene_to_file(SAVE_SELECT_SCENE)


func _on_back_pressed() -> void:
	navigating_away = true
	if game_server != null:
		game_server.clear_pending_client_session_action()
	var active_peer: MultiplayerPeer = multiplayer.multiplayer_peer
	if active_peer != null:
		active_peer.close()
	multiplayer.multiplayer_peer = null
	game_server.reset_client_connection_state()
	get_tree().change_scene_to_file(CONNECT_SCENE)


func _on_server_disconnected() -> void:
	if navigating_away:
		return
	if game_server != null:
		game_server.clear_pending_client_session_action()
	call_deferred("_open_connect_scene")


func _open_connect_scene() -> void:
	if not is_inside_tree() or navigating_away:
		return
	navigating_away = true
	get_tree().change_scene_to_file(CONNECT_SCENE)


func _is_connected_to_server() -> bool:
	var active_peer: MultiplayerPeer = multiplayer.multiplayer_peer
	return active_peer != null and active_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED
