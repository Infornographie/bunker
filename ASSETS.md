# ASSETS — inventaire du pack nature

Carte de référence des modèles du **Stylized Nature MegaKit** (Quaternius, CC0),
tels qu'ils sont rangés dans `assets/nature/meshes/`.

À quoi ça sert : décider quoi semer où sans rouvrir Blender ni relire le pack.
Trois erreurs de composition ont été commises faute de ce document — des
champignons d'arbre semés au sol, la plante réservée à la phytominière dispersée
partout, des taches de fleurs polychromes. La couleur et le port ne se devinent
pas d'un nom de fichier.

**Colonnes.** *Couleur* est la teinte dominante telle qu'elle rend en jeu, pas
celle de la texture. *Port* dit comment l'objet occupe l'espace, donc à quelle
strate il peut appartenir. *Emploi* dit où il est effectivement semé
aujourd'hui — `libre` signifie disponible et non employé, `réservé` signifie
délibérément gardé pour un usage à venir.

Les variantes `_Desert` du pack ne sont pas listées : elles ne servent pas.

## Arbres — canopée et sous-étage

| Famille | Couleur | Port | Emploi |
|---|---|---|---|
| `TallThick_1-5` | feuillage vert clair, tronc sombre | grand arbre, houppier large | **canopy** — sauf `TallThick_2`, écarté (trou noir dans le tronc, défaut de la scène du pack) |
| `CommonTree_1-5` | vert clair classique | arbre moyen, nettement plus petit | **understory** |
| `Birch_1-5` | feuillage **orange**, bois blanc reconnaissable | arbre élancé | libre — un accent d'automne fort, à réserver à un biome |
| `Pine_1-5` | vert classique, rend plus foncé | conifère | libre — forêt sombre |
| `GiantPine_1-5` | **vert foncé** | grand conifère | libre — forêt sombre, altitude |
| `CherryBlossom_1-5` | feuillage **rose** | arbre moyen | libre — patch « bosquet rose » |
| `TwistedTree_1-5` | feuillage **rouge pâle**, tronc penché | arbre penché | libre — berge |
| `DeadTree_1-5` | pas de feuillage, aspect tronc brûlé | tronc nu | libre — tache de troncs brûlés (raconte un événement passé), et candidat aux troncs couchés |

## Buissons et plantes hautes

| Famille | Couleur | Port | Emploi |
|---|---|---|---|
| `Bush_Common` | vert clair classique | buisson rond | **shrub** |
| `Bush_Common_Dry` | **jaune/orange pâle**, automne | buisson rond | libre — réservé à un biome d'automne, hors de la forêt claire |
| `Bush_Common_Flowers` | vert bleuté, fleurs roses/violettes | buisson rond fleuri | libre — patch fleuri |
| `Bush_Large` | vert clair classique | gros buisson | **shrub** |
| `Bush_Large_Flowers` | vert bleuté, fleurs roses/violettes | gros buisson fleuri | libre — patch fleuri |
| `Bush_Long_1-2` | vert clair classique | buisson étalé | **shrub** |
| `Fern_1` | vert un peu plus foncé | fougère | **shrub** |
| `Fern_2` | vert clair classique | fougère | **shrub** |
| `Plant_1` / `Plant_1_Big` | vert classique, bout rougeâtre | feuilles larges | `Plant_1` → **ground**, `Plant_1_Big` → **shrub** |
| `Plant_2` / `Plant_2_Big` | **bleu franc** | touffe dressée | **réservé** — hyperaccumulatrice de la phytominière (GDD, Jalon 11). En semer banalise un signal de jeu |
| `Plant_3` | **orange**, longues feuilles | touffe dressée | libre |
| `Plant_4` | **rose foncé**, fines feuilles | touffe fine | libre |
| `Plant_5` | vert, larges feuilles en cœur | feuilles larges | **ground** |
| `Plant_6` | **rouge orangé**, longues feuilles vers le haut | touffe dressée | libre |
| `Plant_7` / `Plant_7_Big` | amas de fleurs **violettes**, sans tige | tapis bas | `Plant_7` → patch **flower_violet** |

## Herbes et couvre-sol

| Famille | Couleur | Port | Emploi |
|---|---|---|---|
| `Grass_Common_Short` / `_Tall` | vert clair classique | touffe | **ground** ; la haute aussi en patch **grass_bed** |
| `Grass_Wide_Short` / `_Tall` | vert plus foncé | touffe large | **ground** ; la haute aussi en **grass_bed** |
| `Grass_Wispy_Short` / `_Tall` | vert jaunâtre | touffe fine | **ground** ; la haute aussi en **grass_bed** ; la courte sert d'herbe d'éboulis dans **scree** |
| `Grass_Wheat` | **jaune rougeâtre** | épis hauts | libre — prairie sèche, berge |
| `Clover_1-2` | vert clair classique | tapis bas | **ground**, `Clover_1` aussi en **grass_bed** |

## Fleurs

Les `Flower_*_Group` sont des bouquets, les `_Single` des pieds isolés, les
`Petal_*` la fleur seule sans tige. Chaque `Petal` correspond à une `Flower` :
elles vont ensemble dans la même tache, le tapis sous le bouquet.

| Famille | Couleur | Petal correspondant | Emploi |
|---|---|---|---|
| `Flower_1_Group` / `_Single` | **blanc orangé** | `Petal_2` | patch **flower_white** |
| `Flower_2_Group` / `_Single` | **violet** | `Petal_1` | patch **flower_violet** |
| `Flower_3_Group` / `_Single` | **rosé** | `Petal_5` | patch **flower_pink** |
| `Flower_4_Group` / `_Single` | **jaune** | `Petal_4` (jaune foncé) | patch **flower_yellow** |
| `Flower_6` / `Flower_6_2` | feuillage vert, fleurs **rouges**, façon trèfle flottant | `Petal_3` (rouge) | libre |
| `Flower_7_Group` / `_Single` | **jaune à long pistil rouge** | `Petal_6` | patch **flower_yellow** |

## Champignons

Le port est ici décisif : deux de ces quatre poussent **sur les troncs et les
rochers**, pas au sol.

| Famille | Couleur | Port | Emploi |
|---|---|---|---|
| `Mushroom_Common` | blanc cassé | champignon de sol | patch **mushroom_spot** |
| `Mushroom_RedCap` | tige blanche, chapeau orangé | petit champignon de sol | patch **mushroom_spot** |
| `Mushroom_Oyster` | blanc violacé, tige et chapeau | **champignon d'arbre** | réservé à la strate épiphyte (Jalon 4, passe B2) |
| `Mushroom_Laetiporus` | jaune/marron, plats | **champignon d'arbre** | réservé à la strate épiphyte |

## Minéral

| Famille | Couleur | Port | Emploi |
|---|---|---|---|
| `Pebble_Round_1-5` | gris caillou | galet | **ground** (à partir de 6° de pente) |
| `Pebble_Square_1-6` | gris caillou | caillou anguleux | patch **scree** |
| `Rock_Medium_1-4` | gris, avec mousse | rocher moyen | patch **scree** |
| `Rock_Big_1-2` | gris, avec mousse | gros rocher | libre — habillage de l'escarpement (passe C) |
| `RockPath_*` | gris dalle | **dalle posée par l'homme** | réservé — chemins de piétinement, jamais en semis naturel |

## Autres

| Famille | Emploi |
|---|---|
| `Wood_Log_B` (`assets/nature/props/`) | rondin lâché par `Choppable`, hors pack Quaternius |
