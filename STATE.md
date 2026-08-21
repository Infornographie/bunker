# STATE — Projet Bunker (nom provisoire)

## État au 21/08/2026

- Jalon 0 (setup) : projet créé (Godot 4.7.2, renderer Forward+), Stylized
  Nature MegaKit + Modular SciFi MegaKit importés (GLTF + Textures)
- Jalon 1 (forêt + freecam) : terminé
- Jalon 2 (bunker) : terminé — structure SciFi, sol troué au CSG, éclairage
  fonctionnel (recette SpotLight + lumière de remplissage), nav mesh bakée
- Jalon 3 (contrôleur protagoniste) : en cours — locomotion + caméra +
  franchissement de marches automatique en place, reste interaction/state
  machine/animations/construction

## Décisions verrouillées

- **Architecture projet** : organisation par feature/domaine (`entities/`, `world/`, `debug/`, `autoloads/`, `resources/`), pas de séparation par type de fichier (scenes/ vs scripts/) — scène et script d'une même feature restent côte à côte
- **Contrôle des pawns réveillés** : le joueur reste seul personnage jouable, donne des ordres (pas de switch de personnage incarné)
- **Assets** : écosystème Quaternius (CC0) — Stylized Nature MegaKit, Modular Sci-Fi MegaKit, Medieval Village MegaKit, Universal Animation Library 1 & 2, personnages Ultimate Modular (Patreon)
- **Génération de forêt** : scatter procédural sur zone fixe autour du bunker ; pas de terrain généré (heightmap/bruit) au MVP
- **Bunker** : scène fixe construite à la main, pas procédurale
- **Rôle des kits pour le bunker** : Modular SciFi MegaKit couvre l'extérieur ET l'intérieur du bunker (changement par rapport au GDD d'origine). Medieval Village MegaKit n'est plus lié au bunker, réservé entièrement aux futures constructions du joueur en cours de partie.
- **Sol/terrain** : découpe locale au CSG (CSGBox3D Subtraction) autorisée pour des besoins ponctuels comme l'accès au bunker — ne contredit pas le "hors scope" du GDD, qui vise le terrain procédural (heightmap/bruit), pas une découpe manuelle fixe.
- **Joueur** : pas de saut au MVP, mais franchissement automatique de marches basses (step_height 0.35m, ajustable) via test_move dans player_controller.gd.
- **Debug** : bascule caméra joueur ↔ freecam sur la touche F7 (debug_camera_switch.gd), utile pour inspecter la scène en jeu sans repasser par l'éditeur.

## Décisions en attente

- Nom définitif du projet
- Paramètres précis du scatter (densité par type d'asset, taille de zone, règles d'exclusion) — à trancher à l'implémentation du Jalon 1

## Notes libres

- Projet indépendant, inspiré de Degel mais sans reprendre son contenu narratif/thématique
- Point de vigilance personnel identifié : la lisibilité/qualité visuelle est un facteur de motivation important — d'où le choix d'un unique écosystème d'assets cohérent (Quaternius) plutôt que du mix-and-match
