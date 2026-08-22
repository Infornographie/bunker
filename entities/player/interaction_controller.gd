extends Node3D
class_name InteractionController

@export var interaction_range: float = 3.0
@export var prompt_label: Label3D
@export var tool_controller: ToolController
@export var action_state_machine: ActionStateMachine

var _current_target: Interactable

func _ready() -> void:
	if prompt_label:
		prompt_label.visible = false

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
	if prompt_label == null:
		return
	if _current_target and _current_target.can_interact(self):
		prompt_label.text = _current_target.prompt_text
		prompt_label.global_position = _current_target.global_position + Vector3.UP
		prompt_label.visible = true
	else:
		prompt_label.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and _current_target and _current_target.can_interact(self):
		_current_target.interact(self)
