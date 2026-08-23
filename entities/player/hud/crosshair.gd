extends Control
class_name Crosshair

@export var color_default: Color = Color(1, 1, 1, 0.8)
@export var color_active: Color = Color(1, 0.85, 0.2, 1.0)
@export var line_length: float = 6.0
@export var line_gap: float = 4.0
@export var line_width: float = 2.0

var _active: bool = false

func set_active(active: bool) -> void:
	if active == _active:
		return
	_active = active
	queue_redraw()

func _draw() -> void:
	var center := size * 0.5
	var color := color_active if _active else color_default
	var segments := [
		[Vector2(0, -line_gap - line_length), Vector2(0, -line_gap)],
		[Vector2(0, line_gap), Vector2(0, line_gap + line_length)],
		[Vector2(-line_gap - line_length, 0), Vector2(-line_gap, 0)],
		[Vector2(line_gap, 0), Vector2(line_gap + line_length, 0)],
	]
	for seg in segments:
		draw_line(center + seg[0], center + seg[1], color, line_width)
