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

- [x] Quatre strates : `canopy` (TallThick), `understory` (CommonTree), `shrub` (buissons, fougères), `ground` (herbes, trèfles, cailloux)
- [x] Roue de peuplement : un seul appel de bruit par candidat quel que soit le nombre d'essences, et des plaques d'une même espèce
- [x] `FoliagePatch` : taches où la composition change entièrement — `scree`, `grass_bed`, `mushroom_spot`, et quatre taches de fleurs **monochromes**
- [x] `clearing_response` (Curve) par strate : les buissons font une **couronne** en lisière, l'herbe ignore la clairière
- [x] `clearing_uniform` : dans une clairière, palette et essence se tirent au centre — la clairière est une unité, pas un morceau de forêt sans arbres
- [x] Habillage des pentes : `min_slope_degrees` sur les essences et sur les taches, `scree` réservé au-delà de 16°
- [ ] Strate épiphyte : `Mushroom_Oyster` et `Laetiporus`, posés sur les troncs et les rochers. Sortis des strates de sol en attendant — ce sont des champignons d'arbre.
- [ ] Troncs tombés et souches (`DeadTree`) : demande un mode de pose couché (rotation autour de X/Z) que `FoliageDef` ne sait pas exprimer
- [x] `biome_map.gd` : **poids** de biome par sommet (jamais d'identifiant — c'est ce qui donne les dégradés sans code de frontière), calculés sur l'**influence du massif** publiée par le générateur de relief. Carte d'humidité et distances de lisière non faites : elles n'ont pas d'usage tant qu'aucun biome ne les demande.
- [x] `scatter_occupancy.gd` : deux grilles à cellule ~2 m. `blocked` = disques durs au rayon de base, refus binaire (rien ne pousse dans un tronc). `cover` = disques doux au rayon de feuillage, module une **densité**. Confondre les deux fait qu'aucune strate basse ne pousse : à 7 m d'espacement, des disques de feuillage de 6 m couvrent la carte à plus de 100 %.
- [x] `FoliageDef` gagne `base_radius`, `cover_radius`, `cover_amount`, `cover_response` (une `Curve` : l'herbe veut du clair, les champignons de l'ombre) et `min_slope_degrees`
- [x] `FoliageScatter` passe de la liste unique de canopée à des strates ordonnées, chacune semée **sur toute la carte** avant la suivante : un arbre déborde chez le voisin, l'occupation doit être complète avant que la strate d'en dessous ne la lise
- [x] Carte d'ouverture = `cover` laissée par la canopée. Elle sert trois fois : densité des strates basses, couleur de sommet du sol, et plus tard le déboisement qui fait pousser l'herbe. Corollaire visé : déboiser fait pousser l'herbe.
- [x] Strates `shrub` et `ground` **streamées par tuile de 24 m** autour du joueur, via `FoliageProximity` : à 1 m d'espacement sur 1200 m, c'est 1,44 M de candidats et ~100 Mo de multimesh — non semable au boot
- [x] Passe perf : pré-filtrage des clairières par aire (chaque candidat les testait toutes), tuile de streaming découplée du chunk de terrain, et budget de semis en **millisecondes** au lieu de tuiles. 400 ms de gel par chunk → semis continu sans à-coup.
- [x] `BiomeDef`, `BiomeStratum` et `FoliageWeight` en `.tres`. **Le poids quitte `FoliageDef` et la composition quitte `FoliageLayer`** : une essence décrit ce qu'elle est, un biome ce qui pousse là. Les `FoliagePatch` passent au biome.
- [x] Biome `forest_light` : reprise à l'identique de la composition existante, comme test de non-régression du refactor.
- [x] Biome `conifer_highland` : `GiantPine` en canopée, `Pine` en sous-étage, dix `FoliageDef` neufs. Ses strates basses ne contiennent **que des essences déjà employées par la forêt claire**, repondérées — c'est la démonstration que le contenu est réutilisable. Pas de taches de fleurs : monter en altitude fait disparaître la couleur.
- [ ] Troisième biome au-delà de la rivière — demande une **position en travers signée** publiée par le générateur et une seconde bande sur `BiomeDef` : le système ne sait répondre qu'à « à quelle hauteur du relief », pas à « de quel côté ». Dette à ouvrir en même temps : au troisième critère (l'humidité de la berge), les champs nommés devront céder la place à une liste de critères.
- [x] L'**ouverture** s'ajoute au shader du sol en couleur de sommet (canal rouge) — la litière apparaît sous couvert fermé, l'herbe dans les trouées
- [ ] Les **couleurs de biome** s'ajoutent dans les autres canaux, sans remplacer le calcul altitude/pente. C'est ce qui fait exister une clairière lointaine : sans elle, une trouée vue d'une hauteur est une tache de sol nu dans le vert.
- [ ] Le mesh de terrain se construit **après** le semis de canopée, puisqu'il lit `cover` — le sol se colore de ce qui pousse dessus
- [ ] Végétation `persistent` de clairière (touffes hautes, buissons fleuris, bouquets) semée au boot comme la canopée : ce qui doit se voir de loin ne se stream pas
- [ ] Bake `NavigationRegion3D` après le scatter ; rivière et falaise infranchissables, gué praticable
- [ ] Corriger dette Jalon 1 (navmesh/branches)
### Passe B3 — habillage du sol par textures ✅
- [x] `terrain.gdshader` réécrit : cinq matériaux texturés (herbe, litière, caillouteux, falaise, sable) choisis par couvert, altitude, pente et proximité de l'eau
- [x] Mélange par carte de hauteur (`height_weights`) au lieu d'un fondu linéaire — les frontières s'imbriquent
- [x] Occlusion ambiante des packs, reportée sur l'albédo et passée au moteur
- [x] Échelle par matériau sous une échelle maîtresse ; triplanaire réservé à la falaise
- [x] Normalisation des cartes de hauteur sur leur plage utile mesurée (`*_height_range`)
- [x] Reconstruction du canal Z des normales (RGTC n'en stocke que deux)
- [x] `TerrainMeshBuilder.build_chunk()` reçoit le matériau ; `TerrainController._ground_material()` en duplique un exemplaire par génération pour y écrire `water_level`
- [x] `FoliageDef.align_to_slope` + enfoncement fondé sur `base_radius` — les rochers épousent le sol au lieu de flotter
- [x] Petits cailloux retirés (`pebble_round` des deux biomes, `pebble_square` de `scree`) ; rochers moyens plus présents, en filaments, jusqu'au pied des parois
- [x] Force de normale **par matériau** (`*_normal_strength`, multiplicateurs de la force maîtresse) : la normal map de la falaise n'encode que ~3° de pente moyenne contre ~16° pour la litière. Correction de fond au passage : la falaise employait la force comme un **facteur de fondu borné à 1**, donc aucune valeur ne pouvait la redresser — l'amplification est remontée sur la tangente, avant la recomposition triplanaire. Falaise à 3,5.
- [x] Ménage : UV du mesh et `TerrainGenConfig.uv_scale` supprimés (sans lecteur depuis le passage en coordonnées monde) ; variantes 1k, `sand_01` et `sand_03` supprimées des assets, `ASSETS.md` et `ATTRIBUTION.md` mis à jour

### Passe D — personnalité de la carte : catalogue de features et lieux-dits
> **Discuté, pas commencé.** Constat de départ : le générateur n'a qu'un seul type de feature — le massif — et tout le reste en dérive. Une graine ne change donc qu'une orientation et trois dimensions ; la *composition* est identique à chaque fois. Et ce qui n'est pas le massif est du bruit, qui par construction n'a pas d'échelle privilégiée et ne fabrique donc jamais de lieu. Les clairières rondes et les coins à champignons introuvables sont les deux symptômes.
- [x] `HeightmapSignature` : empreinte SHA-256 de tout ce que le générateur publie, sur N graines, avec écriture de référence et comparaison. C'est l'outil qui rend vérifiable « à graine égale, carte identique » — sans lui, un remaniement neutre est une intention.
- [x] Extraire `MassifShape` : la forme portait des champs du générateur, donc il ne pouvait en exister qu'un. La vallée est restée dans le générateur (une carte, une vallée) et le `rng` lui est fourni. **Douze graines identiques à la référence.**
- [x] Extraire `HeightmapOps` : possède `heights`, expose `sample`, `gradient_at`, `flatten_disc`, `carve_channel`, et factorise le calcul d'emprise en indices de grille que les deux opérateurs recopiaient. Générateur de 420 à 299 lignes.
- [ ] Opérateur de paliers dans `HeightmapOps` — une falaise réelle est stratifiée, la nôtre est une rampe régulière. Écrit avec la première feature qui l'emploie, pas avant : un opérateur sans client est du poids mort.
- [ ] `TerrainFeature` en catalogue tiré avec quotas : contrefort (le même code appelé deux fois — ferme la vallée), affluent, cuvette, plaine, carrière, belvédère. **Trois crans d'exécution** : ce qui sculpte passe avant le calcul du niveau d'eau, ce qui suit l'eau après le creusement de la rivière, ce qui se *cherche* sur un relief définitif.
- [ ] Zones dérivées (jamais dessinées) : sommet, pentes, pied de massif, vallée rive bunker, vallée rive opposée, arrière-pays, abords du lac — plus trois zones **linéaires** (cours de la rivière, ligne de falaise, rivage). Quotas par zone et par catégorie (esthétique / contraignant).
- [ ] `Site` publié par le générateur : position, emprise, **direction et largeur de dégagement**, capacité, qualités du terrain, nom composé de deux clés du CSV. Un site porte des **qualités, jamais des activités** — le Jalon 8 déclare ce qu'une activité cherche.
- [ ] Catalogue préliminaire des spots, par zone. Trente entrées pour trois à cinq tirées par carte : c'est l'**unicité** qui fait la personnalité, pas le nombre. Une feature présente sur toutes les cartes redevient du décor au bout de trois parties. Seuls le porche de grotte et le gué sont obligatoires.
  - **Sommet et crêtes** — belvédère (vue plongeante) · arête étroite entre deux vides · cairn ou rocher-repère au point haut
  - **Pentes rocailleuses** — éboulis à traverser *(contraignant)* · vire, replat étroit accroché à la pente avec vue · source sortant de la roche, qui démarre l'affluent
  - **Pied de massif boisé** — porche de grotte *(obligatoire, c'est le bunker)* · seconde cavité, plus petite · chaos de blocs mousseux · carrière abandonnée
  - **Vallée fluviale, rive bunker** — plage de galets · pré inondable · terrasse dominant le cours
  - **Vallée fluviale, rive opposée** — boucle de rivière avec îlot · berge en falaise · confluence de l'affluent
  - **Forêt d'arrière-pays** — tapis de fleurs à l'échelle d'une clairière entière · coin à champignons *trouvable* · bois très dense, presque impénétrable *(contraignant)* · trouée de troncs brûlés
  - **Abords du lac et rivage** — crique abritée · prairie humide · avancée rocheuse dans l'eau · arbres morts noyés
  - **Cours de la rivière** *(linéaire, pas dans une aire)* — cascade · gorge encaissée *(contraignant, coupe le passage)* · gué *(obligatoire)*
- [ ] Registre de réservation d'emprise entre features — même principe que `ScatterOccupancy`, un étage plus haut : une feature ne peut pas en recouvrir une autre sans le déclarer.
- [ ] Outil de planche de graines : douze cartes générées en heightmap seule (sans mesh ni végétation), affichées en vignettes ombrées. **Ne pas générer en cellule grossie** — les features ont des tailles en mètres, une carte réduite n'est pas la même carte.
- [ ] Vérificateur d'invariants sur N graines (rivière qui atteint l'aval, clairière du bunker plane, grotte hors de l'eau, sites atteignables, quotas tenus). C'est ce qui remplace les tests unitaires : une composition qui change est normale, un invariant violé est un bug. **Distinct de `HeightmapSignature`**, qui dit « la carte a changé » et non « la carte est valide » — dès que les features existent, une carte qui change est normale et l'empreinte n'a plus rien à dire.
- [ ] Cime marquée sur le massif — sur les captures actuelles, même du meilleur point de vue accessible, on voit une croupe allongée sans point culminant. Et rapport hauteur/largeur resserré : à 200 m pour 250 m de demi-largeur, c'est une colline.
> **Décisions tranchées.** Les deux premières étaient la même question — *où vit le réglage d'une feature* : une classe par type de feature (`apply(ops, ctx)`), un `.tres` par réglage de cette classe, et `TerrainGenConfig` ne porte que le catalogue et les quotas. Motif `BiomeDef` à l'identique, avec la nuance qui compte : un biome est déclaratif, une feature exécute — d'où la classe sous le `.tres`. Une même classe donne plusieurs entrées de catalogue (un contrefort trapu et un étiré ne sont pas deux classes).
> **Le joueur ne renomme pas un lieu-dit.** Un nom est composé de deux clés du CSV, donc traduit ; un nom saisi est une chaîne libre, intraduisible, et qui casse la règle « aucun texte affichable hors du CSV » du Jalon 3.5. Surtout, le terrain se régénère et ne se sauvegarde pas : un nom personnalisé serait la première donnée du monde à devoir survivre à une régénération. La porte reste ouverte à coût nul tant que `Site` porte ses `name_keys` et que l'affichage passe par un point unique — voir la dette au Jalon 10.
> **Règle structurante** : une feature ne nomme jamais une autre feature. Elles se parlent par qualités du terrain, jamais par identité — sinon chaque ajout redevient une modification des anciennes. C'est la règle biome/essence, remontée d'un cran.
> **Dette à ouvrir en même temps** : la position en travers de la rivière (nécessaire au troisième biome) se publie dans le générateur — l'écrire pendant qu'on y est. Et au troisième critère, les champs nommés de `BiomeDef` devront céder à une liste de critères.

### Passe C — grotte, falaise et lointain
> Dépend du Jalon 4.4 : le raccord du lointain se juge sur la brume et la couleur d'horizon, pas sur la géométrie.
- [ ] Grotte d'entrée : porche posé sur le site publié par le générateur (`CaveSite`), scène séparée reliée par téléportation. C'est là que le bunker sera rebâti.
- [ ] Rochers du pack posés sur l'escarpement : le relief donne la pente, les meshes donnent la paroi
- [ ] Bordure de zone sur les côtés non noyés par le lac
- [ ] Chaîne lointaine hors zone jouable : maillage grossier, sans collision, végétation ni navmesh. Non traversable — le rayon d'action du robot (Jalon 6) fera de toute façon barrière avant. Exigence de raccord : aucune coupure visible entre la zone praticable et cette chaîne, ni en silhouette ni en couleur — elle doit se fondre dans la perspective aérienne du brouillard, pas apparaître comme un décor plaqué à la limite du monde.
- [ ] Cascade, en feature du biome montagne rejoignant la rivière
- [ ] Gorge : passage encaissé entre deux parois sur une portion du cours — feature de relief, pas de végétation
### Dette Jalon 4
- **Le shader de sol lit ses cinq couches à chaque pixel** — une quarantaine de lectures de texture au pire — alors que deux au plus contribuent. GDShader n'accepte pas un `sampler2D` en argument de fonction : la sortie est un `Texture2DArray` et une sélection des deux poids dominants, qui ramènerait le coût à une douzaine de lectures constantes. À faire quand le coût se mesure ; les cinq blocs de lecture recopiés disparaîtront du même coup.
- **La passe de détail réutilise la texture principale en miniature.** `detail_normal` est donc à 0 par défaut : monté, il fait voir le relief des petites formes pendant que la couleur montre les grandes. Correctif propre : une carte de grain dédiée, sans formes reconnaissables, partagée par les cinq matériaux.
- **Le tuilage de la falaise se lit** depuis que ses normales sont exagérées — on a amplifié le motif de répétition avec le relief. Rattrapages possibles (`tint_strength`, force moindre) ; le correctif réel est l'opérateur de paliers de la passe D, qui donnera à la paroi une stratification géométrique.
- **Les neuf `.tres` de galets ne sont plus dans aucune palette** (`pebble_round_1-3`, `pebble_square_1-6`). Conservés parce qu'ils serviront au lieu-dit « chaos de blocs » quand le catalogue de features existera ; à supprimer si cette feature ne se fait pas.
- **Le relief du sol par décalage d'UV est un chantier fermé.** Parallaxe en une passe puis POM à seize pas : les deux ont été écrits, testés et retirés. La cause n'est pas dans le shader (voir STATE §Habillage du sol). Ne pas rouvrir sans changer l'albédo ou l'éclairage.
- **Le scintillement du feuillage est masqué par la brume, pas corrigé.** La densité actuelle le cache à toute heure ; un profil de ciel moins dense ou une journée claire le feraient réapparaître. Cause probable : le fondu de distance du feuillage (voir le gotcha `VISIBILITY_RANGE_FADE_SELF` en fin de STATE).
- **L'occupation des strates streamées est locale à la tuile** (24 m), et non au chunk (96 m) : deux plantes peuvent se chevaucher à une frontière, quatre fois plus souvent qu'avant. Invisible sur l'herbe à 0,8 m d'espacement, à surveiller sur `shrub` dont les buissons sont plus larges.
- **Le budget de semis se teste après chaque tuile**, jamais pendant : une tuile ne s'interrompt pas en cours de route, donc le pic vaut `stream_budget_ms` plus une tuile. Si une tuile devient chère, c'est `stream_tile_cells` qu'on baisse, pas le budget.
- **Les `.tres` de taches portent `min_slope_degrees = null` / `max_slope_degrees = null`** — sérialisation antérieure à ce jalon, sur des `@export_range` float. À vérifier : si `max_slope_degrees` se relit à 0, ces taches ne se déclarent quasiment jamais. Cousin du gotcha « renommage de propriété exportée ».
- **Une quinzaine d'essences ne sont dans aucune palette** (`bush_common_dry`, `plant_2_big`, `plant_6`, `plant_7_big`, `petal_*`…). Certaines volontairement (`tall_thick_2` et son trou noir, `mushroom_oyster` réservé à l'épiphyte), pas toutes. Stock disponible pour le prochain biome.
- **`cover_amount` dépend de l'espacement de la strate.** À 7 m avec un rayon de 7,5 m, chaque point reçoit l'ombre de ~3,5 arbres : au-delà de 0,42 la couverture sature à 1 partout et la carte d'ouverture perd toute dynamique. À reprendre si l'espacement de la canopée change.
- **Le coût des taches est linéaire en leur nombre** : chaque candidat teste le bruit de chaque tache avant de retomber sur la base — sept gates sur la strate sol en forêt claire. Fusionner les quatre taches de fleurs en une seule dont un second bruit choisit la couleur ramènerait sept à quatre.
- **La pente se calcule pour tous les candidats** depuis qu'elle sert à choisir la tache, et plus seulement pour ceux qui passent les filtres. À ne calculer que si une tache de la strate en dépend, si le semis d'un chunk devient sensible.
- **`clearing_uniform` tire dans la palette entière** : si l'essence désignée au centre est marginale, le tapis est clairsemé sans être vide. Le correctif propre est une palette dédiée aux clairières plutôt qu'un rattrapage de poids.
- **`tint` sur `FoliageDef` toujours pas posé**, et `BiomeDef` existe désormais. Les taches se montent donc à la main, biome par biome — c'est tenable à deux biomes, ça ne le sera plus à cinq. `ASSETS.md` tient l'inventaire en attendant.
- **Pas de LOD sur la végétation.** Partiellement payé par la distance d'affichage : on ne simplifie pas les arbres lointains, on cesse de les dessiner. Un vrai LOD ou des imposteurs restent à faire si la distance d'affichage devient insuffisante.
- **`foliage_view_distance` masque le feuillage dans l'éditeur** dès qu'on recule la caméra pour voir la carte. Ce n'est pas un bug, mais ça surprend : monter la valeur temporairement pour inspecter la carte de haut.
- **`TallThick_2` a un trou noir dans son tronc** — défaut de la scène du pack, absent du glTF, sans surcharge de matériau en cause. Retiré de la liste d'essences. À traiter avec les autres corrections d'assets tiers, et à noter dans ATTRIBUTION le jour où on modifie le pack.
- **Collision terrain en `ConcavePolygonShape3D`** et non `HeightMapShape3D` : ce dernier échantillonne à 1 unité fixe, incompatible avec une cellule de 3 m sans scaler le `CollisionShape3D` de façon non uniforme. Repasser dessus si le coût des requêtes physiques se voit au Jalon 5.
- **Eau sans collision** : on traverse le plan d'eau. À traiter quand le gué comptera (Jalon 5) ou au Jalon 6 avec l'énergie.
- **Seuils du shader en mètres absolus** alors que la hauteur du massif est tirée entre 160 et 260 m : la roche monte plus ou moins haut selon la graine. À exprimer en fraction de la hauteur tirée si ça se remarque.
- **Fond de vallée lisse** : atténuation à 0,85, nécessaire pour que la descente de gradient de la rivière ne s'échoue pas. Devrait disparaître sous la végétation.
- **Le tracé de rivière est guidé**, pas érosif. C'est ce qui garantit la topologie 2/3 – 1/3 quelle que soit la graine.
- **Un seul massif par carte.** Des buttes secondaires seraient le même code appelé plusieurs fois ; pas avant d'en avoir le besoin.
- **Génération monofil dans la frame** : ~6,2 s pour le terrain et ~4,3 s pour le semis, mesurés après l'ajout des biomes et le pré-filtrage des clairières. Sans conséquence tant que la carte se génère au chargement ; à découper (`WorkerThreadPool` ou étalement) le jour où elle se régénère en cours de partie.
- **Step-up et saut pas revalidés sur pente irrégulière** — dette reprise du Jalon 3.
- **`forest_test.tscn` et `forest_scatter.gd` sont périmés** mais conservés : ce sont les seules scènes où les mécaniques de jeu sont testables. À supprimer quand elles auront une scène d'accueil dans le nouveau format — sans quoi il existe deux façons de peupler une forêt dans le projet.
- La vitesse du joueur est très élevée (~13 m/s mesurés, soit le double d'un sprint humain). La réduire est le levier le moins cher pour agrandir la carte sans générer un triangle de plus. À traiter à la passe de feeling du Jalon 6.
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
### Passe C — plancher d'élévation
> Requalifiée après test : le décrochage d'ombres attendu ne se voit pas, parce que la coupure de `shadow_enabled` intervient avant que la tangente ne s'effondre. Reste une ceinture de sécurité.
- [ ] `maxf()` sur l'élévation dans `foliage_proximity.gd` : la division par `tan(élévation)` peut produire un `inf`, et un `inf` dans une comparaison de distance ne lève rien du tout
### Dette Jalon 4.4
- **Lune** : disque lisse plaqué à l'opposé du soleil, sans phases ni éclairage propre. Une « vraie » lune est trois chantiers distincts — la **course** (mêmes formules que le soleil, décalées, avec une période légèrement différente pour que les phases dérivent seules) ; les **phases** (fraction éclairée déduite de l'angle lune/soleil, ce qui impose un disque éclairé et non plaqué — c'est là qu'est le travail de shader, et une phase qui ne s'accorde pas avec la position du soleil se voit immédiatement) ; l'**éclairage nocturne** (seconde `DirectionalLight3D`, énergie pilotée par la phase, qui remplacerait une partie de l'ambiante de nuit faite à la main et obligerait la coupure d'ombre du feuillage à raisonner sur deux astres). Le patch de shader de la course et celui de la texture sont **le même bloc de six lignes** : les traiter ensemble.
- **Pas de nuages à l'horizon** : le shader les éteint sous 0,2 en `EYEDIR.y` et ne les pose que sur un plan au-dessus de la tête. Pas de banc de nuages sur les crêtes lointaines, alors que c'est un ingrédient Firewatch. La brume porte la profondeur à leur place.
- **Étoiles en projection planaire XZ** : elles s'étirent au zénith et ne tournent pas avec le ciel. À reprendre avec la lune.
- **Les textures de nuages ne se mélangent pas** : un `SkyProfile` ne fait donc varier que des uniformes, et tous les profils partagent la paire de textures du rig. Si le climat exige des formes de nuages franchement différentes, ce sera une passe de shader (deux jeux de textures et un mélange), pas un contournement.
- **Trois `clamp(0.0, 1.0, x)` aux arguments inversés** dans le shader du pack (lignes 83, 88, 93). Le résultat tombe juste par chance. Noté pour ne pas rediagnostiquer.
- **`sun_off_threshold` coupe l'ombre, jamais la lumière** : le soleil reste toujours visible, sinon le ciel perd `LIGHT0_DIRECTION`. Une directionnelle à énergie nulle reste soumise au rendu — coût mesuré négligeable, à revérifier si le budget lumière devient serré.
- **Répartition et durée du cycle posées à l'œil** (30 min, 5/10/6/9). À revalider quand les pawns auront des activités qui dépendent de l'heure.
- **Brume et ambiante réglées au jugé**, y compris la nuit. La courbe de brume doit rester assez courte à toute heure pour masquer la coupure du feuillage : c'est son **minimum** sur la journée qui compte, pas sa valeur de midi.
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
- [ ] Tâches d'agrément déclenchées par l'heure — aller voir un couchant depuis un point de vue. Les deux mesures de `TimeOfDay` existent pour ça depuis le Jalon 4.4 : un pawn compare le temps de trajet au temps restant avant le crépuscule, et à sa durée.
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
> Piste visuelle : un `SkyProfile` dégradé (les presets `dark_sky` et `red_sky` du pack existent) rendrait la bascule lisible sans un mot. Le mécanisme de fondu entre profils est celui du climat.
## Jalon 13 — Expéditions & fins
- [ ] Système d'expédition hors rayon robot : contrôle délégué au groupe parti
- [ ] Objectifs typiques : souche absente localement, autre communauté, zone écologique différente
- [ ] Résolution en tâche longue avec risque réel
- [ ] Trois branches de fin :
  - **Fin standard** — shutdown du bunker atteint, bilan des pawns sauvés
  - **Game over anticipé** — robot perdu hors périmètre, non secouru
  - **Bonne fin — robot éternel** — tous les dormants sauvés, choix final (variantes lié-mortel / isolé-éternel)
## Features non planifiées
- **Climat et intempéries** — l'axe est orthogonal à l'heure : le shader gère le moment via l'élévation du soleil, un `SkyProfile` décrit le temps qu'il fait. Changer de temps est un fondu d'un profil vers un autre sur quelques minutes. Contrainte à respecter : un profil ne fait varier que des uniformes, jamais des textures.
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