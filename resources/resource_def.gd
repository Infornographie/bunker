extends Resource
class_name ResourceDef

enum CarryType { HAND, BACKPACK }

@export var id: String = ""
@export var display_name: String = ""
@export var carry_type: CarryType = CarryType.HAND
