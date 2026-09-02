extends Node

## Horloge du monde. Source unique du moment de la journée.
##
## Deux registres, et tout le jeu lit l'un ou l'autre — jamais un seuil en dur :
##  - continu : `time_of_day`, `sun_elevation_degrees()` — pour ce qui varie (lumière, brume) ;
##  - discret : `phase` et ses signaux — pour ce qui bascule (un pawn qui va se coucher).
##
## Le temps n'avance pas à vitesse constante : l'aube et le crépuscule sont étirés,
## la nuit comprimée. Mais ce n'est PAS une courbe de vitesse qu'on intègre — c'est un
## remappage. La progression `_progress` avance linéairement sur `day_duration` secondes,
## et `time_of_day` en est déduit par une fonction affine par morceaux. Conséquence :
## une journée dure exactement `day_duration`, quelle que soit la répartition, et il n'y
## a aucune dérive à craindre.
##
## Ce qu'une phase EST se déclare en élévation du soleil (physique, jamais retouché) ;
## combien de temps elle DURE se déclare en parts (ressenti, réglé librement).

signal phase_changed(phase: int)
signal day_started
signal night_started

enum Phase { DAWN, DAY, DUSK, NIGHT }

const _PHASE_COUNT := 4

@export_group("Horloge")
## Durée réelle d'un cycle complet, en secondes.
@export var day_duration := 1800.0:
	set(value):
		day_duration = maxf(value, 1.0)
@export_range(0.0, 1.0) var start_time := 0.30
@export var paused := false

@export_group("Course du soleil")
## Élévation du soleil à midi. En dessous de 90°, les ombres restent longues toute la journée.
@export_range(10.0, 85.0) var max_elevation_degrees := 58.0:
	set(value):
		max_elevation_degrees = clampf(value, 10.0, 85.0)
		_dirty = true
## Sous cette élévation, il fait nuit.
@export_range(-20.0, 0.0) var night_elevation_degrees := -6.0:
	set(value):
		night_elevation_degrees = value
		_dirty = true
## Au-dessus de cette élévation, il fait plein jour.
@export_range(0.0, 40.0) var day_elevation_degrees := 12.0:
	set(value):
		day_elevation_degrees = value
		_dirty = true

@export_group("Répartition du cycle")
## Parts relatives de temps RÉEL accordées à chaque phase. Leur somme n'a pas
## d'importance : elles sont normalisées sur `day_duration`.
@export var dawn_share := 5.0:
	set(value):
		dawn_share = maxf(value, 0.0)
		_dirty = true
@export var day_share := 10.0:
	set(value):
		day_share = maxf(value, 0.0)
		_dirty = true
@export var dusk_share := 6.0:
	set(value):
		dusk_share = maxf(value, 0.0)
		_dirty = true
@export var night_share := 9.0:
	set(value):
		night_share = maxf(value, 0.0)
		_dirty = true

var day_count := 0

## Temps canonique de la journée, 0 à 1. Minuit = 0, lever = 0.25, midi = 0.5, coucher = 0.75.
## C'est LUI qu'on échantillonne pour toute couleur ou courbe : il ne bouge pas quand
## on retouche la répartition.
var time_of_day: float:
	get:
		return _time_of_day

var phase: int:
	get:
		return _phase

## Progression réelle dans le cycle, 0 à 1. Utile au debug, pas au gameplay.
var progress: float:
	get:
		return _progress

var _time_of_day := 0.0
var _progress := 0.0
var _phase := Phase.DAWN
var _dirty := true

# Bornes canoniques de chaque phase (en time_of_day) et leur durée.
var _canon_start := PackedFloat32Array()
var _canon_len := PackedFloat32Array()
# Bornes des mêmes phases en progression réelle.
var _real_start := PackedFloat32Array()
var _real_len := PackedFloat32Array()


func _ready() -> void:
	_rebuild()
	set_time_of_day(start_time)
	_phase = _phase_at(_progress)


func _process(delta: float) -> void:
	if _dirty:
		_rebuild()
	if paused:
		return

	_progress += delta / day_duration
	if _progress >= 1.0:
		day_count += 1
	_progress = fposmod(_progress, 1.0)
	_time_of_day = _time_from_progress(_progress)
	_update_phase()


# --- Lecture -----------------------------------------------------------------

func sun_elevation_degrees() -> float:
	return max_elevation_degrees * sin(TAU * (_time_of_day - 0.25))


func sun_azimuth_degrees() -> float:
	return 90.0 + 360.0 * (_time_of_day - 0.25)


func is_night() -> bool:
	return _phase == Phase.NIGHT


func is_daylight() -> bool:
	return _phase != Phase.NIGHT


## Secondes réelles avant le PROCHAIN début de cette phase. Si on y est déjà,
## renvoie l'attente jusqu'à sa prochaine occurrence — c'est ce qu'un pawn veut
## savoir quand il planifie un trajet.
func seconds_until_phase(target_phase: int) -> float:
	if _dirty:
		_rebuild()
	var index := clampi(target_phase, 0, _PHASE_COUNT - 1)
	return fposmod(_real_start[index] - _progress, 1.0) * day_duration


## Secondes réelles restant à la phase en cours.
func seconds_left_in_phase() -> float:
	if _dirty:
		_rebuild()
	var end := _real_start[_phase] + _real_len[_phase]
	return fposmod(end - _progress, 1.0) * day_duration


## Durée réelle totale d'une phase, en secondes.
func phase_duration(target_phase: int) -> float:
	if _dirty:
		_rebuild()
	return _real_len[clampi(target_phase, 0, _PHASE_COUNT - 1)] * day_duration


# --- Écriture (debug) --------------------------------------------------------

func set_time_of_day(value: float) -> void:
	if _dirty:
		_rebuild()
	_time_of_day = fposmod(value, 1.0)
	_progress = _progress_from_time(_time_of_day)
	_update_phase()


func skip_to_phase(target_phase: int) -> void:
	if _dirty:
		_rebuild()
	var index := clampi(target_phase, 0, _PHASE_COUNT - 1)
	_progress = _real_start[index]
	_time_of_day = _time_from_progress(_progress)
	_update_phase()


# --- Interne -----------------------------------------------------------------

func _rebuild() -> void:
	_dirty = false

	if day_elevation_degrees <= night_elevation_degrees:
		push_warning("TimeOfDay : day_elevation_degrees doit rester au-dessus de night_elevation_degrees.")
		day_elevation_degrees = night_elevation_degrees + 1.0

	# Les bornes de phase sont les instants où le soleil croise les deux seuils.
	# elevation(t) = max * sin(TAU * (t - 0.25)) → t = 0.25 + asin(seuil / max) / TAU
	# en montée, et son miroir 0.75 - u en descente.
	var u_night := asin(clampf(night_elevation_degrees / max_elevation_degrees, -1.0, 1.0)) / TAU
	var u_day := asin(clampf(day_elevation_degrees / max_elevation_degrees, -1.0, 1.0)) / TAU

	_canon_start = PackedFloat32Array([
		fposmod(0.25 + u_night, 1.0),  # DAWN  — le soleil approche de l'horizon
		fposmod(0.25 + u_day, 1.0),    # DAY   — plein jour
		fposmod(0.75 - u_day, 1.0),    # DUSK  — il redescend
		fposmod(0.75 - u_night, 1.0),  # NIGHT — il est passé sous l'horizon
	])

	_canon_len = PackedFloat32Array()
	_canon_len.resize(_PHASE_COUNT)
	for i in _PHASE_COUNT:
		var next: float = _canon_start[(i + 1) % _PHASE_COUNT]
		_canon_len[i] = fposmod(next - _canon_start[i], 1.0)

	var shares := PackedFloat32Array([dawn_share, day_share, dusk_share, night_share])
	var total := 0.0
	for s in shares:
		total += s
	if total <= 0.0:
		shares = PackedFloat32Array([1.0, 1.0, 1.0, 1.0])
		total = 4.0

	_real_start = PackedFloat32Array()
	_real_len = PackedFloat32Array()
	_real_start.resize(_PHASE_COUNT)
	_real_len.resize(_PHASE_COUNT)
	var cursor := 0.0
	for i in _PHASE_COUNT:
		_real_start[i] = cursor
		_real_len[i] = shares[i] / total
		cursor += _real_len[i]

	# La répartition a changé, pas l'heure : on recale la progression sur l'heure
	# courante plutôt que l'inverse. C'est ce qui rend les curseurs de debug utilisables.
	_progress = _progress_from_time(_time_of_day)


func _time_from_progress(p: float) -> float:
	var index := _phase_at(p)
	var span: float = maxf(_real_len[index], 0.000001)
	var frac: float = fposmod(p - _real_start[index], 1.0) / span
	return fposmod(_canon_start[index] + clampf(frac, 0.0, 1.0) * _canon_len[index], 1.0)


func _progress_from_time(t: float) -> float:
	for i in _PHASE_COUNT:
		var offset := fposmod(t - _canon_start[i], 1.0)
		if offset < _canon_len[i] or i == _PHASE_COUNT - 1:
			var span: float = maxf(_canon_len[i], 0.000001)
			return _real_start[i] + clampf(offset / span, 0.0, 1.0) * _real_len[i]
	return 0.0


func _phase_at(p: float) -> int:
	var wrapped := fposmod(p, 1.0)
	for i in _PHASE_COUNT:
		if wrapped < _real_start[i] + _real_len[i]:
			return i
	return _PHASE_COUNT - 1


func _update_phase() -> void:
	var found := _phase_at(_progress)
	if found == _phase:
		return
	_phase = found
	phase_changed.emit(_phase)
	if _phase == Phase.DAY:
		day_started.emit()
	elif _phase == Phase.NIGHT:
		night_started.emit()
