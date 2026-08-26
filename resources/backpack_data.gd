extends Resource
class_name BackpackData

## Données d'un sac à dos. Vit sur l'objet sac (pas sur le joueur) : si le
## sac est lâché, les items restent dedans. Chaque pawn/robot qui porte un
## sac a sa propre instance de BackpackData.

const POCKET_COUNT: int = 3
const STORAGE_COUNT: int = 9

## Poches (accès direct, hotbar 3-5). null = slot vide.
@export var pocket_slots: Array[ResourceDef] = []
## Grande poche (accès sac posé au sol uniquement). null = slot vide.
@export var storage_slots: Array[ResourceDef] = []


func _init() -> void:
	_ensure_slot_sizes()


## Garantit que les tableaux ont la bonne taille (appel défensif, utile
## après désérialisation ou instanciation manuelle).
func _ensure_slot_sizes() -> void:
	pocket_slots.resize(POCKET_COUNT)
	storage_slots.resize(STORAGE_COUNT)


## Tente de ranger un petit objet : poche d'abord, puis stockage.
## Retourne true si absorbé, false si tout est plein.
func try_store(resource: ResourceDef) -> bool:
	for i in POCKET_COUNT:
		if pocket_slots[i] == null:
			pocket_slots[i] = resource
			return true
	for i in STORAGE_COUNT:
		if storage_slots[i] == null:
			storage_slots[i] = resource
			return true
	return false


## Retourne l'index de la première poche libre, ou -1.
func first_free_pocket() -> int:
	for i in POCKET_COUNT:
		if pocket_slots[i] == null:
			return i
	return -1


## Retourne l'index du premier slot stockage libre, ou -1.
func first_free_storage() -> int:
	for i in STORAGE_COUNT:
		if storage_slots[i] == null:
			return i
	return -1


## Nombre total d'items (poches + stockage).
func item_count() -> int:
	var count: int = 0
	for slot in pocket_slots:
		if slot != null:
			count += 1
	for slot in storage_slots:
		if slot != null:
			count += 1
	return count
