extends Node

## Table ResourceDef → PackedScene du pickup correspondant.
##
## Existe pour casser le cycle de références : une scène de pickup référence
## son ResourceDef (.tres), donc le .tres ne peut pas référencer la scène en
## retour (Godot refuse : "Recursion detected"). Le registre résout le sens
## manquant en scannant les scènes au démarrage.
##
## Toute scène placée sous SCAN_ROOTS dont le script est un ResourcePickup
## avec un resource_def assigné est enregistrée automatiquement — aucun
## câblage manuel à faire quand on ajoute une ressource.

const SCAN_ROOTS: Array[String] = [
	"res://entities/interactable/",
]

var _scene_by_resource_id: Dictionary = {}
var _icon_generator: IconGenerator


func _ready() -> void:
	_scan_all()


## Le générateur est créé à la première demande plutôt que dans _ready() :
## un nœud de la scène peut demander une icône avant que l'autoload ait
## fini son initialisation.
func _ensure_generator() -> void:
	if _icon_generator == null:
		_icon_generator = IconGenerator.new()
		add_child(_icon_generator)


## Retourne l'icône générée depuis le modèle 3D de cette ressource.
## Générée au premier appel puis mise en cache. Appel asynchrone :
##   var icon: Texture2D = await ResourceRegistry.get_icon(resource)
func get_icon(resource: ResourceDef) -> Texture2D:
	if resource == null:
		return null
	if _scene_by_resource_id.is_empty():
		_scan_all()
	var scene := get_pickup_scene(resource)
	if scene == null:
		return null
	_ensure_generator()
	return await _icon_generator.get_icon(resource.id, scene)


## Icône d'un outil, générée depuis sa scène de préhension (grip).
## Clé de cache préfixée pour ne pas collisionner avec les ressources.
func get_tool_icon(tool_def: ToolDef) -> Texture2D:
	if tool_def == null or tool_def.mesh_scene == null:
		return null
	_ensure_generator()
	var key: String = "tool:" + tool_def.display_name
	return await _icon_generator.get_icon(key, tool_def.mesh_scene)


## Retourne la scène de pickup pour cette ressource, ou null.
func get_pickup_scene(resource: ResourceDef) -> PackedScene:
	if resource == null or resource.id.is_empty():
		return null
	return _scene_by_resource_id.get(resource.id)


## Instancie un pickup pour cette ressource, ou null si non enregistrée.
func spawn_pickup(resource: ResourceDef) -> Node3D:
	var scene := get_pickup_scene(resource)
	if scene == null:
		push_warning("ResourceRegistry : aucune scène pour la ressource '%s'" % resource.id if resource else "null")
		return null
	return scene.instantiate()


## --- Scan ---------------------------------------------------------------

func _scan_all() -> void:
	for root in SCAN_ROOTS:
		_scan_directory(root)


func _scan_directory(path: String) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		push_warning("ResourceRegistry : dossier introuvable '%s'" % path)
		return
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		var full_path := path.path_join(entry)
		if dir.current_is_dir():
			_scan_directory(full_path)
		elif entry.ends_with(".tscn"):
			_register_scene(full_path)
		entry = dir.get_next()
	dir.list_dir_end()


func _register_scene(scene_path: String) -> void:
	var scene: PackedScene = load(scene_path)
	if scene == null:
		return
	var state := scene.get_state()
	# Le resource_def est une propriété du node racine (index 0).
	if state.get_node_count() == 0:
		return
	for i in state.get_node_property_count(0):
		if state.get_node_property_name(0, i) != "resource_def":
			continue
		var res = state.get_node_property_value(0, i)
		if res is ResourceDef and not res.id.is_empty():
			_scene_by_resource_id[res.id] = scene
		return
