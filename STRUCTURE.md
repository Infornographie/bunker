# STRUCTURE — Projet Bunker

Carte de repérage technique : où vit quoi, et qui dépend de quoi. Pas un suivi d'avancement (→ STATE.md) ni un backlog (→ ROADMAP.md) : uniquement la structure.

## Conventions

- Fichiers `.gd` : snake_case (convention officielle Godot). `class_name` interne en PascalCase si besoin.
- Scènes `.tscn` : snake_case.
- Organisation par feature/domaine, pas par type de fichier (scène et script d'une même feature côte à côte).
- `entities/` = tout ce qui est instanciable individuellement (script de base + scènes concrètes qui en héritent), rangé par comportement.
- `world/` = scènes qui assemblent des entités dans un lieu (le niveau lui-même).
- `resources/` = définitions data-driven. Un sous-dossier par type de def (`resources/`, `tools/`, futur `buildings/`, `techs/`...), à côté des scripts `*_def.gd` correspondants.

## Autoloads (globaux, accessibles partout sans référence)

- `autoloads/sound_manager.gd` — pool de 8 `AudioStreamPlayer3D` réutilisables pour SFX ponctuels positionnés.

## Arborescence

res://
├── autoloads/
│ └── sound_manager.gd — pool SFX, voir Autoloads ci-dessus
├── debug/
│ ├── debug_camera_switch.gd — bascule caméra joueur ↔ freecam (touche F7)
│ └── freecam_controller.gd — caméra libre noclip, conservé tout le long du projet
├── entities/
│ ├── interactable/
│ │ ├── interactable.gd — classe de base, PhysicsBody3D (étendu depuis StaticBody3D pour supporter des interactables mobiles), virtual receive_tool_hit()
│ │ ├── choppable.gd — hérite Interactable : HP, vérif type d'outil, anti-spam swing, signal depleted, hook chop_sound (pas d'asset assigné)
│ │ ├── resource_pickup.gd — hérite Interactable (RigidBody3D en pratique) : objet ramassable/portable au sol, lit un ResourceDef, impulsion de chute orientée
│ │ └── forest/
│ │ ├── oak_choppable.tscn — instance concrète de Choppable (chêne)
│ │ └── resource_pickup_wood.tscn — instance concrète de ResourcePickup (bois)
│ └── player/
│ ├── player.tscn — scène joueur assemblée
│ ├── player_controller.gd — CharacterBody3D, locomotion/caméra, franchissement marches auto (test_move, step_height 0.35m)
│ ├── action_state_machine.gd — states IDLE/USING_TOOL, découple timing du swing des dégâts
│ ├── interaction_controller.gd — raycast/zone vers Interactable, gère le prompt d'interaction, arbitre outil vs portage (mains occupées = pas de swing), déclenche ramassage/dépose (E)
│ ├── carry_controller.gd — un seul objet porté à la fois, reparenting vers HandAnchor, désactive collision + freeze pendant le portage
│ ├── hud/
│ │ ├── player_hud.tscn — CanvasLayer HUD
│ │ ├── player_hud.gd — dessine crosshair + prompt d'interaction 2D screen-space
│ │ └── crosshair.gd — crosshair dessiné en code
│ └── tools/
│ └── tool_controller.gd — swing() en tween 3 phases (anticipation/strike/recoil), lit ToolDef
├── resources/
│ ├── resource_def.gd — classe Resource : définition d'une ressource récoltable
│ ├── tool_def.gd — classe Resource : définition data-driven d'un outil
│ ├── resources/
│ │ └── wood.tres — instance ResourceDef
│ └── tools/
│ └── wooden_axe.tres — instance ToolDef
└── world/
├── bunker/
│ └── bunker_exterior_test.tscn — scène bunker (SciFi MegaKit, extérieur+intérieur)
└── forest/
├── forest_test.tscn — scène de test forêt (sol + scatter + freecam)
└── forest_scatter.gd — placement jitter/poisson-disque, zone d'exclusion autour du bunker

## Dépendances transversales clés

- `InteractionController` (player) → raycast vers `Interactable.receive_tool_hit()` — les effets se résolvent à l'impact, pas à l'input.
- `ToolController.swing()` pilote `ActionStateMachine` (IDLE/USING_TOOL) → au moment du strike, déclenche `receive_tool_hit()` sur la cible.
- `Choppable` (hérite `Interactable`) → vérifie le type d'outil via `ToolDef`, décrémente HP, émet `depleted`, spawn 3 `ResourcePickup` physiques au sol à sa destruction, hook `chop_sound` vers `SoundManager` (autoload) — pas encore d'asset son branché.
- `CarryController` ↔ `ResourcePickup` : `interact()` délègue le ramassage au `CarryController` de l'`InteractionController` (mains libres uniquement) ; `InteractionController` masque/remontre l'outil via `ToolController.set_tool_visible()` en miroir de l'état porté.
- `PlayerHud` écoute les signaux de `InteractionController` pour afficher/masquer le prompt (fix : écoute `tree_exiting` sur la cible, pas `is_instance_valid()` seul, à cause de la destruction différée de `queue_free()`).
- `ForestScatter` doit tourner **avant** le bake de `NavigationRegion3D` (contrainte d'ordre, revalidée au Jalon 4).
