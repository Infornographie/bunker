extends WorldPanel
class_name BackpackPanel

## Panneau du sac posé au sol.
##
## Disposition :
##      [POCHE G]   [3x3 stockage]   [POCHE D]
##                   [POCHE BAS]
##
## Plus de case « main » : la main est la main. On prend une case pleine
## avec E, l'objet arrive vraiment en main, et on le pose dans une autre
## case — du même sac, d'un feu, ou par terre. Le transfert n'a plus besoin
## d'exister en tant que mécanisme.

## Identifiants de zone, portés par le payload des cases.
enum Zone { STORAGE, POCKET }

var _backpack_data: BackpackData

var _storage_slots: Array[PanelSlot] = []
var _pocket_slots: Array[PanelSlot] = []


## Branche le panneau sur un sac. Appelé avant l'ouverture, qui passe elle
## par UIPanelController.
func bind(backpack: BackpackPickup) -> void:
	_backpack_data = backpack.backpack_data


func _build_content() -> void:
	# Grille de stockage 3x3, centrée sur l'origine du panneau.
	for i in BackpackData.STORAGE_COUNT:
		var row: int = int(i / 3.0)
		var col: int = i % 3
		var slot := make_slot({"zone": Zone.STORAGE, "index": i})
		slot.position = grid_position(col - 1.0, row - 1.0)
		_storage_slots.append(slot)

	# Poches : gauche, droite, bas — mêmes positions relatives qu'au corps.
	var pocket_cells: Array[Vector2] = [
		Vector2(-2.2, 0.0),
		Vector2(2.2, 0.0),
		Vector2(0.0, 2.2),
	]
	for i in BackpackData.POCKET_COUNT:
		var slot := make_slot({"zone": Zone.POCKET, "index": i})
		slot.position = grid_position(pocket_cells[i].x, pocket_cells[i].y)
		_pocket_slots.append(slot)


func refresh() -> void:
	if _backpack_data == null:
		return
	for i in _storage_slots.size():
		_storage_slots[i].set_content(_backpack_data.storage_slots[i])
	for i in _pocket_slots.size():
		_pocket_slots[i].set_content(_backpack_data.pocket_slots[i])


## --- Contrat de case ------------------------------------------------------

## Le payload est volontairement opaque côté PanelSlot, donc il arrive ici
## en Variant : on le retype explicitement plutôt que de laisser l'inférence
## s'en charger (elle abandonne, avec un « Compiler bug » pour tout message).
func slot_content(slot: PanelSlot) -> ResourceDef:
	var payload: Dictionary = slot.payload
	var index: int = int(payload["index"])
	match int(payload["zone"]):
		Zone.STORAGE:
			return _backpack_data.storage_slots[index]
		Zone.POCKET:
			return _backpack_data.pocket_slots[index]
	return null


## Une case n'accueille qu'un objet à la fois : sans glisser-déposer, il n'y
## a plus d'échange possible, donc pas de case occupée à déloger.
func slot_accepts(slot: PanelSlot, resource: ResourceDef) -> bool:
	if resource == null or _backpack_data == null:
		return false
	return slot_content(slot) == null


func slot_can_take(slot: PanelSlot) -> bool:
	return slot_content(slot) != null


func slot_take(slot: PanelSlot) -> ResourceDef:
	var resource := slot_content(slot)
	if resource == null:
		return null
	_set_slot_content(slot, null)
	return resource


func slot_put(slot: PanelSlot, resource: ResourceDef) -> bool:
	if not slot_accepts(slot, resource):
		return false
	_set_slot_content(slot, resource)
	return true


func _set_slot_content(slot: PanelSlot, resource: ResourceDef) -> void:
	var payload: Dictionary = slot.payload
	var index: int = int(payload["index"])
	match int(payload["zone"]):
		Zone.STORAGE:
			_backpack_data.storage_slots[index] = resource
		Zone.POCKET:
			_backpack_data.pocket_slots[index] = resource
	refresh()
	# Le hotbar reflète les poches : le tenir à jour.
	if _interactor and _interactor.equipment_controller:
		_interactor.equipment_controller.notify_backpack_changed()
