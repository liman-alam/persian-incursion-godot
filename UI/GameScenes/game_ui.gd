extends RefCounted
class_name GameUi

const GOLD := Color("e99c1f")
const CREAM := Color("f5f0d5")
const INK := Color("08140c")
const GREEN := Color("075c25")
const GREEN_HOVER := Color("0b7932")
const GREEN_PRESSED := Color("06451c")
const PANEL_GREEN := Color("07180e")
const RED := Color("d83a38")
const BLUE := Color("3f70e8")
const WHITE := Color("f4f0df")


static func panel(alpha: float = 0.9, border_color: Color = GOLD, radius: int = 8) -> PanelContainer:
	var result := PanelContainer.new()
	result.add_theme_stylebox_override("panel", panel_style(alpha, border_color, radius))
	return result


static func panel_style(alpha: float = 0.9, border_color: Color = GOLD, radius: int = 8) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(PANEL_GREEN.r, PANEL_GREEN.g, PANEL_GREEN.b, alpha)
	style.border_color = border_color
	style.set_border_width_all(2)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 14.0
	style.content_margin_top = 12.0
	style.content_margin_right = 14.0
	style.content_margin_bottom = 12.0
	style.shadow_color = Color(0, 0, 0, 0.35)
	style.shadow_size = 5
	return style


static func button(text: String, minimum_size: Vector2 = Vector2(160, 52), accent: Color = GOLD) -> Button:
	var result := Button.new()
	result.text = text
	result.custom_minimum_size = minimum_size
	result.focus_mode = Control.FOCUS_ALL
	style_button(result, accent)
	return result


static func style_button(button_node: BaseButton, accent: Color = GOLD) -> void:
	button_node.add_theme_color_override("font_color", CREAM)
	button_node.add_theme_color_override("font_hover_color", Color.WHITE)
	button_node.add_theme_color_override("font_pressed_color", Color.WHITE)
	button_node.add_theme_color_override("font_disabled_color", Color(0.7, 0.7, 0.66, 0.72))
	button_node.add_theme_stylebox_override("normal", button_style(GREEN, accent))
	button_node.add_theme_stylebox_override("hover", button_style(GREEN_HOVER, accent.lightened(0.08)))
	button_node.add_theme_stylebox_override("pressed", button_style(GREEN_PRESSED, accent.darkened(0.08)))
	button_node.add_theme_stylebox_override("focus", button_style(GREEN_HOVER, CREAM, 3))
	button_node.add_theme_stylebox_override("disabled", button_style(Color("26322b"), Color("726742")))


static func button_style(background: Color, border_color: Color, border_width: int = 2) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border_color
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(7)
	style.content_margin_left = 12.0
	style.content_margin_top = 7.0
	style.content_margin_right = 12.0
	style.content_margin_bottom = 7.0
	style.shadow_color = Color(0, 0, 0, 0.28)
	style.shadow_size = 3
	return style


static func label(text: String, font_size: int = 30, alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var result := Label.new()
	result.text = text
	result.horizontal_alignment = alignment
	result.add_theme_font_size_override("font_size", font_size)
	result.add_theme_color_override("font_color", CREAM)
	return result


static func title(text: String, accent: Color, font_size: int = 54) -> Label:
	var result := label(text, font_size, HORIZONTAL_ALIGNMENT_CENTER)
	result.add_theme_color_override("font_color", accent)
	result.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	result.add_theme_constant_override("shadow_offset_x", 3)
	result.add_theme_constant_override("shadow_offset_y", 3)
	return result


static func margin(child: Control, amount: int = 16) -> MarginContainer:
	var result := MarginContainer.new()
	result.add_theme_constant_override("margin_left", amount)
	result.add_theme_constant_override("margin_top", amount)
	result.add_theme_constant_override("margin_right", amount)
	result.add_theme_constant_override("margin_bottom", amount)
	result.add_child(child)
	return result


static func texture(path: String, minimum_size: Vector2, stretch_mode: TextureRect.StretchMode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED) -> TextureRect:
	var result := TextureRect.new()
	result.custom_minimum_size = minimum_size
	result.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	result.stretch_mode = stretch_mode
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists(path):
		result.texture = load(path)
	return result


static func separator() -> HSeparator:
	var result := HSeparator.new()
	result.add_theme_constant_override("separation", 2)
	return result


static func place(control: Control, left: float, top: float, right: float, bottom: float, offsets: Rect2 = Rect2()) -> void:
	control.set_anchor(SIDE_LEFT, left)
	control.set_anchor(SIDE_TOP, top)
	control.set_anchor(SIDE_RIGHT, right)
	control.set_anchor(SIDE_BOTTOM, bottom)
	control.offset_left = offsets.position.x
	control.offset_top = offsets.position.y
	control.offset_right = offsets.end.x
	control.offset_bottom = offsets.end.y


static func format_time(total_seconds: int) -> String:
	var clean_seconds := maxi(0, total_seconds)
	return "%02d:%02d" % [clean_seconds / 60, clean_seconds % 60]


static func team_color(team_name: String) -> Color:
	match team_name:
		"Red":
			return RED
		"Blue":
			return BLUE
		_:
			return WHITE
