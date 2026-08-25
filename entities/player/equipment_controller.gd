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

var _belt: Array[ToolDef] = []
var _backpack_data: BackpackData
var _active_slot: int = 0


func _ready() -> void:
	_belt.resize(BELT_COUNT)
	for i in mini(starting_tools.size(), BELT_COUNT):
		_belt[i] = starting_tools[i]
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


## Synchronise ToolController avec le slot actif.
func _apply_active_slot() -> void:
	if tool_controller == null:
		return
	var tool_def := get_active_tool()
	if tool_def != null:
		tool_controller.equip(tool_def)
	else:
		tool_controller.unequip()
	_update_hotbar()


func _update_hotbar() -> void:
	if hud == null:
		return
	hud.update_hotbar(_active_slot, _belt, _backpack_data)


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
	# Pas d'items petits pour l'instant — prêt pour la suite.
	var _resource := remove_pocket_item(pocket_index)
	if _resource == null:
		return
	# TODO Passe B : spawn un ResourcePickup depuis resource.pickup_scene


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
