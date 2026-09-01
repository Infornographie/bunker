# STRUCTURE — Projet Bunker
 
Carte de repérage technique : où vit quoi, et qui dépend de quoi. Pas un suivi d'avancement (→ STATE.md) ni un backlog (→ ROADMAP.md) : uniquement la structure.
 
## Conventions
 
- Fichiers `.gd` : snake_case. `class_name` interne en PascalCase si besoin.
- Scènes `.tscn` : snake_case.
- Organisation par feature/domaine, pas par type de fichier.
- `entities/` = tout ce qui est instanciable individuellement, rangé par comportement.
- `world/` = scènes qui assemblent des entités dans un lieu, et le code qui fabrique ce lieu.
- `resources/` = définitions data-driven. Un sous-dossier par type de def (`resources/`, `tools/`, `buildings/`, `recipes/`, `terrain/`, `foliage/`, futur `techs/`), à côté des scripts de définition correspondants.
- `assets/` = ressources brutes tierces. **Le nom d'un dossier dit à quoi la ressource sert dans le jeu, jamais de quel pack elle vient** : la provenance vit dans ATTRIBUTION.md.
- Un même item peut avoir trois fichiers homonymes dans trois dossiers, un par rôle : sa définition (`resources/resources/x.tres`), sa recette (`resources/recipes/x.tres`), sa scène de pickup (`entities/interactable/.../x.tscn`). C'est le cas de `grilled_mushroom`.
- **Aucun texte affichable dans le code ni dans les `.tres`** : uniquement des clés de traduction. Voir § Flux de localisation.
## Autoloads
 
Déclarés dans `project.godot` § `[autoload]` — cette liste doit correspondre exactement :
 
- `SoundManager` → `autoloads/sound_manager.gd` — pool d'`AudioStreamPlayer3D` pour SFX ponctuels positionnés.
- `ResourceRegistry` → `autoloads/resource_registry.gd` — table `ResourceDef` → `PackedScene`, scan auto au boot, sert aussi les icônes.
- `Locale` → `autoloads/locale.gd` — wrapper `TranslationServer`, fallback `en`, bascule debug F10.
`autoloads/icon_generator.gd` vit dans le même dossier mais **n'est pas** un autoload : il est instancié par `ResourceRegistry`.
## Couches de collision
 
- **Couche 5 — « UI 3D »** : cases des panneaux du monde (`PanelSlot`). Vue par le raycast d'interaction, et retirée de trois masques : le `collision_mask` du joueur, `ground_mask` et `overlap_mask` de `BuildModeController`.
## Arborescence
 
```
res://
├── project.godot                        — config moteur, autoloads, input map (→ INPUTS.md), locale fallback
├── autoloads/
│   ├── sound_manager.gd
│   ├── resource_registry.gd            — (autoload) ResourceDef → PackedScene, scan auto au boot
│   ├── locale.gd                       — (autoload) wrapper TranslationServer
│   └── icon_generator.gd               — modèle 3D → Texture2D, un SubViewport jetable par icône (pas un autoload)
├── translations/
│   └── strings.csv                     — source unique des textes affichés (`keys`, `en`, `fr`)
├── assets/
│   ├── nature/                         — Quaternius Stylized Nature MegaKit [Pro+]
│   │   ├── models/                     — glTF + textures
│   │   ├── materials/                  — shaders de feuillage et de vent, matériaux MI_*
│   │   └── meshes/                     — une scène par modèle ; c'est de là que le scatter extrait les meshes
│   ├── sci_fi/                         — Quaternius Modular SciFi MegaKit
│   ├── survival/                       — KayKit Resource Bits (survival) : sac à dos, feu de camp
│   ├── characters/tools/                — KayKit, dix outils en bois (un seul câblé, voir ASSETS.md)
│   └── sounds/                         — non inventorié (contenu à documenter)
├── debug/
│   ├── debug_camera_switch.gd          — bascule cam player ↔ freecam (F7)
│   └── freecam_controller.gd
├── entities/
│   ├── interactable/
│   │   ├── interactable.gd             — base PhysicsBody3D : can_interact(), interact(), get_prompt_key(), receive_resource(), receive_tool_hit()
│   │   ├── choppable.gd                — hérite Interactable : HP, type d'outil, depleted → 3× pickup
│   │   ├── resource_pickup.gd          — hérite Interactable (RigidBody3D), lit ResourceDef
│   │   ├── construction_site.gd / .tscn
│   │   ├── tool_pickup.gd              — outil posé au sol, créé dynamiquement par EquipmentController
│   │   ├── backpack_pickup.gd / .tscn
│   │   ├── panel/                      — panneaux posés dans le monde (voir § Flux des panneaux)
│   │   │   ├── world_panel.gd          — suivi d'ancre, billboard axe Y, contrat de case
│   │   │   ├── panel_slot.gd / .tscn   — case, hérite Interactable
│   │   │   ├── panel_gauge.gd
│   │   │   ├── backpack_panel.gd / .tscn
│   │   │   └── cooking_panel.gd / .tscn
│   │   ├── buildings/
│   │   │   ├── campfire.gd / .tscn
│   │   │   ├── transformation_site.gd
│   │   │   └── flame_light_flicker.gd
│   │   ├── food/grilled_mushroom.tscn
│   │   └── forest/
│   │       ├── mushroom_pickup.tscn
│   │       ├── oak_choppable.tscn
│   │       └── resource_pickup_wood.tscn
│   └── player/
│       ├── player.tscn
│       ├── player_controller.gd        — CharacterBody3D, locomotion, marches auto, sprint + saut
│       ├── action_state_machine.gd     — IDLE / USING_TOOL
│       ├── interaction_controller.gd   — raycast, prompt, arbitre outil vs portage, take_into_hand()
│       ├── carry_controller.gd         — point unique "en main"
│       ├── build_mode_controller.gd    — mode construction (B)
│       ├── equipment_controller.gd     — ceinture + sac à dos, routage ramassage, drop (G)
│       ├── ui_panel_controller.gd      — arbitre des panneaux
│       ├── hud/                        — player_hud, crosshair, hotbar
│       └── tools/tool_controller.gd    — viewmodel 1re personne, swing()
├── resources/
│   ├── resource_def.gd                 — Resource : item (CarryType), name_key
│   ├── tool_def.gd                     — Resource : outil data-driven
│   ├── backpack_data.gd                — Resource : contenu d'un sac
│   ├── building_def.gd                 — Resource : bâtiment (coûts, collision_shape, scènes)
│   ├── resource_cost.gd
│   ├── recipe_def.gd                   — Resource : recette de transformation
│   ├── terrain_gen_config.gd           — (@tool) Resource : réglages de génération + convention de grille (grid_size, cell_count, half_size, chunks_per_side, height_index, world_pos, sample_grid, sample_height, chunk_area, stream_tile_area, stream_tiles_per_side). Porte `layers` et `biomes`
│   ├── foliage_def.gd                  — (@tool) Resource : une essence (id, model, scale_range, random_yaw, min/max_slope_degrees, embed_depth, base_radius, cover_radius, cover_amount, cover_response) — **pas de poids** : il appartient à la composition
│   ├── foliage_weight.gd               — (@tool) Resource : une essence et son poids ici (def, weight)
│   ├── foliage_layer.gd                — (@tool) Resource : une strate (id, spacing, jitter, streamed, stand_noise, stand_blend, clearing_response, clearing_uniform) — la grille, pas le contenu
│   ├── foliage_patch.gd                — (@tool) Resource : une tache de composition (id, noise, threshold, min/max_slope_degrees, density, entries)
│   ├── biome_def.gd                    — (@tool) Resource : un biome (id, massif_range, massif_falloff, edge_noise, edge_amount, weight_floor, strata) + stratum_for(layer)
│   ├── biome_stratum.gd                — (@tool) Resource : ce qu'un biome fait pousser dans une strate (layer_id, patches, entries)
│   │   → la couleur, le port et l'emploi de chaque famille du pack sont dans ASSETS.md
│   ├── resources/                      — instances ResourceDef (wood, mushroom, grilled_mushroom)
│   ├── recipes/                        — instances RecipeDef
│   ├── tools/wooden_axe.tres
│   ├── buildings/                      — campfire.tres, campfire_shape.tres
│   ├── terrain/default_terrain.tres    — instance TerrainGenConfig ; porte en sous-ressources les FastNoiseLite, le ShaderMaterial du sol et le matériau de l'eau
│   ├── foliage/                        — instances FoliageDef, une par essence
│   ├── foliage_layers/                 — instances FoliageLayer : canopy, understory, shrub, ground
│   ├── foliage_patches/                — instances FoliagePatch : scree, grass_bed, mushroom_spot, flower_violet/white/yellow/pink
│   └── biomes/                         — instances BiomeDef : forest_light, conifer_highland
│       → FoliageWeight et BiomeStratum n'ont pas de dossier : ce sont des sous-ressources écrites dans le .tres du biome
└── world/
	├── bunker/bunker_exterior_test.tscn — scène morte-née : bunker bâti à la main directement dedans, jamais repris ailleurs, jamais de partie intérieure. À supprimer — le bunker est intégralement à refaire (→ ASSETS.md § Sci-fi)
	├── terrain/
	│   ├── heightmap_generator.gd      — (@tool) RefCounted : massif, relief, eau, clairières, rivière. Publie heights / massif_influence / cave_position / cave_forward / water_level / clearings / river_path
	│   ├── biome_map.gd             — (@tool) RefCounted : generate(cfg, influence) → weights, un PackedFloat32Array normalisé par biome
	│   ├── terrain_mesh_builder.gd     — (@tool) RefCounted statique : build_chunk() → StaticBody3D (mesh + collision trimesh)
	│   ├── foliage_scatter.gd          — (@tool) RefCounted : scatter() sème les strates permanentes, stream_tile(tx, tz) les strates streamées ; expose placed_count, placed_per_layer, placed_per_biome, occupancy, chunk_nodes
	│   ├── scatter_occupancy.gd        — (@tool) RefCounted : is_blocked(point, radius), cover_at(point), mark(point, base_radius, cover_radius, cover_amount)
	│   ├── foliage_proximity.gd        — (@tool) Node : setup(scatter, cfg, space, sun) ; coupe cast_shadow par chunk et sème/libère les tuiles streamées sous budget de temps (update_interval, stream_budget_ms)
	│   ├── terrain_controller.gd       — (@tool) Node3D : orchestrateur, boutons Régénérer/Effacer, crée Chunks / Water / Foliage (+ Proximity) / CaveSite, publie heights ; expose config et sun
	│   └── terrain.gdshader            — sol coloré par altitude, pente et bruit de teinte
	└── forest/
		├── forest_test.tscn            — scène de test historique (sol plat) — seule scène où les mécaniques de jeu sont montées
		└── forest_scatter.gd           — scatter du Jalon 1, périmé, supprimé avec forest_test.tscn
```
## Dépendances transversales clés
 
### Flux de génération du terrain
- Sens de la dépendance : `TerrainController` (seul nœud de la scène) appelle `HeightmapGenerator.generate(config)`, puis `BiomeMap.generate(config, massif_influence)`, puis `FoliageScatter.scatter(...)`, puis `TerrainMeshBuilder.build_chunk(...)` par chunk. Les trois sont des `RefCounted` sans état persistant et ne connaissent ni la scène ni le contrôleur.
- **`TerrainGenConfig` est la source unique de la convention de grille** : `height_index()`, `world_pos()` et `sample_grid()` ne sont réimplémentés nulle part. `sample_height()` est un cas particulier de `sample_grid()` — une heightmap est une grandeur par sommet comme une autre, et c'est ce qui permet de lire les poids de biome au point sans écrire une seconde interpolation. Générateur et scatter les appellent, y compris dans leurs boucles chaudes.
- Ordre dans `HeightmapGenerator.generate()`, et il compte : tirage du massif → relief → niveau de l'eau → clairières → rivière. La rivière se trace sur un relief complet ; la vallée est creusée **avant** parce qu'elle est ce qui empêche la descente de gradient de s'échouer.
- **Tout le relief se calcule dans le repère du massif** (`along` le long de l'axe, `side` en travers). C'est ce qui permet de tirer l'orientation au hasard : vallée, pente d'écoulement et rivière s'alignent dessus sans rien savoir de l'angle.
- Contrainte de placement : la bouche de grotte est à l'origine du monde, et l'axe du massif est **résolu** pour que le pied de sa falaise y tombe. Il n'existe aucun réglage de position de massif.
- Le générateur publie ce que la suite doit savoir : `heights`, `water_level`, `clearings` (centre + rayon), `river_path`, `cave_position`/`cave_forward`. Le contrôleur republie `heights` pour la scène.
- **Les nœuds générés n'ont pas d'owner** : jamais sérialisés dans le `.tscn`, jamais versionnés. Le terrain se régénère, il ne se sauvegarde pas.
- Les normales des chunks sont calculées par différences centrées sur le **tableau global** : deux chunks voisins lisent les mêmes sommets et se raccordent sans couture, sans code de recollement.
- ⚠️ Toute la chaîne est `@tool`. Le `@tool` ne s'hérite pas : un script non-`@tool` instancié par un script `@tool` devient une coquille sans méthodes dans l'éditeur.
### Flux des biomes
- `HeightmapGenerator` publie `massif_influence`, l'influence du massif par sommet : 1 sur l'axe, 0 hors du relief. Elle est calculée pour le relief de toute façon, la publier ne coûte qu'une écriture.
- **Un étage se déclare sur cette influence, jamais sur une altitude.** La carte descend de `drainage_drop` d'un bout à l'autre : une plaine plate y gagne quarante mètres, et un seuil en mètres au-dessus de l'eau fait apparaître un étage montagnard sur une moitié de plaine — c'est arrivé, et ça se voyait comme un mélange 50-50 sur un seul côté de la carte.
- Repères d'influence sur la carte : **0** en plaine, **~0,27** à la bouche de grotte, **~0,57** en haut de falaise, **1** sur l'axe des crêtes.
- `BiomeMap.weights` = un `PackedFloat32Array` par biome, normalisés à 1 par sommet. **Jamais d'identifiant de biome** : une carte qui rangerait chaque cellule dans un biome imposerait du code de frontière, et ce code se verrait — les limites suivraient la grille.
- **Le mélange se fait au tirage, pas sur les poids d'essences.** Le semis tire quel biome décide de ce candidat, puis déroule sa roue inchangée. Sur la lisière, les deux compositions s'entremêlent arbre par arbre. Mélanger les poids aurait donné une moyenne — un arbre à mi-chemin entre deux biomes, qui ne pousse dans aucun — et aurait imposé de reconstruire la roue à chaque candidat.
- Le tirage du biome est un `randf()` et non un bruit : un bruit ferait des plaques aux bords nets, soit exactement la frontière que la carte de poids sert à ne pas avoir.
- **Une essence ne porte pas son poids** : `FoliageWeight` le porte, dans le `BiomeStratum` qui l'emploie. Une essence décrit ce qu'elle est, un biome ce qui pousse là — la même plante pèse 4 chez les conifères et 0,6 en forêt claire.
- Les `FoliagePatch` appartiennent au `BiomeStratum`, pas à la strate : un coin à champignons peut n'exister que sous les conifères sans une ligne de code.
- Un biome sans `BiomeStratum` pour une couche donnée n'y sème rien. Ce n'est pas une erreur : une berge sans entrée `canopy` est une berge dégagée.

### Flux de semis (végétation)
- `FoliageScatter.scatter(cfg, heights, clearings, river, water_level, biomes)` construit un `Node3D` par chunk, contenant un `MultiMeshInstance3D` par essence **et par partie de modèle** — les modèles du pack ne sont pas toujours d'un seul tenant, et chaque partie garde son décalage local.
- Les meshes sont **extraits** de la scène du modèle, une fois par essence et mis en cache. Les matériaux posés en surcharge de surface sur le `MeshInstance3D` sont recopiés dans le mesh : un multimesh ne connaît que les matériaux du mesh lui-même.
- Répartition en grille jitterée globale, parcourue par chunk. **Les deux bornes de la grille s'arrondissent au supérieur**, et la fin d'un chunk est la même expression que le début du suivant — sinon une colonne de plantation se perd à chaque frontière et la grille se voit dans la canopée.
- Rejets, dans cet ordre : sous l'eau, dans une clairière (probabilité croissante sur la distance d'adoucissement — la lisière n'est pas dessinée, elle est le dégradé), dans le lit de la rivière, puis pente trop forte pour l'essence tirée.
- **Le choix d'essence se fait au point, jamais au chunk.** Chaque essence a son champ de bruit propre ; son poids local est son poids propre modulé par ce champ élevé à `stand_sharpness`. Une sélection par chunk produirait une couture rectiligne à chaque frontière.
- Le gain de performance vient de la même mécanique : au cœur d'un peuplement, les autres essences ne sont jamais tirées, donc leur multimesh n'existe pas dans ce chunk.
- `FoliageScatter.chunk_nodes` (`Vector2i` → `Node3D`) est le point d'entrée de `FoliageProximity` vers les chunks. Ni le nom du nœud ni la boîte englobante du multimesh ne sont une seconde source de vérité : le premier se périme au renommage, la seconde n'est pas calculée à la sortie du semis.
- **Les strates se sèment l'une après l'autre, chacune sur toute la carte**, parce qu'une strate lit l'occupation laissée par les précédentes et qu'un arbre déborde chez le chunk voisin.
- **Une strate `streamed` lit l'occupation permanente et n'y écrit jamais.** Elle tient la sienne, locale à la tuile et jetée avec elle — sans quoi un aller-retour du joueur laisserait le sol marqué par une herbe disparue.
- **La tuile de streaming n'est pas le chunk de terrain** (`stream_tile_cells`, 8 cellules = 24 m, contre 32 pour un chunk). Le chunk porte le culling et les ombres ; la tuile porte le semis, dont le coût va comme le carré du côté et doit tenir dans une frame. Confondre les deux coûtait 400 ms par semis.
- Les tuiles streamées se parentent à la **racine du feuillage**, pas au chunk : elles ont leur propre grain, et le chunk n'a rien à en savoir.
- **Le pré-filtrage des clairières et des segments de rivière par aire n'est pas une optimisation, c'est la condition du semis** : sans lui chaque candidat teste toutes les clairières de la carte.
- L'essence se tire sur une **roue** : un champ de bruit désigne une position, chaque essence occupe un secteur proportionnel à son poids. Un seul appel de bruit par candidat quel que soit leur nombre.
- `FoliageProximity` tient deux listes à deux grains : les chunks pour l'ombre, les tuiles pour le semis. Le recensement (`update_interval`) dit quelles tuiles doivent exister sans en semer aucune ; le semis consomme la file à chaque frame dans `stream_budget_ms`. **Le budget est en millisecondes et pas en tuiles** : compté en tuiles il redevient faux dès qu'on change leur taille, un espacement ou de machine.
- La file est triée par distance, le plus proche semé en premier : l'herbe pousse sous les pieds du joueur avant de pousser au loin.
- `FoliageProximity` est le point unique où le feuillage réagit à la distance. Tout s'y calcule **dans le repère du nœud de feuillage**, celui des emprises publiées — le nœud de terrain peut être tourné et déplacé dans sa scène.
- `foliage_view_distance` et `foliage_fade_margin` sont posés sur chaque `MultiMeshInstance3D`. Ils se règlent **de pair avec le brouillard de profondeur** du `WorldEnvironment` : c'est la brume qui doit masquer la coupure.
### Flux d'action (swing outil)
- `ActionStateMachine.use_tool_on(target, on_impact, reach_distance)` appelle `ToolController.swing()` et écoute son signal `swing_impact` en retour. La SM pilote le controller, jamais l'inverse.
- Au `swing_impact`, la SM exécute le `Callable` fourni par l'appelant, uniquement si la cible est encore valide.
- `Choppable.receive_tool_hit()` : vérifie le type d'outil, décrémente HP, émet `depleted` → spawn 3 `ResourcePickup`, hook `chop_sound` → `SoundManager`.
### Flux d'interaction / portage
- `InteractionController` : raycast vers un `Interactable`, gère le prompt (fix `tree_exiting` sur la cible). Le prompt vient de `Interactable.get_prompt_key(interactor)`, surchargeable — c'est ce qui rend le verbe contextuel.
- Ordre des branches sur E, et il compte : objet lourd en main → livraison ou dépose ; petit objet en poche active → livraison ; sinon `interact()`. Une cible qui **refuse** rend la main à la branche suivante au lieu de faire tomber l'objet.
- `CarryController` ↔ `ResourcePickup` : le pickup lit son `ResourceDef.CarryType` pour valider le portage main.
- `InteractionController` masque/remontre l'outil via `ToolController.set_tool_visible()` quand les mains sont occupées.
- `PlayerController` lit `CarryController.is_carrying()` pour brider sprint et saut — seule dépendance locomotion → portage.
- `Campfire.receive_resource()` route le combustible vers lui-même et le reste vers `TransformationSite.try_insert()`. Sortie en `ResourcePickup` via `ResourceRegistry`.
### Flux des panneaux
- Un panneau est un objet du monde : `WorldPanel` (Node3D) suit son ancre et pivote sur l'axe Y. Ses cases sont des `PanelSlot`, qui héritent d'`Interactable`.
- **Conséquence structurante : il n'existe aucun système de visée, de survol ni de transfert propre à l'UI.** Le réticule est le pointeur, le raycast touche les cases comme il touche un rondin, et E prend, pose ou active.
- `UIPanelController.open_panel(panel, anchor)` est le seul chemin d'ouverture. Il refuse si un mode exclusif tourne ou si l'`ActionStateMachine` n'est pas `IDLE`.
- `InteractionController.open_object_panel(source, panel_scene)` **bascule**. Le panneau est instancié à l'ouverture, branché par `bind()`, détruit à la fermeture — un exemplaire par ancre.
- Le panneau est enfant de la **scène**, pas de son ancre : les assets du projet ont des échelles arbitraires.
- `exclusive_modes: Array[Node]` — duck typing (`is_active()`), sans citer aucun type : c'est ce qui évite le cycle de `class_name`.
- Contrat de case, implémenté par le panneau propriétaire : `slot_content()`, `slot_accepts()`, `slot_can_take()`, `slot_take()`, `slot_put()`, plus `slot_action_key()` / `slot_activate()`. La case porte un `payload` opaque et ne décide de rien.
### Flux de localisation
- `translations/strings.csv` = source unique de tout texte affiché. Les lignes de titre ont une **première colonne vide** : Godot les ignore à l'import.
- Convention de clés : `namespace.section.key`.
- **Le `tr()` ne se fait qu'aux points d'affichage — trois dans tout le projet** :
  - `PlayerHud.show_prompt()`
  - `Hotbar._slot_label()`
  - `PanelSlot._refresh_display()`
  Tout nouveau `tr()` ailleurs signale une string qui aurait dû transiter par une clé.
- Les cases de recette n'affichent **aucun texte** : elles montrent l'icône du plat produit, ce qui évite un quatrième point de traduction.
- ⚠️ Les clés de cache d'icônes sont bâties sur les `id`, **jamais** sur un nom affiché.
### Flux de construction
- `BuildModeController` (B) : lit les `BuildingDef` disponibles, instancie le blueprint, molette pour tourner, `Shift` désactive le snap, check collision via `BuildingDef.collision_shape`.
- Placement validé → spawn d'un `ConstructionSite`, qui lit `BuildingDef.costs`, réceptionne les livraisons, et à complétion spawn la `built_scene`.
- **Le mode construction n'est pas un état de l'`ActionStateMachine`.** Son exclusivité passe par `UIPanelController.can_enter_exclusive_mode()`.
### Contraintes d'ordre
- `HeightmapGenerator` avant `TerrainMeshBuilder` et `FoliageScatter` : les deux lisent le tableau de hauteurs terminé.
- Le scatter doit tourner **après** le terrain et **avant** le bake de `NavigationRegion3D`.
- La carte d'ouverture (passe B2) se calcule **entre** la strate canopée et la strate sol : elle dépend de ce que la canopée a effectivement posé.
### Flux d'équipement
- `EquipmentController` : ceinture 2 slots (`ToolDef`) + ref `BackpackData`. Pilote `ToolController.equip()`/`unequip()` selon le slot actif.
- Drop (G) : spawn un `ToolPickup` dynamique ; `interact()` le renvoie en ceinture via `try_store_tool()`.
- Priorité affichage : Main > Hotbar actif. Hotbar dimmed quand mains occupées.
- `BackpackData` vit sur l'objet sac, pas sur le joueur — prêt pour des pawns avec leur propre sac.