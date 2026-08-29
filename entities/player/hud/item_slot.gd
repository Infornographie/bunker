extends Panel
class_name ItemSlot

## Case d'inventaire générique : affiche une ResourceDef (icône générée par
## ResourceRegistry, nom traduit en repli tant qu'elle n'est pas prête) et
## sert de source et de cible au drag & drop natif Godot.
##
## Elle ne connaît aucune logique de rangement. Elle porte un `payload`
## opaque posé par son propriétaire (index de slot, zone, ce qu'il veut) et
## lui délègue toute décision. La donnée de drag est la case source
## elle-même : la case cible interroge son propre propriétaire en la lui
## passant telle quelle. Deux panneaux différents peuvent donc s'échanger
## des items sans jamais se connaître — chacun décide chez lui.
##
## Contrat du propriétaire (les trois méthodes sont appelées en dynamique) :
##   slot_can_accept(target: ItemSlot, source: ItemSlot) -> bool
##   slot_accept_drop(target: ItemSlot, source: ItemSlot) -> void
##   slot_release(source: ItemSlot) -> void
##     — retire l'item de la case source, appelé par le panneau *cible*
##       après un transfert réussi. Obligatoire seulement pour un panneau
##       dont les cases peuvent partir vers un autre panneau.

signal pressed

const ICON_PADDING: float = 4.0
## Opacité de l'ingrédient attendu affiché en fantôme dans une case vide.
const GHOST_ALPHA: float = 0.25

## Posé par le propriétaire, jamais interprété ici.
var payload: Variant = null
var content: ResourceDef
## Affiché en transparence quand la case est vide : ce qu'elle attend.
var ghost_content: ResourceDef
var slot_owner: Object
var can_drag: bool = true
var can_drop: bool = true

var _icon: TextureRect
var _label: Label
var _style: StyleBoxFlat
var _highlighted: bool = false
## Ressource dont l'icône est en cours de chargement (contenu ou fantôme).
var _displayed: ResourceDef


func setup(p_payload: Variant, p_size: float, p_owner: Object) -> void:
	payload = p_payload
	slot_owner = p_owner
	custom_minimum_size = Vector2(p_size, p_size)
	size = Vector2(p_size, p_size)
	mouse_filter = Control.MOUSE_FILTER_STOP

	_style = StyleBoxFlat.new()
	_style.bg_color = Color(0.12, 0.12, 0.14, 0.85)
	_style.set_border_width_all(2)
	_style.set_corner_radius_all(4)
	add_theme_stylebox_override("panel", _style)
	_apply_border()

	_icon = TextureRect.new()
	_icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	_icon.offset_left = ICON_PADDING
	_icon.offset_top = ICON_PADDING
	_icon.offset_right = -ICON_PADDING
	_icon.offset_bottom = -ICON_PADDING
	_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_icon)

	# Repli texte tant que l'icône n'est pas générée.
	_label = Label.new()
	_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.add_theme_font_size_override("font_size", 11)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)


func set_content(resource: ResourceDef) -> void:
	content = resource
	_refresh_display()


## Ce que la case attend quand elle est vide (ingrédient d'une recette).
func set_ghost(resource: ResourceDef) -> void:
	ghost_content = resource
	_refresh_display()


func set_highlighted(value: bool) -> void:
	if value == _highlighted:
		return
	_highlighted = value
	_apply_border()


## --- Affichage ------------------------------------------------------------

func _apply_border() -> void:
	_style.border_color = Color(1.0, 0.85, 0.2, 0.9) if _highlighted \
		else Color(0.6, 0.6, 0.65, 0.6)


## Un des points d'affichage du projet (voir STRUCTURE §Flux de
## localisation) : le tr() des noms d'items en case d'inventaire vit ici.
func _refresh_display() -> void:
	var resource: ResourceDef = content if content else ghost_content
	var is_ghost: bool = content == null and ghost_content != null
	_displayed = resource

	var alpha: float = GHOST_ALPHA if is_ghost else 1.0
	_icon.modulate = Color(1.0, 1.0, 1.0, alpha)
	_label.modulate = Color(1.0, 1.0, 1.0, alpha)

	if resource == null:
		_icon.texture = null
		_label.text = ""
		return
	_label.text = tr(resource.name_key)
	_load_icon(resource)


## Charge l'icône en asynchrone : le texte reste affiché en attendant, et
## disparaît dès que l'icône arrive.
func _load_icon(resource: ResourceDef) -> void:
	var icon: Texture2D = await ResourceRegistry.get_icon(resource)
	# La case a pu changer d'affichage pendant la génération.
	if _displayed != resource:
		return
	if icon:
		_icon.texture = icon
		_label.text = ""


## --- Clic (sélection de recette) -----------------------------------------

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT:
		pressed.emit()


## --- Drag & drop natif Godot ---------------------------------------------

func _get_drag_data(_at_position: Vector2) -> Variant:
	if content == null or not can_drag:
		return null
	set_drag_preview(_make_preview())
	return self


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if not can_drop:
		return false
	if not (data is ItemSlot) or not is_instance_valid(data):
		return false
	if slot_owner == null:
		return false
	return bool(slot_owner.call("slot_can_accept", self, data))


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if slot_owner == null:
		return
	slot_owner.call("slot_accept_drop", self, data)


func _make_preview() -> Control:
	var preview := Panel.new()
	preview.custom_minimum_size = size * 0.8
	preview.size = preview.custom_minimum_size

	var preview_style := StyleBoxFlat.new()
	preview_style.bg_color = Color(0.2, 0.2, 0.24, 0.9)
	preview_style.border_color = Color(1.0, 0.85, 0.2, 0.9)
	preview_style.set_border_width_all(2)
	preview_style.set_corner_radius_all(4)
	preview.add_theme_stylebox_override("panel", preview_style)

	if _icon.texture:
		var preview_icon := TextureRect.new()
		preview_icon.texture = _icon.texture
		preview_icon.set_anchors_preset(Control.PRESET_FULL_RECT)
		preview_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		preview_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		preview.add_child(preview_icon)
	else:
		var preview_label := Label.new()
		preview_label.text = tr(content.name_key)
		preview_label.set_anchors_preset(Control.PRESET_FULL_RECT)
		preview_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		preview_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		preview_label.add_theme_font_size_override("font_size", 11)
		preview.add_child(preview_label)

	return preview
