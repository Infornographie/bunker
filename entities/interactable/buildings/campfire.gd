extends Interactable
class_name Campfire

## Bâtiment posé (feu de camp) : cycle allumé/éteint. S'éteint après
## burn_duration, se rallume en livrant refuel_amount_required exemplaires
## de refuel_resource (E) tant qu'éteint.
##
## Scène attendue (campfire.tscn) : structure "bonfire" toujours visible +
## enfant "bonfire_fire" (flamme) assigné à flame_visual, togglé selon l'état.
##
## Dette : burn_duration arbitraire, à ajuster au feeling en jeu une fois
## testé — voir ROADMAP.md.

@export var refuel_resource: ResourceDef
@export var refuel_amount_required: int = 1
@export var burn_duration: float = 120.0
@export var flame_visual: Node3D

var _lit: bool = true
var _burn_timer: Timer

func _ready() -> void:
	prompt_text = "Allumer"
	_burn_timer = Timer.new()
	_burn_timer.one_shot = true
	_burn_timer.wait_time = burn_duration
	add_child(_burn_timer)
	_burn_timer.timeout.connect(_extinguish)
	_set_lit(false)

func can_interact(interactor: Node) -> bool:
	if _lit:
		return false
	var resource := _get_carried_resource(interactor)
	return resource == refuel_resource

func receive_resource(resource: ResourceDef, amount: int) -> bool:
	if _lit or resource != refuel_resource or amount < refuel_amount_required:
		return false
	_set_lit(true)
	_burn_timer.start()
	return true

func _extinguish() -> void:
	_set_lit(false)

func _set_lit(value: bool) -> void:
	_lit = value
	if flame_visual:
		flame_visual.visible = value
		# Coupe aussi l'émission (pas juste le rendu) si c'est un système de
		# particules — évite que les particules déjà émises continuent de
		# vivre invisibles, ou réapparaissent d'un coup au rallumage.
		if flame_visual.has_method("set_emitting"):
			flame_visual.set_emitting(value)
