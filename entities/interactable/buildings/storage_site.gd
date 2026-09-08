extends Node
class_name StorageSite
## Ce qu'un dépôt contient, et comment ça se montre.
##
## **Le contenu est une liste ; la pile est un affichage.** Empiler de vrais
## corps physiques donnerait des bûches qui roulent, une pile qui s'effondre au
## chargement et rien de fiable à viser. Ici la position de chaque objet est
## *déduite* de son rang : « reprendre celui du dessus » est la dernière entrée
## de la liste, un pawn qui dépose n'a rien à viser, et rien ne peut s'écrouler.
##
## **La mise en place lit la ressource, pas une constante.** Le pas de la grille
## vient du `footprint` de chaque ressource et le motif de son `stack_style` :
## une branche d'1,3 m et un caillou de 30 cm ne se rangent pas au même pas, et
## des rondins se calent dans les creux là où des blocs se posent à plat. Un
## espacement unique fait forcément se chevaucher l'un ou gaspiller la place de
## l'autre — c'est ce qu'on a vu.
##
## Rien ici ne suppose un joueur : un pawn appellera `try_insert()` et
## `take_last()` comme le fait la touche d'interaction.

signal changed

## Nombre de petits objets rangeables sur le plateau.
@export_range(1, 32) var small_capacity: int = 9
## Nombre de gros objets empilables par-dessus.
@export_range(1, 32) var large_capacity: int = 6
## Où les exemplaires décoratifs sont attachés.
@export var display_root: Node3D
## Boîte de collision du contenu, redimensionnée avec la pile. Sans elle, tout
## ce qui est posé dessus traverse — les vues sont décoratives et n'ont aucune
## collision propre.
@export var content_collision: CollisionShape3D

@export_group("Plateau")
## Côté utile du plateau, en mètres. Croisé avec le `footprint` d'une ressource,
## il donne le nombre d'exemplaires par rangée.
@export var deck_size: float = 1.4
## Hauteur du plateau où les objets se posent, en mètres.
@export var deck_height: float = 0.3

var _small: Array[ResourceDef] = []
var _large: Array[ResourceDef] = []
var _views: Array[Node3D] = []


func _ready() -> void:
	if display_root == null:
		display_root = get_parent() as Node3D
	_rebuild()


## --- Lecture ------------------------------------------------------------

func is_empty() -> bool:
	return _small.is_empty() and _large.is_empty()


## Tout ce qui est stocké, petits puis gros. Pour un pawn qui cherche une
## ressource, ou un futur panneau d'inventaire.
func contents() -> Array[ResourceDef]:
	var all: Array[ResourceDef] = []
	all.append_array(_small)
	all.append_array(_large)
	return all


func accepts(resource: ResourceDef) -> bool:
	if resource == null:
		return false
	if resource.carry_type == ResourceDef.CarryType.HAND:
		return _large.size() < large_capacity
	return _small.size() < small_capacity


## --- Dépôt et retrait ---------------------------------------------------

func try_insert(resource: ResourceDef) -> bool:
	if not accepts(resource):
		return false
	if resource.carry_type == ResourceDef.CarryType.HAND:
		_large.append(resource)
	else:
		_small.append(resource)
	_rebuild()
	return true


## Retire le dernier objet posé et le retourne. Les gros d'abord : ils sont
## littéralement au-dessus, et on ne prend pas sous une pile.
func take_last() -> ResourceDef:
	var taken: ResourceDef = null
	if not _large.is_empty():
		taken = _large.pop_back()
	elif not _small.is_empty():
		taken = _small.pop_back()
	if taken != null:
		_rebuild()
	return taken


## Ce que `take_last()` rendrait, sans le retirer — pour le prompt.
func peek_last() -> ResourceDef:
	if not _large.is_empty():
		return _large[_large.size() - 1]
	if not _small.is_empty():
		return _small[_small.size() - 1]
	return null


## --- Affichage ----------------------------------------------------------

## Le visuel est reconstruit en entier à chaque changement. À une dizaine
## d'objets et sur un événement rare, calculer un delta coûterait plus de code
## qu'il n'économise de travail — et une reconstruction complète ne peut pas
## se désynchroniser du contenu.
func _rebuild() -> void:
	for view in _views:
		view.queue_free()
	_views.clear()
	if display_root == null:
		changed.emit()
		return

	var top := deck_height
	top = maxf(top, _lay_out(_small, deck_height))
	top = maxf(top, _lay_out(_large, top))
	_fit_collision(top)
	changed.emit()


## Pose une liste à partir d'une hauteur donnée et retourne le sommet atteint.
## Les objets d'une même liste peuvent être de tailles différentes ; le pas et
## le motif se relisent donc à chaque exemplaire.
func _lay_out(items: Array[ResourceDef], base: float) -> float:
	var top := base
	for i in items.size():
		var res := items[i]
		var placement := _placement_of(res, i, base)
		_place(res, placement)
		top = maxf(top, placement.origin.y + res.stack_height)
	return top


## Rapport au-delà duquel un objet est traité comme allongé, donc empilé en
## couches croisées.
const _ELONGATED_RATIO := 1.5


## Où et comment se pose l'exemplaire de rang `index`.
func _placement_of(resource: ResourceDef, index: int, base: float) -> Transform3D:
	if resource.stack_style == ResourceDef.StackStyle.PYRAMID:
		return _pyramid_placement(resource, index, base)
	return _grid_placement(resource, index, base)


## Couches successives. Un objet allongé tourne d'un quart de tour à chaque
## étage — ses pas s'échangent avec lui, sinon la couche croisée déborderait du
## plateau dans un sens et laisserait un vide dans l'autre.
func _grid_placement(resource: ResourceDef, index: int, base: float) -> Transform3D:
	var long_side := maxf(resource.footprint.x, 0.05)
	var short_side := maxf(resource.footprint.y, 0.05)
	var crossing := long_side / short_side > _ELONGATED_RATIO

	# Combien tiennent par couche, dans l'orientation « au repos ».
	var cols: int = maxi(1, int(floor(deck_size / long_side)))
	var rows: int = maxi(1, int(floor(deck_size / short_side)))
	var per_layer: int = cols * rows
	var layer: int = index / per_layer
	var in_layer: int = index % per_layer
	var col: int = in_layer % cols
	var row: int = in_layer / cols

	var turned := crossing and layer % 2 == 1
	var step_x := short_side if turned else long_side
	var step_z := long_side if turned else short_side
	# Une couche tournée compte ses colonnes sur l'autre axe.
	var half_col := (rows - 1) * 0.5 if turned else (cols - 1) * 0.5
	var half_row := (cols - 1) * 0.5 if turned else (rows - 1) * 0.5
	if turned:
		var swap := col
		col = row
		row = swap

	var origin := Vector3((col - half_col) * step_x,
			base + resource.stack_height * layer,
			(row - half_row) * step_z)
	var basis := Basis.IDENTITY
	if turned:
		basis = Basis(Vector3.UP, PI * 0.5)
	return Transform3D(basis, origin)


## Pyramide : chaque étage porte une rangée de moins et se décale d'un demi-pas
## pour reposer dans le creux du précédent. Réservé à ce qui roule.
func _pyramid_placement(resource: ResourceDef, index: int, base: float) -> Transform3D:
	var step := maxf(resource.footprint.y, 0.05)
	var row: int = maxi(1, int(floor(deck_size / step)))
	var placed := 0
	var layer := 0
	while row > 1 and placed + row <= index:
		placed += row
		row -= 1
		layer += 1
	var col := index - placed
	var half := (row - 1) * 0.5
	return Transform3D(Basis.IDENTITY, Vector3((col - half) * step,
			base + resource.stack_height * layer, 0.0))


## Pose un exemplaire de sorte que **son point le plus bas** repose sur la
## couche. La hauteur voulue ne peut pas se déduire du modèle : l'origine d'un
## asset est tantôt son centre, tantôt sa base, et rien ne le dit. Un décalage
## réglé à la main par ressource marcherait jusqu'au prochain asset importé —
## mesurer la boîte englobante marche pour tous, y compris ceux qu'on n'a pas
## encore.
func _place(resource: ResourceDef, placement: Transform3D) -> void:
	var view := ResourceRegistry.spawn_display(resource)
	if view == null:
		return
	display_root.add_child(view)
	view.transform = placement
	view.position.y += placement.origin.y - _lowest_point(view)
	_views.append(view)


## Altitude du point le plus bas de la géométrie d'un nœud, dans le repère du
## dépôt. Les boîtes englobantes des `VisualInstance3D` sont en espace local :
## chacune est ramenée ici par le transform qui l'y rattache.
func _lowest_point(root: Node3D) -> float:
	var lowest := INF
	for node in _visuals(root):
		var aabb := node.get_aabb()
		var to_root := root.transform * _relative_transform(node, root)
		for i in 8:
			lowest = minf(lowest, (to_root * aabb.get_endpoint(i)).y)
	return 0.0 if is_inf(lowest) else lowest


func _visuals(node: Node) -> Array[VisualInstance3D]:
	var found: Array[VisualInstance3D] = []
	if node is VisualInstance3D:
		found.append(node)
	for child in node.get_children():
		found.append_array(_visuals(child))
	return found


## Transform d'un nœud relativement à un ancêtre, sans passer par les
## coordonnées globales — le dépôt peut être n'importe où dans la scène.
func _relative_transform(node: Node3D, ancestor: Node3D) -> Transform3D:
	var result := Transform3D.IDENTITY
	var current := node
	while current != null and current != ancestor:
		result = current.transform * result
		current = current.get_parent() as Node3D
	return result


## La collision du contenu est une seule boîte qui monte avec la pile, pas une
## forme par objet : ce qu'on veut, c'est pouvoir marcher et poser dessus, pas
## viser un rondin en particulier.
func _fit_collision(top: float) -> void:
	if content_collision == null:
		return
	var box := content_collision.shape as BoxShape3D
	if box == null:
		return
	var height := maxf(top - deck_height, 0.01)
	box.size = Vector3(deck_size, height, deck_size)
	content_collision.position.y = deck_height + height * 0.5
	content_collision.disabled = is_empty()
