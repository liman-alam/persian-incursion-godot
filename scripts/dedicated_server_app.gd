extends Control

const IP_REFRESH_INTERVAL: float = 2.0

const COLOR_BACKGROUND: Color = Color(0.035, 0.040, 0.047)
const COLOR_SURFACE: Color = Color(0.070, 0.080, 0.095)
const COLOR_SURFACE_ALT: Color = Color(0.090, 0.105, 0.125)
const COLOR_BORDER: Color = Color(0.190, 0.225, 0.270)
const COLOR_TEXT: Color = Color(0.930, 0.955, 0.985)
const COLOR_MUTED: Color = Color(0.650, 0.705, 0.780)
const COLOR_ACCENT: Color = Color(0.400, 0.635, 0.930)
const COLOR_SUCCESS: Color = Color(0.220, 0.700, 0.500)
const COLOR_WARNING: Color = Color(0.930, 0.680, 0.250)
const COLOR_DANGER: Color = Color(0.900, 0.260, 0.240)

var status_label: Label
var status_chip_panel: PanelContainer
var status_chip_label: Label
var ip_label: Label
var summary_label: Label
var error_label: Label
var start_button: Button
var stop_button: Button
var players_text: TextEdit
var ip_refresh_elapsed: float = 0.0


func _ready() -> void:
	_build_ui()
	_connect_game_server_signals()
	_refresh_all()


func _process(delta: float) -> void:
	ip_refresh_elapsed += delta
	if ip_refresh_elapsed >= IP_REFRESH_INTERVAL:
		ip_refresh_elapsed = 0.0
		_refresh_ip_label()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		GameServer.stop_server()
		get_tree().quit()


func _build_ui() -> void:
	anchor_right = 1.0
	anchor_bottom = 1.0

	var background := ColorRect.new()
	background.color = COLOR_BACKGROUND
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	add_child(scroll)

	var page := MarginContainer.new()
	page.custom_minimum_size = Vector2(720, 540)
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_theme_constant_override("margin_left", 24)
	page.add_theme_constant_override("margin_top", 24)
	page.add_theme_constant_override("margin_right", 24)
	page.add_theme_constant_override("margin_bottom", 24)
	scroll.add_child(page)

	var root := VBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 16)
	page.add_child(root)

	root.add_child(_build_header())
	root.add_child(_build_controls_panel())
	root.add_child(_build_players_panel())


func _build_header() -> PanelContainer:
	var panel := _make_panel(COLOR_SURFACE, COLOR_BORDER, Vector2(0, 150), 24)
	var header := VBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	panel.add_child(header)

	var top_row := HBoxContainer.new()
	top_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_theme_constant_override("separation", 18)
	header.add_child(top_row)

	var title_box := VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_box.add_theme_constant_override("separation", 4)
	top_row.add_child(title_box)

	var title := Label.new()
	title.text = "Persian Incursion"
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", COLOR_TEXT)
	title_box.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Dedicated Server Console"
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.add_theme_font_size_override("font_size", 13)
	subtitle.add_theme_color_override("font_color", COLOR_MUTED)
	title_box.add_child(subtitle)

	status_chip_panel = _make_chip("OFFLINE", COLOR_WARNING)
	top_row.add_child(status_chip_panel)

	status_label = Label.new()
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.add_theme_font_size_override("font_size", 14)
	status_label.add_theme_color_override("font_color", COLOR_TEXT)
	header.add_child(status_label)

	ip_label = Label.new()
	ip_label.add_theme_color_override("font_color", Color(0.690, 0.805, 1.000))
	ip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ip_label.add_theme_font_size_override("font_size", 14)
	header.add_child(ip_label)

	summary_label = Label.new()
	summary_label.add_theme_color_override("font_color", COLOR_MUTED)
	summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	header.add_child(summary_label)

	error_label = Label.new()
	error_label.add_theme_color_override("font_color", Color(1.000, 0.440, 0.400))
	error_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	header.add_child(error_label)

	return panel


func _build_controls_panel() -> PanelContainer:
	var panel := _make_panel(Color(0.058, 0.066, 0.079), COLOR_BORDER, Vector2(0, 92), 22)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)

	box.add_child(_make_section_title("Server Controls"))

	var controls := HBoxContainer.new()
	controls.add_theme_constant_override("separation", 10)
	box.add_child(controls)

	start_button = _make_button("Start Server", COLOR_ACCENT, Vector2(142, 36))
	start_button.pressed.connect(_on_start_pressed)
	controls.add_child(start_button)

	stop_button = _make_button("Stop Server", COLOR_DANGER, Vector2(142, 36))
	stop_button.pressed.connect(_on_stop_pressed)
	controls.add_child(stop_button)

	return panel


func _build_players_panel() -> PanelContainer:
	var players_panel := _make_panel(COLOR_SURFACE, COLOR_BORDER, Vector2(0, 286), 22)
	players_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	players_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var players_box := VBoxContainer.new()
	players_box.add_theme_constant_override("separation", 10)
	players_panel.add_child(players_box)

	players_box.add_child(_make_section_title("Connected Players"))

	players_text = TextEdit.new()
	players_text.editable = false
	players_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	players_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	players_text.custom_minimum_size = Vector2(0, 210)
	_style_text_edit(players_text)
	players_box.add_child(players_text)

	return players_panel


func _make_panel(bg_color: Color, border_color: Color, minimum_size: Vector2, margin: int) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = minimum_size
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(margin)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.22)
	style.shadow_size = 8
	style.shadow_offset = Vector2(0, 3)
	panel.add_theme_stylebox_override("panel", style)
	panel.add_theme_constant_override("margin_left", margin)
	panel.add_theme_constant_override("margin_top", margin)
	panel.add_theme_constant_override("margin_right", margin)
	panel.add_theme_constant_override("margin_bottom", margin)
	return panel


func _make_section_title(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", COLOR_TEXT)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


func _make_button(text: String, color: Color, minimum_size: Vector2 = Vector2(130, 38)) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = minimum_size
	button.add_theme_font_size_override("font_size", 13)
	button.add_theme_color_override("font_color", COLOR_TEXT)
	button.add_theme_stylebox_override("normal", _make_box(color, Color(min(color.r + 0.08, 1.0), min(color.g + 0.08, 1.0), min(color.b + 0.08, 1.0), 1.0), 8))
	button.add_theme_stylebox_override("hover", _make_box(Color(min(color.r + 0.05, 1.0), min(color.g + 0.05, 1.0), min(color.b + 0.05, 1.0), 1.0), Color(min(color.r + 0.16, 1.0), min(color.g + 0.16, 1.0), min(color.b + 0.16, 1.0), 1.0), 8))
	button.add_theme_stylebox_override("pressed", _make_box(Color(max(color.r - 0.05, 0.0), max(color.g - 0.05, 0.0), max(color.b - 0.05, 0.0), 1.0), COLOR_ACCENT, 8))
	return button


func _style_text_edit(text_edit: TextEdit) -> void:
	text_edit.add_theme_font_size_override("font_size", 14)
	text_edit.add_theme_color_override("font_color", Color(0.800, 0.840, 0.895))
	text_edit.add_theme_color_override("caret_color", COLOR_ACCENT)
	text_edit.add_theme_stylebox_override("normal", _make_box(Color(0.052, 0.058, 0.068), Color(0.130, 0.160, 0.195), 8))
	text_edit.add_theme_stylebox_override("read_only", _make_box(Color(0.052, 0.058, 0.068), Color(0.130, 0.160, 0.195), 8))
	text_edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY


func _make_box(bg_color: Color, border_color: Color, radius: int, content_margin: int = 8) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	style.set_content_margin_all(content_margin)
	return style


func _make_chip(text: String, color: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(104, 30)
	panel.size_flags_horizontal = Control.SIZE_SHRINK_END
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	panel.add_theme_stylebox_override("panel", _make_box(Color(color.r * 0.24, color.g * 0.24, color.b * 0.24, 1.0), color, 8, 6))

	status_chip_label = Label.new()
	status_chip_label.text = text
	status_chip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_chip_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status_chip_label.add_theme_font_size_override("font_size", 12)
	status_chip_label.add_theme_color_override("font_color", COLOR_TEXT)
	panel.add_child(status_chip_label)
	return panel


func _update_status_chip(status_text: String) -> void:
	var chip_color := COLOR_WARNING
	status_chip_label.text = "OFFLINE"

	if status_text.begins_with("SERVER ONLINE"):
		chip_color = COLOR_SUCCESS
		status_chip_label.text = "ONLINE"

	status_chip_panel.add_theme_stylebox_override("panel", _make_box(Color(chip_color.r * 0.24, chip_color.g * 0.24, chip_color.b * 0.24, 1.0), chip_color, 8, 6))


func _connect_game_server_signals() -> void:
	GameServer.status_changed.connect(_on_status_changed)
	GameServer.players_changed.connect(_on_players_changed)
	GameServer.server_error.connect(_on_server_error)


func _refresh_all() -> void:
	_on_status_changed(GameServer.get_status_text())
	_on_players_changed(GameServer.players)


func _on_start_pressed() -> void:
	error_label.text = ""
	GameServer.start_server("Dedicated Server", GameServer.DEFAULT_PORT, false)


func _on_stop_pressed() -> void:
	error_label.text = ""
	GameServer.stop_server()


func _on_status_changed(status_text: String) -> void:
	status_label.text = "Status: %s" % status_text
	_update_status_chip(status_text)
	_refresh_ip_label()
	summary_label.text = GameServer.get_connection_summary()
	_refresh_buttons()


func _on_players_changed(_players: Dictionary) -> void:
	players_text.text = GameServer.get_players_text()
	summary_label.text = GameServer.get_connection_summary()


func _on_server_error(message: String) -> void:
	error_label.text = message
	summary_label.text = GameServer.get_connection_summary()
	_update_status_chip(GameServer.get_status_text())
	_refresh_buttons()


func _refresh_buttons() -> void:
	var server_online := GameServer.is_running
	start_button.visible = not server_online
	stop_button.visible = server_online


func _refresh_ip_label() -> void:
	ip_label.text = "Port %d | Current IP for players: %s" % [GameServer.DEFAULT_PORT, GameServer.get_lan_ip_share_text()]
