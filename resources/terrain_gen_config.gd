@tool
class_name TerrainGenConfig
extends Resource
## Paramètres de génération du terrain — source unique de tous les réglages de
## la chaîne heightmap → mesh, et de la convention de coordonnées de la grille.
##
## Repères posés ici et valables pour toute la chaîne :
## - la zone est un carré centré sur l'origine du monde ;
## - l'origine (0,0) est la bouche de la grotte du bunker : la position du
##   massif en découle, elle n'est pas réglable séparément ;
## - la plupart des réglages de massif sont des *fourchettes*, tirées à la
##   graine. Une carte n'est pas l'autre, mais une graine donnée redonne
##   toujours la même carte.

@export var world_seed: int = 1337

@export_group("Zone")
## Côté de la zone générée, en mètres.
@export var size_meters: float = 1200.0
## Distance entre deux sommets de la heightmap.
@export_range(0.5, 8.0, 0.5) var cell_size: float = 3.0
## Côté d'un chunk, en cellules.
@export_range(8, 128) var chunk_cells: int = 32

@export_group("Relief général")
## Vallonnement de fond. Son domain warp (réglé sur la ressource) sert de
## déformation d'ensemble à toute la carte.
@export var macro_noise: FastNoiseLite
## Amplitude crête-à-creux du vallonnement, en mètres.
@export var macro_amplitude: float = 14.0
## Dénivelé de la zone dans le sens d'écoulement, en mètres. C'est lui qui
## garantit que l'eau a toujours où descendre.
@export var drainage_drop: float = 45.0

@export_group("Massif")
## Orientation de l'axe du massif, en degrés. Le sens d'écoulement de la
## rivière et la vallée s'alignent dessus : le relief commande la géographie.
@export var massif_angle_range: Vector2 = Vector2(0.0, 360.0)
## Demi-longueur du massif, en fraction de la taille de zone. Grande devant la
## demi-largeur : une chaîne qui traverse. Comparable : un pic. Entre les deux :
## un massif qui s'étend dans une direction et s'arrête.
@export var massif_half_length_ratio_range: Vector2 = Vector2(0.25, 0.8)
## Demi-largeur du massif, en fraction de la taille de zone.
@export var massif_half_width_ratio_range: Vector2 = Vector2(0.15, 0.28)
## Altitude de l'axe au-dessus du pied, en mètres.
@export var massif_height_range: Vector2 = Vector2(160.0, 260.0)
## Méandre de l'axe le long du massif.
@export var massif_wobble_noise: FastNoiseLite
## Amplitude du méandre, en mètres.
@export var massif_wobble: float = 90.0
## Variation d'altitude le long de l'axe (sommets et cols).
@export var massif_profile_noise: FastNoiseLite
## 0 = axe d'altitude constante, 1 = cols descendant jusqu'au pied.
@export_range(0.0, 1.0) var massif_profile_variation: float = 0.3

@export_group("Falaise")
## Position du pied de la falaise sur le profil de versant (0 = pied du massif,
## 1 = axe). C'est là que s'ouvre la grotte, donc c'est aussi l'altitude à
## laquelle démarre la partie jouable.
@export_range(0.05, 0.9) var cliff_position: float = 0.32
## Part de la hauteur du massif prise par la falaise.
@export_range(0.0, 0.9) var cliff_height_ratio: float = 0.3
## Largeur horizontale de la falaise, en fraction de la demi-largeur du massif.
## Croisée avec cliff_height_ratio, elle donne la pente de la paroi. Trop
## étroite pour la grille et la paroi part en dents de scie : compte au moins
## une dizaine de cellules de large.
@export_range(0.005, 0.5) var cliff_band_ratio: float = 0.16

@export_group("Clairière du bunker")
## Rayon aplani autour de la bouche de grotte.
@export var bunker_radius: float = 26.0
## Distance d'adoucissement au-delà du rayon.
@export var bunker_falloff: float = 40.0
## Écart de hauteur au-delà duquel la clairière renonce à aplanir. Empêche le
## replat de tailler dans la falaise qui le domine.
@export var bunker_max_delta: float = 12.0

@export_group("Vallée de la rivière")
## Écart entre la grotte et l'axe de vallée, en fraction de la taille de zone,
## mesuré côté versant ouvert. 1/6 partage la zone praticable en 2/3 – 1/3.
@export var valley_offset_ratio: float = 0.1667
## Demi-largeur de la vallée, en fraction de la taille de zone.
@export_range(0.02, 0.4) var valley_half_width_ratio: float = 0.12
## Creusement de la vallée sous le niveau environnant, en mètres.
@export var valley_depth: float = 20.0
## Méandre de l'axe de vallée.
@export var valley_wobble_noise: FastNoiseLite
## Amplitude du méandre, en mètres.
@export var valley_wobble: float = 60.0
## Atténuation du vallonnement dans le fond de vallée. Un fond assez régulier,
## c'est ce qui évite les cuvettes fermées où le tracé viendrait mourir.
@export_range(0.0, 1.0) var valley_macro_damping: float = 0.5

@export_group("Rivière")
## Largeur du lit, en mètres.
@export var river_width: float = 12.0
## Profondeur du lit sous la ligne d'eau, en mètres.
@export var river_depth: float = 6.0
## Largeur de la berge adoucie de part et d'autre du lit. Plus large que le lit
## et elle avale l'entaille avant qu'elle existe.
@export var river_bank: float = 5.0
## Attirance du tracé vers l'axe de vallée. 0 = descente de gradient pure, le
## tracé se perd dans le vallonnement ; 1 = il ignore le relief.
@export_range(0.0, 1.0) var river_valley_pull: float = 0.15
## Longueur d'un pas de tracé, en mètres.
@export var river_step: float = 6.0

@export_group("Lac")
## Position du rivage sur l'axe d'écoulement, en fraction de la demi-zone vers
## l'aval. Le niveau de l'eau est la hauteur du fond de vallée à cet endroit :
## tout ce qui est plus bas est noyé, en aval comme ailleurs sur la carte. Le
## lac s'étend donc au-delà de la zone jouable sans qu'on ait à le dessiner.
@export_range(0.0, 1.0) var lake_shore_along_ratio: float = 0.45

@export_group("Rendu")
@export var terrain_material: Material
@export var water_material: Material
## Répétition de la texture de sol, en tours par mètre.
@export var uv_scale: float = 0.08


## Nombre de sommets par côté de la grille.
func grid_size() -> int:
	return int(round(size_meters / cell_size)) + 1


## Nombre de cellules par côté de la grille.
func cell_count() -> int:
	return grid_size() - 1


func half_size() -> float:
	return size_meters * 0.5


func chunks_per_side() -> int:
	return int(ceil(float(cell_count()) / float(chunk_cells)))


## Index d'un sommet dans le tableau de hauteurs.
func height_index(ix: int, iz: int) -> int:
	return iz * grid_size() + ix


## Position monde (plan XZ) d'un sommet de la grille.
func world_pos(ix: int, iz: int) -> Vector2:
	var half := half_size()
	return Vector2(-half + ix * cell_size, -half + iz * cell_size)
