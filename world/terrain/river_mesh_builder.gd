@tool
class_name RiverMeshBuilder
extends RefCounted
## Construit la surface d'eau des cours d'eau : un ruban par bief.
##
## Le lac est un plan à altitude fixe ; un fleuve, non — sa surface descend d'un
## bout à l'autre. Il lui faut donc sa propre géométrie, et elle se déduit
## entièrement de ce que le générateur publie : le tracé donne la direction, la
## ligne d'eau donne l'altitude, la largeur donne l'écartement.
##
## **Le ruban s'arrête là où il plonge sous le niveau du lac.** En aval, le plan
## du lac couvre déjà la zone, et le shader d'eau est en `blend_mix` sans
## écriture de profondeur : deux surfaces superposées ne scintillent pas, elles
## s'assombrissent l'une l'autre. La jonction est invisible parce que les deux
## sont à la même altitude à l'endroit où elles se rencontrent — l'estuaire n'a
## pas à être dessiné, pas plus que le rivage du lac.
##
## Le ruban est subdivisé en travers : le shader déplace ses sommets pour faire
## les vagues, et un quad de deux sommets de large n'a rien à déplacer.

## Bandes dans la largeur. 4 suffisent pour que la vague se lise ; au-delà on
## paie des sommets pour un mouvement qui reste sous les cinq centimètres.
const CROSS_BANDS := 4
## Marge sous laquelle un bief est jugé trop court pour valoir un ruban.
const MIN_POINTS := 3


## Assemble tous les biefs dans un seul maillage. Un `MeshInstance3D` par bief
## multiplierait les objets de dessin pour une surface que le joueur voit d'un
## seul tenant.
## `shore_overlap` élargit le ruban au-delà du lit : le creusement adoucit ses
## berges sur cette distance, et une nappe limitée à la largeur du lit s'arrête
## au pied du talus en laissant un liseré de terre nue tout du long. C'est au
## shader de dessiner le rivage, pas à la géométrie de s'arrêter avant.
static func build(reaches: Array[RiverReach], lake_level: float, material: Material,
		shore_overlap: float) -> ArrayMesh:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var indices := PackedInt32Array()

	for reach in reaches:
		_append_reach(reach, lake_level, shore_overlap, vertices, normals, indices)

	if indices.is_empty():
		return null

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	# Pas de tableau de couleurs : le shader lit les couleurs de sommet comme des
	# zones de contrôle (écume, découpe, gel de l'animation) et attend du blanc
	# quand on ne peint rien. Ne pas en fournir, c'est demander le comportement
	# par défaut — en fournir du noir couperait la surface.

	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	if material != null:
		mesh.surface_set_material(0, material)
	return mesh


static func _append_reach(reach: RiverReach, lake_level: float, shore_overlap: float,
		vertices: PackedVector3Array, normals: PackedVector3Array, indices: PackedInt32Array) -> void:
	var last := _last_emerged(reach, lake_level)
	if last < MIN_POINTS - 1:
		return

	var base := vertices.size()
	for i in last + 1:
		# La normale au cours se prend sur ses deux voisins : au dernier point,
		# la prendre sur le segment précédent seul ferait pivoter le ruban.
		var previous := reach.path[maxi(i - 1, 0)]
		var next := reach.path[mini(i + 1, last)]
		var tangent := (next - previous).normalized()
		var across := Vector2(-tangent.y, tangent.x) * (reach.widths[i] * 0.5 + shore_overlap)
		var level := reach.water[i]
		for band in CROSS_BANDS + 1:
			var t := float(band) / float(CROSS_BANDS) * 2.0 - 1.0
			var p := reach.path[i] + across * t
			vertices.append(Vector3(p.x, level, p.y))
			normals.append(Vector3.UP)

	var stride := CROSS_BANDS + 1
	for i in last:
		for band in CROSS_BANDS:
			var a := base + i * stride + band
			var b := a + 1
			var c := a + stride
			var d := c + 1
			indices.append_array([a, b, c, b, d, c])


## Dernier point du bief encore au-dessus du lac. En dessous, la surface du lac
## prend le relais.
static func _last_emerged(reach: RiverReach, lake_level: float) -> int:
	for i in reach.path.size():
		if reach.water[i] <= lake_level:
			return i - 1
	return reach.path.size() - 1
