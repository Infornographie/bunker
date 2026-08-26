extends Control
class_name BackpackUI

## Interface du sac posé au sol. Ancrée sur la position monde du sac
## (projetée à l'écran) plutôt que centrée sur l'écran — on reste "accroupi
## devant son sac" plutôt que dans un menu.
##
## Layout :
##                    [ MAIN ]
##      [POCHE G]   [3x3 stockage]   [POCHE D]
##                   [POCHE BAS]
##
## Drag & drop natif Godot (_get_drag_data / _can_drop_data / _drop_data),
## via une petite classe de slot interne.

signal closed

const STORAGE_SLOT_SIZE: float = 52.0
const BIG_SLOT_SIZE: float = 68.0
const GRID_GAP: float = 6.0
const ZONE_GAP: float = 24.0
## Distance au-delà de laquelle le sac se referme tout seul.
@export var close_distance: float = 2.5

## Identifiants de zone pour le drag & drop.
enum Zone { STORAGE, POCKET, HAND }

var _backpack_data: BackpackData
var _equipment: EquipmentController
var _carry: CarryController
var _anchor_node: Node3D
var _camera: Camera3D

var _storage_slots: Array[BackpackSlot] = []
var _pocket_slots: Array[BackpackSlot] = []
var _hand_slot: BackpackSlot


func _ready() -> void:
	set_process(false)
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## Ouvre l'UI ancrée sur le sac visé.
func open(backpack: BackpackPickup, equipment: EquipmentController, carry: CarryController, camera: Camera3D) -> void:
	_backpack_data = backpack.backpack_data
	_equipment = equipment
	_carry = carry
	_anchor_node = backpack
	_camera = camera

	if _storage_slots.is_empty():
		_build_slots()

	refresh()
	visible = true
	set_process(true)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func close() -> void:
	visible = false
	set_process(false)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	closed.emit()


func is_open() -> bool:
	return visible


func _process(_delta: float) -> void:
	if _anchor_node == null or not is_instance_valid(_anchor_node) or _camera == null:
		close()
		return
	# Referme si le joueur s'éloigne trop du sac.
	if _camera.global_position.distance_to(_anchor_node.global_position) > close_distance:
		close()
		return
	_update_anchor_position()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("interact"):
		close()
		get_viewport().set_input_as_handled()


## --- Positionnement ancré sur le sac -------------------------------------

func _update_anchor_position() -> void:
	var world_pos := _anchor_node.global_position
	# Le sac est passé derrière la caméra : on referme.
	if _camera.is_position_behind(world_pos):
		close()
		return
	var screen_pos := _camera.unproject_position(world_pos)
	# Le panneau est centré sur le sac, légèrement remonté pour ne pas
	# empiler la poche du bas sur le mesh.
	position = screen_pos - size * 0.5 - Vector2(0.0, 20.0)


## --- Construction des slots ----------------------------------------------

func _build_slots() -> void:
	var grid_width: float = 3.0 * STORAGE_SLOT_SIZE + 2.0 * GRID_GAP
	var grid_height: float = grid_width
	var total_width: float = grid_width + 2.0 * (BIG_SLOT_SIZE + ZONE_GAP)
	var total_height: float = grid_height + 2.0 * (BIG_SLOT_SIZE + ZONE_GAP)
	size = Vector2(total_width, total_height)

	var center_x: float = total_width * 0.5
	var center_y: float = total_height * 0.5
	var grid_left: float = center_x - grid_width * 0.5
	var grid_top: float = center_y - grid_height * 0.5

	# Grille de stockage 3x3.
	for i in BackpackData.STORAGE_COUNT:
		var row: int = int(i / 3.0)
		var col: int = i % 3
		var slot := _make_slot(Zone.STORAGE, i, STORAGE_SLOT_SIZE)
		slot.position = Vector2(
			grid_left + col * (STORAGE_SLOT_SIZE + GRID_GAP),
			grid_top + row * (STORAGE_SLOT_SIZE + GRID_GAP)
		)
		_storage_slots.append(slot)

	# Poche gauche.
	var pocket_l := _make_slot(Zone.POCKET, 0, BIG_SLOT_SIZE)
	pocket_l.position = Vector2(
		grid_left - ZONE_GAP - BIG_SLOT_SIZE,
		center_y - BIG_SLOT_SIZE * 0.5
	)
	_pocket_slots.append(pocket_l)

	# Poche droite.
	var pocket_r := _make_slot(Zone.POCKET, 1, BIG_SLOT_SIZE)
	pocket_r.position = Vector2(
		grid_left + grid_width + ZONE_GAP,
		center_y - BIG_SLOT_SIZE * 0.5
	)
	_pocket_slots.append(pocket_r)

	# Poche bas.
	var pocket_b := _make_slot(Zone.POCKET, 2, BIG_SLOT_SIZE)
	pocket_b.position = Vector2(
		center_x - BIG_SLOT_SIZE * 0.5,
		grid_top + grid_height + ZONE_GAP
	)
	_pocket_slots.append(pocket_b)

	# Main (haut).
	_hand_slot = _make_slot(Zone.HAND, 0, BIG_SLOT_SIZE)
	_hand_slot.position = Vector2(
		center_x - BIG_SLOT_SIZE * 0.5,
		grid_top - ZONE_GAP - BIG_SLOT_SIZE
	)


func _make_slot(zone: Zone, index: int, slot_size: float) -> BackpackSlot:
	var slot := BackpackSlot.new()
	slot.setup(zone, index, slot_size, self)
	add_child(slot)
	return slot


## --- Rafraîchissement ----------------------------------------------------

func refresh() -> void:
	if _backpack_data == null:
		return
	for i in _storage_slots.size():
		_storage_slots[i].set_content(_backpack_data.storage_slots[i])
	for i in _pocket_slots.size():
		_pocket_slots[i].set_content(_backpack_data.pocket_slots[i])
	_hand_slot.set_content(_get_hand_resource())


## Ressource actuellement en main, si c'est un petit objet transférable.
func _get_hand_resource() -> ResourceDef:
	if _carry == null or not _carry.is_carrying():
		return null
	var item := _carry.get_carried_item()
	if item is ResourcePickup and item.resource_def:
		if item.resource_def.carry_type == ResourceDef.CarryType.SMALL:
			return item.resource_def
	return null


## --- Transferts (appelés par les slots) ----------------------------------

## Lit le contenu d'un emplacement.
func get_slot_content(zone: Zone, index: int) -> ResourceDef:
	match zone:
		Zone.STORAGE:
			return _backpack_data.storage_slots[index]
		Zone.POCKET:
			return _backpack_data.pocket_slots[index]
		Zone.HAND:
			return _get_hand_resource()
	return null


## Déplace le contenu d'un emplacement vers un autre. Échange si la cible
## est occupée (comportement attendu d'un inventaire à slots).
func move_item(from_zone: Zone, from_index: int, to_zone: Zone, to_index: int) -> void:
	if from_zone == to_zone and from_index == to_index:
		return
	var moving := get_slot_content(from_zone, from_index)
	if moving == null:
		return
	var displaced := get_slot_content(to_zone, to_index)

	_set_slot_content(from_zone, from_index, displaced)
	_set_slot_content(to_zone, to_index, moving)
	refresh()
	# Le hotbar reflète les poches : le tenir à jour.
	if _equipment:
		_equipment.notify_backpack_changed()


func _set_slot_content(zone: Zone, index: int, resource: ResourceDef) -> void:
	match zone:
		Zone.STORAGE:
			_backpack_data.storage_slots[index] = resource
		Zone.POCKET:
			_backpack_data.pocket_slots[index] = resource
		Zone.HAND:
			_set_hand_content(resource)


## La main n'est pas un tableau : poser = spawn du pickup porté, retirer =
## consommation de l'objet porté.
func _set_hand_content(resource: ResourceDef) -> void:
	if _carry == null:
		return
	# Vider la main : consomme l'objet porté actuel.
	if _carry.is_carrying():
		_carry.consume()
	if resource == null:
		return
	var pickup: Node3D = ResourceRegistry.spawn_pickup(resource)
	if pickup == null:
		return
	get_tree().current_scene.add_child(pickup)
	pickup.global_position = _camera.global_position
	_carry.carry(pickup)


## --- Slot interne --------------------------------------------------------

class BackpackSlot extends Panel:
	var zone: BackpackUI.Zone
	var index: int
	var content: ResourceDef

	var _ui: BackpackUI
	var _icon: TextureRect
	var _label: Label

	func setup(p_zone: BackpackUI.Zone, p_index: int, p_size: float, p_ui: BackpackUI) -> void:
		zone = p_zone
		index = p_index
		_ui = p_ui
		custom_minimum_size = Vector2(p_size, p_size)
		size = Vector2(p_size, p_size)
		mouse_filter = Control.MOUSE_FILTER_STOP

		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.12, 0.12, 0.14, 0.85)
		style.border_color = Color(0.6, 0.6, 0.65, 0.6)
		style.set_border_width_all(2)
		style.set_corner_radius_all(4)
		add_theme_stylebox_override("panel", style)

		_icon = TextureRect.new()
		_icon.set_anchors_preset(Control.PRESET_FULL_RECT)
		_icon.offset_left = 4.0
		_icon.offset_top = 4.0
		_icon.offset_right = -4.0
		_icon.offset_bottom = -4.0
		_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_icon)

		# Fallback texte tant que l'icône n'est pas générée.
		_label = Label.new()
		_label.set_anchors_preset(Control.PRESET_FULL_RECT)
		_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_label.add_theme_font_size_override("font_size", 11)
		_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_label)

	func set_content(resource: ResourceDef) -> void:
		content = resource
		if resource == null:
			_icon.texture = null
			_label.text = ""
			return
		_label.text = resource.display_name
		_load_icon(resource)

	## Charge l'icône en asynchrone : le texte reste affiché en attendant,
	## et disparaît dès que l'icône arrive.
	func _load_icon(resource: ResourceDef) -> void:
		var icon: Texture2D = await ResourceRegistry.get_icon(resource)
		# La case a pu changer de contenu pendant la génération.
		if content != resource:
			return
		if icon:
			_icon.texture = icon
			_label.text = ""

	## --- Drag & drop natif Godot ---

	func _get_drag_data(_at_position: Vector2) -> Variant:
		if content == null:
			return null
		# Aperçu suivant le curseur.
		var preview := Panel.new()
		preview.custom_minimum_size = Vector2(size.x * 0.8, size.y * 0.8)
		preview.size = preview.custom_minimum_size
		var preview_style := StyleBoxFlat.new()
		preview_style.bg_color = Color(0.2, 0.2, 0.24, 0.9)
		preview_style.border_color = Color(1.0, 0.85, 0.2, 0.9)
		preview_style.set_border_width_all(2)
		preview_style.set_corner_radius_all(4)
		preview.add_theme_stylebox_override("panel", preview_style)
		if _icon.texture:
			var preview_icon := TextureRect.new()
			preview_icon.texture = _icon.texture
			preview_icon.set_anchors_preset(Control.PRESET_FULL_RECT)
			preview_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			preview_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			preview.add_child(preview_icon)
		else:
			var preview_label := Label.new()
			preview_label.text = content.display_name
			preview_label.set_anchors_preset(Control.PRESET_FULL_RECT)
			preview_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			preview_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			preview_label.add_theme_font_size_override("font_size", 11)
			preview.add_child(preview_label)
		set_drag_preview(preview)

		return {"zone": zone, "index": index}

	func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
		return data is Dictionary and data.has("zone") and data.has("index")

	func _drop_data(_at_position: Vector2, data: Variant) -> void:
		_ui.move_item(data["zone"], data["index"], zone, index)
