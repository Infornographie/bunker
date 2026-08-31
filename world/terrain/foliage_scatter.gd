@tool
class_name FoliageScatter
extends RefCounted
## Peuple le terrain à partir de `FoliageLayer`, en `MultiMeshInstance3D` par chunk.
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
## `FoliagePatch` d'une strate remplacent sa palette entière là où leur bruit
## dépasse un seuil. C'est la différence entre un endroit et un saupoudrage.
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
## Nombre d'instances effectivement posées, pour le compte-rendu de génération.
var placed_count: int = 0
## Compte par strate, dans l'ordre de semis. C'est le chiffre qu'on regarde pour
## régler un espacement : un total global ne dit pas quelle strate a débordé.
var placed_per_layer: Array[int] = []
## Ce que le semis a posé et l'ombre qu'il porte. Publié parce que les strates
## streamées et la couleur du sol le lisent.
var occupancy: ScatterOccupancy
## Nœud de chaque chunk, par coordonnées de grille. C'est là que les strates
## streamées viennent s'accrocher et se détacher.
var chunk_nodes: Dictionary = {}

# Contexte de la carte courante, retenu pour pouvoir semer un chunk plus tard.
# Ce `RefCounted` porte donc un état : c'est le prix du semis à la demande, et
# il vit aussi longtemps que le terrain qu'il a produit.
var _cfg: TerrainGenConfig
var _heights: PackedFloat32Array
var _clearings: PackedVector3Array
var _river: PackedVector2Array
var _water_level: float


## Construit tout le feuillage. Retourne un Node3D à parenter dans la scène.
func scatter(cfg: TerrainGenConfig, heights: PackedFloat32Array, clearings: PackedVector3Array,
		river: PackedVector2Array, water_level: float) -> Node3D:
	_cfg = cfg
	_heights = heights
	_clearings = clearings
	_river = river
	_water_level = water_level
	placed_count = 0
	chunk_nodes.clear()
	# Dimensionné sur la liste de strates et non rempli au fil de l'eau : une
	# strate ignorée décalerait tous les comptes suivants.
	placed_per_layer.clear()
	placed_per_layer.resize(cfg.layers.size())
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
			push_warning("FoliageScatter : strate « %s » sans essence exploitable." % layer.id)
			continue
		var before := placed_count
		for cz in side:
			for cx in side:
				# Le dictionnaire est passé pour être rempli : contrairement aux
				# `Packed*Array`, il est bien une référence.
				_scatter_chunk(layer, palettes, index, cx, cz, null, harvest[cz * side + cx])
		placed_per_layer[index] = placed_count - before

	# Un nœud est créé même vide dès qu'une strate est streamée : il faut un
	# point d'accrochage pour l'herbe qui arrivera plus tard, y compris au
	# milieu d'une clairière où rien de permanent n'a poussé.
	var keep_empty := _has_streamed_layers()
	for cz in side:
		for cx in side:
			var placements: Dictionary = harvest[cz * side + cx]
			if placements.is_empty() and not keep_empty:
				continue
			var chunk := _build_chunk_node(cfg, placements, cx, cz)
			root.add_child(chunk)
			chunk_nodes[Vector2i(cx, cz)] = chunk
	return root


func _has_streamed_layers() -> bool:
	for layer in _cfg.layers:
		if layer != null and layer.streamed:
			return true
	return false


## Sème les strates streamées d'un chunk. Le nœud retourné est à parenter par
## l'appelant, qui le libérera quand le chunk s'éloignera.
##
## L'occupation permanente est **lue** et jamais écrite : sans quoi un
## aller-retour du joueur laisserait le sol marqué par une herbe disparue, et le
## même chunk ne donnerait pas deux fois la même chose. Les plantes de la strate
## ne se gênent qu'entre elles, dans une grille locale jetée avec le nœud.
func stream_chunk(cx: int, cz: int) -> Node3D:
	var area := _cfg.chunk_area(cx, cz)
	var local := ScatterOccupancy.new(_cfg.occupancy_cell_size, area)
	var placements: Dictionary = {}
	for index in _cfg.layers.size():
		var layer: FoliageLayer = _cfg.layers[index]
		if layer == null or not layer.streamed:
			continue
		var palettes := _palettes_of(layer, index)
		if palettes.is_empty():
			continue
		_scatter_chunk(layer, palettes, index, cx, cz, local, placements)
	var node := Node3D.new()
	node.name = "streamed"
	for def: FoliageDef in placements:
		for part in _parts_of(def):
			node.add_child(_build_multimesh(_cfg, def, part, placements[def]))
	return node


func _usable_defs(source: Array[FoliageDef], owner: StringName) -> Array[FoliageDef]:
	var defs: Array[FoliageDef] = []
	for def in source:
		if def == null or def.model == null:
			push_warning("FoliageScatter : essence sans modèle dans « %s », ignorée." % owner)
			continue
		defs.append(def)
	return defs


# --- Peuplements ---------------------------------------------------------------

## Palettes d'une strate, taches d'abord puis composition de base. L'ordre est
## celui du test : la première qui répond l'emporte.
func _palettes_of(layer: FoliageLayer, layer_index: int) -> Array[Palette]:
	var built: Array[Palette] = []
	for index in layer.patches.size():
		var patch: FoliagePatch = layer.patches[index]
		if patch == null:
			continue
		var palette := _palette(_usable_defs(patch.defs, layer.id), patch.noise,
				layer.stand_blend, layer_index, index + 1)
		if palette == null:
			push_warning("FoliageScatter : tache « %s » sans essence exploitable." % patch.id)
			continue
		palette.gate = patch.noise.duplicate() if patch.noise != null else FastNoiseLite.new()
		palette.gate.seed = _cfg.world_seed + _SEED_PATCH * (index + 1)
		palette.threshold = patch.threshold
		palette.density = patch.density
		palette.min_slope = patch.min_slope_degrees
		palette.max_slope = patch.max_slope_degrees
		built.append(palette)
	var base := _palette(_usable_defs(layer.defs, layer.id), layer.stand_noise,
			layer.stand_blend, layer_index, 0)
	if base != null:
		built.append(base)
	return built


## Construit une roue de secteurs cumulés. Le calcul se fait une fois par strate
## et non par candidat : c'est ce qui rend le tirage gratuit.
func _palette(defs: Array[FoliageDef], noise: FastNoiseLite, blend: float,
		layer_index: int, salt: int) -> Palette:
	if defs.is_empty():
		return null
	var total := 0.0
	for def in defs:
		total += maxf(def.weight, 0.0)
	if total <= 0.0:
		return null
	var palette := Palette.new()
	palette.defs = defs
	palette.blend = blend
	palette.noise = noise.duplicate() if noise != null else null
	if palette.noise != null:
		palette.noise.seed = _cfg.world_seed + _SEED_STAND + layer_index * _SEED_LAYER + salt * 7919
	palette.wheel.resize(defs.size())
	var cursor := 0.0
	for i in defs.size():
		cursor += maxf(defs[i].weight, 0.0) / total
		palette.wheel[i] = cursor
	return palette


# --- Répartition ---------------------------------------------------------------

func _scatter_chunk(layer: FoliageLayer, palettes: Array[Palette],
		layer_index: int, cx: int, cz: int, local: ScatterOccupancy, into: Dictionary) -> void:
	var cfg := _cfg
	var heights := _heights
	var clearings := _clearings
	var river := _river
	var water_level := _water_level
	var half := cfg.half_size()
	var area := cfg.chunk_area(cx, cz)
	var origin := area.position
	var chunk_span := area.size.x
	var spacing := layer.spacing

	var rng := RandomNumberGenerator.new()
	rng.seed = cfg.world_seed + cx * _CHUNK_SEED_X + cz * _CHUNK_SEED_Z + layer_index * _SEED_LAYER

	# Grille globale, parcourue sur la seule portion qui tombe dans ce chunk : les
	# cellules ne dépendent pas du découpage. Les deux bornes s'arrondissent au
	# supérieur et la fin d'un chunk est le début du suivant — sinon, dès que
	# l'espacement ne divise pas la largeur d'un chunk, une colonne de cellules
	# se perd à chaque frontière et la grille de chunks se voit dans la canopée.
	var gx0 := int(ceil((origin.x + half) / spacing))
	var gz0 := int(ceil((origin.y + half) / spacing))
	var gx1 := int(ceil((origin.x + chunk_span + half) / spacing))
	var gz1 := int(ceil((origin.y + chunk_span + half) / spacing))

	# Le lit est écarté de la moitié de sa largeur plus sa berge : les plantes
	# s'arrêtent en haut de talus. On ne retient que les segments qui passent
	# dans ce chunk, sinon chaque candidat testerait tout le cours d'eau.
	var river_margin := cfg.river_width * 0.5 + cfg.river_bank
	var nearby := _river_segments_near(river, area, river_margin)

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
			var openness := _clearing_openness(cfg, clearings, point)
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
				var index := _clearing_index(clearings, point)
				if index >= 0:
					sample = Vector2(clearings[index].x, clearings[index].y)
					uniform = true

			# La première palette qui couvre le point l'emporte : une tache
			# remplace la composition, elle ne s'y ajoute pas.
			# La pente est lue au point d'échantillonnage : au centre d'une
			# clairière quand elle est uniforme, sinon sous nos pieds.
			var gate_slope := slope if not uniform else _slope_at(cfg, heights, sample)
			var palette: Palette = null
			for candidate in palettes:
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
			if def.random_yaw:
				basis = basis.rotated(Vector3.UP, rng.randf() * TAU)
			basis = basis.scaled(Vector3.ONE * rng.randf_range(def.scale_range.x, def.scale_range.y))
			if not into.has(def):
				into[def] = []
			into[def].append(Transform3D(basis, Vector3(point.x, height - _sink(def, slope), point.y)))
			if local != null:
				local.mark(point, def.base_radius, 0.0, 0.0)
			else:
				occupancy.mark(point, def.base_radius, def.cover_radius, def.cover_amount)
			placed_count += 1


## Part de végétation ligneuse admise en ce point : nulle au cœur d'une
## clairière, pleine au-delà de son adoucissement. La lisière n'est pas
## dessinée, elle est le dégradé entre les deux. Chaque strate y est sensible à
## hauteur de son `clearing_effect`.
func _clearing_openness(cfg: TerrainGenConfig, clearings: PackedVector3Array, point: Vector2) -> float:
	var openness := 1.0
	for clearing in clearings:
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
func _clearing_index(clearings: PackedVector3Array, point: Vector2) -> int:
	var found := -1
	var closest := INF
	for i in clearings.size():
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


## Enfoncement d'un modèle sous la hauteur lue à son centre. Il grandit avec la
## pente parce que la base d'un tronc est un disque : plus le sol penche, plus
## son bord aval s'écarte du point de mesure. La tangente est bornée, sinon une
## essence autorisée en forte pente décollerait vers le bas.
func _sink(def: FoliageDef, slope_degrees: float) -> float:
	return def.embed_depth * (1.0 + tan(deg_to_rad(minf(slope_degrees, 60.0))))


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
