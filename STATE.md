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
- **Import outils FBX (pack low poly CC0)** : le pivot natif du FBX n'est pas exploitable tel quel (posé au sol / à un point arbitraire de l'artiste). Protocole retenu : wrapper `Node3D` vide en racine (ex: `AxeGrip`) contenant l'instance FBX ; on ne déplace **jamais** le `MeshInstance3D` importé (rotation -90° bakée par l'import, un drag dessus part n'importe où) — on déplace uniquement son parent direct (le root de l'instance FBX, sans rotation) jusqu'à ce que l'origine du wrapper tombe sur le point de préhension. Scène sauvegardée : `wooden_axe_grip.tscn`, offset retenu `y = -0.4` sur le node racine. Probablement réutilisable pour les outils de forme similaire (manche + tête), à revérifier un par un pour les autres.
- **Réglage du viewmodel (position/rotation à l'écran)** : toujours régler `hand_position` / `hand_rotation_degrees` sur le `ToolDef` (.tres), jamais la Transform du `ToolController` lui-même — ce dernier doit rester à l'identité (0,0,0), c'est un composant neutre partagé par tous les outils. Méthode pratique : ajuster en live sur l'instance spawnée (onglet Remote pendant le runtime, ou directement le node du .tres en écran splitté), puis reporter les valeurs finales dans le .tres. Piège rencontré : un réglage fait par erreur sur le ToolController plutôt que sur l'instance se sauvegarde silencieusement dans la scène et s'additionne au hand_position → deux sources de vérité qui divergent. Hache en bois : hand_position = (0.41, -0.565, -0.47), hand_rotation_degrees = (0, -96, 15).

## Décisions en attente

- Nom définitif du projet
- Paramètres précis du scatter (densité par type d'asset, taille de zone, règles d'exclusion) — à trancher à l'implémentation du Jalon 1

## Notes libres

- Projet indépendant, inspiré de Degel mais sans reprendre son contenu narratif/thématique
- Point de vigilance personnel identifié : la lisibilité/qualité visuelle est un facteur de motivation important — d'où le choix d'un unique écosystème d'assets cohérent (Quaternius) plutôt que du mix-and-match
