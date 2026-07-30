extends Area2D

signal collected(pickup_type: String, at_position: Vector2, collector: Node)

const PICKUP_STYLES := {
	"repair": {
		"label": "Saha Onarimi",
		"core": Color("#8ce99a"),
		"glow": Color("#d9ffe1")
	},
	"shield": {
		"label": "Plazma Kalkani",
		"core": Color("#8bd3ff"),
		"glow": Color("#dff4ff")
	},
	"overdrive": {
		"label": "Overdrive",
		"core": Color("#92e8ff"),
		"glow": Color("#e7fdff")
	},
	"turbo": {
		"label": "Turbo Palet",
		"core": Color("#8ff9b5"),
		"glow": Color("#e3ffec")
	},
	"fortify": {
		"label": "Cekirdek Tahkimi",
		"core": Color("#ffd97a"),
		"glow": Color("#fff2bf")
	}
}

@export var pickup_type: String = "repair"
@export var lifetime: float = 10.0
var network_id: int = -1
var replica_mode := false

var _hover_time := 0.0
var _anchor_position := Vector2.ZERO


func _ready() -> void:
	add_to_group("pickups")
	collision_layer = 0
	collision_mask = 1
	monitoring = not replica_mode
	body_entered.connect(_on_body_entered)
	_anchor_position = global_position
	set_process(true)
	queue_redraw()


func configure(new_pickup_type: String) -> void:
	if PICKUP_STYLES.has(new_pickup_type):
		pickup_type = new_pickup_type
	else:
		pickup_type = "repair"

	queue_redraw()


func _process(delta: float) -> void:
	if replica_mode:
		_hover_time += delta
		queue_redraw()
		return

	_hover_time += delta
	lifetime -= delta

	global_position = _anchor_position + Vector2(0.0, sin(_hover_time * 2.8) * 5.0)
	queue_redraw()

	if lifetime <= 0.0:
		queue_free()


func _draw() -> void:
	var style: Dictionary = PICKUP_STYLES.get(pickup_type, PICKUP_STYLES["repair"])
	var core: Color = style["core"]
	var glow: Color = style["glow"]
	var aura := glow
	var ring := core
	var pulse := 22.0 + sin(_hover_time * 6.4) * 1.8
	aura.a = 0.16
	ring.a = 0.95

	draw_circle(Vector2.ZERO, pulse + 8.0, aura)
	draw_circle(Vector2.ZERO, pulse, core.darkened(0.2))
	draw_arc(Vector2.ZERO, pulse + 5.0, 0.0, TAU, 32, ring, 3.0)

	match pickup_type:
		"repair":
			draw_rect(Rect2(Vector2(-5.0, -14.0), Vector2(10.0, 28.0)), glow)
			draw_rect(Rect2(Vector2(-14.0, -5.0), Vector2(28.0, 10.0)), glow)
		"shield":
			draw_arc(Vector2.ZERO, 10.0, PI * 0.18, PI * 0.82, 18, glow, 4.0)
			draw_line(Vector2(-7.0, -2.0), Vector2(-7.0, 10.0), glow, 3.0)
			draw_line(Vector2(7.0, -2.0), Vector2(7.0, 10.0), glow, 3.0)
		"overdrive":
			draw_line(Vector2(-9.0, -10.0), Vector2(0.0, 0.0), glow, 4.0)
			draw_line(Vector2(0.0, 0.0), Vector2(-5.0, 0.0), glow, 4.0)
			draw_line(Vector2(3.0, -10.0), Vector2(12.0, 0.0), glow, 4.0)
			draw_line(Vector2(12.0, 0.0), Vector2(7.0, 0.0), glow, 4.0)
		"turbo":
			draw_line(Vector2(-10.0, 8.0), Vector2(0.0, -12.0), glow, 4.0)
			draw_line(Vector2(0.0, -12.0), Vector2(8.0, -2.0), glow, 4.0)
			draw_line(Vector2(8.0, -2.0), Vector2(-2.0, 12.0), glow, 4.0)
		"fortify":
			draw_rect(Rect2(Vector2(-13.0, -9.0), Vector2(26.0, 18.0)), glow, false, 4.0)
			draw_line(Vector2(-8.0, -9.0), Vector2(-8.0, -16.0), glow, 3.0)
			draw_line(Vector2(0.0, -9.0), Vector2(0.0, -16.0), glow, 3.0)
			draw_line(Vector2(8.0, -9.0), Vector2(8.0, -16.0), glow, 3.0)


func _on_body_entered(body: Node) -> void:
	if replica_mode:
		return

	if not body.is_in_group("player_tank"):
		return

	collected.emit(pickup_type, global_position, body)
	queue_free()


func set_replica_mode(enabled: bool) -> void:
	replica_mode = enabled
	monitoring = not enabled


func build_snapshot() -> Dictionary:
	return {
		"id": network_id,
		"type": pickup_type,
		"x": global_position.x,
		"y": global_position.y
	}


func apply_snapshot(snapshot: Dictionary) -> void:
	network_id = int(snapshot.get("id", network_id))
	configure(String(snapshot.get("type", pickup_type)))
	_anchor_position = Vector2(float(snapshot.get("x", global_position.x)), float(snapshot.get("y", global_position.y)))
	global_position = _anchor_position
