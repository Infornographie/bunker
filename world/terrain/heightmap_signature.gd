@tool
class_name HeightmapSignature
extends Node
## Empreinte du générateur de relief sur N graines, pour vérifier qu'un
## remaniement ne change rien à ce qui sort.
##
## À quoi ça sert, et pourquoi ça n'est pas un test unitaire : la sortie du
## générateur est une carte de 161 000 flottants. Personne ne compare ça à l'œil,
## et une différence d'un demi-mètre sur un versant ne se voit sur aucune
## capture. Une empreinte, si — elle change ou elle ne change pas.
##
## Protocole : **écrire la référence avant de toucher au code**, remanier,
## comparer. Une empreinte inchangée sur douze graines est la preuve qu'une
## extraction est bien une extraction et pas une réécriture.
##
## Ce qui est empreint, c'est **tout ce que le générateur publie**, pas seulement
## les hauteurs : la bouche de grotte, le niveau de l'eau, les clairières, le
## tracé de la rivière et l'influence du massif sont lus par le semis, le mesh et
## les biomes. Une extraction qui garde le relief mais décale un tirage de
## clairière n'est pas neutre, et une empreinte des seules hauteurs le raterait.
##
## Ce n'est pas le vérificateur d'invariants de la passe D : celui-ci dit
## « la carte a changé », pas « la carte est valide ». Une composition qui change
## est normale une fois que les features existent ; c'est pendant les
## remaniements à résultat constant que cet outil-ci sert.

## Écrit à côté de ce script. Fichier de travail, pas une ressource du jeu.
const REFERENCE_PATH := "res://world/terrain/heightmap_signature.txt"

@export var config: TerrainGenConfig
## Graines essayées, à partir de celle de la config incluse. Douze suffisent :
## ce qu'on cherche est une différence systématique, pas un cas rare.
@export_range(1, 64) var seed_count: int = 12

@export_tool_button("Écrire la référence") var write_action: Callable = write_reference
@export_tool_button("Comparer à la référence") var compare_action: Callable = compare


func write_reference() -> void:
	var lines := _signatures()
	if lines.is_empty():
		return
	var file := FileAccess.open(REFERENCE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("HeightmapSignature : écriture impossible dans %s." % REFERENCE_PATH)
		return
	file.store_string("\n".join(lines))
	file.close()
	print("HeightmapSignature : référence écrite, %d graines." % lines.size())


func compare() -> void:
	if not FileAccess.file_exists(REFERENCE_PATH):
		push_error("HeightmapSignature : aucune référence. Écrire la référence d'abord.")
		return
	var current := _signatures()
	if current.is_empty():
		return
	var file := FileAccess.open(REFERENCE_PATH, FileAccess.READ)
	var reference := file.get_as_text().split("\n", false)
	file.close()

	if reference.size() != current.size():
		push_error("HeightmapSignature : %d graines en référence, %d maintenant — comparer à nombre égal."
			% [reference.size(), current.size()])
		return

	var drifted := 0
	for i in current.size():
		if reference[i] != current[i]:
			drifted += 1
			# La graine est en tête de ligne : elle permet de rejouer le cas.
			push_warning("HeightmapSignature : %s\n  référence %s" % [current[i], reference[i]])
	if drifted == 0:
		print("HeightmapSignature : %d graines identiques à la référence." % current.size())
	else:
		push_error("HeightmapSignature : %d graines sur %d ont changé." % [drifted, current.size()])


## Une ligne par graine. Le tirage se fait en repartant de la graine de la config
## et non d'un compteur arbitraire, pour que la première ligne soit exactement la
## carte que l'éditeur affiche.
func _signatures() -> PackedStringArray:
	if config == null:
		push_error("HeightmapSignature : aucun TerrainGenConfig assigné.")
		return PackedStringArray()

	var probe := config.duplicate()
	var base := config.world_seed
	var lines := PackedStringArray()
	for i in seed_count:
		probe.world_seed = base + i
		var heightmap := HeightmapGenerator.new()
		heightmap.generate(probe)
		lines.append("graine %d  %s" % [probe.world_seed, _digest(heightmap)])
	return lines


## Empreinte SHA-256 de tout ce que le générateur publie. Les octets bruts des
## `Packed*Array` sont hachés tels quels : deux flottants qui ne diffèrent que
## d'un bit donnent deux empreintes différentes, ce qui est le comportement
## voulu — une extraction neutre l'est au bit près.
func _digest(heightmap: HeightmapGenerator) -> String:
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update(heightmap.heights.to_byte_array())
	ctx.update(heightmap.massif_influence.to_byte_array())
	ctx.update(heightmap.clearings.to_byte_array())
	ctx.update(heightmap.river_path.to_byte_array())
	ctx.update(PackedFloat32Array([
		heightmap.water_level,
		heightmap.cave_position.x, heightmap.cave_position.y, heightmap.cave_position.z,
		heightmap.cave_forward.x, heightmap.cave_forward.y, heightmap.cave_forward.z,
	]).to_byte_array())
	return ctx.finish().hex_encode()
