# INPUTS — Projet Bunker
 
Source unique des bindings clavier/souris du jeu. À mettre à jour à chaque ajout ou modification de binding — un binding qui apparaît en code sans passer par ici, c'est un piège pour la prochaine session.
 
Le nom d'action entre `backticks` est celui de l'Input Map (`project.godot` § `[input]`). Cette liste et l'Input Map doivent se correspondre une pour une : toute action présente d'un côté et pas de l'autre est un bug ou une dette à nommer.
 
⚠️ Godot enregistre des **physical keycodes** = positions QWERTY. Sur clavier AZERTY, la touche notée ici est la touche physiquement pressée (ex. `move_forward` est au code 87 « W » = **Z** sur AZERTY). Ne jamais lire les codes bruts comme des lettres.
## Déplacement / caméra
 
- **ZQSD** — locomotion (`move_forward` / `move_left` / `move_back` / `move_right`)
- **Shift (maintenu)** — course (`sprint`), bloquée quand les mains portent un objet lourd
- **Espace** — saut (`jump`), bloqué quand les mains portent un objet lourd
- **Souris** — orientation caméra première personne (lu directement en `InputEventMouseMotion`, pas d'action dans l'Input Map)
## Outil en main
 
- **Clic gauche** — utiliser l'outil équipé (`use_tool`) : swing hache, etc.
## Interaction / portage
 
- **E** — interagir avec la cible visée (`interact`) : ramasser, déposer, activer
## Équipement (hotbar)
 
- **1-5** — sélection directe du slot (`select_slot_1` … `select_slot_5`)
- **Molette haut / bas** — cycler les slots (`cycle_slot_prev` / `cycle_slot_next`)
- **G** — déposer au sol l'item du slot actif (`drop_slot`)
- **A** — sac à dos : dos ↔ main, ou ramasser un sac au sol (`backpack_toggle`)
- **E** (sur sac posé) — ouvrir l'interface du sac (`interact`)
- **Échap / E** (UI ouverte) — fermer (`ui_cancel` natif Godot / `interact`)
## Mode construction
 
- **B** — ouvrir / fermer le mode construction (`toggle_build_mode`)
- **Clic gauche** — valider la pose du blueprint (`confirm_placement`)
- **Molette haut / bas** — rotation du blueprint (`rotate_ghost` / `rotate_ghost_reverse`, pas de 45°)
- **Shift (maintenu)** — free placing (`free_placement_modifier`, désactive le snap grille)
L'Input Map contient aussi une action `cancel_build_mode` (bindée sur **B**) : elle est **inerte**. Dans `BuildModeController._unhandled_input()`, le bloc `toggle_build_mode` fait un `return` inconditionnel avant qu'elle soit testée. B ferme donc bien le mode, mais via le toggle. Dette rangée au Jalon 3.6.
## Debug
 
- **F7** — bascule caméra joueur ↔ freecam noclip (`toggle_debug_cam`)
- **F10** — bascule de langue EN ↔ FR (`toggle_locale`), écoutée par l'autoload `Locale`
⚠️ **La rangée F5-F9 est réservée à l'éditeur Godot** (lancer / stop / pause…). En fenêtre de jeu embarquée, l'éditeur intercepte ces touches avant le jeu : le binding a l'air correct dans l'Input Map et ne se déclenche jamais. F8 et F9 ont été essayés et écartés pour cette raison. Toute nouvelle touche de debug se teste **en fenêtre embarquée** avant d'atterrir ici.
## Collisions de touches assumées
 
Aucune n'est arbitrée par l'Input Map : ce sont les contrôleurs qui garantissent l'exclusivité. Toute modification de ces gardes doit repasser par ici.
 
- **Shift** : `sprint` en locomotion, `free_placement_modifier` en mode construction. Contextes exclusifs (on ne pose pas un blueprint en courant).
- **Molette** : `rotate_ghost`/`rotate_ghost_reverse` et `cycle_slot_prev`/`cycle_slot_next` partagent les boutons 4 et 5. Exclusivité tenue par le garde `_active` de `BuildModeController`.
- **Clic gauche** : `use_tool` et `confirm_placement` partagent le bouton 1. Exclusivité tenue par la désactivation d'`InteractionController` pendant le mode construction.
- **B** : `toggle_build_mode` et `cancel_build_mode` partagent la touche — voir la note du § Mode construction, ce n'est pas une collision assumée mais une dette.
