extends Resource
class_name ResourceDrop
## Une ligne de butin : quelle ressource, en quelle quantité.
##
## Existe parce qu'une source de récolte en lâche plusieurs sortes — un arbre
## donne des rondins **et** des branches, un bloc de pierre des blocs **et** des
## cailloux. Deux champs `drop_resource`/`pickup_count` sur la source ne savent
## en exprimer qu'une, et les tripler par ressource aurait figé le nombre.

@export var resource: ResourceDef
@export_range(1, 20) var count: int = 1
