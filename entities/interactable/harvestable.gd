extends Interactable
class_name Harvestable
## Source de récolte : encaisse les coups d'un type d'outil, puis se vide en
## lâchant son butin.
##
## **Un seul comportement pour toutes les ressources.** Un arbre qu'on abat et
## un bloc qu'on pioche ne diffèrent que par deux données — le type d'outil qui
## mord dessus, et ce qui tombe. Écrire un `Mineable` à côté d'un `Choppable`
## aurait recopié la santé, le son, le calcul de chute et la destruction pour ne
## changer qu'une comparaison d'enum.

signal depleted

## Type d'outil qui entame cette source. Un autre type ne fait rien du tout :
## c'est le verrou, la puissance de l'outil n'est qu'une vitesse.
@export var required_tool_type: ToolDef.ToolType = ToolDef.ToolType.CHOP
@export var max_health: int = 3
@export var hit_sound: AudioStream
## Ce qui tombe à l'épuisement. Les scènes de pickup sont résolues par
## `ResourceRegistry` : c'est la seule façon d'obtenir un pickup dans le projet.
@export var drops: Array[ResourceDrop] = []
@export var spawn_height_offset: float = 0.3
@export var pickup_stack_spacing: float = 1.3
## Écartement horizontal entre deux piles de butin, en mètres. Chaque ligne de
## `drops` fait sa propre pile : empiler des branches sur des rondins les fait
## tomber du sommet et rebondir n'importe où.
@export var drop_spread: float = 1.1
@export var pickup_spawn_rotation_degrees: Vector3 = Vector3(90.0, 0.0, 0.0)

var _health: int
var _is_depleted: bool = false


func _ready() -> void:
	_health = max_health


## Contrôle uniquement l'affichage HUD (prompt/réticule) — le déclenchement
## réel passe par `receive_tool_hit()`, appelé que la cible soit interactable
## ou non (voir `InteractionController._try_use_tool()`).
func can_interact(interactor: Node) -> bool:
	var tool_controller := _get_tool_controller(interactor)
	if tool_controller == null or not tool_controller.can_swing():
		return false
	var tool := tool_controller.get_equipped_tool()
	return tool != null and tool.tool_type == required_tool_type


## La récolte se déclenche au clic (use_tool), cible valide ou non — pas via la
## touche d'interaction générique (E).
func uses_tool_trigger() -> bool:
	return true


func receive_tool_hit(tool: ToolDef, hit_origin: Vector3 = Vector3.ZERO) -> void:
	if tool == null or tool.tool_type != required_tool_type or _is_depleted:
		return
	if hit_sound:
		SoundManager.play_sfx(hit_sound, global_position)
	_health -= tool.damage
	if _health > 0:
		return
	_is_depleted = true
	var spawn_position := global_position
	depleted.emit()
	_spawn_drops(hit_origin, spawn_position)
	queue_free()


func _spawn_drops(hit_origin: Vector3, spawn_position: Vector3) -> void:
	var fall_direction := Vector3.ZERO
	if hit_origin != Vector3.ZERO:
		fall_direction = spawn_position - hit_origin
		fall_direction.y = 0.0
		fall_direction = fall_direction.normalized()

	# Une pile par ligne de butin, réparties en cercle autour du point de chute.
	# Les lignes valides se comptent d'abord : c'est leur nombre qui donne
	# l'angle, et une ligne unique ne doit pas se retrouver décalée pour rien.
	var lines: Array[ResourceDrop] = []
	for drop in drops:
		if drop != null and drop.resource != null:
			lines.append(drop)
	if lines.is_empty():
		return

	var parent := get_parent()
	for index in lines.size():
		var drop := lines[index]
		var offset := Vector3.ZERO
		if lines.size() > 1:
			var angle := TAU * float(index) / float(lines.size())
			offset = Vector3(cos(angle), 0.0, sin(angle)) * drop_spread
		for i in drop.count:
			var pickup: Node3D = ResourceRegistry.spawn_pickup(drop.resource)
			if pickup == null:
				break
			var world_position := spawn_position + offset + Vector3(0.0,
					spawn_height_offset + i * pickup_stack_spacing, 0.0)
			pickup.position = parent.global_transform.affine_inverse() * world_position
			pickup.rotation_degrees = pickup_spawn_rotation_degrees
			if pickup.has_method("set_fall_direction"):
				pickup.set_fall_direction(fall_direction)
			parent.add_child(pickup)


func _get_tool_controller(interactor: Node) -> ToolController:
	if interactor is InteractionController:
		return interactor.tool_controller
	return null
