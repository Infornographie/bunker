extends Node3D
class_name PanelGauge

## Destination : entities/interactable/panel/panel_gauge.gd
##
## Barre de remplissage d'un panneau 3D : deux quads non éclairés, l'un de
## fond, l'autre mis à l'échelle horizontalement. Construite au code, comme
## les cases — il n'y a pas de scène à instancier.
##
## Le remplissage grandit depuis la gauche : mettre un quad à l'échelle le
## fait grandir depuis son centre, donc on décale sa position d'autant.

var _fill: MeshInstance3D
var _width: float


func setup(width: float, height: float, color: Color) -> void:
	_width = width

	var background := _make_quad(width, height, Color(0.08, 0.08, 0.1, 0.8))
	background.position.z = 0.0
	add_child(background)

	_fill = _make_quad(width, height, color)
	_fill.position.z = 0.002
	add_child(_fill)

	set_ratio(0.0)


func set_ratio(ratio: float) -> void:
	var clamped := clampf(ratio, 0.0, 1.0)
	# Une échelle nulle fait disparaître le quad et brouille les normales :
	# on garde un epsilon plutôt que zéro.
	_fill.scale.x = maxf(clamped, 0.0001)
	_fill.position.x = -_width * 0.5 + _width * clamped * 0.5


func _make_quad(width: float, height: float, color: Color) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(width, height)
	node.mesh = quad

	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = color
	# Même raison que les cases : une jauge cachée derrière une flamme ne
	# sert à rien. Voir PanelSlot.setup().
	material.no_depth_test = true
	material.render_priority = 1
	node.material_override = material

	return node
