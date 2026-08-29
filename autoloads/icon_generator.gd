extends Node
class_name IconGenerator

## Génère une icône 2D à partir d'un modèle 3D, à la demande, avec cache.
##
## Principe : un SubViewport hors écran, caméra orthographique en 3/4,
## éclairage neutre. On y instancie le mesh, on cadre automatiquement sur
## sa bounding box, on capture une frame, on garde la texture.
##
## Le viewport est **jetable** : un par icône, détruit juste après la
## capture. Un viewport partagé et réveillé ponctuellement en UPDATE_ONCE
## garde les pixels de son rendu précédent (le nettoyage ne passe pas sur
## une cible endormie), et les modèles s'empilent d'une icône à l'autre —
## symptôme vécu : hache et champignon dans la même case, à 328 frames
## d'écart. Une cible neuve est vide par construction. Corollaire agréable :
## deux générations simultanées ne se marchent plus dessus, il n'y a plus
## rien à sérialiser.
##
## Utilisé par ResourceRegistry — pas appelé directement.

const ICON_SIZE: int = 128
## Angle 3/4 classique d'icône d'inventaire (yaw, pitch en degrés).
const CAMERA_YAW: float = -35.0
const CAMERA_PITCH: float = -25.0
## Marge autour de l'objet dans le cadre (1.0 = objet pile dans le cadre).
const FRAMING_MARGIN: float = 1.25

var _cache: Dictionary = {}


## Retourne l'icône de cette scène, en la générant au premier appel.
## cache_key : identifiant stable (l'id du ResourceDef en général).
func get_icon(cache_key: String, scene: PackedScene) -> Texture2D:
	if cache_key.is_empty() or scene == null:
		return null
	if _cache.has(cache_key):
		return _cache[cache_key]
	var icon := await _render(scene)
	if icon:
		_cache[cache_key] = icon
	return icon


## Vide le cache (utile en debug si un modèle change à chaud).
func clear_cache() -> void:
	_cache.clear()


## --- Rendu ---------------------------------------------------------------

func _render(scene: PackedScene) -> Texture2D:
	var viewport := _make_viewport()
	var camera: Camera3D = viewport.get_node("Camera")
	var model_root: Node3D = viewport.get_node("ModelRoot")

	var instance := scene.instantiate()
	model_root.add_child(instance)
	_strip_non_visual(instance)

	var bounds := _compute_visual_bounds(model_root, instance)
	if bounds.size == Vector3.ZERO:
		viewport.queue_free()
		return null

	_frame_camera(camera, bounds)

	# Une seule frame suffit : on force le rendu puis on lit la texture.
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	await RenderingServer.frame_post_draw

	var image := viewport.get_texture().get_image()
	viewport.queue_free()

	if image == null:
		return null
	return ImageTexture.create_from_image(image)


## Viewport complet et autonome : caméra, éclairage, porte-modèle. Nommés,
## parce que _render() les récupère par leur nom plutôt que de trimballer
## trois variables.
func _make_viewport() -> SubViewport:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(ICON_SIZE, ICON_SIZE)
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	viewport.own_world_3d = true
	add_child(viewport)

	var camera := Camera3D.new()
	camera.name = "Camera"
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	viewport.add_child(camera)

	# Éclairage neutre : une clé en 3/4, un fill doux à l'opposé pour que
	# les faces sombres ne soient pas noires.
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-40.0, -40.0, 0.0)
	key.light_energy = 1.2
	viewport.add_child(key)

	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-10.0, 140.0, 0.0)
	fill.light_energy = 0.4
	viewport.add_child(fill)

	var env := Environment.new()
	env.background_mode = Environment.BG_CANVAS
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.6, 0.62, 0.68)
	env.ambient_light_energy = 0.5
	camera.environment = env
	camera.attributes = CameraAttributesPractical.new()

	var model_root := Node3D.new()
	model_root.name = "ModelRoot"
	viewport.add_child(model_root)

	return viewport


## Place la caméra en 3/4 et cadre sur la bounding box du modèle.
func _frame_camera(camera: Camera3D, bounds: AABB) -> void:
	var center := bounds.get_center()
	var radius := bounds.size.length() * 0.5

	var basis := Basis.from_euler(Vector3(
		deg_to_rad(CAMERA_PITCH),
		deg_to_rad(CAMERA_YAW),
		0.0
	))
	var direction := basis * Vector3.BACK
	camera.global_position = center + direction * (radius * 4.0 + 1.0)
	camera.look_at(center, Vector3.UP)
	camera.size = radius * 2.0 * FRAMING_MARGIN
	camera.near = 0.01
	camera.far = radius * 10.0 + 10.0


## Union des AABB de tous les MeshInstance3D, en espace local du modèle.
func _compute_visual_bounds(model_root: Node3D, node: Node) -> AABB:
	var result := AABB()
	var found := false
	for mesh_node in _collect_meshes(node):
		var mesh_aabb: AABB = mesh_node.get_aabb()
		# Repasser en espace du model_root.
		var xform: Transform3D = model_root.global_transform.affine_inverse() * mesh_node.global_transform
		mesh_aabb = xform * mesh_aabb
		if not found:
			result = mesh_aabb
			found = true
		else:
			result = result.merge(mesh_aabb)
	return result


func _collect_meshes(node: Node) -> Array[MeshInstance3D]:
	var meshes: Array[MeshInstance3D] = []
	if node is MeshInstance3D:
		meshes.append(node)
	for child in node.get_children():
		meshes.append_array(_collect_meshes(child))
	return meshes


## Retire tout ce qui n'est pas visuel : collision, physique, scripts qui
## pourraient tourner (le pickup instancié ici n'est pas dans le jeu).
func _strip_non_visual(node: Node) -> void:
	if node is CollisionObject3D:
		node.set("collision_layer", 0)
		node.set("collision_mask", 0)
	if node.get_script() != null:
		node.set_script(null)
	if node is Light3D or node is Camera3D:
		node.queue_free()
		return
	for child in node.get_children():
		_strip_non_visual(child)
