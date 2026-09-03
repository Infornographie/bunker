shader_type spatial;
render_mode diffuse_burley;

// Habillage du terrain par cinq matériaux texturés, choisis par la géométrie et
// par la couverture végétale. Aucune donnée nouvelle n'est demandée au mesh :
// l'altitude, la pente et la couleur de sommet suffisent à décider ce qu'on est
// en train de regarder.
//
//   herbe      — à découvert, pente faible
//   litière    — sous un couvert fermé (COLOR.r, carte d'ouverture)
//   caillouteux— en altitude, avant la roche nue
//   falaise    — au-delà d'une pente, en projection triplanaire
//   sable      — au ras de l'eau
//
// Quatre principes tenus dans tout le fichier :
//
// 1. **La texture porte le grain et le relief, jamais la teinte de fond.**
//    Chaque matériau a un `tint` multiplicatif et la variation procédurale
//    s'applique à la fin. Le jour où un biome change de palette, aucune texture
//    n'est à refaire — il n'existe qu'un endroit où la couleur se décide.
//
// 2. **Les matériaux se disputent le pixel à la carte de hauteur**, ils ne se
//    fondent pas linéairement. Les cailloux de la roche émergent à travers la
//    terre avant que la terre ne cède : la frontière s'imbrique au lieu de faire
//    une bouillie (`height_weights`).
//
// 3. **Le relief tient à deux échelles, pas à une astuce de déplacement.** Une
//    cellule de terrain fait plusieurs mètres : aucun sommet ne peut porter le
//    grain d'un caillou, le déplacement de géométrie est hors de portée, et la
//    parallaxe en une passe a été essayée puis retirée — elle glissait sous la
//    caméra sans jamais creuser. Ce qui donne l'illusion, c'est la conjonction
//    d'une macro qui compose les grandes formes, d'un détail qui rend la matière
//    de près, et de l'occlusion ambiante qui creuse les joints. Voir le groupe
//    Détail. Si un vrai creusement devient nécessaire un jour, c'est un POM à
//    huit pas sur la falaise seule — pas un décalage en une passe.
//
// 4. **Tout se calcule en coordonnées monde**, jamais avec les UV du mesh : le
//    triplanaire de la falaise et le planaire des autres partagent ainsi la même
//    origine et la même échelle maîtresse. Conséquence à traiter : `ARRAY_TEX_UV`
//    dans le constructeur de mesh et `uv_scale` dans la config ne servent plus.
//
// Les normales sont recomposées en espace monde pour toutes les couches, puis
// converties en espace vue à la toute fin. Le mesh n'ayant pas de tangentes,
// `NORMAL_MAP` est inutilisable : le repère tangent du planaire est reconstruit
// à la main (u suit +X, v suit +Z, ce que garantit la projection monde), et la
// falaise passe par un mélange triplanaire « whiteout ».

group_uniforms Echelle;
// Échelle maîtresse, en tours par mètre : une tuile tous les 1/x mètres. Les
// cinq multiplicateurs ci-dessous s'y appliquent — bouger celui-ci décale toute
// la carte d'un coup, sans défaire les proportions entre matériaux.
uniform float texture_scale = 0.08;
// Intensité du relief des normal maps. Au-delà de 1, on exagère : c'est souvent
// nécessaire sur des textures stylisées, dont le relief est peint doux.
uniform float normal_strength : hint_range(0.0, 3.0) = 1.4;
// Dureté de la dispute entre deux matériaux. 0 = fondu linéaire (mou),
// au-delà de ~0.5 la frontière devient franche et découpée.
uniform float blend_contrast : hint_range(0.01, 1.0) = 0.35;
// Part de l'occlusion ambiante des textures reportée sur la couleur. L'AO est
// aussi passée au moteur (`AO`), mais sur des textures stylisées c'est le
// creusement de l'albédo qui porte la lecture des joints et des interstices.
uniform float ao_on_albedo : hint_range(0.0, 1.0) = 0.6;
uniform float ao_light_affect : hint_range(0.0, 1.0) = 0.35;

group_uniforms Detail;
// Seconde échelle, bien plus fine, multipliée par-dessus la première. C'est ce
// qui rend le gros plan lisible : une texture étalée sur une tuile de 50 m ne
// porte que ~40 pixels par mètre, et à un mètre de la paroi ces pixels sont
// agrandis des dizaines de fois — joints, occlusion et normales sont détruits
// par l'agrandissement bien avant que l'éclairage n'ait son mot à dire. La passe
// de détail réinjecte du grain à une fréquence que la distance ne dilue pas.
//
// C'est la technique des packs haute résolution : une macro qui donne les
// grandes formes, un détail qui donne la matière. Ni l'une ni l'autre seule ne
// suffit — la macro seule est floue de près, le détail seul est un bruit sans
// composition.
//
// Multiplicateur appliqué à l'échelle de la couche. 8 = un grain huit fois plus
// serré que le motif principal.
uniform float detail_ratio : hint_range(2.0, 24.0, 0.5) = 8.0;
// Force du grain sur la couleur, en écart au gris. 0 = pas de détail.
uniform float detail_albedo : hint_range(0.0, 1.0) = 0.3;
// Force du grain sur les normales.
//
// **À zéro par défaut, et ce n'est pas de la timidité.** Le détail étant la même
// texture en réduction, une normale de détail forte fait voir le relief du motif
// *miniature* pendant que la couleur montre le motif principal : les creux ne
// tombent plus sur les formes, et le sol paraît porter deux textures
// désaccordées. Tant que le détail n'a pas sa propre carte — un grain neutre,
// sans formes reconnaissables — il ne doit rester qu'un bruit de surface léger.
// Monter cette valeur au-delà de ~0.3 fait revenir le désaccord.
uniform float detail_normal : hint_range(0.0, 2.0) = 0.0;
// Distance à laquelle le détail s'éteint, en mètres, et longueur du fondu. De
// loin il ne se distingue plus et ne fait que scintiller : autant l'éteindre.
uniform float detail_distance = 40.0;
uniform float detail_fade = 15.0;

group_uniforms Herbe;
uniform sampler2D grass_albedo : source_color, hint_default_white;
uniform sampler2D grass_normal : hint_normal;
uniform sampler2D grass_rough : hint_default_white;
uniform sampler2D grass_height : hint_default_white;
uniform sampler2D grass_ao : hint_default_white;
uniform vec3 grass_tint : source_color = vec3(1.0, 1.0, 1.0);
// Plage réellement occupée par la carte de hauteur, mesurée sur le fichier
// (5e et 95e centiles). Ces cartes n'utilisent qu'une fraction de leur étendue —
// elles sont quasiment grises — et lues brutes elles creusent cinq fois moins
// que demandé, tant pour le relief que pour le mélange. La normalisation leur
// rend leur amplitude. À remesurer si la texture est remplacée.
uniform vec2 grass_height_range = vec2(0.355, 0.525);
uniform float grass_scale : hint_range(0.05, 4.0) = 1.0;

group_uniforms Litiere;
uniform sampler2D litter_albedo : source_color, hint_default_white;
uniform sampler2D litter_normal : hint_normal;
uniform sampler2D litter_rough : hint_default_white;
uniform sampler2D litter_height : hint_default_white;
uniform sampler2D litter_ao : hint_default_white;
uniform vec3 litter_tint : source_color = vec3(1.0, 1.0, 1.0);
// Plage réellement occupée par la carte de hauteur, mesurée sur le fichier
// (5e et 95e centiles). Ces cartes n'utilisent qu'une fraction de leur étendue —
// elles sont quasiment grises — et lues brutes elles creusent cinq fois moins
// que demandé, tant pour le relief que pour le mélange. La normalisation leur
// rend leur amplitude. À remesurer si la texture est remplacée.
uniform vec2 litter_height_range = vec2(0.267, 0.512);
uniform float litter_scale : hint_range(0.05, 4.0) = 1.0;
// Couverture à partir de laquelle le sol est franchement de la litière.
uniform float litter_cover_full : hint_range(0.05, 1.0) = 0.55;

group_uniforms Caillouteux;
uniform sampler2D rocky_albedo : source_color, hint_default_white;
uniform sampler2D rocky_normal : hint_normal;
uniform sampler2D rocky_rough : hint_default_white;
uniform sampler2D rocky_height : hint_default_white;
uniform sampler2D rocky_ao : hint_default_white;
uniform vec3 rocky_tint : source_color = vec3(1.0, 1.0, 1.0);
// Plage réellement occupée par la carte de hauteur, mesurée sur le fichier
// (5e et 95e centiles). Ces cartes n'utilisent qu'une fraction de leur étendue —
// elles sont quasiment grises — et lues brutes elles creusent cinq fois moins
// que demandé, tant pour le relief que pour le mélange. La normalisation leur
// rend leur amplitude. À remesurer si la texture est remplacée.
uniform vec2 rocky_height_range = vec2(0.327, 0.560);
uniform float rocky_scale : hint_range(0.05, 4.0) = 0.6;
// Bande d'altitude sur laquelle le sol végétal cède au caillouteux, en mètres.
uniform float rock_height_start = 70.0;
uniform float rock_height_end = 125.0;

group_uniforms Falaise;
uniform sampler2D cliff_albedo : source_color, hint_default_white;
uniform sampler2D cliff_normal : hint_normal;
uniform sampler2D cliff_rough : hint_default_white;
uniform sampler2D cliff_height : hint_default_white;
uniform sampler2D cliff_ao : hint_default_white;
uniform vec3 cliff_tint : source_color = vec3(1.0, 1.0, 1.0);
// Bien plus grande que les autres : à échelle égale, les pierres de la paroi
// font un mètre et la falaise ressemble à un mur de briques. 0.25 donne des
// blocs de l'ordre de six mètres. C'est aussi pour ça que cette texture-là
// mérite du 2k quand les autres se contentent du 1k.
// Plage réellement occupée par la carte de hauteur, mesurée sur le fichier
// (5e et 95e centiles). Ces cartes n'utilisent qu'une fraction de leur étendue —
// elles sont quasiment grises — et lues brutes elles creusent cinq fois moins
// que demandé, tant pour le relief que pour le mélange. La normalisation leur
// rend leur amplitude. À remesurer si la texture est remplacée.
uniform vec2 cliff_height_range = vec2(0.136, 0.802);
uniform float cliff_scale : hint_range(0.05, 4.0) = 0.25;
// Bande de pente sur laquelle le sol cède à la paroi nue, en degrés.
uniform float cliff_slope_start = 30.0;
uniform float cliff_slope_end = 44.0;
// Netteté du mélange entre les trois projections. Plus haut = transitions plus
// courtes entre les faces, mais tuilage plus visible sur les pentes moyennes.
uniform float triplanar_sharpness : hint_range(1.0, 16.0) = 4.0;

group_uniforms Sable;
uniform sampler2D sand_albedo : source_color, hint_default_white;
uniform sampler2D sand_normal : hint_normal;
uniform sampler2D sand_rough : hint_default_white;
uniform sampler2D sand_height : hint_default_white;
uniform sampler2D sand_ao : hint_default_white;
uniform vec3 sand_tint : source_color = vec3(1.0, 1.0, 1.0);
// Plage réellement occupée par la carte de hauteur, mesurée sur le fichier
// (5e et 95e centiles). Ces cartes n'utilisent qu'une fraction de leur étendue —
// elles sont quasiment grises — et lues brutes elles creusent cinq fois moins
// que demandé, tant pour le relief que pour le mélange. La normalisation leur
// rend leur amplitude. À remesurer si la texture est remplacée.
uniform vec2 sand_height_range = vec2(0.300, 0.519);
uniform float sand_scale : hint_range(0.05, 4.0) = 1.0;
// Altitude de la surface de l'eau, en mètres. Renseignée à la génération : le
// rivage n'est pas dessiné, c'est une bande au-dessus de ce niveau.
uniform float water_level = 0.0;
// Hauteur au-dessus de l'eau où le sable a totalement cédé au sol végétal.
uniform float sand_band = 3.5;

group_uniforms Teinte;
// Taille des taches de teinte, en tours par mètre.
uniform float tint_scale = 0.03;
// Amplitude de la variation, en fraction de la couleur de base.
uniform float tint_strength : hint_range(0.0, 0.5) = 0.13;

varying vec3 world_normal;
varying vec3 world_position;

// Ramène une hauteur lue sur sa plage utile. Hors de cette plage la carte ne
// contient rien : l'étirer, c'est récupérer le relief que le fichier possède
// déjà mais n'exprime pas.
float h_remap(float v, vec2 range) {
	return clamp((v - range.x) / max(range.y - range.x, 0.001), 0.0, 1.0);
}

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float value_noise(vec2 p) {
	vec2 cell = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash21(cell);
	float b = hash21(cell + vec2(1.0, 0.0));
	float c = hash21(cell + vec2(0.0, 1.0));
	float d = hash21(cell + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

// Poids de deux matériaux qui se disputent un pixel. `t` est le mélange voulu
// (0 = tout le premier, 1 = tout le second) ; les hauteurs le corrigent, si bien
// que le matériau le plus « en relief » l'emporte localement. C'est ce qui fait
// que la roche perce la terre par ses cailloux et non par un dégradé.
vec2 height_weights(float t, float ha, float hb) {
	float wa = (1.0 - t) + ha * blend_contrast;
	float wb = t + hb * blend_contrast;
	float cut = max(wa, wb) - blend_contrast;
	wa = max(wa - cut, 0.0);
	wb = max(wb - cut, 0.0);
	return vec2(wa, wb) / max(wa + wb, 0.0001);
}

// Normale monde d'une couche planaire. Les UV suivent +X et +Z en monde, donc le
// repère tangent est connu sans tangentes sur le mesh : on décale simplement la
// normale géométrique dans le plan horizontal.
vec3 planar_normal(vec3 geo, vec2 uv, sampler2D tex) {
	vec2 ts = texture(tex, uv).xy * 2.0 - 1.0;
	return normalize(geo + vec3(ts.x, 0.0, ts.y) * normal_strength);
}

// Normale tangente lue en ne se fiant qu'à X et Y. La compression normal map de
// Godot (RGTC) ne stocke que ces deux canaux et laisse le moteur reconstruire le
// troisième ; en échantillonnant à la main, `.z` ne contient rien d'utilisable.
vec3 tangent_normal(sampler2D tex, vec2 uv) {
	vec2 xy = texture(tex, uv).xy * 2.0 - 1.0;
	return vec3(xy, sqrt(max(1.0 - dot(xy, xy), 0.0)));
}

void vertex() {
	world_normal = (MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz;
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec3 geo = normalize(world_normal);
	float slope = degrees(acos(clamp(geo.y, -1.0, 1.0)));

	// Poids des trois projections de la falaise. Calculés tout de suite : ils
	// servent dès la lecture des hauteurs.
	vec3 tri = pow(abs(geo), vec3(triplanar_sharpness));
	tri /= (tri.x + tri.y + tri.z);

	// --- Première passe : les hauteurs seules ---------------------------------
	// On ne peut pas connaître la surface avant de savoir qui gagne, et on ne
	// peut pas savoir qui gagne sans les hauteurs. D'où deux passes : celle-ci
	// lit les cinq cartes de hauteur au point géométrique, la cascade en déduit
	// la hauteur de surface, et tout le reste se lit au point déplacé.

	vec2 g0 = world_position.xz * texture_scale * grass_scale;
	vec2 l0 = world_position.xz * texture_scale * litter_scale;
	vec2 r0 = world_position.xz * texture_scale * rocky_scale;
	vec2 s0 = world_position.xz * texture_scale * sand_scale;
	float cs = texture_scale * cliff_scale;

	float grass_h = h_remap(texture(grass_height, g0).r, grass_height_range);
	float litter_h = h_remap(texture(litter_height, l0).r, litter_height_range);
	float rocky_h = h_remap(texture(rocky_height, r0).r, rocky_height_range);
	float sand_h = h_remap(texture(sand_height, s0).r, sand_height_range);
	float cliff_h = h_remap(texture(cliff_height, world_position.zy * cs).r, cliff_height_range) * tri.x
		+ h_remap(texture(cliff_height, world_position.xz * cs).r, cliff_height_range) * tri.y
		+ h_remap(texture(cliff_height, world_position.xy * cs).r, cliff_height_range) * tri.z;

	// La cascade, une première fois sur les seules hauteurs. L'ordre raconte la
	// géographie : le couvert décide du sol de forêt, l'altitude fait monter le
	// caillouteux, la pente impose la paroi, et l'eau reprend la main tout en
	// bas — un rivage reste du sable quelle que soit l'altitude du lac.
	float t_litter = smoothstep(0.0, litter_cover_full, COLOR.r);
	float t_rocky = smoothstep(rock_height_start, rock_height_end, world_position.y);
	float t_cliff = smoothstep(cliff_slope_start, cliff_slope_end, slope);
	float t_sand = 1.0 - smoothstep(0.0, sand_band, world_position.y - water_level);

	vec2 w_litter = height_weights(t_litter, grass_h, litter_h);
	float h = grass_h * w_litter.x + litter_h * w_litter.y;
	vec2 w_rocky = height_weights(t_rocky, h, rocky_h);
	h = h * w_rocky.x + rocky_h * w_rocky.y;
	vec2 w_cliff = height_weights(t_cliff, h, cliff_h);
	h = h * w_cliff.x + cliff_h * w_cliff.y;
	vec2 w_sand = height_weights(t_sand, h, sand_h);
	h = h * w_sand.x + sand_h * w_sand.y;

	// Le point d'échantillonnage est le point géométrique.
	//
	// Deux tentatives de relief par décalage d'UV ont été faites ici et retirées :
	// une parallaxe en une passe, puis un vrai POM à seize pas. La première
	// glissait sans creuser, la seconde déformait tout. Au-delà des bugs, le
	// diagnostic est que ce n'était pas le bon levier : le relief d'un sol vient
	// de l'ombrage contenu dans sa texture et de la direction de la lumière, pas
	// d'un décalage d'échantillonnage. Un albédo stylisé est peint à plat, sans
	// ombres cuites — il n'y a rien à révéler. D'où le poids donné ici à
	// l'occlusion ambiante (`ao_on_albedo`), qui est la seule ombre dont on
	// dispose, et aux rochers posés en géométrie, qui portent le volume.
	//
	// Ne pas y revenir sans changer une de ces deux causes.
	vec3 p = world_position;
	float detail_near = 1.0 - smoothstep(detail_distance - detail_fade, detail_distance, length(VERTEX));
	vec2 guv = p.xz * texture_scale * grass_scale;
	vec2 luv = p.xz * texture_scale * litter_scale;
	vec2 ruv = p.xz * texture_scale * rocky_scale;
	vec2 suv = p.xz * texture_scale * sand_scale;
	vec2 uv_x = p.zy * cs;
	vec2 uv_y = p.xz * cs;
	vec2 uv_z = p.xy * cs;

	// --- Seconde passe : couleur, normale, rugosité, occlusion ----------------
	// Cinq blocs de lecture identiques : GDShader n'accepte pas un `sampler2D`
	// en argument de fonction. Voir la dette en fin de fichier.

	vec2 gd = guv * detail_ratio;
	vec2 ld = luv * detail_ratio;
	vec2 rd = ruv * detail_ratio;
	vec2 sd = suv * detail_ratio;
	float ka = detail_albedo * detail_near;
	float kn = detail_normal * detail_near;

	vec3 grass_c = texture(grass_albedo, guv).rgb * grass_tint
		* mix(vec3(1.0), texture(grass_albedo, gd).rgb * 2.0, ka);
	vec3 grass_n = planar_normal(geo, guv, grass_normal);
	grass_n = normalize(grass_n + vec3(tangent_normal(grass_normal, gd).xy, 0.0).xzy * kn);
	float grass_r = texture(grass_rough, guv).r;
	float grass_o = texture(grass_ao, guv).r;

	vec3 litter_c = texture(litter_albedo, luv).rgb * litter_tint
		* mix(vec3(1.0), texture(litter_albedo, ld).rgb * 2.0, ka);
	vec3 litter_n = planar_normal(geo, luv, litter_normal);
	litter_n = normalize(litter_n + vec3(tangent_normal(litter_normal, ld).xy, 0.0).xzy * kn);
	float litter_r = texture(litter_rough, luv).r;
	float litter_o = texture(litter_ao, luv).r;

	vec3 rocky_c = texture(rocky_albedo, ruv).rgb * rocky_tint
		* mix(vec3(1.0), texture(rocky_albedo, rd).rgb * 2.0, ka);
	vec3 rocky_n = planar_normal(geo, ruv, rocky_normal);
	rocky_n = normalize(rocky_n + vec3(tangent_normal(rocky_normal, rd).xy, 0.0).xzy * kn);
	float rocky_r = texture(rocky_rough, ruv).r;
	float rocky_o = texture(rocky_ao, ruv).r;

	vec3 sand_c = texture(sand_albedo, suv).rgb * sand_tint
		* mix(vec3(1.0), texture(sand_albedo, sd).rgb * 2.0, ka);
	vec3 sand_n = planar_normal(geo, suv, sand_normal);
	sand_n = normalize(sand_n + vec3(tangent_normal(sand_normal, sd).xy, 0.0).xzy * kn);
	float sand_r = texture(sand_rough, suv).r;
	float sand_o = texture(sand_ao, suv).r;

	// La falaise, seule couche en triplanaire : c'est la seule qui vive sur des
	// pentes où une projection verticale étire la texture au point de la rendre
	// illisible. Les autres restent planaires — trois fois moins de lectures, et
	// l'étirement y est imperceptible.
	vec2 dx = uv_x * detail_ratio;
	vec2 dy = uv_y * detail_ratio;
	vec2 dz = uv_z * detail_ratio;

	vec3 cliff_c = (texture(cliff_albedo, uv_x).rgb * tri.x
		+ texture(cliff_albedo, uv_y).rgb * tri.y
		+ texture(cliff_albedo, uv_z).rgb * tri.z) * cliff_tint;
	// La falaise est la couche qui souffre le plus de l'agrandissement : c'est
	// elle qui a la plus grande tuile, et c'est contre elle qu'on se colle.
	cliff_c *= mix(vec3(1.0), (texture(cliff_albedo, dx).rgb * tri.x
		+ texture(cliff_albedo, dy).rgb * tri.y
		+ texture(cliff_albedo, dz).rgb * tri.z) * 2.0, ka);
	float cliff_r = texture(cliff_rough, uv_x).r * tri.x
		+ texture(cliff_rough, uv_y).r * tri.y
		+ texture(cliff_rough, uv_z).r * tri.z;
	float cliff_o = texture(cliff_ao, uv_x).r * tri.x
		+ texture(cliff_ao, uv_y).r * tri.y
		+ texture(cliff_ao, uv_z).r * tri.z;

	// Mélange « whiteout » des trois normales : chaque projection est réorientée
	// selon sa face avant d'être sommée. Un simple mix des trois donnerait des
	// normales molles aux arêtes.
	vec3 nx = tangent_normal(cliff_normal, uv_x) + vec3(tangent_normal(cliff_normal, dx).xy, 0.0) * kn;
	vec3 ny = tangent_normal(cliff_normal, uv_y) + vec3(tangent_normal(cliff_normal, dy).xy, 0.0) * kn;
	vec3 nz = tangent_normal(cliff_normal, uv_z) + vec3(tangent_normal(cliff_normal, dz).xy, 0.0) * kn;
	nx = vec3(nx.xy + geo.zy, abs(nx.z) * geo.x);
	ny = vec3(ny.xy + geo.xz, abs(ny.z) * geo.y);
	nz = vec3(nz.xy + geo.xy, abs(nz.z) * geo.z);
	vec3 cliff_n = normalize(mix(geo,
		normalize(nx.zyx * tri.x + ny.xzy * tri.y + nz.xyz * tri.z),
		clamp(normal_strength, 0.0, 1.0)));

	// --- La cascade, avec les poids déjà calculés -----------------------------

	vec3 col = grass_c * w_litter.x + litter_c * w_litter.y;
	vec3 nrm = grass_n * w_litter.x + litter_n * w_litter.y;
	float rgh = grass_r * w_litter.x + litter_r * w_litter.y;
	float occ = grass_o * w_litter.x + litter_o * w_litter.y;

	col = col * w_rocky.x + rocky_c * w_rocky.y;
	nrm = nrm * w_rocky.x + rocky_n * w_rocky.y;
	rgh = rgh * w_rocky.x + rocky_r * w_rocky.y;
	occ = occ * w_rocky.x + rocky_o * w_rocky.y;

	col = col * w_cliff.x + cliff_c * w_cliff.y;
	nrm = nrm * w_cliff.x + cliff_n * w_cliff.y;
	rgh = rgh * w_cliff.x + cliff_r * w_cliff.y;
	occ = occ * w_cliff.x + cliff_o * w_cliff.y;

	col = col * w_sand.x + sand_c * w_sand.y;
	nrm = nrm * w_sand.x + sand_n * w_sand.y;
	rgh = rgh * w_sand.x + sand_r * w_sand.y;
	occ = occ * w_sand.x + sand_o * w_sand.y;

	// --- Sortie ---------------------------------------------------------------
	// La variation de teinte reste appliquée par-dessus les textures : elle
	// travaille à une échelle bien plus grande que la tuile et casse la
	// répétition là où le tuilage commencerait à se lire. C'est aussi le premier
	// recours si une échelle de matériau est montée au point de rendre son motif
	// reconnaissable.
	vec2 ground = world_position.xz * tint_scale;
	float tint = value_noise(ground) * 0.65 + value_noise(ground * 3.7) * 0.35;

	ALBEDO = col * mix(1.0 - tint_strength, 1.0 + tint_strength, tint)
		* mix(1.0, occ, ao_on_albedo);
	ROUGHNESS = rgh;
	AO = occ;
	AO_LIGHT_AFFECT = ao_light_affect;
	NORMAL = normalize((VIEW_MATRIX * vec4(normalize(nrm), 0.0)).xyz);
}

// --- Dette assumée -------------------------------------------------------------
//
// **Les cinq couches sont lues à chaque pixel**, soit une quarantaine de lectures
// de texture au pire (hauteur puis quatre cartes par couche planaire, trois
// projections pour la falaise), alors que deux couches au plus contribuent
// réellement. GDShader n'accepte pas un `sampler2D` en argument de fonction :
// factoriser exige un `Texture2DArray` et une sélection des deux poids dominants,
// ce qui ramènerait le coût à une douzaine de lectures constantes. À faire quand
// le coût se mesure, pas avant — et à ce moment-là les cinq blocs de lecture
// disparaissent d'eux-mêmes.
//
// **Le POM ne se projette pas d'ombre.** Un caillou creuse mais n'assombrit pas
// son voisin ; l'occlusion vient de la carte d'AO, qui elle est fixe. Une passe
// de self-shadowing (une seconde marche vers la lumière) est la suite si le
// relief paraît trop propre — elle doublerait le coût de la marche.
//
// **La silhouette reste plate.** Un POM creuse vers l'intérieur, il ne fait
// jamais dépasser la matière : le bord d'une paroi vu de profil reste net, et
// aucun caillou ne mord sur le ciel. C'est la limite de la méthode, pas un
// réglage — seule de la géométrie la lève.
//
// **Le détail est la même texture à une autre fréquence.** C'est le procédé le
// moins cher qui marche, et il a son défaut : le motif fin est le motif large en
// réduction, donc une corrélation subsiste entre les deux échelles. Une vraie
// texture de détail dédiée (grain neutre, sans grandes formes) serait meilleure
// si le pack en fournit une.
//
// **La bande d'altitude est en mètres absolus** alors que la carte descend de
// `drainage_drop` d'un bout à l'autre : le caillouteux monte plus ou moins haut
// selon l'endroit. Dette héritée du jalon 4, à exprimer en fraction de la hauteur
// tirée le jour où ça se remarque.
