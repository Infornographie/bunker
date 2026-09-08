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

## Faux pour ce qui se ramasse à la main : un champignon, une branche au sol,
## un caillou. La source répond alors à la touche d'interaction au lieu du clic
## d'outil, `required_tool_type` est ignoré, et un seul geste suffit quels que
## soient les PV.
##
## C'est le même objet dans les deux cas, et c'est voulu : ce qui distingue
## cueillir de couper est le geste, pas la nature de ce qu'on récolte. Un
## `Gatherable` écrit à côté aurait recopié la table de butin, les piles et la
## destruction pour changer un mode d'entrée.
@export var requires_tool: bool = true
## Type d'outil qui entame cette source, quand elle en demande un. Un autre type
## ne fait rien du tout : c'est le verrou, la puissance de l'outil n'est qu'une
## vitesse.
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
	if _is_depleted:
		return false
	if not requires_tool:
		# Cueillir demande seulement d'avoir les mains libres — le butin doit
		# pouvoir aller quelque part.
		var carry := _get_carry_controller(interactor)
		return carry == null or carry.can_carry()
	var tool_controller := _get_tool_controller(interactor)
	if tool_controller == null or not tool_controller.can_swing():
		return false
	var tool := tool_controller.get_equipped_tool()
	return tool != null and tool.tool_type == required_tool_type


## La récolte à l'outil se déclenche au clic, cible valide ou non ; la cueillette
## passe par la touche d'interaction générique.
func uses_tool_trigger() -> bool:
	return requires_tool


## Cueillette : un geste, et la source est vidée quels que soient ses PV. Doser
## une cueillette en plusieurs appuis n'aurait aucune lecture pour le joueur.
func interact(interactor: Node) -> void:
	if requires_tool or _is_depleted:
		return
	if not can_interact(interactor):
		return
	_is_depleted = true
	depleted.emit()
	# Ce qui est cueilli à la main part **dans les poches**, pas au sol. Le
	# faire tomber pour le ramasser aussitôt ajoute un geste que personne n'a
	# demandé : le joueur a déjà exprimé son intention en appuyant sur E.
	# Ce qui ne rentre pas retombe, et c'est le seul cas où il y a un objet
	# physique à ramasser.
	var leftovers: Array[ResourceDrop] = []
	var inventory := _get_inventory(interactor)
	for drop in drops:
		if drop == null or drop.resource == null:
			continue
		var stored := 0
		if inventory != null:
			for i in drop.count:
				if not _store(inventory, drop.resource):
					break
				stored += 1
		if stored < drop.count:
			var rest := ResourceDrop.new()
			rest.resource = drop.resource
			rest.count = drop.count - stored
			leftovers.append(rest)
	if not leftovers.is_empty():
		var kept := drops
		drops = leftovers
		var spawned := _spawn_drops(Vector3.ZERO, global_position)
		drops = kept
		# Ce que l'inventaire refuse suit le même repli que le ramassage d'un
		# pickup au sol — poches, puis sac, puis **la main**. Le laisser tomber
		# obligeait à le ramasser aussitôt, ce que personne n'a demandé.
		var carry := _get_carry_controller(interactor)
		if carry != null and carry.can_carry() and not spawned.is_empty():
			carry.carry(spawned[0])
	queue_free()


## Range une ressource selon son type de portage. Même routage que le ramassage
## d'un pickup au sol — il n'existe qu'une façon de ranger quelque chose.
func _store(inventory: Inventory, resource: ResourceDef) -> bool:
	match resource.carry_type:
		ResourceDef.CarryType.SMALL:
			return inventory.try_store_small(resource)
		ResourceDef.CarryType.TOOL:
			return resource.tool_def != null and inventory.try_store_tool(resource.tool_def)
		_:
			return false


func _get_inventory(interactor: Node) -> Inventory:
	if interactor is InteractionController:
		return interactor.inventory
	return null


func receive_tool_hit(tool: ToolDef, hit_origin: Vector3 = Vector3.ZERO) -> void:
	if not requires_tool or _is_depleted:
		return
	if tool == null or tool.tool_type != required_tool_type:
		return
	if hit_sound:
		SoundManager.play_sfx(hit_sound, global_position)
	_health -= tool.damage
	if _health > 0:
		return
	_deplete(global_position, hit_origin)


func _deplete(spawn_position: Vector3, hit_origin: Vector3) -> void:
	_is_depleted = true
	depleted.emit()
	# Le retour ne sert qu'à la cueillette (repli en main) ; à l'outil, le
	# butin tombe et reste au sol. Assigné plutôt qu'ignoré : le projet traite
	# les avertissements en erreurs.
	var _dropped := _spawn_drops(hit_origin, spawn_position)
	queue_free()


## Sème le butin et retourne les nœuds créés, dans l'ordre des lignes de butin.
func _spawn_drops(hit_origin: Vector3, spawn_position: Vector3) -> Array[Node3D]:
	var fall_direction := Vector3.ZERO
	if hit_origin != Vector3.ZERO:
		fall_direction = spawn_position - hit_origin
		fall_direction.y = 0.0
		fall_direction = fall_direction.normalized()

	# Une pile par ligne de butin, réparties en cercle autour du point de chute.
	# Les lignes valides se comptent d'abord : c'est leur nombre qui donne
	# l'angle, et une ligne unique ne doit pas se retrouver décalée pour rien.
	var spawned: Array[Node3D] = []
	var lines: Array[ResourceDrop] = []
	for drop in drops:
		if drop != null and drop.resource != null:
			lines.append(drop)
	if lines.is_empty():
		return spawned

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
			spawned.append(pickup)
	return spawned


func _get_tool_controller(interactor: Node) -> ToolController:
	if interactor is InteractionController:
		return interactor.tool_controller
	return null


func _get_carry_controller(interactor: Node) -> CarryController:
	if interactor is InteractionController:
		return interactor.carry_controller
	return null
