@tool
class_name HeightmapGenerator
extends RefCounted
## Produit le tableau de hauteurs de la zone, et la bouche de grotte qui en découle.
##
## Ordre de génération, et il compte :
##   1. tirage du massif à la graine (orientation, longueur, largeur, hauteur)
##   2. relief : vallonnement + pente de drainage + massif + vallée
##   3. niveau de l'eau, lu sur le fond de vallée en aval
##   4. clairières : celle du bunker, puis les replats tirés à la graine
##   5. tracé de la rivière par descente de gradient, puis creusement du lit
##
## La rivière se trace sur un relief déjà complet : elle a besoin de connaître
## les pentes pour les descendre. La vallée, elle, est creusée *avant* le tracé
## et non déduite de lui — une descente de gradient sur du vallonnement seul se
## perd dans la première cuvette venue.
##
## Le relief se calcule dans le repère du massif et non dans celui du monde —
## `MassifShape` porte ce repère et le profil qui en découle. C'est ce qui permet
## de tirer l'orientation au hasard sans que rien d'autre n'ait à le savoir : la
## vallée, la pente de drainage et la rivière s'alignent dessus automatiquement.
##
## Ce fichier ne fait donc plus que **composer** : il tire une forme, applique le
## relief, puis enchaîne des opérateurs sur la heightmap (`HeightmapOps`). C'est
## la forme qu'aura le catalogue de features — une feature est une composition
## d'opérateurs, pas du code de terrain neuf.
##
## Convention de position : la bouche de grotte est à l'origine du monde, et le
## massif est placé pour que le pied de sa falaise y tombe. D'où l'absence de
## réglage de position de massif dans la config.

## Hauteurs des sommets de la grille, indexées par TerrainGenConfig.height_index().
var heights: PackedFloat32Array
## Bouche de grotte, à l'origine, à la hauteur finale du terrain.
var cave_position: Vector3
## Direction vers laquelle la grotte s'ouvre (massif dans le dos).
var cave_forward: Vector3
## Altitude de la surface de l'eau. Tout ce qui est plus bas est noyé.
var water_level: float
## Replats aplanis, en (centre.x, centre.z, rayon). Le premier est celui du
## bunker. Lu par le scatter, qui n'y pose pas de canopée.
var clearings: PackedVector3Array
## Tracé de la rivière, en points monde successifs. Lu par le scatter, qui ne
## plante pas dans le lit.
var river_path: PackedVector2Array
## Influence du massif en chaque sommet : 1 sur l'axe, 0 hors du massif. C'est
## la mesure de « à quel point on est en montagne », et c'est sur elle que les
## biomes déclarent leur étage.
##
## Surtout pas sur l'altitude : la carte descend de `drainage_drop` d'un bout à
## l'autre, si bien qu'une plaine parfaitement plate gagne quarante mètres en la
## traversant. Un étage déclaré en mètres au-dessus de l'eau s'y déclenche donc
## d'un seul côté de la carte, sans qu'aucun relief n'apparaisse. L'influence,
## elle, ignore le drainage, le vallonnement et le niveau du lac.
##
## Elle est déjà calculée pour le relief : la publier ne coûte qu'une écriture.
var massif_influence: PackedFloat32Array

const _SEED_MACRO := 0
const _SEED_WOBBLE := 977
const _SEED_PROFILE := 1451
const _SEED_VALLEY := 2129
const _SEED_CLEARING := 3313
## Tentatives de placement par clairière avant abandon.
const _CLEARING_TRIES := 12
## Descente minimale imposée entre deux points du tracé, en mètres. Empêche la
## ligne d'eau de stagner dans un creux et de remonter.
const _RIVER_MIN_DROP := 0.05
## Inertie du tracé : sans elle, il pivote d'un pas à l'autre sur du bruit.
const _RIVER_MOMENTUM := 0.6

var _cfg: TerrainGenConfig
var _n: int
var _macro: FastNoiseLite
var _wobble: FastNoiseLite
var _profile: FastNoiseLite
var _valley: FastNoiseLite

## Le massif tiré à la graine, et le tableau de hauteurs avec ses opérateurs.
var _massif: MassifShape
var _ops: HeightmapOps

## La vallée n'appartient pas au massif : elle s'aligne sur son axe, mais la
## carte n'en a qu'une quel que soit le nombre de massifs, et c'est d'elle que
## dépendent le niveau de l'eau et la topologie de la rivière.
var _valley_offset: float
var _valley_half_width: float
var _drainage_slope: float


func generate(cfg: TerrainGenConfig) -> void:
	_cfg = cfg
	_n = cfg.grid_size()
	_prepare_noise()
	_draw_massif()
	_build_relief()
	_compute_water_level()
	_flatten_clearings()
	_carve_river()
	heights = _ops.heights
	cave_position = Vector3(0.0, _ops.sample(Vector2.ZERO), 0.0)
	cave_forward = Vector3(_massif.side.x, 0.0, _massif.side.y)


# --- Préparation ---------------------------------------------------------------

## Les bruits sont dupliqués avant d'être semés : la graine du monde est la seule
## source de hasard, et la ressource de config n'est jamais modifiée au passage.
func _prepare_noise() -> void:
	_macro = _seeded(_cfg.macro_noise, _SEED_MACRO)
	_wobble = _seeded(_cfg.massif_wobble_noise, _SEED_WOBBLE)
	_profile = _seeded(_cfg.massif_profile_noise, _SEED_PROFILE)
	_valley = _seeded(_cfg.valley_wobble_noise, _SEED_VALLEY)


func _seeded(source: FastNoiseLite, offset: int) -> FastNoiseLite:
	if source == null:
		push_warning("HeightmapGenerator : bruit manquant dans la config, remplacé par un bruit par défaut.")
		source = FastNoiseLite.new()
	var noise: FastNoiseLite = source.duplicate()
	noise.seed = _cfg.world_seed + offset
	return noise


## Tire le massif, puis ce qui s'aligne dessus. La chaîne de hasard est tenue
## ici et non dans `MassifShape` : la graine du monde a un seul maître.
func _draw_massif() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = _cfg.world_seed
	_massif = MassifShape.draw(_cfg, rng, _wobble, _profile)

	var size := _cfg.size_meters
	_valley_offset = _cfg.valley_offset_ratio * size
	_valley_half_width = _cfg.valley_half_width_ratio * size
	_drainage_slope = _cfg.drainage_drop / size


# --- Relief --------------------------------------------------------------------

func _build_relief() -> void:
	# Le tableau se remplit ici puis passe à `HeightmapOps`, qui en devient
	# l'unique propriétaire. Le remplir à travers l'objet (`_ops.heights[i] = …`)
	# écrirait dans une copie de la propriété, sans erreur et sans effet.
	var relief := PackedFloat32Array()
	relief.resize(_n * _n)
	massif_influence.resize(_n * _n)
	for iz in _n:
		for ix in _n:
			var wp := _cfg.world_pos(ix, iz)
			var local := _massif.local_of(wp)
			var along := local.x
			var side := local.y
			var massif := _massif.sample(along, side)
			var valley := _valley_at(along, side)
			var macro := _macro.get_noise_2d(wp.x, wp.y) * _cfg.macro_amplitude
			# Le vallonnement s'efface sur la falaise (on y tient à une paroi
			# lisse), s'atténue au fond de la vallée (pas de cuvette fermée) et
			# se calme en plaine (on y construit).
			macro *= 1.0 - massif.y
			macro *= 1.0 - _cfg.valley_macro_damping * valley.y
			macro *= lerpf(_cfg.plain_macro_scale, 1.0, massif.z)
			var index := _cfg.height_index(ix, iz)
			relief[index] = massif.x + valley.x + macro - along * _drainage_slope
			massif_influence[index] = massif.z
	_ops = HeightmapOps.new(_cfg, relief)


## Retourne (creusement de la vallée, masque de fond de vallée).
func _valley_at(along: float, side: float) -> Vector2:
	var dist := absf(side - _valley_offset - _valley_wobble_at(along))
	var mask := smoothstep(0.0, 1.0, 1.0 - dist / _valley_half_width)
	return Vector2(-_cfg.valley_depth * mask, mask)


func _valley_wobble_at(along: float) -> float:
	return _valley.get_noise_2d(0.0, along) * _cfg.valley_wobble


# --- Eau -----------------------------------------------------------------------

## Le niveau de l'eau n'est pas un réglage absolu : c'est la hauteur du fond de
## vallée au rivage choisi. Il suit donc le tirage du massif et de la pente, et
## le lac occupe toujours l'aval quelle que soit la graine.
func _compute_water_level() -> void:
	var along := _cfg.lake_shore_along_ratio * _cfg.half_size()
	var shore := _massif.axis * along + _massif.side * (_valley_offset + _valley_wobble_at(along))
	water_level = _ops.sample(shore)


# --- Clairières ----------------------------------------------------------------

## La clairière du bunker et les replats dispersés sont la même chose : des
## disques aplanis. Les seconds servent deux fois — une trouée dans la canopée
## à la passe suivante, et un terrain constructible tout de suite.
func _flatten_clearings() -> void:
	# La clairière du bunker est le socle d'une construction : elle, on la veut
	# vraiment plane. Les replats de forêt gardent leur micro-relief.
	_ops.flatten_disc(Vector2.ZERO, _cfg.bunker_radius, _cfg.bunker_falloff, _cfg.bunker_max_delta, 1.0)
	clearings.append(Vector3(0.0, 0.0, _cfg.bunker_radius))

	var rng := RandomNumberGenerator.new()
	rng.seed = _cfg.world_seed + _SEED_CLEARING
	var half := _cfg.half_size()
	for _i in _cfg.clearing_count:
		var radius := rng.randf_range(_cfg.clearing_radius_range.x, _cfg.clearing_radius_range.y)
		var margin := half - radius - _cfg.clearing_falloff
		for _try in _CLEARING_TRIES:
			var candidate := Vector2(rng.randf_range(-margin, margin), rng.randf_range(-margin, margin))
			if not _accepts_clearing(candidate, radius):
				continue
			_ops.flatten_disc(candidate, radius, _cfg.clearing_falloff, _cfg.clearing_max_delta, _cfg.clearing_flatten_strength)
			clearings.append(Vector3(candidate.x, candidate.y, radius))
			break


## Un replat se refuse en montagne (il y taillerait une terrasse), sous l'eau,
## et sur la clairière du bunker qui a déjà été aplanie à ses propres réglages.
func _accepts_clearing(centre: Vector2, radius: float) -> bool:
	if centre.length() < _cfg.bunker_radius + _cfg.bunker_falloff + radius:
		return false
	var local := _massif.local_of(centre)
	var massif := _massif.sample(local.x, local.y)
	if massif.z > _cfg.clearing_max_massif_influence:
		return false
	return _ops.sample(centre) > water_level + _cfg.clearing_min_above_water


# --- Rivière -------------------------------------------------------------------

func _carve_river() -> void:
	river_path = _trace_river()
	if river_path.size() < 2:
		push_warning("HeightmapGenerator : tracé de rivière vide, rien à creuser.")
		return
	_ops.carve_channel(river_path, _water_line(river_path),
		_cfg.river_width, _cfg.river_bank, _cfg.river_depth)


## Descente de gradient dans la plaine, tenue par l'axe de vallée. Le gradient
## donne le méandre ; le guide garantit la topologie voulue (la rivière partage
## la zone au ratio demandé) et empêche le tracé de s'échouer dans une cuvette.
## La rivière ne descend pas du massif : une cascade depuis les hauteurs est une
## feature du biome montagne, pas une propriété du relief.
func _trace_river() -> PackedVector2Array:
	var half := _cfg.half_size()
	var source := _river_source()

	var path := PackedVector2Array([source])
	var dir := _massif.axis
	var max_steps := int(_cfg.size_meters * 3.0 / _cfg.river_step)
	var pos := source

	for _i in max_steps:
		var grad := _ops.gradient_at(pos)
		var downhill := dir
		if grad.length_squared() > 1e-8:
			downhill = -grad.normalized()
		# Le guide vise l'axe de vallée d'autant plus franchement qu'on en est
		# loin, et pousse toujours vers l'aval. Sa portée est la demi-largeur de
		# la vallée : au-delà, on la rejoint à 45°.
		var local := _massif.local_of(pos)
		var along := local.x
		var lateral := clampf((_valley_offset + _valley_wobble_at(along) - local.y) / _valley_half_width, -1.0, 1.0)
		var guide := (_massif.axis + _massif.side * lateral).normalized()
		var wanted := downhill.lerp(guide, _cfg.river_valley_pull)
		dir = (wanted + dir * _RIVER_MOMENTUM).normalized()
		pos += dir * _cfg.river_step
		path.append(pos)
		if absf(pos.x) >= half or absf(pos.y) >= half:
			break

	return path


## Point où l'axe de vallée entre dans la zone, côté amont. La rivière part du
## bord de la carte et pas d'un point arbitraire à l'intérieur — sans ça, une
## orientation en diagonale la faisait démarrer en plein milieu.
func _river_source() -> Vector2:
	var half := _cfg.half_size()
	var start := _massif.side * _valley_offset
	var upstream := -_massif.axis
	var distance := INF
	if absf(upstream.x) > 1e-6:
		distance = minf(distance, ((half if upstream.x > 0.0 else -half) - start.x) / upstream.x)
	if absf(upstream.y) > 1e-6:
		distance = minf(distance, ((half if upstream.y > 0.0 else -half) - start.y) / upstream.y)
	return start + upstream * (distance * 0.999)


## Ligne d'eau le long du tracé : elle suit le terrain mais ne remonte jamais.
func _water_line(path: PackedVector2Array) -> PackedFloat32Array:
	var water := PackedFloat32Array()
	water.resize(path.size())
	var previous := INF
	for i in path.size():
		var level := minf(_ops.sample(path[i]), previous - _RIVER_MIN_DROP)
		water[i] = level
		previous = level
	return water
