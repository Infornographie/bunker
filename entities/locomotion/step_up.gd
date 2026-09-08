class_name StepUp
extends RefCounted
## Franchissement automatique des obstacles bas, pour tout `CharacterBody3D`.
##
## Godot n'en fournit pas : un `CharacterBody3D` bloqué par une contremarche de
## 5 cm y reste. On teste donc si la même trajectoire passerait plus haut, et si
## oui on repose le corps sur l'obstacle.
##
## **Ce seuil est le pendant physique de `filter_low_hanging_obstacles` du
## navmesh.** Le bake déclare franchissables les obstacles plus bas que la
## marche de l'agent — branches, cailloux, champignons — et trace donc des
## chemins qui passent par-dessus. Si le corps, lui, s'y cogne, le pawn s'arrête
## net sur un chemin parfaitement valide, sans erreur ni avertissement. Les deux
## hauteurs doivent rester égales : c'est la même décision, écrite deux fois
## parce qu'elle vit dans deux moteurs.
static func try_step(body: CharacterBody3D, direction: Vector3,
		step_height: float, check_distance: float) -> void:
	var motion := direction * check_distance

	if not body.test_move(body.global_transform, motion):
		return  # rien ne bloque à hauteur actuelle, pas de marche à franchir

	var raised := body.global_transform
	raised.origin += Vector3.UP * step_height

	if body.test_move(raised, motion):
		return  # bloqué même en hauteur -> vrai mur, pas une marche franchissable

	# Le chemin est libre une fois surélevé : on redescend depuis là pour se
	# poser précisément sur la marche plutôt que de rester en l'air.
	var settle := raised
	settle.origin += motion

	var collision := KinematicCollision3D.new()
	if body.test_move(settle, Vector3.DOWN * step_height, collision):
		body.global_position += Vector3.UP * step_height + collision.get_travel()
