# Attribution
 
Ressources tierces effectivement incluses dans le projet. Une entrée par pack : licence, source, et **dossier du projet** où elle vit.

C'est ici — et nulle part ailleurs — que se lit la provenance d'un asset. Les noms de dossiers disent à quoi une ressource sert *dans le jeu* (`nature/`, `scifi/`, `props/`), pas d'où elle vient : un dossier au nom du pack se périme au premier remaniement et personne ne le corrige. Un dossier de `assets/` = un pack, et cette table fait le lien.

À mettre à jour à chaque ajout ou retrait de pack, et à chaque déplacement de dossier.
 
## Modèles 3D
 
### Stylized Nature MegaKit [Pro+] — Quaternius — **CC0**
Dossier : `assets/nature/`
[quaternius.com/packs/stylizednaturemegakit.html](https://quaternius.com/packs/stylizednaturemegakit.html)

129 modèles : 8 familles d'arbres (`CommonTree`, `TallThick`, `Birch`, `TwistedTree`, `Pine`, `GiantPine`, `CherryBlossom`, `DeadTree`), buissons, fougères, plantes, herbes, fleurs et pétales, champignons de sol et de tronc, cailloux, rochers, dalles de chemin. Les rochers et cailloux ont une variante `_Desert`.

La version Pro+ fournit en plus un projet Godot dont on reprend **les shaders de feuillage et de vent** (`materials/M_BaseFoliage.gdshader`, `M_Leaves*.gdshader`, `M_Grass.gdshader`, `M_Bark.gdshader`) et leurs matériaux `MI_*.tres`. Ils sont couverts par la même licence CC0 que les modèles.

Sous-dossiers : `models/` (glTF + textures), `materials/` (shaders + matériaux), `meshes/` (une scène par modèle).

> Les chemins internes des `.tres` et `.tscn` du pack ont été réécrits à l'import : ils référençaient `res://Materials/` et `res://assets/`, chemins valables à la racine du projet d'exemple du pack. Refaire ce remplacement à toute nouvelle copie depuis le pack d'origine.

### Modular Sci-Fi MegaKit — Quaternius — **CC0**
Dossier : `assets/scifi/`
[quaternius.com](https://quaternius.com/)

Extérieur et intérieur du bunker.

### Fantasy Props MegaKit [Standard] — Quaternius — **CC0**
Dossier : `assets/workshop/`
[quaternius.com](https://quaternius.com/)

**Un modèle sur les 94 du pack** : `Workbench` (2,02 × 0,89 × 1,02 m), l'établi de fabrication d'outils. Les six textures de trim qui l'habillent (`T_Trim_Furniture_*`, `T_Trim_Metal_*`, en BaseColor/Normal/ORM) sont communes à tout le pack et resserviront à ce qu'on en tirera ensuite — le doc ASSETS en liste une longue file d'attente.

Le dossier porte l'usage : `workshop/` = mobilier d'atelier construit par le joueur.

### Ultimate Modular Men — Quaternius — **CC0**
Dossier : `assets/characters/pawns/`
[quaternius.com](https://quaternius.com/)

**Un personnage sur les 21 des deux packs** : `Worker.gltf` (1,86 m), premier pawn. Le glTF est autonome — buffer embarqué, aucune texture, matériaux à plat — donc un seul fichier à verser.

Il embarque ses 24 animations sur son propre squelette (`Idle`, `Walk`, `Run`, `Interact`, `Punch_*`, `Death`…), ce qui couvre tout le vocabulaire du Jalon 5 sans retarget.

### Resource Bits — Kay Lousberg — **CC0**
Dossier : `assets/props/`
[kaylousberg.itch.io/resource-bits](https://kaylousberg.itch.io/resource-bits)

Feu de camp, `Wood_Log_B` (le rondin lâché à l'abattage) et `Pallet_Wood` (support de stockage), plus leur texture d'atlas commune. Même famille visuelle low poly stylisée que les packs Quaternius, retenu faute d'équivalent chez Quaternius.

> Crédit facultatif selon la licence, fait ici quand même. `Wood_Log_B` et sa texture vivaient sous `assets/nature/props/` ; remis au 07/09 dans le dossier que cette table leur donnait déjà.

### Forest Free Pack — Ami Polygon — **licence propre à l'auteur**
Dossier : `assets/deadwood/`
[amipolygon.itch.io/free-stylized-low-poly-forest-nature-pack](https://amipolygon.itch.io/free-stylized-low-poly-forest-nature-pack)

**Onze modèles sur les trente-huit du pack** : `stick_1-3` (branches au sol), `log_1-4` (troncs couchés), `trunk_1-4` (souches). Le reste — arbres, pins, arbres morts, buissons, herbes — n'est **pas** importé : son facettage anguleux jure avec le modelé arrondi de Stylized Nature. Ce qui est pris ici l'est parce que le bois mort posé au sol est mat, brun et petit, donc indifférent à cet écart de style.

Le dossier porte le nom de son usage, pas celui du pack : `deadwood/` = bois mort.

**Licence, telle que publiée par l'auteur :**

> Feel free to use these assets in personal and commercial projects. You can
> modify them to fit your game. Credit to Ami Polygon is appreciated but not
> required. Do not resell or redistribute the original asset files as a
> standalone pack.

> Même limite que les textures de sol et le shader d'eau : usage libre, crédit facultatif (fait ici), redistribution des fichiers bruts interdite.

> Chaque `.glb` embarque sa propre copie de l'atlas (30 Ko). Onze fichiers = onze textures importées et onze matériaux distincts là où un seul suffirait. Sans conséquence au semis (un `MultiMesh` par essence de toute façon), à reprendre si ces essences finissent ailleurs qu'en multimesh.

### Low Poly Primitive Tools — lowpolyassets — **CC0**
Dossier : `assets/characters/tools/`
[lowpolyassets.itch.io/low-poly-primitive-tools](https://lowpolyassets.itch.io/low-poly-primitive-tools)

Onze outils primitifs en bois : hache, pioche, pelle, marteau, couteau, massue, lance, bouclier, arc, flèche, torche. Le pack en compte vingt — **la moitié en pierre n'est pas importée**, elle est la piste retenue pour le tier pierre.

`tools/wooden_axe_grip.tscn` est un wrapper Godot maison autour du FBX de hache (rattrapage de pivot — protocole dans STATE §Apprentissages) : le wrapper est du projet, le modèle vient de ce pack.

> Provenance corrigée le 07/09 : ces outils étaient attribués à KayKit, à tort. Le dossier s'appelle `characters/` pour des raisons historiques et ne contient aujourd'hui que `tools/` — les personnages Quaternius ne sont pas encore importés.
### Textures de sol stylisées — freestylized.com — **CC0 personnalisé**
Dossier : `assets/ground/textures/`
[freestylized.com](https://freestylized.com)

Cinq matériaux, en **2K** (le 1K s'est révélé trop grossier une fois les
tuiles agrandies) :

| Matériau | Page |
|---|---|
| `grass_01` | [freestylized.com/material/grass_01](https://freestylized.com/material/grass_01/) |
| `ground_with_roots_01` | [/material/ground_with_roots_01](https://freestylized.com/material/ground_with_roots_01/) |
| `ground_with_rocks_01` | [/material/ground_with_rocks_01](https://freestylized.com/material/ground_with_rocks_01/) |
| `cliff_rocks_02` | [/material/cliff_rocks_02](https://freestylized.com/material/cliff_rocks_02/) |
| `sand_04` | [/material/sand_04](https://freestylized.com/material/sand_04/) |

Chacun livre couleur, normal (GL et DX), roughness, height, AO et metallic,
produits sous Substance Designer. Le `normal_dx` (convention DirectX) et le
`metallic` (un sol est diélectrique) ne sont pas employés.

Seule la variante 2k de chaque matériau est conservée : les 1k pixellisaient
de près. `sand_01` et `sand_03` ont été supprimés au profit de `sand_04`.

**Licence, telle que publiée par le site :**

> All Content provided on freestylized.com is added with the authors
> consent, allowing everyone to use the provided content FREE for their
> Commercial and Non-Commercial projects without any permission.
> Attribution to freestylized.com with your work (in which you used
> freestylized.com in any capacity) would be much appreciated, but not
> required.
> The Content is distributed under custom CC0 License allowing all CC0
> attributions except the limits stated below.
> This license limits the redistribution of freestylized.com content with
> any individual or any organization's attribution other than
> freestylized.com or the authors of content. The redistribution of content
> on any other platform such as marketplaces and other sites is also
> prohibited, unless there are some key modifications and re-purpose of
> content is done then, they can be redistributed such as a model or a
> texture used as part of a kit or an asset pack.

> **Ce que la limite implique concrètement.** L'usage dans le jeu est libre,
> attribution non requise (elle est faite ici quand même). Ce qui est
> interdit, c'est de **redistribuer les textures en tant que telles** sous
> une autre attribution — donc pas de partage du dossier `assets/ground/`
> hors du projet, et prudence si le dépôt devient public : y publier les
> fichiers bruts s'approche de la redistribution. Intégrées au jeu, elles
> sont « re-purposed » au sens de la licence.

## Shaders
 
### Stylized Water Shader — Maciej « EmacEArt » — **licence propre à l'auteur**
Dossier : `assets/water/`
[emaceart.itch.io](https://emaceart.itch.io)

Shader d'eau toon (`EA_CoolWater.gdshader`), ses deux textures et trois
matériaux prédéfinis. Le projet emploie `EA_Water_Lagoon` sur le plan d'eau du
terrain ; `EA_Water_DeepBlue` et `EA_Water_Tropical` sont conservés comme
variantes de climat, pas encore employées.

**Licence, telle que livrée avec le pack :**

> Free for personal and commercial use, but resale or redistribution of the
> assets as standalone files or asset packs is prohibited. No credit is
> required, though it is always welcome.

> Même limite que les textures de sol : l'usage dans le jeu est libre, le
> crédit facultatif (fait ici quand même), et c'est la **redistribution des
> fichiers bruts** qui est interdite — prudence si le dépôt devient public.

### Godot Skies (version complète) — binbun3d — **CC0**
Dossier : `assets/sky/`
[binbun3d.itch.io/godot-skies](https://binbun3d.itch.io/godot-skies)

Shader de ciel (`main.gdshader`) et textures de nuages en bruit (`textures/clouds_0X.tres`). Le shader est **non modifié** à ce jour : le jour où on le patche (lune texturée, direction de lune découplée), la modification se note ici.

Le pack livre aussi 27 presets — des `ShaderMaterial` et des `Sky` tout faits. **Ils ne sont pas dans le projet** : ce sont des jeux de valeurs, pas des assets. Leurs réglages ont été recopiés dans nos `SkyProfile` (`resources/sky/`), qui sont la forme utilisable par le cycle jour/nuit. Un preset décrit une journée entière et ne sait pas s'animer ; un profil, si.

> Le shader du pack livre son propre `triplanar.gdshaderinc`, qui n'est inclus par rien dans `main.gdshader`. Il n'a pas été copié.
## Audio
 
- **chop2.mp3** — igroglaz — **CC0** (SFX coupe du bois, branché sur les essences d'arbres et sur `oak_tree.tscn`)
  [freesound.org/s/593857](https://freesound.org/s/593857/)
- **stone-hit.mp3** — CamoMano — **CC0** (SFX minage — « hitting a rock with a hatchet », branché sur les `rock_medium` et sur `stone_outcrop.tscn`)
  [freesound.org/s/431019](https://freesound.org/s/431019/)