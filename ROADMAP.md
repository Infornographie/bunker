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
### Dette Jalon 1
- Navmesh grimpe sur les branches basses des arbres (collision arbre = mesh complet) — sans conséquence tant qu'aucun agent ne s'y déplace. À corriger avant le déplacement des pawns (Jalon 5) : collision troncs simplifiée (cylindre) ou `NavigationObstacle3D`.
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
## Jalon 3 — Contrôleur protagoniste + interactions ✅
- [x] `CharacterBody3D` + input (locomotion, caméra, franchissement de marches auto via test_move — voir player_controller.gd)
- [x] Système d'interaction (raycast/zone), prompts world-space → `Interactable`/`InteractionController`/`Choppable` fonctionnels, dégâts synchronisés sur `swing_impact` (`receive_tool_hit`).
- [x] Récolte : `Choppable` fait tomber 3 `ResourcePickup` physiques à sa destruction, ramassables (E) et portables à la main via `CarryController` (`ResourceDef.CarryType.HAND`), dépose au clic E.
- [x] Sound manager de base (`autoloads/sound_manager.gd`, pool de `AudioStreamPlayer3D`) → SFX ponctuels positionnés, hook posé sur `Choppable.chop_sound` (pas encore d'asset son assigné). Pas de bus séparé ni de son UI/2D — à ajouter si besoin réel apparaît.
- [x] Système d'outils tenus (viewmodel 1ère personne, `ToolDef` data-driven) → hache en bois fonctionnelle et calée à l'écran (`ToolController` + `ToolDef`).
- [x] Construction data-driven (.tres façon `BuildingDefs`) — blueprint au sol, détection de collision, livraison physique des matériaux, premier bâtiment fonctionnel (feu de camp).
- [x] Ceinture d'outils (2 slots, hanche G/D, barre 1-2, accès direct)
- [x] Poches (3 slots, G/D/avant, barre 3-5, accès direct)
- [x] Sac à dos (9 slots, remplissage auto au ramassage, accès uniquement posé au sol façon Peak)
- [x] Extension de `CarryController` en mécanisme main transversal
- [x] Course (sprint, Shift, ×1.6, kick de FOV) et saut (Espace, coyote time) — bridés quand les mains portent un objet lourd
- [x] Recette de cuisson (champi cru → grillé) via un `RecipeDef` générique (.tres — inputs/output/durée) branché sur le feu de camp existant
> **Repoussé, non bloquant pour la clôture J3** (à reprendre sans urgence) :
> - Grips + hand_position pour les 10 autres outils du pack (lance, pelle, bouclier, pioche, couteau, marteau, massue, flèche, torche, arc)
> - Intégration Universal Animation Library 2 — de toute façon à revalider au chassis robot (J5)
 
### Dette Jalon 3
- Le protagoniste est officiellement un robot (cf. GDD) : l'apparence humaine implicite du viewmodel/main tenant la hache est temporaire — chassis robot + bras/effecteur traités au Jalon 6.
- **Pas de menu de sélection de bâtiment** : `BuildModeController` expose un unique `building_def` à l'inspecteur. Tant qu'il n'y a qu'un bâtiment (feu de camp), ça ne se voit pas ; le menu devient nécessaire au deuxième `BuildingDef`. À traiter au Jalon 11 (ressources & recettes solarpunk) au plus tard, ou dès qu'un deuxième bâtiment arrive.
- Physique des rondins pas réglée (friction/rebond par défaut, roulis parfois excessif) — à ajuster via Physics Material sur le RigidBody3D.
- Objet porté en main pas contraint en taille/collision au HandAnchor — un futur objet plus gros qu'un rondin pourrait traverser le viewmodel ou sortir du champ visuel — à surveiller au cas par cas.
- La hache traverse les murs/arbres quand la caméra s'en approche (viewmodel sans profondeur séparée du monde). Piste : caméra/layer dédié au viewmodel avec son propre near/far.
- Swing statique, manque de "punch" (pas de squash/stretch, transform linéaire). Piste : easing sur le Tween, ou anim dédiée si Universal Animation Library le permet.
- FX minimal manquant à l'impact (particules bois, léger shake caméra) — rien pour l'instant, juste le son non assigné.
- Ombre flottante de la hache (pas de bras) — résolue par le chassis robot au Jalon 6.
- Course/saut gratuits pour l'instant (pas de coût) alors que le GDD prévoit que toute action du robot passe par l'énergie — à rattacher au pool d'énergie local du Jalon 6.
- Feeling course/saut non réglé (valeurs de départ posées à l'inspecteur : ×1.6, jump 4.5, coyote 0.12, FOV +8). Passe de réglage à faire au moment du chassis robot (Jalon 6), quand la silhouette et l'échelle réelle du protagoniste seront fixées.
- Pas de head bob ni de son de pas — la course se lit surtout au FOV. À traiter avec le FX/audio général.
- ToolPickup posé au sol : collision BoxShape3D générique (pas calée au mesh réel), pas de rotation couchée au drop (la hache se plante debout). À ajuster quand on aura plus d'outils à tester.
- Poches et sac à dos : `BackpackData` et routage SMALL/TOOL prêts dans le code, mais pas testables faute d'objets petits et de sac physique — à valider avec le premier petit objet (champignon, Passe B).
- Icônes générées au premier affichage : léger hoquet possible à la première ouverture d'un sac contenant des objets jamais vus. Acceptable pour l'instant ; si ça devient visible, pré-générer au chargement de la partie.
- UI du sac : polish restant (position du panneau parfois haute selon l'angle, pas de feedback sonore au transfert, pas d'animation d'ouverture).
- Grille 3x3 = 9 slots au lieu des 10 annoncés au GDD — GDD à mettre à jour (9 + 3 poches = 12, plus cohérent).
- Prompt d'interaction non contextuel : `_refresh_prompt()` affiche le `prompt_key` de la cible sans tenir compte de la ressource proposée (le feu dit "Alimenter" même avec un champi en poche prêt à cuire). À régler avec le panneau de cuisson (J3.6).
- `grilled_mushroom` = champi cru avec albedo teinté brun. Asset dédié à faire, aucune urgence.
- `Choppable.pickup_scene` : seul endroit du projet où une scène de pickup est référencée en direct plutôt que résolue par `ResourceRegistry` depuis un `ResourceDef`. Deux façons d'obtenir un pickup selon l'appelant. Correction ~5 min, à faire au prochain passage sur `Choppable`.
- Cuisson : une recette à la fois, pas de brûlé si on oublie, ingrédients non visibles sur les braises. Assumé tant que le feu est le seul site de transformation.
## Jalon 3.5 — Localisation (infrastructure L10N) ✅
> Petit jalon transverse posé avant J4 : mettre en place la l10n maintenant coûte 30 min, l'ajouter après 6 mois de strings hardcodées coûte des heures. Décision : dev en **anglais** (langue source, garantit des clés stables si le texte évolue) et **français** disponible dès maintenant pour permettre les playtests du fils d'Anthony.
 
- [x] `translations/strings.csv` — première colonne = clé, colonnes `en`, `fr`. Godot compile automatiquement en `.translation` à l'import. Rangé en sections (ligne à première colonne vide = ignorée à l'import), alphabétique à l'intérieur.
- [x] Convention de clés : `namespace.section.key` (ex : `interact.prompt.chop`, `resource.wood.name`)
- [x] Autoload `Locale` (`autoloads/locale.gd`) — wrapper `TranslationServer` : `get_locale()`, `set_locale()`, signal `locale_changed`, fallback `en`
- [x] Migration des strings existants vers clés + `tr()` : `Interactable.prompt_text` → `prompt_key`, `display_name` → `name_key` sur `ResourceDef`/`ToolDef`/`BuildingDef`/`RecipeDef`
- [x] Le `tr()` centralisé sur quatre points d'affichage seulement (voir STRUCTURE §Flux de localisation) — pas de helper intermédiaire
- [x] Clés de cache d'icônes rebasées sur `ToolDef.id`/`ResourceDef.id` au lieu du nom affiché (corrige au passage la collision entre deux outils homonymes)
- [x] Bascule debug EN ↔ FR sur **F10** (`toggle_locale`) — F8 et F9 écartés, réservées à l'éditeur en fenêtre embarquée
- [x] Project settings : `internationalization/locale/fallback = en`
- [x] Mise à jour docs à la clôture : INPUTS.md, STRUCTURE.md, STATE.md
> Deux migrations manquées, détectées et corrigées au J3.6 : `BackpackSlot.set_content()` lisait encore `resource.display_name` (propriété supprimée), et `InteractionController._refresh_prompt()` passait la string "Déposer" en dur à `tr()` (désormais `interact.prompt.drop`).
 
### Dette Jalon 3.5
- Format `.po` (gettext, standard pour LQA externe) pas retenu — CSV suffit pour un dev solo avec peu de strings. À revoir si un jour on veut envoyer à un traducteur pro.
- Pas de gestion de la pluralisation ni des accords genre à ce stade — à ajouter au premier besoin réel (aucune string avec `%d truc(s)` aujourd'hui).
- **Aucune vérification qu'une clé utilisée existe dans le CSV** : `tr()` sur une clé absente affiche la clé brute à l'écran, sans erreur ni warning. Pas gênant à 13 clés (ça se voit immédiatement en jeu), à revoir si le volume grossit — piste : petit script d'éditeur qui croise les `tr(...)`/`_key` du projet avec les colonnes du CSV.
## Jalon 3.6 — Panneau de cuisson
> Posé après la l10n : une UI neuve écrite avant les clés de traduction, c'est des strings à remigrer aussitôt. Toute string ajoutée ici passe directement par `strings.csv`.
- [x] **Passe A** — `ItemSlot` et `WorldAnchoredPanel` extraits de `BackpackUI`, plus `UIPanelController` : l'arbitre de modes annoncé dans STATE. Comportement du sac inchangé, vérifié en jeu.
- [ ] Panneau feu : liste des recettes à gauche, slots d'ingrédients au centre avec fantôme de l'attendu
- [ ] Barre de progression de cuisson (`TransformationSite.get_progress()`) et jauge de combustible (`Campfire.get_fuel_ratio()`)
- [ ] Case combustible en lecture seule, drag-to-alimenter en option
- [ ] Drag d'un panneau à l'autre (sac posé → feu), rendu possible par le choix « exclusivité entre modes, pas entre panneaux »
- [ ] Prompt contextuel selon la ressource proposée (dette J3) : E dépose si le joueur propose une ressource acceptée, ouvre le panneau sinon
- [ ] Supprimer l'action morte `cancel_build_mode` (dette J3, voir ci-dessous) — **à faire après vérification en jeu** du comportement réel de B en mode construction
- [ ] Nettoyage au passage : `print()` de debug oublié dans `Campfire.receive_resource()`, et `Choppable.pickup_scene` → `ResourceRegistry` (dette J3)
### Dette Jalon 3.6
- `cancel_build_mode` : action de l'Input Map bindée sur **B**, jamais atteinte. `BuildModeController._unhandled_input()` teste `toggle_build_mode` en premier et fait un `return` inconditionnel, donc la branche `cancel_build_mode` est du code mort et B ne ferme le mode que via le toggle. Correction : supprimer la branche + l'action dans l'Input Map (~2 min). Détectée au sanity check pré-J3.5 ; report volontaire pour tester le comportement en jeu avant de toucher au code.
- Fermeture d'un panneau ancré : seules la distance, la destruction de la cible et le passage derrière la caméra ferment. Pas de fermeture à l'angle (se détourner sans s'éloigner laisse le panneau ouvert sur le bord de l'écran). À trancher au feeling une fois deux panneaux ouvrables côte à côte.
- `UIPanelController` gèle le joueur dès qu'un panneau est ouvert. Acceptable pour le sac posé ; à réévaluer si un panneau doit rester lisible pendant qu'on bouge.
## Jalon 4 — Terrain procédural
- [ ] `terrain_gen_config.gd` (Resource) : seed, taille de zone, refs `FastNoiseLite` par couche, rayon/falloff bunker partagé (flatten + exclusion scatter)
- [ ] `heightmap_generator.gd` : bruit macro → masque relief → ridge noise (escarpement) → domain warp → flatten bunker → tracé + creusement rivière
- [ ] `biome_map_generator.gd` : carte de pente (exposition solaire + zones cultivables), carte d'humidité (biome marais), masque sol métallifère (filtré par pente faible) — séparé du relief, ne recalcule rien de déjà calculé
- [ ] `terrain_mesh_builder.gd` : hauteurs → `ArrayMesh`/`SurfaceTool` + `HeightMapShape3D` à partir du même tableau de hauteurs (pas de double source)
- [ ] `terrain_controller.gd` : orchestrateur, ordre de génération, seul point d'entrée de la scène
- [ ] Bake `NavigationRegion3D` après le mesh (même contrainte d'ordre que Jalon 1)
- [ ] `ForestScatter.gd` étendu pour lire les cartes de biome/pente/humidité plutôt que la seule zone d'exclusion codée en dur (dette Jalon 1 à traiter ici) ; les biomes doivent porter les tags exploités au Jalon 10
- [ ] Grotte d'entrée : feature fixe intégrée au masque relief + scène séparée modulaire (mycoculture, Jalon 11) reliée par téléportation, même principe que le sous-sol bunker
### Dette anticipée Jalon 4
- Perf de génération à valider en pratique (plusieurs étapes empilées au chargement) — piste si besoin : `WorkerThreadPool` ou split sur plusieurs frames, pas un problème tant que non mesuré.
- Résolution/taille de zone (300-500m, pas 1-2m envisagés) à confirmer par un premier test en jeu plutôt qu'en théorie.
- Le step-up et le saut sont calibrés sur du sol plat/marches SciFi : à revalider sur terrain irrégulier (pentes, rives de rivière) une fois la heightmap en place.
## Jalon 5 — Réveil de pawn + ordres directs
- [ ] Pawn dormant scripté (état sommeil → réveil via interaction robot)
- [ ] `ActionStateMachine` pawn (idle / se_deplacer / tâche_courante) via `NavigationAgent3D` — prépare les états `EVALUATING`/`INTERRUPTED` utilisés au Jalon 8
- [ ] Sélection de pawn (proximité ou liste rapide) — réutilisée par la roue de réaction au Jalon 6, et à déclarer dans `UIPanelController.exclusive_modes`
- [ ] Ordres directs minimaux (suivre / reste / va-là) — préfigure la roue
- [ ] Corriger dette Jalon 1 (navmesh/branches, cf. section dédiée) avant de tester le déplacement des pawns
## Jalon 6 — Robot : identité, énergie, communication
> Chassis, énergie et communication du robot, maintenant testables contre de vrais pawns plutôt qu'en solo. La partie sociale (sauvetage dégressif, atelier robotique) reste au Jalon 9, une fois les relations disponibles (J7).
 
- [ ] Chassis robot (visuel + rigging) remplaçant l'apparence humaine implicite du contrôleur — bras/effecteur porteur d'outils (reprend `ToolController` du Jalon 3)
- [ ] Pool énergie **local** (jauge embarquée, recharge au bunker central) — inclut le coût de course/saut posé en dette Jalon 3
- [ ] Passe de réglage du feeling course/saut sur le chassis robot définitif (dette Jalon 3)
- [ ] Pool énergie **bunker global** (décrément continu, horloge de fin de partie, quasi non-rechargeable)
- [ ] Rayon d'action = énergie (calcul aller-retour + alerte visuelle avant seuil critique, pas de mur invisible)
- [ ] Roue de réaction (radial menu, touche type A/Q) : set minimal oui / non / suis-moi / reste / reprends ton activité — réutilise la sélection de pawn du Jalon 5, et se déclare dans `UIPanelController.exclusive_modes`
- [ ] Bulles techniques robot (diagnostics, alertes) — pas d'émotions, marque l'altérité
## Jalon 7 — Portage simulation temps réel
- [ ] Fatigue **par catégorie d'action** (float par pawn par catégorie, decay au switch de tâche) — remplace le calcul par tour de Degel
- [ ] Relations par accumulation de coprésence/co-tâche dans le temps (nourrit le `modificateur_partenaire` du Jalon 8 et la qualité d'atelier du Jalon 9)
- [ ] Portage `EventConfig`/`EventManager` (turn-locking → pause ou mode décision)
- [ ] Portage `Chronicle` (journal de faits) en version temps réel
## Jalon 8 — Tableau de tâches (utility AI)
- [ ] `TaskDef` en `.tres` (type, priorité, localisation, seuil pawns requis, poids d'appétence par trait)
- [ ] UI tableau côté joueur : poster une tâche, ajuster priorités
- [ ] Boucle d'évaluation pawn au point de décision : `score = priorité × appétence(trait) × compétence × (1 - fatigue_cat) × modif_partenaire`
- [ ] États `EVALUATING`/`INTERRUPTED` dans l'`ActionStateMachine` (préparés au Jalon 5)
- [ ] **Opportunisme en chemin** : détection de proximité (`Area3D`) → réévaluation ponctuelle, switch si l'opportunité domine largement et que rien ne verrouille la tâche (ex. transport en binôme)
- [ ] Signalement : à défaut de s'arrêter, un pawn ajoute une tâche au tableau ou révèle un point d'intérêt
## Jalon 9 — Interactions pawn ↔ pawn & pawn ↔ robot
> Toute la couche sociale du robot atterrit ici, une fois pawns (J5) et relations (J7) disponibles.
 
- [ ] Bulles thématiques (icône) au croisement pawn/pawn et pawn/robot, générées selon l'état des deux au moment du croisement (fatigue partagée, satisfaction, tension...)
- [ ] Effets légers (micro moral, micro relation) une fois le socle validé
- [ ] Bulles "question" côté pawn répondables via la roue robot (Jalon 6) — la roue rend les bulles répondables et donc diversifiables (questions, propositions, demandes)
- [ ] Sauvetage dégressif : pawn secourt le robot à court hors périmètre, chances décroissantes avec la distance et la récidive
- [ ] Atelier "robotique low-tech" : réparation/upgrades du robot par les pawns, **qualité modulée par la relation** avec le pawn qui répare
## Jalon 10 — Progression tech par tags (analyse + axes)
- [ ] `TechDef` en `.tres` (`required_tags: Array[String]`, `unlocked_recipes`, `axis`) — même famille que `BuildingDefs`/`ToolDef`
- [ ] Station d'analyse au bunker : échantillon récolté → produit des **tags de propriété** persistants (ex : `hyperaccumulateur-métal`, `fibre-longue`, `fongique-structurel`, `réfractaire`, `conducteur`)
- [ ] Base de connaissance persistante (tags découverts + sources) — s'ancre sur le `Chronicle` du Jalon 7
- [ ] Sélection d'un axe de recherche par le joueur (Énergie / Construction / Agriculture-Bio / Matériaux / Gouvernance-Social) : tags suffisants → recette débloquée ; manquants → **indice de propriété**, pas d'item exact
- [ ] Archive du bunker comme ressource limitée : dégrade avant l'extinction complète (nombre de requêtes ou temps d'accès fini) → force le pivot vers la découverte empirique
## Jalon 11 — Ressources & recettes solarpunk (T2 → T3)
- [ ] Menu de sélection de bâtiment en mode construction (dette Jalon 3) — indispensable dès le deuxième `BuildingDef`
- [ ] **Phytominière** (T2) : plantes hyperaccumulatrices → cultivées, récoltées, brûlées, cendre raffinée
- [ ] **Mycoculture** dans la grotte (T2) : bassins + chambres de fermentation, mycélium comme matériau structurel, substrat = bois mort (boucle bois)
- [ ] Construction **terre crue** (pisé/torchis) + **hempcrete** (T2) — pierre en ramassage de surface uniquement
- [ ] **Biogaz/méthanisation** (T2) : digesteur communal à partir des déchets organiques
- [ ] **Four solaire concentré** (T3) : miroirs/lentilles, métallurgie douce sans électronique
- [ ] **Bioleaching** (T3) : bactéries dissolvant le métal d'une roche pauvre, bioréacteur
## Jalon 12 — Bascule écologique & démocratique
- [ ] Métrique de dégradation d'écosystème liée à l'exploitation T1 (extraction/métallurgie classique)
- [ ] Effets visibles progressifs : faune dangereuse, maladies, autres (à définir)
- [ ] Event de gouvernance déclenché par seuil de dégradation (via `EventManager` porté au Jalon 7)
- [ ] Réunion des pawns + **système de vote** pondéré par convictions/vécu de chaque pawn — détail à travailler en session dédiée
- [ ] "Lois" votées qui modifient des paramètres colonie (priorités par défaut, tâches interdites/encouragées)
- [ ] Déblocage effectif du palier solarpunk après le vote (bouclage avec Jalon 11)
- [ ] Passage progressif du tableau piloté-joueur → réajustement colonie (seuil pawns × relation moyenne) — écho au twist narratif
## Jalon 13 — Expéditions & fins
- [ ] Système d'expédition hors rayon robot : contrôle totalement délégué au groupe parti (le robot ne peut pas les rejoindre)
- [ ] Objectifs typiques : souche/population absente localement, autre communauté de survivants (diplomatie/échange de savoir), zone écologique différente pour tags inaccessibles
- [ ] Résolution en tâche longue avec risque réel (pas de secours possible)
- [ ] Trois branches de fin :
  - **Fin standard** — shutdown du bunker atteint, bilan des pawns sauvés
  - **Game over anticipé** — robot perdu hors périmètre, non secouru
  - **Bonne fin — robot éternel** — tous les dormants sauvés, choix : couper le bunker et rediriger l'énergie restante vers le robot (variantes lié-mortel / isolé-éternel à travailler, pas un binaire bien/mal)
## Features non planifiées
- Cycle jour/nuit
- Deuxième bunker / expansion de zone
- Sous-sol du bunker (complexe cryo à grande échelle) via téléportation
  vers une scène séparée depuis le bas de l'escalier, plutôt qu'un vrai
  sous-sol connecté physiquement — c'est aussi là que les dormants du
  Jalon 5 sont susceptibles d'être réveillés
- Pistes solarpunk T3+ à préciser (bio-photovoltaïque, apiculture, culture d'algues, rouissage des fibres en rivière)
- Langues supplémentaires (au-delà de EN/FR) — à déclencher si un besoin réel apparaît, l'infrastructure J3.5 est prête pour n'importe quelle colonne CSV en plus
## Décisions à trancher (avec jalon cible)
 
- **Avant Jalon 6** — Définition concrète de l'"intégrité système" du robot (équivalent moral)
- **Avant Jalon 8** — Traits d'origine des pawns (CEO, gourou tech...) : reconversion progressive vs compétences ancien-monde définitivement inutiles — impact direct sur le ton (généreux vs mordant)
- **Avant Jalon 9** — Règles précises du sauvetage dégressif (distances, probabilités, cooldown de récidive)
- **Avant Jalon 12** — Modalités exactes de la transition d'autonomie politique (seuils, déclencheurs, réversibilité)
- **Avant Jalon 12** — Système de vote / gouvernance : détail à travailler en session dédiée