extends Control

const CONNECT_SCENE: String = "res://UI/MainScenes/Connect.tscn"

@export var play_button: BaseButton


func _ready() -> void:
	if play_button == null:
		play_button = get_node_or_null("CanvasLayer/VBoxContainer/CenterContainer2/PlayButton") as BaseButton

	if play_button == null:
		push_error("Beginning scene is missing PlayButton.")
		return

	play_button.pressed.connect(_on_play_pressed)


func _on_play_pressed() -> void:
	get_tree().change_scene_to_file(CONNECT_SCENE)
