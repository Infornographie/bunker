@tool
class_name MassifShape
extends RefCounted
## Un massif : son repère, ses dimensions, et le profil de relief qu'il produit.
##
## Extrait du générateur pour qu'il puisse en exister plus d'un. Tant que la
## forme vivait dans des champs du générateur, « deux massifs » demandait de
## dupliquer le générateur — ce qui n'a pas de sens, il n'y a qu'une carte.
##
## **Le repère est la vraie raison d'être de cette classe.** `along` court le
## long de la crête, `side` en travers, orienté vers le versant qui porte la
## falaise. Tout ce qui se rapporte au massif se calcule là-dedans, et personne
## n'a besoin de savoir que l'orientation a été tirée au hasard.
##
## Ce qui n'est PAS ici : la vallée, la pente de drainage, le vallonnement. Ils
## s'alignent sur ce repère mais ne lui appartiennent pas — la carte n'a qu'une
## vallée et qu'un sens d'écoulement, quel que soit le nombre de massifs.

## Le long de la crête, et en travers vers le versant de la falaise.
var axis: Vector2
var side: Vector2
var half_length: float
var half_width: float
## Décalage de l'axe en travers, dans le repère monde.
var side_base: float
## Altitude de crête avant modulation par le profil.
var height: float

var _cfg: TerrainGenConfig
var _wobble: FastNoiseLite
var _profile: FastNoiseLite


## Tire une forme dans les fourchettes de la config. **L'ordre des tirages fait
## partie du contrat de la graine** : le changer change toutes les cartes
## existantes. Le `rng` est fourni par l'appelant, qui reste seul maître de la
## chaîne de hasard.
static func draw(cfg: TerrainGenConfig, rng: RandomNumberGenerator,
		wobble: FastNoiseLite, profile: FastNoiseLite) -> MassifShape:
	var shape := MassifShape.new()
	shape._cfg = cfg
	shape._wobble = wobble
	shape._profile = profile

	var angle := deg_to_rad(rng.randf_range(cfg.massif_angle_range.x, cfg.massif_angle_range.y))
	shape.axis = Vector2(cos(angle), sin(angle))
	shape.side = Vector2(-shape.axis.y, shape.axis.x)

	var size := cfg.size_meters
	shape.half_length = rng.randf_range(cfg.massif_half_length_ratio_range.x, cfg.massif_half_length_ratio_range.y) * size
	shape.half_width = rng.randf_range(cfg.massif_half_width_ratio_range.x, cfg.massif_half_width_ratio_range.y) * size
	shape.height = rng.randf_range(cfg.massif_height_range.x, cfg.massif_height_range.y)

	# L'axe est décalé pour que le pied de la falaise passe par l'origine au
	# milieu du massif, méandre compris : c'est là que s'ouvre la grotte.
	var foot_distance := shape.half_width * (1.0 - cfg.cliff_position)
	shape.side_base = -foot_distance - shape.wobble_at(0.0)
	return shape


## Coordonnées d'un point monde dans le repère du massif : (le long, en travers).
func local_of(world_point: Vector2) -> Vector2:
	return Vector2(world_point.dot(axis), world_point.dot(side))


## Retourne (hauteur du massif, masque de falaise, influence) en coordonnées
## locales. Les trois sortent du même calcul de profil, d'où le Vector3 plutôt
## que trois passes identiques. L'influence vaut 1 sur l'axe et 0 hors du
## massif : c'est la mesure de « à quel point on est en montagne ».
func sample(along: float, side_distance: float) -> Vector3:
	var taper := 1.0 - smoothstep(0.0, 1.0, absf(along) / half_length)
	if taper <= 0.0:
		return Vector3.ZERO

	var across := side_distance - side_base - wobble_at(along)
	var t := 1.0 - absf(across) / half_width
	if t <= 0.0:
		return Vector3.ZERO

	var c := _cfg.cliff_position
	var band := minf(_cfg.cliff_band_ratio, (1.0 - c) * 0.9)
	var hc := _cfg.cliff_height_ratio

	var shape := 0.0
	var cliff_mask := 0.0
	if across <= 0.0:
		# Versant opposé à la falaise : un simple dôme.
		shape = smoothstep(0.0, 1.0, t)
	else:
		# Hauteur du pied de falaise : la hauteur hors falaise se répartit entre
		# le versant du dessous et le dôme du dessus au prorata de leur largeur.
		var base_height := (1.0 - hc) * c / (1.0 - band)
		if t <= c:
			shape = base_height * smoothstep(0.0, 1.0, t / c)
		elif t <= c + band:
			shape = base_height + hc * smoothstep(0.0, 1.0, (t - c) / band)
		else:
			var top := base_height + hc
			shape = top + (1.0 - top) * smoothstep(0.0, 1.0, (t - c - band) / (1.0 - c - band))
		# Le masque déborde de la bande et s'éteint progressivement. Un masque
		# binaire coupait net le vallonnement au bord de la paroi : la marche qui
		# en résultait creusait une rainure sur toute la hauteur, de chaque côté.
		var outside := maxf(maxf(c - t, t - c - band), 0.0)
		cliff_mask = (1.0 - smoothstep(0.0, band, outside)) * taper

	return Vector3(shape * taper * amplitude_at(along), cliff_mask, shape * taper)


## Méandre de la crête : c'est lui qui empêche l'axe d'être une droite.
func wobble_at(along: float) -> float:
	return _wobble.get_noise_2d(0.0, along) * _cfg.massif_wobble


## Altitude de l'axe à cette abscisse — c'est elle qui creuse les cols.
func amplitude_at(along: float) -> float:
	var v := 0.5 + 0.5 * _profile.get_noise_2d(1000.0, along)
	return height * (1.0 - _cfg.massif_profile_variation * v)
