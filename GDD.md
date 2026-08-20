# [Nom provisoire] — Game Design Document

> Nom de travail utilisé dans ces docs : **Projet Bunker**. À renommer dès que tu as une idée.

## Pitch

Reprise du concept de gestion de colonie de **Degel**, transposée en vue première personne, low poly / cosy. Un protagoniste isolé développe un bunker caché en pleine forêt, farm et construit, puis réveille progressivement des colons ("pawns") trouvés en dormance à proximité, qu'il dirige façon jeu de gestion de base — sans jamais les incarner directement.

## Piliers

- **Vue incarnée, temps réel** — rupture avec le tour par tour de Degel.
- **Un seul perso jouable** — les pawns réveillés reçoivent des ordres, ne sont jamais contrôlés directement.
- **Systèmes hérités de Degel** (fatigue, relations, events narratifs) recâblés sur une horloge temps réel plutôt que sur des tours.
- **Forêt générée** autour d'un bunker fixe — sinon pas d'intérêt technique/ludique au projet.
- **Low poly / cosy** — lisibilité avant tout, cohérence visuelle assurée par un unique écosystème d'assets (Quaternius).

## Boucle de gameplay (MVP)

1. Explorer/récolter dans la forêt générée.
2. Construire/améliorer le bunker.
3. Trouver et réveiller un pawn en dormance.
4. Lui donner des ordres (récolte, poste de travail, tâche).
5. Fatigue s'accumule avec l'activité → repos nécessaire.
6. Relations émergent entre pawns qui travaillent ensemble.
7. Petits events déclenchés par le contexte de jeu (façon Chronicle de Degel).

## Stack / outils

- **Moteur** : Godot 4.6+, GDScript (cohérence avec Degel et Knighthood Survivor)
- **Assets** (tous CC0, Quaternius) :
  - Stylized Nature MegaKit (forêt)
  - Modular Sci-Fi MegaKit (intérieur bunker)
  - Medieval Village MegaKit (extérieur bunker, bois/pierre)
  - Universal Animation Library 1 & 2 (locomotion, combat, farming)
  - Personnages Ultimate Modular (Patreon)

## Hors scope MVP

- Génération de terrain procédural complexe (heightmap/bruit) — la forêt MVP repose sur un scatter procédural, pas un terrain généré.
- Plusieurs bunkers / expansion de zone.
- Combat.
- Cycle jour/nuit avancé.
- Multijoueur.

## Notes d'architecture (héritées des autres projets)

- Approche data-driven pour les définitions (bâtiments, ressources) via des `Resource` (.tres), comme `BuildingDefs`/`ResourceDefs` dans Projet Isekai et `game_registry.tres` dans Degel.
- `Chronicle` (journal de faits structuré) de Degel à réadapter pour fonctionner en continu plutôt que par snapshot de tour.
- `EventConfig`/`EventManager` de Degel probablement réutilisables presque tels quels (déjà déclenchés par condition) — seul le "turn-locking" doit devenir une vraie pause / mode décision en temps réel.
- Singleton `GameState` façon Knighthood Survivor comme source de vérité globale.
