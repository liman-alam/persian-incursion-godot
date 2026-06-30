extends Control

var status_label: Label
var ip_label: Label
var summary_label: Label
var error_label: Label
var players_text: TextEdit
var chat_text: TextEdit


func _ready() -> void:
	_build_ui()
	_connect_game_server_signals()
	GameServer.start_server("Dedicated Server", GameServer.DEFAULT_PORT, false)
	_refresh_all()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		GameServer.stop_server()
		get_tree().quit()


func _build_ui() -> void:
	anchor_right = 1.0
	anchor_bottom = 1.0

	var background := ColorRect.new()
	background.color = Color(0.04, 0.045, 0.055)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var page := MarginContainer.new()
	page.set_anchors_preset(Control.PRESET_FULL_RECT)
	page.add_theme_constant_override("margin_left", 44)
	page.add_theme_constant_override("margin_top", 34)
	page.add_theme_constant_override("margin_right", 44)
	page.add_theme_constant_override("margin_bottom", 34)
	add_child(page)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 14)
	page.add_child(root)

	var title := Label.new()
	title.text = "Persian Incursion Dedicated Server"
	title.add_theme_font_size_override("font_size", 28)
	root.add_child(title)

	status_label = Label.new()
	status_label.add_theme_font_size_override("font_size", 18)
	root.add_child(status_label)

	ip_label = Label.new()
	ip_label.add_theme_color_override("font_color", Color(0.62, 0.78, 1.0))
	ip_label.add_theme_font_size_override("font_size", 16)
	root.add_child(ip_label)

	summary_label = Label.new()
	summary_label.add_theme_color_override("font_color", Color(0.82, 0.88, 0.95))
	root.add_child(summary_label)

	error_label = Label.new()
	error_label.add_theme_color_override("font_color", Color(1.0, 0.36, 0.32))
	error_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(error_label)

	var controls := HBoxContainer.new()
	controls.add_theme_constant_override("separation", 10)
	root.add_child(controls)

	var start_button := Button.new()
	start_button.text = "Start Server"
	start_button.custom_minimum_size = Vector2(145, 38)
	start_button.pressed.connect(_on_start_pressed)
	controls.add_child(start_button)

	var stop_button := Button.new()
	stop_button.text = "Stop Server"
	stop_button.custom_minimum_size = Vector2(145, 38)
	stop_button.pressed.connect(_on_stop_pressed)
	controls.add_child(stop_button)

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
	players_text.custom_minimum_size = Vector2(390, 320)
	players_box.add_child(players_text)

	var chat_panel := _make_panel()
	chat_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chat_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(chat_panel)

	var chat_box := VBoxContainer.new()
	chat_box.add_theme_constant_override("separation", 8)
	chat_panel.add_child(chat_box)

	var chat_title := Label.new()
	chat_title.text = "Server Events And Chat"
	chat_title.add_theme_font_size_override("font_size", 18)
	chat_box.add_child(chat_title)

	chat_text = TextEdit.new()
	chat_text.editable = false
	chat_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	chat_text.custom_minimum_size = Vector2(560, 320)
	chat_box.add_child(chat_text)


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


func _connect_game_server_signals() -> void:
	GameServer.status_changed.connect(_on_status_changed)
	GameServer.players_changed.connect(_on_players_changed)
	GameServer.chat_changed.connect(_on_chat_changed)
	GameServer.server_error.connect(_on_server_error)


func _refresh_all() -> void:
	_on_status_changed(GameServer.get_status_text())
	_on_players_changed(GameServer.players)
	_on_chat_changed(GameServer.chat_history)


func _on_start_pressed() -> void:
	error_label.text = ""
	GameServer.start_server("Dedicated Server", GameServer.DEFAULT_PORT, false)


func _on_stop_pressed() -> void:
	GameServer.stop_server()


func _on_status_changed(status_text: String) -> void:
	status_label.text = "Status: %s" % status_text
	ip_label.text = "Players join using this IP: %s:%d" % [GameServer.get_lan_ip_text(), GameServer.DEFAULT_PORT]
	summary_label.text = GameServer.get_connection_summary()


func _on_players_changed(_players: Dictionary) -> void:
	players_text.text = GameServer.get_players_text()
	summary_label.text = GameServer.get_connection_summary()


func _on_chat_changed(_chat_history: Array) -> void:
	chat_text.text = GameServer.get_chat_text()
	chat_text.scroll_vertical = chat_text.get_line_count()


func _on_server_error(message: String) -> void:
	error_label.text = message
	summary_label.text = GameServer.get_connection_summary()
