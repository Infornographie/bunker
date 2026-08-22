extends Node3D
class_name ActionStateMachine

## Arbitre des actions du joueur : décide si une action peut démarrer et
## orchestre le timing "déclenchement → impact → effet" pour tout ce qui
## passe par un outil (récolte, minage, etc.).
##
## BUILDING sera ajouté ici quand la construction data-driven sera implémentée
## (voir ROADMAP.md, Jalon 3) — volontairement absent tant qu'il n'y a pas
## de code réel à brancher dessus.
enum State { IDLE, USING_TOOL }

signal state_changed(old_state: State, new_state: State)

@export var tool_controller: ToolController

var _state: State = State.IDLE
var _pending_target: Object
var _pending_impact_callback: Callable

func _ready() -> void:
	tool_controller.swing_impact.connect(_on_swing_impact)

func get_state() -> State:
	return _state

## Démarre un swing d'outil ; on_impact est appelé au signal swing_impact,
## seulement si target est toujours valide à ce moment-là.
func use_tool_on(target: Object, on_impact: Callable) -> bool:
	if _state != State.IDLE:
		return false
	if tool_controller == null or not tool_controller.can_swing():
		return false
	_pending_target = target
	_pending_impact_callback = on_impact
	_set_state(State.USING_TOOL)
	tool_controller.swing()
	return true

func _on_swing_impact() -> void:
	if _state != State.USING_TOOL:
		return
	if _pending_impact_callback.is_valid() and is_instance_valid(_pending_target):
		_pending_impact_callback.call()
	_pending_target = null
	_pending_impact_callback = Callable()
	_set_state(State.IDLE)

func _set_state(new_state: State) -> void:
	var old_state := _state
	_state = new_state
	state_changed.emit(old_state, new_state)
