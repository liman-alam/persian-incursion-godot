extends Control

const PORT: int = 9000
const CONNECT_TIMEOUT: float = 6.0
const LOCALHOST_IP: String = "127.0.0.1"
const BEGINNING_SCENE: String = "res://UI/MainScenes/Beginning.tscn"
const MODE_SELECT_SCENE: String = "res://UI/MainScenes/ModeSelect.tscn"

@export var prompt_label: Label
@export var ip_input: LineEdit
@export var status_label: Label
@export var connect_button: BaseButton
@export var back_button: BaseButton
@export var localhost_button: BaseButton

var peer: ENetMultiplayerPeer = null
var connect_attempt_id: int = 0
var navigating_away: bool = false
var game_server


func _ready() -> void:
	_resolve_ui_references()
	game_server = get_node_or_null("/root/GameServer")
	if game_server == null:
		push_error("Connect scene could not find /root/GameServer.")
		if status_label != null:
			status_label.text = "Game server state is not available."
		return

	game_server.reset_client_connection_state()

	if ip_input == null or status_label == null or connect_button == null:
		push_error("Connect scene is missing one or more required UI nodes.")
		return

	if prompt_label != null:
		prompt_label.text = "Dedicated Server IP"
	status_label.text = ""
	connect_button.pressed.connect(_on_connect_pressed)
	if back_button != null:
		back_button.pressed.connect(_on_back_pressed)
	if localhost_button != null:
		localhost_button.pressed.connect(_on_localhost_pressed)

	multiplayer.connected_to_server.connect(_on_connected)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)


func _resolve_ui_references() -> void:
	if prompt_label == null:
		prompt_label = get_node_or_null("CanvasLayer/VBoxContainer/CenterContainer2/JoinPanel/PanelMargin/PanelVBox/PromptLabel") as Label
	if ip_input == null:
		ip_input = get_node_or_null("CanvasLayer/VBoxContainer/CenterContainer2/JoinPanel/PanelMargin/PanelVBox/IpInput") as LineEdit
	if status_label == null:
		status_label = get_node_or_null("CanvasLayer/VBoxContainer/CenterContainer2/JoinPanel/PanelMargin/PanelVBox/StatusLabel") as Label
	if connect_button == null:
		connect_button = get_node_or_null("CanvasLayer/VBoxContainer/CenterContainer2/JoinPanel/PanelMargin/PanelVBox/ButtonRow/ConnectButton") as BaseButton
	if back_button == null:
		back_button = get_node_or_null("CanvasLayer/VBoxContainer/CenterContainer2/JoinPanel/PanelMargin/PanelVBox/ButtonRow/BackButton") as BaseButton
	if localhost_button == null:
		localhost_button = get_node_or_null("CanvasLayer/VBoxContainer/CenterContainer2/JoinPanel/PanelMargin/PanelVBox/LocalhostButton") as BaseButton


func _on_connect_pressed() -> void:
	var ip := ip_input.text.strip_edges()
	if ip.is_empty():
		status_label.text = "Enter the dedicated server IP."
		return
	_connect_to_server(ip)


func _on_localhost_pressed() -> void:
	ip_input.text = LOCALHOST_IP
	_connect_to_server(LOCALHOST_IP)


func _connect_to_server(ip: String) -> void:
	_reset_connection(false)
	connect_attempt_id += 1
	var attempt_id := connect_attempt_id
	status_label.text = "Connecting..."
	connect_button.disabled = true
	if localhost_button != null:
		localhost_button.disabled = true

	peer = ENetMultiplayerPeer.new()
	var error: Error = peer.create_client(ip, _connection_port())
	if error != OK:
		status_label.text = "Failed to create client."
		_reset_connection(false)
		return

	multiplayer.multiplayer_peer = peer
	_watch_connection_timeout(attempt_id)


func _on_connected() -> void:
	connect_attempt_id += 1
	connect_button.disabled = false
	if localhost_button != null:
		localhost_button.disabled = false
	status_label.text = "Connected to server."
	game_server.clear_pending_client_session_action()
	navigating_away = true
	call_deferred("_open_mode_select_scene")


func _on_connection_failed() -> void:
	connect_attempt_id += 1
	status_label.text = "Connection failed. Check server IP."
	_reset_connection(false)


func _on_server_disconnected() -> void:
	if navigating_away:
		return
	connect_attempt_id += 1
	status_label.text = "Server disconnected."
	_reset_connection(false)
	game_server.reset_client_connection_state()


func _on_back_pressed() -> void:
	navigating_away = true
	connect_attempt_id += 1
	_reset_connection(false)
	game_server.reset_client_connection_state()
	get_tree().change_scene_to_file(BEGINNING_SCENE)


func _watch_connection_timeout(attempt_id: int) -> void:
	await get_tree().create_timer(CONNECT_TIMEOUT).timeout
	if not is_inside_tree() or attempt_id != connect_attempt_id:
		return
	if peer != null and peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTING:
		status_label.text = "Server not found. Check IP, server app, and firewall."
		connect_attempt_id += 1
		_reset_connection(false)


func _reset_connection(clear_status: bool = true) -> void:
	var active_peer: MultiplayerPeer = multiplayer.multiplayer_peer
	if active_peer != null:
		active_peer.close()
	multiplayer.multiplayer_peer = null
	peer = null
	if connect_button != null:
		connect_button.disabled = false
	if localhost_button != null:
		localhost_button.disabled = false
	if clear_status and status_label != null:
		status_label.text = ""


func _open_mode_select_scene() -> void:
	if not is_inside_tree():
		return
	get_tree().change_scene_to_file(MODE_SELECT_SCENE)


func _connection_port() -> int:
	var arguments := OS.get_cmdline_user_args() + OS.get_cmdline_args()
	for argument in arguments:
		if argument.begins_with("--pa-port="):
			var requested_port := int(argument.trim_prefix("--pa-port="))
			if requested_port > 0 and requested_port <= 65535:
				return requested_port
	return PORT
