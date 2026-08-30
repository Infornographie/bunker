extends WorldPanel
class_name CookingPanel

## Destination : entities/interactable/panel/cooking_panel.gd
##
## Panneau d'un site de transformation, posé devant son bâtiment.
##
## Disposition :
##   [recettes]   [ ingrédients, une case par unité attendue ]   [combustible]
##                        [ progression ]                          [ jauge ]
##
## Il ne calcule rien : la recette active, l'avancement, ce qui manque et le
## combustible restant appartiennent à TransformationSite et à l'hôte. Tout
## dépôt repart par Campfire.receive_resource(), le même point d'entrée que
## le E en jeu — le panneau n'ouvre pas un second chemin de livraison.

## Identifiants de zone, portés par le payload des cases.
enum Zone { RECIPE, INPUT, FUEL }

const RECIPE_COLUMN: float = -2.6
const FUEL_COLUMN: float = 2.6
const GAUGE_HEIGHT: float = 0.03

var _host: Campfire
var _transformation: TransformationSite

var _recipe_slots: Array[PanelSlot] = []
var _input_slots: Array[PanelSlot] = []
var _fuel_slot: PanelSlot
var _progress: PanelGauge
var _fuel_gauge: PanelGauge
## Recette pour laquelle les cases d'ingrédients ont été construites : leur
## nombre dépend d'elle, donc elles se reconstruisent quand elle change.
var _inputs_built_for: RecipeDef


## Branche le panneau sur un feu. Appelé avant l'ouverture, qui passe elle
## par UIPanelController.
func bind(campfire: Campfire) -> void:
	_host = campfire
	_transformation = campfire.transformation
	if _transformation and not _transformation.state_changed.is_connected(refresh):
		_transformation.state_changed.connect(refresh)


func close() -> void:
	if _transformation and _transformation.state_changed.is_connected(refresh):
		_transformation.state_changed.disconnect(refresh)
	super()


## Progression et combustible s'écoulent en continu : ils se lisent par
## frame, contrairement au reste qui suit le signal state_changed.
func _process(delta: float) -> void:
	super(delta)
	if is_instance_valid(_host):
		_update_gauges()


## --- Construction ---------------------------------------------------------

func _build_content() -> void:
	# Colonne des recettes, une case par recette, illustrée par le plat
	# produit : pas de libellé, donc pas de texte à traduire ici.
	for i in _transformation.recipes.size():
		var slot := make_slot({"zone": Zone.RECIPE, "index": i})
		slot.position = grid_position(RECIPE_COLUMN, i - 1.0)
		_recipe_slots.append(slot)

	_fuel_slot = make_slot({"zone": Zone.FUEL, "index": 0})
	_fuel_slot.position = grid_position(FUEL_COLUMN, 0.0)
	_fuel_slot.set_ghost(_host.refuel_resource)

	_fuel_gauge = _make_gauge(slot_size, Color(1.0, 0.5, 0.1, 0.9))
	_fuel_gauge.position = grid_position(FUEL_COLUMN, 0.75)

	_progress = _make_gauge(slot_size * 3.0 + slot_gap * 2.0, Color(0.4, 0.8, 1.0, 0.9))
	_progress.position = grid_position(0.0, 0.75)


func _make_gauge(width: float, color: Color) -> PanelGauge:
	var gauge := PanelGauge.new()
	add_child(gauge)
	gauge.setup(width, GAUGE_HEIGHT, color)
	return gauge


## Une case par unité attendue : deux bûches demandées, deux cases. Le
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

	var first_column: float = -(units.size() - 1) * 0.5
	for i in units.size():
		var slot := make_slot({"zone": Zone.INPUT, "index": i})
		slot.set_ghost(units[i])
		slot.position = grid_position(first_column + i, 0.0)
		_input_slots.append(slot)


## --- Rafraîchissement -----------------------------------------------------

func refresh() -> void:
	if _transformation == null:
		return
	var active := _transformation.active_recipe

	for i in _recipe_slots.size():
		_recipe_slots[i].set_content(_transformation.recipes[i].output)

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
	_fuel_gauge.set_ratio(_host.get_fuel_ratio())
	_progress.set_ratio(_transformation.get_progress())
	_progress.visible = _transformation.is_running()


## --- Contrat de case ------------------------------------------------------

func slot_content(slot: PanelSlot) -> ResourceDef:
	return slot.content


## Une case de recette se choisit ; les autres se remplissent.
func slot_action_key(slot: PanelSlot) -> String:
	var payload: Dictionary = slot.payload
	if int(payload["zone"]) == Zone.RECIPE:
		return "interact.prompt.choose"
	return ""


func slot_activate(slot: PanelSlot) -> void:
	var payload: Dictionary = slot.payload
	# select_recipe() refuse d'elle-même pendant une cuisson et rend les
	# ingrédients déjà déposés si on change d'avis : rien à arbitrer ici.
	_transformation.select_recipe(_transformation.recipes[int(payload["index"])])
	refresh()


## Ce qui part sur les braises n'en revient pas : aucune case de ce panneau
## ne se vide à la main.
func slot_can_take(_slot: PanelSlot) -> bool:
	return false


func slot_accepts(slot: PanelSlot, resource: ResourceDef) -> bool:
	if resource == null:
		return false
	var payload: Dictionary = slot.payload
	match int(payload["zone"]):
		Zone.FUEL:
			return resource == _host.refuel_resource
		Zone.INPUT:
			return _transformation.accepts(resource)
	return false


func slot_put(slot: PanelSlot, resource: ResourceDef) -> bool:
	if not slot_accepts(slot, resource):
		return false
	# Un seul chemin de livraison, celui du E en jeu.
	if not _host.receive_resource(resource, 1):
		return false
	refresh()
	return true
