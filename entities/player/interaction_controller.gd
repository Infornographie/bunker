extends Node3D
class_name InteractionController

@export var interaction_range: float = 3.0
@export var tool_controller: ToolController
@export var action_state_machine: ActionStateMachine
@export var hud: PlayerHud

var _current_target: Interactable
var _current_target_distance: float = -1.0

func _physics_process(_delta: float) -> void:
	_update_target()

func _update_target() -> void:
	var camera := get_parent() as Camera3D
	if camera == null:
		return
	var space_state := get_world_3d().direct_space_state
	var from := camera.global_position
	var to := from + camera.global_basis.z * -interaction_range
	var query := PhysicsRayQueryParameters3D.create(from, to)
	var result := space_state.intersect_ray(query)

	var hit_target: Interactable = null
	if result and result.collider is Interactable:
		hit_target = result.collider
	elif result and result.collider.get_parent() is Interactable:
		hit_target = result.collider.get_parent()

	_current_target_distance = from.distance_to(result.position) if result else -1.0

	if hit_target != _current_target:
		_set_current_target(hit_target)

func _set_current_target(new_target: Interactable) -> void:
	if _current_target and is_instance_valid(_current_target) and _current_target.tree_exiting.is_connected(_on_target_freed):
		_current_target.tree_exiting.disconnect(_on_target_freed)
	_current_target = new_target
	if _current_target:
		_current_target.tree_exiting.connect(_on_target_freed)
	_refresh_prompt()

func _on_target_freed() -> void:
	_current_target = null
	_refresh_prompt()

func _refresh_prompt() -> void:
	if hud == null:
		return
	if _current_target and _current_target.can_interact(self):
		hud.show_prompt(_current_target.prompt_text)
		hud.set_targeting(true)
	else:
		hud.hide_prompt()
		hud.set_targeting(false)

## Distance réelle (raycast, n'importe quel collider) jusqu'à ce que vise le
## réticule, -1 si rien. Utilisée pour caler la portée du swing (murs compris).
func get_current_target_distance() -> float:
	return _current_target_distance

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("use_tool"):
		_try_use_tool()
	if event.is_action_pressed("interact") and _current_target and not _current_target.uses_tool_trigger() and _current_target.can_interact(self):
		_current_target.interact(self)

## Un coup d'outil part toujours au clic, cible valide ou non : dans le vide,
## contre un mur (juste stoppé, aucun effet), ou contre un Interactable (dont
## on résout l'effet à l'impact via receive_tool_hit()).
func _try_use_tool() -> void:
	if tool_controller == null or action_state_machine == null:
		return
	var tool := tool_controller.get_equipped_tool()
	if tool == null:
		return
	var target := _current_target
	action_state_machine.use_tool_on(target, func(): target.receive_tool_hit(tool), _current_target_distance)
