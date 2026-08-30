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

@export var config: TerrainGenConfig

@export_tool_button("Régénérer") var regenerate_action: Callable = generate
@export_tool_button("Effacer") var clear_action: Callable = clear


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	generate()


func generate() -> void:
	if config == null:
		push_warning("TerrainController : aucun TerrainGenConfig assigné, rien à générer.")
		return

	var started := Time.get_ticks_msec()
	clear()

	var heightmap := HeightmapGenerator.new()
	heightmap.generate(config)

	var chunks := Node3D.new()
	chunks.name = CHUNKS_NODE
	add_child(chunks)
	var side := config.chunks_per_side()
	for cz in side:
		for cx in side:
			var chunk := TerrainMeshBuilder.build_chunk(config, heightmap.heights, cx, cz)
			if chunk != null:
				chunks.add_child(chunk)

	# Un seul plan pour toute l'eau : le rivage n'est pas dessiné, il est ce qui
	# dépasse. Le lac déborde de la zone parce que le plan est plus large qu'elle.
	var water := MeshInstance3D.new()
	water.name = WATER_NODE
	var surface := PlaneMesh.new()
	surface.size = Vector2(config.size_meters, config.size_meters) * 1.6
	water.mesh = surface
	water.material_override = config.water_material
	add_child(water)
	water.position = Vector3(0.0, heightmap.water_level, 0.0)

	var cave := Marker3D.new()
	cave.name = CAVE_NODE
	add_child(cave)
	cave.position = heightmap.cave_position
	cave.look_at(heightmap.cave_position + heightmap.cave_forward, Vector3.UP)

	print("Terrain généré en %d ms — %d chunks, %d sommets, eau à %.1f m." % [
		Time.get_ticks_msec() - started,
		chunks.get_child_count(),
		heightmap.heights.size(),
		heightmap.water_level,
	])


func clear() -> void:
	for node_name in [CHUNKS_NODE, WATER_NODE, CAVE_NODE]:
		var existing := get_node_or_null(NodePath(node_name))
		if existing != null:
			existing.free()
