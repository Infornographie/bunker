# ROADMAP — Projet Bunker (nom provisoire)
 
## Jalon 0 — Setup projet
- [x] Init repo Godot 4.7.2
- [x] Structure de dossiers
- [x] Import des packs Quaternius, vérification des versions compatibles
- [x] Vérification licences (CC0 — déjà confirmé pour tous les packs identifiés)
## Jalon 1 — Forêt + Freecam ✅
- [x] `ForestScatter.gd` : placement jitter/poisson-disque des assets nature, zone d'exclusion autour du bunker
- [x] `FreecamController.gd` : caméra libre noclip (débug) — remplacé au Jalon 4 par un mode vol intégré à `PlayerController` (`toggle_flight_mode`, F11) ; `FreecamController`/`DebugCameraSwitch` supprimés
- [x] Bake `NavigationServer3D` **après** le scatter
- [x] Scène de test minimale (sol + scatter + freecam)
### Dette Jalon 1
- Navmesh grimpe sur les branches basses des arbres (collision arbre = mesh complet) — sans conséquence tant qu'aucun agent ne s'y déplace. À corriger avant le déplacement des pawns (Jalon 5) : collision troncs simplifiée (cylindre) ou `NavigationObstacle3D`.
## Jalon 2 — Bunker (scène fixe) ✅
- [x] Extérieur ET intérieur en Modular SciFi MegaKit
- [x] Scène construite à la main, pas de génération procédurale
- [x] Sol de la forêt découpé au CSG pour laisser un accès réel à l'escalier intérieur
- [x] Nav mesh du bunker bakée
> **Périmé par le Jalon 4.** `bunker_exterior_test.tscn` a été construit sur un sol plat ; le terrain procédural fournit désormais un site de grotte à l'origine du monde, et le bunker sera rebâti là. La scène actuelle sert de réserve de pièces, pas de livrable.
### Dette Jalon 2
- Jointures entre pièces SciFi non scellées → fuites de lumière SDFGI aux angles du toit, et le joueur peut se faufiler par endroits. À corriger avant toute présentation publique de la scène.
- Plateformes du bunker sans épaisseur visuelle (le kit SciFi n'a pas de pièce "Bottom" pour les sols). Solution retenue : socle réutilisable (BoxMesh + couleur unie) — définie mais pas généralisée.
## Jalon 3 — Contrôleur protagoniste + interactions ✅
- [x] `CharacterBody3D` + input (locomotion, caméra, franchissement de marches auto via test_move)
- [x] Système d'interaction (raycast/zone), prompts world-space → `Interactable`/`InteractionController`/`Choppable`, dégâts synchronisés sur `swing_impact`
- [x] Récolte : `Choppable` fait tomber 3 `ResourcePickup` physiques, ramassables (E) et portables via `CarryController`
- [x] Sound manager de base (`autoloads/sound_manager.gd`) → SFX ponctuels positionnés, hook posé sur `Choppable.chop_sound`
- [x] Système d'outils tenus (viewmodel 1ère personne, `ToolDef` data-driven) → hache en bois fonctionnelle
- [x] Construction data-driven (`BuildingDefs`) — blueprint au sol, détection de collision, livraison physique, feu de camp
- [x] Ceinture d'outils (2 slots, barre 1-2)
- [x] Poches (3 slots, barre 3-5)
- [x] Sac à dos (9 slots, accès uniquement posé au sol façon Peak)
- [x] Extension de `CarryController` en mécanisme main transversal
- [x] Course (Shift, ×1.6, kick de FOV) et saut (Espace, coyote time) — bridés mains occupées
- [x] Recette de cuisson via un `RecipeDef` générique branché sur le feu de camp
> **Repoussé, non bloquant** : grips + hand_position pour les 10 autres outils du pack ; intégration Universal Animation Library 2 (à revalider au chassis robot, J7).
 
### Dette Jalon 3
- Le protagoniste est officiellement un robot : l'apparence humaine implicite du viewmodel est temporaire — chassis robot au Jalon 7.
- **Pas de menu de sélection de bâtiment** : `BuildModeController` expose un unique `building_def`. À traiter au Jalon 10 au plus tard, ou dès qu'un deuxième bâtiment arrive.
- Physique des rondins pas réglée — à ajuster via Physics Material.
- Objet porté en main pas contraint en taille/collision au HandAnchor.
- La hache traverse les murs/arbres quand la caméra s'en approche. Piste : caméra/layer dédié au viewmodel.
- Swing statique, manque de "punch". Piste : easing sur le Tween, ou anim dédiée.
- FX minimal manquant à l'impact (particules bois, léger shake caméra).
- Ombre flottante de la hache — résolue par le chassis robot au Jalon 7.
- Course/saut gratuits alors que le GDD prévoit que toute action passe par l'énergie — Jalon 7.
- Feeling course/saut non réglé. Passe de réglage au Jalon 7.
- Pas de head bob ni de son de pas.
- ToolPickup posé au sol : collision générique, pas de rotation couchée au drop.
- Icônes générées au premier affichage : léger hoquet possible.
- Grille 3x3 = 9 slots au lieu des 10 annoncés au GDD — GDD à mettre à jour.
- `grilled_mushroom` = champi cru teinté brun. Asset dédié à faire.
- Cuisson : une recette à la fois, pas de brûlé, ingrédients non visibles sur les braises.
## Jalon 3.5 — Localisation (infrastructure L10N) ✅
- [x] `translations/strings.csv` — clé + colonnes `en`, `fr`, rangé en sections
- [x] Convention de clés : `namespace.section.key`
- [x] Autoload `Locale` — wrapper `TranslationServer`, fallback `en`
- [x] Migration des strings existants : `prompt_text` → `prompt_key`, `display_name` → `name_key`
- [x] Le `tr()` centralisé sur les seuls points d'affichage (trois, voir STRUCTURE)
- [x] Clés de cache d'icônes rebasées sur les `id`
- [x] Bascule debug EN ↔ FR sur **F10**
- [x] Mise à jour docs à la clôture
### Dette Jalon 3.5
- Format `.po` pas retenu — CSV suffit pour un dev solo.
- Pas de pluralisation ni d'accords genre à ce stade.
- **Aucune vérification qu'une clé utilisée existe dans le CSV.** Piste : script d'éditeur croisant les `tr(...)`/`_key` du projet avec les colonnes du CSV.
## Jalon 3.6 — Panneau de cuisson & interfaces du monde ✅
> **Changement de cap en cours de jalon.** Les passes A à C ont livré des panneaux `Control` ancrés à l'écran, avec curseur souris et drag & drop natif. Testé, commité — et abandonné : manier deux panneaux à la fois était impraticable. Décision retenue : plus de curseur, le réticule est le pointeur, et les panneaux deviennent des objets 3D dont les cases sont des `Interactable`.
 
- [x] **Passe A** — `ItemSlot`, `WorldAnchoredPanel`, `UIPanelController`
- [x] **Passes B et C** — panneau de cuisson en `Control`, prompt contextuel, E contextuel sur le feu
- [x] **Passe D** — socle 3D : `WorldPanel`, `PanelSlot`, couche de collision « UI 3D », `take_into_hand()`
- [x] **Passe E** — panneau de cuisson 3D : recettes illustrées, fantômes d'ingrédients, jauges
- [x] Corrigé au passage : `IconGenerator` produisait des icônes composites ; `_try_use_pocket_item()` jetait l'objet au sol sur refus
- [x] **Passe F** — nettoyage : action morte `cancel_build_mode` supprimée, `Choppable.pickup_scene` remplacé par `drop_resource`
- [x] Mise à jour des docs à la clôture
### Dette Jalon 3.6
- **Les panneaux ne sont pas occultés** : lisibles devant une flamme, mais visibles à travers un mur. À revoir si ça se remarque en intérieur.
- Pas de fermeture à l'angle : se détourner sans s'éloigner laisse le panneau ouvert.
- Aucune surbrillance de la case visée. `PanelSlot` a la structure pour.
- Tailles des panneaux posées à l'œil. À revalider au chassis robot (J7).
- Une case ne contient qu'un objet et ne s'échange pas.
- Pas de feedback sonore ni d'animation à l'ouverture ni au transfert.
## Jalon 4 — Terrain procédural v1 🗄️ archivé
> **Arrêté et mis de côté, pas terminé.** Le jalon a produit un générateur qui marche — relief tiré à la graine, vallée, rivière, lac, deux biomes, quatre strates de végétation streamées, sol texturé à cinq matériaux. Ce qui restait à faire (catalogue de features, lieux-dits, grotte, chaîne lointaine, troisième biome) valait un second jalon entier pour un gain qui ne touche jamais le cœur du jeu — les pawns. On s'arrête là.
>
> **Conservé sur la branche `archive/terrain-v1`.** Le code n'est pas repris sur la branche principale : la v2 repart d'une base minimale plutôt que de désosser celle-ci. Ce qui a de la valeur en est déjà sorti — les décisions de conception et les gotchas moteur vivent dans STATE, l'inventaire d'assets dans ASSETS.
>
> Livré : passes A (relief), A-bis (relief habitable), B1 (canopée), B1-bis (proximité), B2 (strates, occupation, taches, biomes, streaming), B3 (habillage texturé). Non livré : passes C (grotte, falaise, lointain) et D (catalogue de features).
>
> **Reste vrai pour la v2, et rien d'autre :**
> - Une heightmap ne fait pas de verticalité franche — voir STATE §Terrain procédural.
> - La collision terrain se fait en trimesh, pas en `HeightMapShape3D`, dès que la cellule n'est pas à 1 m.
> - La brume porte la profondeur, pas la géométrie lointaine. Distance d'affichage et densité de brume se règlent de pair.
> - La vitesse du joueur (~13 m/s) est le double d'un sprint humain. La réduire agrandit la carte sans un triangle de plus — à traiter à la passe de feeling du Jalon 7.
## Jalon 4.4 — Ciel, lumière et cycle jour/nuit ✅
> Sorti du jalon 4 et placé **avant sa passe C** : le décor lointain se juge sur la brume et la couleur d'horizon, pas sur la géométrie. Impossible de régler l'un sans l'autre.
 
### Passe A — horloge et ciel ✅
- [x] Autoload `TimeOfDay` (scène, pour que ses réglages soient à l'inspecteur) : temps canonique, phases, signaux, et deux mesures en secondes réelles (`seconds_until_phase`, `seconds_left_in_phase`) — c'est ce qu'un pawn interrogera pour décider d'aller voir un couchant
- [x] Temps non linéaire par **remappage** et non par courbe de vitesse : une journée dure exactement `day_duration`, quelle que soit la répartition des phases
- [x] Phases déclarées en **élévation du soleil**, durées déclarées en parts de temps réel — le physique et le ressenti ne se règlent pas au même endroit
- [x] `sky_profile.gd` + quatre instances (`clear_day`, `cold_clear`, `warm_haze`, `overcast`), converties depuis les presets du pack Godot Skies
- [x] `sky_rig.tscn` (`SkyController` + `WorldEnvironment` + `DirectionalLight3D`) : oriente le soleil, écrit les uniformes du ciel, pilote brume et ambiante
- [x] Raccord du lointain confié au moteur : `ambient_light_source = SKY` et `fog_sky_affect = 1.0`. Le `SkyProfile` ne déclare aucune couleur de brume, seulement une distance
- [x] Aube et couchant distingués côté contrôleur, alors que le shader ne sait pas les distinguer
### Passe B — panneau de debug ✅
- [x] `sky_debug_panel.gd` (F3) : heure, phase, élévation, temps restant et temps avant le prochain crépuscule ; heure, durée de cycle, pause, saut aux quatre phases, répartition, choix de profil
- [x] `fog_distance_scale` et `ambient_scale` sur le contrôleur — instrument de mesure, pas réglage : la valeur trouvée se recopie dans la courbe du profil
- [x] Exclusivité via `UIPanelController.exclusive_modes`, curseur libéré, caméra neutralisée
> **Passe C (plancher d'élévation) reportée au Jalon 4.5** : elle vit dans le composant de proximité du feuillage, qui se réécrit avec le terrain.
### Dette Jalon 4.4
- **Lune** : disque lisse plaqué à l'opposé du soleil, sans phases ni éclairage propre. Une « vraie » lune est trois chantiers distincts — la **course** (mêmes formules que le soleil, décalées, avec une période légèrement différente pour que les phases dérivent seules) ; les **phases** (fraction éclairée déduite de l'angle lune/soleil, ce qui impose un disque éclairé et non plaqué — c'est là qu'est le travail de shader, et une phase qui ne s'accorde pas avec la position du soleil se voit immédiatement) ; l'**éclairage nocturne** (seconde `DirectionalLight3D`, énergie pilotée par la phase, qui remplacerait une partie de l'ambiante de nuit faite à la main et obligerait la coupure d'ombre du feuillage à raisonner sur deux astres). Le patch de shader de la course et celui de la texture sont **le même bloc de six lignes** : les traiter ensemble.
- **Pas de nuages à l'horizon** : le shader les éteint sous 0,2 en `EYEDIR.y` et ne les pose que sur un plan au-dessus de la tête. Pas de banc de nuages sur les crêtes lointaines, alors que c'est un ingrédient Firewatch. La brume porte la profondeur à leur place.
- **Étoiles en projection planaire XZ** : elles s'étirent au zénith et ne tournent pas avec le ciel. À reprendre avec la lune.
- **Les textures de nuages ne se mélangent pas** : un `SkyProfile` ne fait donc varier que des uniformes, et tous les profils partagent la paire de textures du rig. Si le climat exige des formes de nuages franchement différentes, ce sera une passe de shader (deux jeux de textures et un mélange), pas un contournement.
- **Trois `clamp(0.0, 1.0, x)` aux arguments inversés** dans le shader du pack (lignes 83, 88, 93). Le résultat tombe juste par chance. Noté pour ne pas rediagnostiquer.
- **`sun_off_threshold` coupe l'ombre, jamais la lumière** : le soleil reste toujours visible, sinon le ciel perd `LIGHT0_DIRECTION`. Une directionnelle à énergie nulle reste soumise au rendu — coût mesuré négligeable, à revérifier si le budget lumière devient serré.
- **Répartition et durée du cycle posées à l'œil** (30 min, 5/10/6/9). À revalider quand les pawns auront des activités qui dépendent de l'heure.
- **Brume et ambiante réglées au jugé**, y compris la nuit. La courbe de brume doit rester assez courte à toute heure pour masquer la coupure du feuillage : c'est son **minimum** sur la journée qui compte, pas sa valeur de midi.
## Jalon 4.5 — Terrain minimal
> **Reset.** Objectif unique : un terrain jouable qui porte les pawns et de quoi les faire travailler, écrit en repartant de zéro. Ce jalon n'a aucune ambition esthétique — la carte finale sera vraisemblablement faite à la main, en polish tardif. Tout ce qui n'est pas nécessaire à une simulation de colonie n'a pas sa place ici.
>
> **Dimensionnement** : la portée de liaison au bunker (Jalon 7) est ce qui fixe la taille utile. Une carte vaut deux fois ce rayon ; au-delà, on paie de la génération pour du terrain où le jeu ne se passe jamais. Point de départ **500 m de côté**, à réviser une fois 50 pawns mesurés dessus — c'est la simulation qui tranche, pas le paysage.

### Passe A — géographie de base
- [ ] Relief : pente de massif d'un côté, plaine de l'autre, un replat plan pour le bunker. Tiré à la graine ou posé en dur, au plus simple — pas de vallée, pas de rivière, pas de lac tant que rien n'en dépend.
- [ ] Site de grotte publié à l'origine du monde, pour que le bunker s'y pose.
- [ ] Mesh + collision. Chunks seulement si la mesure les réclame.
- [ ] Matériau de sol simple. L'habillage à cinq textures se refera quand la simulation tournera.
### Passe B — ressources dans le terrain
> C'est la vraie raison d'être du jalon : les pawns doivent avoir de quoi travailler.
- [ ] Semis simple : arbres, champignons, **rochers et branches** au sol — le tier 1 du GDD, ramassable et récoltable.
- [ ] Chaque essence semée est **récoltable** : `FoliageDef` gagne ses champs de récolte (PV, type d'outil, `drop_resource`), et un arbre proche bascule en instance abattable. Un décor qu'on ne peut pas exploiter ne sert à rien à ce stade.
- [ ] Densités réglées pour que le tier 1 soit montable sans traverser la carte.
### Passe C — navigation
- [ ] Bake `NavigationRegion3D` après le semis
- [ ] Corriger dette Jalon 1 (navmesh qui grimpe sur les branches basses) — collision de tronc simplifiée, pas mesh complet
- [ ] `maxf()` sur l'élévation du soleil dans le composant de proximité du feuillage : la division par `tan(élévation)` peut produire un `inf`, et un `inf` dans une comparaison de distance ne lève rien (report du Jalon 4.4, passe C)
### Dette Jalon 4.5
- Aucune personnalité de carte : pas de lieux-dits, pas de features, une seule composition. Assumé — c'est le polish tardif qui répondra, à la main.
- Pas de rivière, donc pas de contrainte de topologie. La carte est intégralement traversable.
- Habillage du sol minimal. À reprendre quand la simulation tiendra son objectif de pawns.
## Jalon 5 — Pawn : socle et passage à l'échelle
> **Cœur du jeu.** L'objectif chiffré est de simuler **40 à 50 pawns** sans perdre la frame. Ce chiffre n'est pas une ambition d'affichage : c'est ce qui dimensionne l'architecture, et aucun des quatre postes ci-dessous ne se règle après coup.

- [ ] Pawn dormant scripté (état sommeil → réveil via interaction robot)
- [ ] `ActionStateMachine` pawn (idle / se_deplacer / tâche_courante) via `NavigationAgent3D` — prépare les états `EVALUATING`/`INTERRUPTED` du Jalon 6
- [ ] **`PawnManager`** : point de tick unique, évaluation découpée en tranches sous budget en millisecondes. Jamais un `_process()` par pawn.
- [ ] **LOD de simulation à trois niveaux**, conçu dès le premier pawn : proche et visible = squelette animé + `CharacterBody3D` ; loin = interpolation le long du chemin, sans skinning ni physique ; hors liaison = abstrait, sans nœud dans la scène. Le troisième niveau est ce qui rendra les expéditions du Jalon 12 gratuites.
- [ ] **Requêtes de chemin asynchrones**, avec une file plafonnée. C'est le poste qui sature en premier.
- [ ] **Banc de mesure** : bouton « spawner N pawns », compteurs de temps IA / nav / frame. Sans lui, « 50 pawns » est une intention et pas une cible — même rôle que `HeightmapSignature` au Jalon 4.
- [ ] Sélection de pawn — réutilisée par la roue de réaction au Jalon 7, à déclarer dans `UIPanelController.exclusive_modes`
- [ ] Ordres directs minimaux (suivre / reste / va-là)
## Jalon 6 — Tableau de tâches, utility AI et fatigue
> Fusion de l'ancien portage temps réel et de l'ancien tableau de tâches : la fatigue n'a d'existence que comme terme du score, et un score sans fatigue se réécrit dès qu'elle arrive.

- [ ] `TaskDef` en `.tres` (type, priorité, localisation, seuil pawns requis, poids d'appétence par trait)
- [ ] Fatigue **par catégorie d'action**, avec decay au repos ou au changement de catégorie
- [ ] Boucle d'évaluation : `score = priorité × appétence(trait) × compétence × (1 - fatigue_cat) × modif_partenaire`, appelée par le `PawnManager` aux points de décision — jamais en continu
- [ ] États `EVALUATING`/`INTERRUPTED` dans l'`ActionStateMachine`
- [ ] UI tableau côté joueur
- [ ] **Opportunisme en chemin** : détection de proximité → réévaluation ponctuelle
- [ ] Signalement : un pawn ajoute une tâche au tableau ou révèle un point d'intérêt
- [ ] **Tâche de sauvetage du robot** : priorité haute, non refusable, cible = position du robot tombé. C'est ce qui implémente le sauvetage du Jalon 7 sans code spécial — et « aucun pawn disponible = game over » en découle au lieu d'être une règle à part.
- [ ] Relations par accumulation de coprésence/co-tâche
- [ ] Portage `EventConfig`/`EventManager` et `Chronicle` en version temps réel
- [ ] Tâches d'agrément déclenchées par l'heure — aller voir un couchant depuis un point de vue. Les deux mesures de `TimeOfDay` existent pour ça depuis le Jalon 4.4 : un pawn compare le temps de trajet au temps restant avant le crépuscule, et à sa durée.
## Jalon 7 — Robot : identité, liaison, énergie
> Trois ressources distinctes, et aucune ne se calcule à partir d'une autre : **énergie du bunker** = horloge de fin de partie (et raison du réveil) ; **énergie du robot** = autonomie d'action à recharger ; **liaison** = géographie.

- [ ] Chassis robot (visuel + rigging) — bras/effecteur porteur d'outils
- [ ] Pool énergie **bunker global** (décrément continu, horloge de fin de partie)
- [ ] Pool énergie **robot local** (jauge embarquée, recharge au bunker) — inclut le coût de course/saut. **Sans rapport avec la distance.**
- [ ] **Carte de couverture de liaison**, calculée une fois à la génération du terrain : viewshed depuis le bunker sur la heightmap, grille échantillonnée en lecture directe. Aucun raycast par frame. Une crête coupe le signal, la plaine porte loin.
- [ ] **Force de liaison en valeur continue** (0 → 1), calculée à un seul endroit et lue par trois clients qui ne se connaissent pas : glitch d'écran croissant, message d'avertissement, et déclencheur de chute à 0. Le seuil de chute n'est pas une seconde règle de distance.
- [ ] Chute hors liaison → tâche de sauvetage postée au tableau (Jalon 6). Un pawn ramène le robot ; aucun pawn disponible = game over.
- [ ] Passe de réglage du feeling course/saut, réduction de la vitesse du joueur, et revalidation de la taille des panneaux 3D
- [ ] Roue de réaction : oui / non / suis-moi / reste / reprends ton activité
- [ ] Bulles techniques robot (diagnostics, alertes) — pas d'émotions, marque l'altérité
### Dette Jalon 7
- Conséquences d'une chute au-delà du sauvetage (usure, module en panne, coût pour le pawn secouriste) : à définir une fois la mécanique testée.
- Relais de liaison construisibles : pas prévus, mais gratuits à ajouter — un relais est une seconde source composée en `max()` avec la première sur la carte de couverture.
## Jalon 8 — Interactions pawn ↔ pawn & pawn ↔ robot
- [ ] Bulles thématiques au croisement, générées selon l'état des deux
- [ ] Effets légers (micro moral, micro relation)
- [ ] Bulles "question" côté pawn répondables via la roue robot
- [ ] Sauvetage dégressif : le sauvetage lui-même est au Jalon 7 (tâche de tableau) ; ici sa **dégressivité** — récidive, coût pour le pawn secouriste, conséquences sur le robot
- [ ] Atelier "robotique low-tech" : **qualité modulée par la relation** avec le pawn qui répare
## Jalon 9 — Progression tech par tags
- [ ] `TechDef` en `.tres` (`required_tags`, `unlocked_recipes`, `axis`)
- [ ] Station d'analyse au bunker : échantillon → **tags de propriété** persistants
- [ ] Base de connaissance persistante — s'ancre sur le `Chronicle`
- [ ] Sélection d'un axe de recherche : tags suffisants → recette débloquée ; manquants → **indice de propriété**
- [ ] Archive du bunker comme ressource limitée → force le pivot vers la découverte empirique
## Jalon 10 — Ressources & recettes solarpunk (T2 → T3)
- [ ] Menu de sélection de bâtiment en mode construction (dette Jalon 3)
- [ ] **Phytominière** (T2) : plantes hyperaccumulatrices — `Plant_2`, le bleu franc du pack, est la candidate visuelle
- [ ] **Mycoculture** dans la grotte (T2) : mycélium comme matériau structurel, substrat = bois mort
- [ ] Construction **terre crue** + **hempcrete** (T2) — pierre en ramassage de surface uniquement
- [ ] **Biogaz/méthanisation** (T2)
- [ ] **Four solaire concentré** (T3)
- [ ] **Bioleaching** (T3)
## Jalon 11 — Bascule écologique & démocratique
- [ ] Métrique de dégradation d'écosystème liée à l'exploitation T1
- [ ] Effets visibles progressifs : faune dangereuse, maladies, autres
- [ ] Event de gouvernance déclenché par seuil de dégradation
- [ ] Réunion des pawns + **système de vote** pondéré par convictions/vécu
- [ ] "Lois" votées qui modifient des paramètres colonie
- [ ] Déblocage effectif du palier solarpunk après le vote
- [ ] Passage progressif du tableau piloté-joueur → réajustement colonie
> Piste visuelle : un `SkyProfile` dégradé (les presets `dark_sky` et `red_sky` du pack existent) rendrait la bascule lisible sans un mot. Le mécanisme de fondu entre profils est celui du climat.
## Jalon 12 — Expéditions & fins
- [ ] Système d'expédition hors liaison : contrôle délégué au groupe parti, pawns au niveau 3 du LOD de simulation (Jalon 5)
- [ ] Objectifs typiques : souche absente localement, autre communauté, zone écologique différente
- [ ] Résolution en tâche longue avec risque réel
- [ ] Trois branches de fin :
  - **Fin standard** — shutdown du bunker atteint, bilan des pawns sauvés
  - **Game over anticipé** — robot tombé hors liaison, aucun pawn pour le ramener
  - **Bonne fin — robot éternel** — tous les dormants sauvés, choix final (variantes lié-mortel / isolé-éternel)
## Features non planifiées
- **Climat et intempéries** — l'axe est orthogonal à l'heure : le shader gère le moment via l'élévation du soleil, un `SkyProfile` décrit le temps qu'il fait. Changer de temps est un fondu d'un profil vers un autre sur quelques minutes. Contrainte à respecter : un profil ne fait varier que des uniformes, jamais des textures.
- Deuxième bunker / expansion de zone
- **Personnalité de carte procédurale** (ex-passe D du Jalon 4) : catalogue de `TerrainFeature` tirées avec quotas, zones dérivées, `Site` publiés, lieux-dits nommés par deux clés du CSV, registre de réservation d'emprise, planche de graines, vérificateur d'invariants. Le raisonnement et le catalogue préliminaire de trente spots vivent sur la branche `archive/terrain-v1`. Abandonné parce que la carte finale sera vraisemblablement faite à la main.
- **Décor lointain** (ex-passe C du Jalon 4) : chaîne de montagnes hors zone jouable, gorge, cascade, rochers posés sur l'escarpement, bordure de zone. Relève du polish tardif.
- **Habillage riche du sol et de la végétation** : cinq matériaux texturés mélangés par carte de hauteur, quatre strates, taches monochromes, deux biomes. Fonctionnait sur la branche archivée ; se refera si la carte finale le mérite, mais jamais avant que la simulation ne tienne son objectif de pawns.
- **Rivière et topologie contrainte** : le partage 2/3 – 1/3 non franchissable sans gué faisait beaucoup pour la sensation d'espace. À rouvrir si la carte minimale s'avère trop plate ludiquement.
- Sous-sol du bunker (complexe cryo) via téléportation depuis le bas de l'escalier — c'est aussi là que les dormants du Jalon 5 sont susceptibles d'être réveillés
- Chemins qui se tracent au passage du joueur et des pawns : carte de piétinement modulant la couleur du sol et supprimant l'herbe au-dessus d'un seuil. Le découpage en chunks est ce qui la rendra possible sans régénérer la carte, et `RockPath` fournit les dalles.
- Tache de troncs brûlés (`DeadTree`) : un événement passé raconté sans un mot
- Pistes solarpunk T3+ à préciser (bio-photovoltaïque, apiculture, culture d'algues, rouissage des fibres en rivière)
- Langues supplémentaires — l'infrastructure J3.5 est prête pour n'importe quelle colonne CSV en plus
## Décisions à trancher (avec jalon cible)
 
- **Avant Jalon 7** — Définition concrète de l'"intégrité système" du robot (équivalent moral)
- **Avant Jalon 6** — Traits d'origine des pawns : reconversion progressive vs compétences ancien-monde définitivement inutiles — impact direct sur le ton
- **Avant Jalon 5** — Cible de pawns simultanés : **40 à 50** retenu, à confirmer au banc de mesure
- **Avant Jalon 7** — Portée de liaison en plaine, et ce qu'une crête en retire. C'est elle qui fixera la taille définitive de la carte
- **Avant Jalon 8** — Règles précises du sauvetage dégressif (récidive, probabilités, cooldown)
- **Avant Jalon 11** — Modalités exactes de la transition d'autonomie politique
- **Avant Jalon 11** — Système de vote / gouvernance : détail à travailler en session dédiée