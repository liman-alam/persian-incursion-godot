extends Control

var status_label: Label
var error_label: Label
var player_name_input: LineEdit
var ip_input: LineEdit
var players_text: TextEdit
var state_label: Label
var points_label: Label
var log_text: TextEdit
var chat_text: TextEdit
var chat_input: LineEdit


func _ready() -> void:
	_build_screen()
	_connect_server_signals()
	_refresh_all()


func _build_screen() -> void:
	anchors_preset = Control.PRESET_FULL_RECT

	var background := ColorRect.new()
	background.color = Color(0.055, 0.067, 0.082)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 12)
	root.offset_left = 28
	root.offset_top = 22
	root.offset_right = -28
	root.offset_bottom = -22
	add_child(root)

	var title := Label.new()
	title.text = "Persian Incursion - Server Control"
	title.add_theme_font_size_override("font_size", 28)
	root.add_child(title)

	status_label = Label.new()
	status_label.text = "OFFLINE"
	status_label.add_theme_font_size_override("font_size", 18)
	root.add_child(status_label)

	error_label = Label.new()
	error_label.text = ""
	error_label.modulate = Color(1.0, 0.42, 0.35)
	root.add_child(error_label)

	var setup_row := HBoxContainer.new()
	setup_row.add_theme_constant_override("separation", 10)
	root.add_child(setup_row)

	player_name_input = LineEdit.new()
	player_name_input.placeholder_text = "Your name"
	player_name_input.text = "Host"
	player_name_input.custom_minimum_size = Vector2(180, 36)
	setup_row.add_child(player_name_input)

	ip_input = LineEdit.new()
	ip_input.placeholder_text = "Server IP, example 127.0.0.1"
	ip_input.text = "127.0.0.1"
	ip_input.custom_minimum_size = Vector2(260, 36)
	setup_row.add_child(ip_input)

	var host_button := Button.new()
	host_button.text = "Start Server"
	host_button.custom_minimum_size = Vector2(130, 36)
	host_button.pressed.connect(_on_start_server_pressed)
	setup_row.add_child(host_button)

	var connect_button := Button.new()
	connect_button.text = "Connect"
	connect_button.custom_minimum_size = Vector2(110, 36)
	connect_button.pressed.connect(_on_connect_pressed)
	setup_row.add_child(connect_button)

	var stop_button := Button.new()
	stop_button.text = "Stop / Disconnect"
	stop_button.custom_minimum_size = Vector2(150, 36)
	stop_button.pressed.connect(_on_stop_pressed)
	setup_row.add_child(stop_button)

	var team_row := HBoxContainer.new()
	team_row.add_theme_constant_override("separation", 10)
	root.add_child(team_row)

	for team_name in ["White", "Red", "Blue", "Observer"]:
		var team_button := Button.new()
		team_button.text = team_name
		team_button.custom_minimum_size = Vector2(110, 34)
		team_button.pressed.connect(_on_team_pressed.bind(team_name))
		team_row.add_child(team_button)

	var action_row := HBoxContainer.new()
	action_row.add_theme_constant_override("separation", 10)
	root.add_child(action_row)

	var new_game_button := Button.new()
	new_game_button.text = "New Game State"
	new_game_button.pressed.connect(_on_new_game_pressed)
	action_row.add_child(new_game_button)

	var advance_button := Button.new()
	advance_button.text = "Advance Turn"
	advance_button.pressed.connect(_on_advance_turn_pressed)
	action_row.add_child(advance_button)

	var red_mp_button := Button.new()
	red_mp_button.text = "+1 Red MP"
	red_mp_button.pressed.connect(func() -> void: GameServer.add_points("Red", "MP", 1, "Server screen test/control"))
	action_row.add_child(red_mp_button)

	var blue_pp_button := Button.new()
	blue_pp_button.text = "+1 Blue PP"
	blue_pp_button.pressed.connect(func() -> void: GameServer.add_points("Blue", "PP", 1, "Server screen test/control"))
	action_row.add_child(blue_pp_button)

	var save_button := Button.new()
	save_button.text = "Save"
	save_button.pressed.connect(func() -> void: GameServer.save_game("autosave"))
	action_row.add_child(save_button)

	var load_button := Button.new()
	load_button.text = "Load"
	load_button.pressed.connect(func() -> void: GameServer.load_game("autosave"))
	action_row.add_child(load_button)

	var columns := HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 14)
	root.add_child(columns)

	var left_panel := VBoxContainer.new()
	left_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_child(left_panel)

	var players_label := Label.new()
	players_label.text = "Connected Players"
	players_label.add_theme_font_size_override("font_size", 16)
	left_panel.add_child(players_label)

	players_text = TextEdit.new()
	players_text.editable = false
	players_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_panel.add_child(players_text)

	state_label = Label.new()
	state_label.text = ""
	state_label.add_theme_font_size_override("font_size", 16)
	left_panel.add_child(state_label)

	points_label = Label.new()
	points_label.text = ""
	left_panel.add_child(points_label)

	var right_panel := VBoxContainer.new()
	right_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_child(right_panel)

	var log_label := Label.new()
	log_label.text = "Server Action Log"
	log_label.add_theme_font_size_override("font_size", 16)
	right_panel.add_child(log_label)

	log_text = TextEdit.new()
	log_text.editable = false
	log_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_panel.add_child(log_text)

	var chat_label := Label.new()
	chat_label.text = "Team Chat"
	chat_label.add_theme_font_size_override("font_size", 16)
	right_panel.add_child(chat_label)

	chat_text = TextEdit.new()
	chat_text.editable = false
	chat_text.custom_minimum_size = Vector2(0, 110)
	right_panel.add_child(chat_text)

	var chat_row := HBoxContainer.new()
	chat_row.add_theme_constant_override("separation", 8)
	right_panel.add_child(chat_row)

	chat_input = LineEdit.new()
	chat_input.placeholder_text = "Type message..."
	chat_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chat_input.text_submitted.connect(func(_text: String) -> void: _on_send_chat_pressed())
	chat_row.add_child(chat_input)

	var send_chat_button := Button.new()
	send_chat_button.text = "Send"
	send_chat_button.custom_minimum_size = Vector2(80, 34)
	send_chat_button.pressed.connect(_on_send_chat_pressed)
	chat_row.add_child(send_chat_button)


func _connect_server_signals() -> void:
	GameServer.status_changed.connect(_on_status_changed)
	GameServer.players_changed.connect(func(_players: Dictionary) -> void: _refresh_players())
	GameServer.game_state_changed.connect(func(_state: Dictionary) -> void: _refresh_game_state())
	GameServer.action_log_changed.connect(func(_log: Array) -> void: _refresh_log())
	GameServer.chat_changed.connect(func(_chat: Array) -> void: _refresh_chat())
	GameServer.server_error.connect(_on_server_error)


func _on_start_server_pressed() -> void:
	error_label.text = ""
	GameServer.start_server(player_name_input.text)


func _on_connect_pressed() -> void:
	error_label.text = ""
	GameServer.connect_to_server(ip_input.text, player_name_input.text)


func _on_stop_pressed() -> void:
	error_label.text = ""
	if GameServer.is_host:
		GameServer.stop_server()
	else:
		GameServer.disconnect_from_server()


func _on_team_pressed(team_name: String) -> void:
	error_label.text = ""
	GameServer.choose_team(team_name)


func _on_new_game_pressed() -> void:
	error_label.text = ""
	GameServer.start_new_game()


func _on_advance_turn_pressed() -> void:
	error_label.text = ""
	GameServer.advance_turn()


func _on_send_chat_pressed() -> void:
	error_label.text = ""
	GameServer.send_chat_message(chat_input.text)
	chat_input.clear()


func _on_status_changed(status_text: String) -> void:
	status_label.text = "Server Status: %s" % status_text


func _on_server_error(message: String) -> void:
	error_label.text = message


func _refresh_all() -> void:
	_on_status_changed(GameServer.get_status_text())
	_refresh_players()
	_refresh_game_state()
	_refresh_log()
	_refresh_chat()


func _refresh_players() -> void:
	players_text.text = GameServer.get_players_text()


func _refresh_game_state() -> void:
	state_label.text = GameServer.get_game_state_summary()
	points_label.text = GameServer.get_points_summary()


func _refresh_log() -> void:
	var lines: Array[String] = []
	for entry in GameServer.action_log:
		lines.append("#%d [%s] Day %d %s M%d %s - %s" % [
			int(entry.get("index", 0)),
			str(entry.get("category", "LOG")),
			int(entry.get("day", 0)),
			str(entry.get("phase", "Prep")),
			int(entry.get("move", 0)),
			str(entry.get("team", "White")),
			str(entry.get("message", ""))
		])
	log_text.text = "\n".join(lines)


func _refresh_chat() -> void:
	chat_text.text = GameServer.get_chat_text()
