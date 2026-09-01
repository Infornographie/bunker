@tool
class_name FoliageLayer
extends Resource
## Une strate de végétation : sa grille de semis et sa façon de répondre au lieu.
##
## **Elle ne dit pas ce qui pousse.** La composition appartient aux `BiomeDef` :
## la canopée est une hauteur et un espacement, et ce qu'on y trouve dépend de
## l'endroit. La strate porte donc la grille, le bruit de peuplement et les
## réponses aux clairières ; le biome porte les essences et les taches.
##
## **La strate est une responsabilité, pas une étiquette.** Mélanger de petits
## arbres à la canopée creuse des trouées que rien ne ferme ; les mêmes arbres
## rangés en sous-étage se posent *sous* les grands et bouchent la vue. C'est le
## rangement qui règle la question, pas un réglage de densité — corriger la
## densité n'aurait fait que compenser une erreur de strate.
##
## L'ordre de la liste dans `TerrainGenConfig` est l'ordre de semis, et il est
## structurant : une strate lit l'occupation laissée par toutes celles d'avant,
## et n'est lue par aucune d'après.

## Identifiant stable, pour les messages de génération. Jamais un nom affiché.
@export var id: StringName

## Distance entre deux candidats de la grille de semis, en mètres. C'est le
## réglage de densité de la strate.
@export_range(0.5, 30.0, 0.25) var spacing: float = 6.0

## Décalage aléatoire de chaque candidat, en fraction de l'espacement. À 0, la
## strate est un verger.
@export_range(0.0, 1.0) var jitter: float = 0.85

## Strate semée autour du joueur au lieu de l'être une fois pour toutes. Une
## strate au sol tient des centaines de milliers d'instances sur la carte
## entière : elle ne peut exister qu'à portée de vue. En contrepartie, elle
## n'écrit pas dans l'occupation permanente — elle la lit, et tient la sienne,
## locale au chunk et jetée avec lui, pour rester identique à chaque retour.
@export var streamed: bool = false

## Bruit qui décide quelle essence domine où. Sa fréquence donne la taille des
## peuplements : large pour une futaie, serrée pour des touffes d'herbe.
##
## Sa valeur en un point désigne une position sur une roue où chaque essence
## occupe un secteur proportionnel à son poids. **Un seul appel de bruit par
## candidat**, quelle que soit le nombre d'essences — un champ par essence
## coûtait, à un mètre d'espacement, le semis entier. Et deux points voisins
## tombent forcément dans le même secteur : c'est ce qui fait les bosquets.
@export var stand_noise: FastNoiseLite

## Brouillage du tirage, en fraction de la roue. À 0 les bosquets ont des bords
## nets ; plus haut, les espèces se mélangent sur leurs lisières.
@export_range(0.0, 0.5, 0.01) var stand_blend: float = 0.08

## Réponse de la strate à l'ouverture des clairières : la courbe va du cœur de
## la clairière (0) à la pleine forêt (1) et donne la probabilité d'accepter un
## candidat. Nulle = indifférente, ce qui convient au sol.
##
## Une simple atténuation ne suffisait pas : elle ne sait que retirer. Les
## buissons ne sont pas *moins nombreux* près d'une clairière, ils y forment une
## **couronne** — absents du tapis d'herbe, serrés sur la lisière, plus rares
## sous le couvert. Ça se dit avec une cloche et pas avec un facteur.
@export var clearing_response: Curve

## Dans une clairière, tirer l'essence au centre de la tache plutôt qu'au point.
## Une clairière est alors couverte d'une seule espèce, comme une clairière
## réelle colonisée par celle qui s'y est installée — au lieu d'être traversée
## par la frontière de deux peuplements qui l'ignorent.
@export var clearing_uniform: bool = false
