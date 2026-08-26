extends Node3D
class_name EquipmentController

## Point de logique unique pour l'équipement du protagoniste.
##
## Slots logiques (hotbar) :
##   0-1  →  ceinture (outils, Array[ToolDef])
##   2-4  →  poches du sac à dos (petits objets, BackpackData.pocket_slots)
##
## Pilote ToolController selon le slot actif. Respecte la priorité :
##   Main (CarryController) > Hotbar actif
## Si le joueur porte un objet lourd, la ceinture est bloquée visuellement
## mais les données restent (il ne perd pas ses outils).

signal active_slot_changed(index: int)
signal belt_changed(slot_index: int, tool_def: ToolDef)
signal pocket_changed(pocket_index: int, resource_def: ResourceDef)

const BELT_COUNT: int = 2
const HOTBAR_SIZE: int = 5  # 2 belt + 3 pockets

@export var tool_controller: ToolController
@export var carry_controller: CarryController
@export var build_mode_controller: BuildModeController
@export var hud: PlayerHud
## Outils initiaux placés dans la ceinture au démarrage (max 2).
@export var starting_tools: Array[ToolDef] = []
## Distance devant le joueur pour poser un item au sol.
@export var drop_distance: float = 1.5
## Scène complète du sac à dos posé (backpack_pickup.tscn — porte le mesh,
## la collision ET le scale correct). Instanciée quand le sac quitte le dos.
@export var backpack_pickup_scene: PackedScene
## Ancre d'affichage du petit objet sélectionné en poche. Même point que le
## HandAnchor du CarryController : un petit objet actif s'affiche à la même
## place à l'écran qu'un objet lourd porté.
@export var hand_anchor: Node3D

var _belt: Array[ToolDef] = []
var _backpack_data: BackpackData
var _active_slot: int = 0
var _was_carrying: bool = false
var _pocket_view_instance: Node3D = null


func _process(_delta: float) -> void:
	# Le grisage suit l'état des mains sans que chaque site d'appel ait à
	# le notifier (drop, livraison, portage du sac...).
	var carrying: bool = carry_controller != null and carry_controller.is_carrying()
	if carrying != _was_carrying:
		_was_carrying = carrying
		_apply_active_slot()


func _ready() -> void:
	_belt.resize(BELT_COUNT)
	for i in mini(starting_tools.size(), BELT_COUNT):
		_belt[i] = starting_tools[i]
	# Le HUD n'a pas forcément fini son _ready() : on pousse l'état initial
	# à la frame suivante, sinon le premier update part dans le vide.
	await get_tree().process_frame
	_apply_active_slot()


## --- Accesseurs publics ------------------------------------------------

func get_active_slot() -> int:
	return _active_slot


func get_belt_tool(index: int) -> ToolDef:
	if index < 0 or index >= BELT_COUNT:
		return null
	return _belt[index]


func get_backpack_data() -> BackpackData:
	return _backpack_data


func has_backpack() -> bool:
	return _backpack_data != null


## Appelé quand le contenu du sac a été modifié de l'extérieur (UI du sac
## ouvert). Resynchronise hotbar et viewmodel.
func notify_backpack_changed() -> void:
	_notify_all_pockets()
	_apply_active_slot()


## Retourne le ToolDef actif si le slot courant est un slot ceinture occupé,
## null sinon (slot poche, slot vide, ou main occupée).
func get_active_tool() -> ToolDef:
	if carry_controller and carry_controller.is_carrying():
		return null
	if _active_slot < BELT_COUNT:
		return _belt[_active_slot]
	return null


## Contenu du slot poche à l'index hotbar (2-4). Null si pas de sac ou vide.
func get_pocket_content(hotbar_index: int) -> ResourceDef:
	if _backpack_data == null:
		return null
	var pocket_i: int = hotbar_index - BELT_COUNT
	if pocket_i < 0 or pocket_i >= BackpackData.POCKET_COUNT:
		return null
	return _backpack_data.pocket_slots[pocket_i]


## --- Équipement du sac -------------------------------------------------

func equip_backpack(data: BackpackData) -> void:
	_backpack_data = data
	_notify_all_pockets()
	_apply_active_slot()


func unequip_backpack() -> BackpackData:
	var old := _backpack_data
	_backpack_data = null
	_notify_all_pockets()
	# Si le slot actif était une poche, revenir à la ceinture.
	if _active_slot >= BELT_COUNT:
		_set_active_slot(0)
	else:
		_apply_active_slot()
	return old


## --- Routage de ramassage ----------------------------------------------

## Tente de placer un outil dans la ceinture. Retourne true si absorbé.
func try_store_tool(tool_def: ToolDef) -> bool:
	for i in BELT_COUNT:
		if _belt[i] == null:
			_belt[i] = tool_def
			belt_changed.emit(i, tool_def)
			if i == _active_slot:
				_apply_active_slot()
			_update_hotbar()
			return true
	return false


## Tente de placer un petit objet dans les poches puis le stockage du sac.
## Retourne true si absorbé.
func try_store_small(resource: ResourceDef) -> bool:
	if _backpack_data == null:
		return false
	var old_pocket_0: int = _backpack_data.first_free_pocket()
	if _backpack_data.try_store(resource):
		# Notifier si c'est allé dans une poche (hotbar visible).
		var new_pocket_0: int = _backpack_data.first_free_pocket()
		if old_pocket_0 != new_pocket_0 and old_pocket_0 >= 0:
			pocket_changed.emit(old_pocket_0, _backpack_data.pocket_slots[old_pocket_0])
			# Si c'est la poche affichée en main, rafraîchir le viewmodel.
			if old_pocket_0 + BELT_COUNT == _active_slot:
				_apply_active_slot()
				return true
		_update_hotbar()
		return true
	return false


## --- Retrait d'item d'un slot ------------------------------------------

## Retire l'outil du slot ceinture. Retourne le ToolDef retiré (ou null).
func remove_belt_tool(index: int) -> ToolDef:
	if index < 0 or index >= BELT_COUNT:
		return null
	var old := _belt[index]
	_belt[index] = null
	belt_changed.emit(index, null)
	if index == _active_slot:
		_apply_active_slot()
	_update_hotbar()
	return old


## Retire l'item de la poche. Retourne le ResourceDef retiré (ou null).
func remove_pocket_item(pocket_index: int) -> ResourceDef:
	if _backpack_data == null or pocket_index < 0 or pocket_index >= BackpackData.POCKET_COUNT:
		return null
	var old := _backpack_data.pocket_slots[pocket_index]
	_backpack_data.pocket_slots[pocket_index] = null
	pocket_changed.emit(pocket_index, null)
	if pocket_index + BELT_COUNT == _active_slot:
		_apply_active_slot()
	else:
		_update_hotbar()
	return old


## --- Sélection de slot --------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if build_mode_controller and build_mode_controller.is_active():
		return
	if carry_controller and carry_controller.is_carrying():
		return
	if event.is_action_pressed("drop_slot"):
		_drop_active_slot()
	elif event.is_action_pressed("cycle_slot_prev"):
		_cycle_slot(-1)
	elif event.is_action_pressed("cycle_slot_next"):
		_cycle_slot(1)
	elif event.is_action_pressed("select_slot_1"):
		_set_active_slot(0)
	elif event.is_action_pressed("select_slot_2"):
		_set_active_slot(1)
	elif event.is_action_pressed("select_slot_3"):
		_set_active_slot(2)
	elif event.is_action_pressed("select_slot_4"):
		_set_active_slot(3)
	elif event.is_action_pressed("select_slot_5"):
		_set_active_slot(4)


func _cycle_slot(direction: int) -> void:
	var max_slot: int = HOTBAR_SIZE if has_backpack() else BELT_COUNT
	var next: int = (_active_slot + direction) % max_slot
	if next < 0:
		next += max_slot
	_set_active_slot(next)


func _set_active_slot(index: int) -> void:
	var max_slot: int = HOTBAR_SIZE if has_backpack() else BELT_COUNT
	index = clampi(index, 0, max_slot - 1)
	if index == _active_slot:
		return
	_active_slot = index
	active_slot_changed.emit(index)
	_apply_active_slot()


func _notify_all_pockets() -> void:
	for i in BackpackData.POCKET_COUNT:
		var content: ResourceDef = null
		if _backpack_data != null and i < _backpack_data.pocket_slots.size():
			content = _backpack_data.pocket_slots[i]
		pocket_changed.emit(i, content)


## Synchronise le viewmodel avec le slot actif : outil (ToolController)
## pour les slots ceinture, petit objet (hand_anchor) pour les poches.
func _apply_active_slot() -> void:
	var hands_busy: bool = carry_controller != null and carry_controller.is_carrying()

	# Viewmodel outil.
	if tool_controller:
		var tool_def := get_active_tool()
		if tool_def != null:
			tool_controller.equip(tool_def)
		else:
			tool_controller.unequip()

	# Viewmodel petit objet en poche.
	_clear_pocket_view()
	if not hands_busy and _active_slot >= BELT_COUNT:
		var res := get_pocket_content(_active_slot)
		if res and hand_anchor:
			_spawn_pocket_view(res)

	_update_hotbar()


func _spawn_pocket_view(res: ResourceDef) -> void:
	var instance: Node3D = ResourceRegistry.spawn_pickup(res)
	if instance == null:
		return
	# Le viewmodel est décoratif : pas de physique ni de collision.
	_strip_physics(instance)
	hand_anchor.add_child(instance)
	instance.position = Vector3.ZERO
	instance.rotation = Vector3.ZERO
	_pocket_view_instance = instance


func _clear_pocket_view() -> void:
	if _pocket_view_instance:
		_pocket_view_instance.queue_free()
		_pocket_view_instance = null


## Désactive collision et physique d'une instance affichée en viewmodel.
func _strip_physics(node: Node) -> void:
	if node is CollisionObject3D:
		var body: CollisionObject3D = node
		body.collision_layer = 0
		body.collision_mask = 0
		if node is RigidBody3D:
			node.set("freeze", true)
	for child in node.get_children():
		_strip_physics(child)


## Retire l'objet de la poche active et retourne son ResourceDef (ou null).
## Utilisé par InteractionController pour poser/livrer le petit objet.
func take_active_pocket_item() -> ResourceDef:
	if _active_slot < BELT_COUNT:
		return null
	return remove_pocket_item(_active_slot - BELT_COUNT)


## ResourceDef affiché en main via une poche, ou null.
func get_active_pocket_item() -> ResourceDef:
	if carry_controller and carry_controller.is_carrying():
		return null
	if _active_slot < BELT_COUNT:
		return null
	return get_pocket_content(_active_slot)


func _update_hotbar() -> void:
	if hud == null:
		return
	hud.update_hotbar(_active_slot, _belt, _backpack_data)
	# Source unique de vérité pour le grisage : les mains sont-elles prises ?
	var hands_busy: bool = carry_controller != null and carry_controller.is_carrying()
	hud.set_hotbar_dimmed(hands_busy)


## --- Drop depuis le hotbar ----------------------------------------------

func _drop_active_slot() -> void:
	if _active_slot < BELT_COUNT:
		_drop_belt_slot(_active_slot)
	else:
		_drop_pocket_slot(_active_slot - BELT_COUNT)


func _drop_belt_slot(index: int) -> void:
	var tool_def := remove_belt_tool(index)
	if tool_def == null:
		return
	_spawn_tool_pickup(tool_def)


func _drop_pocket_slot(pocket_index: int) -> void:
	var resource := remove_pocket_item(pocket_index)
	if resource == null:
		return
	var camera := get_parent() as Camera3D
	if camera == null:
		return
	var pickup: Node3D = ResourceRegistry.spawn_pickup(resource)
	if pickup == null:
		return
	var drop_pos := camera.global_position + camera.global_basis.z * -drop_distance
	get_tree().current_scene.add_child(pickup)
	pickup.global_position = drop_pos


func _spawn_tool_pickup(tool_def: ToolDef) -> void:
	var camera := get_parent() as Camera3D
	if camera == null:
		return
	var forward_pos := camera.global_position + camera.global_basis.z * -drop_distance

	# Raycast vers le bas pour poser au sol plutôt qu'en l'air.
	var space_state := camera.get_world_3d().direct_space_state
	var ray_from := forward_pos
	var ray_to := forward_pos + Vector3.DOWN * 20.0
	var query := PhysicsRayQueryParameters3D.create(ray_from, ray_to)
	var result := space_state.intersect_ray(query)
	var drop_pos: Vector3 = result.position if result else forward_pos

	var pickup_script: GDScript = preload("res://entities/interactable/tool_pickup.gd")
	var body := StaticBody3D.new()
	body.set_script(pickup_script)
	body.tool_def = tool_def
	body.prompt_text = tool_def.display_name

	# Collision simple pour le raycast d'interaction.
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.3, 0.3, 0.6)
	col.shape = box
	col.position.y = 0.15
	body.add_child(col)

	# Mesh visuel depuis la scène grip de l'outil.
	if tool_def.mesh_scene:
		var mesh := tool_def.mesh_scene.instantiate()
		body.add_child(mesh)

	get_tree().current_scene.add_child(body)
	body.global_position = drop_pos
