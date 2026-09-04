# ASSETS — inventaire des packs tiers

Carte de référence des modèles tiers utilisés dans le projet, tels qu'ils sont
rangés dans `assets/`, plus un catalogue des packs possédés mais pas encore
importés.

À quoi ça sert : décider quoi utiliser où sans rouvrir Blender ni relire un
pack entier. Sur la forêt, trois erreurs de composition ont été commises
faute de ce document — des champignons d'arbre semés au sol, la plante
réservée à la phytominière dispersée partout, des taches de fleurs
polychromes. La couleur et le port ne se devinent pas d'un nom de fichier.

**Colonnes.** *Couleur* est la teinte dominante telle qu'elle rend en jeu, pas
celle de la texture. *Port* dit comment l'objet occupe l'espace, donc à quelle
strate il peut appartenir. *Emploi* dit où il est effectivement utilisé
aujourd'hui — `libre` signifie disponible et non employé, `réservé` signifie
délibérément gardé pour un usage à venir, `à trouver` signifie un besoin
nommé sans candidat dans les packs déjà importés.

**Rappel de cadrage (packs non importés).** Bunker n'est pas un post-apo
classique : c'est loin dans l'avenir, il ne reste aucune trace du monde
d'avant hormis le bunker lui-même. Tout ce qui se construit ou se produit
dans le monde vient des ressources trouvables aux alentours, en low-tech.
Pas de scavenging pré-effondrement dispersé dans la nature, pas de combat —
ton solarpunk cosy, volontiers un peu silly.

**Note Deluxe/Pro.** Certains packs Standard/gratuits ont une version payante
avec du contenu en plus. Pas de listing de fichiers pour ces versions, juste
des images de comparaison fournies par l'utilisateur — les notes "Deluxe/Pro"
ci-dessous sont donc de la lecture visuelle basse résolution, pas un
inventaire vérifié. À confirmer si achat.

## Nature — Stylized Nature MegaKit (Quaternius, CC0)

Rangé dans `assets/nature/meshes/`. Les variantes `_Desert` du pack ne sont
pas listées : elles ne servent pas.

### Arbres — canopée et sous-étage

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

### Buissons et plantes hautes

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

### Herbes et couvre-sol

| Famille | Couleur | Port | Emploi |
|---|---|---|---|
| `Grass_Common_Short` / `_Tall` | vert clair classique | touffe | **ground** ; la haute aussi en patch **grass_bed** |
| `Grass_Wide_Short` / `_Tall` | vert plus foncé | touffe large | **ground** ; la haute aussi en **grass_bed** |
| `Grass_Wispy_Short` / `_Tall` | vert jaunâtre | touffe fine | **ground** ; la haute aussi en **grass_bed** ; la courte sert d'herbe d'éboulis dans **scree** |
| `Grass_Wheat` | **jaune rougeâtre** | épis hauts | libre — prairie sèche, berge |
| `Clover_1-2` | vert clair classique | tapis bas | **ground**, `Clover_1` aussi en **grass_bed** |

### Fleurs

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

### Champignons

Le port est ici décisif : deux de ces quatre poussent **sur les troncs et les
rochers**, pas au sol.

| Famille | Couleur | Port | Emploi |
|---|---|---|---|
| `Mushroom_Common` | blanc cassé | champignon de sol | patch **mushroom_spot** |
| `Mushroom_RedCap` | tige blanche, chapeau orangé | petit champignon de sol | patch **mushroom_spot** |
| `Mushroom_Oyster` | blanc violacé, tige et chapeau | **champignon d'arbre** | réservé à la strate épiphyte (Jalon 4, passe B2) |
| `Mushroom_Laetiporus` | jaune/marron, plats | **champignon d'arbre** | réservé à la strate épiphyte |

### Minéral

| Famille | Couleur | Port | Emploi |
|---|---|---|---|
| `Pebble_Round_1-5` | gris caillou | galet | **ground** (à partir de 6° de pente) |
| `Pebble_Square_1-6` | gris caillou | caillou anguleux | patch **scree** |
| `Rock_Medium_1-4` | gris, avec mousse | rocher moyen | patch **scree** |
| `Rock_Big_1-2` | gris, avec mousse | gros rocher | libre — habillage de l'escarpement (passe C) |
| `RockPath_*` | gris dalle | **dalle posée par l'homme** | réservé — chemins de piétinement, jamais en semis naturel |

## Textures de sol (assets/ground/textures/)

Cinq matériaux stylisés de **freestylized.com** (licence en CC0 personnalisé, voir ATTRIBUTION), un dossier chacun, employés par `terrain.gdshader`. Tous en **2K** : en 1K, une fois les tuiles agrandies, le grain devenait trop grossier.
Chaque dossier livre couleur, `normal_gl`, roughness, height et AO ; le
`normal_dx` et le `metallic` sont présents mais **inutilisés** (convention
DirectX, et un sol est diélectrique).

| Dossier | Rôle dans le shader | Se déclenche sur |
|---|---|---|
| `grass_01` | herbe | couvert ouvert, pente faible |
| `ground_with_roots_01` | litière de sous-bois | couvert fermé (carte d'ouverture) |
| `ground_with_rocks_01` | sol caillouteux | altitude, avant la roche nue |
| `cliff_rocks_02` | paroi | au-delà d'une pente — tuile de 50 m, la plus grande du lot |
| `sand_04` | rivage | au ras du niveau de l'eau |

**Mesures faites sur les fichiers, à refaire si une texture est remplacée.**
Quatre des cinq cartes de hauteur n'occupent que ~20 % de leur plage (elles
sont quasi grises) et le shader les renormalise via `*_height_range`. La
normal map de `cliff_rocks_02` n'encode que ~3° de pente moyenne, contre 16°
pour `ground_with_roots_01` : c'est le matériau le plus plat du lot, alors
que c'est celui qu'on regarde de plus près.

**À trouver.** Une **carte de grain neutre** — micro-relief sans formes
reconnaissables — pour la seconde échelle de détail du shader. Faute de
quoi le détail réutilise la texture principale en miniature, ce qui
désaccorde relief et couleur (voir dette Jalon 4).

## Sci-fi — Modular SciFi MegaKit (Quaternius)

Rangé dans `assets/sci_fi/`. Aucun modèle n'est intégré aujourd'hui :
`bunker_exterior_test.tscn` était une scène morte-née (bunker construit à la
main directement dedans, jamais repris ailleurs, jamais la partie
intérieure) — à supprimer, comme `forest_test.tscn`/`forest_scatter.gd` déjà
notés périmés dans STRUCTURE.md. Le bunker est intégralement à refaire.

Usage retenu : **intérieur uniquement**. L'extérieur du kit a des trous de
collision (on traverse par endroits par certains éléments) — l'entrée du
bunker se pose plutôt dans le terrain généré (Passe C, Jalon 4, encore en
réflexion sur l'emplacement exact).

| Dossier | Modèles | Emploi |
|---|---|---|
| `Aliens` | 3 | hors sujet — pas de créature prévue au GDD |
| `Columns` | 8 | libre — déco intérieure |
| `Decals` | ~25 | libre — signalétique et habillage de surface |
| `Platforms` | ~35 | libre — sols modulaires, portes, rampes, escaliers |
| `Props` | ~26 | libre — mobilier/déco (caisses, éclairages, ventilos, rails) |
| `Walls` | ~55 | libre — murs bas/hauts, une dizaine de finitions (Metal2, DarkPlastic, Astra, Cables, WhitePlate2...) |

**À trouver.** Cryo chambers crédibles pour la chambre de congélation —
vue à travers une vitre, depuis une passerelle, ou sous un escalier grillagé,
pas nécessairement praticable. Rien dans `sci_fi`, `survival` ni
`characters` ne convient — pack dédié à chercher, ou habillage détourné à
inventer.

## Survival — KayKit (assets/survival/)

Trois modèles, deux intégrés :

| Modèle | Emploi |
|---|---|
| `Backpack.fbx` | intégré — sac à dos |
| `Bonfire.fbx` | intégré — `campfire.tscn` |
| `Bonfire_Fire.fbx` | **à supprimer** — variante avec un feu en dur, jamais utilisée (le feu vient de `flame_light_flicker.gd`) |

## Characters — outils (KayKit, assets/characters/tools/)

Dix outils, un seul câblé :

| Modèle | Emploi |
|---|---|
| `Wooden Axe.fbx` | intégré — seul outil avec un grip (`wooden_axe_grip.tscn`) |
| `Bow`, `Torch`, `Wooden Arrow`, `Wooden Club`, `Wooden Hammer`, `Wooden Knife`, `Wooden Pickaxe`, `Wooden Shield`, `Wooden Shovel`, `Wooden Spear` | libres — dette Jalon 3 (grips + hand_position manquants), repoussé non bloquant |

## Resource Bits — KayKit (pack source, non importé)

Pack de ressources industrielles/minières, 76 modèles. **Rien n'est encore
importé dans `assets/`, sauf `Wood_Log_B`** — le rondin lâché par
`Choppable` en vient réellement (corrigé ici : il n'est pas de Quaternius,
malgré son emplacement historique dans `assets/nature/props/`).

| Famille | Modèles | Emploi potentiel |
|---|---|---|
| Métaux — `Copper`/`Gold`/`Iron`/`Silver` (barre, barres, piles L/M/S, pépite L/M/S, pépites, ×9 chacun) | 36 | réserve — bioleaching (Jalon 11, T3) et arbre tech par tags (Jalon 10) : minerai brut vs barre raffinée, un métal par palier |
| `Stone_Brick`, `Stone_Bricks_Stack_*`, `Stone_Chunks_*` | 6 | réserve — pierre en ramassage de surface (dette Jalon 11 : terre crue/hempcrete) |
| `Textiles_A/B/C`, `Textiles_Stack_*` | 6 | réserve — fibres (piste non planifiée : rouissage des fibres en rivière) |
| `Wood_Plank_*`, `Wood_Log_Stack` | 6 | réserve — matériaux de construction transformés (bois scié, low-tech) |
| `Parts_Cog`, `Parts_Pile_*` | 4 | à trancher — pièces mécaniques, cohérent seulement si trouvées **dans le bunker** (seule trace du monde d'avant), pas dispersées en scavenging |
| `Fuel_A/B/C` (baril, baril sale, barils, jerrican, ×4 chacun) | 12 | à trancher — même réserve : hors sujet en scavenging extérieur, éventuellement une réserve de carburant dans le bunker lui-même |
| `Pallet_Wood*` | 3 | probablement hors sujet — palette industrielle, signal trop "entrepôt du monde d'avant" |
| `Wood_Log_A` | 1 | libre |
| `Wood_Log_B` | 1 | **intégré** (`Choppable`, rondin) — actuellement mal rangé sous `assets/nature/props/` |

**Deluxe/Pro (lecture d'image, non vérifiée).** Le Standard ci-dessus couvre
les 76 modèles. Le Pro ("Extra Only") ajoute des familles neuves, pas
seulement des variantes : des cristaux/gemmes bleu-violet (brut, en tas, en
sac, en coffre — signal trop fantasy/magique, hors du GDD tel quel, sauf à
les retexturer en minerai spécial) ; de la nourriture et ses contenants
(pommes, myrtilles, oranges, tomate, fromage, sacs et paniers de récolte,
tonneaux) — cohérent avec les `FarmCrate_*` déjà repérés dans Fantasy Props,
utile pour la réserve alimentaire du bunker ou une future ferme ; des
coffres au trésor — même réserve que les `Chest_Wood`/`Cabinet` déjà notés,
rien de neuf ; des cartons/caisses de transport modernes (cartons
d'expédition, caisses militaires vertes, palettes colorées) — hors sujet,
signal trop "logistique du monde d'avant", et redondant avec les `Crate_*`
déjà présents dans Fantasy Props et SciFi Essentials.

L'argent (pièces, billets, liasses), en revanche, **réserve potentielle —
gag silly.** Sans économie au GDD, ça reste un objet inutile en soi — mais
c'est justement le ressort comique : un ou deux pawns d'origine "financier"
(cohérent avec la tenue `Suit` d'Ultimate Modular Men/Women, piste Jalon 8)
trimballant des liasses dont personne ne veut, essayant encore de "vendre"
des trucs aux autres pawns, ou une pile de billets utilisée comme
allume-feu/isolant faute de mieux — de l'ancien monde rendu absurde plutôt
qu'effrayant. Pas un système, juste une touche de worldbuilding silly à
garder sous le coude.

## Packs non importés — catalogue

Packs possédés, pas encore dans `assets/`. Pas de colonne Emploi actuel
puisque rien n'est intégré ; à la place, trois buckets par pack — **usage
prévu**, **réserve potentielle**, **hors sujet**.

### Fantasy Props MegaKit (Quaternius, 94 modèles)

Mobilier/props médiéval-fantasy. Angle retenu : objets utilisables comme
props/outils constructibles en contexte low-tech, pas comme décor "fantasy"
en soi.

- **Usage prévu.** `Workbench`, `Workbench_Drawers`, `Crate_Wooden`,
  `Chest_Wood`, `Barrel`, `Barrel_Apples`, `Barrel_Holder`,
  `Bucket_Wooden_1`, `Bucket_Metal`, `Cauldron`, `Pot_1`/`Pot_1_Lid`,
  `Candle_1`/`Candle_2`, `CandleStick*`, `Rope_1/2/3`, `Chain_Coil`,
  `Whetstone`, `Anvil`/`Anvil_Log` (forge low-tech), `Bench`, `Stool`,
  `Chair_1`, `Table_Large`, `Shelf_Simple`/`Shelf_Arch`, `Peg_Rack`,
  `Vase_2`/`Vase_4`, `Bottle_1`/`SmallBottle*`, `Mug`,
  `Table_Fork`/`Knife`/`Spoon`/`Plate`, `FarmCrate_Apple`/`Carrot`/`Empty`,
  `Carrot` (item agricole), `Bookcase_2`/`Book*`/`Scroll*`/`BookStand`
  (archive du bunker, Jalon 10), `Cage_Small` (élevage ?).
- **Réserve potentielle.** `Banner_1`/`Banner_2` (+ `_Cloth`), `Chandelier`,
  `Chalice`, `Coin`/`Coin_Pile*` (rejoint le gag silly de l'argent noté sous
  Resource Bits — objet inutile devenu marotte d'un pawn origine
  "financier"), `Key_Gold`/`Key_Metal`, `Potion_1/2/4` (trop "fantasy", à
  retexturer ou écarter), `Pouch_Large`, `Bag`, `Nightstand_Shelf`,
  `Bed_Twin1`/`Bed_Twin2`, `Cabinet`, `Stall_Empty`/`Stall_Cart_Empty`
  (marché — pas de commerce prévu), `Vase_Rubble_Medium`.
- **Hors sujet.** `Axe_Bronze`, `Sword_Bronze`, `Pickaxe_Bronze` (bronze +
  armes, hors du système d'outils bois déjà en place), `Dummy`,
  `WeaponStand`, `Shield_Wooden` (mannequin de combat / arme).
- **Deluxe/Pro (lecture d'image, non vérifiée).** Standard = 94 modèles,
  Pro = 200+. Comme pour Medieval Village, l'essentiel de l'écart est de la
  densité de variantes : plus de lits, plus de bannières colorées, des
  étals de marché supplémentaires, un chariot-cage (transport d'animaux ou
  de biens — pas d'usage prévu), une échelle, et surtout des variantes
  d'armes (faux/scythe, plus de haches/épées) — toutes hors sujet, pas de
  combat prévu. Le vrai plus visible est ailleurs : les sets de texture
  Bois/Métal/Props existent en **variante "usée" (worn)** côté Pro/Source —
  potentiellement utile pour vieillir des objets construits en jeu, mais ça
  reste un détail de texturage, pas une raison d'achat en soi. Aucune
  nouvelle catégorie qui changerait les buckets ci-dessus.

### Medieval Village MegaKit (Quaternius)

Pas pour des ruines — pour la **construction** : les bâtiments médiévaux à
pans de bois se rapprochent de ce qu'on pourrait bâtir avec des
connaissances techniques mais du matériel rustique. Kit modulaire complet
(murs, toits, portes, fenêtres, escaliers, balcons, façades) + props
(clôtures, vignes, charrette, cheminée).

- **Réserve potentielle — le kit entier.** Rien d'urgent (pas de menu de
  bâtiments avant Jalon 11 au plus tôt, dette Jalon 3), mais c'est la
  meilleure référence visuelle actuelle pour des constructions en bois/terre
  crue/hempcrete. Tu restes en recherche de mieux — à garder en tête, pas à
  écarter.
- **Point d'attention, pas un défaut de contenu.** L'esthétique "village
  européen médiéval" peut demander un retexturage pour coller au ton
  solarpunk cosy/silly plutôt qu'à un pastiche fantasy.
- **Deluxe/Pro (lecture d'image, non vérifiée).** Le Standard (~176 modèles)
  couvre déjà tout le gros œuvre modulaire (murs, toits, façades, escaliers,
  clôtures). Le Pro (300+ modèles) semble surtout densifier les mêmes
  familles en plus de variantes/finitions plutôt qu'ajouter des catégories
  neuves. Deux éléments à surveiller si achat : une structure qui ressemble
  à un four/kiln extérieur (four solaire du Jalon 11 est un système à part,
  mais la forme pourrait servir de base visuelle à retravailler), et des
  clôtures en fer forgé (mineur, mais plus proche low-tech-avancé que bois
  brut). Rien vu qui change la conclusion "réserve potentielle" — à
  confirmer avec un vrai listing si le pack est acheté.

### SciFi Essentials Kit (Quaternius)

Complément de props déco pour l'intérieur du bunker — comble le trou
mobilier/rangement du SciFi MegaKit.

- **Usage prévu.** `Prop_Locker`, `Prop_Desk_L`/`Medium`/`Small`,
  `Prop_Shelves_ThinShort`/`ThinTall`/`WideShort`/`WideTall`, `Prop_Crate`/
  `Crate_Large`/`Crate_Tarp`/`Crate_Tarp_Large`, `Prop_Chair`, `Prop_Chest`,
  `Prop_Mug`, `Prop_Barrel1`/`Barrel2_Closed`/`Barrel2_Open`,
  `Prop_SatelliteDish`, `Prop_KeyCard`, `Prop_HealthPack`/
  `HealthPack_Tube`/`Prop_Syringe` (infirmerie du bunker — cohérent avec le
  sauvetage des pawns).
- **Réserve potentielle.** `Enemy_EyeDrone`/`QuadShell`/`Trilobite` —
  reclassés depuis "hors sujet" après relecture des images Standard/Pro :
  visuellement ce sont des drones/robots (coque métallique, pas de chair),
  pas des monstres organiques. Ça les rend compatibles avec le thème
  robot-protagoniste — épaves robotiques trouvées dans le bunker, ou faune
  robotique dérivée d'un ancien usage, plutôt que des ennemis de combat.
  Pas de plan concret, juste gardés en tête plutôt qu'écartés.
- **Hors sujet.** `Gun_Pistol`/`Revolver`/`Rifle`/`SMG_Ammo`/`Sniper`/
  `Sniper_Ammo`, `Prop_Grenade`, `Prop_Mine`, `Prop_Ammo*` — pas de combat
  au GDD, y compris les variantes de couleur supplémentaires vues côté Pro.
- **Deluxe/Pro (lecture d'image, non vérifiée).** Standard = 37 assets, Pro
  = 65 modèles. Le Pro ajoute surtout : des assets de décor spatial
  (planètes, skybox) — a priori hors sujet, le cadre reste une forêt
  terrestre autour du bunker, pas l'espace ; plus de variantes de
  drones/robots (renforce la piste ci-dessus) ; plus de props écran/HUD de
  consoles ; plus de variantes de couleur d'armes (toujours hors sujet, pas
  de combat) ; un orbe lumineux teal (déco possible, sans usage identifié) ;
  des textures de flaque/gunk vert (matière dangereuse ou biologique —
  pourrait illustrer un risque du Jalon 12, à revoir le moment venu).

### Ultimate Modular Men / Ultimate Modular Women (Quaternius)

Pas encore ouverts en détail — base prometteuse pour les pawns. Chaque
tenue (`Worker`, `Farmer`, `Casual*`, `Adventurer`, `Suit`, `Punk`,
`SciFi`/`Spacesuit`, `Medieval`, `Witch`, `King`, `Soldier`/`Swat`,
`Formal`, `Beach`) se démonte en `Body`/`Head`/`Feet`/`Legs` sur un rig
humanoïde partagé — plusieurs variantes par corps à vérifier à l'ouverture,
et la peau/texture est modifiable pour multiplier encore les variantes.

- **Réserve potentielle forte.** Correspond à la décision en suspens du
  Jalon 8 (traits d'origine des pawns : reconversion progressive vs
  compétences ancien-monde) — `Worker`/`Farmer`/`Casual` comme base
  "pawn ordinaire", les tenues plus marquées (`Suit`, `King`, `Witch`,
  `Punk`) comme signal visuel d'un passé spécifique si cette piste est
  retenue — dont le pawn "financier" évoqué sous Resource Bits (`Suit`).
- **Prochaine étape concrète (pas maintenant) :** ouvrir les `.blend`/`.fbx`
  pour compter les variantes de corps/visage natives, et vérifier la
  compatibilité du rig avec Universal Animation Library / UAL2 ci-dessous.
- **Hors sujet pour le robot.** Ce sont des humains — le chassis du robot
  (Jalon 6) est un problème séparé, pas couvert par ces packs.

### Universal Animation Library / Universal Animation Library 2 (Quaternius)

Bibliothèques d'animations génériques sur rig humanoïde standard,
compatibles avec les packs de persos ci-dessus.

- **Usage prévu, déjà nommé en dette.** La dette Jalon 3 mentionne déjà
  "intégration Universal Animation Library 2, à revalider au chassis robot
  (Jalon 6)" — mais elles serviront d'abord aux **pawns** (Jalon 5,
  locomotion via `NavigationAgent3D`), avant le robot.
  UAL2 inclut en plus un mannequin femme séparé (`Mannequin_F`) — à
  vérifier s'il correspond au rig d'Ultimate Modular Women.
- **Deluxe/Pro (lecture d'image, non vérifiée).** Les deux libs ont le même
  écart Standard/Pro : le Standard gratuit ne donne que 42 animations
  basiques (idle, walk, sit, quelques actions d'interaction) sur les 120+
  (UAL1) / 130+ (UAL2) que couvre la version Pro/Source. Sans le Pro, la
  locomotion de base tient déjà (Jalon 5), mais tout ce qui rendrait les
  pawns "vivants" est verrouillé : émotes (`crying`, `nodding`,
  `idle_look_around`), farming (`farm_harvest`, `farm_plantseed`,
  `farm_watering`, `treechopping`, `mining` — UAL2), la pêche
  (`fish_cast`/`fish_reel`, UAL2 — rejoint le gag pêche noté sous KayKit RPG
  Tools), et des déplacements moins raides (climb, wallrun, dodge, jog
  directionnel). Le reste — combat, épée, bouclier, `zombie_*` — est hors
  sujet pour les pawns, mais les `zombie_*` (démarche raide/erratique,
  UAL1 et UAL2) sont un candidat naturel si la faune perturbée du Jalon 12
  a besoin d'une locomotion "abîmée" plutôt que de créer une nouvelle
  bibliothèque. Verdict : le Pro serait surtout utile pour les émotes et le
  farming, pas indispensable au socle de locomotion.

## KayKit RPG Tools

Pack d'outils/objets d'artisanat et d'archive, 42 modèles. Angle retenu :
gros pourvoyeur pour les stations d'artisanat et le système tech/archive du
Jalon 10, avec une question ouverte sur le recoupement avec les outils bois
déjà en place.

- **Usage prévu.** Outils d'atelier : `anvil`, `grindstone`, `handdrill`,
  `handplane`, `file`, `chisel`, `mallet`, `wrench_A`/`B`, `screwdriver_A`/
  `B` (long/short/color), `shovel`, `trowel`, `pickaxe`, `axe`, `knife` —
  stations de craft low-tech. Connaissance/archive (Jalon 10) : `journal_closed`/
  `open`, `map`/`map_empty`/`map_rolled`, `blueprint`/`blueprint_stacked`,
  `pencil_A`/`B` (long/short), `magnifying_glass`, `compass_base`,
  `drafting_compass`. Divers utilitaires : `lantern`, `torch`/`torch_burnt`,
  `rope_bundle_A`/`B`, `bucket_metal`, `nail`, `screw_A`/`B`, `tongs`.
- **Question ouverte.** `shovel`, `pickaxe`, `axe`, `knife` existent déjà en
  version bois dans `characters/tools/`. À trancher plus tard : ces versions
  métal du pack RPG Tools comme palier d'amélioration (upgrade tier bois →
  métal, cohérent avec un arbre tech par tags), ou redondance à ignorer.
- **Hors sujet.** Rien identifié — le pack est entièrement dans le
  périmètre artisanat/archive/utilitaire bas-tech.
- **Deluxe/Pro (lecture d'image, non vérifiée).** Le Standard couvre les
  42 modèles listés ci-dessus. Le Pro ("Extra Only") ajoute trois familles
  distinctes, pas de simples variantes : un set de crochetage (5 picks +
  pochette en cuir), des cadenas et clés assortis (3 teintes), et de la
  pêche (canne + boîte à leurres, 2 variantes, hameçons/flotteurs). Le
  crochetage et les cadenas/clés seraient cohérents avec un système de
  coffres/portes verrouillés si un tel système existe un jour (rien de
  prévu au GDD actuellement — à garder en réserve potentielle, pas en usage
  prévu). La pêche est plus directement intéressante : aucune mécanique de
  pêche n'est au GDD, mais le cadre solarpunk cosy (rivière déjà évoquée
  pour le rouissage des fibres) en ferait un ajout thématiquement facile —
  à signaler comme piste, pas comme besoin. Les animations de pêche
  correspondantes existent côté UAL2 Pro (voir Universal Animation Library
  ci-dessus) — si la piste est retenue un jour, les deux packs se
  complètent.

## Pistes externes repérées (pas encore possédées)

Liens itch.io repérés par l'utilisateur, pas encore téléchargés ni intégrés.
Infos tirées des pages produit — à vérifier au moment de l'achat/téléchargement.

- **[Godot Skies](https://binbun3d.itch.io/godot-skies)** — shader de ciel
  dynamique, natif Godot (le seul de la liste pensé pour le moteur). Version
  de base gratuite (1 shader) ; version complète payante (nom-ton-prix, dès
  5 $) avec 24 préréglages (15 réalistes, 10 stylisés, 4 expérimentaux),
  soleil/lune dynamiques, transition jour/nuit, nuages avec parallaxe. CC0.
  **À trouver** direct : le GDD vise un extérieur forêt en permanence, pas
  de skybox actuel identifié dans les packs déjà catalogués — bon candidat
  pour un ciel stylisé cosy plutôt que réaliste.
- **[PSX First Person Arms (Free)](https://drillimpact.itch.io/psx-first-person-arms-free)**
  — rig de bras FPS façon PS1/PS2, 2 textures (mains nues / gants noirs),
  18 animations (coups, saisie, couteau, idle). CC0, FBX/GLB/.blend.
  Réserve potentielle pour le robot (Jalon 6) : texture à adapter en bras
  robotiques comme le note l'utilisateur — mais le style PSX/rétro tranche
  avec le stylisé Quaternius du reste du projet, à vérifier visuellement
  avant d'investir du temps dessus. Les animations de combat (coups/couteau)
  sont hors sujet, seule la base bras + idle/grab intéresse a priori.
- **[Stylized Forest Kit](https://assetquest.itch.io/stylized-forest-kit)**
  — arbres, buissons, plantes de sol, champignons, oiseaux, props pour forêt
  européenne stylisée. Payant (dès 3 $), CC0, texture unique/atlas. Réserve
  potentielle pour varier ou compléter la canopée Quaternius (oiseaux
  notamment : rien de tel dans Stylized Nature MegaKit) — à comparer
  visuellement avant achat pour vérifier la compatibilité de style.
- **[LowPoly Environment Pack](https://k0rveen.itch.io/lowpoly-environment-pack)**
  — 31 meshes low-poly (buissons, montagnes, herbes, troncs, plantes,
  rochers, arbres). Gratuit (nom-ton-prix), licence CC-BY (attribution
  requise — à noter si utilisé, différent des CC0 déjà en place). Overlap
  fort avec Stylized Nature MegaKit déjà exploité ; l'intérêt principal
  serait les montagnes (rien d'équivalent catalogué ailleurs pour l'instant)
  — à vérifier au moment où le terrain généré aura besoin de reliefs marqués.
- **[KayKit: Furniture Bits](https://kaylousberg.itch.io/furniture-bits)**
  — mobilier (lits, canapés, tables, chaises, lampes, bureaux, moniteurs,
  déco). CC0. Gratuit : 50+ modèles ; Extra (3,95 $+) : 20 modèles et 3
  textures en plus ; Source (5,95 $+) : + fichiers .blend. Recouvre en
  bonne partie ce que Fantasy Props et SciFi Essentials couvrent déjà
  (tables, chaises, bureaux) — utile surtout si le style KayKit (même
  famille que Survival/outils/RPG Tools déjà utilisés) est préféré au
  Quaternius pour l'ameublement du bunker, question de cohérence visuelle
  à trancher plutôt qu'un vrai manque de contenu.
- **[Low Poly Nature Pack](https://svartskogen.itch.io/low-poly-nature-pack)**
  — arbres, plantes, rochers, champignons, pièces d'environnement, tuiles
  de terrain. Lite gratuite (31 prefabs) / Pro payante (134 prefabs, dès
  3,99 $). CC0, matériau/texture partagés + LOD. L'utilisateur y a repéré un
  tronc au sol — élément qui manque justement dans Stylized Nature MegaKit
  (`DeadTree_*` est un tronc débout sans feuillage, pas couché) : piste
  concrète pour combler ce trou plutôt qu'une exploration générale du pack.
- **[Low Poly Forest Asset Pack](https://billybonq.itch.io/low-poly-forest-asset-pack)**
  — 38 modèles (arbres, souches, troncs, champignons, rochers, buissons,
  racines, pancartes), couleurs plates, variantes "mystiques". Gratuit
  (nom-ton-prix), CC0, fichier .blend. L'utilisateur le juge déjà trop
  low-poly pour les souches par rapport au reste du projet — noté ici pour
  mémoire (ne pas le rouvrir sans raison neuve), le reste de la liste offre
  de meilleurs candidats pour les mêmes besoins (troncs, souches).
- **[Stylized Fence](https://elijahcobden.itch.io/stylized-fence)** —
  3 modèles de base (poteau, planche fine, planche large) + 8 sections
  préassemblées, bois low-poly. Nom-ton-prix, pas de licence explicite sur
  la page (l'auteur confirme en commentaire l'usage commercial autorisé —
  à re-vérifier avant d'importer). Comble un vrai trou : ni Medieval
  Village ni Fantasy Props ne semblent avoir de clôture en planches simples
  (Medieval Village a des clôtures mais côté Deluxe/Pro, en fer forgé) —
  candidat direct pour délimiter jardins/enclos low-tech.
- **[JulioVII (storefront)](https://juliovii.itch.io)** — pas un pack mais
  un catalogue de textures PBR stylisées 4K (bois, pierre/briques, tissu,
  cuir, métal, plastique, façades, tuiles) en packs gratuits de 9-20
  matériaux chacun, plus des séries payantes (~7 $/volume). Licence non
  précisée globalement, à vérifier pack par pack. Utilité : aucun des packs
  3D catalogués ne fournit de bibliothèque de textures indépendante des
  meshes — pertinent le jour où les constructions low-tech (terre
  crue/hempcrete, bois scié) ont besoin d'un matériau réutilisable plutôt
  que la texture fixe d'un mesh Quaternius/KayKit. Pas urgent avant le
  Jalon 11.
- **[Lowpoly Animals Vol.1](https://seaeees.itch.io/lowpoly-animals-1)** —
  8 modèles (cheval, gazelle, rhino, éléphant, pingouins, dauphin, lapin,
  vache), gratuit, licence permissive (pas de revente/redistribution).
  **Sans animations ni squelette** — limite forte pour toute faune qui doit
  bouger. La moitié du bestiaire (rhino/éléphant/pingouins/dauphin) est
  hors sujet pour une forêt tempérée ; lapin et vache seraient les seuls
  pertinents (petite faune ambiante, ou élevage — écho au `Cage_Small` déjà
  noté sous Fantasy Props). Faute d'animations, plus utile comme prop
  statique (élevage, silhouette lointaine) que comme faune vivante — voir
  aussi "Manques identifiés" ci-dessous pour la faune en général.
- **[OpenMoji](https://openmoji.org)** — bibliothèque libre de 4495 emojis,
  cohérents visuellement (même studio, même style), en SVG couleur/noir et
  PNG plusieurs tailles, versions peau/genre incluses. CC BY-SA 4.0
  (attribution + partage à l'identique — à respecter si utilisé, différent
  du CC0 dominant dans le catalogue). Répond directement au besoin de bulles
  d'interaction du GDD (communication des pawns par pictos plutôt que texte
  ou voix) — reste à filtrer un sous-ensemble cohérent avec le ton
  solarpunk cosy plutôt que d'importer les 4495.
- **[Stylized Low Poly Nature Lite](https://justcreate3d.itch.io/stylized-low-poly-nature-lite)**
  — seulement 6 prefabs (arbres, herbe, plantes), FBX, feuillage
  recolorable. Gratuit, licence commerciale permissive (pas de revente des
  fichiers bruts). Le "champi rouge sympa" repéré par l'utilisateur en fait
  partie mais le pack lui-même est trop petit pour justifier un
  téléchargement en soi — à ne prendre que pour ce champignon précis si
  besoin, pas comme pack de fond.
- **[Collection Sketchfab — 3DDisco](https://sketchfab.com/3DDisco/collections/cartoon-asset-3d-models-5efd61fd5d804d62a3837b606ed08c55)**
  — pomme de pin, gland, noisette, noix, carotte, terrier de lapin, tronc
  couché repérés par l'utilisateur. Page non lisible en fetch automatique
  (Sketchfab charge son contenu en JS) — à ouvrir manuellement pour
  vérifier licence/format par modèle avant toute décision. Le terrier de
  lapin et le tronc couché rejoignent des trous déjà identifiés (faune/
  élevage, tronc au sol) ; pomme de pin/gland/noisette/noix seraient des
  petits objets de cueillette jamais couverts jusqu'ici.
- **[Collection Sketchfab — Lee1998iii](https://sketchfab.com/Lee1998iii/collections/97b11ec22ead4d2096ac4d34de36e4db-334ad4d6ad324b95bef5bfb09548d3d4)**
  — troncs, racines, planches, herbe, fleurs selon l'utilisateur. Page non
  lisible en fetch automatique (même limite Sketchfab) — à ouvrir
  manuellement. Chevauche largement l'existant (Stylized Nature MegaKit) ;
  seul intérêt potentiel identifiable sans l'ouvrir : encore une piste pour
  le tronc couché et les planches (matériaux de construction transformés,
  déjà en réserve sous Resource Bits).
- **[Free Fantasy Medieval Houses and Props](https://store.godotengine.org/asset/emace-art/free-fantasy-medieval-houses-and-props-pack/)**
  — 80+ modèles, bâtiments et props médiévaux d'inspiration slave, 3 LOD,
  matériau de terrain inclus. Gratuit, licence propre à l'auteur (à lire
  avant usage), natif Godot (asset store officiel). Recoupe directement
  Medieval Village MegaKit (même usage prévu : référence de construction
  low-tech) — l'intérêt serait une esthétique différente (slave plutôt que
  fantasy-générique) à comparer visuellement, pas un contenu inédit.
- **[Stylized Water Shader](https://store.godotengine.org/asset/emace-art/stylized-water-shader/)**
  — shader d'eau toon natif Godot 4.7+ (Forward+), bandes de couleur par
  profondeur, écume de berge automatique, caustiques, vagues, 27
  paramètres, 3 matériaux prédéfinis. CC BY 4.0 (attribution requise).
  **À trouver** direct, comme Godot Skies : aucun shader d'eau catalogué
  jusqu'ici alors que la rivière est déjà nommée à plusieurs endroits (GDD :
  rouissage des fibres, pêche évoquée sous RPG Tools) — bon candidat
  concret plutôt qu'à construire à la main.
- **[Free Stylized Low Poly Forest Nature Pack](https://amipolygon.itch.io/free-stylized-low-poly-forest-nature-pack)**
  — page non récupérée (erreur 429, limite de requêtes du site) — à
  rouvrir plus tard pour vérifier le contenu. L'utilisateur y a repéré des
  troncs, dans la continuité des autres pistes troncs-couchés ci-dessus.
- **[Foliage Asset Pack](https://melissaz.itch.io/foliage-asset-pack)** —
  11 modèles thème zone humide (dont "une petite loutre"), stylisé, pensé
  Unity. Licence **CC BY-NC-ND 4.0 — pas d'usage commercial ni de dérivé**,
  incompatible en l'état avec le projet si celui-ci vise une diffusion
  commerciale (à vérifier selon les intentions de diffusion). Le tronc
  repéré par l'utilisateur reste noyé dans un pack à la licence bloquante —
  à écarter sauf clarification de licence par l'auteur.
- **[NatureBlocks](https://bukkbeek.itch.io/natureblocks)** — gros pack
  (500+ assets) : végétation, terrain, rochers, et surtout des **outils de
  génération procédurale** (terrain, rivières, cascades, lacs, routes,
  falaises) avec 10 biomes et 12 styles de végétation, y compris un style
  "Kuwahara" proche de l'esthétique stylisée. Payant (~21 $). Licence
  commerciale/non-commerciale permise, revente interdite. L'utilisateur note
  un style potentiellement proche de Quaternius — à vérifier visuellement
  avant achat, mais l'argument fort n'est pas le contenu (déjà bien couvert
  par Stylized Nature MegaKit) : ce sont les **outils de génération de
  rivières/cascades/lacs**, rien d'équivalent catalogué ailleurs pour le
  terrain généré (Jalon 4).
- **[luyiod — "S"](https://luyiod.itch.io/s)** — page quasi vide en fetch
  automatique (juste un zip de 142 Mo, "stylized nature", pas de détail de
  contenu). À ouvrir manuellement comme le note l'utilisateur — impossible
  de juger la pertinence sans voir le contenu réel.
- **[Hand-Painted Textures Vol.13 — Nature](https://oleekconder.itch.io/hand-painted-textures-vol-13-nature)**
  — 22 textures seamless 2048×2048 (couleur/normal/AO/height), thème
  herbe/roche/forêt/sol. Payant (~2-10 $, aussi dispo dans un bundle de
  4068 textures à 120 $). Licence non détaillée sur la page — à vérifier.
  Textures de sol pour le terrain généré : chevauche l'usage envisagé pour
  JulioVII (texture indépendante des meshes) mais pour le sol plutôt que
  la construction — pertinence à évaluer ensemble le jour où le terrain a
  besoin de plus de variété que les matériaux actuels.

## Manques identifiés (relecture du GDD)

Pas des packs à trouver précisément, plutôt des trous qui ressortent en
relisant le GDD en entier — à garder en tête plutôt qu'à traiter maintenant.

- **Faune locale, vivante et animée.** Le GDD mentionne une "lignée
  animale" comme motif d'expédition et une "faune dangereuse" au Jalon 12,
  mais rien dans les packs catalogués (importés ou non) ne couvre un animal
  animé, low-tech, cohérent avec une forêt tempérée. `Lowpoly Animals`
  ci-dessus n'a ni squelette ni animation. Vrai manque, pas juste une
  réserve.
- **Apiculture et abeilles.** Citée explicitement dans les briques
  solarpunk du GDD (Jalon 11) — aucune ruche, abeille ou rayon de miel
  identifiés dans quoi que ce soit catalogué jusqu'ici.
- **Mycoculture — bassins et chambres de fermentation.** La grotte doit
  devenir un site de mycoculture (Jalon 4/11) ; les champignons décoratifs
  de Stylized Nature MegaKit existent, mais aucun mobilier/installation
  (bassin, étagère de culture, chambre de fermentation) n'a été repéré nulle
  part — à chercher spécifiquement le moment venu plutôt que de supposer
  que Fantasy Props ou SciFi Essentials suffiront.
- **Four solaire concentré.** Déjà signalé sous Medieval Village (le
  four/kiln du Pro comme piste visuelle) — confirmé comme un vrai manque en
  relisant le GDD, c'est un bâtiment nommé explicitement (Jalon 11) sans
  candidat solide actuellement.
- **Chariot/brouette pour le portage.** Le système de portage fragmenté
  (ceinture/poches/sac, `CarryController`) suggère qu'un moyen de transport
  à plusieurs (brouette, charrette à bras) serait cohérent pour le
  transport collectif de matériaux lourds — Medieval Village a une
  charrette, Fantasy Props un `Stall_Cart_Empty` (marché, pas transport) ;
  à vérifier si la charrette de Medieval Village convient une fois le pack
  ouvert en détail.
- **Prothèses/upgrades visibles du robot.** L'atelier robotique (Jalon 6)
  implique des réparations et améliorations visibles sur le châssis — au
  delà du chassis lui-même (déjà en dette), aucun kit de "pièces greffées"
  (bras alternatif, module) n'a été identifié ; `Parts_Cog`/`Parts_Pile_*`
  de Resource Bits sont un début mais restent des pièces brutes, pas des
  modules montables.

## Manques hors du périmètre 3D (relevés par l'utilisateur)

Le catalogue ci-dessus ne couvre que des packs de modèles. Ces manques-là
touchent d'autres disciplines (2D, VFX, UI, audio) — aucun pack repéré pour
l'instant, listés ici pour ne pas les perdre de vue.

- **Faune animée (animaux de forêt, oiseaux).** Rejoint le manque identifié
  ci-dessus depuis le GDD — confirmé indépendamment par relecture directe du
  catalogue.
- **Feu, fumée et autres VFX.** Le feu de camp actuel vient d'un flicker de
  lumière (`flame_light_flicker.gd`), pas d'un vrai effet ; rien de
  catalogué pour fumée, étincelles, poussière ou effets similaires.
- **Intempéries — pluie, grêle.** Aucun système météo ni asset de précipitation
  identifié dans les packs catalogués.
- **Interface / UI.** Aucun kit d'interface repéré (menus, HUD, icônes
  d'action, jauges) — à distinguer des `Decals`/écrans du SciFi MegaKit qui
  sont des props 3D diégétiques, pas de l'UI.
- **Effets à l'écran pour l'expérience robot.** Batterie faible, sous l'eau,
  réveil/boot, connexion qui se dégrade loin de la base — cohérent avec le
  rayon d'action = énergie et la survie du robot au GDD, mais ce sont des
  effets de post-processing/shader d'écran, rien d'identifié.
- **Son.** Un seul bruitage existe actuellement (coupe de bois). Tout le
  reste de la sonorisation (ambiances, actions, UI, voix/babillage des
  pawns) est à trouver.
- **Musique.** Aucune piste ni pack musical identifié.

Ce sont des trous de discipline entière, pas des variantes à comparer —
la démarche pour les combler (pack tout fait vs. génération/commande) reste
à discuter le moment venu, pas dans ce document.