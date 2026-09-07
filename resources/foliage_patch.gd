@tool
class_name FoliagePatch
extends Resource
## Une tache où la composition d'une strate change entièrement.
##
## Un coin à champignons, un cercle de fleurs, un parterre d'herbe haute : ce ne
## sont pas des essences plus ou moins probables au milieu des autres, ce sont
## des **endroits** où pousse autre chose. Régler ça par des poids donne du
## saupoudrage uniforme — un champignon tous les dix mètres partout, et jamais
## un coin à champignons.
##
## Le patch est donc une seconde palette, activée là où son bruit dépasse un
## seuil. La taille des taches vient de la fréquence du bruit, leur rareté du
## seuil. Les patchs sont testés dans l'ordre : le premier qui répond l'emporte.
##
## Une tache appartient à un `BiomeStratum` et pas à la strate : un coin à
## champignons peut n'exister que sous les conifères, et un bosquet de cerisiers
## que dans la forêt claire, sans une ligne de code pour l'arbitrer.

## Identifiant stable, pour les messages de génération.
@export var id: StringName

## Identité de clairière où cette tache s'installe. **Non vide, elle remplace
## entièrement le bruit et la bande de pente** : la tache n'existe alors que
## dans les clairières portant ce tag, et y existe toujours. C'est ce qui permet
## de poser un coin à champignons à un endroit *décidé*, là où un bruit ne sait
## produire que des taches réparties.
##
## Le terrain et le semis restent ignorants l'un de l'autre : le premier nomme
## des lieux, le second dit ce qui pousse dans un lieu de ce nom.
@export var clearing_tag: StringName = &""

## Bruit qui décide où la tache se forme. Sa fréquence donne la taille des
## taches : basse pour de grands parterres, haute pour de petits bosquets.
@export var noise: FastNoiseLite

## Seuil au-delà duquel la tache prend la main, de 0 (partout) à 1 (jamais).
## C'est le réglage de rareté.
@export_range(0.0, 1.0, 0.01) var threshold: float = 0.72

## Bande de pente où la tache peut se former, en degrés. Un éboulis n'est pas un
## endroit tiré au hasard : c'est un endroit *en pente*. Sans ce critère, une
## tache de rocaille peut se déclarer sur un replat, y remplacer la composition,
## et s'y refuser elle-même faute de pente — le replat reste nu.
@export_range(0.0, 90.0) var min_slope_degrees: float = 0.0
@export_range(0.0, 90.0) var max_slope_degrees: float = 90.0

## Hauteur maximale au-dessus du plan d'eau où la tache peut se former, en
## mètres. **Négatif = aucun critère.** C'est ce qui décrit une berge : le semis
## connaît déjà la hauteur du point et le niveau de l'eau, mais aucune donnée ne
## dit « à quelle distance de la rivière » — et une bande basse le long du cours
## est exactement ce qu'on cherche à décrire.
@export var max_height_above_water: float = -1.0

## Densité relative dans la tache. Au-dessus de 1, la tache est plus fournie que
## la strate autour — c'est ce qui fait qu'un parterre d'herbe se voit comme un
## parterre et pas comme une zone où l'herbe a juste changé d'espèce.
@export_range(0.0, 3.0, 0.05) var density: float = 1.0

## Ce qui pousse dans la tache, essence par essence avec son poids ici.
## Remplace la composition du biome dans cette strate, ne s'y ajoute pas.
@export var entries: Array[FoliageWeight] = []
