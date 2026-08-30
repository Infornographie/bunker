extends Interactable
class_name PanelSlot

## Case d'un panneau 3D. C'est un Interactable comme un rondin ou un feu :
## elle entre dans le raycast de l'InteractionController, affiche un prompt,
## et répond à E. Il n'y a donc aucun système de visée, de survol ni de
## dépôt propre à l'UI — c'est le même chemin de code que le reste du jeu.
##
## Elle ne connaît aucune logique de rangement : elle porte un `payload`
## opaque posé par son panneau et lui délègue toute décision.
##
## Contrat du panneau propriétaire :
##   slot_content(slot: PanelSlot) -> ResourceDef
##   slot_accepts(slot: PanelSlot, resource: ResourceDef) -> bool
##   slot_take(slot: PanelSlot) -> ResourceDef   (retire et rend, ou null)
##   slot_put(slot: PanelSlot, resource: ResourceDef) -> bool

## Opacité de l'ingrédient attendu affiché en fantôme dans une case vide.
const GHOST_ALPHA: float = 0.25
## L'icône générée fait 128px de côté ; on la veut un peu plus petite que la
## case pour laisser une marge visuelle.
const ICON_MARGIN: float = 0.9

@onready var _collision: CollisionShape3D = $CollisionShape3D
@onready var _background: MeshInstance3D = $Background
@onready var _icon: Sprite3D = $Icon
@onready var _label: Label3D = $Label

## Posé par le panneau, jamais interprété ici.
var payload: Variant = null
var content: ResourceDef
## Affiché en transparence quand la case est vide : ce qu'elle attend.
var ghost_content: ResourceDef

var _panel: WorldPanel
var _material: StandardMaterial3D
## Ressource dont l'icône est en cours de chargement (contenu ou fantôme).
var _displayed: ResourceDef


func setup(p_payload: Variant, slot_size: float, panel: WorldPanel, layer: int) -> void:
	payload = p_payload
	_panel = panel

	# Vue par le raycast d'interaction, invisible pour tout le reste : le
	# joueur ne s'y cogne pas et le mode construction ne pose rien dessus.
	collision_layer = layer
	collision_mask = 0

	var box := BoxShape3D.new()
	box.size = Vector3(slot_size, slot_size, 0.02)
	_collision.shape = box

	var quad := QuadMesh.new()
	quad.size = Vector2(slot_size, slot_size)
	_background.mesh = quad
	_material = StandardMaterial3D.new()
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_material.albedo_color = Color(0.1, 0.1, 0.12, 0.95)
	# Une case doit rester lisible même quand une flamme, une herbe ou un
	# rondin passe devant : c'est une interface, pas un décor. Le prix à
	# payer est qu'un panneau se voit à travers un mur — acceptable, il se
	# ferme dès qu'on s'éloigne de son ancre.
	_material.no_depth_test = true
	_material.render_priority = 1
	_background.material_override = _material

	# Légèrement devant le fond, sinon z-fighting sur le quad.
	_icon.position = Vector3(0.0, 0.0, 0.006)
	_icon.pixel_size = slot_size * ICON_MARGIN / 128.0
	_icon.shaded = false
	_icon.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_icon.no_depth_test = true
	_icon.render_priority = 2

	_label.position = Vector3(0.0, 0.0, 0.004)
	_label.font_size = 48
	_label.pixel_size = slot_size / 400.0
	_label.width = 400.0
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.modulate = Color.WHITE
	_label.no_depth_test = true
	_label.render_priority = 3


func set_content(resource: ResourceDef) -> void:
	content = resource
	_refresh_display()


## Ce que la case attend quand elle est vide (ingrédient d'une recette).
func set_ghost(resource: ResourceDef) -> void:
	ghost_content = resource
	_refresh_display()


## --- Interactable ---------------------------------------------------------

func can_interact(interactor: Node) -> bool:
	if not _panel.slot_action_key(self).is_empty():
		return true
	var offered := _get_offered_resource(interactor)
	if offered != null:
		return _panel.slot_accepts(self, offered)
	return _panel.slot_can_take(self) and _hands_free(interactor)


func get_prompt_key(interactor: Node) -> String:
	var action_key := _panel.slot_action_key(self)
	if not action_key.is_empty():
		return action_key
	if _get_offered_resource(interactor) != null:
		return "interact.prompt.put"
	return "interact.prompt.take"


## Mains vides sur une case pleine : l'objet arrive vraiment en main, il n'y
## a pas d'état de transfert intermédiaire. S'éloigner ou fermer le panneau
## ne pose donc aucune question — on tient l'objet, c'est tout.
func interact(interactor: Node) -> void:
	if not _panel.slot_action_key(self).is_empty():
		_panel.slot_activate(self)
		return
	var resource := _panel.slot_take(self)
	if resource == null:
		return
	if not bool(interactor.call("take_into_hand", resource)):
		# La main s'est refusée : on remet, plutôt que d'évaporer l'objet.
		_panel.slot_put(self, resource)


func receive_resource(resource: ResourceDef, _amount: int) -> bool:
	return _panel.slot_put(self, resource)


func _hands_free(interactor: Node) -> bool:
	var carry: Node = interactor.get("carry_controller")
	return carry != null and bool(carry.call("can_carry"))


## --- Affichage ------------------------------------------------------------

## Un des points d'affichage du projet (voir STRUCTURE §Flux de
## localisation) : le tr() des noms d'items en case vit ici.
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
