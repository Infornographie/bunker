extends Node

## Wrapper minimal autour de TranslationServer. Point unique pour lire et
## changer la langue courante. Porte aussi sa bascule debug (F8) : le jour
## où on la retire, tout part d'ici.
##
## Pas de class_name (conflit garanti avec le nom d'autoload).

const SUPPORTED: PackedStringArray = ["en", "fr"]
const FALLBACK: String = "en"

signal locale_changed(locale: String)


func _ready() -> void:
	# Priorité basse : l'autoload est en tête d'arbre, il reçoit les inputs
	# non consommés en dernier. C'est ce qu'on veut pour une touche debug.
	process_mode = Node.PROCESS_MODE_ALWAYS


func get_locale() -> String:
	var current := TranslationServer.get_locale().substr(0, 2)
	return current if current in SUPPORTED else FALLBACK


func set_locale(locale: String) -> void:
	if locale not in SUPPORTED or locale == get_locale():
		return
	TranslationServer.set_locale(locale)
	locale_changed.emit(locale)


## --- Debug --------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_locale"):
		_cycle()
		get_viewport().set_input_as_handled()


func _cycle() -> void:
	var index := SUPPORTED.find(get_locale())
	set_locale(SUPPORTED[(index + 1) % SUPPORTED.size()])
