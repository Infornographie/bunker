extends Node
## Autoload singleton — à déclarer dans Project Settings > Autoload sous le
## nom "SoundManager". Gère les SFX ponctuels via un pool de lecteurs
## réutilisables plutôt qu'un AudioStreamPlayer3D par usage.

const POOL_SIZE := 8

var _pool: Array[AudioStreamPlayer3D] = []
var _next_index: int = 0

func _ready() -> void:
	for i in POOL_SIZE:
		var player := AudioStreamPlayer3D.new()
		add_child(player)
		_pool.append(player)

## Joue un son positionné dans le monde (impact, coupe, pas...).
func play_sfx(stream: AudioStream, world_position: Vector3, volume_db: float = 0.0) -> void:
	if stream == null:
		return
	var player := _pool[_next_index]
	_next_index = (_next_index + 1) % POOL_SIZE
	player.stream = stream
	player.global_position = world_position
	player.volume_db = volume_db
	player.play()
