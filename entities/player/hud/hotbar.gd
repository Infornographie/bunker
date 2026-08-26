extends Control
class_name Hotbar

## Hotbar dessiné en code (même approche que Crosshair). Affiche 2 slots
## ceinture + 3 slots poches en bas au centre de l'écran.
##
## Les slots poches ne sont visibles que si un sac est équipé. Un séparateur
## visuel marque la frontière ceinture|poches.

const SLOT_SIZE: float = 48.0
const SLOT_GAP: float = 4.0
const SEPARATOR_GAP: float = 12.0  # espace supplémentaire entre ceinture et poches
const CORNER_RADIUS: float = 4.0
const BORDER_WIDTH: float = 2.0
const MARGIN_BOTTOM: float = 32.0
const BELT_COUNT: int = 2
const POCKET_COUNT: int = 3
const HOTBAR_SIZE: int = 5

@export var color_bg: Color = Color(0.1, 0.1, 0.1, 0.6)
@export var color_border: Color = Color(0.7, 0.7, 0.7, 0.5)
@export var color_active: Color = Color(1.0, 0.85, 0.2, 0.9)
@export var color_text: Color = Color(1.0, 1.0, 1.0, 0.8)
@export var color_text_dim: Color = Color(0.5, 0.5, 0.5, 0.5)
@export var color_empty_bg: Color = Color(0.08, 0.08, 0.08, 0.4)

var _active_slot: int = 0
var _belt: Array[ToolDef] = []
var _backpack_data: BackpackData
var _dimmed: bool = false
var _icons: Dictionary = {}
var _font: Font
var _font_small: Font


func _ready() -> void:
	_font = ThemeDB.fallback_font
	_font_small = _font
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Taille suffisante pour contenir le hotbar complet — repositionné dans _draw.
	anchors_preset = PRESET_BOTTOM_WIDE
	offset_top = -SLOT_SIZE - MARGIN_BOTTOM - 20.0


func update(active_slot: int, belt: Array[ToolDef], backpack_data: BackpackData) -> void:
	_active_slot = active_slot
	_belt = belt
	_backpack_data = backpack_data
	_request_icons()
	queue_redraw()


## Demande les icônes manquantes des poches. Le texte reste affiché tant
## qu'une icône n'est pas prête.
func _request_icons() -> void:
	print("[Hotbar] _request_icons — belt.size=%d contenu=%s" % [_belt.size(), _belt])
	# Outils en ceinture.
	for tool_def in _belt:
		if tool_def == null:
			continue
		var key: String = "tool:" + tool_def.display_name
		if _icons.has(key):
			continue
		_icons[key] = null
		_fetch_tool_icon(tool_def, key)

	# Petits objets en poche.
	if _backpack_data == null:
		return
	for res in _backpack_data.pocket_slots:
		if res == null or _icons.has(res.id):
			continue
		_icons[res.id] = null  # marque comme "en cours", évite les doublons
		_fetch_icon(res)


func _fetch_tool_icon(tool_def: ToolDef, key: String) -> void:
	var icon: Texture2D = await ResourceRegistry.get_tool_icon(tool_def)
	print("[Hotbar] fetch '%s' → %s" % [key, icon])
	if icon:
		_icons[key] = icon
		queue_redraw()
	else:
		# Échec (registre pas encore prêt) : libérer la clé pour réessayer.
		_icons.erase(key)


func _fetch_icon(res: ResourceDef) -> void:
	var icon: Texture2D = await ResourceRegistry.get_icon(res)
	if icon:
		_icons[res.id] = icon
		queue_redraw()
	else:
		_icons.erase(res.id)


## Grise tout le hotbar quand les mains sont occupées (objet lourd).
func set_dimmed(dimmed: bool) -> void:
	if dimmed == _dimmed:
		return
	_dimmed = dimmed
	queue_redraw()


func _draw() -> void:
	var show_pockets: bool = _backpack_data != null
	var slot_count: int = HOTBAR_SIZE if show_pockets else BELT_COUNT

	# Largeur totale.
	var total_width: float = slot_count * SLOT_SIZE + (slot_count - 1) * SLOT_GAP
	if show_pockets:
		total_width += SEPARATOR_GAP - SLOT_GAP  # remplace un gap normal par le séparateur

	var start_x: float = (size.x - total_width) * 0.5
	var start_y: float = size.y - SLOT_SIZE - MARGIN_BOTTOM

	var x_cursor: float = start_x

	for i in slot_count:
		# Séparateur entre ceinture et poches.
		if i == BELT_COUNT and show_pockets:
			# Ligne verticale fine.
			var sep_x: float = x_cursor - (SEPARATOR_GAP - SLOT_GAP) * 0.5
			draw_line(
				Vector2(sep_x, start_y + 4.0),
				Vector2(sep_x, start_y + SLOT_SIZE - 4.0),
				color_border, 1.0
			)

		var rect := Rect2(x_cursor, start_y, SLOT_SIZE, SLOT_SIZE)
		var is_active: bool = i == _active_slot and not _dimmed
		var has_content: bool = _slot_has_content(i)

		# Fond.
		var bg: Color = color_bg if has_content else color_empty_bg
		if _dimmed:
			bg = Color(0.05, 0.05, 0.05, 0.25)
		draw_rect(rect, bg, true)

		# Bordure.
		var border: Color = color_active if is_active else color_border
		if _dimmed:
			border = Color(0.3, 0.3, 0.3, 0.15)
		var width: float = BORDER_WIDTH * (1.5 if is_active else 1.0)
		draw_rect(rect, border, false, width)

		# Numéro du slot (coin supérieur gauche).
		var num_text: String = str(i + 1)
		var num_color: Color = color_active if is_active else color_text_dim
		if _dimmed:
			num_color = Color(0.4, 0.4, 0.4, 0.2)
		draw_string(_font_small, Vector2(x_cursor + 5.0, start_y + 14.0),
			num_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, num_color)

		# Contenu : icône si disponible, sinon nom en texte.
		var icon := _slot_icon(i)
		if icon:
			var pad: float = 6.0
			var icon_rect := Rect2(
				x_cursor + pad, start_y + pad,
				SLOT_SIZE - pad * 2.0, SLOT_SIZE - pad * 2.0
			)
			var modulate_color := Color.WHITE
			if _dimmed:
				modulate_color = Color(1.0, 1.0, 1.0, 0.2)
			draw_texture_rect(icon, icon_rect, false, modulate_color)
		else:
			var label: String = _slot_label(i)
			if label != "":
				var label_color: Color = color_text if is_active else color_text_dim
				if _dimmed:
					label_color = Color(0.4, 0.4, 0.4, 0.2)
				draw_string(_font_small, Vector2(x_cursor + SLOT_SIZE * 0.5, start_y + SLOT_SIZE * 0.65),
					label, HORIZONTAL_ALIGNMENT_CENTER, SLOT_SIZE - 6.0, 10, label_color)

		x_cursor += SLOT_SIZE + SLOT_GAP
		if i == BELT_COUNT - 1 and show_pockets:
			x_cursor += SEPARATOR_GAP - SLOT_GAP


func _slot_has_content(index: int) -> bool:
	if index < BELT_COUNT:
		return index < _belt.size() and _belt[index] != null
	if _backpack_data == null:
		return false
	var pocket_i: int = index - BELT_COUNT
	return pocket_i < _backpack_data.pocket_slots.size() and _backpack_data.pocket_slots[pocket_i] != null


func _slot_icon(index: int) -> Texture2D:
	if index < BELT_COUNT:
		if index >= _belt.size() or _belt[index] == null:
			return null
		return _icons.get("tool:" + _belt[index].display_name)
	if _backpack_data == null:
		return null
	var pocket_i: int = index - BELT_COUNT
	if pocket_i >= _backpack_data.pocket_slots.size():
		return null
	var res := _backpack_data.pocket_slots[pocket_i]
	if res == null:
		return null
	return _icons.get(res.id)


func _slot_label(index: int) -> String:
	if index < BELT_COUNT:
		if index < _belt.size() and _belt[index] != null:
			return _belt[index].display_name
		return ""
	if _backpack_data == null:
		return ""
	var pocket_i: int = index - BELT_COUNT
	if pocket_i < _backpack_data.pocket_slots.size() and _backpack_data.pocket_slots[pocket_i] != null:
		return _backpack_data.pocket_slots[pocket_i].display_name
	return ""
