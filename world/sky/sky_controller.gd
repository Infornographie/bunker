extends Node3D

## Applique l'heure au monde : oriente le soleil, écrit les uniformes du ciel,
## règle la brume et l'ambiante. Point unique — rien d'autre dans le projet
## n'écrit sur la DirectionalLight3D ni sur l'Environment.
##
## Sens de la dépendance : le contrôleur LIT `TimeOfDay` et n'écrit jamais dedans.
## L'horloge ne sait pas qu'un ciel existe.
##
## Le shader du ciel se pilote tout seul par `LIGHT0_DIRECTION.y` : on tourne la
## lumière, il en déduit jour, couchant, nuit et étoiles. Il n'y a donc aucune
## seconde horloge à synchroniser, et `day_night_mix` (son mode manuel) n'est
## jamais touché.

@export var profile: SkyProfile:
	set(value):
		profile = value
		_static_applied = false

@export var sun: DirectionalLight3D
@export var world_environment: WorldEnvironment

## En dessous de cette énergie, la lumière est éteinte : une directionnelle à
## zéro continue de coûter une passe d'ombre.
@export_range(0.0, 0.5, 0.001) var sun_off_threshold := 0.01

@export_group("Réglage")
## Multiplicateurs appliqués par-dessus les courbes du profil. Ils existent pour
## que le panneau de debug puisse chercher la bonne valeur en direct : une fois
## trouvée, elle se recopie dans la courbe du profil et le multiplicateur revient
## à 1. Ce ne sont pas des réglages de gameplay.
@export_range(0.1, 4.0, 0.01) var fog_distance_scale := 1.0
@export_range(0.0, 4.0, 0.01) var ambient_scale := 1.0

var _sky_material: ShaderMaterial
var _environment: Environment
var _static_applied := false


func _ready() -> void:
	if sun == null:
		push_error("SkyController : aucune DirectionalLight3D assignée.")
		set_process(false)
		return
	if world_environment == null or world_environment.environment == null:
		push_error("SkyController : aucun WorldEnvironment assigné, ou son Environment est vide.")
		set_process(false)
		return

	_environment = world_environment.environment
	if _environment.sky == null or _environment.sky.sky_material == null:
		push_error("SkyController : l'Environment n'a pas de Sky, ou son Sky n'a pas de matériau.")
		set_process(false)
		return

	_sky_material = _environment.sky.sky_material as ShaderMaterial
	if _sky_material == null:
		push_error("SkyController : le matériau du Sky n'est pas un ShaderMaterial.")
		set_process(false)
		return


func _process(_delta: float) -> void:
	if profile == null:
		return
	if not _static_applied:
		_apply_static()
	var t := TimeOfDay.time_of_day
	_apply_sun(t)
	_apply_sky(t)
	_apply_atmosphere(t)


# Ce qui ne dépend pas de l'heure : écrit une fois, et à chaque changement de profil.
func _apply_static() -> void:
	_static_applied = true

	_sky_material.set_shader_parameter("use_directional_light", true)
	_sky_material.set_shader_parameter("sky_day", profile.sky_day)
	_sky_material.set_shader_parameter("horizon_day", profile.horizon_day)
	_sky_material.set_shader_parameter("sky_night", profile.sky_night)
	_sky_material.set_shader_parameter("horizon_night", profile.horizon_night)
	_sky_material.set_shader_parameter("horizon_exponent", profile.horizon_exponent)
	_sky_material.set_shader_parameter("sunset_amount_exponent", profile.sunset_amount_exponent)
	_sky_material.set_shader_parameter("night_amount_exponent", profile.night_amount_exponent)

	_sky_material.set_shader_parameter("cloud_color", profile.cloud_color)
	_sky_material.set_shader_parameter("cloud_tiling", profile.cloud_tiling)
	_sky_material.set_shader_parameter("wind_speed", profile.wind_speed)
	_sky_material.set_shader_parameter("cloud_density", profile.cloud_density)
	_sky_material.set_shader_parameter("cloud_depth", profile.cloud_depth)
	_sky_material.set_shader_parameter("cloud_shape_exponent", profile.cloud_shape_exponent)
	_sky_material.set_shader_parameter("cloud_occlude_exponent", profile.cloud_occlude_exponent)

	_sky_material.set_shader_parameter("sun_scale", profile.sun_disc_scale)
	_sky_material.set_shader_parameter("sun_strength", profile.sun_disc_strength)
	_sky_material.set_shader_parameter("moon_color", profile.moon_color)
	_sky_material.set_shader_parameter("moon_scale", profile.moon_scale)
	_sky_material.set_shader_parameter("moon_strength", profile.moon_strength)

	_environment.fog_depth_begin = profile.fog_depth_begin
	_environment.fog_depth_curve = profile.fog_depth_curve


func _apply_sun(t: float) -> void:
	var elevation := deg_to_rad(TimeOfDay.sun_elevation_degrees())
	var azimuth := deg_to_rad(TimeOfDay.sun_azimuth_degrees())
	var to_sun := Vector3(
		cos(elevation) * sin(azimuth),
		sin(elevation),
		cos(elevation) * cos(azimuth)
	)

	# La lumière éclaire selon son -Z : elle regarde donc à l'opposé du soleil.
	var up := Vector3.UP if absf(to_sun.y) < 0.999 else Vector3.FORWARD
	sun.look_at_from_position(sun.global_position, sun.global_position - to_sun, up)

	# Le soleil reste TOUJOURS visible : c'est lui qui donne l'heure au shader du
	# ciel via LIGHT0_DIRECTION. Le masquer fait disparaître LIGHT0, le ciel lit
	# une direction nulle et se fige. Seule l'ombre se coupe.
	var energy := _sample(profile.sun_energy, t, 1.0)
	sun.light_energy = energy
	sun.shadow_enabled = energy > sun_off_threshold
	if profile.sun_color != null:
		sun.light_color = profile.sun_color.sample(t)


func _apply_sky(t: float) -> void:
	# Le soleil monte sur la première moitié du temps canonique (lever à 0.25,
	# midi à 0.5). L'aube et le couchant partagent les mêmes uniformes côté shader,
	# on choisit lesquels lui donner. La bascule tombe à midi, où ces couleurs
	# sont entièrement mélangées hors du ciel : elle est invisible.
	var rising := t < 0.5
	_sky_material.set_shader_parameter(
		"sky_sunset", profile.sky_dawn if rising else profile.sky_dusk
	)
	_sky_material.set_shader_parameter(
		"horizon_sunset", profile.horizon_dawn if rising else profile.horizon_dusk
	)
	if profile.sun_color != null:
		_sky_material.set_shader_parameter("sun_color", profile.sun_color.sample(t))


func _apply_atmosphere(t: float) -> void:
	_environment.ambient_light_energy = _sample(profile.ambient_energy, t, 0.5) * ambient_scale
	_environment.fog_depth_end = _sample(profile.fog_depth_end, t, 600.0) * fog_distance_scale


func _sample(curve: Curve, t: float, fallback: float) -> float:
	if curve == null:
		return fallback
	return curve.sample_baked(t)
