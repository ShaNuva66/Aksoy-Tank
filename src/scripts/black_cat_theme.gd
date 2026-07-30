extends RefCounted

const BACKGROUND := Color("#05070b")
const BACKGROUND_ALT := Color("#0b0f14")
const SURFACE := Color("#101419")
const SURFACE_ALT := Color("#151a21")
const BORDER := Color("#2b3138")
const TEXT := Color("#f6f0e3")
const MUTED := Color("#c1b498")
const ACCENT := Color("#f3c868")
const ACCENT_SOFT := Color("#ffe3a1")
const DANGER := Color("#cb6b6b")


static func make_panel_style(fill: Color = SURFACE_ALT, border: Color = BORDER, radius: int = 26, border_width: int = 2) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(border_width)
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.shadow_color = Color(0, 0, 0, 0.28)
	style.shadow_size = 18
	return style


static func make_button_style(fill: Color, border: Color, radius: int = 22) -> StyleBoxFlat:
	return make_panel_style(fill, border, radius, 2)


static func make_input_style(fill: Color, border: Color, radius: int = 18) -> StyleBoxFlat:
	return make_panel_style(fill, border, radius, 2)


static func apply_button(button: Button, accent: Color = ACCENT, fill: Color = SURFACE_ALT, text_color: Color = TEXT) -> void:
	button.add_theme_stylebox_override("normal", make_button_style(fill, border_mix(fill, accent, 0.26)))
	button.add_theme_stylebox_override("hover", make_button_style(fill.lightened(0.05), accent))
	button.add_theme_stylebox_override("pressed", make_button_style(fill.darkened(0.08), accent.lightened(0.12)))
	button.add_theme_stylebox_override("disabled", make_button_style(fill.darkened(0.03), BORDER))
	button.add_theme_color_override("font_color", text_color)
	button.add_theme_color_override("font_hover_color", text_color)
	button.add_theme_color_override("font_pressed_color", ACCENT_SOFT)
	button.add_theme_color_override("font_disabled_color", MUTED.darkened(0.32))


static func apply_line_edit(line_edit: LineEdit) -> void:
	line_edit.add_theme_stylebox_override("normal", make_input_style(SURFACE, border_mix(SURFACE, ACCENT, 0.12)))
	line_edit.add_theme_stylebox_override("focus", make_input_style(SURFACE_ALT, ACCENT))
	line_edit.add_theme_stylebox_override("read_only", make_input_style(SURFACE, BORDER))
	line_edit.add_theme_color_override("font_color", TEXT)
	line_edit.add_theme_color_override("font_placeholder_color", MUTED.darkened(0.15))
	line_edit.add_theme_color_override("caret_color", ACCENT_SOFT)
	line_edit.add_theme_color_override("selection_color", Color(ACCENT.r, ACCENT.g, ACCENT.b, 0.3))


static func border_mix(base: Color, accent: Color, amount: float) -> Color:
	return base.lerp(accent, clampf(amount, 0.0, 1.0))
