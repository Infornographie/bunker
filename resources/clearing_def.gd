@tool
extends Resource
class_name ClearingDef
## Un replat déclaré sur la carte, et ce qu'on y trouve.
##
## **Une clairière a une identité, pas seulement une géométrie.** Sans ça, la
## position du replat vivrait dans la config du terrain et le contenu qu'on veut
## y poser dans celle du semis — deux vérités, et le jour où on déplace le
## replat la tache reste où elle était. Le `tag` est ce qui les relie : le
## terrain dit « ici, une clairière nommée *quarry* », le semis dit « voici ce
## qui pousse dans une *quarry* », et ni l'un ni l'autre ne connaît l'autre.

## Centre du replat dans le plan XZ, en mètres.
@export var position: Vector2 = Vector2.ZERO
## Rayon aplani, en mètres.
@export var radius: float = 24.0
## Identité du lieu. Vide = une clairière ordinaire, qui prend la composition
## normale de son biome. Un `FoliagePatch` portant le même tag y remplace cette
## composition.
@export var tag: StringName = &""
