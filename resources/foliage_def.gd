@tool
class_name FoliageDef
extends Resource
## Définition data-driven d'une plante posée par le scatter.
##
## Une essence = un `.tres`, pas une scène montée à la main. C'est ce qui permet
## d'en ajouter dix sans monter dix scènes, et c'est ce que liront les
## `BiomeDef` quand les biomes arriveront.
##
## Volontairement limité à ce que la passe courante consomme : les paramètres de
## récolte (PV, outil, ressource lâchée) et les tags de propriété du Jalon 10
## s'ajouteront quand il y aura quelqu'un pour les lire.

## Identifiant stable. Sert de clé de cache — jamais un nom affiché.
@export var id: StringName

## Scène du modèle, telle qu'elle vient du pack. Le scatter en extrait les
## meshes ; il n'instancie jamais la scène en jeu.
@export var model: PackedScene

## Échelle tirée dans cette fourchette, uniforme sur les trois axes.
@export var scale_range: Vector2 = Vector2(0.9, 1.2)

## Rotation aléatoire autour de l'axe vertical. Faux pour ce qui a une
## orientation qui compte.
@export var random_yaw: bool = true

## Pente au-delà de laquelle l'essence ne pousse pas.
@export_range(0.0, 90.0) var max_slope_degrees: float = 35.0

## Enfoncement dans le sol, en mètres. La hauteur du terrain est lue au centre
## du modèle : sur une pente, le bord aval de la base décolle. L'enfoncement
## effectif croît donc avec la pente, ce réglage en donne la valeur à plat.
@export_range(0.0, 3.0, 0.05) var embed_depth: float = 0.5

## Poids relatif dans le tirage d'espèce, à densité de strate donnée.
@export_range(0.0, 10.0) var weight: float = 1.0
