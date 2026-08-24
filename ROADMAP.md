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
- [x] Système d'interaction (raycast/zone), prompts world-space → `Interactable`/`InteractionController`/`Choppable` fonctionnels, dégâts synchronisés sur `swing_impact` (`receive_tool_hit`).
- [x] Récolte : `Choppable` fait tomber 3 `ResourcePickup` physiques à sa destruction, ramassables (E) et portables à la main via `CarryController` (`ResourceDef.CarryType.HAND`), dépose au clic E.
- [x] Sound manager de base (`autoloads/sound_manager.gd`, pool de `AudioStreamPlayer3D`) → SFX ponctuels positionnés, hook posé sur `Choppable.chop_sound` (pas encore d'asset son assigné). Pas de bus séparé ni de son UI/2D — à ajouter si besoin réel apparaît.
- [ ] State machine d'actions (idle / récolte / construction)
- [ ] Intégration Universal Animation Library 2 (animations farming) — à revalider une fois le chassis robot posé (J5)
- [x] Construction data-driven (.tres façon `BuildingDefs`))
- [x] Système d'outils tenus (viewmodel 1ère personne, `ToolDef` data-driven) → hache en bois fonctionnelle et calée à l'écran (`ToolController` + `ToolDef`). Reste : brancher `swing()` sur le futur système d'interaction, refaire le protocole grip + hand_position pour les 10 autres outils du pack (lance, pelle, bouclier, pioche, couteau, marteau, massue, flèche, torche, arc)
 
> **Dette design Jalon 3** : le protagoniste est officiellement un robot (cf. GDD). L'apparence humaine implicite du viewmodel/main tenant la hache est temporaire — le chassis robot et son bras/effecteur sont traités au Jalon 5.
### Dette Jalon 3 — construction
- `Obstacles` (layer 3) appliqué seulement sur les pièces bunker proches des zones de test, pas toute la structure (le bunker sera refait au Jalon 4/terrain, pas prioritaire).
- `Campfire.burn_duration` arbitraire, à ajuster au feeling en jeu.
- VFX flamme perfectible (particules + GradientTexture2D radiale, correct mais pas top) — à retravailler une fois qu'on aura une meilleure idée de direction artistique pour les effets, potentiellement avec un vrai asset ou une texture dédiée plutôt que 100% procédural.
- Pas de livraison par les pawns (normal, Jalon 6+).
- Pas d'UI de progression du chantier (juste le prompt "Livrer") — à voir si besoin réel apparaît.
- Emplacement des fichiers construction dans `resources/buildings/` plutôt que `entities/interactable/` (écart de convention assumé, voir STATE.md) — à corriger si ça devient gênant.

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
 
## Jalon 5 — Robot : identité, énergie, communication
> Partie « robot solo » — tout ce qui n'exige pas encore les pawns. La partie sociale (sauvetage dégressif, atelier robotique) est au Jalon 9, une fois pawns + relations disponibles.
 
- [ ] Chassis robot (visuel + rigging) remplaçant l'apparence humaine implicite du contrôleur — bras/effecteur porteur d'outils (reprend `ToolController` du Jalon 3)
- [ ] Pool énergie **local** (jauge embarquée, recharge au bunker central)
- [ ] Pool énergie **bunker global** (décrément continu, horloge de fin de partie, quasi non-rechargeable)
- [ ] Rayon d'action = énergie (calcul aller-retour + alerte visuelle avant seuil critique, pas de mur invisible)
- [ ] Roue de réaction (radial menu, touche type A/Q) : set minimal oui / non / suis-moi / reste / reprends ton activité — le ciblage pawn devient réellement utile au Jalon 6
- [ ] Bulles techniques robot (diagnostics, alertes) — pas d'émotions, marque l'altérité
 
## Jalon 6 — Réveil de pawn + ordres directs
- [ ] Pawn dormant scripté (état sommeil → réveil via interaction robot)
- [ ] `ActionStateMachine` pawn (idle / se_deplacer / tâche_courante) via `NavigationAgent3D` — prépare les états `EVALUATING`/`INTERRUPTED` utilisés au Jalon 8
- [ ] Sélection de pawn (proximité ou liste rapide) pour cibler la roue de réaction (Jalon 5)
- [ ] Ordres directs minimaux (suivre / reste / va-là) — préfigure la roue
- [ ] **Dette Jalon 1** : navmesh grimpe sur les branches basses des arbres (collision arbre = mesh complet). Corriger via collision troncs simplifiée (cylindre) ou `NavigationObstacle3D` avant de tester le déplacement des pawns.
 
## Jalon 7 — Portage simulation temps réel
- [ ] Fatigue **par catégorie d'action** (float par pawn par catégorie, decay au switch de tâche) — remplace le calcul par tour de Degel
- [ ] Relations par accumulation de coprésence/co-tâche dans le temps (nourrit le `modificateur_partenaire` du Jalon 8 et la qualité d'atelier du Jalon 9)
- [ ] Portage `EventConfig`/`EventManager` (turn-locking → pause ou mode décision)
- [ ] Portage `Chronicle` (journal de faits) en version temps réel
 
## Jalon 8 — Tableau de tâches (utility AI)
- [ ] `TaskDef` en `.tres` (type, priorité, localisation, seuil pawns requis, poids d'appétence par trait)
- [ ] UI tableau côté joueur : poster une tâche, ajuster priorités
- [ ] Boucle d'évaluation pawn au point de décision : `score = priorité × appétence(trait) × compétence × (1 - fatigue_cat) × modif_partenaire`
- [ ] États `EVALUATING`/`INTERRUPTED` dans l'`ActionStateMachine` (préparés au Jalon 6)
- [ ] **Opportunisme en chemin** : détection de proximité (`Area3D`) → réévaluation ponctuelle, switch si l'opportunité domine largement et que rien ne verrouille la tâche (ex. transport en binôme)
- [ ] Signalement : à défaut de s'arrêter, un pawn ajoute une tâche au tableau ou révèle un point d'intérêt
 
## Jalon 9 — Interactions pawn ↔ pawn & pawn ↔ robot
> Toute la couche sociale du robot atterrit ici, une fois pawns (J6) et relations (J7) disponibles.
 
- [ ] Bulles thématiques (icône) au croisement pawn/pawn et pawn/robot, générées selon l'état des deux au moment du croisement (fatigue partagée, satisfaction, tension...)
- [ ] Effets légers (micro moral, micro relation) une fois le socle validé
- [ ] Bulles "question" côté pawn répondables via la roue robot (Jalon 5) — la roue rend les bulles répondables et donc diversifiables (questions, propositions, demandes)
- [ ] Sauvetage dégressif : pawn secourt le robot à court hors périmètre, chances décroissantes avec la distance et la récidive
- [ ] Atelier "robotique low-tech" : réparation/upgrades du robot par les pawns, **qualité modulée par la relation** avec le pawn qui répare
 
## Jalon 10 — Progression tech par tags (analyse + axes)
- [ ] `TechDef` en `.tres` (`required_tags: Array[String]`, `unlocked_recipes`, `axis`) — même famille que `BuildingDefs`/`ToolDef`
- [ ] Station d'analyse au bunker : échantillon récolté → produit des **tags de propriété** persistants (ex : `hyperaccumulateur-métal`, `fibre-longue`, `fongique-structurel`, `réfractaire`, `conducteur`)
- [ ] Base de connaissance persistante (tags découverts + sources) — s'ancre sur le `Chronicle` du Jalon 7
- [ ] Sélection d'un axe de recherche par le joueur (Énergie / Construction / Agriculture-Bio / Matériaux / Gouvernance-Social) : tags suffisants → recette débloquée ; manquants → **indice de propriété**, pas d'item exact
- [ ] Archive du bunker comme ressource limitée : dégrade avant l'extinction complète (nombre de requêtes ou temps d'accès fini) → force le pivot vers la découverte empirique
 
## Jalon 11 — Ressources & recettes solarpunk (T2 → T3)
- [ ] **Phytominière** (T2) : plantes hyperaccumulatrices → cultivées, récoltées, brûlées, cendre raffinée
- [ ] **Mycoculture** dans la grotte (T2) : bassins + chambres de fermentation, mycélium comme matériau structurel, substrat = bois mort (boucle bois)
- [ ] Construction **terre crue** (pisé/torchis) + **hempcrete** (T2) — pierre en ramassage de surface uniquement
- [ ] **Biogaz/méthanisation** (T2) : digesteur communal à partir des déchets organiques
- [ ] **Four solaire concentré** (T3) : miroirs/lentilles, métallurgie douce sans électronique
- [ ] **Bioleaching** (T3) : bactéries dissolvant le métal d'une roche pauvre, bioréacteur
- [ ] Pistes T3+ à trier (bio-photovoltaïque, apiculture, culture d'algues, rouissage des fibres en rivière)
 
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
 
## Dette visuelle viewmodel (Jalon 3, à traiter plus tard)
- [ ] La hache traverse les murs/arbres quand la caméra s'en approche (le viewmodel n'a pas de traitement de profondeur séparé du monde). Piste : caméra/layer dédié au viewmodel avec son propre near/far, technique standard en FPS.
- [ ] Swing très statique, manque de "punch" (pas d'squash/stretch, pas d'anticipation, transform linéaire). Piste : easing sur le Tween (actuellement linéaire par défaut), ou anim dédiée si Universal Animation Library le permet pour un objet tenu.
- [ ] FX minimal manquant à l'impact (particules/étincelles bois, écran qui vibre légèrement) — rien pour l'instant, juste le son (Choppable.chop_sound, pas encore assigné).
- [ ] Ombre flottante de la hache (pas de corps/bras) — sera résolue par le chassis robot au Jalon 5
 
## Non planifié / idées à trier
- Cycle jour/nuit
- Deuxième bunker / expansion de zone
- Sous-sol du bunker (complexe cryo à grande échelle) via téléportation
  vers une scène séparée depuis le bas de l'escalier, plutôt qu'un vrai
  sous-sol connecté physiquement — c'est aussi là que les dormants du
  Jalon 6 sont susceptibles d'être réveillés
- Traits d'origine des pawns (CEO, gourou tech...) : reconversion progressive vs compétences ancien-monde définitivement inutiles — impact direct sur le ton (généreux vs mordant), à trancher avant Jalon 8
- Définition concrète de l'"intégrité système" du robot (équivalent moral) — à caler avant Jalon 5
 
