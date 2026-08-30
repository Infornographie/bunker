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
> **Périmé par le Jalon 4.** `bunker_exterior_test.tscn` a été construit sur un sol plat ; le terrain procédural fournit désormais un site de grotte à l'origine du monde, et le bunker sera rebâti là. La scène actuelle sert de réserve de pièces, pas de livrable.
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
- [x] Sound manager de base (`autoloads/sound_manager.gd`, pool de `AudioStreamPlayer3D`) → SFX ponctuels positionnés, hook posé sur `Choppable.chop_sound` (pas encore d'asset son assigné).
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
> - Intégration Universal Animation Library 2 — de toute façon à revalider au chassis robot (J6)
 
### Dette Jalon 3
- Le protagoniste est officiellement un robot (cf. GDD) : l'apparence humaine implicite du viewmodel/main tenant la hache est temporaire — chassis robot + bras/effecteur traités au Jalon 6.
- **Pas de menu de sélection de bâtiment** : `BuildModeController` expose un unique `building_def` à l'inspecteur. Le menu devient nécessaire au deuxième `BuildingDef`. À traiter au Jalon 11 au plus tard, ou dès qu'un deuxième bâtiment arrive.
- Physique des rondins pas réglée (friction/rebond par défaut, roulis parfois excessif) — à ajuster via Physics Material sur le RigidBody3D.
- Objet porté en main pas contraint en taille/collision au HandAnchor — un futur objet plus gros qu'un rondin pourrait traverser le viewmodel ou sortir du champ visuel — à surveiller au cas par cas.
- La hache traverse les murs/arbres quand la caméra s'en approche (viewmodel sans profondeur séparée du monde). Piste : caméra/layer dédié au viewmodel avec son propre near/far.
- Swing statique, manque de "punch" (pas de squash/stretch, transform linéaire). Piste : easing sur le Tween, ou anim dédiée si Universal Animation Library le permet.
- FX minimal manquant à l'impact (particules bois, léger shake caméra) — rien pour l'instant, juste le son non assigné.
- Ombre flottante de la hache (pas de bras) — résolue par le chassis robot au Jalon 6.
- Course/saut gratuits pour l'instant alors que le GDD prévoit que toute action du robot passe par l'énergie — à rattacher au pool d'énergie local du Jalon 6.
- Feeling course/saut non réglé (valeurs de départ posées à l'inspecteur : ×1.6, jump 4.5, coyote 0.12, FOV +8). Passe de réglage au Jalon 6, quand la silhouette et l'échelle réelle du protagoniste seront fixées.
- Pas de head bob ni de son de pas — la course se lit surtout au FOV. À traiter avec le FX/audio général.
- ToolPickup posé au sol : collision BoxShape3D générique (pas calée au mesh réel), pas de rotation couchée au drop (la hache se plante debout). À ajuster quand on aura plus d'outils à tester.
- Icônes générées au premier affichage : léger hoquet possible à la première ouverture d'un panneau contenant des objets jamais vus. Acceptable ; si ça devient visible, pré-générer au chargement de la partie.
- Grille 3x3 = 9 slots au lieu des 10 annoncés au GDD — GDD à mettre à jour (9 + 3 poches = 12, plus cohérent).
- `grilled_mushroom` = champi cru avec albedo teinté brun. Asset dédié à faire, aucune urgence.
- Cuisson : une recette à la fois, pas de brûlé si on oublie, ingrédients non visibles sur les braises. Assumé tant que le feu est le seul site de transformation.
## Jalon 3.5 — Localisation (infrastructure L10N) ✅
> Petit jalon transverse posé avant J4 : mettre en place la l10n maintenant coûte 30 min, l'ajouter après 6 mois de strings hardcodées coûte des heures. Décision : dev en **anglais** (langue source, garantit des clés stables si le texte évolue) et **français** disponible dès maintenant pour permettre les playtests du fils d'Anthony.
 
- [x] `translations/strings.csv` — première colonne = clé, colonnes `en`, `fr`. Rangé en sections (ligne à première colonne vide = ignorée à l'import), alphabétique à l'intérieur.
- [x] Convention de clés : `namespace.section.key`
- [x] Autoload `Locale` (`autoloads/locale.gd`) — wrapper `TranslationServer`, fallback `en`
- [x] Migration des strings existants vers clés + `tr()` : `prompt_text` → `prompt_key`, `display_name` → `name_key`
- [x] Le `tr()` centralisé sur les seuls points d'affichage (trois aujourd'hui, voir STRUCTURE §Flux de localisation) — pas de helper intermédiaire
- [x] Clés de cache d'icônes rebasées sur `ToolDef.id`/`ResourceDef.id` au lieu du nom affiché
- [x] Bascule debug EN ↔ FR sur **F10** — F8 et F9 écartées, réservées à l'éditeur en fenêtre embarquée
- [x] Project settings : `internationalization/locale/fallback = en`
- [x] Mise à jour docs à la clôture : INPUTS.md, STRUCTURE.md, STATE.md
> Deux migrations manquées, détectées et corrigées au J3.6 : un slot d'inventaire lisait encore `resource.display_name` (propriété supprimée), et `InteractionController._refresh_prompt()` passait la string "Déposer" en dur à `tr()` (désormais `interact.prompt.drop`).
 
### Dette Jalon 3.5
- Format `.po` (gettext, standard pour LQA externe) pas retenu — CSV suffit pour un dev solo avec peu de strings.
- Pas de gestion de la pluralisation ni des accords genre à ce stade — à ajouter au premier besoin réel.
- **Aucune vérification qu'une clé utilisée existe dans le CSV** : `tr()` sur une clé absente affiche la clé brute, sans erreur ni warning. À revoir si le volume grossit — piste : script d'éditeur croisant les `tr(...)`/`_key` du projet avec les colonnes du CSV.
## Jalon 3.6 — Panneau de cuisson & interfaces du monde ✅
> Posé après la l10n : une UI neuve écrite avant les clés de traduction, c'est des strings à remigrer aussitôt.
>
> **Changement de cap en cours de jalon.** Les passes A à C ont livré des panneaux `Control` ancrés à l'écran, avec curseur souris, gel du joueur et drag & drop natif. Testé, fonctionnel, commité — et abandonné : manier deux panneaux à la fois était impraticable, et la caméra passait son temps à se battre avec le curseur. Décision retenue (voir STATE) : plus de curseur, le réticule est le pointeur, et les panneaux deviennent des objets 3D dont les cases sont des `Interactable`. Le drag & drop natif de Godot devenant inutilisable sans souris, la réécriture était de toute façon obligatoire.
 
- [x] **Passe A** — `ItemSlot` et `WorldAnchoredPanel` extraits de `BackpackUI`, plus `UIPanelController`, l'arbitre de modes annoncé dans STATE. *(Les deux premiers ont été remplacés à la passe D ; l'arbitre a survécu.)*
- [x] **Passes B et C** — panneau de cuisson en `Control`, prompt contextuel (`Interactable.get_prompt_key()`), E contextuel sur le feu. *(Panneau remplacé à la passe E ; le prompt contextuel et le E contextuel ont survécu.)*
- [x] **Passe D** — socle 3D : `WorldPanel` (suivi d'ancre, billboard axe Y), `PanelSlot` (hérite `Interactable`), couche de collision « UI 3D », arbitre allégé (plus de souris ni de gel), sac porté dessus. `InteractionController.take_into_hand()` : prendre dans une case met l'objet en main pour de vrai.
- [x] **Passe E** — panneau de cuisson 3D : colonne de recettes illustrées par le plat produit, cases d'ingrédients avec fantôme de l'attendu (une case par unité), case combustible, jauges de progression et de combustible (`PanelGauge`).
- [x] Corrigé au passage : `IconGenerator` produisait des icônes composites (viewport partagé rémanent → un viewport jetable par icône), et `_try_use_pocket_item()` jetait l'objet au sol dès qu'une cible interactive refusait la ressource.
- [x] **Passe F** — nettoyage : action morte `cancel_build_mode` supprimée (branche + Input Map + doc d'en-tête), et `Choppable.pickup_scene` remplacé par `drop_resource: ResourceDef` résolu via `ResourceRegistry`. Il n'y a plus qu'une seule façon d'obtenir un pickup dans le projet.
- [x] Mise à jour des docs à la clôture : INPUTS.md, STRUCTURE.md, STATE.md
### Dette Jalon 3.6
- **Les panneaux ne sont pas occultés** (`no_depth_test` sur cases, icônes, libellés et jauges) : c'est ce qui les rend lisibles devant une flamme ou derrière une herbe, mais un panneau se voit aussi à travers un mur. Tolérable tant qu'il se ferme dès qu'on s'éloigne de son ancre ; à revoir si ça se remarque en intérieur au Jalon 4.
- Pas de fermeture à l'angle : se détourner sans s'éloigner laisse le panneau ouvert derrière soi. À trancher au feeling.
- Aucun retour visuel sur la case visée en dehors du prompt : pas de surbrillance de la case sous le réticule. `PanelSlot` a la structure pour (matériau déjà en variable), c'est une passe de polish.
- Tailles des panneaux posées à l'œil (case 0,22 m, 0,26 m pour le feu ; hauteur d'ancre 0,9 m et 1,6 m). Critère de réglage retenu : viser une case ne doit demander aucun micro-ajustement. À revalider au chassis robot (J6), qui change la hauteur de vue.
- Une case ne contient qu'un objet et ne s'échange pas : sans glisser-déposer, poser sur une case occupée est refusé au lieu de permuter. Simple, peut-être trop — à réévaluer si ça gêne à l'usage.
- Pas de feedback sonore ni d'animation à l'ouverture d'un panneau ni au transfert d'un objet. À traiter avec le FX/audio général.
## Jalon 4 — Terrain procédural
> Découpé en passes testables. La passe A remplace le sol plat : tout ce qui suit se pose dessus.
 
### Passe A — relief jouable ✅
- [x] `terrain_gen_config.gd` (Resource) : graine, taille de zone, fourchettes de massif, refs `FastNoiseLite` par couche, réglages vallée/rivière/lac/clairière. Porte aussi la convention de grille (`grid_size()`, `height_index()`, `world_pos()`) — source unique des coordonnées pour toute la chaîne.
- [x] `heightmap_generator.gd` : tirage du massif à la graine → relief (vallonnement + pente d'écoulement + massif + falaise + vallée) → niveau de l'eau → clairière du bunker → tracé et creusement de la rivière. Publie `heights`, `cave_position`/`cave_forward`, `water_level`.
- [x] Massif paramétrique : orientation, longueur, largeur et hauteur tirées de la graine dans des fourchettes réglables. Chaîne traversante, pic ou massif directionnel sont le même code, selon le rapport longueur/largeur.
- [x] `terrain_mesh_builder.gd` : hauteurs → chunks `ArrayMesh` + collision, normales calculées sur le tableau global (chunks raccordés sans couture ni code de recollement)
- [x] `terrain_controller.gd` : orchestrateur `@tool`, boutons Régénérer / Effacer, nœuds générés sans owner (jamais sérialisés dans le `.tscn`)
- [x] `terrain.gdshader` : habillage par altitude et pente (herbe → roche → paroi nue), sans donnée supplémentaire
- [x] Lac : niveau d'eau déduit du fond de vallée au rivage choisi, plan d'eau plus large que la zone. Le rivage n'est pas tracé, c'est ce qui dépasse.
- [x] Perf mesurée : **1361 ms** pour 1200 m × cellule 3 m (161 000 sommets, 320 000 triangles, 169 chunks)
### Passe B — biomes et végétation
- [ ] `biome_map_generator.gd` : **poids** de biome par cellule (jamais d'identifiant — c'est ce qui donne les dégradés sans code de frontière), carte de pente, carte d'humidité, distances de lisière
- [ ] Carte d'ouverture calculée **après** la strate canopée (densité d'arbres locale + ombre du relief) : c'est elle qui pilote la strate sol. Corollaire visé : déboiser fait pousser l'herbe.
- [ ] `BiomeDef` et `PatchDef` en `.tres` — le scatter ne référence aucun asset en dur. Les biomes portent les tags exploités au Jalon 10, les patchs (coin à champignons, bosquet fleuri, éboulis, clairière) sont posés par-dessus.
- [ ] Scatter en strates (canopée → arbustive → sol → épiphyte sur troncs et rochers), par chunk
- [ ] `MultiMeshInstance3D` pour tout le décoratif non interactif ; arbres instanciés (`Choppable`) seulement dans un rayon autour du joueur, multimesh sans collision au-delà
- [ ] Biomes disponibles avec le pack Pro : forêt claire, forêt sombre (conifères), forêt d'automne, aride. Bosquet en fleurs et clairières traités en patchs, pas en biomes.
- [ ] Bake `NavigationRegion3D` après le scatter (même contrainte d'ordre que Jalon 1) ; rivière et falaise déclarées infranchissables, gué praticable
- [ ] Corriger dette Jalon 1 (navmesh/branches) avant le déplacement des pawns
### Passe C — grotte, falaise et lointain
- [ ] Grotte d'entrée : porche posé sur le site publié par le générateur (`CaveSite`, à l'origine du monde), scène séparée reliée par téléportation — même principe que le sous-sol bunker. C'est là que le bunker sera rebâti.
- [ ] Rochers du pack posés sur l'escarpement : le relief donne la pente, les meshes donnent la paroi. Une heightmap ne fait pas de vertical.
- [ ] Bordure de zone sur les côtés non noyés par le lac
- [ ] Chaîne lointaine hors zone jouable : maillage grossier, sans collision, sans végétation, sans navmesh. C'est elle qui porte l'échelle « montagne » (500 à 1000 m) que la zone jouable ne peut pas porter.
- [ ] Cascade, en feature du biome montagne rejoignant la rivière — pas en propriété du relief
### Dette Jalon 4
- **Collision terrain en `ConcavePolygonShape3D`** (trimesh issu du mesh de chunk) et non `HeightMapShape3D` comme prévu : ce dernier échantillonne à 1 unité fixe, incompatible avec une cellule de 3 m sans scaler le `CollisionShape3D` de façon non uniforme, ce que Godot supporte mal. Le trimesh sort de la même `ArrayMesh`, donc pas de double source. Repasser dessus si le coût des requêtes physiques se voit au Jalon 5.
- **Eau sans collision** : on traverse le plan d'eau. À traiter quand le gué comptera vraiment (Jalon 5, déplacement des pawns) ou au Jalon 6 avec l'énergie.
- **Seuils du shader en mètres absolus** (roche 70→125 m, paroi 30°→44°) alors que la hauteur du massif est tirée entre 160 et 260 m : la roche monte plus ou moins haut en proportion selon la graine. À exprimer en fraction de la hauteur tirée si ça se remarque.
- **Fond de vallée lisse** : l'atténuation du vallonnement y est à 0,85, nécessaire pour que la descente de gradient de la rivière ne s'échoue pas dans une cuvette fermée. Devrait disparaître sous la végétation en passe B ; sinon descendre à 0,7 et compenser par la pente d'écoulement.
- **Le tracé de rivière est guidé**, pas érosif : attirance de 0,35 vers l'axe de vallée. C'est ce qui garantit la topologie 2/3 – 1/3 quelle que soit la graine. Une vraie érosion hydraulique serait plus juste et beaucoup plus chère — pas au programme.
- **Un seul massif par carte.** Des buttes secondaires seraient le même code appelé plusieurs fois ; pas avant d'en avoir le besoin.
- **Génération monofil dans la frame** (1,4 s). Sans conséquence tant qu'on régénère à la main ; à découper (`WorkerThreadPool` ou étalement sur plusieurs frames) si ça arrive en cours de partie. Levier principal identifié si besoin : le calcul des normales dans `terrain_mesh_builder.gd`, pas la heightmap.
- **Step-up et saut pas revalidés sur pente irrégulière** — dette reprise du Jalon 3, toujours ouverte : ils sont calibrés sur du plat et des marches SciFi.
- Le vallonnement s'efface sur la falaise pour garder une paroi lisse. Le masque déborde et s'éteint progressivement, faute de quoi il creuse une rainure sur toute la hauteur (bug rencontré et corrigé) — ne jamais le repasser en binaire.
## Jalon 5 — Réveil de pawn + ordres directs
- [ ] Pawn dormant scripté (état sommeil → réveil via interaction robot)
- [ ] `ActionStateMachine` pawn (idle / se_deplacer / tâche_courante) via `NavigationAgent3D` — prépare les états `EVALUATING`/`INTERRUPTED` utilisés au Jalon 8
- [ ] Sélection de pawn (proximité ou liste rapide) — réutilisée par la roue de réaction au Jalon 6, et à déclarer dans `UIPanelController.exclusive_modes`
- [ ] Ordres directs minimaux (suivre / reste / va-là) — préfigure la roue
- [ ] Corriger dette Jalon 1 (navmesh/branches) avant de tester le déplacement des pawns
## Jalon 6 — Robot : identité, énergie, communication
> Chassis, énergie et communication du robot, maintenant testables contre de vrais pawns plutôt qu'en solo. La partie sociale reste au Jalon 9, une fois les relations disponibles (J7).
 
- [ ] Chassis robot (visuel + rigging) remplaçant l'apparence humaine implicite du contrôleur — bras/effecteur porteur d'outils
- [ ] Pool énergie **local** (jauge embarquée, recharge au bunker central) — inclut le coût de course/saut posé en dette Jalon 3
- [ ] Passe de réglage du feeling course/saut sur le chassis définitif, et revalidation de la taille des panneaux (la hauteur de vue change)
- [ ] Pool énergie **bunker global** (décrément continu, horloge de fin de partie, quasi non-rechargeable)
- [ ] Rayon d'action = énergie (calcul aller-retour + alerte visuelle avant seuil critique, pas de mur invisible)
- [ ] Roue de réaction (radial menu) : oui / non / suis-moi / reste / reprends ton activité — réutilise la sélection de pawn du Jalon 5, et se déclare dans `UIPanelController.exclusive_modes`
- [ ] Bulles techniques robot (diagnostics, alertes) — pas d'émotions, marque l'altérité
## Jalon 7 — Portage simulation temps réel
- [ ] Fatigue **par catégorie d'action** (float par pawn par catégorie, decay au switch de tâche)
- [ ] Relations par accumulation de coprésence/co-tâche dans le temps (nourrit le `modificateur_partenaire` du Jalon 8 et la qualité d'atelier du Jalon 9)
- [ ] Portage `EventConfig`/`EventManager` (turn-locking → pause ou mode décision)
- [ ] Portage `Chronicle` (journal de faits) en version temps réel
## Jalon 8 — Tableau de tâches (utility AI)
- [ ] `TaskDef` en `.tres` (type, priorité, localisation, seuil pawns requis, poids d'appétence par trait)
- [ ] UI tableau côté joueur : poster une tâche, ajuster priorités
- [ ] Boucle d'évaluation pawn au point de décision : `score = priorité × appétence(trait) × compétence × (1 - fatigue_cat) × modif_partenaire`
- [ ] États `EVALUATING`/`INTERRUPTED` dans l'`ActionStateMachine` (préparés au Jalon 5)
- [ ] **Opportunisme en chemin** : détection de proximité (`Area3D`) → réévaluation ponctuelle, switch si l'opportunité domine largement et que rien ne verrouille la tâche
- [ ] Signalement : à défaut de s'arrêter, un pawn ajoute une tâche au tableau ou révèle un point d'intérêt
## Jalon 9 — Interactions pawn ↔ pawn & pawn ↔ robot
> Toute la couche sociale du robot atterrit ici, une fois pawns (J5) et relations (J7) disponibles.
 
- [ ] Bulles thématiques (icône) au croisement pawn/pawn et pawn/robot, générées selon l'état des deux au moment du croisement
- [ ] Effets légers (micro moral, micro relation) une fois le socle validé
- [ ] Bulles "question" côté pawn répondables via la roue robot (Jalon 6)
- [ ] Sauvetage dégressif : pawn secourt le robot à court hors périmètre, chances décroissantes avec la distance et la récidive
- [ ] Atelier "robotique low-tech" : réparation/upgrades du robot par les pawns, **qualité modulée par la relation** avec le pawn qui répare
## Jalon 10 — Progression tech par tags (analyse + axes)
- [ ] `TechDef` en `.tres` (`required_tags: Array[String]`, `unlocked_recipes`, `axis`) — même famille que `BuildingDefs`/`ToolDef`
- [ ] Station d'analyse au bunker : échantillon récolté → **tags de propriété** persistants (`hyperaccumulateur-métal`, `fibre-longue`, `fongique-structurel`, `réfractaire`, `conducteur`)
- [ ] Base de connaissance persistante (tags découverts + sources) — s'ancre sur le `Chronicle` du Jalon 7
- [ ] Sélection d'un axe de recherche par le joueur (Énergie / Construction / Agriculture-Bio / Matériaux / Gouvernance-Social) : tags suffisants → recette débloquée ; manquants → **indice de propriété**, pas d'item exact
- [ ] Archive du bunker comme ressource limitée : dégrade avant l'extinction complète → force le pivot vers la découverte empirique
## Jalon 11 — Ressources & recettes solarpunk (T2 → T3)
- [ ] Menu de sélection de bâtiment en mode construction (dette Jalon 3) — indispensable dès le deuxième `BuildingDef`
- [ ] **Phytominière** (T2) : plantes hyperaccumulatrices → cultivées, récoltées, brûlées, cendre raffinée
- [ ] **Mycoculture** dans la grotte (T2) : bassins + chambres de fermentation, mycélium comme matériau structurel, substrat = bois mort (boucle bois)
- [ ] Construction **terre crue** (pisé/torchis) + **hempcrete** (T2) — pierre en ramassage de surface uniquement
- [ ] **Biogaz/méthanisation** (T2) : digesteur communal à partir des déchets organiques
- [ ] **Four solaire concentré** (T3) : miroirs/lentilles, métallurgie douce sans électronique
- [ ] **Bioleaching** (T3) : bactéries dissolvant le métal d'une roche pauvre, bioréacteur
## Jalon 12 — Bascule écologique & démocratique
- [ ] Métrique de dégradation d'écosystème liée à l'exploitation T1
- [ ] Effets visibles progressifs : faune dangereuse, maladies, autres (à définir)
- [ ] Event de gouvernance déclenché par seuil de dégradation (via `EventManager` porté au Jalon 7)
- [ ] Réunion des pawns + **système de vote** pondéré par convictions/vécu de chaque pawn — détail à travailler en session dédiée
- [ ] "Lois" votées qui modifient des paramètres colonie (priorités par défaut, tâches interdites/encouragées)
- [ ] Déblocage effectif du palier solarpunk après le vote (bouclage avec Jalon 11)
- [ ] Passage progressif du tableau piloté-joueur → réajustement colonie (seuil pawns × relation moyenne) — écho au twist narratif
## Jalon 13 — Expéditions & fins
- [ ] Système d'expédition hors rayon robot : contrôle totalement délégué au groupe parti
- [ ] Objectifs typiques : souche/population absente localement, autre communauté de survivants, zone écologique différente pour tags inaccessibles
- [ ] Résolution en tâche longue avec risque réel (pas de secours possible)
- [ ] Trois branches de fin :
  - **Fin standard** — shutdown du bunker atteint, bilan des pawns sauvés
  - **Game over anticipé** — robot perdu hors périmètre, non secouru
  - **Bonne fin — robot éternel** — tous les dormants sauvés, choix : couper le bunker et rediriger l'énergie restante vers le robot (variantes lié-mortel / isolé-éternel à travailler, pas un binaire bien/mal)
## Features non planifiées
- Cycle jour/nuit
- Deuxième bunker / expansion de zone
- Sous-sol du bunker (complexe cryo à grande échelle) via téléportation
  vers une scène séparée depuis le bas de l'escalier — c'est aussi là que
  les dormants du Jalon 5 sont susceptibles d'être réveillés
- Chemins qui se tracent au passage du joueur et des pawns : carte de piétinement
  (un float par cellule, décroissance lente) modulant la couleur du sol et
  supprimant l'herbe au-dessus d'un seuil. Prévue comme couche du terrain dès
  le Jalon 4 — le découpage en chunks est ce qui la rendra possible sans
  régénérer toute la carte.
- Pistes solarpunk T3+ à préciser (bio-photovoltaïque, apiculture, culture d'algues, rouissage des fibres en rivière)
- Langues supplémentaires (au-delà de EN/FR) — l'infrastructure J3.5 est prête pour n'importe quelle colonne CSV en plus
## Décisions à trancher (avec jalon cible)
 
- **Avant Jalon 6** — Définition concrète de l'"intégrité système" du robot (équivalent moral)
- **Avant Jalon 8** — Traits d'origine des pawns (CEO, gourou tech...) : reconversion progressive vs compétences ancien-monde définitivement inutiles — impact direct sur le ton
- **Avant Jalon 9** — Règles précises du sauvetage dégressif (distances, probabilités, cooldown de récidive)
- **Avant Jalon 12** — Modalités exactes de la transition d'autonomie politique (seuils, déclencheurs, réversibilité)
- **Avant Jalon 12** — Système de vote / gouvernance : détail à travailler en session dédiée