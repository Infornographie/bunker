extends Harvestable
class_name FoliageHarvestable
## Une instance de `MultiMesh` rendue récoltable.
##
## **Ce qui est dessiné et ce qui est présent sont deux choses.** Le semis pose
## des milliers de plantes dans des `MultiMesh` — rapides à dessiner, mais sans
## le moindre nœud à viser ni à heurter. Cette classe est le corps manquant :
## un `StaticBody3D` **sans mesh**, qui coûte zéro appel de dessin et zéro
## ombre, et dont le seul rôle est d'exister pour le raycast d'interaction et
## pour la navigation.
##
## À l'épuisement, la plante disparaît en mettant son instance à l'échelle zéro
## dans chacun des multimesh de son essence. Le multimesh **est** le registre de
## ce qui a été récolté : il n'y a pas de seconde liste à tenir à jour, donc pas
## de risque qu'une plante abattue repousse au retour du joueur.

## Les multimesh où vit cette instance — un par partie du modèle, les modèles
## des packs n'étant pas toujours d'un seul tenant. Effacer une seule partie
## laisserait le reste de la plante en l'air.
var multimeshes: Array[MultiMesh] = []
var instance_index: int = -1


func _ready() -> void:
	super()
	depleted.connect(_erase_instance)


func _erase_instance() -> void:
	if instance_index < 0:
		return
	for mm in multimeshes:
		if mm == null or instance_index >= mm.instance_count:
			continue
		# L'échelle zéro plutôt qu'un retrait du tableau : retirer décalerait
		# tous les index suivants, et chaque corps voisin pointerait alors sur
		# la mauvaise plante.
		var t := mm.get_instance_transform(instance_index)
		mm.set_instance_transform(instance_index, Transform3D(Basis().scaled(Vector3.ZERO), t.origin))
