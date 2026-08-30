extends Node3D
class_name WorldPanel

## Base des panneaux posés dans le monde : un petit tableau flottant devant
## l'objet qu'il concerne, pivotant sur l'axe vertical pour rester face au
## joueur.
##
## Il ne gère ni souris ni gel : le pointeur est le réticule, le joueur
## continue de bouger. Ses cases sont des Interactable ordinaires, donc tout
## le maniement (viser, prendre, poser) passe par InteractionController.
##
## Un panneau est instancié à l'ouverture, enfant de son ancre, et détruit à
## la fermeture. Pas d'exemplaire unique rebranché d'un objet à l'autre :
## chaque feu, chaque sac ouvre le sien, avec les cases qui lui vont.
##
## Les classes filles surchargent _build_content(), refresh(), et les quatre
## méthodes du contrat de case.

signal closed

## Distance au-delà de laquelle le panneau se referme tout seul. Plus large
## qu'un menu ancré à l'écran : on peut s'écarter un peu sans le perdre.
@export var close_distance: float = 3.5
## Position du panneau par rapport à son ancre.
@export var anchor_offset: Vector3 = Vector3(0.0, 0.9, 0.0)
## Couche de collision des cases : vue par le raycast d'interaction, exclue
## des masques du joueur et du mode construction.
@export_flags_3d_physics var slot_layer: int = 16
## Taille d'une case en mètres. Le critère de réglage : viser une case au
## réticule ne doit demander aucun micro-ajustement.
@export var slot_size: float = 0.22
@export var slot_gap: float = 0.05

const SLOT_SCENE: PackedScene = preload("res://entities/interactable/panel/panel_slot.tscn")

var _anchor: Node3D
var _camera: Camera3D
## Contrôleur du joueur qui a ouvert le panneau — sert aux classes filles à
## notifier l'équipement, pas à viser quoi que ce soit.
var _interactor: InteractionController


## Appelé par UIPanelController uniquement.
func open_anchored(anchor: Node3D, camera: Camera3D, interactor: InteractionController) -> void:
	_anchor = anchor
	_camera = camera
	_interactor = interactor
	_follow_anchor()
	_build_content()
	refresh()
	_face_player()
	set_process(true)


## Nommée ainsi et pas get_anchor() : Node3D hérite de méthodes natives, et
## un homonyme se transforme en surcharge accidentelle.
func get_anchor_node() -> Node3D:
	return _anchor


func close() -> void:
	closed.emit()
	queue_free()


func _process(_delta: float) -> void:
	if _anchor == null or not is_instance_valid(_anchor) or _camera == null:
		close()
		return
	if _camera.global_position.distance_to(global_position) > close_distance:
		close()
		return
	_follow_anchor()
	_face_player()


## Le panneau vit à la racine de la scène et suit son ancre, plutôt que
## d'être son enfant : les assets du projet ont des échelles arbitraires
## (le feu de camp est à 0,005), et un panneau enfant les hériterait — il
## naîtrait deux cents fois trop petit sans que sa taille en mètres y soit
## pour quoi que ce soit.
func _follow_anchor() -> void:
	global_position = _anchor.global_position + anchor_offset


## Pivot sur le seul axe vertical : le panneau se tourne vers le joueur mais
## ne se couche jamais quand on regarde le ciel ou ses pieds. Il reste un
## objet posé dans la scène, pas un autocollant sur la caméra.
func _face_player() -> void:
	var to_player := _camera.global_position - global_position
	to_player.y = 0.0
	if to_player.length_squared() < 0.0001:
		return
	# La face avant d'un QuadMesh est +Z, et look_at() oriente -Z : on vise
	# donc à l'opposé du joueur pour lui présenter l'endroit.
	look_at(global_position - to_player, Vector3.UP)


## --- Construction des cases ----------------------------------------------

func make_slot(payload: Variant) -> PanelSlot:
	var slot := SLOT_SCENE.instantiate() as PanelSlot
	add_child(slot)
	slot.setup(payload, slot_size, self, slot_layer)
	return slot


## Pas de X/Y en mètres à calculer à la main dans les classes filles : une
## position de grille en cases donne la position locale, gouttière comprise.
func grid_position(col: float, row: float) -> Vector3:
	var step: float = slot_size + slot_gap
	return Vector3(col * step, -row * step, 0.0)


## --- Surcharges ------------------------------------------------------------

func _build_content() -> void:
	pass


func refresh() -> void:
	pass


## --- Contrat de case (voir PanelSlot) -------------------------------------

func slot_content(_slot: PanelSlot) -> ResourceDef:
	return null


func slot_accepts(_slot: PanelSlot, _resource: ResourceDef) -> bool:
	return false


## Toutes les cases pleines ne se vident pas : ce qui est posé sur les
## braises n'en ressort plus.
func slot_can_take(slot: PanelSlot) -> bool:
	return slot_content(slot) != null


func slot_take(_slot: PanelSlot) -> ResourceDef:
	return null


func slot_put(_slot: PanelSlot, _resource: ResourceDef) -> bool:
	return false


## Case-action plutôt que case-conteneur : chaîne vide pour un conteneur,
## clé de prompt pour une action (choisir une recette, par exemple).
func slot_action_key(_slot: PanelSlot) -> String:
	return ""


func slot_activate(_slot: PanelSlot) -> void:
	pass
