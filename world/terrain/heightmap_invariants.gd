@tool
class_name HeightmapInvariants
extends Node
## Vérifie sur N graines que la carte reste *jouable*, quelle que soit la
## composition tirée.
##
## **Ce n'est pas `HeightmapSignature`, et les deux ne se remplacent pas.**
## L'empreinte dit « la carte a changé » : elle sert pendant un remaniement qui
## ne doit rien changer, et devient muette dès qu'on ajoute une feature, puisque
## alors une carte qui change est le résultat voulu. Celui-ci dit « la carte est
## valide » : il reste vrai pour toujours, et c'est lui qui attrape la graine sur
## mille où une composition légitime produit un terrain injouable.
##
## C'est ce qui remplace les tests unitaires ici. Un générateur procédural n'a
## pas de sortie attendue à comparer — il a des **promesses** : on peut sortir du
## bunker, l'eau s'écoule quelque part, la grotte n'est pas noyée. Une promesse
## tenue sur douze graines et rompue sur la treizième est un bug qu'aucune
## capture ne montre.
##
## Chaque invariant est écrit à partir d'un cas réel, jamais par précaution.

@export var config: TerrainGenConfig
## Graines essayées, à partir de celle de la config incluse. Plus il y en a,
## plus on attrape de cas rares — c'est le seul réglage qui compte ici.
@export_range(1, 512) var seed_count: int = 48
## Écart entre deux graines essayées.
##
## À 1, on essaie des graines consécutives — et des graines voisines donnent des
## massifs voisins, donc **la même configuration vue sous des angles proches**.
## C'est ce qui a fait remonter deux fois le même cas (2032 et 2036). Un pas
## premier couvre bien plus de compositions pour le même temps de calcul.
@export var seed_stride: int = 997

@export_group("Tolérances")
## Écart d'altitude sous lequel un point de la clairière du bunker compte comme
## constructible, en mètres.
@export var bunker_flatness_tolerance: float = 1.5
## Part du disque qui doit être constructible.
##
## Réglé sur mesure, pas à l'intuition : sur 48 graines, le pire cas observé est
## 49 %. Le seuil est posé juste en dessous — assez bas pour ne pas crier sur une
## carte normale, assez haut pour qu'une régression le déclenche.
##
## **Pas 100 %, et ce n'est pas une tolérance molle.** La bouche de grotte est au
## pied de la falaise : la moitié du disque est le versant qui monte, et
## `flatten_disc` renonce là où le terrain s'écarte trop de la cible — sans quoi
## le disque taillerait une marche dans le relief qui le domine. Exiger un disque
## entièrement plan, c'est mesurer la hauteur de la montagne : les 48 premières
## graines essayées le violaient toutes, avec 27 à 78 m d'écart. La promesse
## tenable est qu'il reste de quoi bâtir, pas que la montagne s'efface.
@export_range(0.1, 1.0) var bunker_buildable_share: float = 0.4
## Marge exigée entre la bouche de grotte et la surface de l'eau, en mètres.
@export var cave_above_water_margin: float = 2.0
## Rayon de l'anneau sondé autour d'une arrivée de rivière pour dire si elle est
## en cuvette. Trop petit, il reste dans le lit déjà creusé et voit une cuvette
## partout ; trop grand, il enjambe la barrière qu'on cherche à constater.
@export var _basin_probe_radius: float = 60.0

@export_tool_button("Vérifier les invariants") var check_action: Callable = check


func check() -> void:
	if config == null:
		push_error("HeightmapInvariants : aucun TerrainGenConfig assigné.")
		return

	# `duplicate()` renvoie un Resource : typer, sinon tout ce qu'on en tire est
	# un Variant et l'inférence échoue au premier appel de méthode.
	var probe: TerrainGenConfig = config.duplicate()
	var base := config.world_seed
	var failed := 0
	# Marge la plus faible rencontrée, reportée même quand tout passe : un
	# invariant qui tient de justesse et un invariant confortable demandent des
	# décisions opposées, et le log ne les distingue pas sans ce chiffre.
	var worst_buildable := 1.0
	for i in seed_count:
		probe.world_seed = base + i * seed_stride
		var heightmap := HeightmapGenerator.new()
		heightmap.generate(probe)
		worst_buildable = minf(worst_buildable, _buildable_share(probe, heightmap.heights, probe.bunker_radius))
		var breaches := _breaches(probe, heightmap)
		if not breaches.is_empty():
			failed += 1
			push_warning("HeightmapInvariants : graine %d — %s" % [probe.world_seed, ", ".join(breaches)])

	print("HeightmapInvariants : bunker constructible au pire à %.0f %% (seuil %.0f %%)."
		% [worst_buildable * 100.0, bunker_buildable_share * 100.0])
	if failed == 0:
		print("HeightmapInvariants : %d graines, tous les invariants tenus." % seed_count)
	else:
		push_error("HeightmapInvariants : %d graines sur %d violent au moins un invariant." % [failed, seed_count])


## Invariants violés par cette carte, en clair. Un message par promesse rompue,
## avec la mesure qui l'a rompue : « ça a échoué » sans le chiffre oblige à
## réinstrumenter pour diagnostiquer.
func _breaches(cfg: TerrainGenConfig, heightmap: HeightmapGenerator) -> PackedStringArray:
	var breaches := PackedStringArray()

	# L'eau doit sortir de la carte. Un tracé qui s'arrête avant le bord est
	# acceptable **s'il finit noyé** — le lac prend alors le relais. Observé à
	# quatre éperons : le creusement s'arrêtait court, mais sous le niveau du
	# lac, donc sans fossé borgne visible. C'est cette nuance qui est l'invariant,
	# pas « le tracé atteint le bord ».
	if heightmap.river_path.size() < 2:
		breaches.append("rivière non tracée")
	else:
		var last := heightmap.river_path[heightmap.river_path.size() - 1]
		var at_border := maxf(absf(last.x), absf(last.y)) >= cfg.half_size() - cfg.river_step
		if not at_border and cfg.sample_height(heightmap.heights, last) > heightmap.water_level:
			# La longueur du tracé dit *pourquoi* il s'arrête : au plafond de pas,
			# il tourne en rond ; bien en deçà, il s'est arrêté pour une autre
			# raison. Deux causes, deux correctifs.
			breaches.append("rivière s'arrête à sec en (%.0f, %.0f) — %s"
				% [last.x, last.y, _why_stuck(cfg, heightmap, last)])

	# La bouche de grotte est l'entrée du bunker : noyée, la partie ne commence
	# pas. Elle est à l'origine, donc c'est le niveau de l'eau qui peut monter
	# jusqu'à elle, pas elle qui peut descendre.
	var cave_clearance := heightmap.cave_position.y - heightmap.water_level
	if cave_clearance < cave_above_water_margin:
		breaches.append("grotte à %.1f m au-dessus de l'eau" % cave_clearance)

	# La clairière du bunker doit offrir de quoi bâtir. Le chiffre est reporté
	# dans le message même quand il passe de justesse : c'est ce qui permet de
	# régler le seuil sur des mesures plutôt que sur une intuition.
	var buildable := _buildable_share(cfg, heightmap.heights, cfg.bunker_radius)
	if buildable < bunker_buildable_share:
		breaches.append("bunker constructible à %.0f %%" % (buildable * 100.0))

	return breaches


## Part des points d'un disque centré sur l'origine qui sont à portée de
## l'altitude du centre — donc de quoi poser un bâtiment de plain-pied.
func _buildable_share(cfg: TerrainGenConfig, heights: PackedFloat32Array, radius: float) -> float:
	var centre_height := cfg.sample_height(heights, Vector2.ZERO)
	var n := cfg.grid_size()
	var half := cfg.half_size()
	var i0 := clampi(int(floor((half - radius) / cfg.cell_size)), 0, n - 1)
	var i1 := clampi(int(ceil((half + radius) / cfg.cell_size)), 0, n - 1)

	var inside := 0
	var flat := 0
	for iz in range(i0, i1 + 1):
		for ix in range(i0, i1 + 1):
			if cfg.world_pos(ix, iz).length() > radius:
				continue
			inside += 1
			if absf(heights[cfg.height_index(ix, iz)] - centre_height) <= bunker_flatness_tolerance:
				flat += 1
	if inside == 0:
		push_warning("HeightmapInvariants : disque du bunker vide — rayon plus petit qu'une cellule ?")
		return 1.0
	return float(flat) / float(inside)


## Pourquoi le tracé s'arrête là. Trois mesures qui départagent les causes, et
## rien de plus : une hypothèse de plus coûte moins cher qu'une capture, mais
## bien plus cher qu'un chiffre.
##
## **Le relief est mesuré sur une carte au creusement neutralisé**, jamais sur la
## carte finale. Un tracé qui tourne en rond creuse 3,6 km de lit dans un
## mouchoir de poche et se fabrique un plateau parfaitement plat : mesuré après
## coup, tout blocage ressemble à un terrain plat, parce que le blocage a effacé
## le relief qui l'a causé. La seconde génération coûte quelques secondes et ne
## se paie que sur les graines fautives.
##
## - **cuvette** : le point le plus bas d'un anneau autour de l'arrivée est plus
##   haut que l'arrivée. Il n'existe alors aucune direction descendante, et une
##   descente de gradient ne peut que tourner. C'est un fait de terrain, pas une
##   supposition sur ce qui l'a creusée.
## - **clairière** : l'arrivée tombe dans un disque aplani. `flatten_disc` ramène
##   le terrain à la hauteur du centre du disque et peut donc creuser une fosse
##   là où il mord sur une pente — une trouée voulue devient un piège.
## - **hauteur** : de combien l'arrivée domine l'eau, pour savoir si le fossé est
##   un vrai problème ou un détail noyé.
func _why_stuck(cfg: TerrainGenConfig, heightmap: HeightmapGenerator, last: Vector2) -> String:
	var facts := PackedStringArray()

	facts.append("%.1f m au-dessus de l'eau"
		% (cfg.sample_height(heightmap.heights, last) - heightmap.water_level))

	# Même graine, creusement réduit à rien : le relief que le tracé a rencontré.
	var bare: TerrainGenConfig = cfg.duplicate()
	bare.river_width_range = Vector2(0.01, 0.01)
	bare.river_depth_range = Vector2.ZERO
	bare.river_bank = 0.01
	bare.river_island_chance = 0.0
	var uncarved := HeightmapGenerator.new()
	uncarved.generate(bare)

	var here := bare.sample_height(uncarved.heights, last)
	var rim := INF
	for i in 24:
		var angle := TAU * float(i) / 24.0
		var probe := last + Vector2(cos(angle), sin(angle)) * _basin_probe_radius
		rim = minf(rim, bare.sample_height(uncarved.heights, probe))
	if rim > here:
		facts.append("cuvette fermée (bord bas à +%.1f m)" % (rim - here))
	else:
		facts.append("issue descendante à %.1f m" % (rim - here))

	for i in heightmap.clearings.size():
		var clearing := heightmap.clearings[i]
		var centre := Vector2(clearing.x, clearing.y)
		if last.distance_to(centre) <= clearing.z + cfg.clearing_falloff:
			facts.append("dans la clairière %d (rayon %.0f m)" % [i, clearing.z])
			break

	return ", ".join(facts)
