extends Node
class_name Inventory
## Ce qu'un acteur porte : ceinture, poches, sac, et le slot actif.
##
## **Le stock, et rien d'autre.** Pas de touches, pas de HUD, pas de viewmodel,
## pas de position dans le monde — cette classe ne sait pas qui la manipule ni
## comment on la regarde. C'est ce qui la rend utilisable par autre chose qu'un
## joueur : un pawn a une ceinture et des poches, il n'a ni hotbar ni caméra.
## Tout ce qui suppose un joueur vit dans `PlayerEquipment`, qui possède un
## `Inventory` et l'habille.
##
## Slots logiques (adressage commun au HUD et à la sélection) :
##   0-1  →  ceinture (outils, `ToolDef`)
##   2-4  →  poches du sac à dos (petits objets, `BackpackData.pocket_slots`)
##
## Priorité : ce qui est **en main** (`CarryController`) prime sur le slot actif.
## Un acteur qui porte un objet lourd garde ses outils, il ne peut simplement
## pas s'en servir.

## Émis à toute mutation du stock ou du slot actif. Un seul signal, parce
## qu'aucun client ne s'est jamais intéressé à *quel* slot avait changé : les
## trois signaux détaillés d'avant (`belt_changed`, `pocket_changed`,
## `active_slot_changed`) étaient émis sept fois et écoutés zéro.
signal changed

const BELT_COUNT: int = 2
const HOTBAR_SIZE: int = 5  # 2 ceinture + 3 poches

## Ce qui est tenu en main, seule chose qui prime sur le slot actif.
@export var carry_controller: CarryController
## Outils placés dans la ceinture au démarrage (max `BELT_COUNT`).
@export var starting_tools: Array[ToolDef] = []

var _belt: Array[ToolDef] = []
var _backpack_data: BackpackData
var _active_slot: int = 0


func _ready() -> void:
	_belt.resize(BELT_COUNT)
	for i in mini(starting_tools.size(), BELT_COUNT):
		_belt[i] = starting_tools[i]


## --- Lecture ------------------------------------------------------------

func get_active_slot() -> int:
	return _active_slot


func get_belt_tool(index: int) -> ToolDef:
	if index < 0 or index >= BELT_COUNT:
		return null
	return _belt[index]


## La ceinture entière, pour un affichage qui veut tout d'un coup.
func get_belt() -> Array[ToolDef]:
	return _belt


func get_backpack_data() -> BackpackData:
	return _backpack_data


func has_backpack() -> bool:
	return _backpack_data != null


## Nombre de slots adressables : sans sac, seule la ceinture existe.
func slot_count() -> int:
	return HOTBAR_SIZE if has_backpack() else BELT_COUNT


func hands_busy() -> bool:
	return carry_controller != null and carry_controller.is_carrying()


## Outil actif, ou null si le slot courant est une poche, est vide, ou si les
## mains sont prises.
func get_active_tool() -> ToolDef:
	if hands_busy():
		return null
	if _active_slot < BELT_COUNT:
		return _belt[_active_slot]
	return null


## Contenu du slot poche à l'index de slot (2-4). Null si pas de sac ou vide.
func get_pocket_content(slot_index: int) -> ResourceDef:
	if _backpack_data == null:
		return null
	var pocket_i: int = slot_index - BELT_COUNT
	if pocket_i < 0 or pocket_i >= BackpackData.POCKET_COUNT:
		return null
	return _backpack_data.pocket_slots[pocket_i]


## Petit objet actuellement en main via une poche, ou null.
func get_active_pocket_item() -> ResourceDef:
	if hands_busy() or _active_slot < BELT_COUNT:
		return null
	return get_pocket_content(_active_slot)


## --- Slot actif ---------------------------------------------------------

func set_active_slot(index: int) -> void:
	index = clampi(index, 0, slot_count() - 1)
	if index == _active_slot:
		return
	_active_slot = index
	changed.emit()


func cycle_slot(direction: int) -> void:
	var count := slot_count()
	var next: int = (_active_slot + direction) % count
	if next < 0:
		next += count
	set_active_slot(next)


## --- Sac ----------------------------------------------------------------

func equip_backpack(data: BackpackData) -> void:
	_backpack_data = data
	changed.emit()


func unequip_backpack() -> BackpackData:
	var old := _backpack_data
	_backpack_data = null
	# Le slot actif pouvait être une poche qui n'existe plus.
	_active_slot = mini(_active_slot, slot_count() - 1)
	changed.emit()
	return old


## Le contenu du sac a été modifié de l'extérieur (panneau ouvert).
func notify_backpack_changed() -> void:
	changed.emit()


## --- Rangement ----------------------------------------------------------

## Place un outil dans la ceinture. True si absorbé.
func try_store_tool(tool_def: ToolDef) -> bool:
	for i in BELT_COUNT:
		if _belt[i] == null:
			_belt[i] = tool_def
			changed.emit()
			return true
	return false


## Range une ressource selon son type de portage. **Seul point où le routage
## est écrit** : le ramassage au sol, la cueillette et la reprise dans un dépôt
## posaient la même question et y répondaient chacun à leur façon.
func try_store(resource: ResourceDef) -> bool:
	if resource == null:
		return false
	match resource.carry_type:
		ResourceDef.CarryType.SMALL:
			return try_store_small(resource)
		ResourceDef.CarryType.TOOL:
			return resource.tool_def != null and try_store_tool(resource.tool_def)
		_:
			return false


## Place un petit objet dans les poches puis le stockage du sac. True si absorbé.
func try_store_small(resource: ResourceDef) -> bool:
	if _backpack_data == null:
		return false
	if not _backpack_data.try_store(resource):
		return false
	changed.emit()
	return true


## --- Retrait ------------------------------------------------------------

## Retire l'outil du slot ceinture et le retourne (ou null).
func remove_belt_tool(index: int) -> ToolDef:
	if index < 0 or index >= BELT_COUNT:
		return null
	var old := _belt[index]
	if old == null:
		return null
	_belt[index] = null
	changed.emit()
	return old


## Retire l'item d'une poche et le retourne (ou null).
func remove_pocket_item(pocket_index: int) -> ResourceDef:
	if _backpack_data == null or pocket_index < 0 or pocket_index >= BackpackData.POCKET_COUNT:
		return null
	var old := _backpack_data.pocket_slots[pocket_index]
	if old == null:
		return null
	_backpack_data.pocket_slots[pocket_index] = null
	changed.emit()
	return old


## Retire l'objet de la poche active et le retourne (ou null).
func take_active_pocket_item() -> ResourceDef:
	if _active_slot < BELT_COUNT:
		return null
	return remove_pocket_item(_active_slot - BELT_COUNT)
