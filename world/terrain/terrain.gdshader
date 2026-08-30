shader_type spatial;
render_mode diffuse_burley;

// Habillage du terrain par sa propre géométrie : l'altitude fait passer l'herbe
// à la roche, la pente fait passer la roche à la paroi nue. Aucune donnée en
// plus n'est nécessaire — hauteur et normale sont déjà là.
//
// Les couleurs de biome viendront s'ajouter ici en couleur de sommet, sans
// remplacer ce calcul : la pente restera de la roche quel que soit le biome.

uniform vec3 grass_color : source_color = vec3(0.36, 0.42, 0.26);
uniform vec3 rock_color : source_color = vec3(0.42, 0.34, 0.24);
uniform vec3 cliff_color : source_color = vec3(0.48, 0.48, 0.46);

// Bande d'altitude sur laquelle l'herbe cède à la roche, en mètres.
uniform float rock_height_start = 90.0;
uniform float rock_height_end = 150.0;
// Bande de pente sur laquelle la roche cède à la paroi nue, en degrés.
uniform float cliff_slope_start = 38.0;
uniform float cliff_slope_end = 55.0;

uniform float ground_roughness : hint_range(0.0, 1.0) = 0.95;

varying vec3 world_normal;
varying float world_height;

void vertex() {
	world_normal = (MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz;
	world_height = (MODEL_MATRIX * vec4(VERTEX, 1.0)).y;
}

void fragment() {
	vec3 n = normalize(world_normal);
	float slope = degrees(acos(clamp(n.y, -1.0, 1.0)));

	vec3 base = mix(grass_color, rock_color, smoothstep(rock_height_start, rock_height_end, world_height));
	ALBEDO = mix(base, cliff_color, smoothstep(cliff_slope_start, cliff_slope_end, slope));
	ROUGHNESS = ground_roughness;
}
