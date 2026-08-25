extends Resource
class_name ResourceDef

enum CarryType { HAND, SMALL, TOOL }

@export var id: String = ""
@export var display_name: String = ""
@export var carry_type: CarryType = CarryType.HAND
