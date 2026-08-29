extends Control
class_name WorldAnchoredPanel

## Base des panneaux ancrés sur un objet du monde : le panneau suit la
## projection écran de sa cible plutôt que d'être centré comme un menu. On
## reste accroupi devant son sac ou son feu, on n'entre pas dans une
## interface.
##
## Le panneau ne sait faire que ça : s'ancrer, se construire une fois, se
## rafraîchir, se fermer quand la cible s'éloigne, disparaît ou passe
## derrière la caméra. Il ne touche NI au mouse mode, NI au gel du joueur,
## NI à l'exclusivité avec les autres modes : tout ça appartient à
## UIPanelController, qui est le seul à ouvrir un panneau.
##
## Les classes filles surchargent _build_content() (une fois, à la première
## ouverture) et refresh().

signal closed

## Distance au-delà de laquelle le panneau se referme tout seul.
@export var close_distance: float = 2.5

var _anchor_node: Node3D
var _camera: Camera3D
var _built: bool = false


func _ready() -> void:
	set_process(false)
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## Appelé par UIPanelController uniquement.
func open_anchored(anchor: Node3D, camera: Camera3D) -> void:
	_anchor_node = anchor
	_camera = camera
	if not _built:
		_build_content()
		_built = true
	refresh()
	visible = true
	set_process(true)


func close() -> void:
	if not visible:
		return
	visible = false
	set_process(false)
	_anchor_node = null
	closed.emit()


func is_open() -> bool:
	return visible


func get_anchor_node() -> Node3D:
	return _anchor_node


func _process(_delta: float) -> void:
	if _anchor_node == null or not is_instance_valid(_anchor_node) or _camera == null:
		close()
		return
	if _camera.global_position.distance_to(_anchor_node.global_position) > close_distance:
		close()
		return
	# La cible est passée derrière la caméra : plus rien à ancrer.
	if _camera.is_position_behind(_anchor_node.global_position):
		close()
		return
	position = _camera.unproject_position(_anchor_node.global_position) \
		- size * 0.5 + anchor_screen_offset()


## Décalage écran par rapport au centre de la cible. Surchargeable quand le
## mesh de l'objet gêne (le sac, dont la poche basse retombait dessus).
func anchor_screen_offset() -> Vector2:
	return Vector2.ZERO


## Construction des enfants, une seule fois à la première ouverture.
func _build_content() -> void:
	pass


## Resynchronise l'affichage sur les données. Appelée à l'ouverture et à
## chaque modification.
func refresh() -> void:
	pass
