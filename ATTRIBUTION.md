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

### Resource Bits — Kay Lousberg — **CC0**
Dossier : `assets/props/`
[kaylousberg.itch.io/resource-bits](https://kaylousberg.itch.io/resource-bits)

Feu de camp. Même famille visuelle low poly stylisée que les packs Quaternius, retenu faute d'équivalent chez Quaternius.

### Outils et personnages
Dossier : `assets/characters/`

Contient notamment `tools/wooden_axe_grip.tscn`, wrapper Godot maison autour du FBX de hache (rattrapage de pivot — protocole dans STATE §Apprentissages). Le wrapper est du projet ; le modèle vient du pack listé ci-dessus dont il est issu.
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
 
### Godot Skies (version complète) — binbun3d — **CC0**
Dossier : `assets/sky/`
[binbun3d.itch.io/godot-skies](https://binbun3d.itch.io/godot-skies)

Shader de ciel (`main.gdshader`) et textures de nuages en bruit (`textures/clouds_0X.tres`). Le shader est **non modifié** à ce jour : le jour où on le patche (lune texturée, direction de lune découplée), la modification se note ici.

Le pack livre aussi 27 presets — des `ShaderMaterial` et des `Sky` tout faits. **Ils ne sont pas dans le projet** : ce sont des jeux de valeurs, pas des assets. Leurs réglages ont été recopiés dans nos `SkyProfile` (`resources/sky/`), qui sont la forme utilisable par le cycle jour/nuit. Un preset décrit une journée entière et ne sait pas s'animer ; un profil, si.

> Le shader du pack livre son propre `triplanar.gdshaderinc`, qui n'est inclus par rien dans `main.gdshader`. Il n'a pas été copié.

### Stylized Water Shader (Cool Water) — EmacEArt — **licence propriétaire**
Dossier : `assets/water/`
[store.godotengine.org/asset/emace-art/stylized-water-shader](https://store.godotengine.org/asset/emace-art/stylized-water-shader/)

Shader d'eau stylisée (`EA_CoolWater.gdshader`), ses deux textures (normale et Voronoï d'écume) et trois matériaux d'exemple. Shader **non modifié** ; le jour où on le patche, la modification se note ici.

> **Licence EmacEArt : usage personnel et commercial libres, redistribution des fichiers en tant que tels interdite.** Concrètement : intégré au jeu, aucun problème ; publier `assets/water/` en fichiers bruts dans un dépôt ouvert s'approche de la redistribution. Même prudence que pour les textures de sol Freestylized si le dépôt devient public. Le texte complet est dans `assets/water/LICENSE.txt`.

Non copiés du pack : la scène de démo, son panneau de sliders, ses scripts de caméra, le mesh et le matériau du terrain de démo. Ce sont des outils de démonstration, pas des assets du jeu — les 27 réglages se lisent dans la documentation PDF restée hors dépôt.

## Audio
 
- **chop2.mp3** — igroglaz — **CC0** (SFX coupe du bois, hook posé, asset non encore branché)
  [freesound.org/s/593857](https://freesound.org/s/593857/)