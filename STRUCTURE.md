# STRUCTURE — Projet Bunker
 
Carte de repérage technique : où vit quoi, et qui dépend de quoi. Pas un suivi d'avancement (→ STATE.md) ni un backlog (→ ROADMAP.md) : uniquement la structure.
 
## Conventions
 
- Fichiers `.gd` : snake_case (convention officielle Godot). `class_name` interne en PascalCase si besoin.
- Scènes `.tscn` : snake_case.
- Organisation par feature/domaine, pas par type de fichier (scène et script d'une même feature côte à côte).
- `entities/` = tout ce qui est instanciable individuellement (script de base + scènes concrètes qui en héritent), rangé par comportement.
- `world/` = scènes qui assemblent des entités dans un lieu (le niveau lui-même), et le code qui fabrique ce lieu.
- `resources/` = définitions data-driven. Un sous-dossier par type de def (`resources/`, `tools/`, `buildings/`, `recipes/`, `terrain/`, futur `techs/`...), à côté des scripts `*_def.gd` correspondants.
- `assets/` = ressources brutes tierces (FBX, textures, audio) + quelques scènes wrapper Godot quand l'asset importé demande un pivot correctif (cf. `wooden_axe_grip.tscn`).
- Un même item peut avoir trois fichiers homonymes dans trois dossiers distincts, un par rôle : sa définition (`resources/resources/x.tres`), sa recette de production (`resources/recipes/x.tres`), sa scène de pickup (`entities/interactable/.../x.tscn`). C'est le cas de `grilled_mushroom`.
- **Aucun texte affichable dans le code ni dans les `.tres`** : uniquement des clés de traduction (`name_key`, `prompt_key`). Voir § Flux de localisation.
## Autoloads (globaux, accessibles partout sans référence)
 
Déclarés dans `project.godot` § `[autoload]` — cette liste doit correspondre exactement :
 
- `SoundManager` → `autoloads/sound_manager.gd` — pool d'`AudioStreamPlayer3D` réutilisables pour SFX ponctuels positionnés.
- `ResourceRegistry` → `autoloads/resource_registry.gd` — table `ResourceDef` → `PackedScene`, scan auto au boot, sert aussi les icônes.
- `Locale` → `autoloads/locale.gd` — wrapper `TranslationServer` : `get_locale()`, `set_locale()`, signal `locale_changed`, fallback `en`. Porte aussi sa bascule debug (F10).
`autoloads/icon_generator.gd` vit dans le même dossier mais **n'est pas** un autoload : il est instancié par `ResourceRegistry`.
## Couches de collision
 
- **Couche 5 — « UI 3D »** : cases des panneaux du monde (`PanelSlot`). Vue par le raycast d'interaction (qui n'a pas de masque), et retirée de trois masques : le `collision_mask` du `CharacterBody3D` joueur, `ground_mask` et `overlap_mask` de `BuildModeController`. Sans ça on se cogne dans ses propres cases et on pose des bâtiments dessus.
## Arborescence
 
```
res://
├── .editorconfig, .gitattributes, .gitignore
├── project.godot                        — config moteur, autoloads, input map (→ INPUTS.md), locale fallback
├── icon.svg
├── autoloads/
│   ├── sound_manager.gd                — pool d'AudioStreamPlayer3D, SFX positionnés
│   ├── resource_registry.gd            — (autoload) table ResourceDef → PackedScene, scan auto de entities/interactable/ au boot, sert aussi les icônes
│   ├── locale.gd                       — (autoload) wrapper TranslationServer, bascule debug EN ↔ FR (F10)
│   └── icon_generator.gd               — rendu d'un modèle 3D → Texture2D, un SubViewport jetable par icône, cache par clé, instancié par ResourceRegistry (pas un autoload)
├── translations/
│   └── strings.csv                     — source unique des textes affichés (colonnes `keys`, `en`, `fr`) ; Godot compile en .translation à l'import
├── debug/
│   ├── debug_camera_switch.gd          — bascule cam player ↔ freecam (F7)
│   └── freecam_controller.gd           — caméra libre noclip
├── entities/
│   ├── interactable/
│   │   ├── interactable.gd             — base PhysicsBody3D : can_interact(), interact(), get_prompt_key(), receive_resource(), receive_tool_hit()
│   │   ├── choppable.gd                — hérite Interactable : HP, type d'outil, depleted → 3× pickup
│   │   ├── resource_pickup.gd          — hérite Interactable (RigidBody3D) : objet ramassable, lit ResourceDef
│   │   ├── construction_site.gd        — hérite Interactable : blueprint posé, réceptionne les livraisons
│   │   ├── construction_site.tscn
│   │   ├── tool_pickup.gd              — outil posé au sol (Interactable, créé dynamiquement par EquipmentController)
│   │   ├── backpack_pickup.gd          — sac à dos dans le monde, porte le BackpackData et sa panel_scene, snap au sol au drop
│   │   ├── backpack_pickup.tscn
│   │   ├── panel/                      — panneaux posés dans le monde (voir § Flux des panneaux)
│   │   │   ├── world_panel.gd          — base : suivi de l'ancre, billboard axe Y, ouverture/fermeture, contrat de case
│   │   │   ├── panel_slot.gd           — case, hérite Interactable : icône Sprite3D, nom traduit en repli, prendre/poser/activer
│   │   │   ├── panel_slot.tscn         — StaticBody3D + CollisionShape3D + Background + Icon + Label (tout dimensionné au code)
│   │   │   ├── panel_gauge.gd          — barre de remplissage, deux quads non éclairés, construite au code
│   │   │   ├── backpack_panel.gd       — panneau du sac posé : 3x3 stockage + 3 poches
│   │   │   ├── backpack_panel.tscn
│   │   │   ├── cooking_panel.gd        — panneau d'un site de transformation : recettes, ingrédients, combustible, jauges
│   │   │   └── cooking_panel.tscn      — porte ses réglages (anchor_offset 1.6m, slot_size 0.26, close_distance 4m)
│   │   ├── buildings/
│   │   │   ├── campfire.gd             — bâtiment fini, allumage/entretien, combustion Timer, E contextuel
│   │   │   ├── campfire.tscn
│   │   │   ├── transformation_site.gd
│   │   │   └── flame_light_flicker.gd  — script d'ambiance sur le Light3D de la flamme
│   │   ├── food/
│   │   │   └── grilled_mushroom.tscn   — pickup du champignon grillé (sortie de TransformationSite)
│   │   └── forest/
│   │       ├── mushroom_pickup.tscn    — premier petit objet (CarryType.SMALL)
│   │       ├── oak_choppable.tscn      — instance concrète de Choppable (chêne)
│   │       └── resource_pickup_wood.tscn — instance concrète de ResourcePickup (bois)
│   └── player/
│       ├── player.tscn                 — scène joueur assemblée
│       ├── player_controller.gd        — CharacterBody3D, locomotion, marches auto (step_height 0.35m), sprint (Shift) + saut (Espace) avec coyote time et kick de FOV
│       ├── action_state_machine.gd     — IDLE / USING_TOOL, découple timing swing/dégâts
│       ├── interaction_controller.gd   — raycast, prompt, arbitre outil vs portage, E → interact/carry, ouverture des panneaux, take_into_hand()
│       ├── carry_controller.gd         — point unique "en main", reparent → HandAnchor, désactive collision + freeze
│       ├── build_mode_controller.gd    — mode construction (B), blueprint, molette (rotation), Shift (free placing), spawn ConstructionSite
│       ├── equipment_controller.gd     — ceinture (2 outils) + sac à dos (BackpackData), hotbar actif, routage ramassage, drop (G → ToolPickup dynamique)
│       ├── ui_panel_controller.gd      — arbitre des panneaux : registre des ouverts, touche de fermeture, exclusivité avec les autres modes joueur
│       ├── hud/
│       │   ├── player_hud.tscn         — CanvasLayer HUD
│       │   ├── player_hud.gd           — réticule + prompt + hotbar, rien de manipulable
│       │   ├── crosshair.gd            — crosshair dessiné en code
│       │   └── hotbar.gd               — hotbar dessiné en code (2 belt + 3 poches si sac équipé), dimming quand mains occupées
│       └── tools/
│           └── tool_controller.gd      — viewmodel 1re personne, swing() tween 3 phases, piloté par EquipmentController
├── resources/
│   ├── resource_def.gd                 — Resource : définition d'item (CarryType: HAND/SMALL/TOOL), name_key
│   ├── tool_def.gd                     — Resource : définition data-driven d'un outil, name_key
│   ├── backpack_data.gd                — Resource : contenu d'un sac à dos (3 poches + 9 stockage), vit sur l'objet sac
│   ├── building_def.gd                 — Resource : définition d'un bâtiment (coûts, collision_shape, blueprint/built scene), name_key
│   ├── resource_cost.gd
│   ├── recipe_def.gd                   — Resource : recette de transformation (inputs/output/durée), name_key
│   ├── terrain_gen_config.gd           — (@tool) Resource : tous les réglages de génération du terrain + la convention de grille (grid_size(), cell_count(), half_size(), chunks_per_side(), height_index(), world_pos())
│   ├── resources/                      — instances ResourceDef
│   │   ├── wood.tres
│   │   ├── mushroom.tres
│   │   └── grilled_mushroom.tres
│   ├── recipes/                        — instances RecipeDef
│   │   └── grilled_mushroom.tres
│   ├── tools/
│   │   └── wooden_axe.tres             — instance ToolDef
│   ├── buildings/
│   │   ├── campfire.tres               — instance BuildingDef
│   │   └── campfire_shape.tres         — Shape3D partagée
│   └── terrain/
│       └── default_terrain.tres        — instance TerrainGenConfig ; porte en sous-ressources les 4 FastNoiseLite, le ShaderMaterial du sol et le StandardMaterial3D de l'eau
└── world/
	├── bunker/
	│   └── bunker_exterior_test.tscn   — scène bunker (SciFi MegaKit, ext + int) — bâtie sur sol plat, périmée par le terrain procédural, conservée comme réserve de pièces
	├── terrain/
	│   ├── heightmap_generator.gd      — (@tool) RefCounted : tirage du massif, relief, niveau d'eau, clairière, rivière. Publie heights / cave_position / cave_forward / water_level
	│   ├── terrain_mesh_builder.gd     — (@tool) RefCounted, statique : build_chunk() → StaticBody3D (MeshInstance3D + CollisionShape3D trimesh)
	│   ├── terrain_controller.gd       — (@tool) Node3D : orchestrateur, boutons Régénérer/Effacer, crée Chunks / Water / CaveSite
	│   └── terrain.gdshader            — sol coloré par altitude et pente (herbe → roche → paroi)
	└── forest/
		├── forest_test.tscn            — scène de test historique (sol plat + scatter + freecam + bunker)
		└── forest_scatter.gd           — placement jitter/poisson-disque, zone d'exclusion bunker — sera étendu aux cartes de biome en passe B du Jalon 4
```
 
Hors `res://` scripts, à noter :
 
- `assets/characters/tools/wooden_axe_grip.tscn` — wrapper `Node3D` pour rattraper le pivot du FBX hache (protocole détaillé dans STATE §Apprentissages). Convention à répliquer pour les prochains outils.
## Dépendances transversales clés
 
### Flux de génération du terrain
- Sens de la dépendance : `TerrainController` (le seul nœud de la scène) appelle `HeightmapGenerator.generate(config)` puis `TerrainMeshBuilder.build_chunk(config, heights, cx, cz)` pour chaque chunk. Les deux générateurs sont des `RefCounted` sans état persistant et ne connaissent ni la scène ni le contrôleur.
- **`TerrainGenConfig` est la source unique de la convention de grille** : `height_index(ix, iz)` et `world_pos(ix, iz)` ne sont réimplémentés nulle part. Générateur et mesh builder les appellent, y compris dans leurs boucles chaudes.
- Ordre de génération dans `HeightmapGenerator.generate()`, et il compte : tirage du massif → relief → niveau de l'eau → clairière → rivière. La rivière se trace sur un relief déjà complet (elle descend les pentes) ; la vallée est creusée **avant** (elle est ce qui empêche la descente de gradient de s'échouer).
- **Tout le relief se calcule dans le repère du massif** (`along` le long de l'axe, `side` en travers), pas dans le repère du monde. C'est ce qui permet de tirer l'orientation au hasard : vallée, pente d'écoulement et rivière s'alignent dessus sans rien savoir de l'angle.
- Contrainte de placement : la bouche de grotte est à l'origine du monde, et l'axe du massif est **résolu** pour que le pied de sa falaise y tombe. Il n'existe donc aucun réglage de position de massif.
- `TerrainController` publie ce que le reste du jeu doit savoir du terrain : le nœud `CaveSite` (`Marker3D`, -Z tourné vers l'extérieur) et le plan `Water` à `water_level`.
- **Les nœuds générés n'ont pas d'owner** : ils ne sont jamais sérialisés dans le `.tscn` et ne partent pas dans le dépôt. Le terrain se régénère, il ne se sauvegarde pas.
- Les normales des chunks sont calculées par différences centrées sur le **tableau global** de hauteurs, pas sur les faces du chunk : deux chunks voisins lisent les mêmes sommets et se raccordent sans couture, sans code de recollement.
- ⚠️ Toute la chaîne est `@tool`. Le `@tool` ne s'hérite pas et ne se transmet pas : un script non-`@tool` instancié ou référencé par un script `@tool` devient une coquille sans méthodes dans l'éditeur (« placeholder instance »).
### Flux d'action (swing outil)
- Sens de la dépendance : `ActionStateMachine.use_tool_on(target, on_impact, reach_distance)` appelle `ToolController.swing()` et écoute son signal `swing_impact` en retour. La SM pilote le controller, jamais l'inverse.
- Au `swing_impact`, la SM exécute le `Callable` fourni par l'appelant — typiquement `receive_tool_hit()` sur la cible verrouillée par l'`InteractionController` — uniquement si la cible est encore valide.
- `Choppable.receive_tool_hit()` : vérifie le type d'outil via `ToolDef`, décrémente HP, émet `depleted` → spawn 3 `ResourcePickup` physiques, hook `chop_sound` → `SoundManager` (asset non branché).
### Flux d'interaction / portage
- `InteractionController` : raycast vers un `Interactable`, gère le prompt (fix `tree_exiting` sur la cible, pas `is_instance_valid()` seul). Le prompt vient de `Interactable.get_prompt_key(interactor)`, surchargeable — c'est ce qui rend le verbe contextuel (le feu dit « Cuire » avec un champi, « Alimenter » avec une bûche).
- Ordre des branches sur E, et il compte : objet lourd en main → livraison ou dépose ; petit objet en poche active → livraison ; sinon `interact()`. Une cible interactive qui **refuse** la ressource proposée rend la main à la branche suivante au lieu de faire tomber l'objet au sol.
- `CarryController` ↔ `ResourcePickup` : le pickup lit son `ResourceDef.CarryType` pour valider le portage main.
- Miroir : `InteractionController` masque/remontre l'outil via `ToolController.set_tool_visible()` quand les mains sont occupées.
- `PlayerController` lit `CarryController.is_carrying()` pour brider sprint et saut — seule dépendance locomotion → portage.
- `TransformationSite` (enfant d'un bâtiment) : `Campfire.receive_resource()` route le combustible vers lui-même et tout le reste vers `try_insert()`. Sortie en `ResourcePickup` via `ResourceRegistry`.
### Flux des panneaux
- Un panneau est un objet du monde, pas un élément de HUD : `WorldPanel` (Node3D) suit son ancre et pivote sur l'axe Y pour lui faire face. Ses cases sont des `PanelSlot`, qui héritent d'`Interactable`.
- **Conséquence structurante : il n'existe aucun système de visée, de survol ni de transfert propre à l'UI.** Le réticule est le pointeur, le raycast d'interaction touche les cases comme il touche un rondin, et E prend, pose ou active. C'est le même chemin de code que tout le reste du jeu.
- `UIPanelController.open_panel(panel, anchor)` est le seul chemin d'ouverture. Il refuse si un mode exclusif tourne ou si l'`ActionStateMachine` n'est pas `IDLE`.
- `InteractionController.open_object_panel(source, panel_scene)` **bascule** : E sur l'objet ouvre, E à nouveau ferme. Le panneau est instancié à l'ouverture, branché par `bind()`, détruit à la fermeture — un exemplaire par ancre, jamais rebranché.
- Le panneau est enfant de la **scène**, pas de son ancre : les assets du projet ont des échelles arbitraires et un panneau enfant les hériterait.
- `exclusive_modes: Array[Node]` — tout nœud exposant `is_active() -> bool` bloque l'ouverture (duck typing). L'arbitre ne cite aucun type de mode : c'est ce qui lui permet d'être référencé *par* eux sans cycle de `class_name`. Réciproquement, un mode appelle `can_enter_exclusive_mode()`.
- Plusieurs panneaux peuvent être ouverts ensemble : l'exclusivité est entre *modes*, pas entre panneaux. Passer un objet d'un panneau à l'autre ne demande aucun code — on le prend en main d'un côté, on le pose de l'autre.
- Contrat de case, implémenté par le panneau propriétaire : `slot_content()`, `slot_accepts()`, `slot_can_take()`, `slot_take()`, `slot_put()`, plus `slot_action_key()` / `slot_activate()` pour une case qui déclenche une action au lieu de contenir un objet (choisir une recette). La case porte un `payload` opaque et ne décide de rien.
### Flux de localisation
- `translations/strings.csv` = source unique de tout texte affiché. Rangé en sections (une par namespace de clé), alphabétique à l'intérieur. Les lignes de titre ont une **première colonne vide** : Godot les ignore à l'import.
- Convention de clés : `namespace.section.key` (`interact.prompt.chop`, `resource.wood.name`).
- Les `.tres` et les `.tscn` ne portent que des clés : `ResourceDef`/`ToolDef`/`BuildingDef`/`RecipeDef.name_key`, `Interactable.prompt_key`.
- **Le `tr()` ne se fait qu'aux points d'affichage — trois dans tout le projet** :
  - `PlayerHud.show_prompt()` — tous les prompts d'interaction
  - `Hotbar._slot_label()` — noms en ceinture et en poche
  - `PanelSlot._refresh_display()` — noms dans les cases, tous panneaux confondus
  Tout nouveau `tr()` ailleurs signale une string qui aurait dû transiter par une clé.
- Les cases de recette n'affichent **aucun texte** : elles montrent l'icône du plat produit. C'est délibéré — ça évite un quatrième point de traduction.
- ⚠️ Les clés de cache d'icônes (`Hotbar`, `ResourceRegistry.get_tool_icon()`) sont bâties sur `ToolDef.id` / `ResourceDef.id`, **jamais** sur un nom affiché — sinon le cache se casse au changement de langue.
### Flux de construction
- `BuildModeController` (B) : lit la liste des `BuildingDef` disponibles, instancie le blueprint, tourne à la molette, `Shift` désactive le snap, check collision via `BuildingDef.collision_shape` (+ `collision_shape_local_transform()`).
- Placement validé → spawn d'un `ConstructionSite` (Interactable).
- `ConstructionSite` : lit `BuildingDef.costs` (Array[`ResourceCost`]), réceptionne les livraisons de `ResourcePickup`, à complétion → `queue_free` + spawn de la `built_scene` (ex : `Campfire`).
- **Le mode construction n'est pas un état de l'`ActionStateMachine`** (décision documentée dans STATE). Son exclusivité passe par `UIPanelController.can_enter_exclusive_mode()`.
### Contraintes d'ordre
- `HeightmapGenerator` avant `TerrainMeshBuilder` : le mesh lit le tableau de hauteurs terminé.
- Le scatter doit tourner **après** le terrain et **avant** le bake de `NavigationRegion3D`.
- La carte d'ouverture (passe B) se calcule **entre** la strate canopée et la strate sol : elle dépend de ce que la canopée a effectivement posé.
### Autoload commun
- `SoundManager` (autoload) : appelé par tout ce qui produit un SFX positionné (aujourd'hui `Choppable`, plus tard `Campfire`, `ConstructionSite` livraison, etc.).
### Flux d'équipement
- `EquipmentController` : ceinture 2 slots (`ToolDef`) + ref `BackpackData` (poches + stockage). Pilote `ToolController.equip()`/`unequip()` selon le slot actif. Sélection via molette/1-5.
- Drop (G) : retire du slot, spawn un `ToolPickup` dynamique (StaticBody3D + mesh + BoxShape3D, raycast sol). `ToolPickup.interact()` → retour en ceinture via `EquipmentController.try_store_tool()`.
- Priorité affichage : Main (CarryController) > Hotbar actif. Hotbar dimmed quand mains occupées.
- `BackpackData` vit sur l'objet sac (pas sur le joueur) — prêt pour pawns avec leur propre sac.