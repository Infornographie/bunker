shader_type spatial;
render_mode diffuse_burley;

// Habillage du terrain par sa propre géométrie : l'altitude fait passer l'herbe
// à la roche, la pente fait passer la roche à la paroi nue. Aucune donnée en
// plus n'est nécessaire — hauteur et normale sont déjà là.
//
// S'y ajoute une variation de teinte tirée d'un bruit calculé dans le shader.
// Sans elle, une pente régulière est un aplat de couleur unique, et le sol a
// l'air d'être en plastique quel que soit son relief.
//
// La couleur de sommet porte la couverture végétale (canal rouge) : sous un
// couvert fermé le sol est une litière brune, dans les trouées c'est de l'herbe.
// C'est ce qui donne à une clairière lointaine une couleur au lieu d'un trou, et
// c'est le même tableau qui décidera de la densité des strates basses. Les
// couleurs de biome viendront s'ajouter dans les autres canaux, sans remplacer
// ce calcul : la pente restera de la roche quel que soit le biome.

uniform vec3 grass_color : source_color = vec3(0.36, 0.42, 0.26);
// Sol de sous-bois : feuilles mortes et humus, là où le couvert est fermé.
uniform vec3 litter_color : source_color = vec3(0.28, 0.22, 0.14);
// Couverture à partir de laquelle le sol est franchement de la litière.
uniform float litter_cover_full : hint_range(0.05, 1.0) = 0.55;
uniform vec3 rock_color : source_color = vec3(0.42, 0.34, 0.24);
uniform vec3 cliff_color : source_color = vec3(0.48, 0.48, 0.46);

// Bande d'altitude sur laquelle l'herbe cède à la roche, en mètres.
uniform float rock_height_start = 70.0;
uniform float rock_height_end = 125.0;
// Bande de pente sur laquelle la roche cède à la paroi nue, en degrés.
uniform float cliff_slope_start = 30.0;
uniform float cliff_slope_end = 44.0;

// Taille des taches de teinte, en tours par mètre.
uniform float tint_scale = 0.03;
// Amplitude de la variation, en fraction de la couleur de base.
uniform float tint_strength : hint_range(0.0, 0.5) = 0.13;

uniform float ground_roughness : hint_range(0.0, 1.0) = 0.95;

varying vec3 world_normal;
varying vec3 world_position;

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

void vertex() {
	world_normal = (MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz;
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec3 n = normalize(world_normal);
	float slope = degrees(acos(clamp(n.y, -1.0, 1.0)));

	vec3 ground_color = mix(grass_color, litter_color, smoothstep(0.0, litter_cover_full, COLOR.r));
	vec3 base = mix(ground_color, rock_color, smoothstep(rock_height_start, rock_height_end, world_position.y));
	vec3 albedo = mix(base, cliff_color, smoothstep(cliff_slope_start, cliff_slope_end, slope));

	// Deux échelles : les grandes taches donnent les zones, la seconde casse
	// leur régularité de près.
	vec2 ground = world_position.xz * tint_scale;
	float tint = value_noise(ground) * 0.65 + value_noise(ground * 3.7) * 0.35;
	ALBEDO = albedo * mix(1.0 - tint_strength, 1.0 + tint_strength, tint);
	ROUGHNESS = ground_roughness;
}