extends Node
class_name UIPanelController

## Arbitre des panneaux ancrés (sac posé, feu de camp, futurs sites de
## transformation). Sibling des autres contrôleurs sous Camera3D.
##
## Il possède ce qui ne peut vivre qu'à un seul endroit :
## - le registre des panneaux ouverts,
## - le mouse mode (visible dès qu'un panneau est ouvert, recapturé à la
##   fermeture du dernier),
## - le gel de la locomotion et de la caméra,
## - la touche de fermeture,
## - l'exclusivité avec les autres modes joueur (construction, swing).
##
## Plusieurs panneaux peuvent être ouverts simultanément — c'est ce qui rend
## possible de glisser un item de son sac posé vers le feu d'à côté. Ce
## n'est pas une exclusivité entre panneaux, c'en est une entre *modes* :
## panneaux ouverts et mode construction s'excluent mutuellement, et c'est
## ici que la question se pose, plus dans un booléen de chaque contrôleur.

## Modes joueur exclusifs qui interdisent l'ouverture d'un panneau tant
## qu'ils tournent. Tout nœud exposant is_active() -> bool convient : le
## mode construction aujourd'hui, la roue de réaction et la sélection de
## pawn demain. L'arbitre ne connaît aucun de ces types — c'est ce qui lui
## permet d'être référencé par eux sans cycle.
@export var exclusive_modes: Array[Node] = []
@export var action_state_machine: ActionStateMachine
## Nœud gelé pendant qu'un panneau est ouvert (doit exposer
## set_input_enabled). Défaut : le propriétaire de la scène joueur.
@export var player: Node

var _open_panels: Array[WorldAnchoredPanel] = []
## Frame de la dernière ouverture. Voir _unhandled_input().
var _opened_frame: int = -1


func _ready() -> void:
	if player == null:
		player = owner


## --- API publique ---------------------------------------------------------

func is_any_panel_open() -> bool:
	return not _open_panels.is_empty()


## Un mode exclusif demande ici s'il peut s'ouvrir, plutôt que d'aller
## tester l'état interne de chaque UI.
func can_enter_exclusive_mode() -> bool:
	return _open_panels.is_empty()


## Ouvre un panneau ancré. Retourne false si un autre mode le refuse.
func open_panel(panel: WorldAnchoredPanel, anchor: Node3D) -> bool:
	if panel == null or anchor == null or panel.is_open():
		return false
	if _is_exclusive_mode_active():
		return false
	if action_state_machine and action_state_machine.get_state() != ActionStateMachine.State.IDLE:
		return false

	var camera := get_parent() as Camera3D
	if camera == null:
		push_warning("UIPanelController doit être enfant direct de la Camera3D")
		return false

	if not panel.closed.is_connected(_on_panel_closed):
		panel.closed.connect(_on_panel_closed.bind(panel))
	panel.open_anchored(anchor, camera)
	_open_panels.append(panel)
	_opened_frame = Engine.get_process_frames()
	_apply_open_state()
	return true


func close_all() -> void:
	# close() retire du registre via le signal : on itère sur une copie.
	for panel in _open_panels.duplicate():
		panel.close()


## --- Interne --------------------------------------------------------------

## L'événement qui vient d'ouvrir un panneau arrive ici juste après, parce
## que _unhandled_input remonte l'arbre du bas vers le haut et que l'ouvreur
## (InteractionController) est plus bas que l'arbitre. Sans cette garde, le
## E d'ouverture referme immédiatement ce qu'il vient d'ouvrir. La garde vit
## ici, et pas chez l'appelant : tout futur ouvreur en hérite.
func _unhandled_input(event: InputEvent) -> void:
	if _open_panels.is_empty() or Engine.get_process_frames() == _opened_frame:
		return
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("interact"):
		close_all()
		get_viewport().set_input_as_handled()


func _is_exclusive_mode_active() -> bool:
	for mode in exclusive_modes:
		if mode and mode.has_method("is_active") and bool(mode.call("is_active")):
			return true
	return false


func _on_panel_closed(panel: WorldAnchoredPanel) -> void:
	_open_panels.erase(panel)
	_apply_open_state()


## Souris et gel du joueur suivent une seule question : reste-t-il un
## panneau ouvert ?
func _apply_open_state() -> void:
	var any_open: bool = not _open_panels.is_empty()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if any_open else Input.MOUSE_MODE_CAPTURED
	if player and player.has_method("set_input_enabled"):
		player.call("set_input_enabled", not any_open)
