@tool
class_name TerrainController
extends Node3D
## Orchestrateur du terrain : seul point d'entrée de la scène vers la génération.
##
## Il ne calcule rien lui-même — il enchaîne heightmap puis chunks, et publie ce
## que le reste du jeu a besoin de savoir du terrain (aujourd'hui : où s'ouvre
## la grotte du bunker).
##
## Les nœuds générés n'ont volontairement pas d'owner : ils n'existent qu'en
## mémoire, ne sont jamais sérialisés dans le .tscn, et ne partent donc pas dans
## le dépôt. Le terrain se régénère, il ne se sauvegarde pas.

const CHUNKS_NODE := "Chunks"
const CAVE_NODE := "CaveSite"
const WATER_NODE := "Water"
const RIVER_NODE := "River"
## Subdivisions du plan du lac, par côté. Assez pour que la houle du shader se
## lise sur toute la nappe, pas au point de payer des sommets pour un
## déplacement qui reste sous les cinq centimètres.
const LAKE_SUBDIVISIONS := 64
const FOLIAGE_NODE := "Foliage"
const PROXIMITY_NODE := "Proximity"

## Hauteurs de la carte courante, publiées pour tout ce qui a besoin de savoir
## où est le sol : `TerrainGenConfig.sample_height()` les interroge.
var heights: PackedFloat32Array

@export var config: TerrainGenConfig
## Soleil de la scène. `FoliageProximity` y lit la portée des ombres et la
## direction d'éclairage pour trier les chunks qui projettent une ombre utile.
@export var sun: DirectionalLight3D

@export_tool_button("Régénérer") var regenerate_action: Callable = generate
@export_tool_button("Effacer") var clear_action: Callable = clear


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	generate()


## Exemplaire de travail du matériau de sol, renseigné des grandeurs tirées à la
## graine. La ressource de config n'est jamais modifiée — même règle que les
## bruits dupliqués du générateur de relief.
func _ground_material(water_level: float) -> Material:
	if config.terrain_material == null:
		return null
	var material := config.terrain_material.duplicate()
	var shader_material := material as ShaderMaterial
	if shader_material != null:
		shader_material.set_shader_parameter("water_level", water_level)
	return material


func generate() -> void:
	if config == null:
		push_warning("TerrainController : aucun TerrainGenConfig assigné, rien à générer.")
		return

	var started := Time.get_ticks_msec()
	clear()

	var heightmap := HeightmapGenerator.new()
	heightmap.generate(config)
	heights = heightmap.heights

	# Un seul plan pour toute l'eau : le rivage n'est pas dessiné, il est ce qui
	# dépasse. Le lac déborde de la zone parce que le plan est plus large qu'elle.
	var water := MeshInstance3D.new()
	water.name = WATER_NODE
	var surface := PlaneMesh.new()
	surface.size = Vector2(config.size_meters, config.size_meters) * 1.6
	# Le shader d'eau fait ses vagues en déplaçant les sommets : un plan à quatre
	# coins n'a rien à déplacer et reste parfaitement lisse. La subdivision est
	# ce qui rend l'animation possible, pas un réglage de qualité.
	surface.subdivide_width = LAKE_SUBDIVISIONS
	surface.subdivide_depth = LAKE_SUBDIVISIONS
	water.mesh = surface
	water.material_override = config.water_material
	add_child(water)
	water.position = Vector3(0.0, heightmap.water_level, 0.0)

	# Le fleuve a sa propre surface : la sienne descend d'un bout à l'autre, un
	# plan à altitude fixe ne peut pas la porter. Elle s'arrête là où le lac
	# prend le relais.
	var ribbon := RiverMeshBuilder.build(heightmap.river_reaches, heightmap.water_level,
		config.water_material, config.river_bank)
	if ribbon != null:
		var river := MeshInstance3D.new()
		river.name = RIVER_NODE
		river.mesh = ribbon
		add_child(river)

	# La carte de biome se calcule entre le relief et le semis : elle se déduit
	# du premier et n'est lue que par le second. Elle lit l'influence du massif
	# et non les hauteurs : un étage se déclare sur le relief, pas sur une
	# altitude que la pente d'écoulement décale d'un bout à l'autre de la carte.
	var biomes := BiomeMap.new()
	biomes.generate(config, heightmap.massif_influence)

	# Le semis passe avant le mesh : celui-ci lit la carte d'ouverture pour
	# colorer le sol de ce qui pousse dessus.
	var scatter := FoliageScatter.new()
	var foliage_started := Time.get_ticks_msec()
	var foliage := scatter.scatter(config, heights, heightmap.clearings, heightmap.river_reaches,
			heightmap.water_level, biomes)
	var foliage_elapsed := Time.get_ticks_msec() - foliage_started
	foliage.name = FOLIAGE_NODE
	add_child(foliage)

	var chunks := Node3D.new()
	chunks.name = CHUNKS_NODE
	add_child(chunks)
	# Le matériau du sol est dupliqué une fois pour toute la carte : le niveau de
	# l'eau est tiré à la graine, et l'écrire sur la ressource de config la
	# modifierait sur disque. Un exemplaire par chunk, à l'inverse, casserait le
	# regroupement des appels de dessin.
	var ground := _ground_material(heightmap.water_level)
	var side := config.chunks_per_side()
	for cz in side:
		for cx in side:
			var chunk := TerrainMeshBuilder.build_chunk(config, heights, scatter.occupancy, cx, cz, ground)
			if chunk != null:
				chunks.add_child(chunk)

	var proximity := FoliageProximity.new()
	proximity.name = PROXIMITY_NODE
	foliage.add_child(proximity)
	proximity.setup(scatter, config, foliage, sun)

	var cave := Marker3D.new()
	cave.name = CAVE_NODE
	add_child(cave)
	cave.position = heightmap.cave_position
	cave.look_at(heightmap.cave_position + heightmap.cave_forward, Vector3.UP)

	print("Terrain généré en %d ms — %d chunks, %d sommets, eau à %.1f m, %d clairières." % [
		Time.get_ticks_msec() - started,
		chunks.get_child_count(),
		heights.size(),
		heightmap.water_level,
		heightmap.clearings.size(),
	])
	var per_layer := PackedStringArray()
	for index in scatter.placed_per_layer.size():
		per_layer.append("%s %d" % [config.layers[index].id, scatter.placed_per_layer[index]])
	var per_biome := PackedStringArray()
	for index in scatter.placed_per_biome.size():
		per_biome.append("%s %d" % [config.biomes[index].id, scatter.placed_per_biome[index]])
	print("Feuillage semé en %d ms — %d chunks, %d instances (%s) — biomes : %s." % [
		foliage_elapsed,
		foliage.get_child_count() - 1,
		scatter.placed_count,
		", ".join(per_layer),
		", ".join(per_biome),
	])


func clear() -> void:
	heights = PackedFloat32Array()
	for node_name in [CHUNKS_NODE, WATER_NODE, RIVER_NODE, FOLIAGE_NODE, CAVE_NODE]:
		var existing := get_node_or_null(NodePath(node_name))
		if existing != null:
			existing.free()
