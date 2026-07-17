extends Control

const MODE_SELECT_SCENE: String = "res://UI/MainScenes/ModeSelect.tscn"
const CONNECT_SCENE: String = "res://UI/MainScenes/Connect.tscn"
const TEAM_SCENES: Dictionary = {
	"White": "res://UI/GameScenes/WhiteTeam.tscn",
	"Blue": "res://UI/GameScenes/BlueTeam.tscn",
	"Red": "res://UI/GameScenes/RedTeam.tscn"
}
const TEAMS: Array[String] = ["White", "Blue", "Red"]

@export var status_label: Label
@export var white_button: BaseButton
@export var blue_button: BaseButton
@export var red_button: BaseButton
@export var back_button: BaseButton
@export var confirmation_overlay: Control
@export var confirmation_message: Label
@export var confirm_button: BaseButton
@export var cancel_button: BaseButton

var team_buttons: Dictionary = {}
var team_crosses: Dictionary = {}
var pending_team_name: String = ""
var waiting_for_selection_response: bool = false
var changing_to_game: bool = false
var game_server


func _ready() -> void:
	_resolve_ui_references()
	_build_team_maps()
	game_server = get_node_or_null("/root/GameServer")

	if white_button != null:
		white_button.pressed.connect(_select_team.bind("White"))
	if blue_button != null:
		blue_button.pressed.connect(_select_team.bind("Blue"))
	if red_button != null:
		red_button.pressed.connect(_select_team.bind("Red"))
	if back_button != null:
		back_button.pressed.connect(_on_back_pressed)
	if confirm_button != null:
		confirm_button.pressed.connect(_on_confirm_pressed)
	if cancel_button != null:
		cancel_button.pressed.connect(_hide_confirmation)
	if not multiplayer.server_disconnected.is_connected(_on_server_disconnected):
		multiplayer.server_disconnected.connect(_on_server_disconnected)

	_hide_confirmation()

	if game_server == null:
		if status_label != null:
			status_label.text = "Game server state is not available."
		return

	if not game_server.teams_changed.is_connected(_on_teams_changed):
		game_server.teams_changed.connect(_on_teams_changed)
	if not game_server.team_selection_rejected.is_connected(_on_team_selection_rejected):
		game_server.team_selection_rejected.connect(_on_team_selection_rejected)
	if not game_server.team_selection_confirmed.is_connected(_on_team_selection_confirmed):
		game_server.team_selection_confirmed.connect(_on_team_selection_confirmed)

	_on_teams_changed(game_server.selected_teams)


func _resolve_ui_references() -> void:
	if status_label == null:
		status_label = get_node_or_null("CanvasLayer/VBoxContainer/CenterContainer2/TeamPanel/PanelMargin/PanelVBox/StatusLabel") as Label
	if white_button == null:
		white_button = get_node_or_null("CanvasLayer/VBoxContainer/CenterContainer2/TeamPanel/PanelMargin/PanelVBox/ButtonRow/WhiteButton") as BaseButton
	if blue_button == null:
		blue_button = get_node_or_null("CanvasLayer/VBoxContainer/CenterContainer2/TeamPanel/PanelMargin/PanelVBox/ButtonRow/BlueButton") as BaseButton
	if red_button == null:
		red_button = get_node_or_null("CanvasLayer/VBoxContainer/CenterContainer2/TeamPanel/PanelMargin/PanelVBox/ButtonRow/RedButton") as BaseButton
	if back_button == null:
		back_button = get_node_or_null("CanvasLayer/VBoxContainer/TopSpacer/BackButton") as BaseButton
	if confirmation_overlay == null:
		confirmation_overlay = get_node_or_null("CanvasLayer/ConfirmOverlay") as Control
	if confirmation_message == null:
		confirmation_message = get_node_or_null("CanvasLayer/ConfirmOverlay/CenterContainer/ConfirmPanel/PanelMargin/PanelVBox/MessageLabel") as Label
	if confirm_button == null:
		confirm_button = get_node_or_null("CanvasLayer/ConfirmOverlay/CenterContainer/ConfirmPanel/PanelMargin/PanelVBox/ButtonRow/ConfirmButton") as BaseButton
	if cancel_button == null:
		cancel_button = get_node_or_null("CanvasLayer/ConfirmOverlay/CenterContainer/ConfirmPanel/PanelMargin/PanelVBox/ButtonRow/CancelButton") as BaseButton


func _build_team_maps() -> void:
	team_buttons = {
		"White": white_button,
		"Blue": blue_button,
		"Red": red_button
	}
	team_crosses = {
		"White": white_button.get_node_or_null("TakenCross") if white_button != null else null,
		"Blue": blue_button.get_node_or_null("TakenCross") if blue_button != null else null,
		"Red": red_button.get_node_or_null("TakenCross") if red_button != null else null
	}


func _select_team(team_name: String) -> void:
	if multiplayer.multiplayer_peer == null:
		if status_label != null:
			status_label.text = "Not connected to server."
		return

	_show_confirmation(team_name)


func _show_confirmation(team_name: String) -> void:
	pending_team_name = team_name

	if confirmation_message != null:
		confirmation_message.text = "Are you sure you want to choose %s?" % team_name
	if confirm_button != null:
		confirm_button.text = "Choose %s" % team_name
	if confirmation_overlay != null:
		confirmation_overlay.visible = true


func _hide_confirmation() -> void:
	pending_team_name = ""
	if confirmation_overlay != null:
		confirmation_overlay.visible = false


func _on_confirm_pressed() -> void:
	if pending_team_name.is_empty():
		_hide_confirmation()
		return

	if status_label != null:
		status_label.text = "Choosing %s..." % pending_team_name

	waiting_for_selection_response = true
	var team_name := pending_team_name
	_hide_confirmation()
	if game_server != null:
		game_server.request_team_selection.rpc_id(1, team_name)


func _on_teams_changed(selected_teams: Dictionary) -> void:
	var peer_id := multiplayer.get_unique_id() if multiplayer.multiplayer_peer != null else 0
	var own_team := str(selected_teams.get(str(peer_id), ""))

	for team_name in TEAMS:
		var button := team_buttons.get(team_name) as BaseButton
		var cross := team_crosses.get(team_name) as Control
		var taken_by_other: bool = false
		if game_server != null:
			taken_by_other = game_server.is_team_taken_by_other(team_name, peer_id)

		if cross != null:
			cross.visible = taken_by_other
			cross.queue_redraw()

		if button != null:
			button.disabled = taken_by_other
			button.tooltip_text = "%s team is already taken." % team_name if taken_by_other else ""

	if own_team != "" and status_label != null:
		status_label.text = "%s selected." % own_team
	if own_team != "":
		_go_to_game(own_team)


func _on_team_selection_confirmed(team_name: String) -> void:
	_go_to_game(team_name)


func _on_team_selection_rejected(team_name: String, message: String) -> void:
	waiting_for_selection_response = false
	if status_label != null:
		status_label.text = message if not message.is_empty() else "%s is not available." % team_name


func _on_back_pressed() -> void:
	if game_server != null:
		game_server.clear_pending_client_session_action()
	get_tree().change_scene_to_file(MODE_SELECT_SCENE)


func _on_server_disconnected() -> void:
	waiting_for_selection_response = false
	if status_label != null:
		status_label.text = "Server disconnected."

	await get_tree().create_timer(1.0).timeout

	if is_inside_tree():
		get_tree().change_scene_to_file(CONNECT_SCENE)


func _go_to_game(team_name: String) -> void:
	if changing_to_game:
		return

	changing_to_game = true
	waiting_for_selection_response = false
	if game_server != null and game_server.has_method("set_local_team"):
		game_server.call("set_local_team", team_name)
	if status_label != null:
		status_label.text = "%s selected." % team_name

	call_deferred("_change_to_game_scene", team_name)


func _change_to_game_scene(team_name: String) -> void:
	var game_scene := str(TEAM_SCENES.get(team_name, ""))
	if game_scene.is_empty():
		changing_to_game = false
		if status_label != null:
			status_label.text = "Unknown team: %s" % team_name
		push_error("No game scene registered for team: %s" % team_name)
		return

	var error := get_tree().change_scene_to_file(game_scene)
	if error != OK:
		changing_to_game = false
		if status_label != null:
			status_label.text = "Could not open game screen. Error code: %d" % error
		push_error("Could not open game screen: %s" % game_scene)
