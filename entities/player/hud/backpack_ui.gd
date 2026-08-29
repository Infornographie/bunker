extends WorldAnchoredPanel
class_name BackpackUI

## Interface du sac posé au sol.
##
## Layout :
##                    [ MAIN ]
##      [POCHE G]   [3x3 stockage]   [POCHE D]
##                   [POCHE BAS]
##
## L'ancrage monde, la fermeture et le cycle d'ouverture vivent dans
## WorldAnchoredPanel ; l'affichage et le drag & drop dans ItemSlot. Ne
## reste ici que ce qui est propre au sac : sa disposition et ses règles de
## transfert.

const STORAGE_SLOT_SIZE: float = 52.0
const BIG_SLOT_SIZE: float = 68.0
const GRID_GAP: float = 6.0
const ZONE_GAP: float = 24.0

## Identifiants de zone, portés par le payload des cases.
enum Zone { STORAGE, POCKET, HAND }

var _backpack_data: BackpackData
var _equipment: EquipmentController
var _carry: CarryController

var _storage_slots: Array[ItemSlot] = []
var _pocket_slots: Array[ItemSlot] = []
var _hand_slot: ItemSlot


## Branche le panneau sur un sac et le joueur. Appelé avant l'ouverture, qui
## passe elle par UIPanelController.
func bind(backpack: BackpackPickup, equipment: EquipmentController, carry: CarryController) -> void:
	_backpack_data = backpack.backpack_data
	_equipment = equipment
	_carry = carry


## Le mesh du sac remonterait sur la poche basse : on décale vers le haut.
func anchor_screen_offset() -> Vector2:
	return Vector2(0.0, -20.0)


## --- Construction des cases ----------------------------------------------

func _build_content() -> void:
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


func _make_slot(zone: Zone, index: int, slot_size: float) -> ItemSlot:
	var slot := ItemSlot.new()
	slot.setup({"zone": zone, "index": index}, slot_size, self)
	add_child(slot)
	return slot


## --- Rafraîchissement -----------------------------------------------------

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


## --- Contrat ItemSlot -----------------------------------------------------

## Le sac n'accepte que ses propres cases : un drag venu d'un autre panneau
## est refusé ici, c'est à ce panneau-là de définir ses règles.
func slot_can_accept(_target: ItemSlot, source: ItemSlot) -> bool:
	return source.slot_owner == self and source.content != null


func slot_accept_drop(target: ItemSlot, source: ItemSlot) -> void:
	move_item(source.payload, target.payload)


## Vide une de ses cases, appelé par le panneau *cible* après un transfert
## réussi vers lui (contrat ItemSlot). C'est ce qui permet de glisser un
## ingrédient du sac posé vers le feu d'à côté.
func slot_release(source: ItemSlot) -> void:
	_set_slot_content(source.payload, null)
	refresh()
	if _equipment:
		_equipment.notify_backpack_changed()


## --- Transferts -----------------------------------------------------------

func get_slot_content(slot_payload: Dictionary) -> ResourceDef:
	var index: int = slot_payload["index"]
	match slot_payload["zone"]:
		Zone.STORAGE:
			return _backpack_data.storage_slots[index]
		Zone.POCKET:
			return _backpack_data.pocket_slots[index]
		Zone.HAND:
			return _get_hand_resource()
	return null


## Déplace le contenu d'un emplacement vers un autre. Échange si la cible est
## occupée (comportement attendu d'un inventaire à cases).
func move_item(from_payload: Dictionary, to_payload: Dictionary) -> void:
	if from_payload == to_payload:
		return
	var moving := get_slot_content(from_payload)
	if moving == null:
		return
	var displaced := get_slot_content(to_payload)

	_set_slot_content(from_payload, displaced)
	_set_slot_content(to_payload, moving)
	refresh()
	# Le hotbar reflète les poches : le tenir à jour.
	if _equipment:
		_equipment.notify_backpack_changed()


func _set_slot_content(slot_payload: Dictionary, resource: ResourceDef) -> void:
	var index: int = slot_payload["index"]
	match slot_payload["zone"]:
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
