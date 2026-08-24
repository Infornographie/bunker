extends Resource
class_name BuildingCost

## Une ligne de coût dans BuildingDef.costs : count exemplaires de
## resource_def doivent être livrés au chantier avant activation.
@export var resource_def: ResourceDef
@export var count: int = 1
