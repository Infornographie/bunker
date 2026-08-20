# ROADMAP — Projet Bunker (nom provisoire)

## Jalon 0 — Setup projet
- [ ] Init repo Godot 4.6+
- [ ] Structure de dossiers
- [ ] Import des packs Quaternius, vérification des versions compatibles
- [ ] Vérification licences (CC0 — déjà confirmé pour tous les packs identifiés)

## Jalon 1 — Forêt + Freecam *(prochaine étape)*
- [ ] `ForestScatter.gd` : placement jitter/poisson-disque des assets nature, zone d'exclusion autour du bunker
- [ ] `FreecamController.gd` : caméra libre noclip (débug, conservé tout le long du projet)
- [ ] Bake `NavigationServer3D` **après** le scatter
- [ ] Scène de test minimale (sol + scatter + freecam)

## Jalon 2 — Bunker (scène fixe)
- [ ] Extérieur bois/pierre (Medieval Village MegaKit)
- [ ] Intérieur modulaire sci-fi (Modular Sci-Fi MegaKit)
- [ ] Scène construite à la main, pas de génération procédurale ici

## Jalon 3 — Contrôleur protagoniste + interactions
- [ ] `CharacterBody3D` + input
- [ ] Système d'interaction (raycast/zone), prompts world-space
- [ ] State machine d'actions (idle / récolte / construction)
- [ ] Intégration Universal Animation Library 2 (animations farming)
- [ ] Construction data-driven (.tres façon `BuildingDefs`)

## Jalon 4 — Réveil de pawn + ordres
- [ ] Pawn dormant scripté (état sommeil → réveil via interaction joueur)
- [ ] State machine d'ordres (suivre / poste / tâche) via `NavigationAgent3D`
- [ ] Sélection de pawn (proximité ou liste rapide)

## Jalon 5 — Portage simulation temps réel
- [ ] Fatigue sur horloge continue (remplace le calcul par tour de Degel)
- [ ] Relations par accumulation de coprésence/co-tâche dans le temps
- [ ] Portage `EventConfig`/`EventManager` (turn-locking → pause ou mode décision)
- [ ] Portage `Chronicle` (journal de faits) en version temps réel

## Non planifié / idées à trier
- Terrain procédural avancé (heightmap/bruit)
- Cycle jour/nuit
- Deuxième bunker / expansion de zone
