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
> **Repoussé, non bloquant** : grips + hand_position pour les 10 autres outils du pack ; intégration Universal Animation Library 2 (à revalider au chassis robot, J6).
 
### Dette Jalon 3
- Le protagoniste est officiellement un robot : l'apparence humaine implicite du viewmodel est temporaire — chassis robot au Jalon 6.
- **Pas de menu de sélection de bâtiment** : `BuildModeController` expose un unique `building_def`. À traiter au Jalon 11 au plus tard, ou dès qu'un deuxième bâtiment arrive.
- Physique des rondins pas réglée — à ajuster via Physics Material.
- Objet porté en main pas contraint en taille/collision au HandAnchor.
- La hache traverse les murs/arbres quand la caméra s'en approche. Piste : caméra/layer dédié au viewmodel.
- Swing statique, manque de "punch". Piste : easing sur le Tween, ou anim dédiée.
- FX minimal manquant à l'impact (particules bois, léger shake caméra).
- Ombre flottante de la hache — résolue par le chassis robot au Jalon 6.
- Course/saut gratuits alors que le GDD prévoit que toute action passe par l'énergie — Jalon 6.
- Feeling course/saut non réglé. Passe de réglage au Jalon 6.
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
- Tailles des panneaux posées à l'œil. À revalider au chassis robot (J6).
- Une case ne contient qu'un objet et ne s'échange pas.
- Pas de feedback sonore ni d'animation à l'ouverture ni au transfert.
## Jalon 4 — Terrain procédural
> Découpé en passes testables. La passe A remplace le sol plat ; tout ce qui suit se pose dessus.
 
### Passe A — relief jouable ✅
- [x] `terrain_gen_config.gd` (Resource) : tous les réglages, plus la convention de grille (`grid_size()`, `height_index()`, `world_pos()`, `sample_height()`) — source unique des coordonnées pour toute la chaîne.
- [x] `heightmap_generator.gd` : tirage du massif → relief → niveau de l'eau → clairières → tracé et creusement de la rivière. Publie `heights`, `cave_position`/`cave_forward`, `water_level`, `clearings`, `river_path`.
- [x] Massif paramétrique : orientation, longueur, largeur et hauteur tirées de la graine. Chaîne traversante, pic ou massif directionnel sont le même code.
- [x] `terrain_mesh_builder.gd` : chunks `ArrayMesh` + collision, normales calculées sur le tableau global (raccord sans couture)
- [x] `terrain_controller.gd` : orchestrateur `@tool`, boutons Régénérer / Effacer, nœuds sans owner
- [x] `terrain.gdshader` : habillage par altitude et pente, plus variation de teinte procédurale
- [x] Lac : niveau d'eau déduit du fond de vallée, plan plus large que la zone. Le rivage n'est pas tracé, c'est ce qui dépasse.
- [x] Perf mesurée : **~2 000 ms** pour 1200 m × cellule 3 m (161 000 sommets, 169 chunks)
### Passe A-bis — relief habitable ✅
- [x] Vallonnement élargi (fréquence 0.009 → 0.006) : pente moyenne de 25 % à 17 %
- [x] Atténuation du vallonnement là où le massif n'a plus d'influence — la plaine se calme, la montagne pas
- [x] Clairières dispersées, tirées à la graine, refusées sur le massif / sous l'eau / sur la clairière du bunker. Même fonction que celle du bunker, avec une force d'aplanissement en plus.
- [x] Variation de teinte du sol dans le shader : sans elle, une pente régulière est un aplat uni
### Passe B1 — canopée ✅
- [x] `foliage_def.gd` : une essence = un `.tres` (modèle, échelle, pente max, enfoncement, poids)
- [x] `foliage_scatter.gd` : grille jitterée, `MultiMeshInstance3D` par essence et par chunk, extraction des meshes du modèle du pack (matériaux de surface recopiés dans le mesh)
- [x] Exclusions : eau, pente, clairières (avec lisière en dégradé), lit de la rivière
- [x] Enfoncement croissant avec la pente
- [x] Peuplements par poids, décidés au point : chaque essence a son champ de bruit, aucune sélection par chunk
- [x] Distance d'affichage + fondu, réglés de pair avec le brouillard de profondeur du `WorldEnvironment`
- [x] Perf mesurée : **~500 ms** de semis, 23 000 instances, ~160 chunks de feuillage
### Passe B1-bis — proximité
- [x] `foliage_proximity.gd` : composant piloté par la caméra courante, point unique de réaction du feuillage à la distance
- [x] Coupure de `cast_shadow` par chunk, sur le critère de l'endroit où l'ombre **atterrit** (chunk translaté le long du soleil de `canopy_height / tan(élévation)`), comparé au `directional_shadow_max_distance` lu sur la lumière
- [x] `TerrainGenConfig.chunk_area()` : emprise d'un chunk, publiée en métadonnée par le semis
- [ ] Bascule des arbres proches en instances abattables — au Jalon 5, avec les pawns qui les récoltent
- [ ] `FoliageDef` gagne ses champs de récolte (PV, type d'outil, `drop_resource`) — écrits quand il y a quelqu'un pour les lire
### Passe B2 — strates basses et biomes
> Découpée en sous-passes. `ScatterOccupancy` en premier : c'est elle qui empêche les strates de se traverser et qui produit la carte d'ouverture.

- [ ] Strate arbustive : les `CommonTree` redescendent là où ils appartiennent, plus buissons et fougères. C'est elle qui bouche la vue à trente mètres et donne la profondeur de Compiègne.
- [ ] Strate sol : herbes, fleurs, cailloux, champignons
- [ ] Strate épiphyte : champignons de tronc, posés sur les troncs et les rochers
- [ ] `biome_map_generator.gd` : **poids** de biome par cellule (jamais d'identifiant — c'est ce qui donne les dégradés sans code de frontière), carte de pente, carte d'humidité, distances de lisière
- [ ] `scatter_occupancy.gd` : deux grilles à cellule ~2 m. `blocked` = disques durs au rayon de base, refus binaire (rien ne pousse dans un tronc). `cover` = disques doux au rayon de feuillage, module une **densité**. Confondre les deux fait qu'aucune strate basse ne pousse : à 7 m d'espacement, des disques de feuillage de 6 m couvrent la carte à plus de 100 %.
- [ ] `FoliageDef` gagne `base_radius`, `cover_radius`, `cover_amount`, `cover_preference` (l'herbe veut du clair, les champignons de l'ombre) et `persistent`
- [ ] `FoliageScatter` passe de la liste unique de canopée à des strates ordonnées, chacune semée **sur toute la carte** avant la suivante : un arbre déborde chez le voisin, l'occupation doit être complète avant que la strate d'en dessous ne la lise
- [ ] Carte d'ouverture = `cover` laissée par la canopée. Elle sert trois fois : densité des strates basses, couleur de sommet du sol, et plus tard le déboisement qui fait pousser l'herbe. Corollaire visé : déboiser fait pousser l'herbe.
- [ ] Strate sol **streamée par chunk** autour du joueur, via `FoliageProximity` : à 1 m d'espacement sur 1200 m, c'est 1,44 M de candidats et ~100 Mo de multimesh — non semable au boot
- [ ] `BiomeDef` et `PatchDef` en `.tres`. Biomes ouverts en premier : forêt claire, forêt sombre (conifères), berge. Patchs : clairière, coin à champignons, bosquet rose.
- [ ] Les couleurs de biome **et l'ouverture** s'ajoutent au shader du sol en couleur de sommet, sans remplacer le calcul altitude/pente. C'est ce qui fait exister une clairière lointaine : sans elle, une trouée vue d'une hauteur est une tache de sol nu dans le vert.
- [ ] Le mesh de terrain se construit **après** le semis de canopée, puisqu'il lit `cover` — le sol se colore de ce qui pousse dessus
- [ ] Végétation `persistent` de clairière (touffes hautes, buissons fleuris, bouquets) semée au boot comme la canopée : ce qui doit se voir de loin ne se stream pas
- [ ] Bake `NavigationRegion3D` après le scatter ; rivière et falaise infranchissables, gué praticable
- [ ] Corriger dette Jalon 1 (navmesh/branches)
### Passe C — grotte, falaise et lointain
- [ ] Grotte d'entrée : porche posé sur le site publié par le générateur (`CaveSite`), scène séparée reliée par téléportation. C'est là que le bunker sera rebâti.
- [ ] Rochers du pack posés sur l'escarpement : le relief donne la pente, les meshes donnent la paroi
- [ ] Bordure de zone sur les côtés non noyés par le lac
- [ ] Chaîne lointaine hors zone jouable : maillage grossier, sans collision, végétation ni navmesh
- [ ] Cascade, en feature du biome montagne rejoignant la rivière
- [ ] Gorge : passage encaissé entre deux parois sur une portion du cours — feature de relief, pas de végétation
### Dette Jalon 4
- **Pas de LOD sur la végétation.** Partiellement payé par la distance d'affichage : on ne simplifie pas les arbres lointains, on cesse de les dessiner. Un vrai LOD ou des imposteurs restent à faire si la distance d'affichage devient insuffisante.
- **`foliage_view_distance` masque le feuillage dans l'éditeur** dès qu'on recule la caméra pour voir la carte. Ce n'est pas un bug, mais ça surprend : monter la valeur temporairement pour inspecter la carte de haut.
- **Le fondu de visibilité dépend du shader du pack** : s'il ne prend pas le tramage, les chunks disparaissent d'un coup. Mettre la marge de fondu à 0 et laisser la brume masquer la coupure.
- **`TallThick_2` a un trou noir dans son tronc** — défaut de la scène du pack, absent du glTF, sans surcharge de matériau en cause. Retiré de la liste d'essences. À traiter avec les autres corrections d'assets tiers, et à noter dans ATTRIBUTION le jour où on modifie le pack.
- **Collision terrain en `ConcavePolygonShape3D`** et non `HeightMapShape3D` : ce dernier échantillonne à 1 unité fixe, incompatible avec une cellule de 3 m sans scaler le `CollisionShape3D` de façon non uniforme. Repasser dessus si le coût des requêtes physiques se voit au Jalon 5.
- **Eau sans collision** : on traverse le plan d'eau. À traiter quand le gué comptera (Jalon 5) ou au Jalon 6 avec l'énergie.
- **Seuils du shader en mètres absolus** alors que la hauteur du massif est tirée entre 160 et 260 m : la roche monte plus ou moins haut selon la graine. À exprimer en fraction de la hauteur tirée si ça se remarque.
- **Fond de vallée lisse** : atténuation à 0,85, nécessaire pour que la descente de gradient de la rivière ne s'échoue pas. Devrait disparaître sous la végétation.
- **Le tracé de rivière est guidé**, pas érosif. C'est ce qui garantit la topologie 2/3 – 1/3 quelle que soit la graine.
- **Un seul massif par carte.** Des buttes secondaires seraient le même code appelé plusieurs fois ; pas avant d'en avoir le besoin.
- **Génération monofil dans la frame** (~2,5 s). À découper (`WorkerThreadPool` ou étalement) si ça arrive en cours de partie.
- **Step-up et saut pas revalidés sur pente irrégulière** — dette reprise du Jalon 3.
- **`forest_test.tscn` et `forest_scatter.gd` sont périmés** mais conservés : ce sont les seules scènes où les mécaniques de jeu sont testables. À supprimer quand elles auront une scène d'accueil dans le nouveau format — sans quoi il existe deux façons de peupler une forêt dans le projet.
- La vitesse du joueur est très élevée (~13 m/s mesurés, soit le double d'un sprint humain). La réduire est le levier le moins cher pour agrandir la carte sans générer un triangle de plus. À traiter à la passe de feeling du Jalon 6.
## Jalon 5 — Réveil de pawn + ordres directs
- [ ] Pawn dormant scripté (état sommeil → réveil via interaction robot)
- [ ] `ActionStateMachine` pawn (idle / se_deplacer / tâche_courante) via `NavigationAgent3D` — prépare les états `EVALUATING`/`INTERRUPTED` du Jalon 8
- [ ] Sélection de pawn — réutilisée par la roue de réaction au Jalon 6, à déclarer dans `UIPanelController.exclusive_modes`
- [ ] Ordres directs minimaux (suivre / reste / va-là)
- [ ] Corriger dette Jalon 1 (navmesh/branches) avant de tester le déplacement des pawns
## Jalon 6 — Robot : identité, énergie, communication
> Chassis, énergie et communication, testables contre de vrais pawns. La partie sociale reste au Jalon 9.
 
- [ ] Chassis robot (visuel + rigging) — bras/effecteur porteur d'outils
- [ ] Pool énergie **local** (jauge embarquée, recharge au bunker) — inclut le coût de course/saut
- [ ] Passe de réglage du feeling course/saut, et revalidation de la taille des panneaux
- [ ] Pool énergie **bunker global** (décrément continu, horloge de fin de partie)
- [ ] Rayon d'action = énergie (calcul aller-retour + alerte avant seuil critique, pas de mur invisible)
- [ ] Roue de réaction : oui / non / suis-moi / reste / reprends ton activité
- [ ] Bulles techniques robot (diagnostics, alertes) — pas d'émotions, marque l'altérité
## Jalon 7 — Portage simulation temps réel
- [ ] Fatigue **par catégorie d'action**
- [ ] Relations par accumulation de coprésence/co-tâche
- [ ] Portage `EventConfig`/`EventManager`
- [ ] Portage `Chronicle` en version temps réel
## Jalon 8 — Tableau de tâches (utility AI)
- [ ] `TaskDef` en `.tres` (type, priorité, localisation, seuil pawns requis, poids d'appétence par trait)
- [ ] UI tableau côté joueur
- [ ] Boucle d'évaluation : `score = priorité × appétence(trait) × compétence × (1 - fatigue_cat) × modif_partenaire`
- [ ] États `EVALUATING`/`INTERRUPTED` dans l'`ActionStateMachine`
- [ ] **Opportunisme en chemin** : détection de proximité → réévaluation ponctuelle
- [ ] Signalement : un pawn ajoute une tâche au tableau ou révèle un point d'intérêt
## Jalon 9 — Interactions pawn ↔ pawn & pawn ↔ robot
- [ ] Bulles thématiques au croisement, générées selon l'état des deux
- [ ] Effets légers (micro moral, micro relation)
- [ ] Bulles "question" côté pawn répondables via la roue robot
- [ ] Sauvetage dégressif : chances décroissantes avec la distance et la récidive
- [ ] Atelier "robotique low-tech" : **qualité modulée par la relation** avec le pawn qui répare
## Jalon 10 — Progression tech par tags
- [ ] `TechDef` en `.tres` (`required_tags`, `unlocked_recipes`, `axis`)
- [ ] Station d'analyse au bunker : échantillon → **tags de propriété** persistants
- [ ] Base de connaissance persistante — s'ancre sur le `Chronicle`
- [ ] Sélection d'un axe de recherche : tags suffisants → recette débloquée ; manquants → **indice de propriété**
- [ ] Archive du bunker comme ressource limitée → force le pivot vers la découverte empirique
## Jalon 11 — Ressources & recettes solarpunk (T2 → T3)
- [ ] Menu de sélection de bâtiment en mode construction (dette Jalon 3)
- [ ] **Phytominière** (T2) : plantes hyperaccumulatrices — `Plant_2`, le bleu franc du pack, est la candidate visuelle
- [ ] **Mycoculture** dans la grotte (T2) : mycélium comme matériau structurel, substrat = bois mort
- [ ] Construction **terre crue** + **hempcrete** (T2) — pierre en ramassage de surface uniquement
- [ ] **Biogaz/méthanisation** (T2)
- [ ] **Four solaire concentré** (T3)
- [ ] **Bioleaching** (T3)
## Jalon 12 — Bascule écologique & démocratique
- [ ] Métrique de dégradation d'écosystème liée à l'exploitation T1
- [ ] Effets visibles progressifs : faune dangereuse, maladies, autres
- [ ] Event de gouvernance déclenché par seuil de dégradation
- [ ] Réunion des pawns + **système de vote** pondéré par convictions/vécu
- [ ] "Lois" votées qui modifient des paramètres colonie
- [ ] Déblocage effectif du palier solarpunk après le vote
- [ ] Passage progressif du tableau piloté-joueur → réajustement colonie
## Jalon 13 — Expéditions & fins
- [ ] Système d'expédition hors rayon robot : contrôle délégué au groupe parti
- [ ] Objectifs typiques : souche absente localement, autre communauté, zone écologique différente
- [ ] Résolution en tâche longue avec risque réel
- [ ] Trois branches de fin :
  - **Fin standard** — shutdown du bunker atteint, bilan des pawns sauvés
  - **Game over anticipé** — robot perdu hors périmètre, non secouru
  - **Bonne fin — robot éternel** — tous les dormants sauvés, choix final (variantes lié-mortel / isolé-éternel)
## Features non planifiées
- Cycle jour/nuit
- Deuxième bunker / expansion de zone
- Sous-sol du bunker (complexe cryo) via téléportation depuis le bas de l'escalier — c'est aussi là que les dormants du Jalon 5 sont susceptibles d'être réveillés
- Chemins qui se tracent au passage du joueur et des pawns : carte de piétinement modulant la couleur du sol et supprimant l'herbe au-dessus d'un seuil. Le découpage en chunks est ce qui la rendra possible sans régénérer la carte, et `RockPath` fournit les dalles.
- Tache de troncs brûlés (`DeadTree`) : un événement passé raconté sans un mot
- Pistes solarpunk T3+ à préciser (bio-photovoltaïque, apiculture, culture d'algues, rouissage des fibres en rivière)
- Langues supplémentaires — l'infrastructure J3.5 est prête pour n'importe quelle colonne CSV en plus
## Décisions à trancher (avec jalon cible)
 
- **Avant Jalon 6** — Définition concrète de l'"intégrité système" du robot (équivalent moral)
- **Avant Jalon 8** — Traits d'origine des pawns : reconversion progressive vs compétences ancien-monde définitivement inutiles — impact direct sur le ton
- **Avant Jalon 9** — Règles précises du sauvetage dégressif (distances, probabilités, cooldown)
- **Avant Jalon 12** — Modalités exactes de la transition d'autonomie politique
- **Avant Jalon 12** — Système de vote / gouvernance : détail à travailler en session dédiée