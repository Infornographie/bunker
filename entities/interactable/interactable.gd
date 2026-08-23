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
