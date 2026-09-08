extends Interactable
class_name Workbench
## Établi : transforme des ressources en outils.
##
## **Il ne fait presque rien lui-même.** Toute la mécanique vit dans son
## `TransformationSite` et dans le `RecipePanel` ; ce script n'existe que pour
## être la cible du raycast, ouvrir le panneau et router les dépôts vers le
## site. Il n'a ni combustible ni état actif — le panneau s'en aperçoit tout
## seul et n'affiche pas de colonne de combustible.

@export var transformation: TransformationSite
@export var panel_scene: PackedScene


func can_interact(_interactor: Node) -> bool:
	# Toujours vrai : mains vides, E ouvre le panneau ; mains pleines, la
	# livraison passe par `receive_resource()` en amont.
	return true


## Le prompt suit ce que le joueur propose, pas seulement l'état de l'établi.
func get_prompt_key(interactor: Node) -> String:
	var resource := _get_offered_resource(interactor)
	if resource != null and transformation != null and transformation.accepts(resource):
		return "interact.prompt.deliver"
	return "building.workbench.name"


## Atteint uniquement quand rien n'est proposé : les livraisons sont traitées
## en amont par `InteractionController`. Sans ce point d'entrée, l'établi
## n'ouvre jamais son panneau — et le dépôt à la main sélectionne alors
## toujours la première recette qui accepte l'ingrédient.
func interact(interactor: Node) -> void:
	interactor.open_object_panel(self, panel_scene)


func _get_offered_resource(interactor: Node) -> ResourceDef:
	if interactor is InteractionController:
		return interactor.get_offered_resource()
	return null


## Un seul point d'entrée pour les dépôts, celui du E en jeu comme celui du
## panneau — l'établi n'ouvre pas un second chemin de livraison.
func receive_resource(resource: ResourceDef, _amount: int) -> bool:
	if transformation == null:
		return false
	return transformation.try_insert(resource)


func can_receive_resource(resource: ResourceDef) -> bool:
	return transformation != null and transformation.accepts(resource)
