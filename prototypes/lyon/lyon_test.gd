extends Node3D

## Mise en place du test de carte lyonnaise : pose le joueur sur le sol.
##
## Le point d'apparition est en coordonnées LOCALES du terrain (mètres depuis
## le coin sud-ouest), pas en coordonnées monde : c'est ainsi que la carte est
## décrite, et convertir ici évite d'avoir à retrouver un repère à la main
## chaque fois qu'on change de fenêtre d'extraction.
##
## Par défaut (1800, 1200) : dans la plaine à l'est de la Saône, Fourvière
## à un kilomètre plein ouest. C'est le point de vue qui donne l'échelle.

@export var terrain: LyonTerrain = null
@export var player: Node3D = null
@export var spawn_local: Vector2 = Vector2(1800.0, 1200.0)
@export var spawn_clearance_m: float = 1.5


func _ready() -> void:
	if terrain == null or player == null:
		push_warning("LyonTest : terrain ou joueur non assigné, aucune mise en place.")
		return
	# Le terrain se construit dans son propre _ready() ; on laisse une frame
	# passer pour que sa carte soit chargée avant de lui demander une altitude.
	await get_tree().process_frame
	_place_player()


func _place_player() -> void:
	if terrain.map == null:
		push_warning("LyonTest : la carte n'a pas pu être chargée, joueur laissé en place.")
		return

	var ground: float = terrain.ground_height(spawn_local.x, spawn_local.y)
	var target := terrain.global_position + Vector3(
			spawn_local.x, ground + spawn_clearance_m, spawn_local.y)

	# player.tscn a un Node3D pour racine et un CharacterBody3D dessous :
	# c'est le corps qu'il faut déplacer, déplacer la racine ne suffit pas.
	var body: CharacterBody3D = _find_body(player)
	if body != null:
		body.global_position = target
	else:
		player.global_position = target

	print("[LyonTest] apparition en local (%.0f, %.0f) · sol à %.1f m au-dessus du point bas · %.1f m NGF"
			% [spawn_local.x, spawn_local.y, ground, ground + terrain.map.alt_min])


func _find_body(node: Node) -> CharacterBody3D:
	if node is CharacterBody3D:
		return node as CharacterBody3D
	for child: Node in node.get_children():
		var found: CharacterBody3D = _find_body(child)
		if found != null:
			return found
	return null
