extends CharacterBody3D
class_name PlayerController

## Contrôleur du protagoniste unique jouable (voir GDD "Un seul perso jouable").
## Vue incarnée première personne, temps réel. Locomotion + caméra uniquement —
## le système d'interaction et la state machine d'actions (idle/récolte/
## construction) sont des scripts séparés (Jalon 3, prochaines étapes).

@export var move_speed: float = 5.0
@export var mouse_sensitivity: float = 0.0025
@export var vertical_limit_deg: float = 89.0
@export var acceleration: float = 12.0  # lissage du départ/arrêt, évite un mouvement trop robotique

@export_group("Step-up")
@export var step_height: float = 0.35  # hauteur max de marche franchissable auto (à ajuster selon la hauteur réelle des Platform_Stairs_*)
@export var step_check_distance: float = 0.3  # distance testée devant le joueur pour détecter une marche

@export_group("Sprint & saut")
@export var sprint_multiplier: float = 1.6
@export var jump_velocity: float = 4.5
## Fenêtre de tolérance après avoir quitté le sol : évite le saut "avalé"
## quand on appuie une frame trop tard en sortant d'un rebord.
@export var coyote_time: float = 0.12
@export var sprint_fov_bonus: float = 8.0
@export var fov_lerp_speed: float = 8.0
@export_group("")

## Mains occupées = ni course ni saut (décision de conception : le portage
## d'un objet lourd immobilise le protagoniste au rythme de la marche).
@export_node_path("Node") var carry_controller_path: NodePath = NodePath("Camera3D/CarryController")

@export_node_path("Camera3D") var camera_path: NodePath = NodePath("Camera3D")

var _camera: Camera3D
var _yaw: float = 0.0
var _pitch: float = 0.0
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)
var _carry_controller: CarryController
var _coyote_timer: float = 0.0
var _base_fov: float = 75.0
var _is_active: bool = true

var _input_enabled: bool = true

func set_input_enabled(enabled: bool) -> void:
	_input_enabled = enabled

func _ready() -> void:
	_camera = get_node(camera_path)
	_carry_controller = get_node_or_null(carry_controller_path)
	_base_fov = _camera.fov
	_yaw = rotation.y
	_yaw = rotation.y
	_pitch = _camera.rotation.x
	set_active(_is_active)

## Active/désactive le contrôleur (mouvement + caméra + capture souris).
## Utilisé par le switch debug cam pour céder la main au FreecamController
## sans que les deux ne se marchent dessus sur les mêmes touches.
func set_active(value: bool) -> void:
	_is_active = value
	_camera.current = value
	set_physics_process(value)

	if value:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if not _is_active:
		return

	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseButton and event.pressed:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		return

	if event is InputEventMouseMotion:
		_yaw -= event.relative.x * mouse_sensitivity
		_pitch -= event.relative.y * mouse_sensitivity
		_pitch = clamp(_pitch, -deg_to_rad(vertical_limit_deg), deg_to_rad(vertical_limit_deg))

		rotation.y = _yaw
		_camera.rotation.x = _pitch

	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _physics_process(delta: float) -> void:
	var hands_free: bool = _carry_controller == null or not _carry_controller.is_carrying()

	# Gravité : nécessaire pour rester collé au sol sur les irrégularités du
	# terrain scatterisé, et pour la retombée du saut.
	if is_on_floor():
		velocity.y = 0.0
		_coyote_timer = coyote_time
	else:
		velocity.y -= _gravity * delta
		_coyote_timer = maxf(_coyote_timer - delta, 0.0)

	if hands_free and _input_enabled and _coyote_timer > 0.0 and Input.is_action_just_pressed("jump"):
		velocity.y = jump_velocity
		_coyote_timer = 0.0  # sinon la fenêtre coyote autorise un second saut en l'air

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var move_basis := transform.basis
	var target_direction := (move_basis.x * input_dir.x) + (move_basis.z * input_dir.y)

	if target_direction.length() > 0.0:
		target_direction = target_direction.normalized()

	var sprinting: bool = hands_free and _input_enabled and Input.is_action_pressed("sprint") and target_direction.length() > 0.0
	var current_speed := move_speed * (sprint_multiplier if sprinting else 1.0)

	# Kick de FOV : lissé ici plutôt qu'en tween, pour suivre le lâcher de
	# touche en cours de course sans avoir à annuler un tween en vol.
	var target_fov := _base_fov + (sprint_fov_bonus if sprinting else 0.0)
	_camera.fov = lerpf(_camera.fov, target_fov, fov_lerp_speed * delta)

	var target_velocity := target_direction * current_speed

	velocity.x = move_toward(velocity.x, target_velocity.x, acceleration * delta * current_speed)
	velocity.z = move_toward(velocity.z, target_velocity.z, acceleration * delta * current_speed)

	if is_on_floor() and target_direction.length() > 0.0:
		_try_step_up(target_direction)

	move_and_slide()

## Simule un "step-up" (Godot n'en a pas d'intégré pour CharacterBody3D) :
## si un déplacement horizontal est bloqué par un obstacle bas (contremarche
## d'escalier, rebord), on teste si la même trajectoire passerait plus haut ;
## si oui, on remonte le joueur pour qu'il se pose sur la marche au lieu de
## rester coincé contre elle. Ne fait rien face à un vrai mur (bloqué même
## en haut) ou si rien n'obstrue le chemin (cas normal, sort tôt).
func _try_step_up(direction: Vector3) -> void:
	var motion := direction * step_check_distance

	if not test_move(global_transform, motion):
		return  # rien ne bloque à hauteur actuelle, pas de marche à franchir

	var raised_transform := global_transform
	raised_transform.origin += Vector3.UP * step_height

	if test_move(raised_transform, motion):
		return  # bloqué même en hauteur -> vrai mur, pas une marche franchissable

	# Le chemin est libre une fois surélevé : on redescend depuis là pour se
	# poser précisément sur la marche plutôt que de rester en l'air.
	var settle_transform := raised_transform
	settle_transform.origin += motion

	var collision := KinematicCollision3D.new()
	if test_move(settle_transform, Vector3.DOWN * step_height, collision):
		global_position += Vector3.UP * step_height + collision.get_travel()

# --- Notes d'intégration ---
# - Ce script attend un Camera3D enfant nommé "Camera3D" par défaut (modifiable
#   via camera_path dans l'inspecteur). Attache-le à la tête d'un CharacterBody3D
#   avec une CollisionShape3D (capsule recommandée, ~0.4 rayon / 1.8 hauteur).
# - Actions input requises dans Project Settings > Input Map :
#   move_forward, move_back, move_left, move_right (WASD par ex.)
#   Contrairement à FreecamController qui utilise les actions ui_* par défaut,
#   celui-ci attend des actions DÉDIÉES pour ne pas entrer en conflit avec
#   d'éventuels menus/UI qui utiliseraient ui_left/right/up/down.
# - ESC libère la souris (menu futur, inventaire...) ; un clic dans le
#   viewport la recapture.
# - Sprint (Shift) et saut (Espace) sont gratuits : pas de coût d'énergie.
#   Dette assumée, rattachée au Jalon 6 (survie/énergie) — voir ROADMAP.
# - step_height (0.35 par défaut) doit rester UN PEU plus haut que la
#   contremarche réelle des Platform_Stairs_* du kit SciFi. Si tu changes de
#   pack ou de type d'escalier plus tard, remesure et ajuste — trop bas et le
#   joueur reste coincé comme avant ce fix, trop haut et il "monte" sur des
#   obstacles qui devraient rester des murs.
