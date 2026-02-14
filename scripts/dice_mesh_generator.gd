class_name DiceMeshGenerator
extends RefCounted
## Generates mesh geometry for DnD-style polyhedral dice.
## Creates D4 (tetrahedron), D6 (cube), D8 (octahedron), D10, D12 (dodecahedron), D20 (icosahedron).

const PHI := (1.0 + sqrt(5.0)) / 2.0  # Golden ratio

## Creates an ArrayMesh for the specified dice type.
## dice_type: 4, 6, 8, 10, 12, or 20
static func create_dice_mesh(dice_type: int, size: float = 0.5) -> ArrayMesh:
	match dice_type:
		4: return _create_tetrahedron(size)
		6: return _create_cube(size)
		8: return _create_octahedron(size)
		10: return _create_d10(size)
		12: return _create_dodecahedron(size)
		20: return _create_icosahedron(size)
		_: return _create_cube(size)


static func _create_tetrahedron(size: float) -> ArrayMesh:
	# Regular tetrahedron - 4 vertices, 4 triangular faces
	var s := size * sqrt(2.0)
	var verts := PackedVector3Array([
		Vector3(s, s, s) / sqrt(3.0),
		Vector3(-s, -s, s) / sqrt(3.0),
		Vector3(-s, s, -s) / sqrt(3.0),
		Vector3(s, -s, -s) / sqrt(3.0)
	])
	return _verts_to_mesh(verts, [0, 1, 2,  0, 2, 3,  0, 3, 1,  1, 3, 2])


static func _create_cube(size: float) -> ArrayMesh:
	# Cube - 8 vertices, 12 triangular faces (2 per square face)
	var s := size
	var verts := PackedVector3Array([
		Vector3(-s, -s, -s), Vector3(s, -s, -s), Vector3(s, s, -s), Vector3(-s, s, -s),
		Vector3(-s, -s, s), Vector3(s, -s, s), Vector3(s, s, s), Vector3(-s, s, s)
	])
	var indices := PackedInt32Array([
		0, 1, 2, 0, 2, 3,  # back
		5, 4, 7, 5, 7, 6,  # front
		4, 0, 3, 4, 3, 7,  # left
		1, 5, 6, 1, 6, 2,  # right
		3, 2, 6, 3, 6, 7,  # top
		4, 5, 1, 4, 1, 0   # bottom
	])
	return _verts_to_mesh(verts, indices)


static func _create_octahedron(size: float) -> ArrayMesh:
	# Octahedron - 6 vertices at ±axes, 8 triangular faces
	var s := size
	var verts := PackedVector3Array([
		Vector3(s, 0, 0), Vector3(-s, 0, 0),
		Vector3(0, s, 0), Vector3(0, -s, 0),
		Vector3(0, 0, s), Vector3(0, 0, -s)
	])
	return _verts_to_mesh(verts, [
		4, 2, 0,  4, 0, 3,  4, 3, 1,  4, 1, 2,
		5, 0, 2,  5, 3, 0,  5, 1, 3,  5, 2, 1
	])


static func _create_icosahedron(size: float) -> ArrayMesh:
	# Icosahedron - 12 vertices, 20 triangular faces (golden ratio based)
	var s := size
	var verts := PackedVector3Array([
		Vector3(-1, PHI, 0).normalized() * s,
		Vector3(1, PHI, 0).normalized() * s,
		Vector3(-1, -PHI, 0).normalized() * s,
		Vector3(1, -PHI, 0).normalized() * s,
		Vector3(0, -1, PHI).normalized() * s,
		Vector3(0, 1, PHI).normalized() * s,
		Vector3(0, -1, -PHI).normalized() * s,
		Vector3(0, 1, -PHI).normalized() * s,
		Vector3(PHI, 0, -1).normalized() * s,
		Vector3(PHI, 0, 1).normalized() * s,
		Vector3(-PHI, 0, -1).normalized() * s,
		Vector3(-PHI, 0, 1).normalized() * s
	])
	return _verts_to_mesh(verts, [
		0, 11, 5,  0, 5, 1,  0, 1, 7,  0, 7, 10,  0, 10, 11,
		1, 5, 9,  5, 11, 4,  11, 10, 2,  10, 7, 6,  7, 1, 8,
		3, 9, 4,  3, 4, 2,  3, 2, 6,  3, 6, 8,  3, 8, 9,
		4, 9, 5,  2, 4, 11,  6, 2, 10,  8, 6, 7,  9, 8, 1
	])


static func _create_dodecahedron(size: float) -> ArrayMesh:
	# Dodecahedron - 20 vertices, 12 pentagonal faces (triangulated)
	var inv_phi := 1.0 / PHI
	var verts := PackedVector3Array([
		Vector3(1, 1, 1) * inv_phi * size, Vector3(1, 1, -1) * inv_phi * size,
		Vector3(1, -1, 1) * inv_phi * size, Vector3(1, -1, -1) * inv_phi * size,
		Vector3(-1, 1, 1) * inv_phi * size, Vector3(-1, 1, -1) * inv_phi * size,
		Vector3(-1, -1, 1) * inv_phi * size, Vector3(-1, -1, -1) * inv_phi * size,
		Vector3(0, inv_phi, PHI) * size, Vector3(0, inv_phi, -PHI) * size,
		Vector3(0, -inv_phi, PHI) * size, Vector3(0, -inv_phi, -PHI) * size,
		Vector3(inv_phi, PHI, 0) * size, Vector3(inv_phi, -PHI, 0) * size,
		Vector3(-inv_phi, PHI, 0) * size, Vector3(-inv_phi, -PHI, 0) * size,
		Vector3(PHI, 0, inv_phi) * size, Vector3(PHI, 0, -inv_phi) * size,
		Vector3(-PHI, 0, inv_phi) * size, Vector3(-PHI, 0, -inv_phi) * size
	])
	# 12 pentagonal faces - vertex indices, triangulated as fans
	var faces := [
		[0, 8, 4, 14, 12], [0, 12, 16, 2, 10], [0, 10, 6, 18, 8],
		[1, 12, 14, 5, 9], [1, 9, 17, 3, 11], [1, 11, 7, 19, 12],
		[2, 16, 18, 6, 10], [3, 17, 16, 2, 11], [4, 8, 18, 6, 14],
		[5, 14, 6, 19, 9], [7, 19, 18, 16, 17], [4, 18, 19, 7, 15]
	]
	var indices: PackedInt32Array = []
	for f in faces:
		for k in range(1, f.size() - 1):
			indices.append(f[0])
			indices.append(f[k])
			indices.append(f[k + 1])
	return _verts_to_mesh(verts, indices)


static func _create_d10(size: float) -> ArrayMesh:
	# Pentagonal trapezohedron - simplified as bipyramid (2 pentagonal pyramids)
	var verts := PackedVector3Array()
	var indices: PackedInt32Array = []
	var r := size * 0.8
	verts.append(Vector3(0, size, 0))  # top
	verts.append(Vector3(0, -size, 0))  # bottom
	for i in range(5):
		var angle := TAU * i / 5.0 - PI/2
		verts.append(Vector3(cos(angle) * r, 0, sin(angle) * r))
	# Top pyramid: 0 connecting to base 2-6
	for i in range(5):
		indices.append(0)
		indices.append(2 + i)
		indices.append(2 + (i + 1) % 5)
	# Bottom pyramid
	for i in range(5):
		indices.append(1)
		indices.append(2 + (i + 1) % 5)
		indices.append(2 + i)
	return _verts_to_mesh(verts, indices)


static func _verts_to_mesh(verts: PackedVector3Array, indices) -> ArrayMesh:
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts

	var normals := PackedVector3Array()
	normals.resize(verts.size())
	for i in verts.size():
		normals[i] = verts[i].normalized()

	# Compute face normals from triangles
	var idx_array: PackedInt32Array
	if indices is PackedInt32Array:
		idx_array = indices
	else:
		idx_array = PackedInt32Array(indices)

	for i in range(0, idx_array.size(), 3):
		var a := verts[idx_array[i]]
		var b := verts[idx_array[i + 1]]
		var c := verts[idx_array[i + 2]]
		var n := (b - a).cross(c - a).normalized()
		normals[idx_array[i]] += n
		normals[idx_array[i + 1]] += n
		normals[idx_array[i + 2]] += n
	for i in normals.size():
		normals[i] = normals[i].normalized()
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = idx_array

	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh
