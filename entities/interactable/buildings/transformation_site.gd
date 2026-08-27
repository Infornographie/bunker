extends Node
class_name TransformationSite

## Composant de transformation, enfant d'un bâtiment. Porte les recettes,
## encaisse les ingrédients, fait tourner le timer, crache le résultat en
## pickup physique. Ne connaît pas son hôte : si celui-ci expose is_active(),
## les recettes marquées requires_host_active se mettent en pause quand il
## est inactif.
##
## Point d'entrée unique pour tous les dépôts (E en main, UI depuis les
## poches plus tard) : try_insert().

signal state_changed
signal completed(output: ResourceDef, amount: int)

@export var recipes: Array[RecipeDef] = []
## Où spawnent le résultat et les ingrédients rendus. Défaut : l'hôte.
@export var output_spawn: Node3D
@export var output_spawn_offset: Vector3 = Vector3(0.0, 0.6, 0.0)

var active_recipe: RecipeDef

var _stored: Dictionary = {}
var _timer: Timer
var _host: Node


func _ready() -> void:
	_host = get_parent()
	if output_spawn == null and _host is Node3D:
		output_spawn = _host
	_timer = Timer.new()
	_timer.one_shot = true
	add_child(_timer)
	_timer.timeout.connect(_on_finished)
	set_process(false)


## Seule la pause est pilotée par frame : source unique de vérité, plutôt
## qu'un signal à écouter sur chaque type d'hôte.
func _process(_delta: float) -> void:
	_timer.paused = active_recipe != null and active_recipe.requires_host_active and not _is_host_active()


## --- API publique ---------------------------------------------------------

func is_running() -> bool:
	return _timer.time_left > 0.0


## Avancement de la cuisson en cours, 0.0 → 1.0.
func get_progress() -> float:
	if active_recipe == null or not is_running():
		return 0.0
	return 1.0 - (_timer.time_left / active_recipe.duration)


func get_stored_amount(resource: ResourceDef) -> int:
	return int(_stored.get(resource, 0))


## Quantité encore attendue d'un ingrédient pour la recette active.
func get_missing_amount(resource: ResourceDef) -> int:
	if active_recipe == null:
		return 0
	for cost in active_recipe.inputs:
		if cost.resource == resource:
			return maxi(0, cost.amount - get_stored_amount(resource))
	return 0


func accepts(resource: ResourceDef) -> bool:
	if resource == null or is_running():
		return false
	if active_recipe != null:
		return get_missing_amount(resource) > 0
	return _find_recipe_for(resource) != null


## Sélection explicite (UI). Rend les ingrédients déjà déposés si on change
## d'avis. Refusée pendant une cuisson.
func select_recipe(recipe: RecipeDef) -> bool:
	if is_running() or recipe == active_recipe:
		return false
	_refund_stored()
	active_recipe = recipe
	state_changed.emit()
	return true


## Dépôt d'un exemplaire. Si aucune recette n'est active, la première recette
## acceptant cet ingrédient s'active toute seule — c'est ce qui rend le dépôt
## à la main utilisable sans passer par l'UI.
func try_insert(resource: ResourceDef) -> bool:
	if not accepts(resource):
		return false
	if active_recipe == null:
		active_recipe = _find_recipe_for(resource)
	_stored[resource] = get_stored_amount(resource) + 1
	state_changed.emit()
	_try_start()
	return true


## --- Interne --------------------------------------------------------------

func _find_recipe_for(resource: ResourceDef) -> RecipeDef:
	for recipe in recipes:
		for cost in recipe.inputs:
			if cost.resource == resource:
				return recipe
	return null


func _try_start() -> void:
	for cost in active_recipe.inputs:
		if get_stored_amount(cost.resource) < cost.amount:
			return
	_stored.clear()
	_timer.start(active_recipe.duration)
	set_process(true)
	state_changed.emit()


func _on_finished() -> void:
	set_process(false)
	_timer.paused = false
	var recipe := active_recipe
	active_recipe = null
	_spawn(recipe.output, recipe.output_amount)
	completed.emit(recipe.output, recipe.output_amount)
	state_changed.emit()


func _refund_stored() -> void:
	for resource in _stored:
		_spawn(resource, _stored[resource])
	_stored.clear()


func _spawn(resource: ResourceDef, amount: int) -> void:
	if resource == null or output_spawn == null:
		return
	for i in amount:
		var pickup: Node3D = ResourceRegistry.spawn_pickup(resource)
		if pickup == null:
			continue
		# Léger éparpillement pour éviter que N pickups se chevauchent au
		# même point et se repoussent violemment au premier pas de physique.
		var scatter := Vector3(randf_range(-0.2, 0.2), 0.0, randf_range(-0.2, 0.2))
		var world_pos := output_spawn.global_position + output_spawn_offset + scatter
		output_spawn.add_child(pickup)
		pickup.global_position = world_pos


func _is_host_active() -> bool:
	if _host == null or not _host.has_method("is_active"):
		return true
	return bool(_host.call("is_active"))
