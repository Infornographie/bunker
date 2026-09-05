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
##   5. tracé géométrique de la rivière, puis creusement du lit
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
## Tracé du cours principal, en points monde successifs. Lu par le scatter, qui
## ne plante pas dans le lit.
var river_path: PackedVector2Array
## Tous les cours d'eau de la carte — le bras principal d'abord, puis les bras
## secondaires. Chacun porte son tracé, sa ligne d'eau et ses largeurs : c'est
## ce que lit le constructeur de ruban pour en faire une surface.
var river_reaches: Array[RiverReach] = []
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
const _SEED_RIVER := 4409
## Tentatives de placement par clairière avant abandon.
const _CLEARING_TRIES := 12
## Descente minimale imposée entre deux points du tracé, en mètres. Empêche la
## ligne d'eau de stagner dans un creux et de remonter.
const _RIVER_MIN_DROP := 0.05

var _cfg: TerrainGenConfig
var _n: int
var _macro: FastNoiseLite
var _wobble: FastNoiseLite
var _profile: FastNoiseLite
var _valley: FastNoiseLite

## Tous les massifs de la carte, composés au `max`. Le premier est le principal :
## c'est lui qui porte le repère dont la vallée, l'écoulement et la rivière
## dérivent, et lui seul est placé par résolution sur la bouche de grotte.
var _massifs: Array[MassifShape] = []
## Raccourci de lecture sur le principal — la géographie de la carte se déclare
## sur lui, pas sur l'ensemble.
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
	_massif.place_cliff_foot_at_origin()
	_massifs.clear()
	_massifs.append(_massif)

	# Après le massif principal, et sur la même chaîne de hasard : à `spur_count`
	# nul, aucun tirage n'est consommé et la carte est exactement celle d'avant.
	for _i in _cfg.spur_count:
		_massifs.append(MassifShape.draw_spur(_cfg, rng, _wobble, _profile, _massif))

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
			# Projections sur les directions du massif, origine au monde : c'est
			# le repère de la vallée et de la pente d'écoulement, qui s'alignent
			# sur son axe sans être placées avec lui. Le massif, lui, se lit dans
			# son repère placé — d'où `sample_at` et non `sample`.
			var proj := _massif.project(wp)
			var along := proj.x
			var side := proj.y
			var massif := _massif_profile_at(wp)
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


## Profil composé de tous les massifs : (hauteur, masque de falaise, influence).
##
## **Composition au `max`, jamais en somme.** Deux reliefs qui se croisent, c'est
## le plus haut qui gagne — la somme ferait une bosse de deux massifs empilés à
## la jonction, là où le `max` fait disparaître le plus bas sous le plus haut et
## produit l'arête franche qu'est un contrefort. Même règle pour les deux autres
## composantes : une falaise reste une falaise quel que soit le massif qui la
## porte, et l'influence d'un point est celle du massif qui le domine — les
## biomes la lisent, et une influence sommée déclencherait les conifères dans
## une plaine coincée entre deux reliefs.
##
## À un seul massif, cette fonction est l'identité : c'est ce qui a permis de
## l'introduire sous empreinte, avant qu'un second massif n'existe.
func _massif_profile_at(world_point: Vector2) -> Vector3:
	var profile := _massifs[0].sample_at(world_point)
	for i in range(1, _massifs.size()):
		var other := _massifs[i].sample_at(world_point)
		profile = Vector3(
			maxf(profile.x, other.x),
			maxf(profile.y, other.y),
			maxf(profile.z, other.z))
	return profile


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
	var massif := _massif_profile_at(centre)
	if massif.z > _cfg.clearing_max_massif_influence:
		return false
	return _ops.sample(centre) > water_level + _cfg.clearing_min_above_water


# --- Rivière -------------------------------------------------------------------

func _carve_river() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = _cfg.world_seed + _SEED_RIVER
	river_path = _lay_river(rng)
	if river_path.size() < 2:
		push_warning("HeightmapGenerator : tracé de rivière vide, rien à creuser.")
		return

	var water := _water_line(river_path)
	var widths := _river_widths(river_path.size(), rng)
	var depths := _river_depths(river_path.size(), rng)
	_ops.carve_channel(river_path, water, widths, _cfg.river_bank, depths)
	river_reaches.clear()
	river_reaches.append(RiverReach.new(river_path, water, widths))
	_carve_island(river_path, water, widths, depths, rng)


## Trace le cours **géométriquement**, sans regarder le relief.
##
## L'ancien tracé descendait le gradient, guidé vers l'axe de vallée. Il avait
## deux défauts, et le second est le vrai : il s'échouait dans la moindre cuvette
## fermée — un éperon en travers de la vallée lui suffisait — et surtout il ne
## produisait pas le méandre qu'on attendait de lui. On payait les inconvénients
## d'une descente de gradient sans en toucher le bénéfice.
##
## Ici le cours est **posé**, puis le terrain cède : la ligne d'eau ne remonte
## jamais et le lit se creuse dessous, si bien qu'un relief en travers du chemin
## est tranché. C'est le modèle de la rivière **antécédente** — elle coulait
## avant que le relief ne se soulève et a creusé au rythme où il montait. La
## cluse n'est donc plus une feature à écrire : c'est ce qui arrive lorsque le
## cours croise un éperon.
##
## Trois harmoniques plutôt qu'une : une sinusoïde se lit comme une sinusoïde,
## et ce sont les longueurs d'onde secondaires qui donnent les boucles serrées
## et les presqu'îles.
func _lay_river(rng: RandomNumberGenerator) -> PackedVector2Array:
	var amplitude := rng.randf_range(_cfg.river_meander_amplitude_range.x, _cfg.river_meander_amplitude_range.y)
	var wavelength := rng.randf_range(_cfg.river_meander_wavelength_range.x, _cfg.river_meander_wavelength_range.y)
	var p0 := rng.randf() * TAU
	var p1 := rng.randf() * TAU
	var p2 := rng.randf() * TAU

	# On parcourt large et on ne garde que ce qui tombe dans la carte : le cours
	# entre et sort par un bord, il ne commence ni ne finit à l'intérieur.
	var half := _cfg.half_size()
	var reach := half * 1.6
	var path := PackedVector2Array()
	var a := -reach
	while a <= reach:
		var lateral := _valley_offset + _valley_wobble_at(a)
		lateral += amplitude * sin(TAU * a / wavelength + p0)
		lateral += amplitude * 0.45 * sin(TAU * a / (wavelength * 0.43) + p1)
		lateral += amplitude * 0.22 * sin(TAU * a / (wavelength * 0.19) + p2)
		path.append(_massif.axis * a + _massif.side * lateral)
		a += _cfg.river_step
	return _clipped_to_zone(path, half)


## Ne garde que la traversée de la zone, plus un point de marge de chaque côté
## pour que le lit soit creusé jusqu'au bord et non un pas avant.
func _clipped_to_zone(path: PackedVector2Array, half: float) -> PackedVector2Array:
	var first := -1
	var last := -1
	for i in path.size():
		if maxf(absf(path[i].x), absf(path[i].y)) <= half:
			if first < 0:
				first = i
			last = i
	if first < 0:
		return PackedVector2Array()
	return path.slice(maxi(first - 1, 0), mini(last + 2, path.size()))


## Largeur du lit le long du cours. Deux ondes de longueurs très différentes :
## la lente fait les biefs larges et les passages resserrés, la rapide évite que
## la variation ne se lise comme une régularité.
func _river_widths(count: int, rng: RandomNumberGenerator) -> PackedFloat32Array:
	var phase := rng.randf() * TAU
	var widths := PackedFloat32Array()
	widths.resize(count)
	for i in count:
		var t := float(i)
		var wave := 0.5 + 0.35 * sin(t * 0.012 + phase) + 0.15 * sin(t * 0.047 + phase * 2.3)
		widths[i] = lerpf(_cfg.river_width_range.x, _cfg.river_width_range.y, clampf(wave, 0.0, 1.0))
	return widths


## Profondeur du lit. Corrélée à la largeur dans la nature — un bief large est un
## bief profond — mais décalée, pour que les deux ne varient pas d'un bloc.
func _river_depths(count: int, rng: RandomNumberGenerator) -> PackedFloat32Array:
	var phase := rng.randf() * TAU
	var depths := PackedFloat32Array()
	depths.resize(count)
	for i in count:
		var wave := 0.5 + 0.5 * sin(float(i) * 0.009 + phase)
		depths[i] = lerpf(_cfg.river_depth_range.x, _cfg.river_depth_range.y, wave)
	return depths


## Détache un bras secondaire sur une portion du cours : ce qui reste entre les
## deux bras est une île.
##
## Le bras s'écarte en cloche, ce qui lui donne ses deux confluences sans qu'on
## ait à les dessiner. Il est creusé **moins large et moins profond** que le bras
## principal : un bras secondaire l'est toujours, et c'est ce qui évite que l'île
## ne flotte entre deux chenaux jumeaux, ce qu'aucun fleuve ne fait.
##
## L'emplacement se tire **dans la portion émergée du cours**. Sans cette
## contrainte, la moitié aval du tracé est sous le niveau du lac, et une île
## tirée là est un haut-fond invisible : c'est ce qui donnait l'impression qu'il
## n'y avait presque jamais d'île.
func _carve_island(path: PackedVector2Array, water: PackedFloat32Array,
		widths: PackedFloat32Array, depths: PackedFloat32Array, rng: RandomNumberGenerator) -> void:
	if rng.randf() > _cfg.river_island_chance:
		return

	var length := rng.randf_range(_cfg.river_island_length_range.x, _cfg.river_island_length_range.y)
	var span := maxi(int(length / _cfg.river_step), 4)
	if path.size() < span + 4:
		return
	var start := _island_start(water, span, rng)
	if start < 0:
		return
	var side_sign := 1.0 if rng.randf() < 0.5 else -1.0

	var branch := PackedVector2Array()
	var branch_water := PackedFloat32Array()
	var branch_widths := PackedFloat32Array()
	var branch_depths := PackedFloat32Array()
	for i in span + 1:
		var k := start + i
		var u := float(i) / float(span)
		var bulge := sin(PI * u) * widths[k] * _cfg.river_island_spread * side_sign
		# L'écart se prend perpendiculairement au **cours**, pas selon l'axe de
		# vallée : dans un coude, les deux ne pointent pas au même endroit.
		var tangent := (path[mini(k + 1, path.size() - 1)] - path[maxi(k - 1, 0)]).normalized()
		branch.append(path[k] + Vector2(-tangent.y, tangent.x) * bulge)
		branch_water.append(water[k])
		branch_widths.append(widths[k] * 0.6)
		branch_depths.append(depths[k] * 0.55)
	_ops.carve_channel(branch, branch_water, branch_widths, _cfg.river_bank, branch_depths)
	river_reaches.append(RiverReach.new(branch, branch_water, branch_widths))


## Indice de départ d'une île, tiré parmi les portions entièrement au-dessus du
## niveau du lac. Retourne -1 s'il n'en existe aucune d'assez longue.
func _island_start(water: PackedFloat32Array, span: int, rng: RandomNumberGenerator) -> int:
	var candidates := PackedInt32Array()
	for start in range(1, water.size() - span - 1):
		if water[start + span] > water_level + _cfg.river_depth_range.x:
			candidates.append(start)
	if candidates.is_empty():
		return -1
	return candidates[rng.randi_range(0, candidates.size() - 1)]


## Ligne d'eau le long du tracé : elle suit le terrain, **en dessous**, et ne
## remonte jamais.
##
## Deux contraintes, deux rôles. Ne jamais remonter est ce qui fait qu'un relief
## posé en travers du cours est tranché plutôt que contourné. Passer sous le
## terrain d'un encaissement est ce qui fait que l'eau reste dans ses berges :
## posée à l'altitude du sol, la nappe déborde sur tout ce qui est un peu plus
## bas alentour et inonde le sous-bois.
func _water_line(path: PackedVector2Array) -> PackedFloat32Array:
	var water := PackedFloat32Array()
	water.resize(path.size())
	var previous := INF
	for i in path.size():
		var level := minf(_ops.sample(path[i]) - _cfg.river_freeboard, previous - _RIVER_MIN_DROP)
		water[i] = level
		previous = level
	return water
