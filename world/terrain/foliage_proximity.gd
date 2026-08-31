@tool
class_name FoliageProximity
extends Node
## Coupe la projection d'ombre des chunks de feuillage qui n'en projettent
## aucune d'utile.
##
## Chaque objet de dessin est resoumis une fois par cascade d'ombre : leur
## nombre, et non le nombre de triangles, est le premier facteur de coût avec
## les ombres allumées.
##
## **Le critère n'est pas la distance au spectateur.** Un soleil bas envoie
## l'ombre d'un arbre à des centaines de mètres de son tronc : couper au-delà
## de ce qu'on voit efface les ombres qui tombent sous nos pieds. Ce qui compte
## est l'endroit où l'ombre *atterrit*. On décale donc l'emprise du chunk le
## long du soleil de la longueur d'ombre de sa canopée, et on teste cette
## zone-là contre la portée des cascades.
##
## La portée est lue sur la lumière, pas réglée à côté : deux valeurs à tenir
## de pair finissent toujours par diverger. Le calcul se refait à chaque
## réévaluation, donc un soleil qui tourne reste juste sans rien à ajuster.
##
## Le point de vue est la **caméra courante**, pas le joueur : c'est elle qui
## décide de ce qui est dessiné, et ça vaut pour la freecam comme pour l'éditeur.
##
## Tout se calcule dans le repère du feuillage, parce que c'est celui des
## emprises publiées par le semis. Le nœud de terrain peut être tourné et
## déplacé dans sa scène : comparer une emprise locale à une position globale
## donne des distances qui n'ont aucun sens, sans la moindre erreur.
##
## Ce composant est le point unique où le feuillage réagit à la distance. Les
## deux autres usages prévus — bascule des arbres proches en instances
## abattables, semis et déchargement de la strate sol — s'y brancheront plutôt
## que de refaire un parcours de chunks à côté.

## Longueur d'ombre maximale, en multiples de la portée des cascades. Sans
## borne, un soleil au ras de l'horizon donne une longueur infinie et plus rien
## n'est jamais coupé.
const _MAX_SHADOW_LENGTH_RATIO := 6.0

## Un chunk de feuillage : son emprise au sol et ses objets de dessin.
class Chunk:
	var area: Rect2
	var meshes: Array[MultiMeshInstance3D] = []
	var casting := true

## Intervalle entre deux réévaluations, en secondes. Un chunk fait 96 m de côté :
## personne n'en traverse un en un quart de seconde.
@export var update_interval: float = 0.25

var _chunks: Array[Chunk] = []
## Repère dans lequel les emprises sont exprimées.
var _space: Node3D
var _sun: DirectionalLight3D
var _canopy_height: float = 0.0
var _countdown: float = 0.0


## Recense les chunks d'un nœud de feuillage. Les enfants sans emprise déclarée
## sont ignorés — ce composant en fait partie une fois parenté.
func setup(foliage_root: Node3D, sun: DirectionalLight3D, canopy_height: float) -> void:
	_chunks.clear()
	_space = foliage_root
	_sun = sun
	_canopy_height = canopy_height
	for node in foliage_root.get_children():
		var chunk := _read_chunk(node)
		if chunk != null:
			_chunks.append(chunk)
	_countdown = 0.0
	if _sun == null:
		push_warning("FoliageProximity : aucun soleil fourni — tous les chunks gardent leur ombre.")
	set_process(_sun != null and not _chunks.is_empty())


## L'emprise est lue sur la métadonnée posée par le semis, seul à connaître la
## grille de chunks. Ni le nom du nœud ni la boîte englobante ne sont une
## seconde source de vérité : le premier se périme au renommage, la seconde
## n'est pas encore calculée à la sortie du semis.
func _read_chunk(node: Node) -> Chunk:
	if not node.has_meta(FoliageScatter.CHUNK_AREA_META):
		return null
	var chunk := Chunk.new()
	# Conversion explicite : un Variant rangé dans un champ typé fait abandonner
	# le générateur de bytecode.
	chunk.area = Rect2(node.get_meta(FoliageScatter.CHUNK_AREA_META))
	for child in node.get_children():
		var mesh := child as MultiMeshInstance3D
		if mesh != null:
			chunk.meshes.append(mesh)
	return null if chunk.meshes.is_empty() else chunk


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
	var reach := _sun.directional_shadow_max_distance
	var drift := _shadow_drift(reach)

	for chunk in _chunks:
		# L'ombre balaie du pied de l'arbre jusqu'à son extrémité : on teste
		# l'emprise et sa translatée réunies. L'union déborde un peu du vrai
		# balayage en diagonale, et c'est le bon sens d'erreur — garder une
		# ombre de trop ne se voit pas, en perdre une se voit.
		var landing := chunk.area.merge(Rect2(chunk.area.position + drift, chunk.area.size))
		var casting := _distance_to(landing, eye) <= reach
		if casting == chunk.casting:
			continue
		chunk.casting = casting
		var mode := GeometryInstance3D.SHADOW_CASTING_SETTING_ON if casting \
				else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		for mesh in chunk.meshes:
			mesh.cast_shadow = mode


## Décalage horizontal entre un arbre et le bout de son ombre. C'est la hauteur
## de canopée divisée par la tangente de l'élévation du soleil : plus il est
## bas, plus l'ombre part loin, et c'est exactement ce qui rendait faux un
## critère fondé sur la distance au spectateur.
func _shadow_drift(reach: float) -> Vector2:
	var ray := (_space.global_basis.orthonormalized().inverse() * -_sun.global_basis.z).normalized()
	var flat := Vector2(ray.x, ray.z)
	if flat.length() < 0.001:
		return Vector2.ZERO  # soleil au zénith : l'ombre reste sous l'arbre
	var descent := maxf(-ray.y, 0.001)
	var length := minf(_canopy_height * flat.length() / descent, reach * _MAX_SHADOW_LENGTH_RATIO)
	return flat.normalized() * length


## Distance d'un point au bord d'un rectangle, nulle à l'intérieur. Mesurer
## depuis le centre ferait varier le rayon effectif d'une demi-diagonale de
## chunk — soixante-dix mètres, plus que la marge qu'on règle.
func _distance_to(area: Rect2, point: Vector2) -> float:
	var gap := Vector2(
		maxf(maxf(area.position.x - point.x, 0.0), point.x - area.end.x),
		maxf(maxf(area.position.y - point.y, 0.0), point.y - area.end.y))
	return gap.length()
