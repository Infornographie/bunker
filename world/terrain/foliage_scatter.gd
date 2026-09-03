@tool
class_name FoliageScatter
extends RefCounted
## Peuple le terrain en croisant strates et biomes, en `MultiMeshInstance3D` par
## chunk.
##
## Deux axes qui ne se mélangent pas : une `FoliageLayer` dit **comment** on
## sème — grille, espacement, réponse aux clairières ; un `BiomeDef` dit **quoi**
## et **où**. Le semis les croise, et une composition est donc toujours le couple
## (strate, biome).
##
## **Biomes.** La `BiomeMap` donne en chaque point un poids par biome, jamais un
## identifiant. Le semis tire au sort quel biome décide de ce candidat-là, puis
## déroule sa roue d'essences inchangée. Là où deux poids se valent, les deux
## compositions s'entremêlent arbre par arbre — une vraie limite forestière est
## un mélange qui s'inverse, pas un trait. Mélanger les *poids* aurait donné une
## moyenne : un arbre à mi-chemin entre deux biomes, qui ne pousse dans aucun.
##
## Répartition : une grille jitterée par strate, un candidat par cellule, accepté
## ou rejeté selon la pente, l'eau, les clairières et ce qui est déjà posé. Pas
## de poisson-disque — à ce volume il coûterait cher pour un résultat que l'œil
## ne distingue pas une fois les troncs posés.
##
## **Les strates se sèment l'une après l'autre, chacune sur toute la carte.**
## Une strate lit l'occupation laissée par les précédentes : un arbre déborde
## chez le chunk voisin, donc l'occupation doit être complète avant que la
## strate d'en dessous ne la consulte. Semer une strate chunk par chunk jusqu'au
## bout puis passer à la suivante est la seule façon de le garantir.
##
## **Peuplements.** Une forêt réelle pousse par bosquets d'une même espèce, et un
## sous-bois par plaques. L'essence n'est donc pas tirée au hasard en chaque
## point : la valeur d'un champ de bruit désigne une position sur une roue où
## chaque essence occupe un secteur proportionnel à son poids. Deux points
## voisins lisent des valeurs voisines, tombent dans le même secteur, et font une
## plaque — sans qu'aucun code ne dessine de frontière.
##
## Un champ de bruit **par essence** donnait le même effet et coûtait un appel
## par essence et par candidat : à un mètre d'espacement et quatorze essences,
## c'était le semis entier. La roue en coûte un, quel que soit le nombre.
##
## Le choix se fait au point et jamais au chunk — sélectionner quelques essences
## par chunk paraissait équivalent et ne l'est pas : là où deux chunks voisins ne
## retiennent pas les mêmes, la couture est une ligne droite, et la grille se
## voit dans la canopée.
##
## **Taches.** Un coin à champignons n'est pas un champignon plus probable : les
## `FoliagePatch` d'un `BiomeStratum` remplacent sa palette entière là où leur
## bruit dépasse un seuil. C'est la différence entre un endroit et un
## saupoudrage — et comme elles appartiennent au biome, une tache peut n'exister
## que sous les conifères sans qu'aucun code n'ait à l'arbitrer.
##
## Découpage par chunk, calé sur celui du terrain : c'est ce qui permet de ne
## dessiner que le visible et de couper l'ombre au loin (`FoliageProximity`).
##
## Les modèles du pack ne sont pas toujours d'un seul tenant (tronc et feuillage
## peuvent être deux `MeshInstance3D`). Chaque partie reçoit donc son propre
## multimesh, alimenté par les mêmes transformées : un modèle en deux morceaux
## se pose comme un modèle en un seul.

## Décalages de graine par chunk — trois grands nombres premiers, pour que deux
## chunks voisins ne tirent pas des suites corrélées.
const _CHUNK_SEED_X := 73856093
const _CHUNK_SEED_Z := 19349663
const _SEED_STAND := 4211
## Décalage de graine entre deux strates : sans lui, les peuplements de buissons
## se calqueraient exactement sur ceux des arbres.
const _SEED_LAYER := 15485863
## Décalage de graine entre deux taches d'une même strate.
const _SEED_PATCH := 6291469
## Décalage de graine entre deux biomes : sans lui, deux biomes emploieraient le
## même champ de peuplement et leurs bosquets se calqueraient les uns sur les
## autres, ce qui se verrait précisément là où les deux se mélangent.
const _SEED_BIOME := 2750159

## Une partie de modèle : son mesh et sa position dans la scène d'origine.
class Part:
	var mesh: Mesh
	var offset: Transform3D

## Une composition disponible en un point : les essences, leur roue de secteurs
## cumulés, et le bruit qui dit où on est sur la roue. La palette de base d'une
## strate et chacune de ses taches en sont une — même code, même tirage.
class Palette:
	var defs: Array[FoliageDef] = []
	## Bornes hautes des secteurs, cumulées et normalisées à 1.
	var wheel := PackedFloat32Array()
	var noise: FastNoiseLite
	var blend := 0.0
	## Bruit et seuil d'activation ; nuls pour la palette de base, qui répond
	## toujours.
	var gate: FastNoiseLite
	var threshold := 0.0
	var density := 1.0
	## Bande de pente où la tache existe.
	var min_slope := 0.0
	var max_slope := 90.0

	## Essence désignée par la roue en ce point. Un appel de bruit, un seul.
	func pick(point: Vector2, roll: float) -> FoliageDef:
		var field := 0.5 + 0.5 * noise.get_noise_2dv(point) if noise != null else roll
		var position := fposmod(field + (roll - 0.5) * blend, 1.0)
		for i in wheel.size():
			if position <= wheel[i]:
				return defs[i]
		return defs[defs.size() - 1]

	## Vrai si cette palette prend la main en ce point.
	func covers(point: Vector2, slope: float) -> bool:
		if gate == null:
			return true
		if slope < min_slope or slope > max_slope:
			return false
		return 0.5 + 0.5 * gate.get_noise_2dv(point) > threshold

var _parts_cache: Dictionary = {}
## Palettes par index de strate. Les strates streamées reconstruisent un chunk à
## chaque pas du joueur : recomposer leurs roues à chaque fois serait du travail
## refait en boucle, et il croît avec le nombre de biomes.
var _palettes_cache: Dictionary = {}
## Nombre d'instances effectivement posées, pour le compte-rendu de génération.
var placed_count: int = 0
## Compte par strate, dans l'ordre de semis. C'est le chiffre qu'on regarde pour
## régler un espacement : un total global ne dit pas quelle strate a débordé.
var placed_per_layer: Array[int] = []
## Compte par biome, dans l'ordre de `TerrainGenConfig.biomes`. Seul moyen de
## vérifier qu'un biome existe vraiment sans aller le chercher à pied — un
## biome dont la bande ne croise jamais le relief tiré rend zéro, en silence.
var placed_per_biome: Array[int] = []
## Ce que le semis a posé et l'ombre qu'il porte. Publié parce que les strates
## streamées et la couleur du sol le lisent.
var occupancy: ScatterOccupancy
## Nœud de chaque chunk, par coordonnées de grille. C'est le point d'entrée de
## `FoliageProximity` vers ce qui est semé en permanence, et donc vers les
## multimeshes dont il coupe l'ombre. Les tuiles streamées ne s'y accrochent
## pas : elles ont leur propre grain et se parentent à la racine du feuillage.
var chunk_nodes: Dictionary = {}

# Contexte de la carte courante, retenu pour pouvoir semer un chunk plus tard.
# Ce `RefCounted` porte donc un état : c'est le prix du semis à la demande, et
# il vit aussi longtemps que le terrain qu'il a produit.
var _cfg: TerrainGenConfig
var _heights: PackedFloat32Array
var _clearings: PackedVector3Array
var _river: PackedVector2Array
var _water_level: float
var _biomes: BiomeMap


## Construit tout le feuillage. Retourne un Node3D à parenter dans la scène.
func scatter(cfg: TerrainGenConfig, heights: PackedFloat32Array, clearings: PackedVector3Array,
		river: PackedVector2Array, water_level: float, biomes: BiomeMap) -> Node3D:
	_cfg = cfg
	_heights = heights
	_clearings = clearings
	_river = river
	_water_level = water_level
	_biomes = biomes
	placed_count = 0
	chunk_nodes.clear()
	# Dimensionnés sur les listes et non remplis au fil de l'eau : une strate ou
	# un biome ignoré décalerait tous les comptes suivants.
	placed_per_layer.clear()
	placed_per_layer.resize(cfg.layers.size())
	placed_per_biome.clear()
	placed_per_biome.resize(cfg.biomes.size())
	_palettes_cache.clear()
	# Pas de retour anticipé : le terrain a besoin d'une occupation même vide —
	# c'est elle qui porte la carte d'ouverture et colore le sol.
	if cfg.biomes.is_empty():
		push_warning("FoliageScatter : aucun biome déclaré, rien ne poussera.")
	occupancy = ScatterOccupancy.new(cfg.occupancy_cell_size,
			Rect2(Vector2(-cfg.half_size(), -cfg.half_size()), Vector2(cfg.size_meters, cfg.size_meters)))
	var root := Node3D.new()
	var side := cfg.chunks_per_side()

	# Placements retenus, par chunk puis par essence. Les nœuds ne se
	# construisent qu'à la fin : un chunk reçoit les instances de toutes les
	# strates, et une strate n'est terminée qu'après le dernier chunk.
	var harvest: Array[Dictionary] = []
	harvest.resize(side * side)
	for i in harvest.size():
		harvest[i] = {}

	for index in cfg.layers.size():
		var layer: FoliageLayer = cfg.layers[index]
		if layer == null:
			push_warning("FoliageScatter : strate nulle en position %d, ignorée." % index)
			continue
		if layer.streamed:
			continue  # semée à la demande, autour du point de vue
		var palettes := _palettes_of(layer, index)
		if palettes.is_empty():
			continue
		var before := placed_count
		for cz in side:
			for cx in side:
				# Le dictionnaire est passé pour être rempli : contrairement aux
				# `Packed*Array`, il est bien une référence.
				_scatter_area(layer, palettes, index, cfg.chunk_area(cx, cz), Vector2i(cx, cz),
						null, harvest[cz * side + cx])
		placed_per_layer[index] = placed_count - before

	for cz in side:
		for cx in side:
			var placements: Dictionary = harvest[cz * side + cx]
			if placements.is_empty():
				continue
			var chunk := _build_chunk_node(cfg, placements, cx, cz)
			root.add_child(chunk)
			chunk_nodes[Vector2i(cx, cz)] = chunk
	return root


## Sème les strates streamées d'une tuile. Le nœud retourné est à parenter par
## l'appelant, qui le libérera quand la tuile s'éloignera.
##
## La tuile est bien plus petite que le chunk de terrain, et c'est tout l'objet :
## le coût d'un semis va comme le carré du côté, et c'est lui qui doit tenir
## dans une frame. Le chunk, lui, garde son grain pour le culling et les ombres.
##
## L'occupation permanente est **lue** et jamais écrite : sans quoi un
## aller-retour du joueur laisserait le sol marqué par une herbe disparue, et la
## même tuile ne donnerait pas deux fois la même chose. Les plantes de la strate
## ne se gênent qu'entre elles, dans une grille locale jetée avec le nœud.
func stream_tile(tx: int, tz: int) -> Node3D:
	var area := _cfg.stream_tile_area(tx, tz)
	var local := ScatterOccupancy.new(_cfg.occupancy_cell_size, area)
	var placements: Dictionary = {}
	for index in _cfg.layers.size():
		var layer: FoliageLayer = _cfg.layers[index]
		if layer == null or not layer.streamed:
			continue
		var palettes := _palettes_of(layer, index)
		if palettes.is_empty():
			continue
		_scatter_area(layer, palettes, index, area, Vector2i(tx, tz), local, placements)
	var node := Node3D.new()
	node.name = "streamed"
	for def: FoliageDef in placements:
		for part in _parts_of(def):
			node.add_child(_build_multimesh(_cfg, def, part, placements[def]))
	return node


## Entrées exploitables d'une composition. Une entrée sans essence ou sans
## modèle est une erreur d'édition : elle se signale, elle ne se devine pas.
func _usable_entries(source: Array[FoliageWeight], owner: StringName) -> Array[FoliageWeight]:
	var entries: Array[FoliageWeight] = []
	for entry in source:
		if entry == null or entry.def == null or entry.def.model == null:
			push_warning("FoliageScatter : entrée sans modèle dans « %s », ignorée." % owner)
			continue
		entries.append(entry)
	return entries


# --- Peuplements ---------------------------------------------------------------

## Palettes d'une strate, par biome. L'index externe suit
## `TerrainGenConfig.biomes` : un biome qui ne fait rien pousser dans cette
## strate y laisse une liste vide, et rien ne s'y sèmera — une berge sans
## canopée est une berge dégagée, pas une erreur.
func _palettes_of(layer: FoliageLayer, layer_index: int) -> Array:
	if _palettes_cache.has(layer_index):
		return _palettes_cache[layer_index]
	var by_biome: Array = []
	var any := false
	for biome_index in _cfg.biomes.size():
		var biome: BiomeDef = _cfg.biomes[biome_index]
		var built: Array[Palette] = []
		by_biome.append(built)
		if biome == null:
			continue
		var stratum := biome.stratum_for(layer.id)
		if stratum == null:
			continue
		var owner := StringName("%s/%s" % [biome.id, layer.id])
		# Taches d'abord, composition de base ensuite : l'ordre de la liste est
		# celui du test, et la première qui répond l'emporte.
		for index in stratum.patches.size():
			var patch: FoliagePatch = stratum.patches[index]
			if patch == null:
				continue
			var palette := _palette(_usable_entries(patch.entries, owner), patch.noise,
					layer.stand_blend, layer_index, biome_index, index + 1)
			if palette == null:
				push_warning("FoliageScatter : tache « %s » sans essence exploitable dans « %s »."
						% [patch.id, owner])
				continue
			palette.gate = patch.noise.duplicate() if patch.noise != null else FastNoiseLite.new()
			palette.gate.seed = _cfg.world_seed + _SEED_PATCH * (index + 1) \
					+ _SEED_BIOME * (biome_index + 1)
			palette.threshold = patch.threshold
			palette.density = patch.density
			palette.min_slope = patch.min_slope_degrees
			palette.max_slope = patch.max_slope_degrees
			built.append(palette)
		var base := _palette(_usable_entries(stratum.entries, owner), layer.stand_noise,
				layer.stand_blend, layer_index, biome_index, 0)
		if base == null:
			push_warning("FoliageScatter : « %s » sans composition de base." % owner)
		else:
			built.append(base)
		any = any or not built.is_empty()
	if not any:
		push_warning("FoliageScatter : strate « %s » sans composition dans aucun biome." % layer.id)
		by_biome = []
	_palettes_cache[layer_index] = by_biome
	return by_biome


## Construit une roue de secteurs cumulés. Le calcul se fait une fois par couple
## (strate, biome) et non par candidat : c'est ce qui rend le tirage gratuit, et
## c'est la raison pour laquelle les biomes se départagent au tirage plutôt
## qu'en additionnant leurs poids d'essences.
func _palette(entries: Array[FoliageWeight], noise: FastNoiseLite, blend: float,
		layer_index: int, biome_index: int, salt: int) -> Palette:
	if entries.is_empty():
		return null
	var total := 0.0
	for entry in entries:
		total += maxf(entry.weight, 0.0)
	if total <= 0.0:
		return null
	var palette := Palette.new()
	for entry in entries:
		palette.defs.append(entry.def)
	palette.blend = blend
	palette.noise = noise.duplicate() if noise != null else null
	if palette.noise != null:
		palette.noise.seed = _cfg.world_seed + _SEED_STAND + layer_index * _SEED_LAYER \
				+ biome_index * _SEED_BIOME + salt * 7919
	palette.wheel.resize(entries.size())
	var cursor := 0.0
	for i in entries.size():
		cursor += maxf(entries[i].weight, 0.0) / total
		palette.wheel[i] = cursor
	return palette


## Biome qui décide de ce candidat. Les poids de la carte somment à 1 en chaque
## sommet, donc aussi une fois interpolés : le tirage n'a rien à normaliser.
##
## Un tirage aléatoire et non un bruit : un bruit ferait des plaques de biome
## aux bords nets, ce qui reviendrait à dessiner la frontière que la carte de
## poids sert justement à ne pas avoir.
func _biome_at(point: Vector2, roll: float) -> int:
	var count := _biomes.weights.size()
	if count <= 1:
		return 0
	var cursor := 0.0
	for i in count:
		cursor += _cfg.sample_grid(_biomes.weights[i], point)
		if roll <= cursor:
			return i
	return count - 1


# --- Répartition ---------------------------------------------------------------

## Sème une strate sur une aire rectangulaire. L'aire est un chunk pour les
## strates permanentes, une tuile de streaming pour les autres : le semis ne
## connaît qu'un rectangle et une graine, ce qui laisse chaque usage choisir son
## grain sans que ce code ait à le savoir.
func _scatter_area(layer: FoliageLayer, palettes_by_biome: Array, layer_index: int,
		area: Rect2, cell: Vector2i, local: ScatterOccupancy, into: Dictionary) -> void:
	var cfg := _cfg
	var heights := _heights
	var clearings := _clearings
	var river := _river
	var water_level := _water_level
	var half := cfg.half_size()
	var origin := area.position
	var spacing := layer.spacing

	var rng := RandomNumberGenerator.new()
	rng.seed = cfg.world_seed + cell.x * _CHUNK_SEED_X + cell.y * _CHUNK_SEED_Z \
			+ layer_index * _SEED_LAYER

	# Grille globale, parcourue sur la seule portion qui tombe dans cette aire :
	# les cellules ne dépendent pas du découpage. Les deux bornes s'arrondissent
	# au supérieur et la fin d'une aire est le début de la suivante — sinon, dès
	# que l'espacement ne divise pas la largeur, une colonne de cellules se perd
	# à chaque frontière et le découpage se voit dans la végétation.
	var gx0 := int(ceil((origin.x + half) / spacing))
	var gz0 := int(ceil((origin.y + half) / spacing))
	var gx1 := int(ceil((origin.x + area.size.x + half) / spacing))
	var gz1 := int(ceil((origin.y + area.size.y + half) / spacing))

	# Le lit est écarté de la moitié de sa largeur plus sa berge : les plantes
	# s'arrêtent en haut de talus. On ne retient que les segments qui passent
	# dans ce chunk, sinon chaque candidat testerait tout le cours d'eau.
	var river_margin := cfg.river_width * 0.5 + cfg.river_bank
	var nearby := _river_segments_near(river, area, river_margin)
	# Même pré-filtrage pour les clairières : la jitter peut déborder d'une
	# cellule au-delà de l'aire, d'où la marge.
	var clearings_near := _clearings_near(clearings, area.grow(spacing))

	for gz in range(gz0, gz1):
		for gx in range(gx0, gx1):
			var jitter := Vector2(rng.randf(), rng.randf()) * spacing * layer.jitter
			var point := Vector2(-half + gx * spacing, -half + gz * spacing) + jitter
			if absf(point.x) >= half or absf(point.y) >= half:
				continue

			var height := cfg.sample_height(heights, point)
			if height < water_level + cfg.foliage_water_margin:
				continue
			# La pente sert deux fois : à choisir la tache, puis à filtrer
			# l'essence. Elle se calcule donc avant la palette, et une seule fois.
			var slope := _slope_at(cfg, heights, point)
			var openness := _clearing_openness(cfg, clearings, clearings_near, point)
			if layer.clearing_response != null \
					and rng.randf() > layer.clearing_response.sample(openness):
				continue
			if _is_in_river(river, nearby, point, river_margin):
				continue

			# Dans une clairière, la composition se lit au centre de la tache :
			# palette *et* essence, sinon la moitié du tapis basculerait dans
			# une autre plaque ou un autre patch. C'est ce qui fait qu'une
			# clairière est une unité et pas un morceau de forêt sans arbres.
			var sample := point
			var uniform := false
			if layer.clearing_uniform and openness < 1.0:
				var index := _clearing_index(clearings, clearings_near, point)
				if index >= 0:
					sample = Vector2(clearings[index].x, clearings[index].y)
					uniform = true

			# Quel biome décide, et donc dans quelles palettes on cherche. Lu au
			# point d'échantillonnage : une clairière uniforme appartient à un
			# seul biome, comme elle n'a qu'une essence.
			var biome_index := _biome_at(sample, 0.5 if uniform else rng.randf())
			var palettes: Array = palettes_by_biome[biome_index]
			if palettes.is_empty():
				continue  # ce biome ne fait rien pousser dans cette strate

			# La première palette qui couvre le point l'emporte : une tache
			# remplace la composition, elle ne s'y ajoute pas.
			# La pente est lue au point d'échantillonnage : au centre d'une
			# clairière quand elle est uniforme, sinon sous nos pieds.
			var gate_slope := slope if not uniform else _slope_at(cfg, heights, sample)
			var palette: Palette = null
			# Boucle typée : `palettes` est un `Array` non typé — GDScript ne
			# sait pas imbriquer les types de tableaux — et affecter son
			# `Variant` à une variable typée fait échouer la compilation.
			for candidate: Palette in palettes:
				if candidate.covers(sample, gate_slope):
					palette = candidate
					break
			if palette == null:
				continue
			# Un tirage figé dans une clairière : le brouillage de lisière y
			# réintroduirait justement le mélange qu'on vient d'écarter.
			var def := palette.pick(sample, 0.5 if uniform else rng.randf())
			if slope < def.min_slope_degrees or slope > def.max_slope_degrees:
				continue
			# Densité de la tache et goût de l'essence pour l'ombre se
			# multiplient : un parterre dense reste clairsemé là où son espèce
			# ne pousse pas, et une tache peut passer outre un léger refus.
			var chance := palette.density
			if def.cover_response != null:
				chance *= def.cover_response.sample(occupancy.cover_at(point))
			if chance < 1.0 and rng.randf() > chance:
				continue
			if occupancy.is_blocked(point, def.base_radius) \
					or (local != null and local.is_blocked(point, def.base_radius)):
				continue

			var basis := Basis.IDENTITY
			if def.align_to_slope > 0.0:
				basis = _slope_basis(cfg, heights, point, def.align_to_slope)
			if def.random_yaw:
				basis = basis.rotated(basis.y.normalized(), rng.randf() * TAU)
			basis = basis.scaled(Vector3.ONE * rng.randf_range(def.scale_range.x, def.scale_range.y))
			if not into.has(def):
				into[def] = []
			into[def].append(Transform3D(basis, Vector3(point.x, height - _sink(def, slope), point.y)))
			if local != null:
				local.mark(point, def.base_radius, 0.0, 0.0)
			else:
				occupancy.mark(point, def.base_radius, def.cover_radius, def.cover_amount)
			placed_count += 1
			placed_per_biome[biome_index] += 1


## Indices des clairières dont le disque, adoucissement compris, recoupe l'aire
## semée. Sans ce filtre, chaque candidat les teste **toutes** : à vingt-trois
## clairières et seize mille candidats par tuile de sol, c'est le premier poste
## de dépense du semis. C'est le service que `_river_segments_near()` rend déjà
## au cours d'eau — le motif existait dans ce fichier, à l'endroit d'à côté.
func _clearings_near(clearings: PackedVector3Array, area: Rect2) -> PackedInt32Array:
	var found := PackedInt32Array()
	for i in clearings.size():
		var reach := clearings[i].z + _cfg.clearing_falloff
		if area.grow(reach).has_point(Vector2(clearings[i].x, clearings[i].y)):
			found.append(i)
	return found


## Part de végétation ligneuse admise en ce point : nulle au cœur d'une
## clairière, pleine au-delà de son adoucissement. La lisière n'est pas
## dessinée, elle est le dégradé entre les deux.
func _clearing_openness(cfg: TerrainGenConfig, clearings: PackedVector3Array,
		nearby: PackedInt32Array, point: Vector2) -> float:
	var openness := 1.0
	for i in nearby:
		var clearing := clearings[i]
		var dist := point.distance_to(Vector2(clearing.x, clearing.y))
		openness = minf(openness, smoothstep(clearing.z, clearing.z + cfg.clearing_falloff, dist))
		if openness <= 0.0:
			return 0.0
	return openness


## Index de la clairière qui contient ce point, adoucissement compris, ou -1 s'il
## n'y en a aucune. La plus proche l'emporte quand deux se chevauchent.
##
## Un index plutôt qu'un centre : renvoyer « un Vector2 ou rien » impose un
## `Variant`, que l'inférence de type refuse.
func _clearing_index(clearings: PackedVector3Array, nearby: PackedInt32Array, point: Vector2) -> int:
	var found := -1
	var closest := INF
	for i in nearby:
		var dist := point.distance_to(Vector2(clearings[i].x, clearings[i].y))
		if dist < clearings[i].z + _cfg.clearing_falloff and dist < closest:
			closest = dist
			found = i
	return found


## Indices des segments de rivière dont le voisinage recoupe le chunk.
func _river_segments_near(river: PackedVector2Array, area: Rect2, margin: float) -> PackedInt32Array:
	var found := PackedInt32Array()
	var grown := area.grow(margin)
	for i in maxi(river.size() - 1, 0):
		if grown.intersects(Rect2(river[i], Vector2.ZERO).expand(river[i + 1]).grow(margin)):
			found.append(i)
	return found


func _is_in_river(river: PackedVector2Array, segments: PackedInt32Array, point: Vector2, margin: float) -> bool:
	for i in segments:
		var a := river[i]
		var ab := river[i + 1] - a
		var length_squared := ab.length_squared()
		if length_squared < 1e-6:
			continue
		var t := clampf((point - a).dot(ab) / length_squared, 0.0, 1.0)
		if point.distance_to(a + ab * t) < margin:
			return true
	return false


func _slope_at(cfg: TerrainGenConfig, heights: PackedFloat32Array, point: Vector2) -> float:
	var e := cfg.cell_size
	var dx := cfg.sample_height(heights, point + Vector2(e, 0.0)) - cfg.sample_height(heights, point - Vector2(e, 0.0))
	var dz := cfg.sample_height(heights, point + Vector2(0.0, e)) - cfg.sample_height(heights, point - Vector2(0.0, e))
	return rad_to_deg(atan(Vector2(dx, dz).length() / (2.0 * e)))


## Repère d'un objet couché dans la pente. `amount` dose entre la verticale et
## la normale du terrain : un rocher l'épouse presque, un tronc pas du tout.
func _slope_basis(cfg: TerrainGenConfig, heights: PackedFloat32Array, point: Vector2,
		amount: float) -> Basis:
	var e := cfg.cell_size
	var dx := cfg.sample_height(heights, point + Vector2(e, 0.0)) - cfg.sample_height(heights, point - Vector2(e, 0.0))
	var dz := cfg.sample_height(heights, point + Vector2(0.0, e)) - cfg.sample_height(heights, point - Vector2(0.0, e))
	var normal := Vector3(-dx, 2.0 * e, -dz).normalized()
	var up := Vector3.UP.lerp(normal, amount).normalized()
	# Repère orthonormé construit sur cette verticale locale. L'axe de départ ne
	# peut pas être colinéaire à `up` : le terrain venant d'une heightmap, sa
	# normale a toujours une composante verticale, donc X fait un pivot sûr.
	var forward := Vector3.RIGHT.cross(up).normalized()
	return Basis(up.cross(forward), up, forward)


## Enfoncement d'un modèle sous la hauteur lue à son centre. Il grandit avec la
## pente parce que la base d'un modèle est un disque : plus le sol penche, plus
## son bord aval s'écarte du point de mesure. C'est donc **le rayon de la base**
## qui commande, pas la profondeur à plat — un bloc large décolle bien davantage
## qu'une touffe d'herbe sur la même pente. Ce qui s'aligne sur la pente n'a
## presque plus besoin de correction : son bord ne se soulève plus.
func _sink(def: FoliageDef, slope_degrees: float) -> float:
	var lift := def.base_radius * tan(deg_to_rad(minf(slope_degrees, 60.0)))
	return def.embed_depth + lift * (1.0 - def.align_to_slope)


# --- Construction des nœuds ----------------------------------------------------

## Un nœud par chunk, contenant les multimeshes de toutes les strates. Les
## essences y arrivent dans l'ordre de semis : un `Dictionary` GDScript conserve
## l'ordre d'insertion, donc la sortie est déterministe.
func _build_chunk_node(cfg: TerrainGenConfig, placements: Dictionary, cx: int, cz: int) -> Node3D:
	var chunk := Node3D.new()
	chunk.name = "foliage_%d_%d" % [cx, cz]
	for def: FoliageDef in placements:
		for part in _parts_of(def):
			chunk.add_child(_build_multimesh(cfg, def, part, placements[def]))
	return chunk


func _build_multimesh(cfg: TerrainGenConfig, def: FoliageDef, part: Part, transforms: Array) -> MultiMeshInstance3D:
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = part.mesh
	multimesh.instance_count = transforms.size()
	for i in transforms.size():
		multimesh.set_instance_transform(i, transforms[i] * part.offset)

	var node := MultiMeshInstance3D.new()
	node.name = String(def.id)
	node.multimesh = multimesh
	# La portée est portée par le chunk : sa boîte englobante fait 96 m, ce qui
	# suffit comme granularité pour que l'effacement ne se voie pas.
	node.visibility_range_end = cfg.foliage_view_distance
	node.visibility_range_end_margin = cfg.foliage_fade_margin
	if cfg.foliage_fade_margin > 0.0:
		node.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
	return node


## Extrait les meshes d'un modèle, une fois pour toutes. Les matériaux posés en
## surcharge de surface sur le `MeshInstance3D` sont recopiés dans le mesh : un
## multimesh ne connaît que les matériaux du mesh lui-même.
func _parts_of(def: FoliageDef) -> Array:
	if _parts_cache.has(def.id):
		return _parts_cache[def.id]

	var parts: Array = []
	var scene := def.model.instantiate()
	for node in _all_mesh_instances(scene):
		if node.mesh == null:
			continue
		var mesh: Mesh = node.mesh.duplicate()
		for surface in mesh.get_surface_count():
			var override := node.get_surface_override_material(surface)
			if override != null:
				mesh.surface_set_material(surface, override)
		var part := Part.new()
		part.mesh = mesh
		part.offset = _local_transform(node, scene)
		parts.append(part)
	scene.free()

	if parts.is_empty():
		push_warning("FoliageScatter : aucun mesh trouvé dans le modèle de « %s »." % def.id)
	_parts_cache[def.id] = parts
	return parts


func _all_mesh_instances(node: Node) -> Array[MeshInstance3D]:
	var found: Array[MeshInstance3D] = []
	if node is MeshInstance3D:
		found.append(node)
	for child in node.get_children():
		found.append_array(_all_mesh_instances(child))
	return found


## Transformée d'un nœud relative à la racine de sa scène — les modèles en
## plusieurs morceaux ne sont assemblés que par ces décalages.
func _local_transform(node: Node3D, root: Node) -> Transform3D:
	var result := Transform3D.IDENTITY
	var current := node
	while current != null and current != root:
		result = current.transform * result
		current = current.get_parent() as Node3D
	return result
