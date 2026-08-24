extends PhysicsBody3D
class_name Interactable

@export var prompt_text: String = "Interagir"

## Override dans les classes filles pour une condition (ex: hache requise).
func can_interact(_interactor: Node) -> bool:
	return true

## Override dans les classes filles pour l'effet réel (récolte, ouverture, etc).
## Volontairement vide ici : Interactable ne connaît aucune logique de jeu.
func interact(_interactor: Node) -> void:
	pass

## Indique si cette interaction se déclenche via l'outil en main (clic gauche,
## action "use_tool") ou via la touche d'interaction générique (E, "interact").
## Par défaut : générique. Choppable la surcharge (voir choppable.gd).
func uses_tool_trigger() -> bool:
	return false

## Appelé à l'impact d'un swing d'outil pointé ici, que ce soit interactable
## ou non. Par défaut : ne fait rien — l'obstacle a juste stoppé le swing.
func receive_tool_hit(_tool: ToolDef, _hit_origin: Vector3 = Vector3.ZERO) -> void:
	pass

## Reçoit une ressource livrée manuellement (E, en portant l'objet). Retourne
## true si acceptée — l'appelant (InteractionController) consomme alors
## l'objet porté. No-op par défaut : seuls les réceptacles (chantiers,
## structures rechargeables...) le redéfinissent.
func receive_resource(_resource: ResourceDef, _amount: int) -> bool:
	return false

## Utilitaire pour les sous-classes réceptrices : résout le ResourceDef
## actuellement porté par l'interactor, ou null si rien / pas une ressource.
func _get_carried_resource(interactor: Node) -> ResourceDef:
	if interactor is InteractionController:
		var controller := interactor as InteractionController
		if controller.carry_controller:
			var item: Node = controller.carry_controller.get_carried_item()
			if item is ResourcePickup:
				return item.resource_def
	return null
