extends SceneTree

const GameRules = preload("res://server/game_rules.gd")
const TEAM_SCENES := {
	"White": "res://UI/GameScenes/WhiteTeam.tscn",
	"Red": "res://UI/GameScenes/RedTeam.tscn",
	"Blue": "res://UI/GameScenes/BlueTeam.tscn"
}

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var neutral := GameRules.make_default_snapshot()
	var totals := GameRules.political_point_totals(neutral.get("PoliticalTrack", {}))
	_expect(totals.get("Blue", {}) == {"IP": 4, "MP": 9, "PP": 5}, "Neutral Blue political totals changed")
	_expect(totals.get("Red", {}) == {"IP": 6, "MP": 5, "PP": 3}, "Neutral Red political totals changed")
	var generated := GameRules.generate_points_from_track(neutral)
	_expect(int(generated.get("IsrealIP", -1)) == 4, "Blue IP did not generate")
	_expect(int(generated.get("IsrealMP", -1)) == 9, "Blue MP did not generate")
	_expect(int(generated.get("IsrealPP", -1)) == 5, "Blue PP did not generate")
	_expect(int(generated.get("IranIP", -1)) == 6, "Red IP did not generate")
	_expect(int(generated.get("IranMP", -1)) == 5, "Red MP did not generate")
	_expect(int(generated.get("IranPP", -1)) == 3, "Red PP did not generate")

	for team_name in TEAM_SCENES:
		await _check_scene(team_name, TEAM_SCENES[team_name], generated)
	for _frame in range(4):
		await process_frame

	if failures.is_empty():
		print("TEAM_GAME_UI_SMOKE: PASS")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		print("TEAM_GAME_UI_SMOKE: FAIL (%d)" % failures.size())
		quit(1)


func _check_scene(team_name: String, scene_path: String, generated: Dictionary) -> void:
	var packed := load(scene_path) as PackedScene
	_expect(packed != null, "%s scene failed to load" % team_name)
	if packed == null:
		return
	var scene = packed.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	_expect(scene.team_name == team_name, "%s scene configured as %s" % [team_name, str(scene.team_name)])
	_expect(scene.get_node_or_null("%Dashboard") != null, "%s dashboard is missing" % team_name)
	_expect(scene.get_node_or_null("%TitleLabel") is Button, "%s Main Menu button is missing" % team_name)
	_expect(scene.get_node_or_null("%ChatHistory") is RichTextLabel, "%s chat panel is missing" % team_name)
	_expect(scene.get_node_or_null("%MenuButton01") is Button, "%s action panel is missing" % team_name)
	_expect(scene.get_node_or_null("%IPLabel") is Label, "%s points HUD is missing" % team_name)
	_expect((scene.get_node("%TitleLabel") as Button).pressed.get_connections().size() == 1, "%s Main Menu button is not connected" % team_name)
	_expect((scene.get_node("%SendChatButton") as Button).pressed.get_connections().size() == 1, "%s chat Send button is not connected" % team_name)
	_expect((scene.get_node("%D6Button") as Button).pressed.get_connections().size() == 1, "%s D6 button is not connected" % team_name)
	_expect((scene.get_node("%PassMoveButton") as Button).pressed.get_connections().size() == 1, "%s Pass button is not connected" % team_name)
	var entries: Array[Dictionary] = scene._menu_entries()
	_expect(entries.size() == (9 if team_name == "White" else 8), "%s action menu is incomplete" % team_name)
	for index in range(entries.size()):
		var menu_button := scene.get_node("%%MenuButton%02d" % (index + 1)) as Button
		_expect(menu_button.pressed.get_connections().size() == 1, "%s menu button %d is not connected" % [team_name, index + 1])

	(scene.get_node("%TitleLabel") as Button).pressed.emit()
	await process_frame
	_expect(scene.modal_root != null and is_instance_valid(scene.modal_root), "%s Main Menu did not open" % team_name)
	scene.close_modal()
	(scene.get_node("%MenuButton01") as Button).pressed.emit()
	await process_frame
	_expect(scene.overlay_root != null and is_instance_valid(scene.overlay_root), "%s first action button did not open" % team_name)
	scene.close_overlay()

	scene.snapshot = generated.duplicate(true)
	scene.snapshot["ChangeTeam"] = team_name if team_name != "White" else "Blue"
	scene._update_from_snapshot()
	var expected_prefix := "Iran" if team_name == "Red" else "Isreal"
	_expect((scene.get_node("%IPLabel") as Label).text == str(generated.get("%sIP" % expected_prefix, -1)), "%s IP HUD did not refresh" % team_name)
	_expect((scene.get_node("%MPLabel") as Label).text == str(generated.get("%sMP" % expected_prefix, -1)), "%s MP HUD did not refresh" % team_name)
	_expect((scene.get_node("%PPLabel") as Label).text == str(generated.get("%sPP" % expected_prefix, -1)), "%s PP HUD did not refresh" % team_name)
	if team_name == "White":
		var review: String = scene.feature_screens._political_generation_message()
		_expect(review.contains("BLUE   IP 4   MP 9   PP 5"), "Political review omitted Blue totals")
		_expect(review.contains("RED     IP 6   MP 5   PP 3"), "Political review omitted Red totals")
		_expect(review.contains("strategic event"), "Political review omitted the Morning situation rule")
	scene.feature_screens.host = null
	scene.feature_screens = null
	scene.queue_free()
	await process_frame


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
