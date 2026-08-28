extends Interactable
class_name ConstructionSite

## Chantier générique : instancié par BuildModeController à la confirmation
## du placement. Affiche le fantôme du bâtiment (BuildingDef.ghost_scene,
## teinté "chantier"), accumule les ressources livrées au E (via
## Interactable.receive_resource, voir InteractionController._try_deliver_carried_item),
## puis se remplace par BuildingDef.built_scene une fois complet.
##
## Scène attendue (construction_site.tscn) : StaticBody3D (ce script) →
## CollisionShape3D (assigné à collision_shape_node) + Node3D "VisualRoot"
## (assigné à visual_root), vide au départ — le fantôme y est instancié au
## runtime selon le BuildingDef.

signal completed(built: Node)

const SITE_TINT := Color(1.0, 0.7, 0.1, 0.6)

@export var building_def: BuildingDef
@export var collision_shape_node: CollisionShape3D
@export var visual_root: Node3D

var _delivered: Dictionary = {}

func _ready() -> void:
	prompt_key = "interact.prompt.deliver"
	if building_def == null:
		return
	for cost in building_def.costs:
		_delivered[cost.resource.id] = 0
	if collision_shape_node and building_def.collision_shape:
		collision_shape_node.shape = building_def.collision_shape
		collision_shape_node.transform = building_def.collision_shape_local_transform()
	if visual_root and building_def.ghost_scene:
		var ghost := building_def.ghost_scene.instantiate()
		visual_root.add_child(ghost)
		_disable_collisions(ghost)
		_tint(ghost, SITE_TINT)

func can_interact(interactor: Node) -> bool:
	var resource := _get_offered_resource(interactor)
	return resource != null and _remaining_for(resource) > 0

func receive_resource(resource: ResourceDef, amount: int) -> bool:
	if resource == null or _remaining_for(resource) <= 0:
		return false
	_delivered[resource.id] = _delivered.get(resource.id, 0) + amount
	if _is_complete():
		_complete()
	return true

func _remaining_for(resource: ResourceDef) -> int:
	for cost in building_def.costs:
		if cost.resource == resource:
			return cost.amount - _delivered.get(resource.id, 0)
	return 0

func _is_complete() -> bool:
	for cost in building_def.costs:
		if _delivered.get(cost.resource.id, 0) < cost.amount:
			return false
	return true

func _complete() -> void:
	if building_def.built_scene:
		var built := building_def.built_scene.instantiate()
		var parent := get_parent()
		parent.add_child(built)
		built.global_transform = global_transform
		completed.emit(built)
	queue_free()

func _tint(node: Node, color: Color) -> void:
	if node is MeshInstance3D:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = color
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		node.material_override = mat
	for child in node.get_children():
		_tint(child, color)

## Le fantôme visuel instancié ici est purement décoratif — sa collision (si
## l'asset source en a une, ex. import SciFi avec Trimesh Static Body) doit
## être neutralisée pour ne pas interférer avec la collision réelle du
## chantier (collision_shape_node). Même pattern que CarryController.carry().
func _disable_collisions(node: Node) -> void:
	if node is CollisionObject3D:
		node.set("collision_layer", 0)
		node.set("collision_mask", 0)
	for child in node.get_children():
		_disable_collisions(child)
