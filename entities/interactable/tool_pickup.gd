extends Interactable
class_name ToolPickup

## Outil posé au sol — créé dynamiquement par PlayerEquipment quand le
## joueur dépose un outil depuis la ceinture (G). Pas de .tscn associé :
## la collision et le mesh sont montés en code au spawn.
##
## Sur E : tente de ranger dans la ceinture. Si la ceinture est pleine,
## ne fait rien (pas d'overflow en main pour les outils, à revoir plus tard).

var tool_def: ToolDef


func can_interact(interactor: Node) -> bool:
	var eq := _get_inventory(interactor)
	if eq == null:
		return false
	# Pickup possible seulement si la ceinture a un slot libre.
	for i in Inventory.BELT_COUNT:
		if eq.get_belt_tool(i) == null:
			return true
	return false


func interact(interactor: Node) -> void:
	var eq := _get_inventory(interactor)
	if eq == null:
		return
	if eq.try_store_tool(tool_def):
		queue_free()


func _get_inventory(interactor: Node) -> Inventory:
	if interactor is InteractionController:
		return interactor.inventory
	return null
