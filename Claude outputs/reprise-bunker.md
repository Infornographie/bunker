# Reprise — Bunker, suite du jalon visuel

Note de passage de relais. **Tout ce qui est durable est déjà dans les docs du projet** (ROADMAP, STATE, ASSETS, ATTRIBUTION, STRUCTURE, mis à jour et commités) — ne pas le recopier ici. Ce document ne contient que ce qui n'y est pas encore : les tâches immédiates, les décisions ouvertes et les points à tester.

## Où on en est

Jalon 4, passe B3 (habillage du sol par textures) close. Le sol est habillé par cinq matériaux freestylized en 2K, mélangés par carte de hauteur. Les rochers ont été corrigés (alignement sur la pente, enfoncement fondé sur le rayon) et les petits cailloux retirés.

Le chantier « donner du relief au sol par décalage d'UV » est **fermé**. Parallaxe et POM ont été écrits, testés, retirés. La raison est dans STATE §Habillage du sol — ne pas le rouvrir sans avoir changé l'albédo ou l'éclairage.

## À faire tout de suite

1. **Force de normale par matériau.** La normal map de `cliff_rocks_02` n'encode que ~3° de pente moyenne, contre ~16° pour `ground_with_roots_01`. Un `normal_strength` global ne peut pas servir les deux : il faut un multiplicateur par couche, la falaise vers 4-5.
2. **Vérifier les valeurs du matériau.** Plusieurs paramètres du `ShaderMaterial` (dans `resources/terrain/default_terrain.tres`) portent encore d'anciennes valeurs qui écrasent les défauts du shader. Au minimum : `detail_normal` doit être à 0, `normal_strength` mérite d'être monté au-dessus de 1.
3. **Ménage.** `ARRAY_TEX_UV` dans `terrain_mesh_builder.gd` et `uv_scale` dans `TerrainGenConfig` ne servent plus (tout est en coordonnées monde). `sand_03` n'est branché nulle part.

## Le gros morceau suivant

**ROADMAP → Jalon 4 → Passe D**, écrite pendant cette session. C'est le catalogue de features et les lieux-dits : la réponse au constat que les cartes manquent de personnalité et se ressemblent d'une graine à l'autre.

Trois décisions à trancher **avant** d'écrire une ligne, elles sont listées en fin de passe D :

- forme de `TerrainFeature` — Resource à script, ou classe plus un `.tres` de réglages ;
- réglages de features dans `TerrainGenConfig` ou dans leurs propres `.tres` ;
- le joueur peut-il renommer un lieu-dit.

Premier pas concret sans risque : extraire `MassifShape` et `heightmap_ops` **sans changer le résultat** — test de non-régression, à graine égale la carte doit être identique. C'est ce qui déverrouille le contrefort, la meilleure feature du catalogue.

Et deux outils à faire **avant** la première feature, pas après la troisième : la planche de graines (douze cartes en heightmap seule, vignettes ombrées) et le vérificateur d'invariants sur N graines.

Le **catalogue préliminaire des spots** — une trentaine, rangés par zone, avec les deux obligatoires et les contraignants signalés — est dans la même passe D de la ROADMAP. C'est une base de discussion, pas un décret.

## Décisions déjà prises dans la discussion, à ne pas rejouer

- Les sites sont des **objets tirés et publiés**, pas des passes de génération — c'est ce qui permet à un pawn d'avoir une destination qui a un sens.
- Un site porte des **qualités, jamais des activités**. Le Jalon 8 déclare ce qu'une activité cherche.
- Le dégagement d'un site est une **direction et un angle**, pas un booléen — c'est ce qui fait exister « aller voir un couchant » sans que le terrain sache qu'il existe des couchants.
- Le lieu préféré vit **sur le pawn**, pas sur le site, et s'accumule.
- Une feature ne nomme **jamais** une autre feature.

## À tester / à décider par l'usage

- Est-ce que les chaînes de rochers rendent mieux depuis le dernier réglage de `scree.tres` (seuil 0.55, densité 0.85) ?
- La brume est un choix assumé, mais elle masque un scintillement du feuillage qui reviendra sur un ciel clair. Dette notée.
- Les galets de plage (`pebble_round`) ont été retirés partout ; les rendre au seul biome qui borde l'eau si le rivage paraît nu.
