extends Resource
class_name SkyProfile

## Un ciel complet : couleurs, nuages, soleil, brume. C'est l'unité de CLIMAT,
## pas de moment — le moment est géré par le shader, à partir de l'élévation du soleil.
##
## Un profil décrit donc une journée entière par temps donné : `clear_day` couvre
## son aube, son midi, son couchant et sa nuit. Le jour où le climat arrivera,
## changer de temps sera un fondu d'un profil vers un autre.
##
## Règle qui rend ce fondu possible, et qu'il ne faut pas casser : un profil fait
## varier des UNIFORMES, jamais des textures. Deux flottants se fondent, deux
## NoiseTexture2D non — et un ciel qui change de nuages au milieu d'un fondu ruine
## l'effet. Les textures de nuages vivent dans le rig et sont les mêmes pour tous
## les profils.
##
## Toutes les courbes et gradients s'échantillonnent en `TimeOfDay.time_of_day`
## (temps canonique 0→1), jamais en temps réel : retoucher la répartition du cycle
## ne doit pas déplacer une couleur.
##
## Ce que ce profil NE contient PAS, volontairement : la couleur du brouillard.
## Elle est produite par le ciel lui-même (`fog_sky_affect`), et la réécrire à la
## main serait la même vérité à deux endroits.

@export_group("Ciel")
@export var sky_day := Color(0.24, 0.44, 0.72)
@export var horizon_day := Color(0.72, 0.82, 0.86)
## Le shader n'a qu'un seul jeu de couleurs de « sunset », et son mélange est
## symétrique : il ne peut pas distinguer l'aube du couchant. Nous si — on connaît
## le sens de la course. Le contrôleur écrit l'un ou l'autre selon que le soleil monte.
@export var sky_dawn := Color(0.30, 0.34, 0.52)
@export var horizon_dawn := Color(0.92, 0.62, 0.52)
@export var sky_dusk := Color(0.22, 0.20, 0.40)
@export var horizon_dusk := Color(0.95, 0.42, 0.16)
@export var sky_night := Color(0.03, 0.05, 0.10)
@export var horizon_night := Color(0.07, 0.10, 0.16)
@export_range(0.5, 8.0, 0.1) var horizon_exponent := 2.4
@export_range(0.1, 4.0, 0.05) var sunset_amount_exponent := 0.7
@export_range(0.5, 10.0, 0.1) var night_amount_exponent := 4.0

@export_group("Nuages")
@export var cloud_color := Color(0.92, 0.92, 0.94)
@export var cloud_tiling := Vector2(1.0, 1.0)
@export var wind_speed := Vector2(0.35, 0.2)
@export_range(0.0, 5.0, 0.05) var cloud_density := 0.65
@export_range(0.0, 10.0, 0.1) var cloud_depth := 2.0
@export_range(0.1, 8.0, 0.1) var cloud_shape_exponent := 2.0
@export_range(0.1, 8.0, 0.1) var cloud_occlude_exponent := 1.0

@export_group("Soleil")
## Pilote À LA FOIS la DirectionalLight3D et le disque du ciel. Deux couleurs pour
## un seul soleil finiraient par diverger au couchant.
@export var sun_color: Gradient
@export var sun_energy: Curve
@export_range(0.005, 0.3, 0.001) var sun_disc_scale := 0.04
@export_range(0.0, 40.0, 0.5) var sun_disc_strength := 14.0

@export_group("Lune")
@export var moon_color := Color(0.55, 0.60, 0.74)
@export_range(0.005, 0.3, 0.001) var moon_scale := 0.028
@export_range(0.0, 40.0, 0.5) var moon_strength := 5.0

@export_group("Atmosphère")
@export var ambient_energy: Curve
## Distance à laquelle la brume est pleine. Plus elle est courte, plus l'air est épais.
## Se règle DE PAIR avec `foliage_view_distance` : la brume doit être quasi opaque
## avant le début de la marge de fondu du feuillage, sinon la coupure se voit.
@export var fog_depth_end: Curve
@export_range(0.0, 500.0, 1.0) var fog_depth_begin := 40.0
@export_range(0.0, 4.0, 0.05) var fog_depth_curve := 1.0
