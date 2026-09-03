@tool
class_name FoliageDef
extends Resource
## Définition data-driven d'une plante posée par le scatter.
##
## Une essence = un `.tres`, pas une scène montée à la main. C'est ce qui permet
## d'en ajouter dix sans monter dix scènes.
##
## **Une essence décrit ce qu'elle est, jamais où elle pousse ni en quelle
## proportion.** Son poids appartient à la composition qui l'emploie
## (`FoliageWeight`, dans un `BiomeDef`) : la même plante pèse lourd dans un
## biome et presque rien dans un autre, et un poids porté ici obligerait à
## écrire la composition d'une strate à deux endroits.
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

## Pente en deçà de laquelle l'essence ne pousse pas. Sert aux éboulis et aux
## rochers : ce qui n'a rien à faire dans une prairie plate.
@export_range(0.0, 90.0) var min_slope_degrees: float = 0.0

## Pente au-delà de laquelle l'essence ne pousse pas. C'est ce qui déshabille
## les falaises : l'herbe s'arrête, la roche prend la suite.
@export_range(0.0, 90.0) var max_slope_degrees: float = 35.0

## Part de la normale du terrain reprise par l'objet, de 0 (toujours vertical)
## à 1 (couché dans la pente). Une plante pousse vers le haut quelle que soit la
## pente : elle reste à 0. Un rocher, lui, épouse le sol — sans quoi il flotte
## par son bord aval et s'enterre par l'amont, d'autant plus qu'il est large.
@export_range(0.0, 1.0, 0.05) var align_to_slope: float = 0.0

## Enfoncement dans le sol, en mètres. La hauteur du terrain est lue au centre
## du modèle : sur une pente, le bord aval de la base décolle. L'enfoncement
## effectif croît donc avec la pente, ce réglage en donne la valeur à plat.
@export_range(0.0, 3.0, 0.05) var embed_depth: float = 0.5

## Rayon de la base, en mètres : l'emprise que rien d'autre ne pourra occuper.
## C'est la contrainte *dure*, celle qui empêche un buisson de pousser dans un
## tronc. À ne pas confondre avec le rayon de feuillage ci-dessous : traiter
## l'ombre comme un refus ne laisse pousser aucune strate basse.
@export_range(0.0, 12.0, 0.1) var base_radius: float = 1.0

## Rayon du feuillage, en mètres. Sert à l'ombre portée sur la carte
## d'ouverture, pas au refus. À 0, la plante ne couvre rien.
@export_range(0.0, 20.0, 0.5) var cover_radius: float = 0.0

## Densité du couvert sous le feuillage, de 0 (transparent) à 1 (fermé).
@export_range(0.0, 1.0, 0.05) var cover_amount: float = 1.0

## Réponse de l'essence à la couverture déjà en place : la courbe va de « à
## découvert » (0) à « sous un couvert fermé » (1) et donne la probabilité
## d'accepter un candidat. L'herbe décroît, les champignons croissent, une
## fougère de sous-bois fait une cloche. Nulle = indifférente.
@export var cover_response: Curve
