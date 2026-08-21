# ROADMAP — Projet Bunker (nom provisoire)

## Jalon 0 — Setup projet
- [x] Init repo Godot 4.7.2
- [x] Structure de dossiers
- [x] Import des packs Quaternius, vérification des versions compatibles
- [x] Vérification licences (CC0 — déjà confirmé pour tous les packs identifiés)

## Jalon 1 — Forêt + Freecam ✅
- [x] `ForestScatter.gd` : placement jitter/poisson-disque des assets nature, zone d'exclusion autour du bunker
- [x] `FreecamController.gd` : caméra libre noclip (débug, conservé tout le long du projet)
- [x] Bake `NavigationServer3D` **après** le scatter
- [x] Scène de test minimale (sol + scatter + freecam)

## Jalon 2 — Bunker (scène fixe) ✅
- [x] Extérieur ET intérieur en Modular SciFi MegaKit (changement de scope :
	  Medieval Village MegaKit n'est plus utilisé pour le bunker, réservé
	  exclusivement aux futures constructions du joueur en jeu — voir STATE.md)
- [x] Scène construite à la main, pas de génération procédurale
- [x] Sol de la forêt découpé au CSG (CSGBox3D + Subtraction) pour laisser
	  un accès réel à l'escalier intérieur, plutôt qu'un sous-sol qui
	  traverse le plan de sol
- [x] Nav mesh du bunker bakée (reparenté sous le NavigationRegion3D
	  existant de la forêt)

### Dette Jalon 2
- Jointures entre pièces SciFi non scellées (pas de chevauchement appliqué
  partout) → fuites de lumière SDFGI visibles aux angles du toit, et le
  joueur peut se faufiler par endroits en poussant depuis l'extérieur.
  À corriger avant toute présentation publique de la scène.
- Plateformes du bunker sans épaisseur visuelle (le kit SciFi n'a pas de
  pièce "Bottom" pour les sols, contrairement aux murs). Solution retenue :
  socle réutilisable (BoxMesh + couleur unie) — définie mais pas encore
  généralisée à toutes les plateformes posées.

## Jalon 3 — Contrôleur protagoniste + interactions
- [x] `CharacterBody3D` + input (locomotion, caméra, franchissement de marches auto via test_move — voir player_controller.gd)
- [ ] Système d'interaction (raycast/zone), prompts world-space
- [ ] State machine d'actions (idle / récolte / construction)
- [ ] Intégration Universal Animation Library 2 (animations farming)
- [ ] Construction data-driven (.tres façon `BuildingDefs`))
- [x] Système d'outils tenus (viewmodel 1ère personne, `ToolDef` data-driven) → hache en bois fonctionnelle et calée à l'écran (`ToolController` + `ToolDef`). Reste : brancher `swing()` sur le futur système d'interaction, refaire le protocole grip + hand_position pour les 10 autres outils du pack (lance, pelle, bouclier, pioche, couteau, marteau, massue, flèche, torche, arc)

## Jalon 4 — Réveil de pawn + ordres
- [ ] Pawn dormant scripté (état sommeil → réveil via interaction joueur)
- [ ] State machine d'ordres (suivre / poste / tâche) via `NavigationAgent3D`
- [ ] Sélection de pawn (proximité ou liste rapide)
- [ ] **Dette Jalon 1** : navmesh grimpe sur les branches basses des arbres (collision arbre = mesh complet). Corriger via collision troncs simplifiée (cylindre) ou `NavigationObstacle3D` avant de tester le déplacement des pawns.

## Jalon 5 — Portage simulation temps réel
- [ ] Fatigue sur horloge continue (remplace le calcul par tour de Degel)
- [ ] Relations par accumulation de coprésence/co-tâche dans le temps
- [ ] Portage `EventConfig`/`EventManager` (turn-locking → pause ou mode décision)
- [ ] Portage `Chronicle` (journal de faits) en version temps réel

## Non planifié / idées à trier
- Terrain procédural avancé (heightmap/bruit)
- Cycle jour/nuit
- Deuxième bunker / expansion de zone
- Sous-sol du bunker (complexe cryo à grande échelle) via téléportation
  vers une scène séparée depuis le bas de l'escalier, plutôt qu'un vrai
  sous-sol connecté physiquement
