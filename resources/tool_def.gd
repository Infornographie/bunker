extends Resource
class_name ToolDef

enum ToolType { CHOP, MINE, STAB, BLUNT }

@export var id: StringName
@export var display_name: String
@export var tool_type: ToolType = ToolType.CHOP
@export var mesh_scene: PackedScene
@export var damage: int = 1
@export var swing_duration: float = 0.35
## Position/rotation du wrapper une fois accroché à la caméra (viewmodel).
## Rotation en degrés, ordre YXZ (cohérent avec l'inspecteur Node3D).
@export var hand_position: Vector3 = Vector3.ZERO
@export var hand_rotation_degrees: Vector3 = Vector3.ZERO
