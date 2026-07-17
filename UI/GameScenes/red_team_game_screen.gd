extends "res://UI/GameScenes/combat_team_game_base.gd"


func _configure_team() -> void:
	team_name = "Red"
	team_accent = GameUi.RED


func _menu_entries() -> Array[Dictionary]:
	return [
		{"label": "Log Of Actions", "screen": "log"},
		{"label": "Political Track", "screen": "political"},
		{"label": "Actions", "screen": "actions"},
		{"label": "Aircraft Status", "screen": "aircraft"},
		{"label": "Upgrades", "screen": "upgrades"},
		{"label": "River", "screen": "river"},
		{"label": "Quit", "screen": "quit"},
		{"label": "Target Status", "screen": "targets"}
	]
