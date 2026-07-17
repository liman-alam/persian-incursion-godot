extends Node

const CLIENT_SCENE: String = "res://UI/MainScenes/Beginning.tscn"
const SERVER_SCENE: String = "res://Scripts/dedicated_server.tscn"


func _ready() -> void:
	call_deferred("_open_start_scene")


func _open_start_scene() -> void:
	var scene_path := CLIENT_SCENE
	var executable_name := OS.get_executable_path().get_file().to_lower()
	var args := OS.get_cmdline_args()

	if OS.has_feature("phantom_arrow_server") or executable_name.contains("server") or args.has("--server"):
		scene_path = SERVER_SCENE

	get_tree().change_scene_to_file(scene_path)
