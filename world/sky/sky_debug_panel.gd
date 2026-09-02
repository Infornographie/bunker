extends CanvasLayer

## Panneau de debug du cycle jour/nuit. Hors-diégèse : c'est le seul endroit du
## projet où une interface est un Control ancré à l'écran avec un curseur souris.
## La décision « interfaces = objets du monde, réticule = pointeur » concerne les
## interfaces de JEU ; un outil de réglage n'en est pas une.
##
## Deux exceptions assumées, et nommées pour qu'elles ne se propagent pas :
##  - l'UI est construite en code et pas en .tscn — vingt-cinq Control montés à la
##    main dériveraient du script à la première modification, et ce panneau n'est
##    pas un livrable ;
##  - ses textes ne passent pas par le CSV de traduction. Un outil de dev ne se
##    localise pas.
##
## Les deux multiplicateurs de brume et d'ambiante écrivent sur `SkyController`,
## pas sur le profil : on cherche la valeur en direct, puis on la recopie à la main
## dans la courbe du profil et on remet le multiplicateur à 1. Un panneau de debug
## qui écrit dans les données finit par être la seule façon de les régler.

const PROFILE_DIR := "res://resources/sky/"
const PHASE_LABELS := ["Aube", "Jour", "Crépuscule", "Nuit"]

@export var sky_controller: Node
## Testé en duck typing (`can_enter_exclusive_mode()`), sans citer son type.
@export var ui_panel_controller: Node

var _root: PanelContainer
var _readout: Label
var _time_slider: HSlider
var _time_slider_held := false
var _duration_slider: HSlider
var _pause_button: Button
var _share_sliders: Array[HSlider] = []
var _profile_picker: OptionButton
var _fog_slider: HSlider
var _ambient_slider: HSlider


func _ready() -> void:
	layer = 100
	_build_ui()
	visible = false
	set_process(false)


func is_active() -> bool:
	return visible


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_sky_debug"):
		_toggle()
		get_viewport().set_input_as_handled()


func _input(event: InputEvent) -> void:
	# Panneau ouvert = souris libre. Sans ça, la caméra continue de suivre les
	# mouvements sous le curseur et régler un curseur devient impossible.
	if visible and event is InputEventMouseMotion:
		get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	var t: float = TimeOfDay.time_of_day
	if not _time_slider_held:
		_time_slider.set_value_no_signal(t)

	var total_minutes := int(round(t * 1440.0)) % 1440
	var elevation: float = TimeOfDay.sun_elevation_degrees()
	var lines := PackedStringArray()
	lines.append("%02d:%02d   jour %d   %s" % [
		floori(total_minutes / 60.0), total_minutes % 60, TimeOfDay.day_count, PHASE_LABELS[TimeOfDay.phase]
	])
	lines.append("soleil %+.1f°     phase : %s restantes" % [
		elevation, _format_duration(TimeOfDay.seconds_left_in_phase())
	])
	lines.append("crépuscule dans %s   (durée %s)" % [
		_format_duration(TimeOfDay.seconds_until_phase(TimeOfDay.Phase.DUSK)),
		_format_duration(TimeOfDay.phase_duration(TimeOfDay.Phase.DUSK)),
	])
	if sky_controller != null:
		var env: Environment = sky_controller.world_environment.environment
		lines.append("brume %.0f m      ambiante %.2f" % [
			env.fog_depth_end, env.ambient_light_energy
		])
	_readout.text = "\n".join(lines)


# --- Ouverture / fermeture ---------------------------------------------------

func _toggle() -> void:
	if visible:
		_close()
	else:
		_open()


func _open() -> void:
	if ui_panel_controller != null and ui_panel_controller.has_method("can_enter_exclusive_mode"):
		if not ui_panel_controller.can_enter_exclusive_mode():
			return
	_sync_from_state()
	visible = true
	set_process(true)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _close() -> void:
	visible = false
	set_process(false)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _sync_from_state() -> void:
	_duration_slider.set_value_no_signal(TimeOfDay.day_duration)
	_share_sliders[0].set_value_no_signal(TimeOfDay.dawn_share)
	_share_sliders[1].set_value_no_signal(TimeOfDay.day_share)
	_share_sliders[2].set_value_no_signal(TimeOfDay.dusk_share)
	_share_sliders[3].set_value_no_signal(TimeOfDay.night_share)
	_pause_button.text = "Reprendre" if TimeOfDay.paused else "Pause"
	if sky_controller != null:
		_fog_slider.set_value_no_signal(sky_controller.fog_distance_scale)
		_ambient_slider.set_value_no_signal(sky_controller.ambient_scale)


# --- Construction de l'interface ---------------------------------------------

func _build_ui() -> void:
	_root = PanelContainer.new()
	_root.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_root.position = Vector2(16, 16)
	_root.custom_minimum_size = Vector2(340, 0)
	add_child(_root)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	_root.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	margin.add_child(box)

	_readout = Label.new()
	box.add_child(_readout)

	box.add_child(HSeparator.new())

	_time_slider = _add_slider(box, "Heure", 0.0, 1.0, 0.001, 0.3)
	_time_slider.value_changed.connect(func(v: float) -> void: TimeOfDay.set_time_of_day(v))
	_time_slider.drag_started.connect(func() -> void: _time_slider_held = true)
	_time_slider.drag_ended.connect(func(_c: bool) -> void: _time_slider_held = false)

	_duration_slider = _add_slider(box, "Durée du cycle (s)", 30.0, 3600.0, 10.0, 1800.0)
	_duration_slider.value_changed.connect(func(v: float) -> void: TimeOfDay.day_duration = v)

	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 4)
	box.add_child(buttons)

	_pause_button = Button.new()
	_pause_button.text = "Pause"
	_pause_button.pressed.connect(_on_pause_pressed)
	buttons.add_child(_pause_button)

	for i in PHASE_LABELS.size():
		var button := Button.new()
		button.text = PHASE_LABELS[i]
		button.pressed.connect(TimeOfDay.skip_to_phase.bind(i))
		buttons.add_child(button)

	box.add_child(HSeparator.new())

	var shares_label := Label.new()
	shares_label.text = "Répartition (parts de temps réel)"
	box.add_child(shares_label)

	_share_sliders.clear()
	for i in PHASE_LABELS.size():
		var slider := _add_slider(box, PHASE_LABELS[i], 0.0, 20.0, 0.5, 5.0)
		slider.value_changed.connect(_on_share_changed.bind(i))
		_share_sliders.append(slider)

	box.add_child(HSeparator.new())

	var profile_label := Label.new()
	profile_label.text = "Profil de ciel"
	box.add_child(profile_label)

	_profile_picker = OptionButton.new()
	_profile_picker.item_selected.connect(_on_profile_selected)
	box.add_child(_profile_picker)
	_fill_profiles()

	_fog_slider = _add_slider(box, "Brume ×", 0.1, 4.0, 0.01, 1.0)
	_fog_slider.value_changed.connect(func(v: float) -> void:
		if sky_controller != null:
			sky_controller.fog_distance_scale = v)

	_ambient_slider = _add_slider(box, "Ambiante ×", 0.0, 4.0, 0.01, 1.0)
	_ambient_slider.value_changed.connect(func(v: float) -> void:
		if sky_controller != null:
			sky_controller.ambient_scale = v)


func _add_slider(parent: Node, title: String, minimum: float, maximum: float,
		step: float, initial: float) -> HSlider:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	parent.add_child(row)

	var label := Label.new()
	label.text = title
	label.custom_minimum_size = Vector2(150, 0)
	row.add_child(label)

	var slider := HSlider.new()
	slider.min_value = minimum
	slider.max_value = maximum
	slider.step = step
	slider.value = initial
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(slider)

	var value_label := Label.new()
	value_label.custom_minimum_size = Vector2(56, 0)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.text = _format_number(initial)
	row.add_child(value_label)
	slider.value_changed.connect(func(v: float) -> void: value_label.text = _format_number(v))

	return slider


func _fill_profiles() -> void:
	var dir := DirAccess.open(PROFILE_DIR)
	if dir == null:
		push_warning("SkyDebugPanel : dossier de profils introuvable (%s)." % PROFILE_DIR)
		return

	var current_path := ""
	if sky_controller != null and sky_controller.profile != null:
		current_path = sky_controller.profile.resource_path

	for file_name in dir.get_files():
		var clean := file_name.trim_suffix(".remap")
		if not clean.ends_with(".tres"):
			continue
		var path := PROFILE_DIR + clean
		_profile_picker.add_item(clean.trim_suffix(".tres"))
		var index := _profile_picker.item_count - 1
		_profile_picker.set_item_metadata(index, path)
		if path == current_path:
			_profile_picker.select(index)


# --- Réactions ---------------------------------------------------------------

func _on_pause_pressed() -> void:
	TimeOfDay.paused = not TimeOfDay.paused
	_pause_button.text = "Reprendre" if TimeOfDay.paused else "Pause"


func _on_share_changed(value: float, index: int) -> void:
	match index:
		0: TimeOfDay.dawn_share = value
		1: TimeOfDay.day_share = value
		2: TimeOfDay.dusk_share = value
		3: TimeOfDay.night_share = value


func _on_profile_selected(index: int) -> void:
	if sky_controller == null:
		return
	var path: String = _profile_picker.get_item_metadata(index)
	var loaded := ResourceLoader.load(path)
	if loaded == null:
		push_warning("SkyDebugPanel : profil illisible (%s)." % path)
		return
	sky_controller.profile = loaded


# --- Formatage ---------------------------------------------------------------

func _format_number(value: float) -> String:
	if absf(value) >= 100.0:
		return "%.0f" % value
	return "%.2f" % value


func _format_duration(seconds: float) -> String:
	var total := int(round(seconds))
	return "%d min %02d s" % [floori(total / 60.0), total % 60]
