extends Control


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var shortest_side: float = minf(size.x, size.y)
	var inset: float = maxf(9.0, shortest_side * 0.16)
	var line_width: float = maxf(7.0, shortest_side * 0.16)
	var from_a: Vector2 = Vector2(inset, inset)
	var to_a: Vector2 = Vector2(size.x - inset, size.y - inset)
	var from_b: Vector2 = Vector2(size.x - inset, inset)
	var to_b: Vector2 = Vector2(inset, size.y - inset)

	var shadow: Color = Color(0.0, 0.0, 0.0, 0.68)
	var border: Color = Color(0.96, 0.68, 0.16, 0.98)
	var red: Color = Color(0.88, 0.05, 0.045, 0.96)

	draw_line(from_a + Vector2(2, 3), to_a + Vector2(2, 3), shadow, line_width + 8.0, true)
	draw_line(from_b + Vector2(2, 3), to_b + Vector2(2, 3), shadow, line_width + 8.0, true)
	draw_line(from_a, to_a, border, line_width + 4.0, true)
	draw_line(from_b, to_b, border, line_width + 4.0, true)
	draw_line(from_a, to_a, red, line_width, true)
	draw_line(from_b, to_b, red, line_width, true)
