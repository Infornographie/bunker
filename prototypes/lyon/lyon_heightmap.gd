@tool
class_name LyonHeightmap
extends RefCounted

## Carte de hauteurs issue du MNT 50 cm du Grand Lyon, rééchantillonnée à 3 m.
##
## Lit un couple de fichiers produits hors moteur : un `.f32` de valeurs brutes
## et un `.json` qui décrit sa grille. Les dimensions ne sont donc écrites
## qu'à un seul endroit — le json — et jamais recopiées dans une scène.
##
## Disposition du `.f32` : float32 petit-boutiste, row-major,
## ligne 0 au SUD (+Z), colonne 0 à l'OUEST (+X), altitudes absolues en mètres.

var cols: int = 0
var rows: int = 0
var cell_size: float = 0.0
var alt_min: float = 0.0
var alt_max: float = 0.0
var heights: PackedFloat32Array = PackedFloat32Array()

## Largeur (X) et profondeur (Z) du terrain en mètres.
var width_m: float:
	get: return float(cols - 1) * cell_size

var depth_m: float:
	get: return float(rows - 1) * cell_size

var amplitude_m: float:
	get: return alt_max - alt_min


## Charge la carte décrite par `<base_path>.json` et `<base_path>.f32`.
## Renvoie null et pousse une erreur si quoi que ce soit ne colle pas :
## une carte à moitié chargée produirait un terrain silencieusement faux.
static func load_pair(base_path: String) -> LyonHeightmap:
	var meta_path: String = base_path + ".json"
	var data_path: String = base_path + ".f32"

	var meta_text: String = FileAccess.get_file_as_string(meta_path)
	if meta_text.is_empty():
		push_error("LyonHeightmap : json introuvable ou vide — " + meta_path)
		return null

	var parsed: Variant = JSON.parse_string(meta_text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("LyonHeightmap : json illisible — " + meta_path)
		return null
	var meta: Dictionary = parsed

	for key: String in ["cols", "rows", "cell_m", "alt_min_m", "alt_max_m"]:
		if not meta.has(key):
			push_error("LyonHeightmap : clé « %s » absente de %s" % [key, meta_path])
			return null

	var map := LyonHeightmap.new()
	map.cols = int(meta["cols"])
	map.rows = int(meta["rows"])
	map.cell_size = float(meta["cell_m"])
	map.alt_min = float(meta["alt_min_m"])
	map.alt_max = float(meta["alt_max_m"])

	var file: FileAccess = FileAccess.open(data_path, FileAccess.READ)
	if file == null:
		push_error("LyonHeightmap : .f32 introuvable — " + data_path)
		return null
	var raw: PackedByteArray = file.get_buffer(file.get_length())
	file.close()

	var expected: int = map.cols * map.rows * 4
	if raw.size() != expected:
		push_error("LyonHeightmap : %s fait %d octets, %d attendus (%d x %d floats)"
				% [data_path, raw.size(), expected, map.cols, map.rows])
		return null

	map.heights = raw.to_float32_array()
	return map


## Altitude absolue au sommet de grille (col, row), bornée aux bords.
func height_at_vertex(col: int, row: int) -> float:
	var c: int = clampi(col, 0, cols - 1)
	var r: int = clampi(row, 0, rows - 1)
	return heights[r * cols + c]


## Altitude absolue en coordonnées locales du terrain, interpolée bilinéairement.
## (0, 0) est le coin sud-ouest.
func height_at(local_x: float, local_z: float) -> float:
	var fx: float = clampf(local_x / cell_size, 0.0, float(cols - 1))
	var fz: float = clampf(local_z / cell_size, 0.0, float(rows - 1))
	var c0: int = int(fx)
	var r0: int = int(fz)
	var c1: int = mini(c0 + 1, cols - 1)
	var r1: int = mini(r0 + 1, rows - 1)
	var tx: float = fx - float(c0)
	var tz: float = fz - float(r0)

	var h00: float = heights[r0 * cols + c0]
	var h10: float = heights[r0 * cols + c1]
	var h01: float = heights[r1 * cols + c0]
	var h11: float = heights[r1 * cols + c1]
	return lerpf(lerpf(h00, h10, tx), lerpf(h01, h11, tx), tz)
