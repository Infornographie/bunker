extends Resource
class_name ResourceDef

enum CarryType { HAND, SMALL, TOOL }

@export var id: String = ""
@export var name_key: String = ""
@export var carry_type: CarryType = CarryType.HAND
## Renseigné uniquement pour carry_type == TOOL. Permet au routage de
## ramassage de savoir quel outil placer en ceinture.
@export var tool_def: ToolDef
