extends Interactable
class_name StoragePallet
## Palette de stockage : on y pose, on y reprend.
##
## Comme l'établi, elle ne fait presque rien elle-même — elle est la cible du
## raycast et route vers son `StorageSite`. Le verbe dépend de ce que le joueur
## propose : les mains pleines, E dépose ; les mains vides, E reprend le dernier
## objet posé.

@export var storage: StorageSite


func can_interact(interactor: Node) -> bool:
	if storage == null:
		return false
	var offered := _get_offered_resource(interactor)
	if offered != null:
		return storage.accepts(offered)
	return storage.peek_last() != null


func get_prompt_key(interactor: Node) -> String:
	if storage == null:
		return prompt_key
	if _get_offered_resource(interactor) != null:
		return "interact.prompt.put"
	return "interact.prompt.take"


## Mains vides : reprendre. Les livraisons, elles, sont traitées en amont par
## `InteractionController` et arrivent par `receive_resource()`.
func interact(interactor: Node) -> void:
	if storage == null or not (interactor is InteractionController):
		return
	var resource := storage.peek_last()
	if resource == null:
		return
	# Poches, puis sac, puis la main : le même repli que le ramassage au sol et
	# que la cueillette. Un caillou repris d'une palette n'a pas de raison
	# d'occuper les mains alors qu'un caillou ramassé par terre part en poche.
	var inventory: Inventory = interactor.inventory
	if inventory != null and inventory.try_store(resource):
		var _stored := storage.take_last()
		return
	if not interactor.take_into_hand(resource):
		return
	var _taken := storage.take_last()


func receive_resource(resource: ResourceDef, _amount: int) -> bool:
	return storage != null and storage.try_insert(resource)
