extends Node3D
class_name PlayerEquipment
## Habille un `Inventory` pour le joueur : touches, HUD, viewmodel, et le geste
## de lâcher un objet devant soi.
##
## **Le partage de responsabilité.** L'`Inventory` sait ce qui est rangé où ;
## il ne sait pas qu'on le regarde. Cette classe est la seule qui suppose un
## joueur — un clavier, une barre à l'écran, une main devant une caméra. Un
## pawn aura son propre habillage, ou aucun, et partagera l'`Inventory`.
##
## Le sens de la dépendance est à sens unique : cette classe lit et pilote
## l'inventaire, l'inventaire ne la connaît pas. Elle se resynchronise sur son
## signal `changed` plutôt qu'après chaque appel — sinon chaque site d'appel
## devrait penser à rafraîchir, et un seul oubli laisse le HUD mentir.

@export var inventory: Inventory
@export var tool_controller: ToolController
@export var build_mode_controller: BuildModeController
@export var hud: PlayerHud
## Ancre d'affichage du petit objet sélectionné en poche. Même point que le
## `HandAnchor` du `CarryController` : un petit objet actif s'affiche à la même
## place à l'écran qu'un objet lourd porté.
@export var hand_anchor: Node3D
## D'où part un objet lâché — le nœud dont on prend la position et l'avant.
## Déclaré, jamais déduit du parent : un composant qui devine son parent est un
## composant qu'on ne peut pas ranger ailleurs.
@export var drop_origin: Node3D
## Distance devant le joueur pour poser un item au sol.
@export var drop_distance: float = 1.5

var _pocket_view_instance: Node3D = null
var _was_hands_busy: bool = false


func _ready() -> void:
	if inventory == null:
		push_warning("PlayerEquipment : aucun Inventory assigné.")
		return
	inventory.changed.connect(_refresh)
	# Le HUD n'a pas forcément fini son _ready() : on pousse l'état initial à
	# la frame suivante, sinon le premier update part dans le vide.
	await get_tree().process_frame
	_refresh()


func _process(_delta: float) -> void:
	# Prendre un objet en main n'est pas une mutation de l'inventaire, donc
	# n'émet pas `changed` — mais ça change ce qui s'affiche et ce qui est
	# grisé. On surveille la bascule plutôt que de demander à chaque site
	# d'appel (drop, livraison, portage du sac) de nous prévenir.
	if inventory == null:
		return
	var busy := inventory.hands_busy()
	if busy != _was_hands_busy:
		_was_hands_busy = busy
		_refresh()


## --- Vue ----------------------------------------------------------------

## Synchronise viewmodel et HUD avec l'état courant de l'inventaire.
func _refresh() -> void:
	if inventory == null:
		return

	if tool_controller:
		var tool_def := inventory.get_active_tool()
		if tool_def != null:
			tool_controller.equip(tool_def)
		else:
			tool_controller.unequip()

	_clear_pocket_view()
	var res := inventory.get_active_pocket_item()
	if res != null and hand_anchor:
		_spawn_pocket_view(res)

	if hud:
		hud.update_hotbar(inventory.get_active_slot(), inventory.get_belt(),
				inventory.get_backpack_data())
		hud.set_hotbar_dimmed(inventory.hands_busy())


func _spawn_pocket_view(res: ResourceDef) -> void:
	var instance: Node3D = ResourceRegistry.spawn_display(res)
	if instance == null:
		return
	hand_anchor.add_child(instance)
	instance.position = Vector3.ZERO
	instance.rotation = Vector3.ZERO
	_pocket_view_instance = instance


func _clear_pocket_view() -> void:
	if _pocket_view_instance:
		_pocket_view_instance.queue_free()
		_pocket_view_instance = null



## --- Touches ------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if inventory == null:
		return
	if build_mode_controller and build_mode_controller.is_active():
		return
	if inventory.hands_busy():
		return
	if event.is_action_pressed("drop_slot"):
		_drop_active_slot()
	elif event.is_action_pressed("cycle_slot_prev"):
		inventory.cycle_slot(-1)
	elif event.is_action_pressed("cycle_slot_next"):
		inventory.cycle_slot(1)
	elif event.is_action_pressed("select_slot_1"):
		inventory.set_active_slot(0)
	elif event.is_action_pressed("select_slot_2"):
		inventory.set_active_slot(1)
	elif event.is_action_pressed("select_slot_3"):
		inventory.set_active_slot(2)
	elif event.is_action_pressed("select_slot_4"):
		inventory.set_active_slot(3)
	elif event.is_action_pressed("select_slot_5"):
		inventory.set_active_slot(4)


## --- Lâcher un objet devant soi -----------------------------------------

func _drop_active_slot() -> void:
	var slot := inventory.get_active_slot()
	if slot < Inventory.BELT_COUNT:
		var tool_def := inventory.remove_belt_tool(slot)
		if tool_def != null:
			_spawn_tool_pickup(tool_def)
	else:
		var resource := inventory.remove_pocket_item(slot - Inventory.BELT_COUNT)
		if resource != null:
			_spawn_resource_pickup(resource)


## Point au sol devant le porteur, ou null si l'origine manque.
func _drop_position(raycast_down: bool) -> Variant:
	if drop_origin == null:
		push_warning("PlayerEquipment : drop_origin non assigné, objet non lâché.")
		return null
	var forward := drop_origin.global_position + drop_origin.global_basis.z * -drop_distance
	if not raycast_down:
		return forward
	var space_state := drop_origin.get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(forward, forward + Vector3.DOWN * 20.0)
	var result := space_state.intersect_ray(query)
	return result.position if result else forward


func _spawn_resource_pickup(resource: ResourceDef) -> void:
	var drop_pos = _drop_position(false)
	if drop_pos == null:
		return
	var pickup: Node3D = ResourceRegistry.spawn_pickup(resource)
	if pickup == null:
		return
	get_tree().current_scene.add_child(pickup)
	pickup.global_position = drop_pos


func _spawn_tool_pickup(tool_def: ToolDef) -> void:
	# Raycast vers le bas pour poser au sol plutôt qu'en l'air.
	var drop_pos = _drop_position(true)
	if drop_pos == null:
		return

	var pickup_script: GDScript = preload("res://entities/interactable/tool_pickup.gd")
	var body := StaticBody3D.new()
	body.set_script(pickup_script)
	body.tool_def = tool_def
	body.prompt_key = tool_def.name_key

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
