extends Camera3D
class_name FreecamController

## Caméra libre noclip pour le debug. Conservée tout le long du projet
## (voir ROADMAP Jalon 1). Activation/désactivation via toggle_active().

@export var move_speed: float = 8.0
@export var boost_multiplier: float = 3.0
@export var mouse_sensitivity: float = 0.0025
@export var vertical_limit_deg: float = 89.0
@export var start_active: bool = true

var _active: bool = false
var _yaw: float = 0.0
var _pitch: float = 0.0

func _ready() -> void:
	_yaw = rotation.y
	_pitch = rotation.x
	set_active(start_active)

func set_active(value: bool) -> void:
	_active = value
	if _active:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		current = true
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func toggle_active() -> void:
	set_active(not _active)

func _unhandled_input(event: InputEvent) -> void:
	if not _active:
		return

	if event is InputEventMouseMotion:
		_yaw -= event.relative.x * mouse_sensitivity
		_pitch -= event.relative.y * mouse_sensitivity
		_pitch = clamp(_pitch, -deg_to_rad(vertical_limit_deg), deg_to_rad(vertical_limit_deg))
		rotation.y = _yaw
		rotation.x = _pitch

	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		set_active(false)

func _process(delta: float) -> void:
	if not _active:
		return

	var input_dir := Vector3.ZERO
	input_dir.x = Input.get_axis("ui_left", "ui_right")
	input_dir.z = Input.get_axis("ui_up", "ui_down")

	var vertical := 0.0
	if Input.is_key_pressed(KEY_E):
		vertical += 1.0
	if Input.is_key_pressed(KEY_Q):
		vertical -= 1.0

	var speed := move_speed
	if Input.is_key_pressed(KEY_SHIFT):
		speed *= boost_multiplier

	# Déplacement relatif à l'orientation caméra (yaw + pitch), sans collision (noclip).
	var basis_move := global_transform.basis
	var move := (basis_move.x * input_dir.x) + (basis_move.z * input_dir.z) + (Vector3.UP * vertical)
	if move.length() > 0.0:
		move = move.normalized()

	global_position += move * speed * delta

# --- Notes d'intégration ---
# - Rattacher ce script directement à un Camera3D placé dans la scène de test
#   (Jalon 1 : "Scène de test minimale (sol + scatter + freecam)").
# - Les actions "ui_left/right/up/down" utilisent les inputs par défaut de Godot
#   (flèches). Remapper vers WASD dans Project Settings > Input Map si besoin,
#   ou dupliquer les actions en "move_forward/back/left/right" dédiées.
# - ESC libère la souris ; cliquer sur la vue reprend la capture (à brancher
#   sur un InputEventMouseButton si tu veux ce comportement).
