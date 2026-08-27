extends Resource
class_name ResourceCost

## Couple ressource/quantité. Partagé par les coûts de construction
## (BuildingDef.costs) et les entrées de recette (RecipeDef.inputs).

@export var resource: ResourceDef
@export var amount: int = 1
