# STRUCTURE — Projet Bunker
 
Carte de repérage technique : où vit quoi, et qui dépend de quoi. Pas un suivi d'avancement (→ STATE.md) ni un backlog (→ ROADMAP.md) : uniquement la structure.
 
## Conventions
 
- Fichiers `.gd` : snake_case (convention officielle Godot). `class_name` interne en PascalCase si besoin.
- Scènes `.tscn` : snake_case.
- Organisation par feature/domaine, pas par type de fichier (scène et script d'une même feature côte à côte).
- `entities/` = tout ce qui est instanciable individuellement (script de base + scènes concrètes qui en héritent), rangé par comportement.
- `world/` = scènes qui assemblent des entités dans un lieu (le niveau lui-même).
- `resources/` = définitions data-driven. Un sous-dossier par type de def (`resources/`, `tools/`, `buildings/`, futur `techs/`...), à côté des scripts `*_def.gd` correspondants.
- `assets/` = ressources brutes tierces (FBX, textures, audio) + quelques scènes wrapper Godot quand l'asset importé demande un pivot correctif (cf. `wooden_axe_grip.tscn`).
## Autoloads (globaux, accessibles partout sans référence)
 
- `autoloads/sound_manager.gd` — pool d'`AudioStreamPlayer3D` réutilisables pour SFX ponctuels positionnés.
## Arborescence
 
```
res://
├── autoloads/
│   └── sound_manager.gd
├── debug/
│   ├── debug_camera_switch.gd          — bascule cam player ↔ freecam (F7)
│   └── freecam_controller.gd           — caméra libre noclip
├── entities/
│   ├── interactable/
│   │   ├── interactable.gd             — base PhysicsBody3D, receive_tool_hit()
│   │   ├── choppable.gd                — hérite Interactable : HP, type d'outil, depleted → 3× pickup
│   │   ├── resource_pickup.gd          — hérite Interactable (RigidBody3D) : objet ramassable, lit ResourceDef
│   │   ├── construction_site.gd        — hérite Interactable : blueprint posé, réceptionne les livraisons
│   │   ├── construction_site.tscn
│   │   ├── buildings/
│   │   │   ├── campfire.gd             — bâtiment fini, allumage/entretien, combustion Timer
│   │   │   ├── campfire.tscn
│   │   │   └── flame_light_flicker.gd  — script d'ambiance sur le Light3D de la flamme
│   │   └── forest/
│   │       ├── oak_choppable.tscn      — instance concrète de Choppable (chêne)
│   │       └── resource_pickup_wood.tscn — instance concrète de ResourcePickup (bois)
│   └── player/
│       ├── player.tscn                 — scène joueur assemblée
│       ├── player_controller.gd        — CharacterBody3D, locomotion, marches auto (step_height 0.35m)
│       ├── action_state_machine.gd     — IDLE / USING_TOOL, découple timing swing/dégâts
│       ├── interaction_controller.gd   — raycast, prompt, arbitre outil vs portage, E → interact/carry
│       ├── carry_controller.gd         — point unique "en main", reparent → HandAnchor, désactive collision + freeze
│       ├── build_mode_controller.gd    — mode construction (B), blueprint, molette (rotation), Shift (free placing), spawn ConstructionSite
│       ├── hud/
│       │   ├── player_hud.tscn         — CanvasLayer HUD
│       │   ├── player_hud.gd           — crosshair + prompt d'interaction 2D
│       │   └── crosshair.gd            — crosshair dessiné en code
│       └── tools/
│           └── tool_controller.gd      — viewmodel 1re personne, swing() tween 3 phases, lit ToolDef
├── resources/
│   ├── resource_def.gd                 — Resource : définition d'une ressource récoltable (carry_type, visuel)
│   ├── tool_def.gd                     — Resource : définition data-driven d'un outil
│   ├── building_def.gd                 — Resource : définition d'un bâtiment (coûts, shape, blueprint/built scene)
│   ├── building_cost.gd                — Resource sous-type : une ligne de coût (ResourceDef × quantité), utilisé en Array[BuildingCost] dans BuildingDef
│   ├── resources/
│   │   └── wood.tres                   — instance ResourceDef
│   ├── tools/
│   │   └── wooden_axe.tres             — instance ToolDef
│   └── buildings/
│       ├── campfire.tres               — instance BuildingDef
│       └── campfire_shape.tres         — Shape3D partagée (blueprint collision + collision runtime)
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
- `ToolController.swing()` → pilote `ActionStateMachine` (IDLE → USING_TOOL) ; au signal `swing_impact`, déclenche `receive_tool_hit()` sur la cible verrouillée par l'`InteractionController`.
- `Choppable.receive_tool_hit()` : vérifie le type d'outil via `ToolDef`, décrémente HP, émet `depleted` → spawn 3 `ResourcePickup` physiques, hook `chop_sound` → `SoundManager` (asset non branché).
### Flux d'interaction / portage
- `InteractionController` : raycast vers un `Interactable`, gère le prompt (fix `tree_exiting` sur la cible, pas `is_instance_valid()` seul).
- Sur E : soit `Interactable.interact()`, soit délégation à `CarryController` (mains libres uniquement).
- `CarryController` ↔ `ResourcePickup` : le pickup lit son `ResourceDef.CarryType` pour valider le portage main.
- Miroir : `InteractionController` masque/remontre l'outil via `ToolController.set_tool_visible()` quand les mains sont occupées.
### Flux de construction
- `BuildModeController` (B) : lit la liste des `BuildingDef` disponibles, instancie le blueprint, tourne à la molette, `Shift` désactive le snap, check collision via `BuildingDef.shape`.
- Placement validé → spawn d'un `ConstructionSite` (Interactable).
- `ConstructionSite` : lit `BuildingDef.costs` (Array[`BuildingCost`]), réceptionne les livraisons de `ResourcePickup` (via `interact()` avec ressource en main), à complétion → `queue_free` + spawn de la `built_scene` (ex : `Campfire`).
- `Campfire` : bâtiment fini, `Timer` de combustion, `flame_light_flicker` anime le Light3D de la flamme.
### Contraintes d'ordre
- `ForestScatter` doit tourner **avant** le bake de `NavigationRegion3D` (revalidé au Jalon 4 avec le terrain procédural).
### Autoload commun
- `SoundManager` (autoload) : appelé par tout ce qui produit un SFX positionné (aujourd'hui `Choppable`, plus tard `Campfire`, `ConstructionSite` livraison, etc.).