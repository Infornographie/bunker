# Bunker — Game Design Document
 
> Nom de travail : **Projet Bunker**. À renommer plus tard.
 
## Pitch
 
Futur lointain, post-apo **solarpunk**, assez loin dans le temps pour qu'il ne reste presque aucune trace visible autour du bunker. Une alerte énergie s'active dans un bunker caché en pleine forêt : le système central n'a plus longtemps à vivre. Il réveille son extension physique — un robot — et lui confie une mission : réveiller le plus de dormants (pawns) possible avant le shutdown, et produire de quoi les faire survivre.
 
**Twist** : impossible de recréer le monde d'avant (plus les ressources, l'énergie ni les compétences). Les dormants sont majoritairement des profils "inutiles" dans ce nouveau contexte (CEO, financiers, gourous tech...). Ils doivent se réinventer et coexister dans un nouveau paradigme pour survivre.
 
Reprise du concept de gestion de colonie de **Degel**, transposée en vue première personne, low poly / cosy. Le joueur incarne le robot, oriente les pawns réveillés via un tableau de tâches, mais ne les contrôle jamais directement.
 
### Protagoniste — le robot
 
Extension physique de l'ordinateur central du bunker, voué à s'éteindre faute d'énergie. Justifie diégétiquement :
- l'impossibilité de tout gérer seul (un seul châssis, pas de bras illimités) ;
- la fin littérale du jeu si l'énergie tombe à zéro ;
- le fait que le protagoniste ne consomme pas les mêmes ressources que les pawns (pas de faim/sommeil, mais énergie/usure).
## Piliers
 
- **Vue incarnée, temps réel** — rupture avec le tour par tour de Degel.
- **Un seul perso jouable** — les pawns réveillés reçoivent des ordres, ne sont jamais contrôlés directement.
- **Le joueur oriente, il n'exécute pas à la place des pawns** — le collectif est indispensable pour survivre, jamais géré solo.
- **Autonomie des pawns** — ils choisissent leurs actions selon leur propre état, pas juste des ordres directs.
- **Ambiance silencieuse mais vivante** — pas de dialogue parlé, interactions par bulles thématiques.
- **Pas de gros inventaire** — le transport de ressources/outils est un enjeu en soi, moteur de coopération.
- **Dépendance réciproque et évolutive** entre le robot et les pawns (le sauveur devient sauvé).
- **Systèmes hérités de Degel** (fatigue, relations, events narratifs) recâblés sur une horloge temps réel plutôt que sur des tours.
- **Colonie nombreuse** — la simulation vise 40 à 50 pawns simultanés. C'est le pilier technique du projet, et il prime sur le décor : tout ce qui coûte de la frame sans faire vivre un pawn est négociable.
- **Monde resserré autour du bunker** — une forêt générée, mais petite et sobre. La contrainte d'espace ne vient pas des mètres, elle vient de la liaison au bunker.
- **Low poly / cosy** — lisibilité avant tout, cohérence visuelle assurée par un unique écosystème d'assets (Quaternius).
## Boucle de gameplay (MVP)
 
1. Explorer/récolter dans la forêt générée avec le robot.
2. Construire/améliorer le bunker.
3. Trouver et réveiller un pawn en dormance.
4. Poster des tâches au tableau ; les pawns s'auto-assignent selon leur état.
5. Fatigue s'accumule avec l'activité → repos nécessaire.
6. Relations émergent entre pawns qui travaillent ensemble.
7. Petits events déclenchés par le contexte de jeu (façon Chronicle de Degel).
## Systèmes
 
### Tableau des tâches (utility AI)
 
Le joueur poste des tâches sur un tableau (type, priorité, localisation, éventuel seuil de pawns requis). Chaque pawn, à un point de décision (fin de tâche, réveil, passage au tableau), évalue un score par tâche disponible :
 
```
score = priorité_tableau × poids_appétence(trait) × poids_compétence × (1 - fatigue_catégorie) × modificateur_partenaire
```
 
Cohérent avec le pattern data-driven existant : un `TaskDef` (.tres) par type de tâche, poids inclus.
 
#### Opportunisme en chemin
 
Un pawn en route vers sa tâche assignée peut croiser une opportunité (filon, ressource rare) :
- **Interruption douce** : détection de proximité (`Area3D`) → réévaluation ponctuelle du score ; switch si l'opportunité domine largement et que rien ne verrouille la tâche en cours (ex. transport en binôme).
- **Signalement** : à défaut de s'arrêter, le pawn peut ajouter une tâche au tableau ou révéler un point d'intérêt sur la carte.
#### Autonomie politique croissante
 
Les pawns gagnent en poids décisionnel collectif à mesure que la colonie mûrit (écho à la bascule démocratique du Jalon 11 — modalités précises dans ROADMAP §Décisions à trancher).
 
### Fatigue
 
Fatigue **par catégorie d'action** (pas un seul chiffre global) : chaque pawn accumule de la fatigue séparément par catégorie de tâche, avec decay au repos ou au switch. Nourrit directement le score de tableau (`1 - fatigue_catégorie`).
 
### Bulles d'interaction
 
Pas de dialogue direct. Au croisement de deux pawns en mouvement (ou pawn + robot), déclenchement d'une bulle thématique (icône) selon l'état des deux au moment du croisement (fatigue partagée, satisfaction, tension...). Affichage émergent de l'état interne plutôt que déco pure. Possibilité d'effets légers (micro moral) une fois le socle en place.
 
Le robot ne génère probablement pas de bulles émotionnelles — soit rien, soit un jeu de bulles techniques (diagnostics, alertes), pour marquer son altérité.
 
### Roue de réaction du robot
 
Le robot ne parle pas, mais dispose d'une **roue de réponses rapides** (radial menu, déclenché sur une touche type A/Q) pour interagir avec les pawns : oui / non / suis-moi / reste / reprends ton activité, etc.
 
Intérêt : même un set minimal (oui/non) suffit à ouvrir un vrai espace de "discussion" silencieuse avec les pawns — un pawn pose une question via bulle, le joueur répond via la roue. Ça enrichit mécaniquement le système de bulles sans jamais passer par du dialogue écrit/parlé : les bulles peuvent alors se diversifier et se complexifier (questions, propositions, demandes) puisqu'elles ont désormais une réponse possible.
 
Piste d'extension naturelle : les options de la roue pourraient s'enrichir avec la progression (plus de nuances de réponse) en écho avec l'autonomie politique croissante de la colonie.
 
### Portage & inventaire du protagoniste
 
Pas de gros inventaire (pilier) — le portage est fragmenté en contenants avec des frictions d'accès différentes, jamais un sac fourre-tout instantané.
 
| Contenant | Slots | Accès | Contenu |
|---|---|---|---|
| Ceinture | 2 (hanche G/D) | Direct, barre 1-2 | Outils équipés |
| Poches | 3 (G/D/avant) | Direct, barre 3-5 | Petits objets actifs |
| Sac à dos | 10 | Doit être posé au sol pour être ouvert | Stockage petits objets |
 
Ramassage d'un petit objet : va automatiquement dans le sac à dos, jamais dans les poches — les poches sont réservées à ce qu'on veut utiliser tout de suite. Pour rendre un objet utilisable (barre 3-5) ou le livrer à un site, il faut le faire remonter en poche via l'interface du sac posé au sol (façon Peak) — c'est la friction voulue.
 
**La main comme mécanisme transversal** : le portage à la main (`CarryController`) n'est pas un 4e contenant séparé, c'est le même mécanisme réutilisé dans 3 contextes :
- Portage d'un objet lourd (bois) — bloque la ceinture, comme aujourd'hui.
- Outil de transfert dans l'interface du sac posé au sol (faire passer un objet vers une poche, ou direct en main pour livraison).
- Débordement : ceinture + poches + sac pleins → un nouveau ramassage va en main plutôt que d'être perdu, au prix de perdre l'accès à la ceinture le temps de s'en délester.
### Survie du robot (miroir de la survie pawn)
 
| Pawns | Robot |
|---|---|
| Faim | Énergie (charge) |
| Fatigue | Usure/dégradation des composants |
| Maladie/blessure | Panne/dysfonction d'un module |
| Sommeil | Recharge (immobile, vulnérable ?) |
| Moral | Intégrité système (à définir) |
 
#### Deux pools distincts
 
- **Pool robot local** : énergie embarquée, rechargeable au bunker central, gère l'autonomie court-terme (déplacements/actions).
- **Pool bunker global** : la vraie fatalité — descend en continu, non rechargeable (ou très difficilement), horloge de fin de partie.
#### Liaison au bunker

Le robot est l'extension physique de l'ordinateur central : il n'agit qu'en restant **connecté** à lui. Le périmètre n'est donc ni une limite spatiale fixe ni une conséquence de l'énergie embarquée (celle-ci n'a aucun rapport avec la distance) — c'est une **portée de signal**, que le relief module. La plaine porte loin, une crête coupe derrière elle.

Ce qui se passe quand on s'éloigne, dans l'ordre :

1. L'écran commence à glitcher.
2. Le glitch s'intensifie avec la distance, un avertissement s'affiche.
3. Au-delà de la limite, le robot **tombe**.
4. S'il n'y a aucun pawn éveillé, c'est un game over.
5. Sinon, un pawn vient le ramener au bunker — conséquences supplémentaires à définir.

Trois ressources coexistent et **aucune ne se déduit d'une autre** : l'énergie du bunker (horloge de fin de partie, et raison du réveil), l'énergie du robot (autonomie d'action, à recharger), la liaison (géographie). Le mur invisible est remplacé par une dégradation qu'on ressent avant de la heurter.
 
#### Sauvetage dégressif
 
Le sauvetage n'est pas un système à part : c'est une tâche postée au tableau, prioritaire et non refusable, dont la cible est la position du robot tombé. Les chances s'amenuisent avec la distance et la récidive. Peut mener à un **game over anticipé** (perdu, non retrouvé) — indépendant du shutdown global. Règles précises à caler par expérimentation.
 
#### Expéditions hors périmètre
 
Les pawns peuvent partir en expédition au-delà de la portée de liaison du robot (celui-ci ne peut pas les rejoindre). Bon test de l'autonomie de la colonie : pendant l'expédition, le contrôle est totalement délégué. Risque (pas de secours possible) contre bénéfice (ressources hors zone habituelle).
 
#### Atelier robotique — dépendance inversée
 
Un atelier "robotique low-tech" permet aux pawns de réparer/améliorer le robot (prothèses, upgrades). Point clé : l'efficacité/qualité de la réparation dépend de la **relation** avec les pawns concernés — le système social a une conséquence mécanique directe et pas seulement narrative.
 
## Progression technologique & narration écologique
 
Contexte narratif verrouillé : post-apo **très lointain temporellement**, **solarpunk**. Pas de ruines ni de traces de l'ancien monde à part le bunker lui-même, qui est sur le point de rendre l'âme. Les pawns ont accès aux **connaissances modernes** (archive du bunker) mais pas aux moyens matériels/humains du monde d'avant — la contrainte n'est pas le savoir, c'est l'échelle et le temps disponible.
 
### Arc narratif en 3 temps
 
1. **Survie de base** — bois, pierre ramassée en surface, argile, fibre, agriculture simple. Aucune recherche nécessaire, craft direct.
2. **Tentative de retour à l'avant** — l'archive du bunker donne accès dès le début à la voie "classique" (extraction/métallurgie façon monde d'avant). Cette voie est volontairement **non bloquée mais économiquement intenable** : le coût en temps/énergie de la colonie (fatigue, effectifs) rapporté à la production réelle rend le ratio visiblement mauvais à l'échelle d'une petite population. Le joueur le découvre par ses propres chiffres, pas par un mur artificiel.
3. **Bascule écologique et démocratique** — l'exploitation façon palier 1/2 dégrade l'écosystème local (faune dangereuse, maladies, autres conséquences à définir). Cette dégradation déclenche le premier événement de gouvernance collective : les pawns se réunissent et votent des "lois" pour la nouvelle société, influencées par les convictions/vécu de chaque pawn en jeu (système de vote à détailler dans une session dédiée). Cet événement ouvre la voie vers les alternatives solarpunk (bio/construction douce/énergie).
Le bunker comme ressource narrative limitée : l'accès à l'archive peut se dégrader avant l'extinction complète du bunker (nombre de requêtes ou temps d'accès fini), ce qui pousse mécaniquement le joueur à basculer vers la découverte empirique une fois l'archive épuisée — renforcement du pivot narratif à un second niveau (accès à l'information, pas seulement viabilité économique).
 
### Logique ressources (rejette le cycle extraction/épuisement classique)
 
Principe directeur : on ne prélève pas un stock fini, on **cultive/gère un système vivant** qui produit tant qu'on en prend soin — généralisation du principe déjà présent sur l'entretien de la forêt à toute l'économie.
 
- **Métaux** : pas de minerai en filon épuisable. Voie retenue : **phytominière** (plantes hyperaccumulatrices cultivées, récoltées, brûlées, cendre riche en métal raffinée — technique réelle) et **biominière/bioleaching** (bactéries dissolvant le métal d'une roche pauvre, palier plus tardif nécessitant un bioréacteur). Remplace intégralement la mine/carrière comme site d'extraction classique.
- **Grotte** : réaffectée en site de **mycoculture** (bassins de culture, chambres de fermentation) plutôt qu'en mine. Le mycélium sert de matériau structurel réel (isolant, composite léger, biodégradable), avec le bois mort comme substrat — boucle avec la ressource bois.
- **Construction** : terre crue (pisé/torchis) et hempcrete (chanvre + chaux) comme matériaux principaux plutôt que la pierre taillée en masse. La pierre reste utilisable mais en ramassage de surface (blocs déjà détachés par l'érosion), pas en carrière lourde.
- **Énergie** : four solaire concentré (miroirs/lentilles, sans composant électronique) pour la métallurgie douce ; piste bio-photovoltaïque (cellules solaires biologiques, domaine de recherche réel) comme palier avancé ; énergie hydraulique et éolienne en complément selon le site.
- **Autres briques solarpunk concrètes** : biogaz/méthanisation (digesteur communal à partir des déchets organiques), apiculture, culture d'algues (biomasse/engrais/bioplastique), rouissage des fibres en rivière.
### Arbre technologique — axes + tags plutôt qu'une ligne fixe
 
Inspiration : boucle d'analyse façon *Raft* (un échantillon récolté révèle des propriétés) combinée à une recherche dirigée façon *Alpha Centauri* (le joueur choisit un axe, pas un item précis).
 
- Chaque échantillon récolté (plante, roche, champignon, fibre) passe par une **analyse** au bunker → produit des **tags de propriété** dans une base de connaissance persistante (ex : `hyperaccumulateur-métal`, `fibre-longue`, `fongique-structurel`, `réfractaire`, `conducteur`). Plusieurs sources différentes peuvent révéler le même tag.
- Le joueur choisit une **direction de recherche** (Énergie, Construction, Agriculture/Bio, Matériaux, Gouvernance/Social). Le système compare les tags déjà connus aux tags requis par les technologies de cet axe :
  - tags suffisants → déblocage d'une recette/bâtiment.
  - tags manquants → indice sur la **propriété** à chercher (pas l'item exact), pousse à l'exploration plutôt qu'au suivi de wiki.
- Architecture prévue : `TechDef` en `.tres` (même famille que `BuildingDefs`/`ToolDef`) avec `required_tags: Array[String]`, `unlocked_recipes`, `axis`.
Paliers indicatifs (à affiner) :
- **T0 — Fondations** : bois, pierre ramassée, argile, fibre, culture de base. Pas de recherche requise.
- **T1 — Tentation** : voie classique métallurgie/extraction débloquée d'entrée via l'archive, mais économiquement intenable à l'échelle de la colonie (cf. arc narratif).
- **T2 — Pivot** : phytominière, mycoculture, hempcrete, biogaz — débloqués par tags trouvés en explorant les biomes locaux, déclenché par la bascule écologique/démocratique.
- **T3 — Solarpunk avancé** : four solaire concentré, bioleaching, pistes bio-photovoltaïques — tags plus rares, motive les expéditions.
- **T4 — Social/gouvernance** (si activé) : technologies débloquant des mécaniques de décision collective plutôt que des objets.
### Expéditions — moteur biologique/social, pas géologique
 
Puisqu'il n'y a ni minerai rare à chercher au loin ni ruines à piller, la raison d'une expédition hors zone de jeu devient :
- Chercher des **souches/populations absentes localement** (variété de plante hyperaccumulatrice plus efficace, souche fongique particulière, lignée animale).
- Chercher **d'autres communautés de survivants** — diplomatie, échange de savoir/graines, cohérent avec le pilier démocratique (réseau de colonies autonomes plutôt qu'empire minier).
- Atteindre une **zone écologiquement différente** dont le sol/climat rend accessibles des tags absents localement.
## Fins possibles (pistes)
 
- **Fin standard** : shutdown atteint, bilan des pawns sauvés.
- **Game over anticipé** : robot perdu hors périmètre, non secouru.
- **Bonne fin — robot éternel** : tous les dormants sauvés, possibilité de couper le bunker et de réserver l'énergie restante uniquement au robot, qui devient alors "éternel" — mais possiblement séparé de la colonie qu'il a sauvée. Piste pour plusieurs variantes de fin autour de ce choix (rester lié mais mortel / éternel mais isolé) plutôt qu'un simple bon/mauvais binaire.
## Stack / outils
 
- **Moteur** : Godot 4.6+, GDScript (cohérence avec Degel et Knighthood Survivor)
- **Assets** (voir ATTRIBUTION.md pour les licences exactes) :
  - Stylized Nature MegaKit — Quaternius (forêt)
  - Modular Sci-Fi MegaKit — Quaternius (intérieur/extérieur bunker)
  - Medieval Village MegaKit — Quaternius (constructions joueur, import différé)
  - Universal Animation Library 1 & 2 — Quaternius (locomotion, combat, farming)
  - Personnages Ultimate Modular — Quaternius (Patreon)
  - Resource Bits — Kay Lousberg (feu de camp, complément ponctuel)
## Hors scope MVP
 
- Plusieurs bunkers / expansion de zone.
- Combat.
- Cycle jour/nuit avancé.
- Multijoueur.
## Notes d'architecture (héritées des autres projets)
 
- Approche data-driven pour les définitions (bâtiments, ressources) via des `Resource` (.tres), comme `BuildingDefs`/`ResourceDefs` dans Projet Isekai et `game_registry.tres` dans Degel.
- `Chronicle` (journal de faits structuré) de Degel à réadapter pour fonctionner en continu plutôt que par snapshot de tour.
- `EventConfig`/`EventManager` de Degel probablement réutilisables presque tels quels (déjà déclenchés par condition) — seul le "turn-locking" doit devenir une vraie pause / mode décision en temps réel.
- Singleton `GameState` façon Knighthood Survivor comme source de vérité globale.