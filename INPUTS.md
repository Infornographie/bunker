# INPUTS — Projet Bunker
 
Source unique des bindings clavier/souris du jeu. À mettre à jour à chaque ajout ou modification de binding — un binding qui apparaît en code sans passer par ici, c'est un piège pour la prochaine session.
 
Le nom d'action entre `backticks` est celui de l'Input Map (`project.godot` § `[input]`). Cette liste et l'Input Map doivent se correspondre une pour une : toute action présente d'un côté et pas de l'autre est un bug ou une dette à nommer.
 
⚠️ Godot enregistre des **physical keycodes** = positions QWERTY. Sur clavier AZERTY, la touche notée ici est la touche physiquement pressée (ex. `move_forward` est au code 87 « W » = **Z** sur AZERTY). Ne jamais lire les codes bruts comme des lettres.
 
⚠️ **Il n'y a pas de curseur souris dans le jeu.** La souris reste capturée en permanence, y compris interfaces ouvertes : les panneaux sont des objets 3D et leurs cases se visent au réticule. Aucune interface ne fige le joueur — on continue de marcher pendant qu'un panneau est ouvert. Seul le panneau de debug du ciel (F3) libère le curseur, et c'est un outil de dev, pas une interface de jeu.
## Déplacement / caméra
 
- **ZQSD** — locomotion (`move_forward` / `move_left` / `move_back` / `move_right`)
- **Shift (maintenu)** — course (`sprint`), bloquée quand les mains portent un objet lourd ; en vol (voir § Debug), accélère le déplacement
- **Espace** — saut (`jump`), bloqué quand les mains portent un objet lourd ; en vol, monte
- **Souris** — orientation caméra première personne (lu directement en `InputEventMouseMotion`, pas d'action dans l'Input Map)
## Outil en main
 
- **Clic gauche** — utiliser l'outil équipé (`use_tool`) : swing hache, etc.
## Interaction / portage
 
- **E** — interagir avec la cible visée (`interact`). Verbe unique du jeu, contextuel : ramasser, déposer, livrer, ouvrir ou refermer un panneau, prendre ou poser dans une case, choisir une recette. Le prompt affiché à l'écran annonce toujours ce que E va faire — il vient de `Interactable.get_prompt_key()`, que chaque cible peut surcharger selon ce que le joueur propose.
## Équipement (hotbar)
 
- **1-5** — sélection directe du slot (`select_slot_1` … `select_slot_5`)
- **Molette haut / bas** — cycler les slots (`cycle_slot_prev` / `cycle_slot_next`)
- **G** — déposer au sol l'item du slot actif (`drop_slot`)
- **A** — sac à dos : dos ↔ main, ou ramasser un sac au sol (`backpack_toggle`)
## Panneaux du monde (sac posé, feu de camp…)
 
- **E** (sur l'objet) — ouvrir son panneau, et **le refermer** si déjà ouvert (`interact`). Le verbe qui ouvre est celui qui ferme.
- **E** (sur une case) — prendre l'objet en main, ou y poser ce qu'on tient, ou déclencher l'action de la case (`interact`)
- **Échap** — refermer tous les panneaux ouverts (`ui_cancel` natif Godot)
Un panneau se referme aussi tout seul quand on s'éloigne de son ancre, ou quand celle-ci disparaît. Plusieurs panneaux peuvent être ouverts en même temps : passer un objet de l'un à l'autre se fait par la main, il n'y a pas de glisser-déposer.
## Mode construction
 
- **B** — ouvrir / fermer le mode construction (`toggle_build_mode`)
- **Clic gauche** — valider la pose du blueprint (`confirm_placement`)
- **Molette haut / bas** — rotation du blueprint (`rotate_ghost` / `rotate_ghost_reverse`, pas de 45°)
- **Shift (maintenu)** — free placing (`free_placement_modifier`, désactive le snap grille)
Le mode construction et les panneaux s'excluent mutuellement : `UIPanelController` arbitre les deux sens.
## Debug
 
- **F11** — bascule le mode vol du joueur (`toggle_flight_mode`, dans `player_controller.gd`) : noclip, ignore gravité et collision. Espace monte, Ctrl descend, Shift accélère (`flight_boost_multiplier`). Désactiver le vol laisse le joueur là où il a volé, pas de retour au point de départ.
- **F10** — bascule de langue EN ↔ FR (`toggle_locale`), écoutée par l'autoload `Locale`
- **F3** — panneau de debug du cycle jour/nuit (`toggle_sky_debug`, dans `sky_debug_panel.gd`) : heure, durée du cycle, pause, saut direct aux quatre phases, répartition des phases, choix du profil de ciel, multiplicateurs de brume et d'ambiante. **Seule interface du projet qui libère le curseur** et qui neutralise la caméra tant qu'elle est ouverte. Déclarée dans `UIPanelController.exclusive_modes` comme les autres modes.
⚠️ **La rangée F5-F9 est réservée à l'éditeur Godot** (lancer / stop / pause…). En fenêtre de jeu embarquée, l'éditeur intercepte ces touches avant le jeu : le binding a l'air correct dans l'Input Map et ne se déclenche jamais. F7, F8 et F9 ont été essayés et écartés pour cette raison — d'où F11 pour le mode vol. Toute nouvelle touche de debug se teste **en fenêtre embarquée** avant d'atterrir ici.
## Collisions de touches assumées
 
Aucune n'est arbitrée par l'Input Map : ce sont les contrôleurs qui garantissent l'exclusivité. Toute modification de ces gardes doit repasser par ici.
 
- **Shift** : `sprint` en locomotion, `free_placement_modifier` en mode construction, boost en vol. Contextes exclusifs (on ne pose pas un blueprint en courant, on ne vole pas en construisant).
- **Molette** : `rotate_ghost`/`rotate_ghost_reverse` et `cycle_slot_prev`/`cycle_slot_next` partagent les boutons 4 et 5. Exclusivité tenue par le garde `_active` de `BuildModeController`.
- **Clic gauche** : `use_tool` et `confirm_placement` partagent le bouton 1. Exclusivité tenue par la désactivation d'`InteractionController` pendant le mode construction.
- **E** : un seul binding, mais plusieurs branches dans `InteractionController._unhandled_input()`, et **leur ordre est une règle de conception** — objet lourd en main d'abord, puis petit objet en poche active, puis `interact()` sur la cible. Une cible qui refuse la ressource proposée rend la main à la branche suivante au lieu de faire tomber l'objet. Toute branche ajoutée se place en connaissance de cet ordre.