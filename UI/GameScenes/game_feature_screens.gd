extends RefCounted
class_name GameFeatureScreens

const GameRules = preload("res://server/game_rules.gd")
const GameUi = preload("res://UI/GameScenes/game_ui.gd")

const COUNTRIES: Array[Dictionary] = [
	{"code": "IR", "name": "Iran", "flag": "iran.jpg", "home": "Red"},
	{"code": "IL", "name": "Israel", "flag": "israel.jpg", "home": "Blue"},
	{"code": "JO", "name": "Jordan", "flag": "jordan.jpg"},
	{"code": "PRC", "name": "PRC", "flag": "prc.jpg"},
	{"code": "RU", "name": "Russia", "flag": "russia.jpg"},
	{"code": "UN", "name": "UN", "flag": "un.jpg"},
	{"code": "TR", "name": "Turkey", "flag": "turkey.jpg"},
	{"code": "SA", "name": "Saudi Arabia", "flag": "saudi_arabia.jpg"},
	{"code": "US", "name": "US & Iraq", "flag": "us_iraq.jpg"}
]
const COUNTRY_NAMES := {
	1: "Israel", 2: "PRC", 3: "Russia", 4: "Saudi Arabia", 5: "UN",
	6: "Jordan", 7: "Turkey", 8: "US & Iraq", 9: "Iran"
}
const BLUE_ACTION_TYPES: Array[String] = ["Airstrike", "Special Warfare"]
const RED_ACTION_TYPES: Array[String] = ["Ballistic Missile", "Terror Attack", "Reposition Air Defense", "Close Strait"]
const SPECIAL_MISSIONS: Array[String] = ["Civil Economic", "Weaken Air Defenses", "Spot", "Attack Undamaged Building", "Finish Damaged Building"]
const RED_AIRCRAFT_MISSIONS: Array[String] = ["Ready", "Alert", "Patrol", "Stand Down", "Rebasing"]
const BLUE_AIRCRAFT_MISSIONS: Array[String] = ["Ready", "Fragged", "In Flight 1", "In Flight 2", "Resting"]
const LOCATIONS: Array[String] = ["Home", "TAB 1", "TAB 2", "TAB 3", "Forward Base", "Deployed"]

var host
var current_screen: String = ""
var political_draft: Dictionary = {}
var river_team: String = ""
var refresh_queued: bool = false
var last_state_signature: int = 0
var rebuild_count: int = 0


func _init(game_host) -> void:
	host = game_host
	river_team = "Red" if host.team_name == "White" else host.team_name


func show(screen_name: String) -> void:
	match screen_name:
		"log":
			_show_log()
		"political":
			_show_political()
		"actions":
			_show_actions()
		"targets":
			_show_targets()
		"aircraft":
			_show_aircraft()
		"upgrades":
			_show_upgrades()
		"river", "send_river":
			_show_river()
		"team_track":
			_show_team_track()
		"save":
			_show_save()
		"load":
			_show_load()
		_:
			host.show_status("That screen is not available.", false)
			return
	current_screen = screen_name
	last_state_signature = _state_signature(screen_name)


func refresh_from_state() -> void:
	if current_screen.is_empty() or host.overlay_root == null or refresh_queued:
		return
	var next_signature := _state_signature(current_screen)
	if next_signature == last_state_signature:
		return
	refresh_queued = true
	_reopen_deferred.call_deferred(current_screen)


func _reopen_deferred(screen_name: String) -> void:
	refresh_queued = false
	if current_screen != screen_name or host.overlay_root == null:
		return
	rebuild_count += 1
	show(screen_name)


func _state_signature(screen_name: String) -> int:
	var state: Dictionary = host.snapshot
	var payload: Dictionary = {
		"screen": screen_name,
		"day": state.get("TurnDay", 0),
		"turn": state.get("TurnTime", 0),
		"move": state.get("Move", 0),
		"team": state.get("ChangeTeam", "White"),
		"game_over": state.get("GameOver", false)
	}
	match screen_name:
		"log":
			payload["log"] = state.get("ActionLog", [])
		"political":
			payload["track"] = state.get("PoliticalTrack", {})
			payload["points"] = _point_signature(state)
		"river", "send_river":
			payload["cards"] = {
				"blue_deck": state.get("_blueCardDeck", ""),
				"blue_river": state.get("_blueCardRiver", ""),
				"blue_discard": state.get("_blueCardDiscard", ""),
				"red_deck": state.get("_redCardDeck", ""),
				"red_river": state.get("_redCardRiver", ""),
				"red_discard": state.get("_redCardDiscard", ""),
				"last_card": state.get("LastPlayedCard", 0),
				"last_roll": state.get("LastRollSummary", ""),
				"pending": state.get("PendingCard", {}),
				"reveal": state.get("RiverRevealForTeam", ""),
				"locks": state.get("TrackLocks", {})
			}
		"upgrades":
			payload["selected"] = state.get("SelectedUpgrades", {})
			payload["available"] = state.get("UpgradePoints", {})
			payload["review"] = [state.get("BlueUpgrades", ""), state.get("RedUpgrades", "")]
		"actions":
			payload["planned"] = state.get("PlannedActions", [])
			payload["pending"] = [state.get("ActionPending", false), state.get("ActionTeam", "")]
			payload["points"] = _point_signature(state)
			payload["conflict"] = state.get("ConflictStarted", false)
			payload["strait"] = [state.get("StraitStatus", "Open"), state.get("StraitCooldown", 0)]
		"targets":
			payload["targets"] = state.get("Targets", {})
			payload["victory_levels"] = state.get("TargetVictoryLevels", {})
			payload["strike_history"] = state.get("AirstrikeHistory", [])
		"aircraft":
			payload["red_aircraft"] = state.get("RedAircraft", [])
			payload["blue_aircraft"] = state.get("BlueAircraft", [])
			payload["aircraft_events"] = state.get("AircraftEvents", [])
		"team_track":
			payload["points"] = _point_signature(state)
			payload["aircraft"] = [state.get("RedAircraft", []), state.get("BlueAircraft", [])]
			payload["upgrades"] = state.get("SelectedUpgrades", {})
			payload["rivers"] = [state.get("_redCardRiver", ""), state.get("_blueCardRiver", "")]
			payload["planned"] = state.get("PlannedActions", [])
		"load":
			payload["saved_games"] = host.saved_games
		"save":
			if host.game_server != null and host.game_server.has_method("get_session_info"):
				payload["session"] = host.game_server.get_session_info()
	return hash(payload)


func _point_signature(state: Dictionary) -> Array:
	return [
		state.get("IranIP", 0), state.get("IranMP", 0), state.get("IranPP", 0),
		state.get("IsrealIP", 0), state.get("IsrealMP", 0), state.get("IsrealPP", 0)
	]


func refresh_save_list() -> void:
	if current_screen == "load" and host.overlay_root != null:
		_reopen_deferred.call_deferred("load")


func _show_log() -> void:
	var content: VBoxContainer = host.begin_overlay("LOG OF ACTIONS")
	var toolbar := HBoxContainer.new()
	toolbar.add_theme_constant_override("separation", 12)
	content.add_child(toolbar)
	var count_label := GameUi.label("%d entries" % _action_log().size(), 23)
	count_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	toolbar.add_child(count_label)
	if host.team_name == "White":
		var clear := GameUi.button("Clear Log", Vector2(170, 46), host.team_accent)
		clear.add_theme_font_size_override("font_size", 21)
		clear.pressed.connect(func(): host.confirm_action("CLEAR LOG", "Remove every campaign log entry?", func(): host.request_action("clear_log")))
		toolbar.add_child(clear)
	var panel := GameUi.panel(0.82, host.team_accent)
	panel.custom_minimum_size = Vector2(0, 760)
	content.add_child(panel)
	var log_text := RichTextLabel.new()
	log_text.bbcode_enabled = false
	log_text.fit_content = true
	log_text.add_theme_font_size_override("normal_font_size", 26)
	log_text.add_theme_color_override("default_color", GameUi.CREAM)
	var lines: Array[String] = []
	var entries := _action_log()
	if entries.is_empty():
		lines.append("No campaign actions recorded.")
	else:
		for index in range(entries.size() - 1, -1, -1):
			lines.append("%03d   %s" % [index + 1, str(entries[index])])
	log_text.text = "\n\n".join(lines)
	panel.add_child(log_text)


func _action_log() -> Array:
	var raw = host.snapshot.get("ActionLog", [])
	return raw if raw is Array else []


func _show_political() -> void:
	var editable: bool = host.team_name == "White"
	political_draft = _clean_track(host.snapshot.get("PoliticalTrack", {}))
	var content: VBoxContainer = host.begin_overlay("POLITICAL TRACK")
	var toolbar := HBoxContainer.new()
	toolbar.add_theme_constant_override("separation", 12)
	content.add_child(toolbar)
	var phase := GameUi.label(GameRules.turn_label(host.snapshot), 25)
	phase.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	toolbar.add_child(phase)
	if editable:
		var generate := GameUi.button("Generate Points", Vector2(220, 50), host.team_accent)
		generate.add_theme_font_size_override("font_size", 22)
		generate.pressed.connect(_submit_political.bind(true))
		toolbar.add_child(generate)
		var submit := GameUi.button("Submit Track", Vector2(200, 50), host.team_accent)
		submit.add_theme_font_size_override("font_size", 22)
		submit.pressed.connect(_submit_political.bind(false))
		toolbar.add_child(submit)

	var flow := HFlowContainer.new()
	flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	flow.add_theme_constant_override("h_separation", 24)
	flow.add_theme_constant_override("v_separation", 24)
	content.add_child(flow)
	for country in COUNTRIES:
		flow.add_child(_political_card(country, editable))


func _political_card(country: Dictionary, editable: bool) -> PanelContainer:
	var code := str(country.get("code", ""))
	var value := int(political_draft.get(code, 0))
	var status := _political_status(value, str(country.get("home", "")))
	var card := GameUi.panel(0.9, _political_color(value, str(country.get("home", ""))))
	card.custom_minimum_size = Vector2(300, 325 if editable else 280)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 7)
	card.add_child(box)
	var flag_path := "res://Art/PoliticalTrackFlags/%s" % str(country.get("flag", ""))
	box.add_child(GameUi.texture(flag_path, Vector2(210, 115), TextureRect.STRETCH_KEEP_ASPECT_CENTERED))
	var name_label := GameUi.label(str(country.get("name", code)), 29, HORIZONTAL_ALIGNMENT_CENTER)
	box.add_child(name_label)
	var value_label := GameUi.label(str(value), 34, HORIZONTAL_ALIGNMENT_CENTER)
	box.add_child(value_label)
	var status_label := GameUi.label(status, 22, HORIZONTAL_ALIGNMENT_CENTER)
	status_label.add_theme_color_override("font_color", _political_color(value, str(country.get("home", ""))))
	box.add_child(status_label)
	if editable:
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 14)
		box.add_child(row)
		var minus := GameUi.button("−", Vector2(70, 45), host.team_accent)
		minus.tooltip_text = "Move one space toward Red"
		minus.add_theme_font_size_override("font_size", 26)
		minus.pressed.connect(_adjust_political.bind(country, -1, value_label, status_label, card))
		row.add_child(minus)
		var plus := GameUi.button("+", Vector2(70, 45), host.team_accent)
		plus.tooltip_text = "Move one space toward Blue"
		plus.add_theme_font_size_override("font_size", 26)
		plus.pressed.connect(_adjust_political.bind(country, 1, value_label, status_label, card))
		row.add_child(plus)
	return card


func _adjust_political(country: Dictionary, amount: int, value_label: Label, status_label: Label, card: PanelContainer) -> void:
	var code := str(country.get("code", ""))
	var next_value := clampi(int(political_draft.get(code, 0)) + amount, -10, 10)
	political_draft[code] = next_value
	var home := str(country.get("home", ""))
	value_label.text = str(next_value)
	status_label.text = _political_status(next_value, home)
	var color := _political_color(next_value, home)
	status_label.add_theme_color_override("font_color", color)
	card.add_theme_stylebox_override("panel", GameUi.panel_style(0.9, color))


func _submit_political(generate_points: bool) -> void:
	if generate_points:
		host.confirm_action("GENERATE POLITICAL POINTS", _political_generation_message(), func():
			host.request_action("set_political_track", {"track": political_draft, "generate_points": true})
		)
		return
	host.confirm_action("SUBMIT POLITICAL TRACK", "Save these political-track positions without changing team resources?", func():
		host.request_action("set_political_track", {"track": political_draft, "generate_points": false})
	)


func _political_generation_message() -> String:
	var totals := GameRules.political_point_totals(political_draft)
	var blue: Dictionary = totals.get("Blue", {})
	var red: Dictionary = totals.get("Red", {})
	var lines: Array[String] = [
		"The server will replace the current resource totals with:",
		"BLUE   IP %d   MP %d   PP %d" % [int(blue.get("IP", 0)), int(blue.get("MP", 0)), int(blue.get("PP", 0))],
		"RED     IP %d   MP %d   PP %d" % [int(red.get("IP", 0)), int(red.get("MP", 0)), int(red.get("PP", 0))],
		"",
		"Active political situations:"
	]
	for entry_value in GameRules.political_point_breakdown(political_draft):
		var entry: Dictionary = entry_value
		var contributions: Array[String] = []
		for team_name in ["Blue", "Red"]:
			var points: Dictionary = entry.get(team_name, {})
			var point_parts: Array[String] = []
			for point_name in ["IP", "MP", "PP"]:
				var amount := int(points.get(point_name, 0))
				if amount != 0:
					point_parts.append("%s %d" % [point_name, amount])
			if not point_parts.is_empty():
				contributions.append("%s +%s" % [team_name, ", ".join(point_parts)])
		if not contributions.is_empty():
			lines.append("%s (%+d): %s" % [_country_name_for_code(str(entry.get("code", ""))), int(entry.get("position", 0)), " | ".join(contributions)])
	lines.append("")
	lines.append("Morning upkeep also preserves Night action gains and checks each side for a strategic event: D6, then D10 on a 6.")
	lines.append("Apply these server-authoritative totals now?")
	return "\n".join(lines)


func _country_name_for_code(code: String) -> String:
	for country in COUNTRIES:
		if str(country.get("code", "")) == code:
			return str(country.get("name", code))
	return code


func _clean_track(value) -> Dictionary:
	var clean: Dictionary = {}
	var source: Dictionary = value if value is Dictionary else {}
	for country in COUNTRIES:
		var code := str(country.get("code", ""))
		clean[code] = clampi(int(source.get(code, 0)), -10, 10)
	return clean


func _political_status(value: int, home_team: String = "") -> String:
	if value == 0 and not home_team.is_empty():
		return "No Status"
	var distance := absi(value)
	if distance == 0:
		return "Neutral"
	if distance <= 4:
		return "Cordial with %s" % ("Blue" if value > 0 else "Red")
	if distance <= 8:
		return "%s Supporter" % ("Blue" if value > 0 else "Red")
	return "%s Ally" % ("Blue" if value > 0 else "Red")


func _political_color(value: int, home_team: String = "") -> Color:
	if value > 0 or (value == 0 and home_team == "Blue"):
		return GameUi.BLUE
	if value < 0 or (value == 0 and home_team == "Red"):
		return GameUi.RED
	return GameUi.WHITE


func _show_river() -> void:
	var can_view_opponent: bool = str(host.snapshot.get("RiverRevealForTeam", "")) == host.team_name
	if host.team_name != "White" and river_team != host.team_name and not can_view_opponent:
		river_team = host.team_name
	var content: VBoxContainer = host.begin_overlay("%s RIVER" % river_team.to_upper())
	var toolbar := HBoxContainer.new()
	toolbar.add_theme_constant_override("separation", 11)
	content.add_child(toolbar)
	var deck_count := _card_list("deck", river_team).size()
	var discard_count := _card_list("discard", river_team).size()
	var deck_label := GameUi.label("Deck %d   Discard %d" % [deck_count, discard_count], 24)
	deck_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	toolbar.add_child(deck_label)
	if host.team_name == "White":
		for selectable_team in ["Red", "Blue"]:
			var team_button := GameUi.button(selectable_team, Vector2(110, 46), GameUi.team_color(selectable_team))
			team_button.add_theme_font_size_override("font_size", 21)
			team_button.pressed.connect(_switch_river.bind(selectable_team))
			toolbar.add_child(team_button)
		var draw := GameUi.button("Draw River", Vector2(165, 46), host.team_accent)
		draw.add_theme_font_size_override("font_size", 21)
		draw.pressed.connect(func(): host.request_action("draw_river", {"team": river_team}))
		toolbar.add_child(draw)
		var send := GameUi.button("Send Both", Vector2(160, 46), host.team_accent)
		send.add_theme_font_size_override("font_size", 21)
		send.pressed.connect(func(): host.confirm_action("SEND RIVERS", "Send seven cards to both combat teams?", func(): host.request_action("send_rivers")))
		toolbar.add_child(send)
	elif can_view_opponent:
		for selectable_team in [host.team_name, "Blue" if host.team_name == "Red" else "Red"]:
			var view_button := GameUi.button(selectable_team, Vector2(130, 46), GameUi.team_color(selectable_team))
			view_button.add_theme_font_size_override("font_size", 20)
			view_button.pressed.connect(_switch_river.bind(selectable_team))
			toolbar.add_child(view_button)

	var pending_panel := _river_pending_panel()
	if pending_panel != null:
		content.add_child(pending_panel)

	var river := _card_list("river", river_team)
	if river.is_empty():
		var empty_panel := GameUi.panel(0.82, GameUi.team_color(river_team))
		empty_panel.custom_minimum_size = Vector2(430, 520)
		content.add_child(empty_panel)
		var empty_box := VBoxContainer.new()
		empty_box.alignment = BoxContainer.ALIGNMENT_CENTER
		empty_box.add_theme_constant_override("separation", 18)
		empty_panel.add_child(empty_box)
		var back_path := "res://Art/Cards/red_card_back.jpg" if river_team == "Red" else "res://Art/Cards/blue_card_back.jpg"
		empty_box.add_child(GameUi.texture(back_path, Vector2(300, 400)))
		empty_box.add_child(GameUi.label("Waiting for White to send cards", 27, HORIZONTAL_ALIGNMENT_CENTER))
		return

	var flow := HFlowContainer.new()
	flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	flow.add_theme_constant_override("h_separation", 18)
	flow.add_theme_constant_override("v_separation", 20)
	content.add_child(flow)
	for card_index in range(river.size()):
		flow.add_child(_river_card(int(river[card_index]), card_index))


func _switch_river(next_team: String) -> void:
	river_team = next_team
	_show_river()
	current_screen = "river"


func _card_list(kind: String, for_team: String) -> Array:
	var prefix := "_redCard" if for_team == "Red" else "_blueCard"
	var key := "%s%s" % [prefix, kind.capitalize()]
	return GameRules.cards_from_string(str(host.snapshot.get(key, "")))


func _river_card(card_id: int, card_index: int) -> PanelContainer:
	var metadata := GameRules.card_metadata(card_id)
	var card := GameUi.panel(0.91, GameUi.team_color(river_team))
	card.custom_minimum_size = Vector2(288, 590)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 7)
	card.add_child(box)
	box.add_child(GameUi.texture("res://Art/Cards/card_%d.jpg" % card_id, Vector2(250, 350)))
	var name_label := GameUi.label(str(metadata.get("name", "Card %d" % card_id)), 24, HORIZONTAL_ALIGNMENT_CENTER)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.custom_minimum_size = Vector2(250, 55)
	box.add_child(name_label)
	var cost := "IP %s   MP %s   PP %s" % [str(metadata.get("iPCost", "0")), str(metadata.get("mPCost", "0")), str(metadata.get("pPCost", "0"))]
	box.add_child(GameUi.label(cost, 19, HORIZONTAL_ALIGNMENT_CENTER))
	var action_text := GameRules.action_description(int(metadata.get("action", 0)))
	var requirement_text := GameRules.requirement_description(int(metadata.get("requirement", 0)))
	var detail := GameUi.label("%s\n%s" % [action_text, requirement_text], 17, HORIZONTAL_ALIGNMENT_CENTER)
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.custom_minimum_size = Vector2(250, 58)
	box.add_child(detail)
	if host.team_name == river_team:
		var action_row := HBoxContainer.new()
		action_row.alignment = BoxContainer.ALIGNMENT_CENTER
		action_row.add_theme_constant_override("separation", 7)
		box.add_child(action_row)
		var play := GameUi.button("Play", Vector2(105, 42), host.team_accent)
		play.add_theme_font_size_override("font_size", 19)
		var pending_value = host.snapshot.get("PendingCard", {})
		var has_pending := pending_value is Dictionary and not (pending_value as Dictionary).is_empty()
		var requirement_error := GameRules.card_requirement_error(host.snapshot, river_team, metadata)
		play.disabled = has_pending or not requirement_error.is_empty()
		play.tooltip_text = "Finish resolving the active card first." if has_pending else requirement_error
		play.pressed.connect(func(): host.confirm_action("PLAY CARD", "Play %s and pay its cost?" % str(metadata.get("name", "this card")), func(): host.request_action("play_card", {"team": river_team, "index": card_index})))
		action_row.add_child(play)
		var discard := GameUi.button("Discard", Vector2(115, 42), host.team_accent)
		discard.add_theme_font_size_override("font_size", 19)
		discard.disabled = has_pending
		discard.pressed.connect(func(): host.confirm_action("DISCARD CARD", "Discard %s?" % str(metadata.get("name", "this card")), func(): host.request_action("discard_card", {"team": river_team, "index": card_index})))
		action_row.add_child(discard)
	return card


func _river_pending_panel() -> PanelContainer:
	var pending_value = host.snapshot.get("PendingCard", {})
	if not pending_value is Dictionary or (pending_value as Dictionary).is_empty():
		return null
	var pending := pending_value as Dictionary
	var resolver := str(pending.get("resolving_team", ""))
	var card_id := int(pending.get("card_id", 0))
	var panel := GameUi.panel(0.9, GameUi.team_color(resolver))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)
	var pending_title := str(pending.get("title", GameRules.card_display_name(card_id)))
	box.add_child(GameUi.label("RESOLVE %s" % pending_title.to_upper(), 27, HORIZONTAL_ALIGNMENT_CENTER))
	if host.team_name != resolver:
		box.add_child(GameUi.label("Waiting for %s to finish this rules choice." % resolver, 22, HORIZONTAL_ALIGNMENT_CENTER))
		return panel

	var pending_type := str(pending.get("type", ""))
	match pending_type:
		"strategic_domestic_exchange":
			var point_prefix := "Iran" if resolver == "Red" else "Isreal"
			var available_mp := maxi(0, int(host.snapshot.get("%sMP" % point_prefix, 0)))
			var available_ip := maxi(0, int(host.snapshot.get("%sIP" % point_prefix, 0)))
			var required_units := maxi(0, int(pending.get("required_units", 0)))
			var spend_target := mini(required_units, available_mp + available_ip)
			box.add_child(GameUi.label("Political Points were insufficient. Spend exactly %d combined MP/IP to satisfy the 3:1 exchange." % spend_target, 21, HORIZONTAL_ALIGNMENT_CENTER))
			var row := HBoxContainer.new()
			row.alignment = BoxContainer.ALIGNMENT_CENTER
			row.add_theme_constant_override("separation", 12)
			var default_mp := mini(available_mp, spend_target)
			var military := _spin_box(0, available_mp, default_mp)
			var intelligence := _spin_box(0, available_ip, spend_target - default_mp)
			row.add_child(GameUi.label("MP", 21))
			row.add_child(military)
			row.add_child(GameUi.label("IP", 21))
			row.add_child(intelligence)
			var resolve_scandal := GameUi.button("Pay Exchange", Vector2(200, 48), host.team_accent)
			resolve_scandal.pressed.connect(func(): host.request_action("resolve_card_action", {"team": host.team_name, "mp_spent": int(military.value), "ip_spent": int(intelligence.value)}))
			row.add_child(resolve_scandal)
			box.add_child(row)
		"strategic_intifada":
			var available_mp := maxi(0, int(host.snapshot.get("IranMP", 0)))
			var max_spend := mini(12, int(floor(float(available_mp) / 3.0)) * 3)
			box.add_child(GameUi.label("Iran rolls twice on Israel. Every 3 MP spent adds one extra opinion roll.", 21, HORIZONTAL_ALIGNMENT_CENTER))
			var row := HBoxContainer.new()
			row.alignment = BoxContainer.ALIGNMENT_CENTER
			row.add_theme_constant_override("separation", 12)
			var military := _spin_box(0, max_spend, 0)
			military.step = 3
			row.add_child(GameUi.label("Iran MP", 21))
			row.add_child(military)
			var resolve_intifada := GameUi.button("Resolve Intifada", Vector2(220, 48), host.team_accent)
			resolve_intifada.pressed.connect(func(): host.request_action("resolve_card_action", {"team": host.team_name, "mp_spent": int(military.value)}))
			row.add_child(resolve_intifada)
			box.add_child(row)
		"strait_response":
			var available_pp := clampi(int(host.snapshot.get("IsrealPP", 0)), 0, 2)
			box.add_child(GameUi.label("Iran achieved: %s\nIran committed %d PP. Spend 0-2 Blue PP before the blockade-effects D10." % [str(pending.get("closure", "No Effect")), int(pending.get("red_pp_spent", 0))], 21, HORIZONTAL_ALIGNMENT_CENTER))
			var row := HBoxContainer.new()
			row.alignment = BoxContainer.ALIGNMENT_CENTER
			row.add_theme_constant_override("separation", 12)
			var interference := _spin_box(0, available_pp, 0)
			row.add_child(GameUi.label("Blue PP", 21))
			row.add_child(interference)
			var resolve := GameUi.button("Resolve Blockade", Vector2(230, 48), host.team_accent)
			resolve.pressed.connect(func(): host.request_action("resolve_card_action", {"team": host.team_name, "pp_spent": int(interference.value)}))
			row.add_child(resolve)
			box.add_child(row)
		"opinion":
			var options_value = pending.get("group_options", [])
			var options: Array = []
			if options_value is Array and not (options_value as Array).is_empty() and (options_value as Array)[0] is Array:
				options = (options_value as Array)[0]
			var used_value = pending.get("used_country_ids", [])
			var used: Array = used_value if used_value is Array else []
			var selector := OptionButton.new()
			var allow_repeat := bool(pending.get("allow_repeat_country", false))
			for country_id in options:
				if allow_repeat or not used.has(int(country_id)):
					selector.add_item(str(COUNTRY_NAMES.get(int(country_id), "Country")), int(country_id))
			_style_option(selector, Vector2(280, 48))
			box.add_child(GameUi.label("%d group(s) left, %d D10 in this group" % [int(pending.get("groups_remaining", 1)), int(pending.get("dice_per_group", 1))], 21, HORIZONTAL_ALIGNMENT_CENTER))
			var row := HBoxContainer.new()
			row.alignment = BoxContainer.ALIGNMENT_CENTER
			row.add_theme_constant_override("separation", 12)
			row.add_child(selector)
			var roll := GameUi.button("Roll Opinion Dice", Vector2(220, 48), host.team_accent)
			roll.disabled = selector.item_count == 0
			roll.pressed.connect(func():
				if selector.item_count > 0:
					host.request_action("roll_card_country", {"team": host.team_name, "card_id": card_id, "country_id": selector.get_item_id(selector.selected)})
			)
			row.add_child(roll)
			box.add_child(row)
		"set_choice":
			box.add_child(GameUi.label("Choose one complete opinion-dice set.", 21, HORIZONTAL_ALIGNMENT_CENTER))
			var row := HBoxContainer.new()
			row.alignment = BoxContainer.ALIGNMENT_CENTER
			row.add_theme_constant_override("separation", 14)
			for choice in ["set1", "set2"]:
				var choose := GameUi.button(choice.capitalize(), Vector2(170, 48), host.team_accent)
				choose.pressed.connect(func(): host.request_action("resolve_card_action", {"team": host.team_name, "choice": choice}))
				row.add_child(choose)
			box.add_child(row)
		"retrieve":
			var selector := OptionButton.new()
			var eligible_value = pending.get("eligible_cards", [])
			if eligible_value is Array:
				for eligible_id in eligible_value:
					selector.add_item(GameRules.card_display_name(int(eligible_id)), int(eligible_id))
			_style_option(selector, Vector2(430, 48))
			box.add_child(selector)
			var retrieve := GameUi.button("Retrieve Card", Vector2(210, 48), host.team_accent)
			retrieve.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			retrieve.disabled = selector.item_count == 0
			retrieve.pressed.connect(func(): host.request_action("resolve_card_action", {"team": host.team_name, "card_id": selector.get_item_id(selector.selected)}))
			box.add_child(retrieve)
		"discard_choice":
			var opponent := "Blue" if str(pending.get("owner_team", "")) == "Red" else "Red"
			var selector := OptionButton.new()
			var opponent_river := _card_list("river", opponent)
			for opponent_card_id in opponent_river:
				selector.add_item(GameRules.card_display_name(int(opponent_card_id)), int(opponent_card_id))
			_style_option(selector, Vector2(430, 48))
			box.add_child(GameUi.label("Choose %d opposing card(s)." % int(pending.get("choices_left", 1)), 21, HORIZONTAL_ALIGNMENT_CENTER))
			box.add_child(selector)
			var discard := GameUi.button("Discard Selected", Vector2(230, 48), host.team_accent)
			discard.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			discard.disabled = selector.item_count == 0
			discard.pressed.connect(func(): host.request_action("resolve_card_action", {"team": host.team_name, "card_id": selector.get_item_id(selector.selected)}))
			box.add_child(discard)
		"convert":
			var row := HBoxContainer.new()
			row.alignment = BoxContainer.ALIGNMENT_CENTER
			row.add_theme_constant_override("separation", 10)
			var source := OptionButton.new()
			var target := OptionButton.new()
			for point_type in ["IP", "MP", "PP"]:
				source.add_item(point_type)
				target.add_item(point_type)
			target.select(1)
			_style_option(source, Vector2(120, 48))
			_style_option(target, Vector2(120, 48))
			var amount := _spin_box(3, 99, 3)
			amount.step = 3
			row.add_child(source)
			row.add_child(GameUi.label("to", 21))
			row.add_child(target)
			row.add_child(amount)
			var convert := GameUi.button("Convert 3:1", Vector2(190, 48), host.team_accent)
			convert.pressed.connect(func(): host.request_action("resolve_card_action", {"team": host.team_name, "source": source.get_item_text(source.selected), "target": target.get_item_text(target.selected), "amount": int(amount.value)}))
			row.add_child(convert)
			box.add_child(row)
		"freeze":
			var selector := OptionButton.new()
			for country in COUNTRIES:
				selector.add_item(str(country.get("name", country.get("code", "Country"))))
				selector.set_item_metadata(selector.item_count - 1, str(country.get("code", "")))
			_style_option(selector, Vector2(280, 48))
			box.add_child(selector)
			var freeze := GameUi.button("Freeze Track", Vector2(200, 48), host.team_accent)
			freeze.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			freeze.pressed.connect(func(): host.request_action("resolve_card_action", {"team": host.team_name, "country": str(selector.get_item_metadata(selector.selected))}))
			box.add_child(freeze)
		_:
			box.add_child(GameUi.label("Waiting for card resolution.", 21, HORIZONTAL_ALIGNMENT_CENTER))
	return panel


func _metadata_countries(metadata: Dictionary) -> Array:
	var result: Array = []
	for key in ["countries", "set1Countries", "set2Countries"]:
		var raw = metadata.get(key, [])
		if raw is Array:
			for country_id in raw:
				var clean_id := int(country_id)
				if clean_id > 0 and not result.has(clean_id):
					result.append(clean_id)
	return result


func _show_upgrades() -> void:
	if host.team_name == "White":
		_show_white_upgrade_review()
	else:
		_show_combat_upgrades()


func _show_combat_upgrades() -> void:
	var content: VBoxContainer = host.begin_overlay("%s UPGRADES" % host.team_name.to_upper())
	var groups: Array[String] = [host.team_name]
	if host.team_name == "Red":
		groups.append("RedExtra")
	var points_value = host.snapshot.get("UpgradePoints", {})
	var points: Dictionary = points_value if points_value is Dictionary else {}
	var selected_value = host.snapshot.get("SelectedUpgrades", {})
	var selected: Dictionary = selected_value if selected_value is Dictionary else {}

	for group_name in groups:
		var display_group := "ALLIED SUPPORT" if group_name == "RedExtra" else "%s TEAM" % group_name.to_upper()
		var heading_row := HBoxContainer.new()
		heading_row.add_theme_constant_override("separation", 12)
		content.add_child(heading_row)
		var heading := GameUi.title(display_group, GameUi.team_color(host.team_name), 37)
		heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		heading_row.add_child(heading)
		heading_row.add_child(GameUi.label("Points: %d" % int(points.get(group_name, 0)), 29, HORIZONTAL_ALIGNMENT_RIGHT))

		var flow := HFlowContainer.new()
		flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		flow.add_theme_constant_override("h_separation", 16)
		flow.add_theme_constant_override("v_separation", 16)
		content.add_child(flow)
		for raw_upgrade in GameRules.upgrades_for_team(group_name):
			if raw_upgrade is Dictionary:
				flow.add_child(_upgrade_catalog_card(group_name, raw_upgrade as Dictionary, int(points.get(group_name, 0))))

		content.add_child(GameUi.label("CART", 31))
		var cart: Array = selected.get(group_name, []) if selected.get(group_name, []) is Array else []
		if cart.is_empty():
			content.add_child(GameUi.label("No upgrades selected", 23))
		else:
			for index in range(cart.size()):
				if cart[index] is Dictionary:
					content.add_child(_upgrade_cart_row(group_name, index, cart[index] as Dictionary))
		content.add_child(GameUi.separator())


func _upgrade_catalog_card(group_name: String, upgrade: Dictionary, available_points: int) -> PanelContainer:
	var card := GameUi.panel(0.86, GameUi.team_color(host.team_name))
	card.custom_minimum_size = Vector2(410, 230)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 7)
	card.add_child(box)
	var name_label := GameUi.label(str(upgrade.get("name", "Upgrade")), 26, HORIZONTAL_ALIGNMENT_CENTER)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.custom_minimum_size = Vector2(380, 55)
	box.add_child(name_label)
	box.add_child(GameUi.label("Cost %d" % int(upgrade.get("cost", 0)), 23, HORIZONTAL_ALIGNMENT_CENTER))
	var description := GameUi.label(str(upgrade.get("description", "")), 18)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.custom_minimum_size = Vector2(380, 72)
	description.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(description)
	var purchase := GameUi.button("Add to Cart", Vector2(170, 45), host.team_accent)
	purchase.add_theme_font_size_override("font_size", 20)
	var requirement_error := GameRules.upgrade_requirement_error(host.snapshot, group_name, upgrade)
	purchase.disabled = available_points < int(upgrade.get("cost", 0)) or not requirement_error.is_empty()
	if not requirement_error.is_empty():
		purchase.tooltip_text = requirement_error
	purchase.pressed.connect(func(): host.request_action("purchase_upgrade", {"team": group_name, "upgrade": str(upgrade.get("name", ""))}))
	box.add_child(purchase)
	return card


func _upgrade_cart_row(group_name: String, index: int, upgrade: Dictionary) -> PanelContainer:
	var panel := GameUi.panel(0.75, host.team_accent)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	panel.add_child(row)
	var name_label := GameUi.label("%s   (%d)" % [str(upgrade.get("name", "Upgrade")), int(upgrade.get("cost", 0))], 23)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_label)
	var refund := GameUi.button("Remove", Vector2(125, 42), host.team_accent)
	refund.add_theme_font_size_override("font_size", 19)
	refund.pressed.connect(func(): host.request_action("refund_upgrade", {"team": group_name, "index": index}))
	row.add_child(refund)
	return panel


func _show_white_upgrade_review() -> void:
	var content: VBoxContainer = host.begin_overlay("UPGRADE REVIEW")
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 20)
	columns.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.custom_minimum_size = Vector2(0, 700)
	content.add_child(columns)
	var selected_value = host.snapshot.get("SelectedUpgrades", {})
	var selected: Dictionary = selected_value if selected_value is Dictionary else {}
	for team in ["Red", "Blue"]:
		var panel := GameUi.panel(0.86, GameUi.team_color(team))
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		columns.add_child(panel)
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 10)
		panel.add_child(box)
		box.add_child(GameUi.title("%s UPGRADES" % team.to_upper(), GameUi.team_color(team), 36))
		var team_items: Array = selected.get(team, []) if selected.get(team, []) is Array else []
		if team == "Red":
			var extra_items: Array = selected.get("RedExtra", []) if selected.get("RedExtra", []) is Array else []
			team_items = team_items.duplicate(true)
			team_items.append_array(extra_items)
		if team_items.is_empty():
			box.add_child(GameUi.label("No upgrades submitted", 25, HORIZONTAL_ALIGNMENT_CENTER))
		else:
			for item in team_items:
				if item is Dictionary:
					var item_panel := GameUi.panel(0.72, GameUi.team_color(team))
					var item_label := GameUi.label("%s   %d pts" % [str(item.get("name", "Upgrade")), int(item.get("cost", 0))], 22)
					item_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
					item_panel.add_child(item_label)
					box.add_child(item_panel)
	var send := GameUi.button("Send Upgrades to Both Teams", Vector2(430, 62), host.team_accent)
	send.add_theme_font_size_override("font_size", 27)
	send.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	send.pressed.connect(func():
		var blue_text := _upgrade_names(selected.get("Blue", []))
		var red_names := _upgrade_names(selected.get("Red", []))
		var extra_names := _upgrade_names(selected.get("RedExtra", []))
		if not extra_names.is_empty():
			red_names = "%s%s%s" % [red_names, ", " if not red_names.is_empty() else "", extra_names]
		host.confirm_action("SEND UPGRADES", "Confirm the final Red and Blue upgrade lists?", func(): host.request_action("set_upgrades", {"blue": blue_text, "red": red_names, "confirmed": true}))
	)
	content.add_child(send)


func _upgrade_names(value) -> String:
	var names: Array[String] = []
	if value is Array:
		for item in value:
			if item is Dictionary:
				names.append(str(item.get("name", "Upgrade")))
	return ", ".join(names)


func _show_targets() -> void:
	var content: VBoxContainer = host.begin_overlay("STRATEGIC TARGET STATUS")
	var oil := GameRules._oil_capacity_summary(host.snapshot)
	var summary_panel := GameUi.panel(0.86, host.team_accent)
	content.add_child(summary_panel)
	var summary_box := VBoxContainer.new()
	summary_box.add_theme_constant_override("separation", 6)
	summary_panel.add_child(summary_box)
	summary_box.add_child(GameUi.label("OIL CAMPAIGN", 29, HORIZONTAL_ALIGNMENT_CENTER))
	summary_box.add_child(GameUi.label(
		"Refinery capacity %.1f / %.1f%%   |   Terminal capacity %.1f / %.1f%%   |   Blue victory at 50%% / 15%%" % [
			float(oil.get("refinery_remaining", 0.0)), float(oil.get("refinery_total", 0.0)),
			float(oil.get("terminal_remaining", 0.0)), float(oil.get("terminal_total", 0.0))
		],
		23,
		HORIZONTAL_ALIGNMENT_CENTER
	))
	var grid := HFlowContainer.new()
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(grid)
	for row_value in GameRules.target_status_rows(host.snapshot):
		var row := row_value as Dictionary
		var panel := GameUi.panel(0.82, host.team_accent)
		panel.custom_minimum_size = Vector2(560, 0)
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(panel)
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 6)
		panel.add_child(box)
		var level := str(row.get("victory_level", "None"))
		var type_text := str(row.get("type", ""))
		if type_text == "Oil":
			type_text = "%s / %s" % [type_text, str(row.get("oil_category", ""))]
		box.add_child(GameUi.label(str(row.get("name", "Target")).to_upper(), 27, HORIZONTAL_ALIGNMENT_CENTER))
		box.add_child(GameUi.label(
			"%s   |   Sector %s   |   Routes %s   |   Result %s" % [
				type_text, str(row.get("sector", "-")), ", ".join(row.get("routes", [])), level
			],
			20,
			HORIZONTAL_ALIGNMENT_CENTER
		))
		if type_text.begins_with("Oil"):
			box.add_child(GameUi.label("Capacity %.1f / %d%%" % [float(row.get("remaining_capacity", 0.0)), int(row.get("capacity", 0))], 20, HORIZONTAL_ALIGNMENT_CENTER))
		var component_lines: Array[String] = []
		for component_value in row.get("components", []):
			var component := component_value as Dictionary
			var status := "DESTROYED" if bool(component.get("destroyed", false)) else ("DAMAGED" if bool(component.get("damage_threshold_met", false)) else "Intact")
			component_lines.append("%s [%s]  %s  Size %s / Armor %d  %d/%d  %s" % [
				str(component.get("key", "")), str(component.get("role", "Primary")), str(component.get("name", "Component")),
				str(component.get("size_class", "-")), int(component.get("armor", 0)), int(component.get("damaged", 0)),
				int(component.get("boxes", 0)), status
			])
		var components_label := GameUi.label("\n".join(component_lines), 18)
		components_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(components_label)


func _show_actions() -> void:
	if host.team_name == "White":
		_show_team_track()
		return
	var content: VBoxContainer = host.begin_overlay("%s ACTIONS" % host.team_name.to_upper())
	var point_prefix := "Isreal" if host.team_name == "Blue" else "Iran"
	var resource_text := "AVAILABLE   IP %d   MP %d   PP %d" % [
		int(host.snapshot.get("%sIP" % point_prefix, 0)),
		int(host.snapshot.get("%sMP" % point_prefix, 0)),
		int(host.snapshot.get("%sPP" % point_prefix, 0))
	]
	content.add_child(GameUi.label(resource_text, 24, HORIZONTAL_ALIGNMENT_CENTER))
	var form := GameUi.panel(0.87, host.team_accent)
	content.add_child(form)
	var form_box := VBoxContainer.new()
	form_box.add_theme_constant_override("separation", 11)
	form.add_child(form_box)
	form_box.add_child(GameUi.label("PLAN ACTION", 31, HORIZONTAL_ALIGNMENT_CENTER))
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 9)
	form_box.add_child(grid)

	var action_type := OptionButton.new()
	var action_names: Array[String] = BLUE_ACTION_TYPES if host.team_name == "Blue" else RED_ACTION_TYPES
	for action_name in action_names:
		action_type.add_item(action_name)
	_style_option(action_type, Vector2(310, 48))
	var attack_name := LineEdit.new()
	attack_name.placeholder_text = "Operation name"
	attack_name.custom_minimum_size = Vector2(310, 48)
	attack_name.add_theme_font_size_override("font_size", 22)
	var target_select := OptionButton.new()
	if host.team_name == "Blue":
		var targets := GameRules.all_target_metadata()
		for target in targets:
			if target is Dictionary:
				target_select.add_item(str(target.get("name", target.get("id", "Target"))))
				target_select.set_item_metadata(target_select.item_count - 1, str(target.get("id", "")))
	else:
		var red_targets: Array[Dictionary] = [
			{"name": "Israeli Urban Area", "id": "Urban"},
			{"name": "Israeli Airbase", "id": "Israeli Airbase"},
			{"name": "Israeli Military Base", "id": "Israeli Military Base"},
			{"name": "Israeli Ballistic-Missile Shelter", "id": "Israeli Ballistic Missile Shelter"},
			{"name": "Civil / Economic Target", "id": "Civil Economic Target"},
			{"name": "Northern Air-Defense Sector", "id": "Northern Sector"},
			{"name": "Central Air-Defense Sector", "id": "Central Sector"},
			{"name": "Southern Air-Defense Sector", "id": "Southern Sector"},
			{"name": "Strait of Hormuz", "id": "Strait of Hormuz"}
		]
		for target in red_targets:
			target_select.add_item(str(target.get("name", "Target")))
			target_select.set_item_metadata(target_select.item_count - 1, str(target.get("id", "")))
	if target_select.item_count == 0:
		target_select.add_item("No available target")
		target_select.set_item_metadata(0, "")
	_style_option(target_select, Vector2(310, 48))
	var component_select := OptionButton.new()
	_style_option(component_select, Vector2(310, 48))
	var route_select := OptionButton.new()
	for route_name in ["Northern", "Central", "Southern"]:
		route_select.add_item(route_name)
		route_select.set_item_metadata(route_select.item_count - 1, route_name)
	_style_option(route_select, Vector2(310, 48))
	var squadron_select := OptionButton.new()
	var blue_aircraft_value = host.snapshot.get("BlueAircraft", [])
	var blue_aircraft: Array = blue_aircraft_value if blue_aircraft_value is Array else []
	for aircraft_index in range(blue_aircraft.size()):
		if not blue_aircraft[aircraft_index] is Dictionary:
			continue
		var aircraft_row := blue_aircraft[aircraft_index] as Dictionary
		var model := str(aircraft_row.get("model", ""))
		if not ["F16I", "F15I"].has(model):
			continue
		squadron_select.add_item("%s - %s (%d ready, %s)" % [str(aircraft_row.get("name", "Squadron")), model, int(aircraft_row.get("operational", 0)), str(aircraft_row.get("mission", "Ready"))])
		squadron_select.set_item_metadata(squadron_select.item_count - 1, {"index": aircraft_index, "model": model, "operational": int(aircraft_row.get("operational", 0)), "mission": str(aircraft_row.get("mission", "Ready"))})
	if squadron_select.item_count == 0:
		squadron_select.add_item("No strike squadron")
		squadron_select.set_item_metadata(0, {"index": -1, "model": "", "operational": 0, "mission": "Unavailable"})
	_style_option(squadron_select, Vector2(310, 48))
	var loadout_select := OptionButton.new()
	_style_option(loadout_select, Vector2(310, 48))
	var sead_loadout_select := OptionButton.new()
	sead_loadout_select.add_item("SEAD - AGM-88 HARM")
	sead_loadout_select.add_item("SEAD - STAR-1")
	_style_option(sead_loadout_select, Vector2(310, 48))
	var mission_select := OptionButton.new()
	for mission_name in SPECIAL_MISSIONS:
		mission_select.add_item(mission_name)
	_style_option(mission_select, Vector2(310, 48))
	var missile_select := OptionButton.new()
	missile_select.add_item("Shahab-3")
	if GameRules.selected_upgrade_count(host.snapshot, "Red", "Sejil-2") > 0:
		missile_select.add_item("Sejil-2")
	_style_option(missile_select, Vector2(310, 48))
	var wait_time := _spin_box(0, 5, 1)
	var units := _spin_box(0, 4, 1)
	var coordination_mp := _spin_box(0, 2, 0)
	var ip_cost := _spin_box(0, 4, 0)
	var mp_cost := _spin_box(0, 7, 0)
	var pp_cost := _spin_box(0, 2, 0)
	var escort_aircraft := _spin_box(0, 12, 0)
	escort_aircraft.step = 2
	var sead_aircraft := _spin_box(0, 4, 0)
	sead_aircraft.step = 2
	var shavit_aircraft := _spin_box(0, 1, 0)
	var eitan_aircraft := _spin_box(0, 2, 0)
	var extra_sead_mp := _spin_box(0, 6, 0)
	extra_sead_mp.step = 2

	_add_form_control(grid, "Action", action_type)
	_add_form_control(grid, "Operation", attack_name)
	_add_form_control(grid, "Target", target_select)
	_add_form_control(grid, "Mission", mission_select)
	if host.team_name == "Blue":
		_add_form_control(grid, "Target Component", component_select)
		_add_form_control(grid, "Ingress Route", route_select)
		_add_form_control(grid, "Strike Squadron", squadron_select)
		_add_form_control(grid, "Strike Loadout", loadout_select)
		_add_form_control(grid, "Escort Aircraft", escort_aircraft)
		_add_form_control(grid, "SEAD Aircraft", sead_aircraft)
		_add_form_control(grid, "SEAD Weapon", sead_loadout_select)
		_add_form_control(grid, "Shavit", shavit_aircraft)
		_add_form_control(grid, "Eitan Support", eitan_aircraft)
		_add_form_control(grid, "Extra SEAD MP", extra_sead_mp)
	if host.team_name == "Red":
		_add_form_control(grid, "Missile", missile_select)
		_add_form_control(grid, "Coordination MP", coordination_mp)
	_add_form_control(grid, "Map Turns", wait_time)
	_add_form_control(grid, "Aircraft / Missiles", units)
	_add_form_control(grid, "IP Cost", ip_cost)
	_add_form_control(grid, "MP Cost", mp_cost)
	_add_form_control(grid, "PP Cost", pp_cost)

	var rule_label := GameUi.label("", 20, HORIZONTAL_ALIGNMENT_CENTER)
	rule_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	form_box.add_child(rule_label)
	var update_target_components := func(_unused = 0):
		component_select.clear()
		if target_select.item_count <= 0:
			return
		var target_id := str(target_select.get_item_metadata(target_select.selected))
		var target := GameRules._find_target_metadata(target_id)
		for component_value in target.get("components", []):
			if not component_value is Dictionary:
				continue
			var component := component_value as Dictionary
			component_select.add_item("%s [%s] %s - Size %s / Armor %d" % [str(component.get("key", "")), str(component.get("role", "Primary")), str(component.get("name", "Component")), str(component.get("size_class", "-")), int(component.get("armor", 0))])
			component_select.set_item_metadata(component_select.item_count - 1, str(component.get("key", "")))
		var allowed_routes_value = target.get("routes", [])
		var allowed_routes: Array = allowed_routes_value if allowed_routes_value is Array else []
		var selected_route := -1
		for route_index in range(route_select.item_count):
			var route_name := str(route_select.get_item_metadata(route_index))
			var reaches_target := allowed_routes.is_empty() or allowed_routes.has(route_name)
			var politically_open := GameRules._route_plan_error(host.snapshot, route_name).is_empty()
			var allowed := reaches_target and politically_open
			route_select.set_item_disabled(route_index, not allowed)
			if allowed and selected_route < 0:
				selected_route = route_index
		if selected_route >= 0:
			route_select.select(selected_route)
	var update_strike_loadouts := func(_unused = 0):
		loadout_select.clear()
		if squadron_select.item_count <= 0:
			return
		var metadata_value = squadron_select.get_item_metadata(squadron_select.selected)
		var metadata: Dictionary = metadata_value if metadata_value is Dictionary else {}
		var model := str(metadata.get("model", ""))
		for loadout_name in GameRules.blue_loadouts_for_model(model):
			var loadout_value = GameRules.BLUE_LOADOUTS.get(model, {}).get(loadout_name, {})
			if loadout_value is Dictionary and str((loadout_value as Dictionary).get("role", "")) == "Strike":
				loadout_select.add_item(loadout_name)
		var operational := maxi(1, int(metadata.get("operational", 1)))
		units.max_value = operational
		units.value = clampi(maxi(1, int(units.value)), 1, operational)
	update_target_components.call()
	update_strike_loadouts.call()
	var update_ballistic_controls := func(_unused = 0):
		if action_type.get_item_text(action_type.selected) != "Ballistic Missile":
			return
		var selected_missile := missile_select.get_item_text(missile_select.selected)
		var available := GameRules.available_ballistic_battalions(host.snapshot, selected_missile)
		units.min_value = 0
		units.max_value = available
		if available <= 0:
			units.value = 0
		else:
			units.value = clampi(maxi(1, int(units.value)), 1, available)
		wait_time.value = 0 if selected_missile == "Sejil-2" else 1
		mp_cost.value = int(units.value) + int(coordination_mp.value)
		rule_label.text = "%s: %d battalion(s) available; four missiles per battalion. Coordination may spend up to 2 MP. %s" % [
			selected_missile,
			available,
			"Resolves immediately." if selected_missile == "Sejil-2" else "Resolves next map turn."
		]
	var configure_form := func(_selected_index: int = 0):
		var selected_action := action_type.get_item_text(action_type.selected)
		var is_special := selected_action == "Special Warfare" or selected_action == "Terror Attack"
		var is_airstrike := selected_action == "Airstrike"
		mission_select.disabled = selected_action != "Special Warfare"
		wait_time.editable = is_special
		ip_cost.editable = is_special
		pp_cost.editable = selected_action == "Close Strait"
		units.editable = selected_action == "Ballistic Missile" or is_airstrike
		missile_select.disabled = selected_action != "Ballistic Missile"
		coordination_mp.editable = selected_action == "Ballistic Missile"
		target_select.disabled = selected_action == "Close Strait" or selected_action == "Terror Attack"
		for airstrike_control in [component_select, route_select, squadron_select, loadout_select, sead_loadout_select]:
			(airstrike_control as BaseButton).disabled = not is_airstrike
		for airstrike_spin in [escort_aircraft, sead_aircraft, shavit_aircraft, eitan_aircraft, extra_sead_mp]:
			(airstrike_spin as SpinBox).editable = is_airstrike
		if selected_action == "Terror Attack":
			mission_select.select(0)
			for target_index in range(target_select.item_count):
				if str(target_select.get_item_metadata(target_index)) == "Civil Economic Target":
					target_select.select(target_index)
					break
		match selected_action:
			"Airstrike":
				units.min_value = 1
				var squadron_metadata_value = squadron_select.get_item_metadata(squadron_select.selected)
				var squadron_metadata: Dictionary = squadron_metadata_value if squadron_metadata_value is Dictionary else {}
				units.max_value = maxi(1, int(squadron_metadata.get("operational", 1)))
				wait_time.value = 1
				units.value = clampi(maxi(2, int(units.value)), 1, int(units.max_value))
				ip_cost.value = 3
				mp_cost.value = 3 + int(extra_sead_mp.value)
				mp_cost.editable = false
				pp_cost.value = 0
				rule_label.text = "Airstrike: 3 IP + 3 MP, plus optional SEAD MP; executes next map turn. Routes need a Blue Supporter/Ally, or one unused cordial overflight."
			"Special Warfare", "Terror Attack":
				units.min_value = 0
				units.max_value = 4
				wait_time.value = maxi(1, int(wait_time.value))
				ip_cost.value = maxi(1, int(ip_cost.value))
				mp_cost.value = maxi(1, int(mp_cost.value))
				mp_cost.editable = true
				units.value = 0
				pp_cost.value = 0
				if selected_action == "Terror Attack":
					rule_label.text = "Terror attacks only target Israeli civil/economic infrastructure. Spend 1-4 IP and 1-3 MP (2-7 total)."
				else:
					rule_label.text = "Spend 1-4 IP and 1-3 MP (2-7 total). Waiting longer improves the success chance; attacking an undamaged building applies -30%."
			"Ballistic Missile":
				ip_cost.value = 0
				mp_cost.editable = false
				pp_cost.value = 0
				update_ballistic_controls.call()
			"Reposition Air Defense":
				units.min_value = 0
				units.max_value = 4
				wait_time.value = 1
				units.value = 0
				ip_cost.value = 0
				mp_cost.value = 0
				mp_cost.editable = false
				pp_cost.value = 0
				rule_label.text = "Choose a sector. Repositioning consumes one map turn."
			"Close Strait":
				units.min_value = 0
				units.max_value = 4
				wait_time.value = 1
				units.value = 0
				ip_cost.value = 0
				mp_cost.value = maxi(1, int(mp_cost.value))
				mp_cost.editable = true
				rule_label.text = "Strait status: %s. Spend 1-7 MP and up to 2 PP; cooldown %d map turn(s)." % [str(host.snapshot.get("StraitStatus", "Open")), int(host.snapshot.get("StraitCooldown", 0))]
	action_type.item_selected.connect(configure_form)
	target_select.item_selected.connect(update_target_components)
	squadron_select.item_selected.connect(update_strike_loadouts)
	missile_select.item_selected.connect(update_ballistic_controls)
	coordination_mp.value_changed.connect(update_ballistic_controls)
	units.value_changed.connect(update_ballistic_controls)
	configure_form.call(0)

	var add_action := GameUi.button("Add Planned Action", Vector2(280, 55), host.team_accent)
	add_action.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	add_action.disabled = str(host.snapshot.get("ChangeTeam", "")) != host.team_name or bool(host.snapshot.get("ActionPending", false))
	add_action.pressed.connect(func():
		var target_id := ""
		if target_select.item_count > 0:
			target_id = str(target_select.get_item_metadata(target_select.selected))
		var selected_action := action_type.get_item_text(action_type.selected)
		if selected_action == "Ballistic Missile":
			mp_cost.value = units.value + coordination_mp.value
		elif selected_action == "Airstrike":
			mp_cost.value = 3 + extra_sead_mp.value
		host.request_action("add_planned_action", {
			"team": host.team_name,
			"action_name": selected_action,
			"attack_name": attack_name.text,
			"target": target_id,
			"wait_time": int(wait_time.value),
			"missiles": int(units.value),
			"battalions": int(units.value),
			"missile_type": missile_select.get_item_text(missile_select.selected),
			"coordination_mp": int(coordination_mp.value),
			"ip_cost": int(ip_cost.value),
			"mp_cost": int(mp_cost.value),
			"pp_cost": int(pp_cost.value),
			"mission_type": mission_select.get_item_text(mission_select.selected),
			"component_key": str(component_select.get_item_metadata(component_select.selected)) if component_select.item_count > 0 else "",
			"route": str(route_select.get_item_metadata(route_select.selected)) if route_select.item_count > 0 else "Central",
			"squadron_index": int((squadron_select.get_item_metadata(squadron_select.selected) as Dictionary).get("index", -1)) if squadron_select.item_count > 0 and squadron_select.get_item_metadata(squadron_select.selected) is Dictionary else -1,
			"loadout": loadout_select.get_item_text(loadout_select.selected) if loadout_select.item_count > 0 else "",
			"escort_aircraft": int(escort_aircraft.value),
			"sead_aircraft": int(sead_aircraft.value),
			"sead_loadout": sead_loadout_select.get_item_text(sead_loadout_select.selected),
			"shavit_aircraft": int(shavit_aircraft.value),
			"eitan_aircraft": int(eitan_aircraft.value),
			"air_defense_mp": int(extra_sead_mp.value)
		})
	)
	form_box.add_child(add_action)

	var turn_row := HBoxContainer.new()
	turn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	turn_row.add_theme_constant_override("separation", 18)
	content.add_child(turn_row)
	var take_action := GameUi.button("Submit Action", Vector2(230, 55), host.team_accent)
	take_action.disabled = str(host.snapshot.get("ChangeTeam", "")) != host.team_name or bool(host.snapshot.get("ActionPending", false))
	take_action.pressed.connect(func(): host.confirm_action("SUBMIT ACTION", "Send this move to White for review?", func(): host.request_action("take_action", {"team": host.team_name})))
	turn_row.add_child(take_action)
	var pass_button := GameUi.button("Pass Move", Vector2(200, 55), host.team_accent)
	pass_button.disabled = str(host.snapshot.get("ChangeTeam", "")) != host.team_name
	pass_button.pressed.connect(func(): host.confirm_action("PASS MOVE", "Pass this move to the opposing team?", func(): host.request_action("pass", {"team": host.team_name})))
	turn_row.add_child(pass_button)

	content.add_child(GameUi.label("PLANNED ACTIONS", 31))
	var planned_value = host.snapshot.get("PlannedActions", [])
	var planned: Array = planned_value if planned_value is Array else []
	var found := false
	for index in range(planned.size()):
		if planned[index] is Dictionary and str(planned[index].get("team", "")) == host.team_name:
			found = true
			content.add_child(_planned_action_row(index, planned[index] as Dictionary))
	if not found:
		content.add_child(GameUi.label("No planned actions", 23))


func _planned_action_row(index: int, action: Dictionary) -> PanelContainer:
	var panel := GameUi.panel(0.78, host.team_accent)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	panel.add_child(row)
	var action_detail := str(action.get("mission_type", action.get("action_type", "")))
	if str(action.get("action_type", "")) == "Ballistic Missile":
		action_detail = "%s | Coordination %d MP" % [str(action.get("missile_type", "Shahab-3")), int(action.get("coordination_mp", 0))]
	var text := "%s | %s | Target: %s | Wait: %d | Units: %d | Cost: %d IP / %d MP / %d PP" % [
		str(action.get("display", action.get("action_name", "Action"))),
		action_detail,
		str(action.get("target", "None")), int(action.get("wait_time", 0)), int(action.get("missiles", 0)),
		int(action.get("ip_cost", 0)), int(action.get("mp_cost", 0)), int(action.get("pp_cost", 0))
	]
	var label := GameUi.label(text, 22)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(label)
	var resolve := GameUi.button("Resolve", Vector2(125, 44), host.team_accent)
	resolve.add_theme_font_size_override("font_size", 19)
	resolve.disabled = int(action.get("wait_time", 0)) > 0
	resolve.pressed.connect(func(): host.confirm_action("RESOLVE ACTION", "Resolve %s now?" % str(action.get("display", "this action")), func(): host.request_action("resolve_planned_action", {"index": index, "team": host.team_name})))
	row.add_child(resolve)
	var remove := GameUi.button("Remove", Vector2(120, 44), host.team_accent)
	remove.add_theme_font_size_override("font_size", 19)
	remove.pressed.connect(func(): host.confirm_action("REMOVE ACTION", "Remove this planned action?", func(): host.request_action("remove_planned_action", {"index": index, "team": host.team_name})))
	row.add_child(remove)
	return panel


func _add_form_control(grid: GridContainer, label_text: String, control: Control) -> void:
	grid.add_child(GameUi.label(label_text, 21, HORIZONTAL_ALIGNMENT_RIGHT))
	grid.add_child(control)


func _style_option(option: OptionButton, minimum_size: Vector2) -> void:
	option.custom_minimum_size = minimum_size
	option.add_theme_font_size_override("font_size", 21)
	GameUi.style_button(option, host.team_accent)


func _spin_box(minimum: float, maximum: float, initial: float) -> SpinBox:
	var spin := SpinBox.new()
	spin.min_value = minimum
	spin.max_value = maximum
	spin.value = initial
	spin.step = 1
	spin.custom_minimum_size = Vector2(130, 48)
	spin.add_theme_font_size_override("font_size", 21)
	return spin


func _show_aircraft() -> void:
	if host.team_name == "White":
		_show_team_track()
		return
	var content: VBoxContainer = host.begin_overlay("%s TEAM AIR FORCE STATUS" % host.team_name.to_upper())
	var toolbar := HBoxContainer.new()
	toolbar.add_theme_constant_override("separation", 14)
	content.add_child(toolbar)
	var phase := GameUi.label(GameRules.turn_label(host.snapshot), 26)
	phase.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	toolbar.add_child(phase)
	var repair := GameUi.button("Repair Roll", Vector2(175, 48), host.team_accent)
	repair.add_theme_font_size_override("font_size", 21)
	var repair_markers_value = host.snapshot.get("LastAircraftRepairDay", {})
	var repair_markers: Dictionary = repair_markers_value if repair_markers_value is Dictionary else {}
	var current_day := int(host.snapshot.get("TurnDay", 0))
	repair.disabled = current_day <= 0 or int(host.snapshot.get("TurnTime", 3)) != 0 or int(repair_markers.get(host.team_name, -1)) == current_day
	repair.tooltip_text = "Repairs run once for every eligible damaged aircraft at the start of Morning."
	repair.pressed.connect(func(): host.request_action("aircraft_roll", {"team": host.team_name, "mode": "repair"}))
	toolbar.add_child(repair)
	var breakdown_label := "Squadron Breakdown" if host.team_name == "Red" else "Return Breakdown"
	var breakdown := GameUi.button(breakdown_label, Vector2(245, 48), host.team_accent)
	breakdown.add_theme_font_size_override("font_size", 21)
	if host.team_name == "Red":
		var turn_key := "%d:%d" % [current_day, int(host.snapshot.get("TurnTime", 3))]
		breakdown.disabled = str(host.snapshot.get("LastRedBreakdownTurn", "")) == turn_key
		breakdown.tooltip_text = "One 2D6 result is applied to every eligible Iranian squadron."
	else:
		breakdown.disabled = true
		for blue_row in _aircraft_rows("Blue"):
			if blue_row is Dictionary and str((blue_row as Dictionary).get("mission", "")) == "In Flight 2" and not bool((blue_row as Dictionary).get("return_breakdown_done", false)):
				breakdown.disabled = false
				break
		breakdown.tooltip_text = "Israeli breakdowns are rolled only when a squadron returns from an airstrike."
	breakdown.pressed.connect(func(): host.request_action("aircraft_roll", {"team": host.team_name, "mode": "breakdown"}))
	toolbar.add_child(breakdown)

	var table_panel := GameUi.panel(0.84, host.team_accent)
	content.add_child(table_panel)
	var horizontal := ScrollContainer.new()
	horizontal.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	horizontal.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	table_panel.add_child(horizontal)
	var grid := GridContainer.new()
	grid.columns = 9
	grid.add_theme_constant_override("h_separation", 13)
	grid.add_theme_constant_override("v_separation", 9)
	grid.custom_minimum_size = Vector2(1720, 0)
	horizontal.add_child(grid)
	for heading in ["Squadron", "Location", "Model", "Mission", "Starting", "Current", "Damaged", "Missing", "KIA"]:
		var heading_label := GameUi.label(heading, 22, HORIZONTAL_ALIGNMENT_CENTER)
		heading_label.add_theme_color_override("font_color", host.team_accent)
		grid.add_child(heading_label)

	var aircraft := _aircraft_rows(host.team_name)
	for index in range(aircraft.size()):
		var row: Dictionary = aircraft[index]
		grid.add_child(_table_label(str(row.get("name", "Squadron")), 165))
		var location := _table_option(LOCATIONS, str(row.get("location", "Home")), 175)
		location.disabled = host.team_name == "Red" and not bool(host.snapshot.get("ConflictStarted", false))
		location.item_selected.connect(func(selected_index: int): host.request_action("aircraft_set", {"team": host.team_name, "index": index, "field": "location", "value": location.get_item_text(selected_index)}))
		grid.add_child(location)
		grid.add_child(_table_label(str(row.get("model", "Unknown")), 140))
		var mission_options := RED_AIRCRAFT_MISSIONS if host.team_name == "Red" else BLUE_AIRCRAFT_MISSIONS
		var mission := _table_option(mission_options, str(row.get("mission", "Ready")), 185)
		if host.team_name == "Red":
			mission.disabled = not bool(host.snapshot.get("ConflictStarted", false))
		else:
			for mission_index in range(mission.item_count):
				mission.set_item_disabled(mission_index, not ["Ready", "Fragged"].has(mission.get_item_text(mission_index)))
		mission.item_selected.connect(func(selected_index: int): host.request_action("aircraft_set", {"team": host.team_name, "index": index, "field": "mission", "value": mission.get_item_text(selected_index)}))
		grid.add_child(mission)
		grid.add_child(_table_label(str(int(row.get("total", 0))), 105))
		grid.add_child(_table_label(str(int(row.get("operational", 0))), 105))
		grid.add_child(_table_label(str(int(row.get("damaged", 0))), 105))
		grid.add_child(_table_label(str(int(row.get("missing", 0))), 105))
		grid.add_child(_table_label(str(int(row.get("kia", 0))), 105))

	var events_value = host.snapshot.get("AircraftEvents", [])
	var events: Array = events_value if events_value is Array else []
	content.add_child(GameUi.label("AIRCRAFT EVENTS", 29))
	var events_panel := GameUi.panel(0.75, host.team_accent)
	events_panel.custom_minimum_size = Vector2(0, 170)
	content.add_child(events_panel)
	var event_text := GameUi.label("No aircraft events" if events.is_empty() else "\n".join(events), 21)
	event_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	events_panel.add_child(event_text)


func _aircraft_rows(team: String) -> Array:
	var value = host.snapshot.get("%sAircraft" % team, [])
	return value if value is Array else []


func _table_label(text: String, width: float) -> Label:
	var label := GameUi.label(text, 21, HORIZONTAL_ALIGNMENT_CENTER)
	label.custom_minimum_size = Vector2(width, 48)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return label


func _table_option(items: Array[String], selected_text: String, width: float) -> OptionButton:
	var option := OptionButton.new()
	option.custom_minimum_size = Vector2(width, 48)
	option.add_theme_font_size_override("font_size", 20)
	GameUi.style_button(option, host.team_accent)
	var selected_index := 0
	for item in items:
		option.add_item(item)
		if item == selected_text:
			selected_index = option.item_count - 1
	if not items.has(selected_text) and not selected_text.is_empty():
		option.add_item(selected_text)
		selected_index = option.item_count - 1
	option.select(selected_index)
	return option


func _show_team_track() -> void:
	var content: VBoxContainer = host.begin_overlay("TEAM TRACK")
	var current_team := str(host.snapshot.get("ChangeTeam", "White"))
	var banner := GameUi.panel(0.87, GameUi.team_color(current_team))
	content.add_child(banner)
	var banner_label := GameUi.title("CURRENT MOVE: %s" % current_team.to_upper(), GameUi.team_color(current_team), 40)
	banner.add_child(banner_label)

	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 22)
	columns.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(columns)
	for team in ["Red", "Blue"]:
		columns.add_child(_team_status_panel(team))

	var pending := bool(host.snapshot.get("ActionPending", false))
	content.add_child(GameUi.label("ACTION REVIEW", 31))
	var review := GameUi.panel(0.8, GameUi.team_color(str(host.snapshot.get("ActionTeam", "White"))))
	content.add_child(review)
	var review_box := VBoxContainer.new()
	review_box.alignment = BoxContainer.ALIGNMENT_CENTER
	review_box.add_theme_constant_override("separation", 12)
	review.add_child(review_box)
	if not pending:
		review_box.add_child(GameUi.label("No action is waiting for White", 25, HORIZONTAL_ALIGNMENT_CENTER))
	else:
		var action_team := str(host.snapshot.get("ActionTeam", ""))
		review_box.add_child(GameUi.label("%s submitted an action" % action_team, 29, HORIZONTAL_ALIGNMENT_CENTER))
		if host.team_name == "White":
			var row := HBoxContainer.new()
			row.alignment = BoxContainer.ALIGNMENT_CENTER
			row.add_theme_constant_override("separation", 18)
			review_box.add_child(row)
			var approve := GameUi.button("Approve", Vector2(180, 52), host.team_accent)
			approve.pressed.connect(func(): host.request_action("approve_action", {"approved": true}))
			row.add_child(approve)
			var reject := GameUi.button("Return", Vector2(180, 52), host.team_accent)
			reject.pressed.connect(func(): host.request_action("approve_action", {"approved": false}))
			row.add_child(reject)

	content.add_child(GameUi.label("PLANNED OPERATIONS", 31))
	var planned_value = host.snapshot.get("PlannedActions", [])
	var planned: Array = planned_value if planned_value is Array else []
	if planned.is_empty():
		content.add_child(GameUi.label("No operations planned", 23))
	else:
		for action in planned:
			if action is Dictionary:
				var panel := GameUi.panel(0.74, GameUi.team_color(str(action.get("team", "White"))))
				var label := GameUi.label("%s   %s   wait %d" % [str(action.get("team", "")), str(action.get("display", "Action")), int(action.get("wait_time", 0))], 22)
				panel.add_child(label)
				content.add_child(panel)


func _team_status_panel(team: String) -> PanelContainer:
	var panel := GameUi.panel(0.86, GameUi.team_color(team))
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.custom_minimum_size = Vector2(0, 360)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 9)
	panel.add_child(box)
	box.add_child(GameUi.title("%s TEAM" % team.to_upper(), GameUi.team_color(team), 38))
	var prefix := "Iran" if team == "Red" else "Isreal"
	box.add_child(GameUi.label("IP %d     MP %d     PP %d" % [int(host.snapshot.get("%sIP" % prefix, 0)), int(host.snapshot.get("%sMP" % prefix, 0)), int(host.snapshot.get("%sPP" % prefix, 0))], 27, HORIZONTAL_ALIGNMENT_CENTER))
	var aircraft := _aircraft_rows(team)
	var operational := 0
	var damaged := 0
	for row in aircraft:
		if row is Dictionary:
			operational += int(row.get("operational", 0))
			damaged += int(row.get("damaged", 0))
	box.add_child(GameUi.label("Aircraft: %d operational / %d damaged" % [operational, damaged], 23, HORIZONTAL_ALIGNMENT_CENTER))
	var selected_value = host.snapshot.get("SelectedUpgrades", {})
	var selected: Dictionary = selected_value if selected_value is Dictionary else {}
	var upgrades: Array = selected.get(team, []) if selected.get(team, []) is Array else []
	box.add_child(GameUi.label("Upgrades: %d" % upgrades.size(), 23, HORIZONTAL_ALIGNMENT_CENTER))
	var river := _card_list("river", team)
	box.add_child(GameUi.label("River cards: %d" % river.size(), 23, HORIZONTAL_ALIGNMENT_CENTER))
	return panel


func _show_save() -> void:
	var content: VBoxContainer = host.begin_overlay("SAVE CAMPAIGN")
	var center := CenterContainer.new()
	center.custom_minimum_size = Vector2(0, 650)
	content.add_child(center)
	var panel := GameUi.panel(0.9, host.team_accent)
	panel.custom_minimum_size = Vector2(760, 330)
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 22)
	panel.add_child(box)
	var session_name := "Current campaign"
	if host.game_server != null and host.game_server.has_method("get_session_info"):
		session_name = str(host.game_server.get_session_info().get("name", session_name))
	box.add_child(GameUi.title(session_name.to_upper(), host.team_accent, 40))
	box.add_child(GameUi.label(GameRules.turn_label(host.snapshot), 29, HORIZONTAL_ALIGNMENT_CENTER))
	box.add_child(GameUi.label("The authoritative JSON save is stored by the server.", 23, HORIZONTAL_ALIGNMENT_CENTER))
	var save := GameUi.button("Save Campaign", Vector2(270, 60), host.team_accent)
	save.pressed.connect(func(): host.confirm_action("SAVE CAMPAIGN", "Append the current campaign state to the server save?", host.save_current_snapshot))
	box.add_child(save)


func _show_load() -> void:
	var content: VBoxContainer = host.begin_overlay("LOAD CAMPAIGN")
	host.request_save_list()
	if host.saved_games.is_empty():
		content.add_child(GameUi.label("No server saves are available", 28, HORIZONTAL_ALIGNMENT_CENTER))
		return
	for raw_save in host.saved_games:
		var save_info: Dictionary = raw_save if raw_save is Dictionary else {"name": str(raw_save)}
		var save_name := str(save_info.get("name", save_info.get("game_name", save_info.get("file", "Campaign"))))
		var panel := GameUi.panel(0.8, host.team_accent)
		content.add_child(panel)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 14)
		panel.add_child(row)
		var details := GameUi.label(save_name, 27)
		details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(details)
		var load_button := GameUi.button("Load", Vector2(140, 50), host.team_accent)
		load_button.pressed.connect(func(): host.confirm_action("LOAD CAMPAIGN", "Replace the active campaign with %s?" % save_name, func(): host.load_server_session(save_name)))
		row.add_child(load_button)
