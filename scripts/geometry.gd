class_name Geo
extends RefCounted
static var cache: Dictionary = {}
static func material(color: String, glow: float = 0.0) -> StandardMaterial3D:
	var key = color+str(glow)
	if cache.has(key): return cache[key]
	var m = StandardMaterial3D.new()
	m.albedo_color = Color(color)
	m.roughness = 1.0
	m.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	if glow > 0:
		m.emission_enabled = true
		m.emission = Color(color)
		m.emission_energy_multiplier = glow
	cache[key] = m
	return m
static func mesh(parent: Node3D, shape: Mesh, pos: Vector3, color: String, solid: bool = false, glow: float = 0) -> MeshInstance3D:
	var n = MeshInstance3D.new()
	n.mesh = shape
	n.material_override = material(color,glow)
	n.position = pos
	parent.add_child(n)
	if solid:
		var body = StaticBody3D.new()
		n.add_child(body)
		var c = CollisionShape3D.new()
		c.shape = shape.create_convex_shape()
		body.add_child(c)
	return n
static func box(p: Node3D, pos: Vector3, size: Vector3, color: String, solid: bool = false, glow: float = 0) -> MeshInstance3D:
	var m = BoxMesh.new()
	m.size = size
	return mesh(p,m,pos,color,solid,glow)
static func cylinder(p: Node3D, pos: Vector3, radius: float, height: float, color: String, top: float = -1, solid: bool = false) -> MeshInstance3D:
	var m = CylinderMesh.new()
	m.bottom_radius = radius
	m.top_radius = radius if top < 0 else top
	m.height = height
	m.radial_segments = 12
	return mesh(p,m,pos,color,solid)
static func sphere(p: Node3D, pos: Vector3, size: Vector3, color: String, glow: float = 0) -> MeshInstance3D:
	var m = SphereMesh.new()
	m.radius = 0.5
	m.height = 1.0
	m.radial_segments = 14
	m.rings = 7
	var n = mesh(p,m,pos,color,false,glow)
	n.scale = size
	return n
static func text(p: Node3D, value: String, pos: Vector3, size: int = 32) -> Label3D:
	var n = Label3D.new()
	n.text = value
	n.position = pos
	n.font_size = size
	n.pixel_size = 0.012
	n.modulate = Color("f1dfb6")
	n.outline_modulate = Color("24323c")
	n.outline_size = 6
	p.add_child(n)
	return n
static func bench(p: Node3D, pos: Vector3, angle: float = 0) -> void:
	var n = Node3D.new()
	p.add_child(n)
	n.position = pos
	n.rotation.y = angle
	for x in [-1.1,1.1]: box(n,Vector3(x,0.35,0),Vector3(0.1,0.7,0.65),"344b53")
	for z in [-0.24,0,0.24]: box(n,Vector3(0,0.7,z),Vector3(2.7,0.12,0.19),"9b8367",true)
	for y in [1.0,1.23]: box(n,Vector3(0,y,0.33),Vector3(2.7,0.18,0.1),"9b8367")
static func lamp(p: Node3D, pos: Vector3, height: float = 3.8) -> void:
	cylinder(p,pos+Vector3(0,height/2,0),0.075,height,"415862")
	box(p,pos+Vector3(0,height,0),Vector3(0.9,0.1,0.5),"314650")
	box(p,pos+Vector3(0,height-0.08,0),Vector3(0.65,0.06,0.32),"ebcb93",false,0.4)
static func tree(p: Node3D, pos: Vector3, rng: RandomNumberGenerator) -> void:
	cylinder(p,pos+Vector3(0,1.5,0),0.18,3,"716556",0.1,true)
	for i in range(6):
		sphere(p,pos+Vector3(rng.randf_range(-1.2,1.2),rng.randf_range(2.6,3.8),rng.randf_range(-1,1)),Vector3(2.3,1.1,2.1),["9aa68c","b2b395","899e8b"][i%3])
