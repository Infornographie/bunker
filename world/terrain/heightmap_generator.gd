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
## Repère de travail : tout le relief se calcule dans le repère du massif, pas
## dans celui du monde. `along` court le long de l'axe du massif, `side` en
## travers. C'est ce qui permet de tirer l'orientation au hasard sans que rien
## d'autre n'ait à le savoir — la vallée, la pente de drainage et la rivière
## s'alignent dessus automatiquement.
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

## Repère du massif : _axis le long de la crête, _side en travers, orienté vers
## le versant qui porte la falaise.
var _axis: Vector2
var _side: Vector2
var _half_length: float
var _half_width: float
var _height: float
var _axis_side_base: float
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
	cave_position = Vector3(0.0, _cfg.sample_height(heights, Vector2.ZERO), 0.0)
	cave_forward = Vector3(_side.x, 0.0, _side.y)


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


## Tire la forme du massif, puis le place. L'ordre des tirages fait partie du
## contrat de la graine : le changer change toutes les cartes existantes.
func _draw_massif() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = _cfg.world_seed

	var angle := deg_to_rad(rng.randf_range(_cfg.massif_angle_range.x, _cfg.massif_angle_range.y))
	_axis = Vector2(cos(angle), sin(angle))
	_side = Vector2(-_axis.y, _axis.x)

	var size := _cfg.size_meters
	_half_length = rng.randf_range(_cfg.massif_half_length_ratio_range.x, _cfg.massif_half_length_ratio_range.y) * size
	_half_width = rng.randf_range(_cfg.massif_half_width_ratio_range.x, _cfg.massif_half_width_ratio_range.y) * size
	_height = rng.randf_range(_cfg.massif_height_range.x, _cfg.massif_height_range.y)

	# L'axe est décalé pour que le pied de la falaise passe par l'origine au
	# milieu du massif, méandre compris : c'est là que s'ouvre la grotte.
	var foot_distance := _half_width * (1.0 - _cfg.cliff_position)
	_axis_side_base = -foot_distance - _wobble_at(0.0)

	_valley_offset = _cfg.valley_offset_ratio * size
	_valley_half_width = _cfg.valley_half_width_ratio * size
	_drainage_slope = _cfg.drainage_drop / size


# --- Relief --------------------------------------------------------------------

func _build_relief() -> void:
	heights.resize(_n * _n)
	for iz in _n:
		for ix in _n:
			var wp := _cfg.world_pos(ix, iz)
			var along := wp.dot(_axis)
			var side := wp.dot(_side)
			var massif := _massif_at(along, side)
			var valley := _valley_at(along, side)
			var macro := _macro.get_noise_2d(wp.x, wp.y) * _cfg.macro_amplitude
			# Le vallonnement s'efface sur la falaise (on y tient à une paroi
			# lisse), s'atténue au fond de la vallée (pas de cuvette fermée) et
			# se calme en plaine (on y construit).
			macro *= 1.0 - massif.y
			macro *= 1.0 - _cfg.valley_macro_damping * valley.y
			macro *= lerpf(_cfg.plain_macro_scale, 1.0, massif.z)
			heights[_cfg.height_index(ix, iz)] = massif.x + valley.x + macro - along * _drainage_slope


## Retourne (hauteur du massif, masque de falaise, influence) en coordonnées
## locales. Les trois sortent du même calcul de profil, d'où le Vector3 plutôt
## que trois passes identiques. L'influence vaut 1 sur l'axe et 0 hors du
## massif : c'est la mesure de « à quel point on est en montagne ».
func _massif_at(along: float, side: float) -> Vector3:
	var taper := 1.0 - smoothstep(0.0, 1.0, absf(along) / _half_length)
	if taper <= 0.0:
		return Vector3.ZERO

	var across := side - _axis_side_base - _wobble_at(along)
	var t := 1.0 - absf(across) / _half_width
	if t <= 0.0:
		return Vector3.ZERO

	var c := _cfg.cliff_position
	var band := minf(_cfg.cliff_band_ratio, (1.0 - c) * 0.9)
	var hc := _cfg.cliff_height_ratio

	var shape := 0.0
	var cliff_mask := 0.0
	if across <= 0.0:
		# Versant opposé à la falaise : un simple dôme.
		shape = smoothstep(0.0, 1.0, t)
	else:
		# Hauteur du pied de falaise : la hauteur hors falaise se répartit entre
		# le versant du dessous et le dôme du dessus au prorata de leur largeur.
		var base_height := (1.0 - hc) * c / (1.0 - band)
		if t <= c:
			shape = base_height * smoothstep(0.0, 1.0, t / c)
		elif t <= c + band:
			shape = base_height + hc * smoothstep(0.0, 1.0, (t - c) / band)
		else:
			var top := base_height + hc
			shape = top + (1.0 - top) * smoothstep(0.0, 1.0, (t - c - band) / (1.0 - c - band))
		# Le masque déborde de la bande et s'éteint progressivement. Un masque
		# binaire coupait net le vallonnement au bord de la paroi : la marche qui
		# en résultait creusait une rainure sur toute la hauteur, de chaque côté.
		var outside := maxf(maxf(c - t, t - c - band), 0.0)
		cliff_mask = (1.0 - smoothstep(0.0, band, outside)) * taper

	return Vector3(shape * taper * _amplitude_at(along), cliff_mask, shape * taper)


## Retourne (creusement de la vallée, masque de fond de vallée).
func _valley_at(along: float, side: float) -> Vector2:
	var dist := absf(side - _valley_offset - _valley_wobble_at(along))
	var mask := smoothstep(0.0, 1.0, 1.0 - dist / _valley_half_width)
	return Vector2(-_cfg.valley_depth * mask, mask)


func _wobble_at(along: float) -> float:
	return _wobble.get_noise_2d(0.0, along) * _cfg.massif_wobble


func _valley_wobble_at(along: float) -> float:
	return _valley.get_noise_2d(0.0, along) * _cfg.valley_wobble


## Altitude de l'axe à cette abscisse — c'est elle qui creuse les cols.
func _amplitude_at(along: float) -> float:
	var v := 0.5 + 0.5 * _profile.get_noise_2d(1000.0, along)
	return _height * (1.0 - _cfg.massif_profile_variation * v)


# --- Eau -----------------------------------------------------------------------

## Le niveau de l'eau n'est pas un réglage absolu : c'est la hauteur du fond de
## vallée au rivage choisi. Il suit donc le tirage du massif et de la pente, et
## le lac occupe toujours l'aval quelle que soit la graine.
func _compute_water_level() -> void:
	var along := _cfg.lake_shore_along_ratio * _cfg.half_size()
	var shore := _axis * along + _side * (_valley_offset + _valley_wobble_at(along))
	water_level = _cfg.sample_height(heights, shore)


# --- Clairières ----------------------------------------------------------------

## La clairière du bunker et les replats dispersés sont la même chose : des
## disques aplanis. Les seconds servent deux fois — une trouée dans la canopée
## à la passe suivante, et un terrain constructible tout de suite.
func _flatten_clearings() -> void:
	# La clairière du bunker est le socle d'une construction : elle, on la veut
	# vraiment plane. Les replats de forêt gardent leur micro-relief.
	_flatten_disc(Vector2.ZERO, _cfg.bunker_radius, _cfg.bunker_falloff, _cfg.bunker_max_delta, 1.0)
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
			_flatten_disc(candidate, radius, _cfg.clearing_falloff, _cfg.clearing_max_delta, _cfg.clearing_flatten_strength)
			clearings.append(Vector3(candidate.x, candidate.y, radius))
			break


## Un replat se refuse en montagne (il y taillerait une terrasse), sous l'eau,
## et sur la clairière du bunker qui a déjà été aplanie à ses propres réglages.
func _accepts_clearing(centre: Vector2, radius: float) -> bool:
	if centre.length() < _cfg.bunker_radius + _cfg.bunker_falloff + radius:
		return false
	var massif := _massif_at(centre.dot(_axis), centre.dot(_side))
	if massif.z > _cfg.clearing_max_massif_influence:
		return false
	return _cfg.sample_height(heights, centre) > water_level + _cfg.clearing_min_above_water


## Aplanit un disque sur la hauteur de son centre. L'aplanissement renonce là où
## le terrain s'écarte trop de la cible : sans ça, le disque taillerait une
## marche nette dès qu'il mord sur un relief qui le domine.
func _flatten_disc(centre: Vector2, radius: float, falloff: float, max_delta: float, strength: float) -> void:
	var target := _cfg.sample_height(heights, centre)
	var outer := radius + falloff
	var half := _cfg.half_size()
	var ix0 := clampi(int(floor((centre.x - outer + half) / _cfg.cell_size)), 0, _n - 1)
	var ix1 := clampi(int(ceil((centre.x + outer + half) / _cfg.cell_size)), 0, _n - 1)
	var iz0 := clampi(int(floor((centre.y - outer + half) / _cfg.cell_size)), 0, _n - 1)
	var iz1 := clampi(int(ceil((centre.y + outer + half) / _cfg.cell_size)), 0, _n - 1)

	for iz in range(iz0, iz1 + 1):
		for ix in range(ix0, ix1 + 1):
			var dist := _cfg.world_pos(ix, iz).distance_to(centre)
			if dist >= outer:
				continue
			var idx := _cfg.height_index(ix, iz)
			var h := heights[idx]
			var w := strength * (1.0 - smoothstep(radius, outer, dist))
			w *= 1.0 - smoothstep(max_delta, max_delta * 2.0, absf(h - target))
			heights[idx] = lerpf(h, target, w)


# --- Rivière -------------------------------------------------------------------

func _carve_river() -> void:
	river_path = _trace_river()
	if river_path.size() < 2:
		push_warning("HeightmapGenerator : tracé de rivière vide, rien à creuser.")
		return
	_carve_channel(river_path, _water_line(river_path))


## Descente de gradient dans la plaine, tenue par l'axe de vallée. Le gradient
## donne le méandre ; le guide garantit la topologie voulue (la rivière partage
## la zone au ratio demandé) et empêche le tracé de s'échouer dans une cuvette.
## La rivière ne descend pas du massif : une cascade depuis les hauteurs est une
## feature du biome montagne, pas une propriété du relief.
func _trace_river() -> PackedVector2Array:
	var half := _cfg.half_size()
	var source := _river_source()

	var path := PackedVector2Array([source])
	var dir := _axis
	var max_steps := int(_cfg.size_meters * 3.0 / _cfg.river_step)
	var pos := source

	for _i in max_steps:
		var grad := _gradient_at(pos)
		var downhill := dir
		if grad.length_squared() > 1e-8:
			downhill = -grad.normalized()
		# Le guide vise l'axe de vallée d'autant plus franchement qu'on en est
		# loin, et pousse toujours vers l'aval. Sa portée est la demi-largeur de
		# la vallée : au-delà, on la rejoint à 45°.
		var along := pos.dot(_axis)
		var lateral := clampf((_valley_offset + _valley_wobble_at(along) - pos.dot(_side)) / _valley_half_width, -1.0, 1.0)
		var guide := (_axis + _side * lateral).normalized()
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
	var start := _side * _valley_offset
	var upstream := -_axis
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
		var level := minf(_cfg.sample_height(heights, path[i]), previous - _RIVER_MIN_DROP)
		water[i] = level
		previous = level
	return water


func _carve_channel(path: PackedVector2Array, water: PackedFloat32Array) -> void:
	var inner := _cfg.river_width * 0.5
	var outer := inner + _cfg.river_bank
	var half := _cfg.half_size()

	for i in path.size() - 1:
		var a := path[i]
		var b := path[i + 1]
		var ab := b - a
		var ab_len_sq := ab.length_squared()
		if ab_len_sq < 1e-6:
			continue

		var lo := Vector2(minf(a.x, b.x), minf(a.y, b.y)) - Vector2(outer, outer)
		var hi := Vector2(maxf(a.x, b.x), maxf(a.y, b.y)) + Vector2(outer, outer)
		var ix0 := clampi(int(floor((lo.x + half) / _cfg.cell_size)), 0, _n - 1)
		var ix1 := clampi(int(ceil((hi.x + half) / _cfg.cell_size)), 0, _n - 1)
		var iz0 := clampi(int(floor((lo.y + half) / _cfg.cell_size)), 0, _n - 1)
		var iz1 := clampi(int(ceil((hi.y + half) / _cfg.cell_size)), 0, _n - 1)

		for iz in range(iz0, iz1 + 1):
			for ix in range(ix0, ix1 + 1):
				var wp := _cfg.world_pos(ix, iz)
				var s := clampf((wp - a).dot(ab) / ab_len_sq, 0.0, 1.0)
				var dist := wp.distance_to(a + ab * s)
				if dist >= outer:
					continue
				var idx := _cfg.height_index(ix, iz)
				var bed := lerpf(water[i], water[i + 1], s) - _cfg.river_depth
				var carved := bed
				if dist > inner:
					var k := smoothstep(0.0, 1.0, (dist - inner) / _cfg.river_bank)
					carved = lerpf(bed, heights[idx], k)
				heights[idx] = minf(heights[idx], carved)


# --- Échantillonnage -----------------------------------------------------------

func _gradient_at(p: Vector2) -> Vector2:
	var e := _cfg.cell_size
	var dx := _cfg.sample_height(heights, p + Vector2(e, 0.0)) - _cfg.sample_height(heights, p - Vector2(e, 0.0))
	var dz := _cfg.sample_height(heights, p + Vector2(0.0, e)) - _cfg.sample_height(heights, p - Vector2(0.0, e))
	return Vector2(dx, dz) / (2.0 * e)
