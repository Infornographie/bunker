extends Node3D
class_name BuildModeController

## Pose de bâtiments : fait apparaître un fantôme qui suit la caméra, teste
## le chevauchement en continu contre la vraie forme de collision (pas de
## boîte englobante), et instancie un ConstructionSite à la confirmation.
##
## Mode à part entière (mains libres), pas une action chronométrée :
## InteractionController se désactive tant qu'il est actif (voir son
## _unhandled_input), même principe que le verrouillage carry→swing existant.
##
## Actions Input Map attendues (à créer dans le projet) :
## - toggle_build_mode : entrer/sortir du mode
## - rotate_ghost / rotate_ghost_reverse : tourner le fantôme (pas de ROTATION_STEP_DEG)
## - confirm_placement : valider la pose
## - select_slot_1..5 : choisir le bâtiment (réemploi des touches du hotbar,
##   libres pendant le mode ; la molette, elle, est prise par la rotation)
## - free_placement_modifier (maintenue, ex: Shift) : désactive le snap grille

const GRID_CELL_SIZE: float = 1.0
const ROTATION_STEP_DEG: float = 45.0
const MAX_PLACEMENT_DISTANCE: float = 5.0

## Bâtiments constructibles, dans l'ordre de sélection : les touches 1-5 les
## choisissent pendant le mode construction. Elles y sont libres —
## `PlayerEquipment` ignore ses entrées tant que le mode est actif — et pas la
## molette, déjà prise par la rotation du blueprint. Pas de touche neuve, pas
## de menu : le rang dans cette liste est le chiffre à presser.
@export var building_defs: Array[BuildingDef] = []
@export var carry_controller: CarryController
@export var action_state_machine: ActionStateMachine
@export var world_parent: Node3D
@export var ui_panel_controller: UIPanelController
## Layer(s) du sol/terrain uniquement — sert à trouver où poser le fantôme.
## Ne doit PAS inclure arbres/murs/bâtiments, sinon le fantôme peut se caler
## sur n'importe quelle surface visée (bug observé : pose sur troncs/murs).
@export_flags_3d_physics var ground_mask: int = 0xFFFFFFFF
## Layers testées pour le chevauchement (monde + constructions existantes) —
## à caler dans l'éditeur sur les layers réelles du projet.
@export_flags_3d_physics var overlap_mask: int = 0xFFFFFFFF

var _active: bool = false
var _ghost: Node3D
var _ghost_material_valid: StandardMaterial3D
var _ghost_material_invalid: StandardMaterial3D
## Les touches de sélection, dans l'ordre. Ce sont celles du hotbar, réemployées
## faute d'être utilisées en construction — ajouter cinq actions qui feraient
## doublon avec elles serait cinq bindings de plus à tenir cohérents.
const _SELECT_ACTIONS: Array[StringName] = [&"select_slot_1", &"select_slot_2",
		&"select_slot_3", &"select_slot_4", &"select_slot_5"]

var _selected: int = 0
var _rotation_y: float = 0.0
var _placement_valid: bool = false
var _placement_transform: Transform3D

func _ready() -> void:
	_ghost_material_valid = StandardMaterial3D.new()
	_ghost_material_valid.albedo_color = Color(0.3, 1.0, 0.3, 0.5)
	_ghost_material_valid.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_ghost_material_invalid = StandardMaterial3D.new()
	_ghost_material_invalid.albedo_color = Color(1.0, 0.3, 0.3, 0.5)
	_ghost_material_invalid.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

func is_active() -> bool:
	return _active


## Bâtiment actuellement sélectionné, ou null si la liste est vide.
func current_def() -> BuildingDef:
	if building_defs.is_empty():
		return null
	return building_defs[clampi(_selected, 0, building_defs.size() - 1)]


func _select_building(index: int) -> void:
	if index == _selected or index >= building_defs.size():
		return
	_selected = index
	# Le fantôme est reconstruit plutôt que retexturé : deux bâtiments n'ont ni
	# la même scène ni la même emprise. L'orientation, elle, se conserve — la
	# perdre à chaque cran de molette rendrait la comparaison pénible.
	var kept_rotation := _rotation_y
	_exit_build_mode()
	_enter_build_mode()
	_rotation_y = kept_rotation

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_build_mode"):
		if _active:
			_exit_build_mode()
		else:
			_enter_build_mode()
		return
	if not _active:
		return
	for i in mini(building_defs.size(), _SELECT_ACTIONS.size()):
		if event.is_action_pressed(_SELECT_ACTIONS[i]):
			_select_building(i)
			return
	if event.is_action_pressed("rotate_ghost"):
		_rotation_y += deg_to_rad(ROTATION_STEP_DEG)
	elif event.is_action_pressed("rotate_ghost_reverse"):
		_rotation_y -= deg_to_rad(ROTATION_STEP_DEG)
	elif event.is_action_pressed("confirm_placement"):
		_confirm_placement()

func _enter_build_mode() -> void:
	var building_def := current_def()
	if building_def == null or building_def.ghost_scene == null:
		return
	if carry_controller and carry_controller.is_carrying():
		return
	if ui_panel_controller and not ui_panel_controller.can_enter_build_mode():
		return
	if action_state_machine and action_state_machine.get_state() != ActionStateMachine.State.IDLE:
		return
	_active = true
	_rotation_y = 0.0
	_ghost = building_def.ghost_scene.instantiate()
	_disable_collisions(_ghost)
	_apply_material(_ghost, _ghost_material_valid)
	get_tree().current_scene.add_child(_ghost)

func _exit_build_mode() -> void:
	_active = false
	if _ghost:
		_ghost.queue_free()
		_ghost = null

func _physics_process(_delta: float) -> void:
	if not _active:
		return
	_update_ghost_transform()
	_update_overlap_check()

func _update_ghost_transform() -> void:
	var camera := get_parent() as Camera3D
	if camera == null or _ghost == null:
		return
	var space_state := get_world_3d().direct_space_state
	var from := camera.global_position
	var to := from + camera.global_basis.z * -MAX_PLACEMENT_DISTANCE
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = ground_mask
	var result := space_state.intersect_ray(query)
	if not result:
		return
	var pos: Vector3 = result.position
	if not Input.is_action_pressed("free_placement_modifier"):
		pos.x = round(pos.x / GRID_CELL_SIZE) * GRID_CELL_SIZE
		pos.z = round(pos.z / GRID_CELL_SIZE) * GRID_CELL_SIZE
	_placement_transform = Transform3D(Basis(Vector3.UP, _rotation_y), pos)
	_ghost.global_transform = _placement_transform

func _update_overlap_check() -> void:
	var building_def := current_def()
	if building_def == null or building_def.collision_shape == null:
		_placement_valid = true
	else:
		var space_state := get_world_3d().direct_space_state
		var params := PhysicsShapeQueryParameters3D.new()
		params.shape = building_def.collision_shape
		params.transform = _placement_transform * building_def.collision_shape_local_transform()
		params.collision_mask = overlap_mask
		var results := space_state.intersect_shape(params, 1)
		_placement_valid = results.is_empty()
	_apply_material(_ghost, _ghost_material_valid if _placement_valid else _ghost_material_invalid)

func _confirm_placement() -> void:
	if not _placement_valid:
		return
	var construction_scene: PackedScene = load("res://entities/interactable/construction_site.tscn")
	var parent := world_parent if world_parent else get_tree().current_scene
	var site := construction_scene.instantiate()
	site.building_def = current_def()
	parent.add_child(site)
	site.global_transform = _placement_transform
	_exit_build_mode()

func _apply_material(node: Node, material: StandardMaterial3D) -> void:
	if node is MeshInstance3D:
		node.material_override = material
	for child in node.get_children():
		_apply_material(child, material)

## Le fantôme est purement visuel — sa collision (si l'asset source en a
## une) est neutralisée pour ne pas fausser le raycast de visée ni le test
## de chevauchement. Même pattern que CarryController.carry().
func _disable_collisions(node: Node) -> void:
	if node is CollisionObject3D:
		node.set("collision_layer", 0)
		node.set("collision_mask", 0)
	for child in node.get_children():
		_disable_collisions(child)
