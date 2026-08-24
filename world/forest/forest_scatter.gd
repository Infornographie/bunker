@tool
extends Node3D
class_name ForestScatter

## Placement jitteré (approximation poisson-disque par rejet de distance)
## des assets nature Quaternius autour d'une zone d'exclusion (le bunker).
## Voir ROADMAP Jalon 1 + GDD "Hors scope MVP" : pas de heightmap/bruit,
## uniquement un scatter sur un sol plat/fixe.

## Une entrée par type d'asset : scène à instancier + poids relatif dans le
## tirage + échelle min/max pour un peu de variation visuelle.
class ScatterEntry:
	var scene: PackedScene
	var weight: float = 1.0
	var min_scale: float = 0.85
	var max_scale: float = 1.15

	func _init(p_scene: PackedScene, p_weight: float = 1.0, p_min_scale: float = 0.85, p_max_scale: float = 1.15) -> void:
		scene = p_scene
		weight = p_weight
		min_scale = p_min_scale
		max_scale = p_max_scale

@export var scatter_entries: Array[PackedScene] = []
## Poids parallèle à scatter_entries (même index). Si vide, poids uniforme.
@export var scatter_weights: Array[float] = []

@export var zone_size: Vector2 = Vector2(120.0, 120.0)  # dimensions X/Z de la zone de scatter
@export var zone_center: Vector3 = Vector3.ZERO
@export var exclusion_radius: float = 15.0  # rayon libre autour du bunker
@export var min_distance_between_props: float = 2.5  # rejet poisson-disque
@export var target_count: int = 400
@export var max_attempts_per_point: int = 30
@export var random_seed: int = 0  # 0 = aléatoire à chaque run

var _rng := RandomNumberGenerator.new()
var _placed_points: Array[Vector2] = []

func _ready() -> void:
	generate()

func generate() -> void:
	clear_scatter()

	if scatter_entries.is_empty():
		push_warning("ForestScatter: aucune scatter_entries assignée, rien à placer.")
		return

	if random_seed != 0:
		_rng.seed = random_seed
	else:
		_rng.randomize()

	_placed_points.clear()

	var placed := 0
	var attempts := 0
	var max_total_attempts := target_count * max_attempts_per_point

	while placed < target_count and attempts < max_total_attempts:
		attempts += 1

		var candidate := _random_point_in_zone()

		if candidate.length() < exclusion_radius:
			continue

		if not _is_far_enough(candidate):
			continue

		_placed_points.append(candidate)
		_spawn_instance(candidate)
		placed += 1

	if placed < target_count:
		push_warning("ForestScatter: seulement %d/%d props placés (zone trop dense ou trop petite)." % [placed, target_count])

func clear_scatter() -> void:
	for child in get_children():
		child.queue_free()
	_placed_points.clear()

func _random_point_in_zone() -> Vector2:
	var x := _rng.randf_range(-zone_size.x * 0.5, zone_size.x * 0.5)
	var z := _rng.randf_range(-zone_size.y * 0.5, zone_size.y * 0.5)
	return Vector2(x, z)

func _is_far_enough(candidate: Vector2) -> bool:
	for p in _placed_points:
		if p.distance_to(candidate) < min_distance_between_props:
			return false
	return true

func _spawn_instance(point: Vector2) -> void:
	var scene := _pick_weighted_scene()
	if scene == null:
		return

	var instance := scene.instantiate()
	add_child(instance)

	if instance is Node3D:
		var node3d := instance as Node3D
		node3d.position = zone_center + Vector3(point.x, 0.0, point.y)
		node3d.rotation.y = _rng.randf_range(0.0, TAU)

		var scale_factor := _rng.randf_range(0.85, 1.15)
		node3d.scale = Vector3.ONE * scale_factor

func _pick_weighted_scene() -> PackedScene:
	if scatter_entries.is_empty():
		return null

	var weights := scatter_weights
	if weights.size() != scatter_entries.size():
		weights = []
		for i in scatter_entries.size():
			weights.append(1.0)

	var total := 0.0
	for w in weights:
		total += w

	if total <= 0.0:
		return scatter_entries[_rng.randi_range(0, scatter_entries.size() - 1)]

	var roll := _rng.randf_range(0.0, total)
	var cumulative := 0.0
	for i in scatter_entries.size():
		cumulative += weights[i]
		if roll <= cumulative:
			return scatter_entries[i]

	return scatter_entries[scatter_entries.size() - 1]

# --- Notes d'intégration ---
# - Renseigner scatter_entries dans l'inspecteur avec les .tscn des assets
#   Stylized Nature MegaKit (arbres, rochers, buissons...).
# - exclusion_radius doit couvrir l'emprise du bunker (Jalon 2) + marge.
# - IMPORTANT (ROADMAP) : bake NavigationServer3D APRÈS generate(), pas avant,
#   sinon le nav mesh ne tient pas compte des props placés.
# - Pour un vrai poisson-disque (Bridson) plus dense/rapide que le rejet
#   naïf ci-dessus, on pourra migrer plus tard si target_count monte
#   significativement (perf du rejet dégrade avec la densité).
