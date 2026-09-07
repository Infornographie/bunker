@tool
class_name BlockoutHeightmap
extends RefCounted
## Carte de travail **déclarée** : une plaine, une colline, une rivière, des
## clairières. Rien n'est tiré au hasard.
##
## Elle occupe la place qu'avait le générateur procédural et publie exactement le
## même contrat — `heights`, `water_level`, `clearings`, `river_path`,
## `massif_influence`, `cave_position`/`cave_forward`. C'est ce qui permet au
## semis, aux biomes, au mesh et au shader de sol de continuer à fonctionner sans
## qu'une ligne ne change chez eux : ils n'ont jamais connu que ce contrat.
##
## **Pourquoi une carte déclarée.** Le cœur du jeu est le comportement des pawns,
## et il se valide sur un terrain dont on connaît la forme par cœur : une plaine
## pour marcher, une pente pour buter, un cours d'eau pour contourner, un gué
## pour passer. Une carte tirée à la graine rend chaque test différent du
## précédent — c'est l'inverse de ce qu'on veut pendant qu'on met au point une IA.
## La vraie carte sera dessinée à la main plus tard ; celle-ci est un décor de
## répétition, et elle assume de se lire d'un coup d'œil dans l'inspecteur.

## Hauteurs par sommet, indexées par `TerrainGenConfig.height_index()`.
var heights: PackedFloat32Array

## Position et orientation du site du bunker. Toujours l'origine du monde, comme
## dans le générateur précédent : c'est le repère auquel tout le reste se situe.
var cave_position: Vector3
var cave_forward: Vector3

## Altitude du plan d'eau. Déclarée, pas déduite d'un fond de vallée.
var water_level: float

## Replats publiés pour le semis, en (x, z, rayon). La clairière du bunker est
## toujours la première.
##
## Reste un `PackedVector3Array` et non un tableau de `ClearingDef` : le semis
## le parcourt dans ses boucles chaudes, et une géométrie compacte s'y lit sans
## déréférencer un objet par candidat.
var clearings: PackedVector3Array
## Identité de chaque replat, **indexée comme `clearings`**. Lue seulement une
## fois qu'un candidat est déjà tombé dans une clairière — donc jamais dans la
## boucle chaude.
var clearing_tags: Array[StringName] = []

## Tracé de la rivière, tel que déclaré dans la config.
var river_path: PackedVector2Array

## Influence du relief par sommet, 0 en plaine et 1 au sommet de la colline.
## Les biomes ne lisent que ça — ils continuent donc de marcher à l'identique,
## avec la colline dans le rôle qu'avait le massif.
var massif_influence: PackedFloat32Array

var _cfg: TerrainGenConfig
var _n: int
var _ops: HeightmapOps


func generate(cfg: TerrainGenConfig) -> void:
	_cfg = cfg
	_n = cfg.grid_size()
	water_level = cfg.water_level
	river_path = cfg.river_points

	# Le relief de départ passe par le constructeur : `HeightmapOps` possède son
	# tableau et rien ne l'écrit du dehors (copie sur écriture).
	_ops = HeightmapOps.new(cfg, _build_relief())

	_flatten_clearings()
	_carve_river()

	heights = _ops.heights
	_compute_influence()
	_place_cave()


## Plaine à l'altitude zéro, plus une colline. Le profil est en cosinus adouci :
## pente nulle au sommet et au pied, maximale à mi-versant — une pente
## constante donnerait un cône, dont le pied fait une arête que la navigation
## traverse mal.
func _build_relief() -> PackedFloat32Array:
	var relief := PackedFloat32Array()
	relief.resize(_n * _n)

	for iz in _n:
		for ix in _n:
			relief[_cfg.height_index(ix, iz)] = _cfg.hill_height * _hill_profile(_cfg.world_pos(ix, iz))

	return relief


## 1 au centre de la colline, 0 au-delà de son rayon.
func _hill_profile(point: Vector2) -> float:
	var dist := point.distance_to(_cfg.hill_centre)
	return 1.0 - smoothstep(0.0, _cfg.hill_radius, dist)


## La clairière du bunker en premier, puis celles déclarées. Toutes sont aplanies
## et toutes sont publiées : le semis lit la même liste pour ne pas y planter
## d'arbres.
func _flatten_clearings() -> void:
	clearings = PackedVector3Array()
	clearing_tags = []
	clearings.append(Vector3(0.0, 0.0, _cfg.bunker_radius))
	clearing_tags.append(&"bunker")
	_ops.flatten_disc(Vector2.ZERO, _cfg.bunker_radius, _cfg.bunker_falloff,
			_cfg.bunker_max_delta, 1.0)

	for spot in _cfg.clearings:
		if spot == null:
			continue
		clearings.append(Vector3(spot.position.x, spot.position.y, spot.radius))
		clearing_tags.append(spot.tag)
		_ops.flatten_disc(spot.position, spot.radius, _cfg.clearing_falloff,
				_cfg.clearing_max_delta, _cfg.clearing_flatten_strength)


## La rivière se creuse d'un bout à l'autre, puis le gué la remonte. C'est ce qui
## fait d'elle une contrainte de topologie avec **un** point de passage : le pawn
## qui veut l'autre rive doit y aller.
##
## Le gué est un haut-fond, pas un trou dans le lit : l'eau continue de couler
## par-dessus, seulement assez basse pour qu'on la traverse. Interrompre le
## creusement laisserait une langue de terre sèche en travers du cours — un pont
## naturel, ce qui n'est pas la même chose et ne se lit pas comme un passage.
func _carve_river() -> void:
	if river_path.size() < 2:
		return

	var line := PackedFloat32Array()
	line.resize(river_path.size())
	line.fill(water_level)
	_ops.carve_channel(river_path, line, _cfg.river_width, _cfg.river_bank, _cfg.river_depth)

	if _cfg.river_ford_radius > 0.0:
		_ops.lift_disc(_cfg.river_ford, _cfg.river_ford_radius, _cfg.river_ford_falloff,
				water_level - _cfg.river_ford_depth)


## Même profil que la colline, et c'est volontaire : l'influence dit « à quelle
## hauteur du relief on est », pas « à quelle altitude ». Une altitude serait
## fausse dès qu'un replat ou une berge déplacerait le sol.
func _compute_influence() -> void:
	massif_influence = PackedFloat32Array()
	massif_influence.resize(_n * _n)

	for iz in _n:
		for ix in _n:
			massif_influence[_cfg.height_index(ix, iz)] = _hill_profile(_cfg.world_pos(ix, iz))


## Le porche s'ouvre à l'origine et regarde à l'opposé de la colline.
func _place_cave() -> void:
	cave_position = Vector3(0.0, _cfg.sample_height(heights, Vector2.ZERO), 0.0)

	var away := -_cfg.hill_centre
	if away.length_squared() < 1e-6:
		away = Vector2(0.0, 1.0)
	away = away.normalized()
	cave_forward = Vector3(away.x, 0.0, away.y)
