@tool
class_name FoliageProximity
extends Node
## Fait réagir le feuillage à la distance du point de vue : couper les ombres
## inutiles, et semer les strates streamées autour du joueur.
##
## Deux responsabilités, deux grains, deux listes — les confondre est ce qui a
## produit les gels décrits plus bas. L'ombre se décide par **chunk** de terrain
## parce qu'elle porte sur ce qui y est dessiné en permanence ; le semis se fait
## par **tuile**, bien plus petite, parce que son coût doit tenir dans une frame.
##
## **Les ombres.** Chaque objet de dessin est resoumis une fois par cascade
## d'ombre : leur nombre, et non le nombre de triangles, est le premier facteur
## de coût avec les ombres allumées. Mais le critère n'est pas la distance au
## spectateur : un soleil bas envoie l'ombre d'un arbre à des centaines de
## mètres de son tronc, et couper au-delà de ce qu'on voit efface les ombres qui
## tombent sous nos pieds. Ce qui compte est l'endroit où l'ombre *atterrit*. On
## décale donc l'emprise du chunk le long du soleil de la longueur d'ombre de sa
## canopée, et on teste cette zone-là contre la portée des cascades — lue sur la
## lumière, pas réglée à côté : deux valeurs à tenir de pair finissent toujours
## par diverger, et celle-ci reste juste toute seule au cycle jour/nuit.
##
## **Le streaming.** Une strate au sol tient des centaines de milliers
## d'instances sur la carte entière ; elle n'existe qu'à portée de vue. Les
## tuiles entrent et sortent du rayon, leur végétation basse est semée puis
## libérée.
##
## Deux grains distincts, et c'est délibéré : le chunk de terrain porte le
## culling et les ombres, la **tuile** porte le semis. Un semis coûte comme le
## carré de son côté, et c'est lui qui doit tenir dans une frame — au grain du
## chunk, une tuile de sol tenait seize mille candidats et gelait 400 ms.
##
## **Le budget est en millisecondes, pas en tuiles.** Compté en tuiles, il
## redevient faux dès qu'on change leur taille, l'espacement d'une strate ou de
## machine — c'est exactement comme ça qu'on est arrivé à des gels de 800 ms
## avec un garde-fou en place. Les tuiles à semer entrent dans une file triée
## par distance, consommée à chaque frame tant que le budget n'est pas dépassé :
## l'herbe pousse du plus proche au plus lointain au lieu d'arriver d'un bloc.
##
## Le point de vue est la **caméra courante**, pas le joueur : c'est elle qui
## décide de ce qui est dessiné, et ça vaut pour la freecam comme pour l'éditeur.
##
## Tout se calcule dans le repère du feuillage, celui des emprises publiées par
## la configuration. Le nœud de terrain peut être tourné et déplacé dans sa
## scène : comparer une emprise locale à une position globale donne des
## distances qui n'ont aucun sens, sans la moindre erreur.

## Longueur d'ombre maximale, en multiples de la portée des cascades. Sans
## borne, un soleil au ras de l'horizon donne une longueur infinie et plus rien
## n'est jamais coupé.
const _MAX_SHADOW_LENGTH_RATIO := 6.0

## Un chunk : son emprise au sol et ce qu'il dessine en permanence.
class Chunk:
	var area: Rect2
	var meshes: Array[MultiMeshInstance3D] = []
	var casting := true

## Intervalle entre deux recensements, en secondes. Le recensement dit *quelles*
## tuiles doivent exister ; il ne sème rien, donc il peut être espacé.
@export var update_interval: float = 0.25
## Temps accordé au semis à chaque frame, en millisecondes. C'est le seul
## garde-fou, et il est exprimé dans l'unité du problème : une frame à 60 Hz
## dure 16,7 ms, en prendre 4 se voit à peine et laisse de la marge au reste.
@export_range(0.5, 16.0, 0.5) var stream_budget_ms: float = 4.0

var _chunks: Array[Chunk] = []
var _scatter: FoliageScatter
var _space: Node3D
var _sun: DirectionalLight3D
var _cfg: TerrainGenConfig
var _canopy_height: float = 0.0
var _stream_distance: float = 0.0
var _countdown: float = 0.0
## Tuiles semées, par coordonnées de tuile.
var _tiles: Dictionary = {}
## Tuiles recensées mais pas encore semées, les plus proches en fin de liste :
## on dépile par la fin, ce qui évite de décaler le tableau à chaque semis.
var _pending: Array[Vector2i] = []


## Recense les chunks produits par un semis et prend la main dessus.
func setup(scatter: FoliageScatter, cfg: TerrainGenConfig, space: Node3D, sun: DirectionalLight3D) -> void:
	_chunks.clear()
	_tiles.clear()
	_pending.clear()
	_scatter = scatter
	_space = space
	_sun = sun
	_cfg = cfg
	_canopy_height = cfg.canopy_height
	_stream_distance = cfg.stream_distance
	for cell: Vector2i in scatter.chunk_nodes:
		var chunk := Chunk.new()
		chunk.area = cfg.chunk_area(cell.x, cell.y)
		# Conversion explicite : un Variant rangé dans un champ typé fait
		# abandonner le générateur de bytecode.
		var node := scatter.chunk_nodes[cell] as Node3D
		for child in node.get_children():
			var mesh := child as MultiMeshInstance3D
			if mesh != null:
				chunk.meshes.append(mesh)
		_chunks.append(chunk)
	_countdown = 0.0
	if _sun == null:
		push_warning("FoliageProximity : aucun soleil fourni — tous les chunks gardent leur ombre.")
	set_process(true)


func _process(delta: float) -> void:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	var seen := _space.to_local(camera.global_position)
	var eye := Vector2(seen.x, seen.z)

	# Le recensement est périodique, le semis est continu. Les séparer est ce
	# qui permet d'espacer le premier (il parcourt des listes) sans retarder le
	# second (il doit remplir chaque frame le temps qu'on lui accorde).
	_countdown -= delta
	if _countdown <= 0.0:
		_countdown = update_interval
		_update_shadows(eye)
		_survey_tiles(eye)
	_consume_pending()


# --- Ombres --------------------------------------------------------------------

func _update_shadows(eye: Vector2) -> void:
	if _sun == null:
		return
	var reach := _sun.directional_shadow_max_distance
	var drift := _shadow_drift(reach)
	for chunk in _chunks:
		if chunk.meshes.is_empty():
			continue
		# L'ombre balaie du pied de l'arbre jusqu'à son extrémité : on teste
		# l'emprise et sa translatée réunies. L'union déborde un peu du vrai
		# balayage en diagonale, et c'est le bon sens d'erreur — garder une
		# ombre de trop ne se voit pas, en perdre une se voit. La zone est
		# élargie d'une hauteur de canopée parce que la longueur d'ombre est
		# estimée sur une hauteur *moyenne*, et qu'un chunk qui bascule pile à
		# la limite fait clignoter son ombre quand le joueur marche.
		var landing := chunk.area.merge(Rect2(chunk.area.position + drift, chunk.area.size)) \
				.grow(_canopy_height)
		var casting := _distance_to(landing, eye) <= reach
		if casting == chunk.casting:
			continue
		chunk.casting = casting
		var mode := GeometryInstance3D.SHADOW_CASTING_SETTING_ON if casting \
				else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		for mesh in chunk.meshes:
			mesh.cast_shadow = mode


## Décalage horizontal entre un arbre et le bout de son ombre : la hauteur de
## canopée divisée par la tangente de l'élévation du soleil. Plus il est bas,
## plus l'ombre part loin, et c'est exactement ce qui rendait faux un critère
## fondé sur la distance au spectateur.
func _shadow_drift(reach: float) -> Vector2:
	var ray := (_space.global_basis.orthonormalized().inverse() * -_sun.global_basis.z).normalized()
	var flat := Vector2(ray.x, ray.z)
	if flat.length() < 0.001:
		return Vector2.ZERO  # soleil au zénith : l'ombre reste sous l'arbre
	var descent := maxf(-ray.y, 0.001)
	var length := minf(_canopy_height * flat.length() / descent, reach * _MAX_SHADOW_LENGTH_RATIO)
	return flat.normalized() * length


# --- Strates streamées ---------------------------------------------------------

## Recense les tuiles qui doivent exister, libère celles qui sortent, et met en
## file celles qui manquent — sans en semer aucune.
##
## Seule la fenêtre de tuiles autour du point de vue est parcourue, pas la carte
## entière : à 24 m de côté, celle-ci en compte deux mille cinq cents pour une
## cinquantaine à portée. Balayer la liste complète chaque fois coûterait plus
## cher que ce qu'on cherche à économiser.
func _survey_tiles(eye: Vector2) -> void:
	if _stream_distance <= 0.0:
		return
	var span := _cfg.stream_tile_cells * _cfg.cell_size
	var half := _cfg.half_size()
	var last := _cfg.stream_tiles_per_side() - 1
	var x0 := clampi(int(floor((eye.x - _stream_distance + half) / span)), 0, last)
	var z0 := clampi(int(floor((eye.y - _stream_distance + half) / span)), 0, last)
	var x1 := clampi(int(floor((eye.x + _stream_distance + half) / span)), 0, last)
	var z1 := clampi(int(floor((eye.y + _stream_distance + half) / span)), 0, last)

	_pending.clear()
	var wanted := {}
	for tz in range(z0, z1 + 1):
		for tx in range(x0, x1 + 1):
			if _distance_to(_cfg.stream_tile_area(tx, tz), eye) > _stream_distance:
				continue
			var cell := Vector2i(tx, tz)
			wanted[cell] = true
			if not _tiles.has(cell):
				_pending.append(cell)

	# Libérer est immédiat et sans coût : seul le semis a un budget.
	for cell: Vector2i in _tiles.keys():
		if not wanted.has(cell):
			(_tiles[cell] as Node3D).queue_free()
			_tiles.erase(cell)

	# Le plus proche en dernier : `_consume_pending()` dépile par la fin, donc
	# l'herbe pousse sous les pieds du joueur avant de pousser au loin. Le tri se
	# fait ici et pas à chaque frame — la file ne change qu'au recensement.
	_pending.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return _distance_to(_cfg.stream_tile_area(a.x, a.y), eye) \
				> _distance_to(_cfg.stream_tile_area(b.x, b.y), eye))


## Sème les tuiles en attente tant que le budget de la frame le permet.
##
## Le budget se teste **après** chaque semis : une tuile ne s'interrompt pas en
## cours de route, donc le dépassement vaut au plus une tuile. C'est la vraie
## raison pour laquelle les tuiles doivent rester petites — la borne du pic
## n'est pas le budget, c'est le budget plus une tuile.
func _consume_pending() -> void:
	if _pending.is_empty():
		return
	var deadline := Time.get_ticks_usec() + int(stream_budget_ms * 1000.0)
	while not _pending.is_empty():
		var cell: Vector2i = _pending.pop_back()
		var node := _scatter.stream_tile(cell.x, cell.y)
		_space.add_child(node)
		_tiles[cell] = node
		if Time.get_ticks_usec() >= deadline:
			return


# --- Géométrie -----------------------------------------------------------------

## Distance d'un point au bord d'un rectangle, nulle à l'intérieur. Mesurer
## depuis le centre ferait varier le rayon effectif d'une demi-diagonale de
## chunk — soixante-dix mètres, plus que la marge qu'on règle.
func _distance_to(area: Rect2, point: Vector2) -> float:
	var gap := Vector2(
		maxf(maxf(area.position.x - point.x, 0.0), point.x - area.end.x),
		maxf(maxf(area.position.y - point.y, 0.0), point.y - area.end.y))
	return gap.length()
