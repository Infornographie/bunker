extends Interactable
class_name BackpackPickup

## Sac à dos dans le monde — trouvé dans le bunker ou posé par le joueur.
## Porte les données d'inventaire (BackpackData). L'objet circule entre :
##   - le monde (Interactable au sol, cette scène)
##   - le dos du joueur (données dans EquipmentController, node détruit)
##   - les mains (porté par CarryController, même node reparenté)
##
## E : équiper sur le dos (B.3 changera en "ouvrir l'UI").
## A : équiper sur le dos (depuis le sol, via InteractionController).

var backpack_data: BackpackData

## Décalage vertical appliqué après le snap au sol. À régler si l'origine
## du .tscn n'est pas à la base du mesh (sinon le sac s'enfonce).
@export var ground_offset: float = 0.0

var _snap_requested: bool = false


func _ready() -> void:
	if backpack_data == null:
		backpack_data = BackpackData.new()
	if prompt_key == "interact.prompt.interact":
		prompt_key = "interact.prompt.open_backpack"
	set_physics_process(false)


## E : ouvrir l'interface du sac (accès au stockage 10 slots).
## A : équiper sur le dos — géré par InteractionController, pas ici.
func can_interact(_interactor: Node) -> bool:
	# Le sac au sol est toujours ouvrable, sac équipé ou non.
	return true


func interact(interactor: Node) -> void:
	if interactor is InteractionController:
		interactor.open_backpack_ui(self)


## --- Snap au sol --------------------------------------------------------

## Appelé par InteractionController après un drop (StaticBody3D ne tombe
## pas tout seul). Attend un frame physique pour que le raycast fonctionne
## après le reparent.
func request_ground_snap() -> void:
	_snap_requested = true
	set_physics_process(true)


func _physics_process(_delta: float) -> void:
	if not _snap_requested:
		set_physics_process(false)
		return
	_snap_requested = false
	set_physics_process(false)
	var space := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(
		global_position + Vector3.UP * 2.0,
		global_position + Vector3.DOWN * 20.0
	)
	query.exclude = [get_rid()]
	var result := space.intersect_ray(query)
	if result:
		global_position = result.position + Vector3.UP * ground_offset


## --- Utilitaire ---------------------------------------------------------

func _get_equipment_controller(interactor: Node) -> EquipmentController:
	if interactor is InteractionController:
		return interactor.equipment_controller
	return null
