@tool
class_name FoliageProximity
extends Node
## Fait réagir le feuillage à la distance du point de vue. Deux usages, un seul
## parcours de chunks : couper les ombres inutiles, et semer les strates
## streamées autour du joueur.
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
## chunks entrent et sortent du rayon, leur végétation basse est semée puis
## libérée. Le semis d'un chunk coûte quelques millisecondes, donc on en fait un
## nombre borné par réévaluation : un joueur qui court ne doit pas provoquer un
## à-coup, quitte à ce que l'herbe apparaisse une fraction de seconde plus tard,
## loin devant lui.
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

## Un chunk : son emprise au sol, ce qu'il dessine en permanence, et ce qui y
## pousse tant que le joueur est à portée.
class Chunk:
	var cell: Vector2i
	var area: Rect2
	var node: Node3D
	var meshes: Array[MultiMeshInstance3D] = []
	var casting := true
	var streamed: Node3D

## Intervalle entre deux réévaluations, en secondes. Un chunk fait 96 m de côté :
## personne n'en traverse un en un quart de seconde.
@export var update_interval: float = 0.25
## Chunks semés au plus par réévaluation. C'est ce qui étale le coût du semis
## plutôt que de le prendre d'un bloc au moment où le joueur franchit une limite.
@export_range(1, 16) var stream_budget: int = 2

var _chunks: Array[Chunk] = []
var _scatter: FoliageScatter
var _space: Node3D
var _sun: DirectionalLight3D
var _canopy_height: float = 0.0
var _stream_distance: float = 0.0
var _countdown: float = 0.0


## Recense les chunks produits par un semis et prend la main dessus.
func setup(scatter: FoliageScatter, cfg: TerrainGenConfig, space: Node3D, sun: DirectionalLight3D) -> void:
	_chunks.clear()
	_scatter = scatter
	_space = space
	_sun = sun
	_canopy_height = cfg.canopy_height
	_stream_distance = cfg.stream_distance
	for cell: Vector2i in scatter.chunk_nodes:
		var chunk := Chunk.new()
		chunk.cell = cell
		chunk.area = cfg.chunk_area(cell.x, cell.y)
		# Conversion explicite : un Variant rangé dans un champ typé fait
		# abandonner le générateur de bytecode.
		chunk.node = scatter.chunk_nodes[cell] as Node3D
		for child in chunk.node.get_children():
			var mesh := child as MultiMeshInstance3D
			if mesh != null:
				chunk.meshes.append(mesh)
		_chunks.append(chunk)
	_countdown = 0.0
	if _sun == null:
		push_warning("FoliageProximity : aucun soleil fourni — tous les chunks gardent leur ombre.")
	set_process(not _chunks.is_empty())


func _process(delta: float) -> void:
	_countdown -= delta
	if _countdown > 0.0:
		return
	_countdown = update_interval

	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	var seen := _space.to_local(camera.global_position)
	var eye := Vector2(seen.x, seen.z)

	_update_shadows(eye)
	_update_streaming(eye)


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

func _update_streaming(eye: Vector2) -> void:
	if _stream_distance <= 0.0:
		return
	var budget := stream_budget
	for chunk in _chunks:
		var wanted := _distance_to(chunk.area, eye) <= _stream_distance
		if wanted == (chunk.streamed != null):
			continue
		if not wanted:
			# Libérer est immédiat et sans coût : seul le semis a un budget.
			chunk.streamed.queue_free()
			chunk.streamed = null
			continue
		if budget <= 0:
			continue
		budget -= 1
		chunk.streamed = _scatter.stream_chunk(chunk.cell.x, chunk.cell.y)
		chunk.node.add_child(chunk.streamed)


# --- Géométrie -----------------------------------------------------------------

## Distance d'un point au bord d'un rectangle, nulle à l'intérieur. Mesurer
## depuis le centre ferait varier le rayon effectif d'une demi-diagonale de
## chunk — soixante-dix mètres, plus que la marge qu'on règle.
func _distance_to(area: Rect2, point: Vector2) -> float:
	var gap := Vector2(
		maxf(maxf(area.position.x - point.x, 0.0), point.x - area.end.x),
		maxf(maxf(area.position.y - point.y, 0.0), point.y - area.end.y))
	return gap.length()
