extends Node
class_name UIPanelController

## Arbitre des panneaux du monde (sac posé, feu de camp, futurs sites de
## transformation). Sibling des autres contrôleurs sous Camera3D.
##
## Depuis le passage au réticule-pointeur, il ne touche plus ni à la souris
## ni à la locomotion : le joueur garde le contrôle pendant qu'un panneau
## est ouvert, et les cases se manient comme n'importe quel Interactable.
## Il lui reste ce qui ne peut vivre qu'à un seul endroit :
## - le registre des panneaux ouverts,
## - la touche de fermeture,
## - l'exclusivité avec les autres modes joueur.
##
## Plusieurs panneaux peuvent être ouverts simultanément — c'est
## l'exclusivité entre *modes*, pas entre panneaux.

## Modes joueur exclusifs qui interdisent l'ouverture d'un panneau tant
## qu'ils tournent. Tout nœud exposant is_active() -> bool convient : le
## mode construction aujourd'hui, la roue de réaction et la sélection de
## pawn demain. L'arbitre ne connaît aucun de ces types — c'est ce qui lui
## permet d'être référencé par eux sans cycle.
@export var exclusive_modes: Array[Node] = []
@export var action_state_machine: ActionStateMachine
@export var interaction_controller: InteractionController

var _open_panels: Array[WorldPanel] = []


## --- API publique ---------------------------------------------------------

func is_any_panel_open() -> bool:
	return not _open_panels.is_empty()


## Un mode exclusif demande ici s'il peut s'ouvrir, plutôt que d'aller
## tester l'état interne de chaque panneau.
func can_enter_exclusive_mode() -> bool:
	return _open_panels.is_empty()


## Adopte un panneau fraîchement instancié et branché, l'attache à son ancre
## et l'ouvre. Retourne false si un autre mode le refuse — l'appelant est
## alors responsable de libérer l'instance.
func open_panel(panel: WorldPanel, anchor: Node3D) -> bool:
	if panel == null or anchor == null:
		return false
	if _is_exclusive_mode_active():
		return false
	if action_state_machine and action_state_machine.get_state() != ActionStateMachine.State.IDLE:
		return false

	var camera := get_parent() as Camera3D
	if camera == null:
		push_warning("UIPanelController doit être enfant direct de la Camera3D")
		return false

	panel.closed.connect(_on_panel_closed.bind(panel))
	# À la racine de la scène, pas sous l'ancre : voir WorldPanel._follow_anchor().
	get_tree().current_scene.add_child(panel)
	panel.open_anchored(anchor, camera, interaction_controller)
	_open_panels.append(panel)
	return true


func has_panel_for(anchor: Node3D) -> bool:
	for panel in _open_panels:
		if panel.get_anchor_node() == anchor:
			return true
	return false


func close_panel_for(anchor: Node3D) -> void:
	for panel in _open_panels.duplicate():
		if panel.get_anchor_node() == anchor:
			panel.close()


func close_all() -> void:
	# close() retire du registre via le signal : on itère sur une copie.
	for panel in _open_panels.duplicate():
		panel.close()


## --- Interne --------------------------------------------------------------

## Seul ui_cancel ferme : E est devenu le verbe de manipulation des cases,
## il ne peut plus servir à refermer ce sur quoi on travaille.
func _unhandled_input(event: InputEvent) -> void:
	if _open_panels.is_empty():
		return
	if event.is_action_pressed("ui_cancel"):
		close_all()
		get_viewport().set_input_as_handled()


func _is_exclusive_mode_active() -> bool:
	for mode in exclusive_modes:
		if mode and mode.has_method("is_active") and bool(mode.call("is_active")):
			return true
	return false


func _on_panel_closed(panel: WorldPanel) -> void:
	_open_panels.erase(panel)
