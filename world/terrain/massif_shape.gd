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
## **Tirer et placer sont deux gestes séparés.** Le massif principal se place par
## résolution — le pied de sa falaise doit tomber sur la bouche de grotte, à
## l'origine du monde — alors que tout autre massif se place où on le lui dit.
## Confondre les deux, c'est ne pouvoir en avoir qu'un : tous naîtraient au même
## endroit. `draw()` ne fait donc que tirer une forme, et le placement est un
## second appel, explicite.
##
## Ce qui n'est PAS ici : la vallée, la pente de drainage, le vallonnement. Ils
## s'alignent sur ce repère mais ne lui appartiennent pas — la carte n'a qu'une
## vallée et qu'un sens d'écoulement, quel que soit le nombre de massifs.

## Le long de la crête, et en travers vers le versant de la falaise.
var axis: Vector2
var side: Vector2
var half_length: float
var half_width: float
## Altitude de crête avant modulation par le profil.
var height: float

## Placement, en projections du centre du massif sur son propre repère. Deux
## scalaires plutôt qu'un point : c'est sous cette forme que le repère les
## consomme, et un point obligerait à reprojeter à chaque lecture.
var along_base: float
var side_base: float

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
	return shape


## Tire un éperon perpendiculaire à la crête d'un massif hôte, et le place.
##
## Tirage et placement sont faits ensemble ici, contrairement au massif
## principal, parce qu'un éperon n'existe que par rapport à son hôte : il n'y a
## pas de forme d'éperon indépendante d'une crête à laquelle s'accrocher.
##
## **Le centre est posé sur le pied de falaise de l'hôte**, pas sur sa crête :
## l'éperon part donc du versant, traverse la vallée et s'éteint au-delà. La
## moitié qui remonte dans le massif disparaît sous lui au `max`, gratuitement.
static func draw_spur(cfg: TerrainGenConfig, rng: RandomNumberGenerator,
		wobble: FastNoiseLite, profile: FastNoiseLite, host: MassifShape) -> MassifShape:
	var spur := MassifShape.new()
	spur._cfg = cfg
	spur._wobble = wobble
	spur._profile = profile

	var deviation := deg_to_rad(rng.randf_range(-cfg.spur_angle_deviation, cfg.spur_angle_deviation))
	spur.axis = host.side.rotated(deviation)
	spur.side = Vector2(-spur.axis.y, spur.axis.x)

	var size := cfg.size_meters
	spur.half_length = rng.randf_range(cfg.spur_half_length_ratio_range.x, cfg.spur_half_length_ratio_range.y) * size
	spur.half_width = rng.randf_range(cfg.spur_half_width_ratio_range.x, cfg.spur_half_width_ratio_range.y) * size
	spur.height = host.height * rng.randf_range(cfg.spur_height_ratio_range.x, cfg.spur_height_ratio_range.y)

	# Position le long de la crête hôte, d'un côté ou de l'autre. Le plancher
	# tient l'éperon à l'écart de la bouche de grotte : elle est à l'origine, et
	# un éperon qui passe dessus la mure.
	var along := rng.randf_range(cfg.spur_along_ratio_range.x, cfg.spur_along_ratio_range.y) * host.half_length
	if rng.randf() < 0.5:
		along = -along
	var clearance := spur.half_width + cfg.bunker_radius + cfg.bunker_falloff
	along = signf(along) * maxf(absf(along), clearance)

	spur.place_at(host.axis * along)
	return spur


## Place le massif pour que le pied de sa falaise passe par l'origine du monde,
## au milieu de la crête et méandre compris : c'est là que s'ouvre la grotte.
## Un placement par **résolution**, pas par réglage — d'où l'absence de position
## de massif dans la config.
func place_cliff_foot_at_origin() -> void:
	along_base = 0.0
	side_base = -(half_width * (1.0 - _cfg.cliff_position)) - wobble_at(0.0)


## Place le centre du massif sur un point monde. C'est le placement de tout
## massif qui n'est pas le principal.
func place_at(centre: Vector2) -> void:
	along_base = centre.dot(axis)
	side_base = centre.dot(side)


## Projections d'un point monde sur les directions du massif, **origine au
## monde** : (le long, en travers). C'est le repère de ce qui s'aligne sur son
## axe sans lui appartenir — la vallée, la pente d'écoulement.
##
## Le retour est un `Vector2`, donc arrondi à 32 bits là où `dot()` calcule en
## 64. Ce n'est pas un détail de style : ce passage est une étape d'arrondi, et
## la remplacer par deux `dot()` directs déplace tous les sommets de la carte de
## quelques millièmes de millimètre. Assez pour qu'aucun œil ne le voie, et pour
## que l'empreinte change sur toutes les graines.
func project(world_point: Vector2) -> Vector2:
	return Vector2(world_point.dot(axis), world_point.dot(side))


## Profil du massif en un point monde. Point d'entrée normal : c'est ici, et
## seulement ici, que le placement du massif entre en jeu — d'où le passage par
## `project()` plutôt qu'une projection écrite au dehors, qui oublierait un jour
## de retirer les bases.
func sample_at(world_point: Vector2) -> Vector3:
	var p := project(world_point)
	return sample(p.x - along_base, p.y - side_base)


## Retourne (hauteur du massif, masque de falaise, influence) en coordonnées
## locales. Les trois sortent du même calcul de profil, d'où le Vector3 plutôt
## que trois passes identiques. L'influence vaut 1 sur l'axe et 0 hors du
## massif : c'est la mesure de « à quel point on est en montagne ».
func sample(along: float, side_distance: float) -> Vector3:
	var taper := 1.0 - smoothstep(0.0, 1.0, absf(along) / half_length)
	if taper <= 0.0:
		return Vector3.ZERO

	var across := side_distance - wobble_at(along)
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
