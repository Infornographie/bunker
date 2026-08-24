extends OmniLight3D
class_name FlameLightFlicker

## Vacillement simple d'une lumière de feu — bruit aléatoire lissé sur
## l'énergie, pas de dépendance externe (FastNoiseLite suffit, déjà natif).

@export var base_energy: float = 2.0
@export var flicker_amount: float = 0.6
@export var flicker_speed: float = 8.0

var _noise := FastNoiseLite.new()
var _time: float = 0.0

func _ready() -> void:
	_noise.seed = randi()

func _process(delta: float) -> void:
	_time += delta * flicker_speed
	var offset := _noise.get_noise_1d(_time)
	light_energy = base_energy + offset * flicker_amount
