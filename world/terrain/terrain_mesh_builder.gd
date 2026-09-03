@tool
class_name TerrainMeshBuilder
extends RefCounted
## Transforme le tableau de hauteurs en chunks affichables et solides.
##
## Un chunk = un StaticBody3D portant son MeshInstance3D et sa collision. Le
## découpage n'est pas cosmétique : c'est lui qui rendra possible le LOD de
## végétation et la régénération partielle (piétinement) sans toucher au reste.
##
## Les normales sont calculées par différences centrées sur le tableau global,
## pas sur les faces du chunk : deux chunks voisins lisent les mêmes sommets et
## se raccordent donc sans couture, sans code de recollement.
##
## La couleur de sommet porte la **couverture végétale** (canal rouge), lue sur
## la carte d'ouverture que le semis vient de remplir. C'est ce qui met de la
## litière sous les arbres et de l'herbe dans les trouées, et ce qui fait qu'une
## clairière lointaine existe comme une tache claire plutôt que comme un rond de
## sol nu. Le mesh se construit donc **après** le semis : le sol se colore de ce
## qui pousse dessus. Les biomes viendront s'ajouter dans les autres canaux.

## Construit un chunk, ou null si le découpage ne laisse rien à construire à
## ces coordonnées (dernier chunk d'une grille non multiple de chunk_cells).
static func build_chunk(cfg: TerrainGenConfig, heights: PackedFloat32Array,
		occupancy: ScatterOccupancy, cx: int, cz: int, material: Material) -> StaticBody3D:
	var cells := cfg.cell_count()
	var x0 := cx * cfg.chunk_cells
	var z0 := cz * cfg.chunk_cells
	var x1 := mini(x0 + cfg.chunk_cells, cells)
	var z1 := mini(z0 + cfg.chunk_cells, cells)
	if x0 >= x1 or z0 >= z1:
		return null

	var wide := x1 - x0 + 1
	var deep := z1 - z0 + 1
	var origin := cfg.world_pos(x0, z0)

	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var colors := PackedColorArray()
	vertices.resize(wide * deep)
	normals.resize(wide * deep)
	uvs.resize(wide * deep)
	colors.resize(wide * deep)

	for iz in range(z0, z1 + 1):
		for ix in range(x0, x1 + 1):
			var local := (iz - z0) * wide + (ix - x0)
			var wp := cfg.world_pos(ix, iz)
			var h := heights[cfg.height_index(ix, iz)]
			vertices[local] = Vector3(wp.x - origin.x, h, wp.y - origin.y)
			normals[local] = _normal_at(cfg, heights, ix, iz)
			uvs[local] = wp * cfg.uv_scale
			colors[local] = Color(occupancy.cover_at(wp), 0.0, 0.0, 1.0)

	var indices := PackedInt32Array()
	indices.resize((wide - 1) * (deep - 1) * 6)
	var cursor := 0
	for iz in deep - 1:
		for ix in wide - 1:
			var a := iz * wide + ix
			var b := a + 1
			var c := a + wide
			var d := c + 1
			# Godot considère front-facing les triangles en sens horaire :
			# cet ordre-là donne des faces tournées vers le ciel.
			indices[cursor] = a
			indices[cursor + 1] = b
			indices[cursor + 2] = c
			indices[cursor + 3] = b
			indices[cursor + 4] = d
			indices[cursor + 5] = c
			cursor += 6

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices

	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	if material != null:
		mesh.surface_set_material(0, material)

	var body := StaticBody3D.new()
	body.name = "chunk_%d_%d" % [cx, cz]
	body.position = Vector3(origin.x, 0.0, origin.y)

	var visual := MeshInstance3D.new()
	visual.name = "Mesh"
	visual.mesh = mesh
	body.add_child(visual)

	var collision := CollisionShape3D.new()
	collision.name = "Collision"
	collision.shape = mesh.create_trimesh_shape()
	body.add_child(collision)

	return body


## Normale d'un sommet, par différences centrées sur les hauteurs voisines.
static func _normal_at(cfg: TerrainGenConfig, heights: PackedFloat32Array, ix: int, iz: int) -> Vector3:
	var last := cfg.cell_count()
	var left := heights[cfg.height_index(maxi(ix - 1, 0), iz)]
	var right := heights[cfg.height_index(mini(ix + 1, last), iz)]
	var back := heights[cfg.height_index(ix, maxi(iz - 1, 0))]
	var front := heights[cfg.height_index(ix, mini(iz + 1, last))]
	return Vector3(left - right, 2.0 * cfg.cell_size, back - front).normalized()
