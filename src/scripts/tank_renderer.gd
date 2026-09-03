extends RefCounted


static func draw_player_tank(canvas: CanvasItem, profile: Dictionary, flash_mix: float = 0.0, turbo: bool = false, overdrive: bool = false, shield_strength: float = 0.0) -> void:
	var body := Color(String(profile.get("body_color", "#7fb069")))
	var turret := Color(String(profile.get("turret_color", "#d3ad58")))
	var track := Color(String(profile.get("track_color", "#2e3945")))
	var accent := Color(String(profile.get("accent_color", "#fff0b0")))
	var style_id := String(profile.get("style_id", "akinci"))
	if turbo:
		body = body.lerp(Color("#9be58f"), 0.3)
	if overdrive:
		turret = turret.lerp(Color("#92e8ff"), 0.45)
	body = body.lerp(Color.WHITE, clampf(flash_mix, 0.0, 1.0))
	turret = turret.lerp(Color.WHITE, clampf(flash_mix, 0.0, 1.0))

	# Soft floor shadow gives the tank weight without using a bitmap texture.
	canvas.draw_colored_polygon(_ellipse_points(Vector2(2.0, 5.0), Vector2(28.0, 32.0), 28), Color(0.0, 0.0, 0.0, 0.3))

	_draw_rounded_rect(canvas, Rect2(-25.0, -25.0, 10.0, 50.0), track.darkened(0.36), track.lightened(0.13), 5.0, 1)
	_draw_rounded_rect(canvas, Rect2(15.0, -25.0, 10.0, 50.0), track.darkened(0.36), track.lightened(0.13), 5.0, 1)
	for y in range(-19, 23, 8):
		canvas.draw_line(Vector2(-23.0, y), Vector2(-17.0, y), track.lightened(0.28), 1.4, true)
		canvas.draw_line(Vector2(17.0, y), Vector2(23.0, y), track.lightened(0.28), 1.4, true)

	_draw_rounded_rect(canvas, Rect2(-19.0, -24.0, 38.0, 48.0), body.darkened(0.12), accent.darkened(0.3), 8.0, 2)
	var glacis := PackedVector2Array([Vector2(-16.0, -23.0), Vector2(16.0, -23.0), Vector2(19.0, -12.0), Vector2(15.0, -4.0), Vector2(-15.0, -4.0), Vector2(-19.0, -12.0)])
	canvas.draw_colored_polygon(glacis, body.lightened(0.1))
	canvas.draw_polyline(_closed(glacis), accent.darkened(0.2), 1.4, true)
	_draw_rounded_rect(canvas, Rect2(-14.0, 7.0, 28.0, 12.0), body.darkened(0.2), body.lightened(0.2), 4.0, 1)
	canvas.draw_line(Vector2(-11.0, 2.0), Vector2(11.0, 2.0), body.lightened(0.23), 1.2, true)
	canvas.draw_circle(Vector2(-13.0, -16.0), 2.3, accent.lightened(0.25), true, -1.0, true)
	canvas.draw_circle(Vector2(13.0, -16.0), 2.3, accent.lightened(0.25), true, -1.0, true)

	# Barrel has a dark housing, a colored inner tube and a distinct muzzle brake.
	canvas.draw_line(Vector2(0.0, -10.0), Vector2(0.0, -40.0), track.darkened(0.42), 10.0, true)
	canvas.draw_line(Vector2(0.0, -11.0), Vector2(0.0, -42.0), turret.lightened(0.04), 5.5, true)
	_draw_rounded_rect(canvas, Rect2(-6.0, -45.0, 12.0, 7.0), track.darkened(0.28), accent.darkened(0.25), 2.5, 1)

	canvas.draw_circle(Vector2.ZERO, 13.5, track.darkened(0.45), true, -1.0, true)
	canvas.draw_circle(Vector2.ZERO, 11.5, turret, true, -1.0, true)
	canvas.draw_arc(Vector2.ZERO, 11.5, 0.0, TAU, 36, accent.darkened(0.18), 1.8, true)
	canvas.draw_circle(Vector2(0.0, 1.0), 6.4, turret.darkened(0.18), true, -1.0, true)
	canvas.draw_arc(Vector2(0.0, 1.0), 6.4, 0.0, TAU, 28, turret.lightened(0.3), 1.2, true)
	_draw_emblem(canvas, style_id, accent)

	if turbo:
		canvas.draw_line(Vector2(-10.0, 23.0), Vector2(-15.0, 35.0), Color("#8ff9b5"), 3.0, true)
		canvas.draw_line(Vector2(10.0, 23.0), Vector2(15.0, 35.0), Color("#8ff9b5"), 3.0, true)
	if shield_strength > 0.0:
		var shield := Color("#8bd3ff")
		var fill := Color(shield, 0.06 + clampf(shield_strength, 0.0, 1.0) * 0.08)
		canvas.draw_circle(Vector2.ZERO, 34.0, fill, true, -1.0, true)
		canvas.draw_arc(Vector2.ZERO, 37.0, 0.0, TAU, 48, shield, 2.4, true)


static func _draw_emblem(canvas: CanvasItem, style_id: String, color: Color) -> void:
	match style_id:
		"gece":
			canvas.draw_arc(Vector2(0.0, 1.0), 3.2, -PI * 0.65, PI * 0.65, 16, color, 1.8, true)
		"col":
			canvas.draw_line(Vector2(-3.5, 1.0), Vector2(3.5, 1.0), color, 1.8, true)
			canvas.draw_line(Vector2(0.0, -2.5), Vector2(0.0, 4.5), color, 1.8, true)
		"neon":
			canvas.draw_circle(Vector2(0.0, 1.0), 2.8, color, false, 1.8, true)
			canvas.draw_circle(Vector2(0.0, 1.0), 1.0, color.lightened(0.2), true, -1.0, true)
		"orman":
			var leaf := PackedVector2Array([Vector2(0.0, -3.0), Vector2(3.2, 0.5), Vector2(0.0, 4.2), Vector2(-3.2, 0.5)])
			canvas.draw_colored_polygon(leaf, color)
		_:
			canvas.draw_polyline(PackedVector2Array([Vector2(-4.0, -1.0), Vector2(0.0, 4.0), Vector2(4.0, -1.0)]), color, 2.0, true)


static func _draw_rounded_rect(canvas: CanvasItem, rect: Rect2, fill: Color, border: Color, radius: float, border_width: int) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(border_width)
	style.corner_radius_top_left = int(radius)
	style.corner_radius_top_right = int(radius)
	style.corner_radius_bottom_left = int(radius)
	style.corner_radius_bottom_right = int(radius)
	canvas.draw_style_box(style, rect)


static func _ellipse_points(center: Vector2, radii: Vector2, count: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in range(count):
		var angle := TAU * float(index) / float(count)
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	return points


static func _closed(points: PackedVector2Array) -> PackedVector2Array:
	var result := PackedVector2Array(points)
	if not result.is_empty():
		result.append(result[0])
	return result
