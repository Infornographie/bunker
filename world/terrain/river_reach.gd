@tool
class_name RiverReach
extends RefCounted
## Un bief : une portion de cours d'eau, de son tracé à sa surface.
##
## Le bras principal en est un, un bras d'île en est un autre, et un affluent ou
## une cascade en seront d'autres le jour où ils existeront. C'est ce qui évite
## que le constructeur de ruban n'ait un cas particulier par sorte de cours
## d'eau : il en reçoit une liste et les traite tous pareil.
##
## Les trois tableaux ont la même longueur et se lisent au même indice. Le
## générateur les remplit, le constructeur de ruban et le semis les lisent —
## personne ne recalcule une largeur ou une ligne d'eau de son côté.

## Points du cours, en coordonnées monde (x, z).
var path: PackedVector2Array
## Altitude de la surface en chaque point. Ne remonte jamais d'un point au
## suivant : c'est cette contrainte qui fait qu'un relief en travers du cours
## est tranché plutôt que contourné.
var water: PackedFloat32Array
## Largeur du lit en chaque point, en mètres.
var widths: PackedFloat32Array


func _init(p: PackedVector2Array, w: PackedFloat32Array, wd: PackedFloat32Array) -> void:
	path = p
	water = w
	widths = wd
