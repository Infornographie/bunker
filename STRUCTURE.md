# STRUCTURE — Projet Bunker
 
Carte de repérage technique : où vit quoi, et qui dépend de quoi. Pas un suivi d'avancement (→ STATE.md) ni un backlog (→ ROADMAP.md) : uniquement la structure.
 
## Conventions
 
- Fichiers `.gd` : snake_case (convention officielle Godot). `class_name` interne en PascalCase si besoin.
- Scènes `.tscn` : snake_case.
- Organisation par feature/domaine, pas par type de fichier (scène et script d'une même feature côte à côte).
- `entities/` = tout ce qui est instanciable individuellement (script de base + scènes concrètes qui en héritent), rangé par comportement.
- `world/` = scènes qui assemblent des entités dans un lieu (le niveau lui-même).
- `resources/` = définitions data-driven. Un sous-dossier par type de def (`resources/`, `tools/`, `buildings/`, `recipes/`, futur `techs/`...), à côté des scripts `*_def.gd` correspondants.
- `assets/` = ressources brutes tierces (FBX, textures, audio) + quelques scènes wrapper Godot quand l'asset importé demande un pivot correctif (cf. `wooden_axe_grip.tscn`).
- Un même item peut avoir trois fichiers homonymes dans trois dossiers distincts, un par rôle : sa définition (`resources/resources/x.tres`), sa recette de production (`resources/recipes/x.tres`), sa scène de pickup (`entities/interactable/.../x.tscn`). C'est le cas de `grilled_mushroom`.
- **Aucun texte affichable dans le code ni dans les `.tres`** : uniquement des clés de traduction (`name_key`, `prompt_key`). Voir § Flux de localisation.
## Autoloads (globaux, accessibles partout sans référence)
 
Déclarés dans `project.godot` § `[autoload]` — cette liste doit correspondre exactement :
 
- `SoundManager` → `autoloads/sound_manager.gd` — pool d'`AudioStreamPlayer3D` réutilisables pour SFX ponctuels positionnés.
- `ResourceRegistry` → `autoloads/resource_registry.gd` — table `ResourceDef` → `PackedScene`, scan auto au boot, sert aussi les icônes.
- `Locale` → `autoloads/locale.gd` — wrapper `TranslationServer` : `get_locale()`, `set_locale()`, signal `locale_changed`, fallback `en`. Porte aussi sa bascule debug (F10).
`autoloads/icon_generator.gd` vit dans le même dossier mais **n'est pas** un autoload : il est instancié par `ResourceRegistry`.
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
│   └── icon_generator.gd               — rendu SubViewport ortho 3/4 d'un modèle 3D → Texture2D, cache par clé, instancié par ResourceRegistry (pas un autoload)
├── translations/
│   └── strings.csv                     — source unique des textes affichés (colonnes `keys`, `en`, `fr`) ; Godot compile en .translation à l'import
├── debug/
│   ├── debug_camera_switch.gd          — bascule cam player ↔ freecam (F7)
│   └── freecam_controller.gd           — caméra libre noclip
├── entities/
│   ├── interactable/
│   │   ├── interactable.gd             — base PhysicsBody3D, receive_tool_hit(), prompt_key
│   │   ├── choppable.gd                — hérite Interactable : HP, type d'outil, depleted → 3× pickup
│   │   ├── resource_pickup.gd          — hérite Interactable (RigidBody3D) : objet ramassable, lit ResourceDef
│   │   ├── construction_site.gd        — hérite Interactable : blueprint posé, réceptionne les livraisons
│   │   ├── construction_site.tscn
│   │   ├── tool_pickup.gd              — outil posé au sol (Interactable, créé dynamiquement par EquipmentController)
│   │   ├── backpack_pickup.gd          — sac à dos dans le monde, porte le BackpackData, snap au sol au drop
│   │   ├── backpack_pickup.tscn
│   │   ├── buildings/
│   │   │   ├── campfire.gd             — bâtiment fini, allumage/entretien, combustion Timer
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
│       ├── interaction_controller.gd   — raycast, prompt, arbitre outil vs portage, E → interact/carry
│       ├── carry_controller.gd         — point unique "en main", reparent → HandAnchor, désactive collision + freeze
│       ├── build_mode_controller.gd    — mode construction (B), blueprint, molette (rotation), Shift (free placing), spawn ConstructionSite
│       ├── equipment_controller.gd     — ceinture (2 outils) + sac à dos (BackpackData), hotbar actif, routage ramassage, drop (G → ToolPickup dynamique)
│       ├── ui_panel_controller.gd      — arbitre des panneaux ancrés : registre des panneaux ouverts, mouse mode, gel du joueur, touche de fermeture, exclusivité avec les autres modes joueur
│       ├── hud/
│       │   ├── player_hud.tscn         — CanvasLayer HUD
│       │   ├── player_hud.gd           — crosshair + prompt + hotbar
│       │   ├── crosshair.gd            — crosshair dessiné en code
│       │   ├── hotbar.gd               — hotbar dessiné en code (2 belt + 3 poches si sac équipé), dimming quand mains occupées
│       │   ├── world_anchored_panel.gd — base des panneaux ancrés sur un objet du monde : projection écran, fermeture distance / cible détruite / derrière-caméra, _build_content() et refresh() surchargeables
│       │   ├── item_slot.gd            — case d'inventaire générique : icône générée + nom traduit en repli, drag & drop natif, payload opaque posé par le panneau propriétaire
│       │   └── backpack_ui.gd          — UI du sac ouvert (hérite WorldAnchoredPanel) : disposition 3x3 + 3 poches + main, règles de transfert
│       └── tools/
│           └── tool_controller.gd      — viewmodel 1re personne, swing() tween 3 phases, piloté par EquipmentController (plus de default_tool)
├── resources/
│   ├── resource_def.gd                 — Resource : définition d'item (CarryType: HAND/SMALL/TOOL), name_key
│   ├── tool_def.gd                     — Resource : définition data-driven d'un outil, name_key
│   ├── backpack_data.gd                — Resource : contenu d'un sac à dos (3 poches + 9 stockage), vit sur l'objet sac
│   ├── building_def.gd                 — Resource : définition d'un bâtiment (coûts, collision_shape, blueprint/built scene), name_key
│   ├── resource_cost.gd
│   ├── recipe_def.gd                   — Resource : recette de transformation (inputs/output/durée), name_key
│   ├── resources/                      — instances ResourceDef
│   │   ├── wood.tres
│   │   ├── mushroom.tres
│   │   └── grilled_mushroom.tres
│   ├── recipes/                        — instances RecipeDef
│   │   └── grilled_mushroom.tres
│   ├── tools/
│   │   └── wooden_axe.tres             — instance ToolDef
│   └── buildings/
│       ├── campfire.tres               — instance BuildingDef
│       └── campfire_shape.tres         — Shape3D partagée
└── world/
	├── bunker/
	│   └── bunker_exterior_test.tscn   — scène bunker (SciFi MegaKit, ext + int)
	└── forest/
		├── forest_test.tscn            — scène de test (sol + scatter + freecam + bunker)
		└── forest_scatter.gd           — placement jitter/poisson-disque, zone d'exclusion bunker
```
 
Hors `res://` scripts, à noter :
 
- `assets/characters/tools/wooden_axe_grip.tscn` — wrapper `Node3D` pour rattraper le pivot du FBX hache (protocole détaillé dans STATE §Apprentissages). Convention à répliquer pour les prochains outils.
## Dépendances transversales clés
 
### Flux d'action (swing outil)
- Sens de la dépendance : `ActionStateMachine.use_tool_on(target, on_impact, reach_distance)` appelle `ToolController.swing()` et écoute son signal `swing_impact` en retour. La SM pilote le controller, jamais l'inverse.
- Au `swing_impact`, la SM exécute le `Callable` fourni par l'appelant — typiquement `receive_tool_hit()` sur la cible verrouillée par l'`InteractionController` — uniquement si la cible est encore valide.
- `Choppable.receive_tool_hit()` : vérifie le type d'outil via `ToolDef`, décrémente HP, émet `depleted` → spawn 3 `ResourcePickup` physiques, hook `chop_sound` → `SoundManager` (asset non branché).
### Flux d'interaction / portage
- `InteractionController` : raycast vers un `Interactable`, gère le prompt (fix `tree_exiting` sur la cible, pas `is_instance_valid()` seul).
- Sur E : soit `Interactable.interact()`, soit délégation à `CarryController` (mains libres uniquement).
- `CarryController` ↔ `ResourcePickup` : le pickup lit son `ResourceDef.CarryType` pour valider le portage main.
- Miroir : `InteractionController` masque/remontre l'outil via `ToolController.set_tool_visible()` quand les mains sont occupées.
- `PlayerController` lit `CarryController.is_carrying()` pour brider sprint et saut — seule dépendance locomotion → portage.
- `TransformationSite` (enfant d'un bâtiment) : `Campfire.receive_resource()` route le combustible vers lui-même et tout le reste vers `try_insert()`. Sortie en `ResourcePickup` via `ResourceRegistry`.
### Flux des panneaux ancrés
- Trois responsabilités, trois fichiers, aucun recouvrement : `ItemSlot` affiche et drague, `WorldAnchoredPanel` s'ancre et se ferme, `UIPanelController` arbitre.
- `UIPanelController.open_panel(panel, anchor)` est **le seul chemin d'ouverture**. Il refuse si un mode exclusif tourne ou si l'`ActionStateMachine` n'est pas `IDLE`, puis appelle `panel.open_anchored(anchor, camera)`.
- Le contrôleur possède seul le mouse mode et le gel du joueur (`set_input_enabled`), pilotés par une question unique : reste-t-il un panneau ouvert ? Un panneau n'y touche jamais.
- **Plusieurs panneaux peuvent être ouverts simultanément** (sac posé + feu voisin) : l'exclusivité est entre *modes* joueur, pas entre panneaux. C'est ce qui rend possible le drag d'un panneau à l'autre.
- `exclusive_modes: Array[Node]` — tout nœud exposant `is_active() -> bool` bloque l'ouverture d'un panneau (duck typing, même patron que `TransformationSite` ↔ son hôte). Le contrôleur ne cite aucun type de mode : c'est ce qui lui permet d'être référencé *par* eux sans cycle de `class_name`.
- Réciproquement, un mode exclusif appelle `can_enter_exclusive_mode()` avant de s'ouvrir. Une seule direction de connaissance typée : mode → contrôleur.
- Drag & drop : la donnée de drag est l'`ItemSlot` source elle-même, pas un dictionnaire à schéma. La case cible interroge son propre propriétaire (`slot_can_accept()` / `slot_accept_drop()`) en lui passant la source telle quelle. Deux panneaux s'échangent donc des items sans se connaître — chacun décide chez lui, et `BackpackUI` refuse aujourd'hui toute source étrangère.
### Flux de localisation
- `translations/strings.csv` = source unique de tout texte affiché. Rangé en sections (une par namespace de clé), alphabétique à l'intérieur. Les lignes de titre ont une **première colonne vide** : Godot les ignore à l'import.
- Convention de clés : `namespace.section.key` (`interact.prompt.chop`, `resource.wood.name`).
- Les `.tres` et les `.tscn` ne portent que des clés : `ResourceDef`/`ToolDef`/`BuildingDef`/`RecipeDef.name_key`, `Interactable.prompt_key`.
- **Le `tr()` ne se fait qu'aux points d'affichage — quatre dans tout le projet** :
  - `PlayerHud.show_prompt()` — tous les prompts d'interaction
  - `Hotbar._slot_label()` — noms en ceinture et en poche
  - `ItemSlot.set_content()` — noms dans les cases d'inventaire, tous panneaux confondus
  - `ItemSlot._make_preview()` — libellé de l'aperçu de drag
  Tout nouveau `tr()` ailleurs signale une string qui aurait dû transiter par une clé.
- ⚠️ Les clés de cache d'icônes (`Hotbar`, `ResourceRegistry.get_tool_icon()`) sont bâties sur `ToolDef.id` / `ResourceDef.id`, **jamais** sur un nom affiché — sinon le cache se casse au changement de langue.
### Flux de construction
- `BuildModeController` (B) : lit la liste des `BuildingDef` disponibles, instancie le blueprint, tourne à la molette, `Shift` désactive le snap, check collision via `BuildingDef.collision_shape` (+ `collision_shape_local_transform()`).
- Placement validé → spawn d'un `ConstructionSite` (Interactable).
- `ConstructionSite` : lit `BuildingDef.costs` (Array[`ResourceCost`]), réceptionne les livraisons de `ResourcePickup` (via `interact()` avec ressource en main), à complétion → `queue_free` + spawn de la `built_scene` (ex : `Campfire`).
- `Campfire` : bâtiment fini, `Timer` de combustion, `flame_light_flicker` anime le Light3D de la flamme.
- **Le mode construction n'est pas un état de l'`ActionStateMachine`** (décision documentée dans STATE). Son exclusivité passe désormais par `UIPanelController` : `_enter_build_mode()` appelle `can_enter_exclusive_mode()`, et `InteractionController` se tait tant que `is_any_panel_open()` ou `BuildModeController.is_active()`.
### Contraintes d'ordre
- `ForestScatter` doit tourner **avant** le bake de `NavigationRegion3D` (revalidé au Jalon 4 avec le terrain procédural).
### Autoload commun
- `SoundManager` (autoload) : appelé par tout ce qui produit un SFX positionné (aujourd'hui `Choppable`, plus tard `Campfire`, `ConstructionSite` livraison, etc.).
### Flux d'équipement
- `EquipmentController` : ceinture 2 slots (`ToolDef`) + ref `BackpackData` (poches + stockage). Pilote `ToolController.equip()`/`unequip()` selon le slot actif. Sélection via molette/1-5.
- Drop (G) : retire du slot, spawn un `ToolPickup` dynamique (StaticBody3D + mesh + BoxShape3D, raycast sol). `ToolPickup.interact()` → retour en ceinture via `EquipmentController.try_store_tool()`.
- Priorité affichage : Main (CarryController) > Hotbar actif. Hotbar dimmed quand mains occupées.
- `BackpackData` vit sur l'objet sac (pas sur le joueur) — prêt pour pawns avec leur propre sac.
