extends "res://UI/GameScenes/team_game_base.gd"
class_name CombatTeamGameBase


func combat_menu_entries() -> Array[Dictionary]:
	return [
		{"label": "Log Of Actions", "screen": "log"},
		{"label": "Political Track", "screen": "political"},
		{"label": "Actions", "screen": "actions"},
		{"label": "Aircraft Status", "screen": "aircraft"},
		{"label": "Upgrades", "screen": "upgrades"},
		{"label": "River", "screen": "river"},
		{"label": "Quit", "screen": "quit"}
	]
