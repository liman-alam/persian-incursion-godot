extends Control

var status_label: Label
var summary_label: Label
var local_ip_label: Label
var error_label: Label
var player_name_input: LineEdit
var host_ip_input: LineEdit
var players_text: TextEdit
var chat_text: TextEdit
var chat_input: LineEdit
var join_dialog: AcceptDialog
var join_ip_input: LineEdit


func _ready() -> void:
	_build_ui()
	_connect_game_server_signals()
	_refresh_all()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		GameServer.disconnect_from_server()
		get_tree().quit()


func _build_ui() -> void:
	anchor_right = 1.0
	anchor_bottom = 1.0

	var background := ColorRect.new()
	background.color = Color(0.045, 0.05, 0.06)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var page := MarginContainer.new()
	page.set_anchors_preset(Control.PRESET_FULL_RECT)
	page.add_theme_constant_override("margin_left", 48)
	page.add_theme_constant_override("margin_top", 36)
	page.add_theme_constant_override("margin_right", 48)
	page.add_theme_constant_override("margin_bottom", 36)
	add_child(page)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 14)
	page.add_child(root)

	var title := Label.new()
	title.text = "Persian Incursion"
	title.add_theme_font_size_override("font_size", 30)
	root.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Multiplayer Prototype"
	subtitle.add_theme_color_override("font_color", Color(0.75, 0.80, 0.86))
	subtitle.add_theme_font_size_override("font_size", 18)
	root.add_child(subtitle)

	status_label = Label.new()
	status_label.add_theme_font_size_override("font_size", 18)
	root.add_child(status_label)

	summary_label = Label.new()
	summary_label.add_theme_color_override("font_color", Color(0.82, 0.88, 0.95))
	root.add_child(summary_label)

	local_ip_label = Label.new()
	local_ip_label.add_theme_color_override("font_color", Color(0.62, 0.74, 0.92))
	root.add_child(local_ip_label)

	error_label = Label.new()
	error_label.add_theme_color_override("font_color", Color(1.0, 0.36, 0.32))
	error_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(error_label)

	var connection_panel := _make_panel()
	root.add_child(connection_panel)

	var connection_box := VBoxContainer.new()
	connection_box.add_theme_constant_override("separation", 10)
	connection_panel.add_child(connection_box)

	var player_row := HBoxContainer.new()
	player_row.add_theme_constant_override("separation", 10)
	connection_box.add_child(player_row)

	var name_label := Label.new()
	name_label.text = "Your Name"
	name_label.custom_minimum_size = Vector2(105, 0)
	player_row.add_child(name_label)

	player_name_input = LineEdit.new()
	player_name_input.text = "Player"
	player_name_input.placeholder_text = "Enter your name"
	player_name_input.custom_minimum_size = Vector2(220, 0)
	player_row.add_child(player_name_input)

	var ip_label := Label.new()
	ip_label.text = "Server IP"
	ip_label.custom_minimum_size = Vector2(80, 0)
	player_row.add_child(ip_label)

	host_ip_input = LineEdit.new()
	host_ip_input.text = "127.0.0.1"
	host_ip_input.placeholder_text = "Example: 10.255.84.156"
	host_ip_input.custom_minimum_size = Vector2(220, 0)
	player_row.add_child(host_ip_input)

	var button_row := HBoxContainer.new()
	button_row.add_theme_constant_override("separation", 10)
	connection_box.add_child(button_row)

	var host_button := Button.new()
	host_button.text = "Host Game"
	host_button.custom_minimum_size = Vector2(150, 38)
	host_button.pressed.connect(_on_host_pressed)
	button_row.add_child(host_button)

	var join_button := Button.new()
	join_button.text = "Join Game"
	join_button.custom_minimum_size = Vector2(150, 38)
	join_button.pressed.connect(_on_join_pressed)
	button_row.add_child(join_button)

	var disconnect_button := Button.new()
	disconnect_button.text = "Disconnect"
	disconnect_button.custom_minimum_size = Vector2(150, 38)
	disconnect_button.pressed.connect(_on_disconnect_pressed)
	button_row.add_child(disconnect_button)

	var team_row := HBoxContainer.new()
	team_row.add_theme_constant_override("separation", 10)
	connection_box.add_child(team_row)

	var team_label := Label.new()
	team_label.text = "Team"
	team_label.custom_minimum_size = Vector2(105, 0)
	team_row.add_child(team_label)

	for team_name in GameServer.TEAM_NAMES:
		var team_button := Button.new()
		team_button.text = team_name
		team_button.custom_minimum_size = Vector2(118, 34)
		team_button.pressed.connect(_on_team_pressed.bind(team_name))
		team_row.add_child(team_button)

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 14)
	root.add_child(body)

	var players_panel := _make_panel()
	players_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	players_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(players_panel)

	var players_box := VBoxContainer.new()
	players_box.add_theme_constant_override("separation", 8)
	players_panel.add_child(players_box)

	var players_title := Label.new()
	players_title.text = "Connected Players"
	players_title.add_theme_font_size_override("font_size", 18)
	players_box.add_child(players_title)

	players_text = TextEdit.new()
	players_text.editable = false
	players_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	players_text.custom_minimum_size = Vector2(390, 260)
	players_box.add_child(players_text)

	var chat_panel := _make_panel()
	chat_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chat_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(chat_panel)

	var chat_box := VBoxContainer.new()
	chat_box.add_theme_constant_override("separation", 8)
	chat_panel.add_child(chat_box)

	var chat_title := Label.new()
	chat_title.text = "Chat"
	chat_title.add_theme_font_size_override("font_size", 18)
	chat_box.add_child(chat_title)

	chat_text = TextEdit.new()
	chat_text.editable = false
	chat_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	chat_text.custom_minimum_size = Vector2(520, 260)
	chat_box.add_child(chat_text)

	var chat_row := HBoxContainer.new()
	chat_row.add_theme_constant_override("separation", 8)
	chat_box.add_child(chat_row)

	chat_input = LineEdit.new()
	chat_input.placeholder_text = "Type message..."
	chat_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chat_input.text_submitted.connect(_on_chat_submitted)
	chat_row.add_child(chat_input)

	var send_button := Button.new()
	send_button.text = "Send"
	send_button.custom_minimum_size = Vector2(90, 34)
	send_button.pressed.connect(_on_send_chat_pressed)
	chat_row.add_child(send_button)

	_create_join_dialog()


func _make_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.075, 0.085, 0.10)
	style.border_color = Color(0.15, 0.18, 0.22)
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel", style)
	panel.add_theme_constant_override("margin_left", 16)
	panel.add_theme_constant_override("margin_top", 14)
	panel.add_theme_constant_override("margin_right", 16)
	panel.add_theme_constant_override("margin_bottom", 14)
	return panel


func _create_join_dialog() -> void:
	join_dialog = AcceptDialog.new()
	join_dialog.title = "Join Game"
	join_dialog.confirmed.connect(_on_join_confirmed)
	add_child(join_dialog)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	join_dialog.add_child(box)

	var prompt := Label.new()
	prompt.text = "Enter the host computer IP address."
	box.add_child(prompt)

	join_ip_input = LineEdit.new()
	join_ip_input.text = host_ip_input.text
	join_ip_input.placeholder_text = "Example: 10.255.84.156"
	join_ip_input.custom_minimum_size = Vector2(360, 36)
	box.add_child(join_ip_input)


func _connect_game_server_signals() -> void:
	GameServer.status_changed.connect(_on_status_changed)
	GameServer.players_changed.connect(_on_players_changed)
	GameServer.chat_changed.connect(_on_chat_changed)
	GameServer.server_error.connect(_on_server_error)


func _refresh_all() -> void:
	_on_status_changed(GameServer.get_status_text())
	_on_players_changed(GameServer.players)
	_on_chat_changed(GameServer.chat_history)
	local_ip_label.text = "Your computer IP for teammates: %s" % GameServer.get_lan_ip_text()


func _on_host_pressed() -> void:
	error_label.text = ""
	host_ip_input.text = "127.0.0.1"
	summary_label.text = "Host mode selected. Start the server executable first, then this game window will connect as host."
	GameServer.connect_to_server("127.0.0.1", _get_player_name())


func _on_join_pressed() -> void:
	error_label.text = ""
	join_ip_input.text = host_ip_input.text
	join_dialog.popup_centered(Vector2i(430, 170))
	join_ip_input.grab_focus()


func _on_join_confirmed() -> void:
	error_label.text = ""
	host_ip_input.text = join_ip_input.text.strip_edges()
	GameServer.connect_to_server(host_ip_input.text, _get_player_name())


func _on_disconnect_pressed() -> void:
	GameServer.disconnect_from_server()


func _on_team_pressed(team_name: String) -> void:
	GameServer.choose_team(team_name)


func _on_send_chat_pressed() -> void:
	_send_chat_message()


func _on_chat_submitted(_message: String) -> void:
	_send_chat_message()


func _send_chat_message() -> void:
	var message := chat_input.text.strip_edges()
	if message.is_empty():
		return

	GameServer.send_chat_message(message)
	chat_input.clear()
	chat_input.grab_focus()


func _on_status_changed(status_text: String) -> void:
	status_label.text = "Server Status: %s" % status_text
	summary_label.text = GameServer.get_connection_summary()
	local_ip_label.text = "Your computer IP for teammates: %s" % GameServer.get_lan_ip_text()


func _on_players_changed(_players: Dictionary) -> void:
	players_text.text = GameServer.get_players_text()
	summary_label.text = GameServer.get_connection_summary()


func _on_chat_changed(_chat_history: Array) -> void:
	chat_text.text = GameServer.get_chat_text()
	chat_text.scroll_vertical = chat_text.get_line_count()


func _on_server_error(message: String) -> void:
	error_label.text = message
	summary_label.text = GameServer.get_connection_summary()


func _get_player_name() -> String:
	var player_name := player_name_input.text.strip_edges()
	if player_name.is_empty():
		return "Player"
	return player_name
