extends Resource
class_name ResourceDef

enum CarryType { HAND, SMALL, TOOL }

@export var id: String = ""
@export var name_key: String = ""
@export var carry_type: CarryType = CarryType.HAND
## Renseigné uniquement pour carry_type == TOOL. Permet au routage de
## ramassage de savoir quel outil placer en ceinture.
@export var tool_def: ToolDef

## Comment cette ressource se pose quand elle est stockée.
##   GRID    — posée à plat, en couches. Tout ce qui n'est pas cylindrique.
##   PYRAMID — empilée en pyramide, chaque étage calé dans le creux du
##             précédent. Réservé à ce qui roule : rondins, tuyaux.
enum StackStyle { GRID, PYRAMID }

@export_group("Stockage")
@export var stack_style: StackStyle = StackStyle.GRID
## Encombrement au sol, en mètres : **longueur × largeur**, dans le repère de
## l'objet. Un scalaire ne suffit pas — une branche fait 1,3 m de long pour
## 30 cm de large, et un pas unique la fait forcément soit se traverser, soit
## gaspiller la place de ce qui est rond.
##
## Un objet nettement allongé (rapport > 1,5) voit ses couches **croisées à
## 90°**, comme une pile de bois : c'est ce qui la fait tenir, et ce qui la
## rend lisible d'un coup d'œil.
@export var footprint: Vector2 = Vector2(0.4, 0.4)
## Hauteur d'une couche empilée, en mètres.
@export_range(0.05, 2.0, 0.05) var stack_height: float = 0.25
