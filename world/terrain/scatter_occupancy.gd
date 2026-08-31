@tool
class_name ScatterOccupancy
extends RefCounted
## Ce que le semis a déjà posé, et à quel point le sol en est couvert.
##
## **Deux grilles, parce qu'il y a deux problèmes.** Empêcher un buisson de
## pousser dans un tronc est une contrainte dure, binaire, sur un petit rayon —
## la base de la plante. Empêcher l'herbe de pousser sous un couvert fermé est
## une contrainte douce, sur un grand rayon — le feuillage — et elle module une
## *densité*, pas une autorisation.
##
## Les confondre ne marche pas : à sept mètres d'espacement, des disques de
## feuillage de six mètres de rayon couvrent la carte à plus de cent pour cent.
## Traiter l'ombre comme un refus, c'est n'avoir aucune strate basse nulle part.
##
## La grille de couverture est la **carte d'ouverture** : c'est elle qui pilotera
## la strate sol, qui teintera le sol pour que les clairières lointaines existent
## autrement qu'en creux, et qui fera pousser l'herbe là où on aura déboisé. Une
## seule structure, trois usages — pas trois calculs à tenir d'accord.

var _cell: float
var _side: int
var _origin: Vector2
var _blocked: PackedByteArray
var _cover: PackedFloat32Array


## La grille couvre une zone quelconque : la carte entière pour l'occupation
## permanente, un seul chunk pour celle d'une strate streamée, qui naît et meurt
## avec lui. Même code, deux portées.
func _init(cell_size: float, area: Rect2) -> void:
	_cell = cell_size
	_origin = area.position
	_side = int(ceil(maxf(area.size.x, area.size.y) / _cell)) + 1
	_blocked.resize(_side * _side)
	_cover.resize(_side * _side)


## Vrai si un disque de ce rayon recoupe une base déjà posée. On teste le disque
## du candidat et pas seulement son centre : deux plantes ne se traversent pas
## dès que leur distance dépasse la *somme* de leurs rayons, et un test au centre
## n'en verrait qu'un seul.
func is_blocked(point: Vector2, radius: float) -> bool:
	for iz in range(_cell_of_z(point.y - radius), _cell_of_z(point.y + radius) + 1):
		for ix in range(_cell_of_x(point.x - radius), _cell_of_x(point.x + radius) + 1):
			if _blocked[iz * _side + ix] != 0:
				return true
	return false


## Couverture au-dessus d'un point : 0 à découvert, 1 sous un couvert fermé.
func cover_at(point: Vector2) -> float:
	return minf(_cover[_cell_of_z(point.y) * _side + _cell_of_x(point.x)], 1.0)


## Inscrit une plante : l'emprise que rien ne pourra plus occuper, et l'ombre
## qu'elle porte alentour.
func mark(point: Vector2, base_radius: float, cover_radius: float, cover_amount: float) -> void:
	if base_radius > 0.0:
		for iz in range(_cell_of_z(point.y - base_radius), _cell_of_z(point.y + base_radius) + 1):
			for ix in range(_cell_of_x(point.x - base_radius), _cell_of_x(point.x + base_radius) + 1):
				if _center_of(ix, iz).distance_to(point) <= base_radius:
					_blocked[iz * _side + ix] = 1
	if cover_radius <= 0.0 or cover_amount <= 0.0:
		return
	# Le couvert s'éteint vers le bord plutôt que de s'arrêter net : un masque
	# binaire dessinerait le contour du feuillage dans la répartition de
	# l'herbe, et un disque net se voit toujours.
	for iz in range(_cell_of_z(point.y - cover_radius), _cell_of_z(point.y + cover_radius) + 1):
		for ix in range(_cell_of_x(point.x - cover_radius), _cell_of_x(point.x + cover_radius) + 1):
			var index := iz * _side + ix
			var falloff := 1.0 - smoothstep(0.0, cover_radius, _center_of(ix, iz).distance_to(point))
			_cover[index] += cover_amount * falloff


## Indice de cellule contenant une coordonnée, borné à la grille.
func _cell_of_x(value: float) -> int:
	return clampi(int(floor((value - _origin.x) / _cell)), 0, _side - 1)


func _cell_of_z(value: float) -> int:
	return clampi(int(floor((value - _origin.y) / _cell)), 0, _side - 1)


func _center_of(ix: int, iz: int) -> Vector2:
	return _origin + Vector2(ix + 0.5, iz + 0.5) * _cell
