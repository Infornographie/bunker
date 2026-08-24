extends Interactable
class_name Choppable

signal depleted

@export var max_health: int = 3
@export var chop_sound: AudioStream
@export var pickup_scene: PackedScene
@export var pickup_count: int = 3
@export var spawn_height_offset: float = 0.3
@export var pickup_stack_spacing: float = 1.3
@export var pickup_spawn_rotation_degrees: Vector3 = Vector3(90.0, 0.0, 0.0)

var _health: int
var _is_depleted: bool = false

func _ready() -> void:
	_health = max_health

## Contrôle uniquement l'affichage HUD (prompt/réticule) — le déclenchement
## réel du chop passe par receive_tool_hit(), appelé que ce soit interactable
## ou non (voir InteractionController._try_use_tool()).
func can_interact(interactor: Node) -> bool:
	var tool_controller := _get_tool_controller(interactor)
	if tool_controller == null or not tool_controller.can_swing():
		return false
	var tool := tool_controller.get_equipped_tool()
	return tool != null and tool.tool_type == ToolDef.ToolType.CHOP

## Le chop se déclenche au clic (use_tool), cible valide ou non — pas via la
## touche d'interaction générique (E).
func uses_tool_trigger() -> bool:
	return true

func receive_tool_hit(tool: ToolDef, hit_origin: Vector3 = Vector3.ZERO) -> void:
	if tool == null or tool.tool_type != ToolDef.ToolType.CHOP or _is_depleted:
		return
	if chop_sound:
		SoundManager.play_sfx(chop_sound, global_position)
	_health -= tool.damage
	if _health <= 0:
		_is_depleted = true
		var spawn_position := global_position
		depleted.emit()
		_spawn_pickup(hit_origin, spawn_position)
		queue_free()

func _spawn_pickup(hit_origin: Vector3, spawn_position: Vector3) -> void:
	if pickup_scene == null:
		return
	var fall_direction := Vector3.ZERO
	if hit_origin != Vector3.ZERO:
		fall_direction = spawn_position - hit_origin
		fall_direction.y = 0.0
		fall_direction = fall_direction.normalized()
	var parent := get_parent()
	for i in pickup_count:
		var pickup := pickup_scene.instantiate()
		var world_position := spawn_position + Vector3(0.0, spawn_height_offset + i * pickup_stack_spacing, 0.0)
		pickup.position = parent.global_transform.affine_inverse() * world_position
		pickup.rotation_degrees = pickup_spawn_rotation_degrees
		if pickup.has_method("set_fall_direction"):
			pickup.set_fall_direction(fall_direction)
		parent.add_child(pickup)

func _get_tool_controller(interactor: Node) -> ToolController:
	if interactor is InteractionController:
		return interactor.tool_controller
	return null
