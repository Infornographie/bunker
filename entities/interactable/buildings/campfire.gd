extends Interactable
class_name Campfire

## Bâtiment posé (feu de camp) : cycle allumé/éteint. S'éteint après
## burn_duration, se rallume ou se recharge en livrant
## refuel_amount_required exemplaires de refuel_resource (E).
##
## Scène attendue (campfire.tscn) : structure "bonfire" toujours visible +
## enfant "bonfire_fire" (flamme) assigné à flame_visual, togglé selon
## l'état + un enfant TransformationSite portant les recettes de cuisson.
##
## Dette : burn_duration arbitraire, à ajuster au feeling en jeu une fois
## testé — voir ROADMAP.md.

@export var refuel_resource: ResourceDef
@export var refuel_amount_required: int = 1
@export var burn_duration: float = 120.0
@export var flame_visual: Node3D
@export var transformation: TransformationSite

var _lit: bool = false
var _burn_timer: Timer


func _ready() -> void:
	_burn_timer = Timer.new()
	_burn_timer.one_shot = true
	add_child(_burn_timer)
	_burn_timer.timeout.connect(_extinguish)
	_set_lit(false)


## Consommé par TransformationSite (duck typing) pour mettre la cuisson en
## pause quand le feu est mort.
func is_active() -> bool:
	return _lit


## Combustible restant, 0.0 → 1.0. Pour la jauge de l'UI (Passe B).
func get_fuel_ratio() -> float:
	return _burn_timer.time_left / burn_duration


func can_interact(interactor: Node) -> bool:
	var resource := _get_offered_resource(interactor)
	if resource == null:
		return false
	if resource == refuel_resource:
		return true
	return transformation != null and transformation.accepts(resource)


func receive_resource(resource: ResourceDef, amount: int) -> bool:
	print("recv ", resource.id, " | transfo=", transformation, " | accepts=", transformation.accepts(resource) if transformation else "n/a")
	# Le combustible prime : un même objet ne peut pas être à la fois bûche
	# et ingrédient sans qu'on ait à trancher ici.
	if resource == refuel_resource:
		if amount < refuel_amount_required:
			return false
		_refuel()
		return true
	if transformation != null:
		return transformation.try_insert(resource)
	return false


func _refuel() -> void:
	# Recharge complète, plafonnée : une bûche remet le feu à plein, qu'il
	# soit mort ou déjà en train de brûler.
	_burn_timer.start(burn_duration)
	_set_lit(true)


func _extinguish() -> void:
	_set_lit(false)


func _set_lit(value: bool) -> void:
	_lit = value
	prompt_key = "interact.prompt.feed_fire" if value else "interact.prompt.light_fire"
	if flame_visual:
		flame_visual.visible = value
		# Coupe aussi l'émission (pas juste le rendu) si c'est un système de
		# particules — évite que les particules déjà émises continuent de
		# vivre invisibles, ou réapparaissent d'un coup au rallumage.
		if flame_visual.has_method("set_emitting"):
			flame_visual.set_emitting(value)
