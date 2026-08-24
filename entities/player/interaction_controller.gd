extends Node3D
class_name InteractionController

@export var interaction_range: float = 3.0
@export var tool_controller: ToolController
@export var action_state_machine: ActionStateMachine
@export var hud: PlayerHud
@export var carry_controller: CarryController
@export var drop_distance: float = 1.5
@export var build_mode_controller: BuildModeController

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
	if _current_target and not _current_target.tree_exiting.is_connected(_on_target_freed):
		_current_target.tree_exiting.connect(_on_target_freed)
	_refresh_prompt()

func _on_target_freed() -> void:
	_current_target = null
	_refresh_prompt()

func _refresh_prompt() -> void:
	if hud == null:
		return
	if build_mode_controller and build_mode_controller.is_active():
		hud.hide_prompt()
		hud.set_targeting(false)
		return
	if carry_controller and carry_controller.is_carrying():
		hud.show_prompt("Déposer")
		hud.set_targeting(true)
	elif _current_target and _current_target.can_interact(self):
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
	# Mode construction actif = mode à part entière, mains libres : les
	# actions habituelles (outil, ramassage) se taisent le temps du placement.
	if build_mode_controller and build_mode_controller.is_active():
		return
	if event.is_action_pressed("use_tool"):
		_try_use_tool()
	if event.is_action_pressed("interact"):
		if carry_controller and carry_controller.is_carrying():
			if not _try_deliver_carried_item():
				_drop_carried_item()
		elif _can_start_interaction() and _current_target and not _current_target.uses_tool_trigger() and _current_target.can_interact(self):
			_current_target.interact(self)
			if carry_controller and carry_controller.is_carrying() and tool_controller:
				tool_controller.set_tool_visible(false)

## Livre l'objet porté à la cible visée si elle l'accepte (chantier,
## structure rechargeable...). Retourne true si la livraison a eu lieu —
## l'appelant ne droppe alors pas l'objet au sol.
func _try_deliver_carried_item() -> bool:
	if _current_target == null or carry_controller == null:
		return false
	var pickup := carry_controller.get_carried_item() as ResourcePickup
	if pickup == null or pickup.resource_def == null:
		return false
	if not _current_target.can_interact(self):
		return false
	if not _current_target.receive_resource(pickup.resource_def, pickup.amount):
		return false
	carry_controller.consume()
	if tool_controller:
		tool_controller.set_tool_visible(true)
	return true

## Empêche de démarrer une interaction (ramassage...) pendant un swing en
## cours — même logique de verrouillage que _try_use_tool() côté outil.
## Fail-open si la state machine n'est pas câblée (pas de régression sur
## un ancien setup de scène sans action_state_machine assigné).
func _can_start_interaction() -> bool:
	return action_state_machine == null or action_state_machine.get_state() == ActionStateMachine.State.IDLE

## Un coup d'outil part toujours au clic, cible valide ou non. Aucun coup ne
## part si les mains sont occupées (objet porté).
func _try_use_tool() -> void:
	if tool_controller == null or action_state_machine == null:
		return
	if carry_controller and carry_controller.is_carrying():
		return
	var tool := tool_controller.get_equipped_tool()
	if tool == null:
		return
	var target := _current_target
	var camera := get_parent() as Camera3D
	var hit_origin := camera.global_position if camera else Vector3.ZERO
	action_state_machine.use_tool_on(target, func(): target.receive_tool_hit(tool, hit_origin), _current_target_distance)

func _drop_carried_item() -> void:
	if carry_controller == null:
		return
	var camera := get_parent() as Camera3D
	if camera == null:
		return
	var drop_position := camera.global_position + camera.global_basis.z * -drop_distance
	carry_controller.drop(drop_position, get_tree().current_scene)
	if tool_controller:
		tool_controller.set_tool_visible(true)
