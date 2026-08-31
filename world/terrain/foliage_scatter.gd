@tool
class_name FoliageScatter
extends RefCounted
## Peuple le terrain à partir de `FoliageDef`, en `MultiMeshInstance3D` par chunk.
##
## Répartition : une grille jitterée, un candidat par cellule, accepté ou rejeté
## selon la pente, l'eau et les clairières. Pas de poisson-disque — à quarante
## mille arbres il coûterait cher pour un résultat que l'œil ne distingue pas
## une fois les troncs posés.
##
## **Peuplements.** Une forêt réelle pousse par bosquets d'une même espèce. Le
## poids de chaque essence est donc modulé, *en chaque point*, par un bruit qui
## lui est propre : au cœur d'un peuplement une seule domine, sur ses bords le
## mélange se fait. Le choix se fait au point et jamais au chunk — sélectionner
## quelques essences par chunk paraissait équivalent et ne l'est pas : là où deux
## chunks voisins ne retiennent pas les mêmes, la couture est une ligne droite,
## et la grille se voit dans la canopée.
##
## Le gain de performance vient de la même mécanique : au cœur d'un peuplement,
## les autres essences ne sont jamais tirées, donc leur multimesh n'existe pas.
##
## Découpage par chunk, calé sur celui du terrain : c'est ce qui permettra de ne
## dessiner que le visible, de couper l'ombre au loin, puis de basculer les
## arbres proches en instances abattables sans toucher au reste de la carte.
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
## Métadonnée portant l'emprise au sol d'un chunk de feuillage.
const CHUNK_AREA_META := &"chunk_area"
## Décalage d'échantillonnage entre deux essences : elles lisent le même bruit à
## des endroits assez éloignés pour que leurs champs soient indépendants.
const _STAND_SPREAD := Vector2(977.0, -613.0)

## Une partie de modèle : son mesh et sa position dans la scène d'origine.
class Part:
	var mesh: Mesh
	var offset: Transform3D

var _parts_cache: Dictionary = {}
## Nombre d'instances effectivement posées, pour le compte-rendu de génération.
var placed_count: int = 0


## Construit tout le feuillage. Retourne un Node3D à parenter dans la scène.
func scatter(cfg: TerrainGenConfig, heights: PackedFloat32Array, clearings: PackedVector3Array,
		river: PackedVector2Array, water_level: float) -> Node3D:
	placed_count = 0
	var root := Node3D.new()
	var defs := _usable_defs(cfg.canopy)
	if defs.is_empty():
		push_warning("FoliageScatter : la liste d'essences de canopée est vide ou inexploitable — rien à semer.")
		return root

	var stands: FastNoiseLite = cfg.stand_noise.duplicate() if cfg.stand_noise != null else FastNoiseLite.new()
	stands.seed = cfg.world_seed + _SEED_STAND

	var side := cfg.chunks_per_side()
	for cz in side:
		for cx in side:
			var chunk := _scatter_chunk(cfg, heights, clearings, river, water_level, defs, stands, cx, cz)
			if chunk != null:
				root.add_child(chunk)
	return root


func _usable_defs(source: Array[FoliageDef]) -> Array[FoliageDef]:
	var defs: Array[FoliageDef] = []
	for def in source:
		if def == null or def.model == null:
			push_warning("FoliageScatter : essence sans modèle, ignorée.")
			continue
		defs.append(def)
	return defs


# --- Peuplements ---------------------------------------------------------------

## Poids local de chaque essence : son poids propre, modulé par son champ de
## peuplement élevé à la netteté demandée.
##
## Le tableau est *retourné* et non rempli par référence : un `PackedFloat32Array`
## passé en argument est une valeur à copie sur écriture, et l'appelant ne verrait
## jamais les valeurs écrites dedans.
func _stand_weights(cfg: TerrainGenConfig, defs: Array[FoliageDef], stands: FastNoiseLite,
		point: Vector2) -> PackedFloat32Array:
	var weights := PackedFloat32Array()
	weights.resize(defs.size())
	for i in defs.size():
		var field := 0.5 + 0.5 * stands.get_noise_2dv(point + _STAND_SPREAD * float(i))
		weights[i] = defs[i].weight * pow(maxf(field, 0.001), cfg.stand_sharpness)
	return weights


# --- Répartition ---------------------------------------------------------------

func _scatter_chunk(cfg: TerrainGenConfig, heights: PackedFloat32Array, clearings: PackedVector3Array,
		river: PackedVector2Array, water_level: float, defs: Array[FoliageDef],
		stands: FastNoiseLite, cx: int, cz: int) -> Node3D:
	var half := cfg.half_size()
	var area := cfg.chunk_area(cx, cz)
	var origin := area.position
	var chunk_span := area.size.x
	var spacing := cfg.foliage_spacing

	var rng := RandomNumberGenerator.new()
	rng.seed = cfg.world_seed + cx * _CHUNK_SEED_X + cz * _CHUNK_SEED_Z

	# Grille globale, parcourue sur la seule portion qui tombe dans ce chunk : les
	# cellules ne dépendent pas du découpage. Les deux bornes s'arrondissent au
	# supérieur et la fin d'un chunk est le début du suivant — sinon, dès que
	# l'espacement ne divise pas la largeur d'un chunk, une colonne de cellules
	# se perd à chaque frontière et la grille de chunks se voit dans la canopée.
	var gx0 := int(ceil((origin.x + half) / spacing))
	var gz0 := int(ceil((origin.y + half) / spacing))
	var gx1 := int(ceil((origin.x + chunk_span + half) / spacing))
	var gz1 := int(ceil((origin.y + chunk_span + half) / spacing))

	# Le lit est écarté de la moitié de sa largeur plus sa berge : les arbres
	# s'arrêtent en haut de talus. On ne retient que les segments qui passent
	# dans ce chunk, sinon chaque candidat testerait tout le cours d'eau.
	var river_margin := cfg.river_width * 0.5 + cfg.river_bank
	var nearby := _river_segments_near(river, area, river_margin)

	var placements: Array[Array] = []
	placements.resize(defs.size())
	for i in defs.size():
		placements[i] = []

	for gz in range(gz0, gz1):
		for gx in range(gx0, gx1):
			var jitter := Vector2(rng.randf(), rng.randf()) * spacing * cfg.foliage_jitter
			var point := Vector2(-half + gx * spacing, -half + gz * spacing) + jitter
			if absf(point.x) >= half or absf(point.y) >= half:
				continue

			var height := cfg.sample_height(heights, point)
			if height < water_level + cfg.foliage_water_margin:
				continue
			if rng.randf() > _clearing_openness(cfg, clearings, point):
				continue
			if _is_in_river(river, nearby, point, river_margin):
				continue

			var weights := _stand_weights(cfg, defs, stands, point)
			var total_weight := 0.0
			for weight in weights:
				total_weight += weight
			if total_weight <= 0.0:
				continue
			var index := _pick_def(weights, rng.randf() * total_weight)
			var def: FoliageDef = defs[index]
			var slope := _slope_at(cfg, heights, point)
			if slope > def.max_slope_degrees:
				continue

			var basis := Basis.IDENTITY
			if def.random_yaw:
				basis = basis.rotated(Vector3.UP, rng.randf() * TAU)
			basis = basis.scaled(Vector3.ONE * rng.randf_range(def.scale_range.x, def.scale_range.y))
			placements[index].append(Transform3D(basis, Vector3(point.x, height - _sink(def, slope), point.y)))
			placed_count += 1

	return _build_chunk_node(cfg, defs, placements, area, cx, cz)


## Densité de canopée admise en ce point : nulle au cœur d'une clairière, pleine
## au-delà de son adoucissement. La lisière n'est pas dessinée, elle est le
## dégradé entre les deux.
func _clearing_openness(cfg: TerrainGenConfig, clearings: PackedVector3Array, point: Vector2) -> float:
	var openness := 1.0
	for clearing in clearings:
		var dist := point.distance_to(Vector2(clearing.x, clearing.y))
		openness = minf(openness, smoothstep(clearing.z, clearing.z + cfg.clearing_falloff, dist))
		if openness <= 0.0:
			return 0.0
	return openness


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


func _pick_def(weights: PackedFloat32Array, roll: float) -> int:
	var cursor := 0.0
	for i in weights.size():
		cursor += weights[i]
		if roll <= cursor:
			return i
	return weights.size() - 1


# --- Construction des nœuds ----------------------------------------------------

func _build_chunk_node(cfg: TerrainGenConfig, defs: Array[FoliageDef], placements: Array[Array],
		area: Rect2, cx: int, cz: int) -> Node3D:
	var chunk: Node3D = null
	for i in defs.size():
		var transforms: Array = placements[i]
		if transforms.is_empty():
			continue
		if chunk == null:
			chunk = Node3D.new()
			chunk.name = "foliage_%d_%d" % [cx, cz]
			# Emprise posée par celui qui la connaît. Tout ce qui raisonne par
			# distance la lit ici plutôt que de la redéduire d'une boîte
			# englobante ou du nom du nœud.
			chunk.set_meta(CHUNK_AREA_META, area)
		for part in _parts_of(defs[i]):
			chunk.add_child(_build_multimesh(cfg, defs[i], part, transforms))
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
