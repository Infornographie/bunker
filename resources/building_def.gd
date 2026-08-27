extends Resource
class_name BuildingDef

@export var id: StringName
@export var display_name: String = ""
## Fantôme affiché pendant le placement (BuildModeController) ET pendant que
## le chantier attend ses ressources (ConstructionSite le teinte) — même
## scène, deux usages, un seul asset à maintenir.
@export var ghost_scene: PackedScene
## Forme réelle utilisée pour le test de chevauchement au placement (pas de
## boîte englobante synthétique) et pour la collision du ConstructionSite
## une fois posé.
@export var collision_shape: Shape3D
## Scène finale instanciée à la complétion du chantier.
@export var built_scene: PackedScene
## Position + scale locaux à appliquer à collision_shape pour qu'elle
## coïncide avec le mesh — nécessaire quand le hull convexe est généré dans
## une unité différente du mesh affiché (variante du quirk pivot FBX, voir
## STATE.md). Valeurs relevées à l'œil dans l'éditeur sur un CollisionShape3D
## de test aligné sur le mesh.
@export var collision_shape_position: Vector3 = Vector3.ZERO
@export var collision_shape_scale: Vector3 = Vector3.ONE
@export var costs: Array[ResourceCost] = []

func collision_shape_local_transform() -> Transform3D:
	return Transform3D(Basis().scaled(collision_shape_scale), collision_shape_position)
