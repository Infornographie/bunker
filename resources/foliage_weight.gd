@tool
class_name FoliageWeight
extends Resource
## Une essence et le poids qu'elle a dans une composition donnée.
##
## Le poids ne vit pas sur l'essence, et c'est tout l'intérêt : la même plante
## pèse lourd dans un biome et presque rien dans un autre. Une `FoliageDef`
## décrit ce qu'une essence *est* — son modèle, ses rayons, la pente qu'elle
## admet, son goût pour l'ombre. Une composition décrit ce qui pousse *là*, et
## en quelle proportion. Garder le poids sur l'essence obligerait à écrire la
## composition d'une strate à deux endroits, et à n'en lire le résultat nulle
## part.

## L'essence.
@export var def: FoliageDef

## Poids relatif dans le tirage, à l'intérieur de la seule composition qui le
## porte. C'est un rapport et pas une densité : doubler tous les poids d'une
## palette ne change strictement rien au résultat. La densité, elle, est le
## `spacing` de la strate.
@export_range(0.0, 10.0, 0.05) var weight: float = 1.0
