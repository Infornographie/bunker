extends CanvasLayer

## Relevé de position pour juger la carte lyonnaise.
##
## TROIS EXCEPTIONS ASSUMÉES, mêmes que le panneau de ciel (F3), et pour la
## même raison — un outil de développement n'est pas une interface de jeu :
##   1. UI construite en code plutôt qu'en .tscn ;
##   2. textes hors du CSV de traduction (un outil de dev ne se localise pas) ;
##   3. affichage hors-diégèse, alors que le projet pose « interfaces = objets
##      du monde ».
## Ces exceptions ne font pas précédent : elles meurent avec ce prototype.

const KEY_TOGGLE: Key = KEY_F4

@export var terrain: LyonTerrain = null
@export var target: Node3D = null

var _label: Label = null


func _ready() -> void:
	_label = Label.new()
	_label.position = Vector2(14.0, 14.0)
	_label.add_theme_color_override("font_color", Color(1.0, 0.97, 0.88))
	_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.75))
	_label.add_theme_constant_override("outline_size", 6)
	add_child(_label)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key_event: InputEventKey = event
		if key_event.pressed and not key_event.echo and key_event.keycode == KEY_TOGGLE:
			visible = not visible
			get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	if not visible or _label == null or terrain == null or terrain.map == null or target == null:
		return

	var local: Vector3 = target.global_position - terrain.global_position
	var ground: float = terrain.ground_height(local.x, local.z)
	var map: LyonHeightmap = terrain.map

	_label.text = "\n".join([
		"local  X %7.1f   Z %7.1f   (carte %.0f x %.0f m)" % [local.x, local.z, map.width_m, map.depth_m],
		"sol    %6.1f m au-dessus du point bas   =   %6.1f m NGF" % [ground, ground + map.alt_min],
		"tête   %6.1f m" % local.y,
		"carte  %.1f -> %.1f m NGF   amplitude %.1f m" % [map.alt_min, map.alt_max, map.amplitude_m],
		"%d fps      F4 masquer      F11 vol libre" % Engine.get_frames_per_second(),
	])
