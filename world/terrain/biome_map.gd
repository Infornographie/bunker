@tool
class_name BiomeMap
extends RefCounted
## Poids de biome par sommet de la grille.
##
## **Des poids, jamais un identifiant.** Une carte qui rangerait chaque cellule
## dans *un* biome obligerait à écrire du code de frontière, et ce code se
## verrait : les limites suivraient la grille. Des poids qui se croisent donnent
## la lisière gratuitement, et c'est le semis qui tranche, point par point.
##
## **L'étage se lit sur l'influence du massif, jamais sur l'altitude.** La carte
## descend de `drainage_drop` d'un bout à l'autre : une plaine parfaitement
## plate y gagne quarante mètres, et un seuil exprimé en mètres au-dessus de
## l'eau bascule donc d'un côté de la carte sans qu'aucun relief n'apparaisse.
## C'est l'erreur de la première version, et elle se voyait comme un mélange à
## parts égales sur une moitié de la plaine. L'influence vaut 1 sur l'axe du
## massif et 0 partout ailleurs, quelle que soit la pente générale.
##
## Résolution : celle de la heightmap, dont l'influence partage la grille. Le
## semis échantillonne ces tableaux avec exactement la fonction qui lit les
## hauteurs (`TerrainGenConfig.sample_grid()`) — pas de seconde convention.

## Décalage de graine entre deux biomes : sans lui, deux limites déformées par
## le même bruit ondulent en phase et la transition redevient une ligne.
const _SEED_BIOME := 8191

## Un tableau de poids par biome, dans l'ordre de `TerrainGenConfig.biomes`.
## Normalisés : en chaque sommet, leur somme vaut 1.
var weights: Array[PackedFloat32Array] = []


## Calcule la carte à partir de l'influence de massif publiée par le générateur
## de relief. Vide si la config ne déclare aucun biome — c'est au semis de dire
## que rien ne poussera, pas à la carte de l'inventer.
func generate(cfg: TerrainGenConfig, influence: PackedFloat32Array) -> void:
	weights.clear()
	var count := cfg.biomes.size()
	if count == 0:
		return

	var n := cfg.grid_size()
	var cells := n * n

	# Poids bruts, un tableau par biome. Chaque tableau est rempli dans une
	# variable locale puis rangé : un `PackedFloat32Array` est une valeur à
	# copie sur écriture, et l'écrire à travers son conteneur est le genre de
	# détour qui ne lève rien et ne garde rien.
	var raw: Array[PackedFloat32Array] = []
	for i in count:
		var field := PackedFloat32Array()
		field.resize(cells)
		var biome: BiomeDef = cfg.biomes[i]
		if biome == null:
			push_warning("BiomeMap : biome nul en position %d, ignoré." % i)
			raw.append(field)
			continue
		var noise := _seeded(cfg, biome, i)
		for iz in n:
			for ix in n:
				var index := cfg.height_index(ix, iz)
				var level := influence[index]
				if noise != null:
					level += noise.get_noise_2dv(cfg.world_pos(ix, iz)) * biome.edge_amount
				field[index] = _band(biome, level)
		raw.append(field)

	var totals := PackedFloat32Array()
	totals.resize(cells)
	for field in raw:
		for c in cells:
			totals[c] += field[c]

	for i in count:
		var field := raw[i]
		for c in cells:
			if totals[c] > 0.0:
				field[c] = field[c] / totals[c]
			else:
				# Aucun biome ne revendique ce point : le premier le prend,
				# plutôt que d'y laisser un trou où rien ne pousserait.
				field[c] = 1.0 if i == 0 else 0.0
		weights.append(field)


## Appartenance d'un point à l'étage du biome, de 0 à 1. Deux `smoothstep` dos à
## dos : l'un ouvre la bande, l'autre la referme. Le plancher passe par-dessus,
## ce qui donne à un biome de fond de carte une présence partout.
func _band(biome: BiomeDef, level: float) -> float:
	var low := biome.massif_range.x
	var high := biome.massif_range.y
	# Un falloff nul ferait un `smoothstep` à bornes égales, dont le résultat
	# est une marche — exactement ce que la bande sert à éviter.
	var falloff := maxf(biome.massif_falloff, 0.001)
	var rise := smoothstep(low - falloff, low, level)
	var fall := 1.0 - smoothstep(high, high + falloff, level)
	return maxf(rise * fall, biome.weight_floor)


## Copie du bruit de lisière d'un biome, resemée. `null` quand le biome n'en a
## pas ou n'en veut pas : le semis d'un bruit inutilisé se paie par sommet.
func _seeded(cfg: TerrainGenConfig, biome: BiomeDef, index: int) -> FastNoiseLite:
	if biome.edge_noise == null or biome.edge_amount <= 0.0:
		return null
	var noise: FastNoiseLite = biome.edge_noise.duplicate()
	noise.seed = cfg.world_seed + _SEED_BIOME * (index + 1)
	return noise
