@tool
class_name BiomeDef
extends Resource
## Un biome : où il règne, et ce qui y pousse.
##
## **Un biome ne porte jamais de frontière.** Il déclare une bande d'altitude et
## un bruit ; `BiomeMap` en tire un *poids* par sommet, et le semis tire au sort
## quel biome décide en chaque point. Là où deux poids se valent, les deux
## compositions s'entremêlent arbre par arbre — c'est ce qu'est une vraie limite
## forestière, un mélange qui s'inverse et pas un trait.
##
## Mélanger les *poids d'essences* plutôt que le tirage donnerait au contraire
## une moyenne : au milieu de la transition, un arbre à mi-chemin entre les deux
## biomes, qui ne pousse dans aucun des deux. Et ça coûterait une roue
## reconstruite à chaque candidat, là où celle-ci se construit une fois.
##
## L'étage se déclare sur l'**influence du massif** — 1 sur l'axe, 0 hors du
## relief — et jamais sur une altitude. La carte descend de `drainage_drop` d'un
## bout à l'autre : une plaine parfaitement plate y gagne quarante mètres, si
## bien qu'un seuil en mètres au-dessus de l'eau fait apparaître un étage
## montagnard sur une moitié de plaine. L'influence ignore le drainage, le
## vallonnement et le niveau du lac, et elle est déjà normalisée entre 0 et 1.

## Identifiant stable, pour les messages de génération. Jamais un nom affiché.
@export var id: StringName

@export_group("Emprise")

## Bande d'influence de massif où le biome règne. Quelques repères sur la carte
## actuelle : 0 en plaine, environ 0,27 à la bouche de la grotte, 0,57 en haut
## de la falaise, 1 sur l'axe des crêtes. (0, 1) = partout, ce qui convient à un
## biome de fond de carte — à condition qu'il redescende avant que le suivant ne
## monte, sinon les deux se partagent le sommet à égalité.
@export var massif_range: Vector2 = Vector2(0.0, 1.0)

## Largeur de la transition de part et d'autre de la bande, même unité. C'est
## la seule chose qui sépare une limite d'étage d'un trait de crayon : à 0, la
## bascule tient sur une cellule et se lit comme une ligne de niveau.
@export_range(0.0, 1.0, 0.01) var massif_falloff: float = 0.12

## Bruit qui déforme la limite. Une vraie limite forestière ondule avec
## l'exposition, le vent et le sol ; un seuil net suit la forme du relief de
## trop près et se lit comme un tracé.
@export var edge_noise: FastNoiseLite

## Amplitude de la déformation, dans l'unité de l'influence. À comparer à
## `massif_falloff` : bien plus grande, elle décroche des paquets du biome loin
## de sa bande, ce qui est un effet et pas un défaut.
@export_range(0.0, 0.5, 0.01) var edge_amount: float = 0.06

## Poids tenu partout, y compris hors de la bande. C'est ce qui laisse un biome
## de fond de carte reprendre la main là où plus personne ne revendique, et ce
## qui garantit qu'aucun point ne se retrouve sans aucun biome.
@export_range(0.0, 1.0, 0.01) var weight_floor: float = 0.0

@export_group("Végétation")

## Ce que le biome fait pousser, une entrée par strate concernée. Une strate
## absente de cette liste ne pousse pas dans ce biome.
@export var strata: Array[BiomeStratum] = []


## Strate de ce biome visant une couche donnée, ou `null` s'il n'y pousse rien.
func stratum_for(layer: StringName) -> BiomeStratum:
	for stratum in strata:
		if stratum != null and stratum.layer_id == layer:
			return stratum
	return null
