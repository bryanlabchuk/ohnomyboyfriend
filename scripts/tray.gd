class_name Tray
extends StaticBody3D
## A 3D tray that dice roll onto. Has raised edges to contain dice.

@export var tray_size: Vector2 = Vector2(0.5, 0.4)
@export var edge_height: float = 0.02
@export var tray_color: Color = Color(0.55, 0.38, 0.22)  # Warm wood


func _ready() -> void:
	_setup_tray()


func _setup_tray() -> void:
	var mesh_instance := MeshInstance3D.new()
	var surface_tool := SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)

	var hx := tray_size.x / 2.0
	var hy := tray_size.y / 2.0

	# Bottom (floor) - 2 triangles
	var v0 := Vector3(-hx, 0, -hy)
	var v1 := Vector3(hx, 0, -hy)
	var v2 := Vector3(hx, 0, hy)
	var v3 := Vector3(-hx, 0, hy)
	_add_quad(surface_tool, v0, v1, v2, v3, Vector3.UP)

	# Edges - 4 sides (inward-facing normals for inside visibility)
	var e := edge_height
	_add_quad(surface_tool, v0, v3, v3 + Vector3(0, e, 0), v0 + Vector3(0, e, 0), Vector3(-1, 0, 0))  # left
	_add_quad(surface_tool, v1, v0, v0 + Vector3(0, e, 0), v1 + Vector3(0, e, 0), Vector3(0, 0, -1))   # front
	_add_quad(surface_tool, v2, v1, v1 + Vector3(0, e, 0), v2 + Vector3(0, e, 0), Vector3(1, 0, 0))  # right
	_add_quad(surface_tool, v3, v2, v2 + Vector3(0, e, 0), v3 + Vector3(0, e, 0), Vector3(0, 0, 1))  # back

	# Top of edges
	_add_quad(surface_tool, v0 + Vector3(0, e, 0), v3 + Vector3(0, e, 0), v2 + Vector3(0, e, 0), v1 + Vector3(0, e, 0), Vector3.UP)

	surface_tool.generate_normals()
	var mat := StandardMaterial3D.new()
	mat.albedo_color = tray_color
	mat.roughness = 0.75
	mat.metallic = 0.02
	surface_tool.set_material(mat)
	mesh_instance.mesh = surface_tool.commit()
	add_child(mesh_instance)

	# Collision - floor and 4 walls to contain dice
	var floor_col := CollisionShape3D.new()
	var floor_shape := BoxShape3D.new()
	floor_shape.size = Vector3(tray_size.x, 0.01, tray_size.y)
	floor_col.shape = floor_shape
	floor_col.position = Vector3(0, 0.005, 0)
	add_child(floor_col)

	var wall_thickness := 0.01

	for i in range(4):
		var w := CollisionShape3D.new()
		var ws := BoxShape3D.new()
		var offset := Vector3.ZERO
		if i == 0:  # left (-x)
			ws.size = Vector3(wall_thickness, e, tray_size.y + wall_thickness * 2)
			offset = Vector3(-hx - wall_thickness / 2, e / 2, 0)
		elif i == 1:  # front (-z)
			ws.size = Vector3(tray_size.x + wall_thickness * 2, e, wall_thickness)
			offset = Vector3(0, e / 2, -hy - wall_thickness / 2)
		elif i == 2:  # right (+x)
			ws.size = Vector3(wall_thickness, e, tray_size.y + wall_thickness * 2)
			offset = Vector3(hx + wall_thickness / 2, e / 2, 0)
		else:  # back (+z)
			ws.size = Vector3(tray_size.x + wall_thickness * 2, e, wall_thickness)
			offset = Vector3(0, e / 2, hy + wall_thickness / 2)
		w.shape = ws
		w.position = offset
		add_child(w)


func _add_quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, _normal: Vector3) -> void:
	st.add_vertex(a)
	st.add_vertex(b)
	st.add_vertex(c)
	st.add_vertex(a)
	st.add_vertex(c)
	st.add_vertex(d)
