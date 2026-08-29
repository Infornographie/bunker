extends WorldAnchoredPanel
class_name CookingPanel

## Panneau d'un site de transformation ancré sur son bâtiment.
##
## Layout :
##   [recettes]   [ ingrédients (une case par unité attendue) ]   [combustible]
##                        [ progression ]                          [ jauge ]
##
## Il ne calcule rien : la recette active, l'avancement, ce qui manque et le
## combustible restant appartiennent à TransformationSite et à l'hôte. Le
## panneau les lit et les affiche. Tout dépôt repart par
## Campfire.receive_resource(), le même point d'entrée que le E en jeu —
## l'UI n'ouvre pas un second chemin de livraison.

const RECIPE_SLOT_SIZE: float = 52.0
const INPUT_SLOT_SIZE: float = 68.0
const SLOT_GAP: float = 6.0
const ZONE_GAP: float = 24.0
const INPUT_ZONE_WIDTH: float = 3.0 * INPUT_SLOT_SIZE + 2.0 * SLOT_GAP
const GAUGE_HEIGHT: float = 10.0
const PANEL_SIZE: Vector2 = Vector2(
	RECIPE_SLOT_SIZE + ZONE_GAP + INPUT_ZONE_WIDTH + ZONE_GAP + INPUT_SLOT_SIZE,
	170.0
)

## Identifiants de zone, portés par le payload des cases.
enum Zone { RECIPE, INPUT, FUEL }

var _host: Campfire
var _transformation: TransformationSite

var _recipe_slots: Array[ItemSlot] = []
var _input_slots: Array[ItemSlot] = []
var _fuel_slot: ItemSlot
var _progress: ProgressBar
var _fuel_gauge: ProgressBar
var _inputs_container: Control
## Recette pour laquelle les cases d'ingrédients ont été construites : elles
## dépendent de la recette (une case par unité attendue), donc elles se
## reconstruisent quand elle change.
var _inputs_built_for: RecipeDef
## Même raison, un cran au-dessus : le panneau est unique dans le HUD et
## sert tous les sites de transformation. Ses cases de recettes suivent donc
## le site branché, elles ne peuvent pas être construites une fois pour
## toutes comme celles du sac.
var _recipes_built_for: TransformationSite


## Branche le panneau sur un feu. Appelé avant l'ouverture, qui passe elle
## par UIPanelController.
func bind(campfire: Campfire) -> void:
	if _transformation and _transformation.state_changed.is_connected(refresh):
		_transformation.state_changed.disconnect(refresh)
	_host = campfire
	_transformation = campfire.transformation
	if _transformation and not _transformation.state_changed.is_connected(refresh):
		_transformation.state_changed.connect(refresh)


func close() -> void:
	if _transformation and _transformation.state_changed.is_connected(refresh):
		_transformation.state_changed.disconnect(refresh)
	super()


## Le feu occupe le bas de l'ancre : on remonte le panneau au-dessus.
func anchor_screen_offset() -> Vector2:
	return Vector2(0.0, -60.0)


## Progression et combustible s'écoulent en continu : ils se lisent par
## frame, contrairement au reste qui suit le signal state_changed.
func _process(delta: float) -> void:
	super(delta)
	if visible:
		_update_gauges()


## --- Construction ---------------------------------------------------------

func _build_content() -> void:
	size = PANEL_SIZE

	# Zone d'ingrédients : reconstruite à chaque changement de recette.
	_inputs_container = Control.new()
	_inputs_container.position = Vector2(RECIPE_SLOT_SIZE + ZONE_GAP, 0.0)
	_inputs_container.size = Vector2(INPUT_ZONE_WIDTH, INPUT_SLOT_SIZE)
	_inputs_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_inputs_container)

	var fuel_x: float = RECIPE_SLOT_SIZE + ZONE_GAP + INPUT_ZONE_WIDTH + ZONE_GAP
	_fuel_slot = _make_slot(Zone.FUEL, 0, INPUT_SLOT_SIZE)
	_fuel_slot.can_drag = false
	_fuel_slot.position = Vector2(fuel_x, 0.0)

	_fuel_gauge = _make_gauge(Color(1.0, 0.5, 0.1, 0.9))
	_fuel_gauge.position = Vector2(fuel_x, INPUT_SLOT_SIZE + SLOT_GAP)
	_fuel_gauge.size = Vector2(INPUT_SLOT_SIZE, GAUGE_HEIGHT)

	_progress = _make_gauge(Color(0.4, 0.8, 1.0, 0.9))
	_progress.position = Vector2(RECIPE_SLOT_SIZE + ZONE_GAP, INPUT_SLOT_SIZE + SLOT_GAP)
	_progress.size = Vector2(INPUT_ZONE_WIDTH, GAUGE_HEIGHT)


func _make_slot(zone: Zone, index: int, slot_size: float) -> ItemSlot:
	var slot := ItemSlot.new()
	slot.setup({"zone": zone, "index": index}, slot_size, self)
	add_child(slot)
	return slot


func _make_gauge(fill: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.min_value = 0.0
	bar.max_value = 1.0
	bar.show_percentage = false
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.08, 0.08, 0.1, 0.8)
	bg.set_corner_radius_all(3)
	bar.add_theme_stylebox_override("background", bg)

	var fg := StyleBoxFlat.new()
	fg.bg_color = fill
	fg.set_corner_radius_all(3)
	bar.add_theme_stylebox_override("fill", fg)

	add_child(bar)
	return bar


## Colonne des recettes du site branché, une case par recette, illustrée par
## le plat produit : pas de libellé, donc pas de texte à traduire ici.
func _rebuild_recipe_slots() -> void:
	for slot in _recipe_slots:
		slot.queue_free()
	_recipe_slots.clear()
	_recipes_built_for = _transformation
	if _transformation == null:
		return

	for i in _transformation.recipes.size():
		var slot := _make_slot(Zone.RECIPE, i, RECIPE_SLOT_SIZE)
		slot.can_drag = false
		slot.can_drop = false
		slot.position = Vector2(0.0, i * (RECIPE_SLOT_SIZE + SLOT_GAP))
		slot.pressed.connect(_on_recipe_pressed.bind(i))
		_recipe_slots.append(slot)


## Une case par unité attendue : deux bûches demandées = deux cases. Le
## remplissage se lit alors sans afficher le moindre chiffre.
func _rebuild_input_slots(recipe: RecipeDef) -> void:
	for slot in _input_slots:
		slot.queue_free()
	_input_slots.clear()
	_inputs_built_for = recipe
	if recipe == null:
		return

	var units: Array[ResourceDef] = []
	for cost in recipe.inputs:
		for i in cost.amount:
			units.append(cost.resource)

	var total_width: float = units.size() * INPUT_SLOT_SIZE \
		+ maxi(units.size() - 1, 0) * SLOT_GAP
	var start_x: float = (INPUT_ZONE_WIDTH - total_width) * 0.5

	for i in units.size():
		var slot := ItemSlot.new()
		slot.setup({"zone": Zone.INPUT, "index": i}, INPUT_SLOT_SIZE, self)
		slot.can_drag = false
		slot.set_ghost(units[i])
		slot.position = Vector2(start_x + i * (INPUT_SLOT_SIZE + SLOT_GAP), 0.0)
		_inputs_container.add_child(slot)
		_input_slots.append(slot)


## --- Rafraîchissement -----------------------------------------------------

func refresh() -> void:
	if _transformation == null:
		return
	var active := _transformation.active_recipe

	if _transformation != _recipes_built_for:
		_rebuild_recipe_slots()
	_fuel_slot.set_ghost(_host.refuel_resource)

	for i in _recipe_slots.size():
		var recipe: RecipeDef = _transformation.recipes[i]
		_recipe_slots[i].set_content(recipe.output)
		_recipe_slots[i].set_highlighted(recipe == active)

	if active != _inputs_built_for:
		_rebuild_input_slots(active)
	_refresh_input_contents(active)

	_fuel_slot.set_content(_host.refuel_resource if _host.is_active() else null)
	_update_gauges()


## Les cases se remplissent dans l'ordre : autant de cases pleines que
## d'unités déjà déposées. Pendant la cuisson les ingrédients ont été
## consommés côté données, mais ils restent affichés pleins — ils sont sur
## le feu, pas revenus dans la nature.
func _refresh_input_contents(recipe: RecipeDef) -> void:
	if recipe == null:
		return
	var running: bool = _transformation.is_running()
	var remaining: Dictionary = {}
	if not running:
		for cost in recipe.inputs:
			remaining[cost.resource] = _transformation.get_stored_amount(cost.resource)

	for slot in _input_slots:
		var expected: ResourceDef = slot.ghost_content
		if running:
			slot.set_content(expected)
			continue
		var left: int = int(remaining.get(expected, 0))
		if left > 0:
			remaining[expected] = left - 1
			slot.set_content(expected)
		else:
			slot.set_content(null)


func _update_gauges() -> void:
	_fuel_gauge.value = clampf(_host.get_fuel_ratio(), 0.0, 1.0)
	_progress.value = _transformation.get_progress()
	_progress.visible = _transformation.is_running()


## --- Sélection de recette -------------------------------------------------

func _on_recipe_pressed(index: int) -> void:
	# select_recipe() refuse d'elle-même pendant une cuisson et rend les
	# ingrédients déjà déposés si on change d'avis : rien à arbitrer ici.
	_transformation.select_recipe(_transformation.recipes[index])


## --- Contrat ItemSlot -----------------------------------------------------

## Contrairement au sac, le feu accepte les sources étrangères : c'est ce
## qui permet de glisser un champi depuis le sac posé à côté. La source doit
## juste savoir se vider.
func slot_can_accept(target: ItemSlot, source: ItemSlot) -> bool:
	if source.content == null or source.slot_owner == self:
		return false
	if not source.slot_owner.has_method("slot_release"):
		return false
	match target.payload["zone"]:
		Zone.FUEL:
			return source.content == _host.refuel_resource
		Zone.INPUT:
			return _transformation.accepts(source.content)
	return false


func slot_accept_drop(_target: ItemSlot, source: ItemSlot) -> void:
	# Livraison d'abord, retrait de la source ensuite : un refus du feu ne
	# doit jamais faire disparaître l'objet.
	if _host.receive_resource(source.content, 1):
		source.slot_owner.call("slot_release", source)
		refresh()
