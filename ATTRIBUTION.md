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
## Shaders
 
### Godot Skies (version complète) — binbun3d — **CC0**
Dossier : `assets/sky/`
[binbun3d.itch.io/godot-skies](https://binbun3d.itch.io/godot-skies)

Shader de ciel (`main.gdshader`) et textures de nuages en bruit (`textures/clouds_0X.tres`). Le shader est **non modifié** à ce jour : le jour où on le patche (lune texturée, direction de lune découplée), la modification se note ici.

Le pack livre aussi 27 presets — des `ShaderMaterial` et des `Sky` tout faits. **Ils ne sont pas dans le projet** : ce sont des jeux de valeurs, pas des assets. Leurs réglages ont été recopiés dans nos `SkyProfile` (`resources/sky/`), qui sont la forme utilisable par le cycle jour/nuit. Un preset décrit une journée entière et ne sait pas s'animer ; un profil, si.

> Le shader du pack livre son propre `triplanar.gdshaderinc`, qui n'est inclus par rien dans `main.gdshader`. Il n'a pas été copié.
## Audio
 
- **chop2.mp3** — igroglaz — **CC0** (SFX coupe du bois, hook posé, asset non encore branché)
  [freesound.org/s/593857](https://freesound.org/s/593857/)