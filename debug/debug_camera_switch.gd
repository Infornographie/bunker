extends Node
class_name DebugCameraSwitch

## Bascule entre la caméra du joueur et le FreecamController via une touche
## de debug. Au passage en mode debug, le freecam est téléporté à la
## position/orientation exacte de la caméra joueur, pour ne pas perdre le
## contexte visuel au moment du switch.

@export_node_path("PlayerController") var player_path: NodePath
@export_node_path("FreecamController") var freecam_path: NodePath

var _player: PlayerController
var _freecam: FreecamController
var _debug_mode: bool = false

func _ready() -> void:
	_player = get_node(player_path)
	_freecam = get_node(freecam_path)

	# call_deferred : s'exécute après TOUS les _ready() de la frame en cours,
	# quel que soit l'ordre des enfants dans l'arbre. Sans ça, si FreeCam
	# est ready() après ce coordinateur, son propre start_active=true écrase
	# la désactivation qu'on vient de lui donner.
	call_deferred("_apply_initial_state")

func _apply_initial_state() -> void:
	# Départ toujours côté joueur ; le freecam reste désactivé jusqu'au
	# premier appui sur la touche de debug.
	_player.set_active(true)
	_freecam.set_active(false)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_debug_cam"):
		_toggle()

func _toggle() -> void:
	_debug_mode = not _debug_mode

	if _debug_mode:
		_freecam.sync_transform_from(_player._camera)
		_player.set_active(false)
		_freecam.set_active(true)
	else:
		_player.set_active(true)
		_freecam.set_active(false)

# --- Notes d'intégration ---
# - À attacher sur un Node dans la scène de test (par ex. la racine),
#   PAS sur le joueur ni le freecam eux-mêmes — logique de coordination
#   séparée des deux contrôleurs qu'elle orchestre.
# - Assigner player_path et freecam_path dans l'inspecteur une fois les deux
#   nodes présents dans la scène.
# - Nouvelle action Input Map requise : "toggle_debug_cam". Suggestion :
#   touche F1 (peu de risque de conflit avec le reste du jeu).
# - _player._camera est accédé directement (pas de getter dédié) — acceptable
#   ici vu que c'est un script de debug interne au même module ; à revoir
#   si PlayerController expose un jour une API publique plus stricte.
