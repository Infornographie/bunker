extends StaticBody3D
class_name Interactable

@export var prompt_text: String = "Interagir"

## Override dans les classes filles pour une condition (ex: hache requise).
func can_interact(_interactor: Node) -> bool:
	return true

## Override dans les classes filles pour l'effet réel (récolte, ouverture, etc).
## Volontairement vide ici : Interactable ne connaît aucune logique de jeu.
func interact(_interactor: Node) -> void:
	pass
