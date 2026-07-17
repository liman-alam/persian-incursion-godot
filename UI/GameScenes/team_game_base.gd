extends Control
class_name TeamGameBase

const GameRules = preload("res://server/game_rules.gd")
const GameUi = preload("res://UI/GameScenes/game_ui.gd")
const GameFeatureScreens = preload("res://UI/GameScenes/game_feature_screens.gd")
const GAME_BUTTON_FONT = preload("res://Art/Fonts/Rajdhani/Rajdhani-SemiBold.ttf")
const MODE_SELECT_SCENE := "res://UI/MainScenes/ModeSelect.tscn"
var team_name: String = ""
var team_accent: Color = GameUi.WHITE
var game_server
var snapshot: Dictionary = {}
var saved_games: Array = []
var feature_screens

var runtime_root: Control
var overlay_root: Control
var modal_root: Control
var title_label: Button
var turn_label: Label
var current_move_label: Label
var countdown_label: Label
var elapsed_label: Label
var timer_button: Button
var team_selector: OptionButton
var point_team_label: Label
var point_labels: Dictionary = {}
var pending_panel: PanelContainer
var pending_label: Label
var pending_resolution_button: Button
var turn_controls_panel: PanelContainer
var turn_instruction_label: Label
var begin_campaign_button: Button
var open_turn_screen_button: Button
var submit_action_button: Button
var pass_move_button: Button
var chat_history_label: RichTextLabel
var chat_input: LineEdit
var chat_channel_label: Label
var chat_channel_buttons: Dictionary = {}
var chat_channel: String = "Announcement"
var dice_result_label: Label
var status_label: Label
var game_over_root: Control
var game_over_label: Label
var menu_buttons: Array[Button] = []


func _ready() -> void:
	_configure_team()
	if not ["White", "Red", "Blue"].has(team_name):
		push_error("A team game scene must configure White, Red, or Blue.")
		return

	snapshot = GameRules.make_default_snapshot()
	game_server = get_node_or_null("/root/GameServer")
	if not _bind_main_screen():
		push_error("The team game scene is missing its editable 2D dashboard nodes.")
		return
	feature_screens = GameFeatureScreens.new(self)
	_connect_server_signals()
	if game_server != null:
		if game_server.has_method("set_local_team"):
			game_server.set_local_team(team_name)
		if game_server.has_method("get_active_save_data"):
			var server_snapshot: Dictionary = game_server.get_active_save_data()
			if not server_snapshot.is_empty():
				snapshot = server_snapshot
	_update_from_snapshot()
	_refresh_chat()


func _configure_team() -> void:
	pass


func _menu_entries() -> Array[Dictionary]:
	return []


func _connect_server_signals() -> void:
	if game_server == null:
		show_status("Offline preview: server state is not connected.", false)
		return
	if not game_server.session_changed.is_connected(_on_session_changed):
		game_server.session_changed.connect(_on_session_changed)
	if not game_server.session_request_completed.is_connected(_on_request_completed):
		game_server.session_request_completed.connect(_on_request_completed)
	if not game_server.chat_message_received.is_connected(_on_chat_message):
		game_server.chat_message_received.connect(_on_chat_message)
	if not game_server.save_list_changed.is_connected(_on_save_list_changed):
		game_server.save_list_changed.connect(_on_save_list_changed)
	if not game_server.server_error.is_connected(_on_server_error):
		game_server.server_error.connect(_on_server_error)


func _bind_main_screen() -> bool:
	runtime_root = get_node_or_null("%Dashboard") as Control
	if runtime_root == null:
		return false

	title_label = get_node_or_null("%TitleLabel") as Button
	turn_label = get_node_or_null("%TurnLabel") as Label
	current_move_label = get_node_or_null("%CurrentMoveLabel") as Label
	countdown_label = get_node_or_null("%CountdownLabel") as Label
	elapsed_label = get_node_or_null("%ElapsedLabel") as Label
	timer_button = get_node_or_null("%TimerButton") as Button
	team_selector = get_node_or_null("%TeamSelector") as OptionButton
	point_team_label = get_node_or_null("%PointTeamLabel") as Label
	point_labels = {
		"IP": get_node_or_null("%IPLabel") as Label,
		"MP": get_node_or_null("%MPLabel") as Label,
		"PP": get_node_or_null("%PPLabel") as Label
	}
	pending_panel = get_node_or_null("%PendingPanel") as PanelContainer
	pending_label = get_node_or_null("%PendingLabel") as Label
	pending_resolution_button = get_node_or_null("%ResolveButton") as Button
	turn_controls_panel = get_node_or_null("%TurnControlsPanel") as PanelContainer
	turn_instruction_label = get_node_or_null("%TurnInstructionLabel") as Label
	begin_campaign_button = get_node_or_null("%BeginCampaignButton") as Button
	submit_action_button = get_node_or_null("%SubmitActionButton") as Button
	pass_move_button = get_node_or_null("%PassMoveButton") as Button
	chat_history_label = get_node_or_null("%ChatHistory") as RichTextLabel
	chat_input = get_node_or_null("%ChatInput") as LineEdit
	chat_channel_label = get_node_or_null("%ChatChannelLabel") as Label
	dice_result_label = get_node_or_null("%DiceResultLabel") as Label
	status_label = get_node_or_null("%StatusLabel") as Label
	game_over_root = get_node_or_null("%GameOverOverlay") as Control
	game_over_label = get_node_or_null("%GameOverLabel") as Label

	var required_nodes: Array = [
		title_label, turn_label, current_move_label, countdown_label, elapsed_label,
		timer_button, team_selector, point_team_label, pending_panel, pending_label,
		pending_resolution_button, turn_controls_panel, turn_instruction_label,
		begin_campaign_button, submit_action_button, pass_move_button,
		chat_history_label, chat_input, chat_channel_label, dice_result_label,
		status_label, game_over_root, game_over_label
	]
	for required_node in required_nodes:
		if required_node == null:
			return false

	_style_editor_dashboard()
	_configure_team_controls()
	_connect_editor_controls()
	return true


func _style_editor_dashboard() -> void:
	_style_clear_panel("TitlePanel")
	_style_overlay_panel("TimerPanel")
	_style_overlay_panel("PointsPanel")
	_style_panel("PendingPanel", 0.94, team_accent)
	_style_panel("TurnControlsPanel", 0.94, team_accent)
	_style_clear_panel("ChatPanel")
	_style_panel("DicePanel", 0.9, GameUi.GOLD)
	_style_clear_panel("MenuPanel")
	_style_panel("StatusPanel", 0.88, GameUi.GOLD)
	_style_panel("GameOverPanel", 0.98, team_accent)
	chat_history_label.add_theme_stylebox_override("normal", _friend_chat_style())

	for node in runtime_root.find_children("*", "BaseButton", true, false):
		GameUi.style_button(node as BaseButton, team_accent)
	var review_button := get_node_or_null("%ReviewCampaignButton") as Button
	if review_button != null:
		GameUi.style_button(review_button, team_accent)
	for node_name in ["PrevTurnButton", "PrevDayButton", "TeamSelector", "NextDayButton", "NextTurnButton", "TimerButton", "D6Button", "TwoD6Button", "D10Button", "D100Button"]:
		var button_node := get_node_or_null("%%%s" % node_name) as BaseButton
		if button_node != null:
			GameUi.style_button(button_node, GameUi.GOLD)

	_style_friend_button(title_label, 50)
	for node_name in ["PublicChatButton", "RedChatButton", "BlueChatButton"]:
		_style_friend_button(get_node_or_null("%%%s" % node_name) as BaseButton, 30)
	_style_friend_button(get_node_or_null("%SendChatButton") as BaseButton, 30)
	for index in range(1, 10):
		_style_friend_button(get_node_or_null("%%MenuButton%02d" % index) as BaseButton, 30)

	title_label.add_theme_color_override("font_color", GameUi.CREAM)
	point_team_label.add_theme_color_override("font_color", team_accent)
	var turn_heading := get_node_or_null("%TurnControlHeading") as Label
	if turn_heading != null:
		turn_heading.add_theme_color_override("font_color", team_accent)
	var menu_heading := get_node_or_null("%MenuHeading") as Label
	if menu_heading != null:
		menu_heading.add_theme_color_override("font_color", team_accent)
	var game_over_title := get_node_or_null("%GameOverTitle") as Label
	if game_over_title != null:
		game_over_title.add_theme_color_override("font_color", team_accent)


func _style_panel(unique_name: String, alpha: float, border_color: Color) -> void:
	var panel := get_node_or_null("%%%s" % unique_name) as PanelContainer
	if panel != null:
		panel.add_theme_stylebox_override("panel", GameUi.panel_style(alpha, border_color))


func _style_clear_panel(unique_name: String) -> void:
	var panel := get_node_or_null("%%%s" % unique_name) as PanelContainer
	if panel == null:
		return
	var style := StyleBoxFlat.new()
	style.bg_color = Color.TRANSPARENT
	panel.add_theme_stylebox_override("panel", style)


func _style_overlay_panel(unique_name: String) -> void:
	var panel := get_node_or_null("%%%s" % unique_name) as PanelContainer
	if panel == null:
		return
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.035, 0.025, 0.55)
	style.content_margin_left = 8.0
	style.content_margin_top = 8.0
	style.content_margin_right = 8.0
	style.content_margin_bottom = 8.0
	panel.add_theme_stylebox_override("panel", style)


func _friend_chat_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.025, 0.018, 0.54)
	style.content_margin_left = 6.0
	style.content_margin_top = 6.0
	style.content_margin_right = 6.0
	style.content_margin_bottom = 6.0
	return style


func _style_friend_button(button_node: BaseButton, font_size: int) -> void:
	if button_node == null:
		return
	button_node.add_theme_font_override("font", GAME_BUTTON_FONT)
	button_node.add_theme_font_size_override("font_size", font_size)
	button_node.add_theme_color_override("font_color", GameUi.CREAM)
	button_node.add_theme_color_override("font_hover_color", Color.WHITE)
	button_node.add_theme_color_override("font_pressed_color", Color.WHITE)
	button_node.add_theme_stylebox_override("normal", _friend_button_style(Color(0.0353, 0.298, 0.102, 0.92), Color(0.58, 0.36, 0.04, 1.0)))
	button_node.add_theme_stylebox_override("hover", _friend_button_style(Color(0.0588, 0.4314, 0.1412, 0.98), Color(0.95, 0.68, 0.12, 1.0)))
	button_node.add_theme_stylebox_override("pressed", _friend_button_style(Color(0.025, 0.235, 0.075, 0.98), Color(0.84, 0.55, 0.08, 1.0)))
	button_node.add_theme_stylebox_override("focus", _friend_button_style(Color(0.0588, 0.4314, 0.1412, 0.98), GameUi.CREAM))
	button_node.add_theme_stylebox_override("disabled", _friend_button_style(Color(0.12, 0.16, 0.13, 0.88), Color(0.35, 0.29, 0.17, 1.0)))


func _friend_button_style(background: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(3)
	style.set_corner_radius_all(12)
	style.content_margin_left = 12.0
	style.content_margin_top = 7.0
	style.content_margin_right = 12.0
	style.content_margin_bottom = 7.0
	style.shadow_color = Color(0, 0, 0, 0.28)
	style.shadow_size = 3
	return style


func _configure_team_controls() -> void:
	var is_white := team_name == "White"
	(get_node("%AdminRow") as Control).visible = false
	timer_button.visible = false
	current_move_label.visible = false
	point_team_label.visible = false
	turn_controls_panel.visible = false
	(get_node("%DicePanel") as Control).visible = false
	(get_node("%ApproveButton") as Button).visible = is_white
	(get_node("%ReturnButton") as Button).visible = is_white
	pending_resolution_button.visible = false
	begin_campaign_button.visible = is_white
	(get_node("%OpenTeamTrackButton") as Button).visible = is_white
	(get_node("%PlanActionButton") as Button).visible = not is_white
	submit_action_button.visible = not is_white
	pass_move_button.visible = not is_white
	open_turn_screen_button = (get_node("%OpenTeamTrackButton") if is_white else get_node("%PlanActionButton")) as Button

	point_team_label.text = "%s RESOURCES" % team_name.to_upper()
	(get_node("%MenuHeading") as Label).text = "%s COMMAND" % team_name.to_upper()

	var public_button := get_node("%PublicChatButton") as Button
	var red_button := get_node("%RedChatButton") as Button
	var blue_button := get_node("%BlueChatButton") as Button
	public_button.visible = is_white
	red_button.visible = is_white or team_name == "Red"
	blue_button.visible = is_white or team_name == "Blue"
	chat_channel_buttons.clear()
	if is_white:
		chat_channel = "Announcement"
		chat_channel_buttons = {"Announcement": public_button, "Red": red_button, "Blue": blue_button}
	elif team_name == "Red":
		chat_channel = "Red"
		chat_channel_buttons = {"Red": red_button}
	else:
		chat_channel = "Blue"
		chat_channel_buttons = {"Blue": blue_button}

	menu_buttons = []
	for index in range(1, 10):
		menu_buttons.append(get_node("%%MenuButton%02d" % index) as Button)
	var entries := _menu_entries()
	for index in range(menu_buttons.size()):
		var button := menu_buttons[index]
		button.visible = index < entries.size()
		if button.visible:
			var entry: Dictionary = entries[index]
			button.text = str(entry.get("label", "Open"))
			button.pressed.connect(_open_feature.bind(str(entry.get("screen", ""))))


func _connect_editor_controls() -> void:
	(get_node("%PrevTurnButton") as Button).pressed.connect(_request_turn_change.bind(false))
	(get_node("%PrevDayButton") as Button).pressed.connect(_request_day_change.bind(false))
	team_selector.item_selected.connect(_on_team_selector_changed)
	(get_node("%NextDayButton") as Button).pressed.connect(_request_day_change.bind(true))
	(get_node("%NextTurnButton") as Button).pressed.connect(_request_turn_change.bind(true))
	timer_button.pressed.connect(_toggle_timer)
	(get_node("%ApproveButton") as Button).pressed.connect(func(): request_action("approve_action", {"approved": true}))
	(get_node("%ReturnButton") as Button).pressed.connect(func(): request_action("approve_action", {"approved": false}))
	pending_resolution_button.pressed.connect(func():
		if feature_screens != null:
			feature_screens.show("river")
	)
	begin_campaign_button.pressed.connect(_confirm_begin_campaign)
	(get_node("%OpenTeamTrackButton") as Button).pressed.connect(_open_feature.bind("team_track"))
	(get_node("%PlanActionButton") as Button).pressed.connect(_open_feature.bind("actions"))
	submit_action_button.pressed.connect(_confirm_submit_action)
	pass_move_button.pressed.connect(_confirm_pass_move)
	for channel in chat_channel_buttons.keys():
		var button: Button = chat_channel_buttons[channel]
		button.pressed.connect(_set_chat_channel.bind(channel))
	chat_input.text_submitted.connect(func(_text: String): _send_chat())
	(get_node("%SendChatButton") as Button).pressed.connect(_send_chat)
	_connect_dice_button("D6Button", 6, 1, "D6")
	_connect_dice_button("TwoD6Button", 6, 2, "2 D6")
	_connect_dice_button("D10Button", 10, 1, "D10")
	_connect_dice_button("D100Button", 100, 1, "D100")
	(get_node("%ReviewCampaignButton") as Button).pressed.connect(func(): game_over_root.visible = false)
	title_label.pressed.connect(_show_dashboard_menu)
	_update_chat_channel_buttons()


func _connect_dice_button(node_name: String, sides: int, count: int, label_text: String) -> void:
	var button := get_node("%%%s" % node_name) as Button
	button.pressed.connect(func(): request_action("roll_dice", {"sides": sides, "count": count, "label": label_text}))


func _update_from_snapshot() -> void:
	if turn_label == null:
		return
	turn_label.text = GameRules.turn_label(snapshot)
	countdown_label.text = GameUi.format_time(int(snapshot.get("TimeRemaining", GameRules.TIMER_SECONDS)))
	var overall_time := int(snapshot.get("OverallTime", 0))
	if overall_time <= 0 and bool(snapshot.get("TimerStarted", false)):
		overall_time = maxi(0, GameRules.TIMER_SECONDS - int(snapshot.get("TimeRemaining", GameRules.TIMER_SECONDS)))
	elapsed_label.text = GameUi.format_time(overall_time)
	if timer_button != null:
		timer_button.text = "Pause Timer" if bool(snapshot.get("TimerRunning", false)) else "Start Timer"
	if team_selector != null:
		var current_team := str(snapshot.get("ChangeTeam", "White"))
		for index in range(team_selector.item_count):
			if team_selector.get_item_text(index) == current_team:
				team_selector.select(index)
				break
	_update_points()
	_update_pending_action()
	_update_turn_controls()
	var last_roll := str(snapshot.get("LastRollSummary", ""))
	if not last_roll.is_empty():
		dice_result_label.text = last_roll
	_update_game_over()


func _update_points() -> void:
	var resource_team := team_name
	if team_name == "White":
		resource_team = str(snapshot.get("ChangeTeam", "Blue"))
		if resource_team == "White":
			resource_team = "Blue"
		point_team_label.text = "%s RESOURCES" % resource_team.to_upper()
	var prefix := "Iran" if resource_team == "Red" else "Isreal"
	for point_name in ["IP", "MP", "PP"]:
		var label: Label = point_labels.get(point_name)
		if label != null:
			label.text = str(int(snapshot.get("%s%s" % [prefix, point_name], 0)))


func _update_pending_action() -> void:
	var is_pending := bool(snapshot.get("ActionPending", false))
	var action_team := str(snapshot.get("ActionTeam", ""))
	var pending_card_value = snapshot.get("PendingCard", {})
	var pending_card: Dictionary = pending_card_value if pending_card_value is Dictionary else {}
	var card_waiting := not pending_card.is_empty() and str(pending_card.get("resolving_team", "")) == team_name
	if team_name == "White":
		pending_panel.visible = is_pending
		pending_label.text = "%s submitted an action" % action_team
	else:
		pending_panel.visible = (is_pending and action_team == team_name) or card_waiting
		if card_waiting:
			pending_label.text = "%s requires your choice" % str(pending_card.get("title", "A rules resolution"))
		else:
			pending_label.text = "White is reviewing your action"
		if pending_resolution_button != null:
			pending_resolution_button.visible = card_waiting


func _update_turn_controls() -> void:
	var current_team := str(snapshot.get("ChangeTeam", "White"))
	var action_pending := bool(snapshot.get("ActionPending", false))
	var action_team := str(snapshot.get("ActionTeam", ""))
	var pending_value = snapshot.get("PendingCard", {})
	var has_pending_card := pending_value is Dictionary and not (pending_value as Dictionary).is_empty()
	var is_setup := int(snapshot.get("TurnDay", 0)) == 0
	var is_my_move := current_team == team_name

	if current_move_label != null:
		if is_my_move:
			current_move_label.text = "YOUR MOVE - %s TEAM" % team_name.to_upper()
		elif action_pending and current_team == "White":
			current_move_label.text = "WHITE REVIEWING %s ACTION" % action_team.to_upper()
		else:
			current_move_label.text = "%s TEAM TO ACT" % current_team.to_upper()
		current_move_label.add_theme_color_override("font_color", GameUi.team_color(current_team))

	if team_name == "White":
		if is_setup:
			turn_instruction_label.text = "Setup is active. Begin the campaign when all teams are ready."
		elif action_pending:
			turn_instruction_label.text = "Review %s's submitted action, then approve or return it." % action_team
		elif has_pending_card:
			turn_instruction_label.text = "A rules choice must be resolved before play continues."
		else:
			turn_instruction_label.text = "Monitoring %s's move." % current_team
		begin_campaign_button.visible = is_setup
		begin_campaign_button.disabled = not is_setup or action_pending or has_pending_card
		open_turn_screen_button.text = "Review Action" if action_pending else "Open Team Track"
		return

	if is_setup:
		turn_instruction_label.text = "Waiting for White to begin Day 1."
	elif action_pending and action_team == team_name:
		turn_instruction_label.text = "Your action was sent. Waiting for White's decision."
	elif has_pending_card:
		turn_instruction_label.text = "Resolve the active card choice before ending the move."
	elif is_my_move:
		turn_instruction_label.text = "Choose an action to submit, or pass this move."
	else:
		turn_instruction_label.text = "Waiting for %s to finish the move." % current_team

	var can_end_move := is_my_move and not is_setup and not action_pending and not has_pending_card
	submit_action_button.disabled = not can_end_move
	pass_move_button.disabled = not can_end_move
	open_turn_screen_button.disabled = is_setup or action_pending


func _confirm_begin_campaign() -> void:
	confirm_action(
		"BEGIN CAMPAIGN",
		"Start Day 1 - Morning with Blue taking the first move?",
		func(): request_action("change_turn", {"next": true})
	)


func _confirm_submit_action() -> void:
	confirm_action(
		"SUBMIT ACTION",
		"Send %s's planned action to White for review?" % team_name,
		func(): request_action("take_action", {"team": team_name})
	)


func _confirm_pass_move() -> void:
	confirm_action(
		"PASS MOVE",
		"Pass %s's current move without submitting an action?" % team_name,
		func(): request_action("pass", {"team": team_name})
	)


func _update_game_over() -> void:
	if not bool(snapshot.get("GameOver", false)):
		game_over_root.visible = false
		return
	var summary_value = snapshot.get("GameOverSummary", {})
	var summary: Dictionary = summary_value if summary_value is Dictionary else {}
	game_over_label.text = "%s wins\n%s" % [str(summary.get("winner", "Draw")), str(summary.get("reason", "Campaign complete."))]
	game_over_root.visible = true


func _request_turn_change(next: bool) -> void:
	request_action("change_turn", {"next": next})


func _request_day_change(next: bool) -> void:
	request_action("change_day", {"next": next})


func _on_team_selector_changed(index: int) -> void:
	if team_selector == null:
		return
	request_action("set_team", {"team": team_selector.get_item_text(index), "next_move": false})


func _toggle_timer() -> void:
	request_action("start_timer", {"running": not bool(snapshot.get("TimerRunning", false))})


func _set_chat_channel(channel: String) -> void:
	chat_channel = channel
	_update_chat_channel_buttons()
	_refresh_chat()


func _update_chat_channel_buttons() -> void:
	if chat_channel_label != null:
		chat_channel_label.text = "%s CHAT" % ("PUBLIC" if chat_channel == "Announcement" else chat_channel.to_upper())
	for channel in chat_channel_buttons.keys():
		var button: Button = chat_channel_buttons[channel]
		button.button_pressed = str(channel) == chat_channel


func _send_chat() -> void:
	var message := chat_input.text.strip_edges()
	if message.is_empty():
		return
	if game_server == null:
		show_status("Chat requires a server connection.", false)
		return
	game_server.send_chat_message(chat_channel, message)
	chat_input.clear()


func _refresh_chat() -> void:
	if chat_history_label == null:
		return
	var history: Array = []
	if game_server != null and game_server.has_method("get_chat_history"):
		history = game_server.get_chat_history()
	var lines: Array[String] = []
	for raw_entry in history:
		if not raw_entry is Dictionary:
			continue
		var entry := raw_entry as Dictionary
		var channel := str(entry.get("channel", "Announcement"))
		if team_name == "White":
			if channel != chat_channel:
				continue
		elif channel != "Announcement" and channel != team_name:
			continue
		lines.append("%s: %s" % [str(entry.get("sender_name", "Player")), str(entry.get("message", ""))])
	chat_history_label.text = "\n".join(lines)
	chat_history_label.scroll_to_line(maxi(0, lines.size() - 1))


func _open_feature(screen_name: String) -> void:
	if screen_name == "quit":
		_show_quit_dialog()
		return
	if feature_screens != null:
		feature_screens.show(screen_name)


func begin_overlay(screen_title: String) -> VBoxContainer:
	close_overlay()
	overlay_root = Control.new()
	overlay_root.name = "FeatureOverlay"
	overlay_root.z_index = 200
	overlay_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay_root)

	var shade := ColorRect.new()
	shade.color = Color(0.005, 0.012, 0.007, 0.66)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay_root.add_child(shade)
	var panel := GameUi.panel(0.97, team_accent)
	GameUi.place(panel, 0.018, 0.018, 0.982, 0.995)
	overlay_root.add_child(panel)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 10)
	panel.add_child(outer)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 16)
	outer.add_child(header)
	var back := GameUi.button("<", Vector2(80, 54), team_accent)
	back.tooltip_text = "Back to team menu"
	back.add_theme_font_size_override("font_size", 34)
	back.pressed.connect(close_overlay)
	header.add_child(back)
	var heading := GameUi.title(screen_title, team_accent, 48)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(heading)
	var team_badge := GameUi.label("%s TEAM" % team_name.to_upper(), 24, HORIZONTAL_ALIGNMENT_RIGHT)
	team_badge.add_theme_color_override("font_color", team_accent)
	team_badge.custom_minimum_size = Vector2(220, 0)
	header.add_child(team_badge)
	outer.add_child(GameUi.separator())
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	outer.add_child(scroll)
	var content := VBoxContainer.new()
	content.name = "FeatureContent"
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 15)
	scroll.add_child(content)
	return content


func close_overlay() -> void:
	if overlay_root != null and is_instance_valid(overlay_root):
		overlay_root.queue_free()
	overlay_root = null
	if feature_screens != null:
		feature_screens.current_screen = ""


func confirm_action(title: String, message: String, confirmed: Callable) -> void:
	close_modal()
	modal_root = Control.new()
	modal_root.name = "ConfirmationModal"
	modal_root.z_index = 400
	modal_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	modal_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(modal_root)
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.68)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	modal_root.add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	modal_root.add_child(center)
	var panel := GameUi.panel(0.99, team_accent)
	var message_lines := message.count("\n") + 1
	panel.custom_minimum_size = Vector2(760, minf(660.0, 300.0 + float(message_lines) * 26.0))
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 20)
	panel.add_child(box)
	box.add_child(GameUi.title(title, team_accent, 40))
	var body := GameUi.label(message, 26, HORIZONTAL_ALIGNMENT_CENTER)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(body)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 18)
	box.add_child(row)
	var cancel := GameUi.button("Cancel", Vector2(180, 55), team_accent)
	cancel.pressed.connect(close_modal)
	row.add_child(cancel)
	var accept := GameUi.button("Confirm", Vector2(180, 55), team_accent)
	accept.pressed.connect(func():
		close_modal()
		confirmed.call()
	)
	row.add_child(accept)


func close_modal() -> void:
	if modal_root != null and is_instance_valid(modal_root):
		modal_root.queue_free()
	modal_root = null


func request_action(action_name: String, args: Dictionary = {}) -> Dictionary:
	if game_server != null and game_server.has_method("has_active_session") and game_server.has_active_session():
		if multiplayer.multiplayer_peer == null or multiplayer.is_server():
			var result: Dictionary = game_server.request_game_action_locally(action_name, args)
			show_status(str(result.get("message", "Game updated.")), bool(result.get("ok", false)))
			return result
		game_server.request_game_action.rpc_id(1, action_name, args)
		show_status("Sending request...", true)
		return {"ok": true, "message": "Request sent."}

	var preview_result := GameRules.apply_action(snapshot, action_name, args)
	if bool(preview_result.get("ok", false)):
		snapshot = (preview_result.get("snapshot", snapshot) as Dictionary).duplicate(true)
		_update_from_snapshot()
		if feature_screens != null:
			feature_screens.refresh_from_state()
	show_status("Offline preview: %s" % str(preview_result.get("message", "Action complete.")), bool(preview_result.get("ok", false)))
	return preview_result


func request_save_list() -> void:
	if game_server == null:
		return
	if multiplayer.multiplayer_peer == null or multiplayer.is_server():
		saved_games = game_server.get_saved_games()
		_on_save_list_changed(saved_games)
	else:
		game_server.request_save_list.rpc_id(1)


func save_current_snapshot() -> void:
	if game_server == null or not game_server.has_active_session():
		show_status("No server campaign is active.", false)
		return
	if multiplayer.multiplayer_peer == null or multiplayer.is_server():
		var ok: bool = game_server.save_snapshot(snapshot, "Campaign saved on server.")
		show_status("Campaign saved on server." if ok else "Save failed.", ok)
	else:
		game_server.request_save_snapshot.rpc_id(1, snapshot, "Campaign saved on server.")


func load_server_session(save_name: String) -> void:
	if game_server == null:
		show_status("Server is unavailable.", false)
		return
	if multiplayer.multiplayer_peer == null or multiplayer.is_server():
		var ok: bool = game_server.load_game_session(save_name)
		show_status("Campaign loaded." if ok else "Load failed.", ok)
	else:
		game_server.request_load_game_session.rpc_id(1, save_name)


func show_status(message: String, success: bool = true) -> void:
	if status_label == null:
		return
	status_label.text = message
	status_label.add_theme_color_override("font_color", GameUi.CREAM if success else Color("ff9c8f"))
	var status_panel := get_node_or_null("%StatusPanel") as Control
	if status_panel != null:
		status_panel.visible = true
	var displayed_message := message
	await get_tree().create_timer(3.5).timeout
	if status_panel != null and is_instance_valid(status_panel) and status_label.text == displayed_message:
		status_panel.visible = false


func _show_dashboard_menu() -> void:
	close_modal()
	var box := _begin_command_modal("MAIN MENU", "Campaign tools are kept here so the map stays open and uncluttered.")
	_add_command_button(box, "Campaign Controls", func():
		close_modal()
		_show_campaign_controls()
	)
	_add_command_button(box, "Dice Roller", func():
		close_modal()
		_show_dice_controls()
	)
	_add_command_button(box, "Leave Campaign", func():
		close_modal()
		_show_quit_dialog()
	)
	_add_command_button(box, "Close", close_modal)


func _show_campaign_controls() -> void:
	close_modal()
	var box := _begin_command_modal("CAMPAIGN CONTROLS", turn_instruction_label.text)
	if team_name == "White":
		var day_row := HBoxContainer.new()
		day_row.alignment = BoxContainer.ALIGNMENT_CENTER
		day_row.add_theme_constant_override("separation", 12)
		box.add_child(day_row)
		_add_command_button(day_row, "Prev Turn", func(): _request_turn_change(false), Vector2(145, 54))
		_add_command_button(day_row, "Prev Day", func(): _request_day_change(false), Vector2(145, 54))
		_add_command_button(day_row, "Next Day", func(): _request_day_change(true), Vector2(145, 54))
		_add_command_button(day_row, "Next Turn", func(): _request_turn_change(true), Vector2(145, 54))
		var team_row := HBoxContainer.new()
		team_row.alignment = BoxContainer.ALIGNMENT_CENTER
		team_row.add_theme_constant_override("separation", 12)
		box.add_child(team_row)
		for target_team in ["White", "Red", "Blue"]:
			_add_command_button(team_row, target_team, _request_team_selection.bind(target_team), Vector2(145, 54))
		_add_command_button(box, timer_button.text, _toggle_timer)
		if begin_campaign_button.visible:
			_add_command_button(box, "Begin Campaign", _confirm_begin_campaign)
		_add_command_button(box, "Open Team Track", func():
			close_modal()
			_open_feature("team_track")
		)
	else:
		_add_command_button(box, "Plan Action", func():
			close_modal()
			_open_feature("actions")
		)
		var submit := _add_command_button(box, "Submit Action", _confirm_submit_action)
		submit.disabled = submit_action_button.disabled
		var pass_button := _add_command_button(box, "Pass Move", _confirm_pass_move)
		pass_button.disabled = pass_move_button.disabled
	_add_command_button(box, "Back", func():
		close_modal()
		_show_dashboard_menu()
	)


func _show_dice_controls() -> void:
	close_modal()
	var result_text := dice_result_label.text if dice_result_label != null else "Roll dice"
	var box := _begin_command_modal("DICE ROLLER", result_text)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	box.add_child(grid)
	_add_command_button(grid, "D6", func(): request_action("roll_dice", {"sides": 6, "count": 1, "label": "D6"}), Vector2(180, 58))
	_add_command_button(grid, "2 D6", func(): request_action("roll_dice", {"sides": 6, "count": 2, "label": "2 D6"}), Vector2(180, 58))
	_add_command_button(grid, "D10", func(): request_action("roll_dice", {"sides": 10, "count": 1, "label": "D10"}), Vector2(180, 58))
	_add_command_button(grid, "D100", func(): request_action("roll_dice", {"sides": 100, "count": 1, "label": "D100"}), Vector2(180, 58))
	_add_command_button(box, "Back", func():
		close_modal()
		_show_dashboard_menu()
	)


func _begin_command_modal(title: String, message: String) -> VBoxContainer:
	modal_root = Control.new()
	modal_root.name = "CommandModal"
	modal_root.z_index = 400
	modal_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	modal_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(modal_root)
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.68)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	modal_root.add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	modal_root.add_child(center)
	var panel := GameUi.panel(0.98, GameUi.GOLD, 8)
	panel.custom_minimum_size = Vector2(720, 420)
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 16)
	panel.add_child(box)
	var heading := GameUi.title(title, team_accent, 40)
	heading.add_theme_font_override("font", GAME_BUTTON_FONT)
	box.add_child(heading)
	var body := GameUi.label(message, 23, HORIZONTAL_ALIGNMENT_CENTER)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(body)
	return box


func _add_command_button(parent: Control, text_value: String, callback: Callable, minimum_size: Vector2 = Vector2(340, 58)) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = minimum_size
	_style_friend_button(button, 28)
	button.pressed.connect(callback)
	parent.add_child(button)
	return button


func _request_team_selection(target_team: String) -> void:
	request_action("set_team", {"team": target_team, "next_move": false})


func _show_quit_dialog() -> void:
	close_modal()
	confirm_action("LEAVE CAMPAIGN", "Return to the game selection screen?", func(): get_tree().change_scene_to_file(MODE_SELECT_SCENE))


func _on_session_changed(_session_info: Dictionary, save_data: Dictionary) -> void:
	if save_data.is_empty():
		return
	snapshot = save_data.duplicate(true)
	_update_from_snapshot()
	if feature_screens != null:
		feature_screens.refresh_from_state()


func _on_request_completed(success: bool, message: String) -> void:
	show_status(message, success)


func _on_chat_message(_message_data: Dictionary) -> void:
	_refresh_chat()


func _on_save_list_changed(new_saved_games: Array) -> void:
	saved_games = new_saved_games.duplicate(true)
	if feature_screens != null:
		feature_screens.refresh_save_list()


func _on_server_error(message: String) -> void:
	show_status(message, false)
