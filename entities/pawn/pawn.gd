class_name PawnController
extends CharacterBody3D
## Un pawn qui se déplace sur le navmesh. Socle du Jalon 5, passe B.
##
## Deux états, et rien d'autre : il attend, ou il va quelque part. C'est le
## minimum qui exerce vraiment la chaîne — tirage de destination, requête de
## chemin, locomotion, orientation, animation — sans préjuger de ce que le
## Jalon 6 mettra à la place du tirage au sort. Les états `EVALUATING` et
## `INTERRUPTED` viendront s'ajouter ici, pas remplacer ceux-là.
##
## Ce nœud ne se tick pas encore par un `PawnManager` : il vit dans son
## `_physics_process`. C'est assumé le temps de la passe B, et c'est précisément
## ce que la passe C viendra retirer — d'où le regroupement de toute la décision
## dans `_think()`, seul point que le manager aura à appeler.

enum State { IDLE, MOVING }

## Vitesse de marche. Volontairement lente : le joueur court à ~13 m/s, ce qui
## est déjà noté comme une anomalie à corriger au Jalon 7. Un pawn qui marche à
## la vitesse d'un humain est le mètre-étalon qui rendra cet écart visible.
@export var move_speed: float = 2.2
## Vitesse de rotation vers la direction de marche, en radians par seconde.
@export var turn_speed: float = 8.0
@export var idle_duration: Vector2 = Vector2(1.0, 5.0)
## Rayon de vadrouille autour de la position courante. Un tirage sur la carte
## entière enverrait chaque pawn faire 200 m au premier pas : bon pour éprouver
## le pathfinding, illisible pour regarder un bonhomme marcher.
@export var wander_radius: float = 40.0
## Hauteur d'obstacle franchie sans y penser. **Doit rester égale à la marche
## déclarée au navmesh** (`agent_max_climb`) : le bake déclare franchissables
## les objets plus bas qu'elle et trace des chemins par-dessus. Un corps qui s'y
## cogne s'arrête net sur un chemin valide, sans la moindre erreur.
@export var step_height: float = 0.4
@export var step_check_distance: float = 0.3
## Trace les transitions d'état à la console. Instrument de mise au point de la
## passe B, à retirer quand le banc de mesure de la passe C prendra le relais :
## un print par pawn et par frame ne passera pas l'échelle.
@export var debug_trace: bool = false

## Vitesse au sol en dessous de laquelle on considère le pawn à l'arrêt, pour
## le choix d'animation. Le critère est la vitesse **réelle** et non l'état :
## un pawn bloqué contre un tronc doit cesser de mimer la marche.
const _MOVING_THRESHOLD: float = 0.15
## Animations du pack à jouer en boucle. Le glTF ne déclare aucun mode de
## bouclage — le moteur ne le devine pas — donc une marche importée telle
## quelle se joue une fois et fige le personnage debout, jambes écartées.
const _LOOPED: Array[String] = ["Idle", "Walk", "Run"]
const _ANIM_IDLE := "Idle"
const _ANIM_WALK := "Walk"
## Distance minimale d'une destination. En deçà, le pawn ferait trois pas et se
## replanterait — beaucoup de décisions pour aucun déplacement lisible.
const _MIN_TRAVEL: float = 5.0

@onready var _agent: NavigationAgent3D = $NavigationAgent3D

var _animation: AnimationPlayer
var _state: int = State.IDLE
var _idle_left: float = 0.0
var _fresh_departure: bool = false
# `get_setting()` rend un `Variant` : l'inférence échouerait, comme sur tout
# retour d'autoload. La conversion est explicite.
var _gravity: float = float(ProjectSettings.get_setting("physics/3d/default_gravity", 9.8))


func _ready() -> void:
	# L'`AnimationPlayer` est cherché plutôt que déclaré en `NodePath` : il vit
	# dans l'arbre **importé** du modèle, dont la forme appartient au pack et non
	# au projet. Un chemin écrit à la main se périmerait au premier réimport, et
	# en silence.
	_animation = find_child("AnimationPlayer", true, false) as AnimationPlayer
	if _animation == null:
		push_error("PawnController : aucun AnimationPlayer sous le modèle, pas d'animation.")
	else:
		_enable_looping()
	_idle_left = randf_range(idle_duration.x, idle_duration.y)


## Le glTF importé porte ses animations sans mode de bouclage ; celui-ci se pose
## donc sur la ressource au démarrage. Le faire ici plutôt que dans les réglages
## d'import garde la vérité dans le code, à côté de la liste des animations
## qu'on boucle vraiment.
func _enable_looping() -> void:
	# `name` est une propriété de `Node` : une variable de boucle qui la
	# masquerait lève un avertissement, et le projet les traite en erreurs.
	for anim_name in _LOOPED:
		if not _animation.has_animation(anim_name):
			push_warning("PawnController : animation « %s » absente du modèle." % anim_name)
			continue
		_animation.get_animation(anim_name).loop_mode = Animation.LOOP_LINEAR


func _physics_process(delta: float) -> void:
	_think(delta)
	_locomote(delta)
	_animate()


# --- Décision ------------------------------------------------------------------

## Tout ce qui décide vit ici. C'est ce que le `PawnManager` de la passe C
## appellera à son rythme, sous budget — et c'est la raison pour laquelle rien
## de ce qui décide n'a le droit de descendre dans `_locomote()`.
func _think(delta: float) -> void:
	match _state:
		State.IDLE:
			_idle_left -= delta
			if _idle_left <= 0.0:
				_depart()
		State.MOVING:
			# L'agent ne rafraîchit son verdict qu'une fois son chemin
			# interrogé, ce qui n'arrive qu'en fin de frame dans `_locomote()`.
			# Le tester dès la frame du départ, c'est lire la réponse du trajet
			# précédent — « terminé » — et se replanter aussitôt parti.
			if _fresh_departure:
				_fresh_departure = false
			elif _agent.is_navigation_finished():
				_trace("arrivé à %v" % _agent.target_position)
				_rest()


func _depart() -> void:
	var destination := _pick_destination()
	if destination == Vector3.ZERO:
		# Carte de navigation pas encore prête : le bake est lancé sur un thread
		# à la génération du terrain et met plus d'une seconde. On repasse en
		# attente au lieu de partir vers l'origine du monde.
		_trace("carte de navigation pas prête, réessai")
		_idle_left = 0.5
		return
	_agent.target_position = destination

	# L'agent calcule son chemin **paresseusement**, à la première interrogation.
	# Sans cet appel, `is_navigation_finished()` répond encore sur le trajet
	# précédent — donc « terminé » — et le pawn se replante à peine parti. Pire :
	# tant qu'aucun chemin n'existe, `get_next_path_position()` rend la
	# destination elle-même, et le pawn y va en ligne droite, à travers rochers
	# et troncs. Deux symptômes, une seule cause, et pas la moindre erreur.
	_agent.get_next_path_position()
	if _agent.get_current_navigation_path().is_empty():
		push_warning("PawnController : aucun chemin vers %v, nouvelle tentative." % destination)
		_idle_left = 0.5
		return

	_state = State.MOVING
	_fresh_departure = true
	_trace("part vers %v (%d points, %.0f m)" % [
		destination,
		_agent.get_current_navigation_path().size(),
		global_position.distance_to(destination),
	])


func _rest() -> void:
	_state = State.IDLE
	_idle_left = randf_range(idle_duration.x, idle_duration.y)
	_trace("attend %.1f s" % _idle_left)
	velocity.x = 0.0
	velocity.z = 0.0


## Une destination proche, **sur le navmesh**. On tire un point dans le disque
## de vadrouille autour du pawn, puis on demande au serveur le point navigable
## le plus proche : la projection est ce qui garantit une cible atteignable,
## jamais dans un tronc ni au milieu de la rivière.
##
## Le tirage uniforme sur la carte entière, essayé d'abord, ne pouvait pas
## marcher : sur 384 m de côté, un point au hasard tombe à ~200 m en moyenne,
## et un rayon de 40 m couvre 3 % de la surface. Huit tirages avec rejet ne
## trouvaient donc jamais rien et rendaient le dernier venu — d'où des
## expéditions de 193 m à 2,2 m/s, soit une minute et demie de marche avant la
## moindre réévaluation. Échantillonner *là où on veut le point* coûte un appel
## au lieu de huit, et ne peut pas échouer.
##
## Renvoie `Vector3.ZERO` tant que la carte n'est pas exploitable.
func _pick_destination() -> Vector3:
	var map := _agent.get_navigation_map()
	# Un RID valide ne veut pas dire une carte utilisable : la carte par défaut
	# du monde existe dès la première frame, vide, pendant que le bake tourne sur
	# son thread. Interroger une carte sans région ne lève rien et rend des
	# points nuls — c'est le compte de régions qui dit si le monde est navigable.
	if not map.is_valid() or NavigationServer3D.map_get_regions(map).is_empty():
		return Vector3.ZERO

	var angle := randf() * TAU
	# Racine carrée du tirage : sans elle, les points s'agglutinent au centre du
	# disque, puisque la surface d'une couronne croît avec le rayon.
	var radius := _MIN_TRAVEL + sqrt(randf()) * maxf(wander_radius - _MIN_TRAVEL, 0.0)
	var wanted := global_position + Vector3(cos(angle), 0.0, sin(angle)) * radius
	return NavigationServer3D.map_get_closest_point(map, wanted)


func _trace(message: String) -> void:
	if debug_trace:
		print("[%s] %s" % [name, message])


# --- Locomotion ----------------------------------------------------------------

## Rien ne décide ici : on suit le chemin déjà calculé. La séparation n'est pas
## cosmétique — c'est elle qui permettra au niveau 2 du LOD de remplacer cette
## fonction par une interpolation le long du chemin, sans toucher à `_think()`.
func _locomote(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= _gravity * delta

	if _state == State.MOVING:
		var step := _agent.get_next_path_position() - global_position
		step.y = 0.0
		if step.length() > 0.001:
			var direction := step.normalized()
			velocity.x = direction.x * move_speed
			velocity.z = direction.z * move_speed
			_face(direction, delta)
			StepUp.try_step(self, direction, step_height, step_check_distance)

	move_and_slide()


## Oriente le pawn vers sa direction de marche. L'angle est interpolé et non
## posé : le chemin rendu par l'agent est une suite de segments, et poser
## l'angle ferait pivoter le pawn d'un quart de tour sur place à chaque coude.
##
## **Le modèle du pack regarde vers +Z**, à l'inverse de la convention Godot où
## l'avant est -Z. C'est ce qui faisait marcher le pawn à reculons — il allait
## au bon endroit, dos devant. On aligne donc +Z sur la direction, et surtout on
## ne compense pas en tournant le nœud `Model` : l'orientation du corps est ce
## que lisent la navigation, le regard et plus tard le bras porte-outil, et une
## correction cachée dans un enfant les ferait tous mentir.
func _face(direction: Vector3, delta: float) -> void:
	var target := atan2(direction.x, direction.z)
	rotation.y = rotate_toward(rotation.y, target, turn_speed * delta)


# --- Animation -----------------------------------------------------------------

## L'animation suit la vitesse mesurée, jamais l'état. Un pawn coincé contre un
## rocher est en `MOVING` et ne bouge pas : le faire mimer la marche est le
## genre de mensonge qui fait chercher un bug de navigation là où il n'y en a
## pas.
func _animate() -> void:
	if _animation == null:
		return
	var ground_speed := Vector2(velocity.x, velocity.z).length()
	var wanted := _ANIM_WALK if ground_speed > _MOVING_THRESHOLD else _ANIM_IDLE
	if _animation.current_animation != wanted:
		_animation.play(wanted, 0.2)
