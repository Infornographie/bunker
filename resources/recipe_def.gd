extends Resource
class_name RecipeDef

## Recette de transformation, purement data. Consommée par TransformationSite,
## qui ne connaît aucun bâtiment en particulier.

@export var id: String = ""
@export var display_name: String = ""
@export var inputs: Array[ResourceCost] = []
@export var output: ResourceDef
@export var output_amount: int = 1
## Durée totale, hors temps passé en pause.
@export var duration: float = 8.0
## Si vrai, la progression se met en pause quand le bâtiment hôte est inactif
## (feu éteint). L'hôte doit exposer is_active() -> bool.
@export var requires_host_active: bool = true
