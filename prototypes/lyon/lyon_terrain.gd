@tool
class_name LyonTerrain
extends Node3D

## Terrain de test bâti sur une carte de hauteurs réelle (MNT Grand Lyon).
##
## Prototype isolé : il ne partage rien avec `world/terrain/`, ne génère rien,
## ne sème rien. Il transforme une grille d'altitudes en meshes et en collision,
## et c'est tout. Le but est de MARCHER sur la topographie lyonnaise pour la
## juger — l'habillage viendra si et seulement si la carte convainc.
##
## Repère : (0, 0) est le coin sud-ouest, +X vers l'est, +Z vers le nord.
## L'altitude 0 du monde correspond au point le plus bas de la carte.

const CHUNK_CELLS: int = 128

@export_file("*.f32") var heightmap_path: String = "res://prototypes/lyon/data/B_deux_collines.f32":
	set(value):
		heightmap_path = value
		if is_inside_tree():
			rebuild()

## Altitude ABSOLUE du plan d'eau, en mètres NGF. La Saône est à ~162,2 m.
@export var water_altitude_m: float = 162.4:
	set(value):
		water_altitude_m = value
		if is_inside_tree():
			rebuild()

@export var build_collision: bool = true

var map: LyonHeightmap = null

var _chunk_root: Node3D = null
var _water: MeshInstance3D = null


func _ready() -> void:
	rebuild()


## Reconstruit tout le terrain. Les nœuds produits n'ont pas d'owner : ils ne
## sont jamais sérialisés dans le .tscn, comme le terrain procédural du projet.
func rebuild() -> void:
	_clear()

	var base_path: String = heightmap_path.get_basename()
	map = LyonHeightmap.load_pair(base_path)
	if map == null:
		return

	_chunk_root = Node3D.new()
	_chunk_root.name = "Chunks"
	add_child(_chunk_root)

	var material: StandardMaterial3D = _make_material()
	var chunks_x: int = ceili(float(map.cols - 1) / float(CHUNK_CELLS))
	var chunks_z: int = ceili(float(map.rows - 1) / float(CHUNK_CELLS))

	for cz: int in range(chunks_z):
		for cx: int in range(chunks_x):
			var col0: int = cx * CHUNK_CELLS
			var row0: int = cz * CHUNK_CELLS
			var col1: int = mini(col0 + CHUNK_CELLS, map.cols - 1)
			var row1: int = mini(row0 + CHUNK_CELLS, map.rows - 1)
			_build_chunk(col0, row0, col1, row1, material)

	_build_water()

	print("[LyonTerrain] %d x %d sommets · %.0f x %.0f m · amplitude %.1f m · %d chunks"
			% [map.cols, map.rows, map.width_m, map.depth_m, map.amplitude_m,
			   chunks_x * chunks_z])


## Altitude du sol au-dessus du zéro monde, en coordonnées locales du terrain.
func ground_height(local_x: float, local_z: float) -> float:
	if map == null:
		return 0.0
	return map.height_at(local_x, local_z) - map.alt_min


func _clear() -> void:
	for child: Node in get_children():
		child.queue_free()
	_chunk_root = null
	_water = null


func _make_material() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.95
	mat.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	return mat


func _build_chunk(col0: int, row0: int, col1: int, row1: int,
		material: StandardMaterial3D) -> void:
	var n_cols: int = col1 - col0 + 1
	var n_rows: int = row1 - row0 + 1
	if n_cols < 2 or n_rows < 2:
		return

	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()
	verts.resize(n_cols * n_rows)
	normals.resize(n_cols * n_rows)
	colors.resize(n_cols * n_rows)

	var cell: float = map.cell_size
	for r: int in range(n_rows):
		for c: int in range(n_cols):
			var col: int = col0 + c
			var row: int = row0 + r
			var h: float = map.height_at_vertex(col, row) - map.alt_min
			var i: int = r * n_cols + c
			verts[i] = Vector3(float(col) * cell, h, float(row) * cell)

			# Normale par différences centrées sur la grille source : exacte
			# aux bords de chunk, donc pas de couture d'éclairage.
			var hx: float = map.height_at_vertex(col + 1, row) - map.height_at_vertex(col - 1, row)
			var hz: float = map.height_at_vertex(col, row + 1) - map.height_at_vertex(col, row - 1)
			var normal := Vector3(-hx, 2.0 * cell, -hz).normalized()
			normals[i] = normal
			colors[i] = _shade(h, normal)

	# Godot considère front-facing les triangles en sens horaire :
	# pour une grille XZ vue du dessus, (x,z) → (x+1,z) → (x,z+1).
	var indices := PackedInt32Array()
	indices.resize((n_cols - 1) * (n_rows - 1) * 6)
	var k: int = 0
	for r: int in range(n_rows - 1):
		for c: int in range(n_cols - 1):
			var i00: int = r * n_cols + c
			var i10: int = i00 + 1
			var i01: int = i00 + n_cols
			var i11: int = i01 + 1
			indices[k] = i00; indices[k + 1] = i10; indices[k + 2] = i01
			indices[k + 3] = i10; indices[k + 4] = i11; indices[k + 5] = i01
			k += 6

	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices

	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

	var instance := MeshInstance3D.new()
	instance.name = "Chunk_%d_%d" % [col0, row0]
	instance.mesh = mesh
	instance.material_override = material
	_chunk_root.add_child(instance)

	if build_collision:
		# Trimesh plutôt que HeightMapShape3D : ce dernier échantillonne à
		# 1 unité fixe et imposerait une mise à l'échelle non uniforme.
		var body := StaticBody3D.new()
		var shape := CollisionShape3D.new()
		var concave := ConcavePolygonShape3D.new()
		var faces := PackedVector3Array()
		faces.resize(indices.size())
		for j: int in range(indices.size()):
			faces[j] = verts[indices[j]]
		concave.set_faces(faces)
		shape.shape = concave
		body.add_child(shape)
		instance.add_child(body)


## Teinte de lecture : rampe d'altitude, assombrie par la pente.
## Aucune prétention esthétique — il s'agit de lire le relief sans texture.
func _shade(height: float, normal: Vector3) -> Color:
	var t: float = clampf(height / maxf(map.amplitude_m, 1.0), 0.0, 1.0)
	var low := Color(0.42, 0.53, 0.31)
	var mid := Color(0.62, 0.57, 0.36)
	var high := Color(0.72, 0.70, 0.66)
	var base: Color = low.lerp(mid, smoothstep(0.0, 0.55, t)).lerp(high, smoothstep(0.55, 1.0, t))
	var steepness: float = 1.0 - clampf(normal.y, 0.0, 1.0)
	return base.darkened(steepness * 0.55)


func _build_water() -> void:
	var level: float = water_altitude_m - map.alt_min
	if level <= 0.0:
		return
	var plane := PlaneMesh.new()
	# Débordement volontaire : la rive est ce qui dépasse, elle ne se dessine pas.
	plane.size = Vector2(map.width_m * 1.2, map.depth_m * 1.2)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.16, 0.34, 0.45, 0.78)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.roughness = 0.12
	plane.material = mat

	_water = MeshInstance3D.new()
	_water.name = "Water"
	_water.mesh = plane
	_water.position = Vector3(map.width_m * 0.5, level, map.depth_m * 0.5)
	add_child(_water)
