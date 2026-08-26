extends Node3D
class_name InteractionController

@export var interaction_range: float = 3.0
@export var tool_controller: ToolController
@export var action_state_machine: ActionStateMachine
@export var hud: PlayerHud
@export var carry_controller: CarryController
@export var drop_distance: float = 1.5
@export var build_mode_controller: BuildModeController
@export var equipment_controller: EquipmentController

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
	if hud and hud.get_backpack_ui() and hud.get_backpack_ui().is_open():
		return
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
		elif _try_use_pocket_item():
			pass
		elif _can_start_interaction() and _current_target and not _current_target.uses_tool_trigger() and _current_target.can_interact(self):
			_current_target.interact(self)
			if carry_controller and carry_controller.is_carrying() and tool_controller:
				tool_controller.set_tool_visible(false)
	if event.is_action_pressed("backpack_toggle"):
		_handle_backpack_toggle()
		
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
	var item := carry_controller.get_carried_item()  # ← AJOUTER (sauver avant drop)
	var drop_position := camera.global_position + camera.global_basis.z * -drop_distance
	carry_controller.drop(drop_position, get_tree().current_scene)
	# Snap au sol pour les objets non-RigidBody (sac à dos).
	if item is BackpackPickup:                        # ← AJOUTER
		item.request_ground_snap()                    # ← AJOUTER
	if tool_controller:
		tool_controller.set_tool_visible(true)

## Touche A : gère le cycle sac à dos ↔ main ↔ sol.
func _handle_backpack_toggle() -> void:
	if equipment_controller == null:
		return

	# Cas 1 : on regarde un BackpackPickup au sol → équiper sur le dos.
	if _current_target is BackpackPickup and not equipment_controller.has_backpack():
		equipment_controller.equip_backpack(_current_target.backpack_data)
		_current_target.queue_free()
		return

	# Cas 2 : on porte un sac en main → le remettre sur le dos.
	if carry_controller and carry_controller.is_carrying():
		var carried := carry_controller.get_carried_item()
		if carried is BackpackPickup:
			var data: BackpackData = carried.backpack_data
			carry_controller.consume()
			equipment_controller.equip_backpack(data)
			if tool_controller:
				tool_controller.set_tool_visible(true)
		return

	# Cas 3 : sac sur le dos, mains libres → prendre en main.
	if equipment_controller.has_backpack() and carry_controller and carry_controller.can_carry():
		var data := equipment_controller.unequip_backpack()
		var pickup := _spawn_backpack_in_hand(data)
		if pickup == null:
			equipment_controller.equip_backpack(data)
			return
		carry_controller.carry(pickup)
		if tool_controller:
			tool_controller.set_tool_visible(false)


## Crée un BackpackPickup depuis la scène (scale et collision corrects).
func _spawn_backpack_in_hand(data: BackpackData) -> Node3D:
	if equipment_controller.backpack_pickup_scene == null:
		push_warning("EquipmentController.backpack_pickup_scene non assignée")
		return null
	var pickup := equipment_controller.backpack_pickup_scene.instantiate()
	pickup.backpack_data = data
	get_tree().current_scene.add_child(pickup)
	return pickup

## E avec un petit objet sélectionné en poche : livraison à la cible visée
## si elle l'accepte, sinon dépose au sol. Retourne true si l'action a eu lieu.
func _try_use_pocket_item() -> bool:
	if equipment_controller == null:
		return false
	var resource := equipment_controller.get_active_pocket_item()
	if resource == null:
		return false

	# Tentative de livraison (chantier, feu de camp...).
	if _current_target and _current_target.can_interact(self):
		if _current_target.receive_resource(resource, 1):
			equipment_controller.take_active_pocket_item()
			return true

	# Sinon dépose au sol.
	if resource.pickup_scene == null:
		return false
	equipment_controller.take_active_pocket_item()
	var camera := get_parent() as Camera3D
	var drop_position := camera.global_position + camera.global_basis.z * -drop_distance
	var pickup: Node3D = ResourceRegistry.spawn_pickup(resource)
	get_tree().current_scene.add_child(pickup)
	pickup.global_position = drop_position
	return true

## Ouvre l'UI du sac visé. Verrouille caméra et déplacement.
func open_backpack_ui(backpack: BackpackPickup) -> void:
	if hud == null:
		return
	var ui := hud.get_backpack_ui()
	if ui == null:
		return
	var camera := get_parent() as Camera3D
	ui.open(backpack, equipment_controller, carry_controller, camera)
	if not ui.closed.is_connected(_on_backpack_ui_closed):
		ui.closed.connect(_on_backpack_ui_closed)
	_set_player_frozen(true)


func _on_backpack_ui_closed() -> void:
	_set_player_frozen(false)


## Gèle locomotion et rotation caméra (UI modale ouverte).
func _set_player_frozen(frozen: bool) -> void:
	var player := owner as Node
	if player and player.has_method("set_input_enabled"):
		player.set_input_enabled(not frozen)
