@tool
class_name HeightmapOps
extends RefCounted
## Le tableau de hauteurs et les opérations qui le déforment.
##
## **Pourquoi un objet et pas des fonctions statiques.** Un `PackedFloat32Array`
## est une valeur à copie sur écriture : une fonction qui en reçoit un et écrit
## dedans écrit dans sa propre copie, sans erreur ni avertissement, et l'appelant
## garde son tableau d'origine. Des opérateurs statiques devraient donc retourner
## le tableau à chaque appel, en laissant l'appelant libre d'oublier la
## réaffectation. Ici l'objet possède le tableau : il n'existe qu'un propriétaire,
## et une opération est un appel, pas une affectation à ne pas rater.
##
## Ce que chaque opérateur a en commun : il borne son travail à l'emprise qu'il
## touche, jamais à la carte entière. C'est ce qui permettra d'en enchaîner
## beaucoup quand les features du catalogue existeront.

## Hauteurs des sommets de la grille, indexées par TerrainGenConfig.height_index().
##
## Se lit librement, mais **ne s'écrit pas de l'extérieur** : `ops.heights[i] = x`
## passe par une copie de la propriété et n'écrit nulle part, silencieusement.
## Le relief de départ arrive donc par le constructeur, et tout ce qui le déforme
## ensuite est un opérateur de cette classe.
var heights: PackedFloat32Array

var _cfg: TerrainGenConfig
var _n: int


func _init(cfg: TerrainGenConfig, initial_heights: PackedFloat32Array) -> void:
	_cfg = cfg
	_n = cfg.grid_size()
	heights = initial_heights


## Hauteur interpolée en un point monde.
func sample(point: Vector2) -> float:
	return _cfg.sample_height(heights, point)


## Aplanit un disque sur la hauteur de son centre. L'aplanissement renonce là où
## le terrain s'écarte trop de la cible : sans ça, le disque taillerait une
## marche nette dès qu'il mord sur un relief qui le domine.
func flatten_disc(centre: Vector2, radius: float, falloff: float, max_delta: float, strength: float) -> void:
	var target := sample(centre)
	var outer := radius + falloff
	var box := _cell_box(centre - Vector2(outer, outer), centre + Vector2(outer, outer))

	for iz in range(box.y, box.w + 1):
		for ix in range(box.x, box.z + 1):
			var dist := _cfg.world_pos(ix, iz).distance_to(centre)
			if dist >= outer:
				continue
			var idx := _cfg.height_index(ix, iz)
			var h := heights[idx]
			var w := strength * (1.0 - smoothstep(radius, outer, dist))
			w *= 1.0 - smoothstep(max_delta, max_delta * 2.0, absf(h - target))
			heights[idx] = lerpf(h, target, w)


## Creuse un chenal le long d'une polyligne, sous une ligne d'eau donnée point
## par point. Le lit descend au niveau demandé, les berges rejoignent le terrain
## existant sur `bank` mètres. Le terrain n'est jamais remonté : un chenal creuse.
##
## Largeur et profondeur sont données **par point** et interpolées le long de
## chaque segment. Un fleuve de largeur constante se lit comme un canal : c'est
## le resserrement dans les coudes et l'évasement dans les courbes qui le font
## passer pour un cours d'eau.
func carve_channel(path: PackedVector2Array, water: PackedFloat32Array,
		widths: PackedFloat32Array, bank: float, depths: PackedFloat32Array) -> void:

	for i in path.size() - 1:
		var a := path[i]
		var b := path[i + 1]
		var ab := b - a
		var ab_len_sq := ab.length_squared()
		if ab_len_sq < 1e-6:
			continue

		# L'emprise du segment se prend sur la plus large de ses deux extrémités.
		var inner := maxf(widths[i], widths[i + 1]) * 0.5
		var outer := inner + bank
		var lo := Vector2(minf(a.x, b.x), minf(a.y, b.y)) - Vector2(outer, outer)
		var hi := Vector2(maxf(a.x, b.x), maxf(a.y, b.y)) + Vector2(outer, outer)
		var box := _cell_box(lo, hi)

		for iz in range(box.y, box.w + 1):
			for ix in range(box.x, box.z + 1):
				var wp := _cfg.world_pos(ix, iz)
				var s := clampf((wp - a).dot(ab) / ab_len_sq, 0.0, 1.0)
				var dist := wp.distance_to(a + ab * s)
				if dist >= outer:
					continue
				var idx := _cfg.height_index(ix, iz)
				var lit := lerpf(widths[i], widths[i + 1], s) * 0.5
				var bed := lerpf(water[i], water[i + 1], s) - lerpf(depths[i], depths[i + 1], s)
				var carved := bed
				if dist > lit:
					var k := smoothstep(0.0, 1.0, clampf((dist - lit) / bank, 0.0, 1.0))
					carved = lerpf(bed, heights[idx], k)
				heights[idx] = minf(heights[idx], carved)


## Indices de grille couvrant une emprise monde, bornés à la carte, en
## (ix0, iz0, ix1, iz1). Les deux bornes s'arrondissent vers l'extérieur : un
## `floor` d'un côté et un `ceil` de l'autre perdraient la cellule de frontière.
func _cell_box(lo: Vector2, hi: Vector2) -> Vector4i:
	var half := _cfg.half_size()
	return Vector4i(
		clampi(int(floor((lo.x + half) / _cfg.cell_size)), 0, _n - 1),
		clampi(int(floor((lo.y + half) / _cfg.cell_size)), 0, _n - 1),
		clampi(int(ceil((hi.x + half) / _cfg.cell_size)), 0, _n - 1),
		clampi(int(ceil((hi.y + half) / _cfg.cell_size)), 0, _n - 1))
