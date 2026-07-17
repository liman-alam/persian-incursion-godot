extends "res://UI/GameScenes/team_game_base.gd"


func _configure_team() -> void:
	team_name = "White"
	team_accent = GameUi.WHITE


func _menu_entries() -> Array[Dictionary]:
	return [
		{"label": "Upgrades", "screen": "upgrades"},
		{"label": "Send River", "screen": "send_river"},
		{"label": "Team Track", "screen": "team_track"},
		{"label": "Political Track", "screen": "political"},
		{"label": "Log Of Actions", "screen": "log"},
		{"label": "Save Game", "screen": "save"},
		{"label": "Load Game", "screen": "load"},
		{"label": "Target Status", "screen": "targets"},
		{"label": "Quit", "screen": "quit"}
	]
