# STATE — Projet Bunker (nom provisoire)

## État au 24/08/2026

- Jalon 0 (setup) : projet créé (Godot 4.7.2, renderer Forward+), Stylized Nature MegaKit + Modular SciFi MegaKit importés (GLTF + Textures)
- Jalon 1 (forêt + freecam) : terminé
- Jalon 2 (bunker) : terminé — structure SciFi, sol troué au CSG, éclairage fonctionnel (recette SpotLight + lumière de remplissage), nav mesh bakée
- Jalon 3 (contrôleur protagoniste) : en cours — locomotion + caméra + franchissement de marches automatique en place ; hache viewmodel fonctionnelle ; système d'interaction générique (`Interactable` + `InteractionController`) en place avec première classe fille (`Choppable`, récolte d'arbre) ; `ActionStateMachine` ajoutée (états `IDLE`/`USING_TOOL`), synchronise dégâts sur `swing_impact` ; reste animations et construction

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
- **Swing animation** : deux bugs identifiés et corrigés successivement. (1) `rotated_local()` tournait autour de l'axe déjà réorienté par `hand_rotation_degrees`, rendant le mouvement quasi invisible. (2) Le remplacement par `rotated()` faisait aussi tourner l'origine autour du pivot du parent (caméra), envoyant la hache derrière la caméra pendant le swing. Fix final : rotation appliquée uniquement au basis (`Basis(axis, angle) * rest_transform.basis`), origine gérée séparément avec un `strike_offset` explicite (avant-bas) pour donner l'impression d'un coup porté. Angle/offset toujours à valider/ajuster visuellement, pas figé.
- **Prompt d'interaction persistant après destruction de la cible** : `is_instance_valid()` ne suffit pas juste après `queue_free()` (destruction différée en fin de frame). Fix : écoute du signal natif `tree_exiting` sur la cible courante, qui déclenche l'effacement du prompt au bon moment peu importe la cause de la destruction.
- **State machine d'actions** : `ActionStateMachine`, sibling de `ToolController`/`InteractionController` sous `Camera3D`. Rôle : arbitrer si une action peut démarrer et orchestrer le timing swing→impact→effet via un `Callable` passé par l'`Interactable` cible (`use_tool_on(target, on_impact)`). `Choppable.interact()` ne fait plus l'effet direct : il délègue à la state machine, qui n'exécute l'effet qu'au signal `swing_impact` et seulement si la cible est encore valide. `BUILDING` réservé en commentaire dans l'enum, non codé.
- **Structure de fichiers** : revue et nettoyée (24/08/2026) — fusion `entities/world/forest` dans `entities/interactable/forest/` (instances) + `world/forest/` (scène de niveau), renommage `FreecamController.gd`/`ForestScatter.gd`/`test exterior.tscn` en snake_case, suppression des dossiers vides `entities/pawn/` et `ui/` (à recréer aux Jalons 6 et 8). Carte de référence détaillée dans `STRUCTURE.md` à la racine, à tenir à jour à chaque changement d'arborescence.

## Décisions en attente

- Nom définitif du projet
- Paramètres précis du scatter (densité par type d'asset, taille de zone, règles d'exclusion) — à trancher à l'implémentation du Jalon 1

## Notes libres

- Projet indépendant, inspiré de Degel mais sans reprendre son contenu narratif/thématique
- Point de vigilance personnel identifié : la lisibilité/qualité visuelle est un facteur de motivation important — d'où le choix d'un unique écosystème d'assets cohérent (Quaternius) plutôt que du mix-and-match
- **`Interactable` (PhysicsBody3D) → accès membres RigidBody3D** : un cast/test de type direct (`as RigidBody3D` ou `is RigidBody3D` sur `self`) échoue à la compilation dans une classe fille comme `ResourcePickup`, car l'analyse statique de GDScript voit son type déclaré (héritant de `PhysicsBody3D`) comme non lié à `RigidBody3D`. Fix : repasser par une variable typée `Node` avant le test (`var node: Node = self; if node is RigidBody3D:`), qui échappe au typage statique et vérifie le vrai type à l'exécution. Accès aux membres ensuite via `set(...)`/`call(...)` en dynamique.
