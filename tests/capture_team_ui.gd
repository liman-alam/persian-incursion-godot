extends SceneTree

const GameRules = preload("res://server/game_rules.gd")
const TEAM_SCENES := {
	"White": "res://UI/GameScenes/WhiteTeam.tscn",
	"Red": "res://UI/GameScenes/RedTeam.tscn",
	"Blue": "res://UI/GameScenes/BlueTeam.tscn"
}


func _initialize() -> void:
	call_deferred("_capture")


func _capture() -> void:
	var options := _options()
	var team_name := str(options.get("team", "White")).capitalize()
	var scene_path := str(TEAM_SCENES.get(team_name, TEAM_SCENES.White))
	var width := maxi(960, int(options.get("width", 1920)))
	var height := maxi(540, int(options.get("height", 1080)))
	var output_path := str(options.get("output", "res://tmp/team_ui_%s_%dx%d.png" % [team_name.to_lower(), width, height]))
	root.size = Vector2i(width, height)
	var scene = (load(scene_path) as PackedScene).instantiate()
	root.add_child(scene)
	for _frame in range(8):
		await process_frame
	if str(options.get("generated", "false")).to_lower() == "true":
		scene.snapshot = GameRules.generate_points_from_track(scene.snapshot)
		scene.snapshot["ChangeTeam"] = "Blue" if team_name == "White" else team_name
		scene._update_from_snapshot()
	var screen_name := str(options.get("screen", ""))
	if not screen_name.is_empty():
		scene.feature_screens.show(screen_name)
		await process_frame
	if str(options.get("review", "false")).to_lower() == "true":
		scene.feature_screens._submit_political(true)
		await process_frame
	var image := root.get_texture().get_image()
	if image.is_empty():
		push_error("Viewport capture returned an empty image.")
		quit(1)
		return
	var absolute_output := ProjectSettings.globalize_path(output_path)
	var result := image.save_png(absolute_output)
	if result != OK:
		push_error("Could not save capture to %s (error %d)." % [absolute_output, result])
		quit(1)
		return
	print("TEAM_UI_CAPTURE: %s" % absolute_output)
	quit(0)


func _options() -> Dictionary:
	var result: Dictionary = {}
	for argument in OS.get_cmdline_user_args():
		var parts := argument.split("=", true, 1)
		if parts.size() == 2:
			result[str(parts[0]).trim_prefix("--")] = parts[1]
	return result
