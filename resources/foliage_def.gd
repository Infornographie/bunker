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
## Volontairement limité à ce que la passe courante consomme : les tags de
## propriété du Jalon 9 s'ajouteront quand il y aura quelqu'un pour les lire.

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


@export_group("Présence physique")
## Rayon du cylindre de collision, en mètres, à l'échelle 1. **À zéro, aucun
## corps n'est posé** : l'essence reste du décor pur, ce qui est le cas de
## l'herbe, des fleurs et de tout ce qu'on traverse.
##
## Le corps posé n'a **pas de mesh** : le `MultiMesh` continue de dessiner la
## plante, le corps ne fait qu'exister pour le raycast d'interaction et pour
## bloquer le passage. Un corps nu ne coûte rien au rendu — lui donner un mesh
## rendrait à la scène les milliers d'objets de dessin que le multimesh existe
## précisément pour éviter.
@export_range(0.0, 4.0, 0.05) var collider_radius: float = 0.0
## Hauteur du cylindre, en mètres à l'échelle 1. Pour un arbre c'est le tronc,
## pas la couronne : une collision qui épouse le feuillage est ce qui fait
## grimper le navmesh dans les branches.
@export_range(0.1, 30.0, 0.1) var collider_height: float = 2.0

@export_group("Récolte")
## Ce qui tombe quand l'essence est épuisée. **Vide = rien à récolter** : la
## plante peut alors porter un corps sans être exploitable, ce qui est le cas
## d'un rocher qu'on contourne.
@export var harvest_drops: Array[ResourceDrop] = []
## Faux pour ce qui se ramasse à la main plutôt que de s'abattre : champignons,
## branches au sol, cailloux. `harvest_tool_type` est alors ignoré.
@export var harvest_requires_tool: bool = true
## Type d'outil qui l'entame. Sans le bon outil, les coups ne font rien.
@export var harvest_tool_type: ToolDef.ToolType = ToolDef.ToolType.CHOP
@export_range(1, 50) var harvest_health: int = 3
@export var harvest_prompt_key: String = "interact.prompt.chop"
@export var harvest_sound: AudioStream
