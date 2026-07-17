extends Control

const MODE_SELECT_SCENE: String = "res://UI/MainScenes/ModeSelect.tscn"
const CONNECT_SCENE: String = "res://UI/MainScenes/Connect.tscn"
const TEAM_SELECT_SCENE: String = "res://UI/MainScenes/TeamSelect.tscn"
const FONT_PATH: String = "res://Art/Fonts/Rajdhani/Rajdhani-SemiBold.ttf"

@export var title_label: Label
@export var prompt_label: Label
@export var status_label: Label
@export var panel_vbox: VBoxContainer
@export var back_button: BaseButton
@export var continue_button: BaseButton
@export var refresh_button: BaseButton

var game_font: FontFile
var game_name_input: LineEdit
var save_list_scroll: ScrollContainer
var save_list_box: VBoxContainer
var save_buttons: Array[Button] = []
var saved_games: Array = []
var selected_save_index: int = -1
var request_in_flight: bool = false
var navigating_away: bool = false
var game_server


func _ready() -> void:
	game_font = load(FONT_PATH) as FontFile
	_resolve_ui_references()
	game_server = get_node_or_null("/root/GameServer")
	if game_server == null:
		push_error("SaveSelect scene could not find /root/GameServer.")
		if status_label != null:
			status_label.text = "Game server state is not available."
		return
	if not _is_connected_to_server():
		game_server.clear_pending_client_session_action()
		call_deferred("_open_connect_scene")
		return

	_connect_buttons()
	_connect_server_signals()
	_build_for_action()


func _resolve_ui_references() -> void:
	if title_label == null:
		title_label = get_node_or_null("CanvasLayer/VBoxContainer/CenterContainer/TitleLabel") as Label
	if prompt_label == null:
		prompt_label = get_node_or_null("CanvasLayer/VBoxContainer/CenterContainer2/Panel/PanelMargin/PanelVBox/PromptLabel") as Label
	if status_label == null:
		status_label = get_node_or_null("CanvasLayer/VBoxContainer/CenterContainer2/Panel/PanelMargin/PanelVBox/StatusLabel") as Label
	if panel_vbox == null:
		panel_vbox = get_node_or_null("CanvasLayer/VBoxContainer/CenterContainer2/Panel/PanelMargin/PanelVBox") as VBoxContainer
	if back_button == null:
		back_button = get_node_or_null("CanvasLayer/VBoxContainer/CenterContainer2/Panel/PanelMargin/PanelVBox/ButtonRow/BackButton") as BaseButton
	if continue_button == null:
		continue_button = get_node_or_null("CanvasLayer/VBoxContainer/CenterContainer2/Panel/PanelMargin/PanelVBox/ButtonRow/ContinueButton") as BaseButton
	if refresh_button == null:
		refresh_button = get_node_or_null("CanvasLayer/VBoxContainer/CenterContainer2/Panel/PanelMargin/PanelVBox/ButtonRow/RefreshButton") as BaseButton


func _connect_buttons() -> void:
	if back_button != null:
		back_button.pressed.connect(_on_back_pressed)
	if continue_button != null:
		continue_button.pressed.connect(_on_continue_pressed)
	if refresh_button != null:
		refresh_button.pressed.connect(_refresh_save_list)


func _connect_server_signals() -> void:
	if not game_server.save_list_changed.is_connected(_on_save_list_changed):
		game_server.save_list_changed.connect(_on_save_list_changed)
	if not game_server.session_request_completed.is_connected(_on_session_request_completed):
		game_server.session_request_completed.connect(_on_session_request_completed)
	if not multiplayer.server_disconnected.is_connected(_on_server_disconnected):
		multiplayer.server_disconnected.connect(_on_server_disconnected)


func _build_for_action() -> void:
	var action: String = str(game_server.pending_client_session_action)
	if action == game_server.CLIENT_SESSION_ACTION_NEW:
		_build_new_game_ui()
	elif action == game_server.CLIENT_SESSION_ACTION_LOAD:
		_build_load_game_ui()
	else:
		call_deferred("_open_mode_select_scene")


func _build_new_game_ui() -> void:
	if title_label != null:
		title_label.text = "New Game"
	if prompt_label != null:
		prompt_label.text = "Create Save on This Server"
	if status_label != null:
		status_label.text = "Enter a name for the new game."
	if refresh_button != null:
		refresh_button.visible = false
	if continue_button != null:
		continue_button.text = "Create Game"
		continue_button.disabled = false

	game_name_input = _make_line_edit("Game name")
	game_name_input.text_submitted.connect(_on_game_name_submitted)
	panel_vbox.add_child(game_name_input)
	panel_vbox.move_child(game_name_input, status_label.get_index())
	game_name_input.call_deferred("grab_focus")


func _build_load_game_ui() -> void:
	if title_label != null:
		title_label.text = "Load Game"
	if prompt_label != null:
		prompt_label.text = "Saved Games on This Server"
	if status_label != null:
		status_label.text = "Loading saves from the server..."
	if refresh_button != null:
		refresh_button.visible = true
	if continue_button != null:
		continue_button.text = "Load Game"
		continue_button.disabled = true

	save_list_scroll = ScrollContainer.new()
	save_list_scroll.custom_minimum_size = Vector2(680, 255)
	save_list_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	save_list_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	save_list_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED

	save_list_box = VBoxContainer.new()
	save_list_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	save_list_box.add_theme_constant_override("separation", 12)
	save_list_scroll.add_child(save_list_box)
	panel_vbox.add_child(save_list_scroll)
	panel_vbox.move_child(save_list_scroll, status_label.get_index())
	_refresh_save_list()


func _on_game_name_submitted(_submitted_text: String) -> void:
	_on_continue_pressed()


func _refresh_save_list() -> void:
	if request_in_flight or not _is_connected_to_server():
		return
	_clear_save_list()
	if status_label != null:
		status_label.text = "Loading saves from the server..."
	if refresh_button != null:
		refresh_button.disabled = true
	if continue_button != null:
		continue_button.disabled = true
	game_server.request_save_list.rpc_id(1)


func _on_save_list_changed(server_saved_games: Array) -> void:
	if game_server.pending_client_session_action != game_server.CLIENT_SESSION_ACTION_LOAD:
		return
	if save_list_box == null:
		return

	_clear_save_list()
	for raw_save_info in server_saved_games:
		var save_info: Dictionary = raw_save_info if raw_save_info is Dictionary else {}
		var save_name := str(save_info.get("name", "")).strip_edges()
		if save_name.is_empty():
			continue
		saved_games.append(save_info.duplicate(true))
		var button := _make_save_button(save_name, str(save_info.get("summary", "")))
		button.pressed.connect(_select_save.bind(saved_games.size() - 1))
		save_buttons.append(button)
		save_list_box.add_child(button)

	if save_buttons.is_empty():
		saved_games.clear()
		save_list_box.add_child(_make_label("No saved games found on this server."))
		status_label.text = "Create a new game to begin on this server."
	else:
		status_label.text = "%d saved game%s found. Choose one to load." % [save_buttons.size(), "" if save_buttons.size() == 1 else "s"]

	if refresh_button != null:
		refresh_button.disabled = false
	if continue_button != null:
		continue_button.disabled = true


func _clear_save_list() -> void:
	selected_save_index = -1
	save_buttons.clear()
	saved_games.clear()
	if save_list_box == null:
		return
	for child in save_list_box.get_children():
		child.queue_free()


func _select_save(index: int) -> void:
	if index < 0 or index >= save_buttons.size() or index >= saved_games.size():
		return
	selected_save_index = index
	for button_index in range(save_buttons.size()):
		_style_save_button(save_buttons[button_index], button_index == selected_save_index)
	if continue_button != null:
		continue_button.disabled = false
	var save_name := str((saved_games[index] as Dictionary).get("name", ""))
	if status_label != null:
		status_label.text = "%s selected." % save_name


func _on_continue_pressed() -> void:
	if request_in_flight:
		return
	var action: String = str(game_server.pending_client_session_action)
	if action == game_server.CLIENT_SESSION_ACTION_NEW:
		_create_new_game_on_server()
	elif action == game_server.CLIENT_SESSION_ACTION_LOAD:
		_load_selected_game_from_server()


func _create_new_game_on_server() -> void:
	if game_name_input == null:
		return
	var game_name := SaveFunctionality.sanitize_game_name(game_name_input.text)
	if game_name.is_empty():
		status_label.text = "Enter a game name."
		return
	request_in_flight = true
	status_label.text = "Creating %s on this server..." % game_name
	_set_controls_disabled(true)
	game_server.request_create_game_session.rpc_id(1, game_name)


func _load_selected_game_from_server() -> void:
	if selected_save_index < 0 or selected_save_index >= saved_games.size():
		status_label.text = "Choose a saved game to load."
		return
	var save_name := str((saved_games[selected_save_index] as Dictionary).get("name", ""))
	if save_name.is_empty():
		status_label.text = "Choose a valid saved game."
		return
	request_in_flight = true
	status_label.text = "Loading %s from this server..." % save_name
	_set_controls_disabled(true)
	game_server.request_load_game_session.rpc_id(1, save_name)


func _on_session_request_completed(success: bool, message: String) -> void:
	if game_server.pending_client_session_action == game_server.CLIENT_SESSION_ACTION_NONE:
		return
	request_in_flight = false
	status_label.text = message
	_set_controls_disabled(false)
	if not success:
		return
	game_server.clear_pending_client_session_action()
	navigating_away = true
	get_tree().change_scene_to_file(TEAM_SELECT_SCENE)


func _set_controls_disabled(disabled: bool) -> void:
	if game_name_input != null:
		game_name_input.editable = not disabled
	if back_button != null:
		back_button.disabled = disabled
	if refresh_button != null:
		refresh_button.disabled = disabled
	for button in save_buttons:
		button.disabled = disabled
	if continue_button != null:
		if disabled:
			continue_button.disabled = true
		elif game_server.pending_client_session_action == game_server.CLIENT_SESSION_ACTION_LOAD:
			continue_button.disabled = selected_save_index < 0
		else:
			continue_button.disabled = false


func _on_back_pressed() -> void:
	if request_in_flight:
		return
	navigating_away = true
	game_server.clear_pending_client_session_action()
	get_tree().change_scene_to_file(MODE_SELECT_SCENE)


func _on_server_disconnected() -> void:
	if navigating_away:
		return
	game_server.reset_client_connection_state()
	call_deferred("_open_connect_scene")


func _open_connect_scene() -> void:
	if not is_inside_tree() or navigating_away:
		return
	navigating_away = true
	get_tree().change_scene_to_file(CONNECT_SCENE)


func _open_mode_select_scene() -> void:
	if not is_inside_tree() or navigating_away:
		return
	navigating_away = true
	get_tree().change_scene_to_file(MODE_SELECT_SCENE)


func _is_connected_to_server() -> bool:
	var active_peer: MultiplayerPeer = multiplayer.multiplayer_peer
	return active_peer != null and active_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED


func _make_line_edit(placeholder: String) -> LineEdit:
	var line_edit := LineEdit.new()
	line_edit.placeholder_text = placeholder
	line_edit.custom_minimum_size = Vector2(560, 64)
	line_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	line_edit.add_theme_font_size_override("font_size", 36)
	line_edit.add_theme_color_override("font_color", Color(0.972549, 0.95686275, 0.7921569, 1))
	line_edit.add_theme_color_override("font_placeholder_color", Color(0.972549, 0.95686275, 0.7921569, 0.45))
	if game_font != null:
		line_edit.add_theme_font_override("font", game_font)
	var style := _make_box(Color(0.015686275, 0.06666667, 0.03529412, 0.88), Color(0.6901961, 0.43137255, 0.09411765, 0.95), 10, 16)
	line_edit.add_theme_stylebox_override("normal", style)
	line_edit.add_theme_stylebox_override("focus", style)
	return line_edit


func _make_save_button(save_name: String, summary: String) -> Button:
	var button := Button.new()
	button.text = "%s\n%s" % [save_name, summary]
	button.custom_minimum_size = Vector2(0, 84)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.clip_text = true
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.add_theme_font_size_override("font_size", 24)
	button.add_theme_color_override("font_color", Color(0.972549, 0.95686275, 0.7921569, 1))
	button.add_theme_color_override("font_hover_color", Color(1, 1, 0.8627451, 1))
	if game_font != null:
		button.add_theme_font_override("font", game_font)
	_style_save_button(button, false)
	return button


func _style_save_button(button: Button, selected: bool) -> void:
	var bg := Color(0.015686275, 0.06666667, 0.03529412, 0.88)
	var border := Color(0.6901961, 0.43137255, 0.09411765, 0.95)
	if selected:
		bg = Color(0.03529412, 0.29803923, 0.101960786, 0.95)
		border = Color(1, 0.76862746, 0.23137255, 1)
	button.add_theme_stylebox_override("normal", _make_box(bg, border, 10, 18))
	button.add_theme_stylebox_override("hover", _make_box(Color(0.05882353, 0.43137255, 0.14117648, 0.98), Color(1, 0.76862746, 0.23137255, 1), 10, 18))
	button.add_theme_stylebox_override("pressed", _make_box(Color(0.019607844, 0.20784314, 0.07450981, 1), border, 10, 18))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())


func _make_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.custom_minimum_size = Vector2(0, 120)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 28)
	label.add_theme_color_override("font_color", Color(0.972549, 0.95686275, 0.7921569, 1))
	if game_font != null:
		label.add_theme_font_override("font", game_font)
	return label


func _make_box(bg_color: Color, border_color: Color, radius: int, content_margin: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.set_border_width_all(3)
	style.set_corner_radius_all(radius)
	style.set_content_margin_all(content_margin)
	style.shadow_color = Color(0, 0, 0, 0.42)
	style.shadow_size = 8
	return style
