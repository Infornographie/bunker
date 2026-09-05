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

@export_group("Contrefort")
## Éperons perpendiculaires à la crête, qui ferment la vallée et cassent la
## symétrie d'une carte à massif unique. À 0, la carte est celle d'avant.
##
## Dette nommée : ces fourchettes vivront dans le `.tres` du contrefort quand le
## catalogue de features existera (passe D). Elles sont ici parce qu'un
## contrefort est un massif, et que les fourchettes de massif sont ici.
@export_range(0, 4) var spur_count: int = 1
## Demi-longueur, en fraction de la taille de zone. Au-delà de la distance du
## pied de falaise à la vallée, l'éperon barre le cours — et le fleuve le tranche
## en cluse, ce qui est voulu.
@export var spur_half_length_ratio_range: Vector2 = Vector2(0.15, 0.25)
## Demi-largeur, en fraction de la taille de zone. Un éperon est étroit : c'est
## ce qui le distingue d'un second massif.
@export var spur_half_width_ratio_range: Vector2 = Vector2(0.04, 0.07)
## Hauteur, en fraction de celle du massif hôte. Au-delà de ~0,6 il rivalise
## avec la crête au lieu d'en descendre.
@export var spur_height_ratio_range: Vector2 = Vector2(0.35, 0.55)
## Position le long de la crête hôte, en fraction de sa demi-longueur.
@export var spur_along_ratio_range: Vector2 = Vector2(0.35, 0.7)
## Écart à la perpendiculaire, en degrés. Un éperon exactement perpendiculaire
## se lit comme une construction.
@export_range(0.0, 60.0) var spur_angle_deviation: float = 25.0

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

@export_group("Plaine")
## Atténuation du vallonnement là où le massif n'a plus d'influence. 1 = aucune.
## C'est ce qui rend la plaine habitable sans raboter la montagne.
@export_range(0.2, 1.0) var plain_macro_scale: float = 0.55

@export_group("Clairière du bunker")
## Rayon aplani autour de la bouche de grotte.
@export var bunker_radius: float = 26.0
## Distance d'adoucissement au-delà du rayon.
@export var bunker_falloff: float = 40.0
## Écart de hauteur au-delà duquel la clairière renonce à aplanir. Empêche le
## replat de tailler dans la falaise qui le domine.
@export var bunker_max_delta: float = 12.0

@export_group("Clairières")
## Nombre de replats tentés. Un emplacement refusé (sur le massif, sous l'eau,
## sur la clairière du bunker, trop près du bord) n'est pas remplacé : le compte
## est un maximum, pas une garantie.
@export_range(0, 60) var clearing_count: int = 16
## Rayon aplani, tiré dans cette fourchette.
@export var clearing_radius_range: Vector2 = Vector2(16.0, 42.0)
## Distance d'adoucissement au-delà du rayon.
@export var clearing_falloff: float = 26.0
## Écart de hauteur au-delà duquel un replat renonce à aplanir.
@export var clearing_max_delta: float = 10.0
## Influence du massif au-dessus de laquelle un emplacement est refusé. Les
## clairières sont une feature de plaine et de bas de versant.
@export_range(0.0, 1.0) var clearing_max_massif_influence: float = 0.15
## Hauteur minimale au-dessus du niveau de l'eau.
@export var clearing_min_above_water: float = 4.0
## Part du relief effacée au centre du replat. 1 = plan parfait, et ça se voit :
## une clairière de forêt n'est pas un terrain de sport. En dessous de 1, le
## micro-relief du vallonnement subsiste, proportionnellement.
@export_range(0.0, 1.0) var clearing_flatten_strength: float = 0.75

@export_group("Vallée de la rivière")
## Écart entre la grotte et l'axe de vallée, en fraction de la taille de zone,
## mesuré côté versant ouvert. 1/6 partage la zone praticable en 2/3 – 1/3.
@export var valley_offset_ratio: float = 0.25
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
## Largeur du lit, en mètres — fourchette parcourue le long du cours. Repères
## réels : Saône 30-50 m, Rhône jusqu'à 60 m dans Lyon, Seine 170 m à Rouen.
## Un fleuve de 300 m mangerait la carte ; 50-60 m se traverse en pont et se
## lit comme un fleuve.
@export var river_width_range: Vector2 = Vector2(42.0, 68.0)
## Profondeur du lit sous la ligne d'eau, en mètres. Les fleuves français vont
## de 5 à 30 m. Le minimum compte plus que le maximum : sous une dizaine de
## mètres, les passages les moins creusés cessent de se lire comme un lit.
@export var river_depth_range: Vector2 = Vector2(12.0, 24.0)
## Encaissement : de combien la surface de l'eau est sous le terrain qu'elle
## traverse, en mètres.
##
## Sans lui, la ligne d'eau est posée à l'altitude du sol et le fleuve coule au
## ras de la plaine : le moindre creux alentour passe sous la nappe, et l'eau
## se répand en feuilles au-dessus de la forêt. Un fleuve coule dans ses berges.
@export var river_freeboard: float = 6.0
## Largeur de la berge adoucie de part et d'autre du lit. Plus large que le lit
## et elle avale l'entaille avant qu'elle existe.
@export var river_bank: float = 18.0
## Longueur d'un pas de tracé, en mètres.
@export var river_step: float = 6.0

## Amplitude du méandre principal, en mètres. Deux harmoniques plus courtes s'y
## ajoutent — c'est ce qui fait une boucle de Seine plutôt qu'une sinusoïde.
## Le total dépasse l'amplitude d'environ deux tiers : la garder sous la
## demi-largeur de vallée évite que le cours ne grimpe sur les versants.
@export var river_meander_amplitude_range: Vector2 = Vector2(45.0, 75.0)
## Longueur d'onde du méandre principal, en mètres.
@export var river_meander_wavelength_range: Vector2 = Vector2(260.0, 460.0)

## Chance qu'un bras secondaire se détache et laisse une île. Le tirage peut
## échouer faute de portion émergée assez longue : la fréquence réelle est plus
## basse que ce réglage.
@export_range(0.0, 1.0) var river_island_chance: float = 0.7
## Longueur de l'île, en mètres.
@export var river_island_length_range: Vector2 = Vector2(160.0, 320.0)
## Écartement du bras secondaire, en multiples de la largeur du lit. Sous 2, les
## deux bras se rejoignent et l'île n'existe pas.
@export var river_island_spread: float = 3.0

@export_group("Lac")
## Position du rivage sur l'axe d'écoulement, en fraction de la demi-zone vers
## l'aval. Le niveau de l'eau est la hauteur du fond de vallée à cet endroit :
## tout ce qui est plus bas est noyé, en aval comme ailleurs sur la carte. Le
## lac s'étend donc au-delà de la zone jouable sans qu'on ait à le dessiner.
@export_range(0.0, 1.0) var lake_shore_along_ratio: float = 0.45

@export_group("Végétation")
## Hauteur minimale au-dessus de l'eau pour qu'une plante pousse.
@export var foliage_water_margin: float = 1.5
## Strates de végétation, **dans l'ordre de semis**. Chacune lit l'occupation
## laissée par les précédentes ; l'ordre n'est donc pas cosmétique.
##
## Une strate porte la grille et la réponse au lieu ; ce qui y pousse vient des
## biomes ci-dessous.
@export var layers: Array[FoliageLayer] = []
## Biomes de la carte. Leur ordre n'a qu'une conséquence : le premier sert de
## recours là où aucun autre ne revendique un point. Ils ne se départagent pas
## par priorité mais par poids — voir `BiomeMap`.
@export var biomes: Array[BiomeDef] = []
## Distance autour du point de vue où les strates streamées sont semées, en
## mètres. Au-delà, leurs tuiles sont libérées. À tenir sous
## `foliage_view_distance` : semer ce qui n'est pas dessiné ne sert à rien.
@export_range(20.0, 400.0, 5.0) var stream_distance: float = 90.0
## Côté d'une tuile de streaming, en cellules. **Rien à voir avec `chunk_cells`,
## et c'est le but** : un chunk de terrain porte le culling et les ombres, une
## tuile porte le semis à la demande. Au grain du chunk, une tuile de sol tient
## seize mille candidats et son semis bloque la frame ; le coût d'une tuile va
## comme le carré de son côté, donc la diviser par quatre le divise par seize.
@export_range(2, 64) var stream_tile_cells: int = 8
## Côté d'une cellule de la carte d'occupation, en mètres. Elle enregistre les
## bases posées et la couverture du feuillage — voir `ScatterOccupancy`.
@export_range(0.25, 8.0, 0.25) var occupancy_cell_size: float = 1.0
## Distance au-delà de laquelle la végétation cesse d'être dessinée, en mètres.
## Ce n'est pas un aveu de faiblesse : au-delà, c'est le brouillard qui doit
## porter la profondeur et le relief nu qui doit porter la silhouette. Régler de
## pair avec la densité de brouillard — les arbres doivent disparaître là où on
## ne les distingue déjà plus.
@export_range(50.0, 2000.0, 10.0) var foliage_view_distance: float = 350.0
## Distance d'effacement progressif avant la limite, en mètres. À 0, la
## disparition est nette.
@export_range(0.0, 300.0, 5.0) var foliage_fade_margin: float = 80.0
## Hauteur de canopée retenue pour estimer la longueur des ombres, en mètres.
## Sert au seul tri des chunks qui projettent une ombre utile : la portée, elle,
## est lue sur la lumière. Voir `FoliageProximity`.
@export_range(2.0, 80.0, 1.0) var canopy_height: float = 25.0

@export_group("Rendu")
@export var terrain_material: Material
@export var water_material: Material


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


## Hauteur interpolée en un point monde quelconque. Cas particulier de
## `sample_grid()` : une heightmap est une grandeur par sommet comme une autre.
func sample_height(heights: PackedFloat32Array, p: Vector2) -> float:
	return sample_grid(heights, p)


## Valeur interpolée d'une grandeur quelconque définie par sommet de la grille —
## hauteur du sol, poids de biome. Vit ici parce que la convention de grille vit
## ici : il n'existe qu'une écriture de cette interpolation, et tout ce qui est
## calculé par sommet peut être lu au point sans en réécrire une seconde.
func sample_grid(values: PackedFloat32Array, p: Vector2) -> float:
	var n := grid_size()
	var half := half_size()
	var fx := (p.x + half) / cell_size
	var fz := (p.y + half) / cell_size
	var ix := clampi(int(floor(fx)), 0, n - 2)
	var iz := clampi(int(floor(fz)), 0, n - 2)
	var tx := clampf(fx - ix, 0.0, 1.0)
	var tz := clampf(fz - iz, 0.0, 1.0)
	var low := lerpf(values[height_index(ix, iz)], values[height_index(ix + 1, iz)], tx)
	var high := lerpf(values[height_index(ix, iz + 1)], values[height_index(ix + 1, iz + 1)], tx)
	return lerpf(low, high, tz)


## Emprise au sol d'un chunk. La convention de grille vit ici : le semis, le
## mesh et tout ce qui raisonne par chunk lisent la même écriture. Le dernier
## chunk d'une rangée peut dépasser la zone — sans conséquence, rien ne s'y sème.
func chunk_area(cx: int, cz: int) -> Rect2:
	return _grid_area(cx, cz, chunk_cells)


## Emprise au sol d'une tuile de streaming. Même convention que les chunks, à un
## autre grain : les deux découpages partagent l'origine de la zone, donc une
## tuile ne chevauche jamais deux chunks tant que `chunk_cells` est un multiple
## de `stream_tile_cells`.
func stream_tile_area(tx: int, tz: int) -> Rect2:
	return _grid_area(tx, tz, stream_tile_cells)


## Nombre de tuiles de streaming par côté de la zone.
func stream_tiles_per_side() -> int:
	return int(ceil(float(cell_count()) / float(stream_tile_cells)))


func _grid_area(gx: int, gz: int, cells: int) -> Rect2:
	var span := cells * cell_size
	var half := half_size()
	return Rect2(Vector2(-half + gx * span, -half + gz * span), Vector2(span, span))


## Position monde (plan XZ) d'un sommet de la grille.
func world_pos(ix: int, iz: int) -> Vector2:
	var half := half_size()
	return Vector2(-half + ix * cell_size, -half + iz * cell_size)
