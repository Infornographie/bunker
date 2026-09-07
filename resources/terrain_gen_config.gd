@tool
class_name TerrainGenConfig
extends Resource
## Paramètres du terrain — source unique des réglages de la chaîne heightmap →
## mesh, et de la convention de coordonnées de la grille.
##
## Repères posés ici et valables pour toute la chaîne :
## - la zone est un carré centré sur l'origine du monde ;
## - l'origine (0,0) est la bouche de la grotte du bunker : tout se situe par
##   rapport à elle ;
## - la carte est **déclarée**, pas tirée. Deux générations donnent la même
##   carte, et changer la carte veut dire changer une valeur ici.

## Graine du **semis**, et d'elle seule : le relief est déclaré, pas tiré. Elle
## décide de la répartition du feuillage et des lisières de biome, jamais de la
## forme de la carte.
@export var world_seed: int = 1337

@export_group("Zone")
## Côté de la zone générée, en mètres.
@export var size_meters: float = 384.0
## Distance entre deux sommets de la heightmap.
@export_range(0.5, 8.0, 0.5) var cell_size: float = 3.0
## Côté d'un chunk, en cellules.
@export_range(8, 128) var chunk_cells: int = 32

@export_group("Colline")
## Centre de la colline dans le plan XZ, en mètres.
@export var hill_centre: Vector2 = Vector2(-80.0, -80.0)
## Rayon au pied de la colline, en mètres. Croisé avec la hauteur, il donne la
## pente : à 45 m pour 120 m, le versant plafonne autour de 20°, donc reste
## marchable partout. C'est le couple à bouger pour tester une pente refusée.
@export var hill_radius: float = 120.0
## Altitude du sommet au-dessus de la plaine, en mètres.
@export var hill_height: float = 45.0

@export_group("Eau")
## Altitude du plan d'eau. La plaine étant à zéro, une valeur négative garde
## l'eau dans le seul lit de la rivière ; une valeur positive noie la plaine.
@export var water_level: float = -3.0
## Tracé de la rivière dans le plan XZ, déclaré point par point. C'est le
## premier réglage à bouger pour changer la forme de la carte.
@export var river_points: PackedVector2Array = PackedVector2Array([
	Vector2(-192.0, 150.0), Vector2(-40.0, 108.0), Vector2(70.0, 128.0), Vector2(192.0, 86.0)])
## Position du gué dans le plan XZ — à poser sur le tracé. Le lit y est relevé
## juste sous la ligne d'eau : la rivière continue de couler, elle devient
## seulement traversable. Un lit interrompu ferait un pont à sec, pas un gué.
@export var river_ford: Vector2 = Vector2(15.0, 118.0)
## Rayon du haut-fond, en mètres. 0 rend la rivière infranchissable.
@export var river_ford_radius: float = 9.0
## Distance d'adoucissement au-delà du rayon — c'est la pente d'entrée dans
## l'eau. Trop courte et le gué est une marche.
@export var river_ford_falloff: float = 8.0
## Hauteur d'eau au-dessus du gué, en mètres.
@export var river_ford_depth: float = 0.4
## Largeur du lit, en mètres.
@export var river_width: float = 12.0
## Profondeur du lit sous la ligne d'eau, en mètres.
@export var river_depth: float = 6.0
## Largeur de la berge adoucie de part et d'autre du lit. Plus large que le lit
## et elle avale l'entaille avant qu'elle existe.
@export var river_bank: float = 5.0

@export_group("Clairière du bunker")
## Rayon aplani autour de la bouche de grotte, toujours à l'origine du monde.
@export var bunker_radius: float = 26.0
## Distance d'adoucissement au-delà du rayon.
@export var bunker_falloff: float = 40.0
## Écart de hauteur au-delà duquel la clairière renonce à aplanir.
@export var bunker_max_delta: float = 12.0

@export_group("Clairières")
## Replats déclarés, en (x, z, rayon). La clairière du bunker n'est pas dans
## cette liste : elle est posée à part parce que sa position est une contrainte,
## pas un réglage.
@export var clearings: PackedVector3Array = PackedVector3Array([
	Vector3(100.0, -60.0, 30.0), Vector3(-40.0, 40.0, 24.0), Vector3(150.0, 30.0, 20.0)])
## Distance d'adoucissement au-delà du rayon.
@export var clearing_falloff: float = 26.0
## Écart de hauteur au-delà duquel un replat renonce à aplanir.
@export var clearing_max_delta: float = 10.0
## Part du relief effacée au centre du replat. 1 = plan parfait, et ça se voit :
## une clairière de forêt n'est pas un terrain de sport.
@export_range(0.0, 1.0) var clearing_flatten_strength: float = 0.75

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
