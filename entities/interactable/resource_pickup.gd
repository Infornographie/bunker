extends Interactable
class_name ResourcePickup

@export var resource_def: ResourceDef
@export var amount: int = 1
@export var scatter_impulse: float = 1.0

var _fall_direction: Vector3 = Vector3.ZERO

## Appelé par Choppable._spawn_pickup() avant add_child, pour orienter la
## chute vers l'avant du coup plutôt qu'aléatoirement.
func set_fall_direction(direction: Vector3) -> void:
	_fall_direction = direction

func _ready() -> void:
	# self est statiquement typé ResourcePickup (hérite de PhysicsBody3D),
	# donc un "is RigidBody3D" direct est rejeté à la compilation (classe
	# non liée). On repasse par Node pour forcer une vérification au runtime.
	var node: Node = self
	if not (node is RigidBody3D):
		return
	set("can_sleep", false)
	var base_direction := _fall_direction
	if base_direction == Vector3.ZERO:
		base_direction = Vector3(randf_range(-1.0, 1.0), 0.0, randf_range(-1.0, 1.0))
	var impulse := (base_direction + Vector3(randf_range(-0.2, 0.2), 0.3, randf_range(-0.2, 0.2))).normalized() * scatter_impulse
	call("apply_central_impulse", impulse)

## Pas d'inventaire pour l'instant (dette, voir ROADMAP) : on se contente
## de logger le ramassage et de retirer l'objet du monde.
func interact(_interactor: Node) -> void:
	if resource_def == null:
		push_warning("ResourcePickup sans ResourceDef assigné : %s" % name)
		return
	print("Ramassé : %d x %s" % [amount, resource_def.display_name])
	queue_free()
