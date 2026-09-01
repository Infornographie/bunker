@tool
class_name BiomeStratum
extends Resource
## Ce qu'un biome fait pousser dans une strate donnée.
##
## Le lien vers la strate se fait par son `id`, pas par sa position dans la
## liste : l'ordre de semis est un réglage de `TerrainGenConfig`, et un biome
## n'a aucune raison de savoir à quel rang la canopée est semée.
##
## Un biome peut n'avoir aucune strate pour une couche donnée. Ce n'est pas une
## erreur, c'est une façon de dire quelque chose : une berge sans entrée
## `canopy` est une berge dégagée.

## `id` de la `FoliageLayer` visée.
@export var layer_id: StringName

## Taches de composition propres à ce biome dans cette strate. Testées dans
## l'ordre, la première qui répond l'emporte, la composition de base prend la
## suite. Les taches appartenant au biome et non à la strate, un coin à
## champignons peut n'exister que sous les conifères sans une ligne de code.
@export var patches: Array[FoliagePatch] = []

## Composition de base : les essences et leur poids ici.
@export var entries: Array[FoliageWeight] = []
