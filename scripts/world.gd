class_name StationWorld
extends Node3D
const G = preload("res://scripts/geometry.gd")
var rng = RandomNumberGenerator.new()
var points: Array[Dictionary] = []
var gate: Node3D
var train: Node3D
var signal_light: MeshInstance3D
var sun: DirectionalLight3D
func _ready() -> void:
	rng.seed = 4701
	sky()
	station()
	garden()
	overlook()
	horizon()
	make_train()
	vegetation()
	details()
	point("ticket","A ticket with no destination",Vector3(0,0.75,9))
	point("notice","Read the evacuation notice",Vector3(-12,1.25,-3))
	point("diary","Stationmaster's notebook",Vector3(-14,0.9,4))
	point("m1","Remember · the promise",Vector3(-16,1,2),true)
	point("cell","Take the reserve cell",Vector3(-17,1.3,30.8))
	point("record","A maintenance record",Vector3(-12,1.2,32))
	point("m2","Remember · the departure",Vector3(-17,0.8,21.5),true)
	point("m4","Remember · a small kindness",Vector3(-6,0.8,-19.2),true)
	point("relay","Open the signal relay",Vector3(-5,1,-18.6))
	point("signal","Tune the memory signal",Vector3(2,1.4,-43.3))
	point("m3","Remember · the last light",Vector3(-4,1,-47),true)
	point("stranger","The traveler in white",Vector3(5.7,0.8,2))
	point("train","Board the last train",Vector3(6.4,0.8,-3))
	G.cylinder(self,Vector3(5.7,0.7,2),0.4,1.4,"c3cbbb",0.2)
	G.sphere(self,Vector3(5.7,1.5,2),Vector3(0.45,0.52,0.45),"daddcd")
	G.box(self,Vector3(5.7,1.48,2.23),Vector3(0.28,0.15,0.05),"70878a")
func sky() -> void:
	var we = WorldEnvironment.new()
	var e = Environment.new()
	e.background_mode = Environment.BG_SKY
	var s = Sky.new()
	var m = ProceduralSkyMaterial.new()
	m.sky_top_color = Color("536f91")
	m.sky_horizon_color = Color("d9b897")
	m.ground_bottom_color = Color("526974")
	m.ground_horizon_color = Color("b7b5a9")
	m.sky_curve = 0.2
	m.sun_angle_max = 8
	s.sky_material = m
	e.sky = s
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color("b6c6d1")
	e.ambient_light_energy = 0.55
	e.ambient_light_sky_contribution = 0
	e.fog_enabled = true
	e.fog_light_color = Color("b9b9b0")
	e.fog_density = 0.0025
	e.fog_sky_affect = 0.15
	we.environment = e
	add_child(we)
	sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-24,-35,0)
	sun.light_color = Color("ffe2b2")
	sun.light_energy = 0.45
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 65
	add_child(sun)
func floor_at(pos: Vector3, size: Vector3, color: String) -> void:
	G.box(self,pos,size,color,true)
func station() -> void:
	floor_at(Vector3(0,-0.48,0),Vector3(17,0.9,44),"838f90")
	floor_at(Vector3(-13,-0.5,2),Vector3(10,1,26),"819082")
	G.cylinder(self,Vector3(-3,-6,0),23,11,"52646d",15)
	G.cylinder(self,Vector3(-4,-14,0),7,10,"465c69",19)
	for z in range(-21,22,2):
		G.box(self,Vector3(7.65,0.025,z),Vector3(0.48,0.06,1.75),"c6b17b")
		for x in range(-7,8,2): G.box(self,Vector3(x,0.005,z),Vector3(0.025,0.02,1.94),"758486")
	for z in range(-70,75,2): G.box(self,Vector3(10,-0.3,z),Vector3(4.5,0.2,0.35),"726f68")
	for x in [8.7,11.3]: G.box(self,Vector3(x,-0.08,0),Vector3(0.13,0.2,150),"596a70")
	G.box(self,Vector3(10,-0.65,0),Vector3(5.1,0.3,150),"566970")
	for z in [-18,-10,-2,6,14]:
		for x in [-6,5]: G.box(self,Vector3(x,2.3,z),Vector3(0.2,4.6,0.2),"526568",true)
		G.box(self,Vector3(-0.5,4.5,z),Vector3(11.5,0.17,0.17),"536466")
	for x in [-3.6,2.7]:
		var roof = G.box(self,Vector3(x,4.9,-2),Vector3(6.6,0.18,38),"3f5863",true)
		roof.rotation.z = 0.11 if x<0 else -0.11
	for z in range(-21,18,2): G.box(self,Vector3(-0.4,5.28,z),Vector3(0.14,0.12,1.9),"73858a")
	for z in [-14,1,12]:
		G.bench(self,Vector3(-3.8,0,z),PI/2)
		G.lamp(self,Vector3(6.4,0,z),3.5)
	G.box(self,Vector3(0,3.7,-8),Vector3(4.8,0.95,0.12),"273f4c")
	G.text(self,"P L A T F O R M   0",Vector3(0,3.75,-7.91),35)
	G.text(self,"LAST SERVICE / --:--",Vector3(0,3.39,-7.9),15)
	floor_at(Vector3(-13,0.06,0),Vector3(9,0.12,14),"9b9586")
	floor_at(Vector3(-17.5,1.8,0),Vector3(0.3,3.6,14),"a6a690")
	for z in [-7,7]: floor_at(Vector3(-13,1.8,z),Vector3(9,3.6,0.3),"a6a690")
	G.box(self,Vector3(-13,3.75,0),Vector3(10,0.25,15),"49616b",true)
	for z in [-6,6]:
		G.box(self,Vector3(-8.6,1.8,z),Vector3(0.18,3.6,2),"a6a690",true)
		G.box(self,Vector3(-8.5,2.7,z),Vector3(0.22,0.8,1.7),"4c646b")
	G.box(self,Vector3(-13,0.6,-4),Vector3(5,1.2,0.8),"796f5e",true)
	G.box(self,Vector3(-13,1.24,-4),Vector3(5.2,0.12,1),"a09072")
	G.bench(self,Vector3(-15,0,4))
	G.text(self,"WAITING ROOM",Vector3(-13,2.9,-6.8),30)
	var clock = G.cylinder(self,Vector3(-13,2.5,-6.75),0.35,0.08,"c7b994")
	clock.rotation.x = PI/2
	G.box(self,Vector3(-13,2.6,-6.68),Vector3(0.025,0.23,0.025),"42505b")
	G.box(self,Vector3(-12.9,2.5,-6.66),Vector3(0.22,0.03,0.03),"42505b")
	G.text(self,"KEEP A LIGHT\nFOR THOSE\nSTILL COMING",Vector3(-16.9,1.8,1),20).rotation.y = PI/2
	G.box(self,Vector3(-6.7,1.1,-17),Vector3(1.3,2.2,0.85),"a56f5c",true)
	G.box(self,Vector3(-6.7,1.4,-16.55),Vector3(1.03,1.2,0.06),"354d59")
	for x in range(4):
		for y in range(2): G.cylinder(self,Vector3(-7.08+x*0.25,1.1+y*0.45,-16.5),0.075,0.23,["b0b9a2","c79f79","8da8ac"][x%3])
	for p in [Vector3(3,0.3,16),Vector3(-5,0.3,-10),Vector3(-14,0.3,4)]:
		G.box(self,p,Vector3(0.8,0.6,0.35),"8c785e",true)
		G.box(self,p+Vector3(0,0.35,0),Vector3(0.26,0.1,0.12),"475661")
	G.box(self,Vector3(-5,0.95,-19.5),Vector3(1.9,1.9,0.7),"465d64",true)
	G.text(self,"LINE POWER",Vector3(-5,2.1,-19),22)
	fence(Vector3(7.9,0,0),43,true)
	fence(Vector3(0,0,21.7),16,false)
	for x in [-5.7,5.7]: fence(Vector3(x,0,-21.7),4.4,false)
func fence(pos: Vector3, length_v: float, along_z: bool) -> void:
	var n = Node3D.new()
	add_child(n)
	n.position = pos
	if along_z: n.rotation.y = PI/2
	for x in range(int(-length_v/2),int(length_v/2)+1,2): G.box(n,Vector3(x,0.55,0),Vector3(0.075,1.1,0.075),"566b70")
	for y in [0.35,0.9]: G.box(n,Vector3(0,y,0),Vector3(length_v,0.05,0.06),"748287")
	var b = StaticBody3D.new()
	n.add_child(b)
	var c = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(length_v,1.6,0.2)
	c.shape = shape
	c.position.y = 0.8
	b.add_child(c)
func garden() -> void:
	floor_at(Vector3(-13,-0.25,17),Vector3(11,0.5,15),"859582")
	G.cylinder(self,Vector3(-15,-3,18),8,6,"6c7f7b",6)
	for x in [-17,-10]: G.tree(self,Vector3(x,0,18),rng)
	floor_at(Vector3(-15,0,29),Vector3(9,0.4,9),"8f9387")
	for x in [-19.5,-10.5]: floor_at(Vector3(x,1.7,29),Vector3(0.2,3.4,9),"89968b")
	floor_at(Vector3(-15,1.7,33.5),Vector3(9,3.4,0.2),"89968b")
	G.box(self,Vector3(-15,3.5,29),Vector3(10,0.2,10),"4d656b",true)
	G.text(self,"MAINTENANCE / 03",Vector3(-15,2.8,24.35),28).rotation.y = PI
	G.box(self,Vector3(-17,0.6,31),Vector3(3,1.2,1),"746d5f",true)
	G.text(self,"RESERVE CELL",Vector3(-17,1.6,30.4),17).rotation.y = PI
	for x in [-18.5,-18,-17.5]: G.cylinder(self,Vector3(x,0.5,27),0.3,1,"667b7d")
	G.box(self,Vector3(-12,1,32.9),Vector3(1.8,1.8,0.4),"485e65",true)
	G.lamp(self,Vector3(-11,0,23))
	fence(Vector3(-19,0,18),13,true)
	for z in range(10,25,2): G.cylinder(self,Vector3(-13+sin(z)*0.4,0.06,z),0.7,0.12,"b0af98")
func overlook() -> void:
	floor_at(Vector3(0,-0.2,-30),Vector3(7,0.4,17),"9a9e8f")
	for x in [-3.3,3.3]: fence(Vector3(x,0,-30),17,true)
	floor_at(Vector3(0,-0.35,-44),Vector3(17,0.7,13),"8b9a8d")
	G.cylinder(self,Vector3(0,-5,-44),10,9,"657c7d",8)
	G.cylinder(self,Vector3(0,-12,-44),2,6,"536d77",8)
	for x in [-8,8]: fence(Vector3(x,0,-44),12,true)
	fence(Vector3(0,0,-50),16,false)
	G.tree(self,Vector3(-5,0,-46),rng)
	G.bench(self,Vector3(-4,0,-42),PI)
	G.lamp(self,Vector3(5.5,0,-46),4)
	gate = Node3D.new()
	add_child(gate)
	gate.position = Vector3(0,0,-24)
	G.box(gate,Vector3(0,1.1,0),Vector3(6.7,2.2,0.18),"536b6e",true)
	G.text(gate,"SIGNAL WALK\nPOWER REQUIRED",Vector3(0,1.2,0.13),27)
	G.cylinder(self,Vector3(4,2,-46),0.13,4,"405967")
	G.box(self,Vector3(4,4,-46),Vector3(0.8,1.5,0.5),"2f4653")
	signal_light = G.sphere(self,Vector3(4,4.1,-45.72),Vector3(0.46,0.46,0.12),"ba765f",0.4)
	G.box(self,Vector3(2,0.8,-44),Vector3(1.2,1.6,0.9),"4b646b",true)
	G.text(self,"LINE MEMORY",Vector3(2,1.9,-43.5),21)
func horizon() -> void:
	for i in range(22):
		var a = rng.randf_range(0,TAU)
		var dist = rng.randf_range(85,240)
		var p = Vector3(cos(a)*dist,rng.randf_range(-35,30),sin(a)*dist)
		var r = rng.randf_range(8,20)
		G.cylinder(self,p,r*0.3,20,"6b858a",r)
		G.cylinder(self,p+Vector3(0,10,0),r,0.8,"839887")
		for j in range(rng.randi_range(3,7)):
			var h = rng.randf_range(5,22)
			var bpos = p+Vector3(rng.randf_range(-r*0.6,r*0.6),10+h/2,rng.randf_range(-r*0.6,r*0.6))
			var width = rng.randf_range(2.5,4.5)
			G.box(self,bpos,Vector3(width,h,width),["6c8388","84948b","627e88"][j%3])
			G.box(self,bpos+Vector3(0,h/2+0.15,0),Vector3(width+0.3,0.3,width+0.3),"526e7a")
			for y in range(2,int(h)-1,3): G.box(self,Vector3(bpos.x-0.3,10+p.y+y,bpos.z+width/2+0.015),Vector3(width*0.45,0.8,0.04),"b3c5ba")
	for z in range(-180,-70,14):
		G.box(self,Vector3(10,-1,z),Vector3(5,1,10),"7c8e91")
		G.cylinder(self,Vector3(10,-12,z),0.8,23,"819397")
	for i in range(25): G.sphere(self,Vector3(rng.randf_range(-230,230),rng.randf_range(-36,-20),rng.randf_range(-230,230)),Vector3(rng.randf_range(30,65),rng.randf_range(3,9),rng.randf_range(20,55)),"a9b4b3")
func make_train() -> void:
	train = Node3D.new()
	add_child(train)
	train.position = Vector3(10,0,-110)
	for z in [0,13]:
		G.box(train,Vector3(0,1.5,z),Vector3(3.2,3,11.8),"8eaaa5")
		G.box(train,Vector3(0,0.65,z),Vector3(3.25,0.3,11.8),"ad7c59")
		G.box(train,Vector3(0,3.05,z),Vector3(3.05,0.3,11.8),"49636c")
		for w in [-4,-2,0,2,4]:
			for x in [-1.62,1.62]: G.box(train,Vector3(x,2,z+w),Vector3(0.025,1,1.35),"d6c296",false,0.4)
		for x in [-1.3,1.3]:
			for wz in [-3.8,3.8]: G.cylinder(train,Vector3(x,0.15,z+wz),0.5,0.22,"293c49").rotation.z = PI/2
	G.box(train,Vector3(0,2,-5.93),Vector3(2.6,1.1,0.05),"b6c3b1",false,0.2)
	for x in [-1,1]: G.sphere(train,Vector3(x,0.9,-6),Vector3(0.35,0.35,0.1),"ead8a6",0.5)
	G.text(train,"00 / THE SEA ABOVE",Vector3(0,2.9,-6.03),15).rotation.y = PI
	train.visible = false
func vegetation() -> void:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for x in [-0.1,0,0.1]:
		st.set_normal(Vector3.FORWARD)
		st.add_vertex(Vector3(x-0.05,0,0))
		st.add_vertex(Vector3(x+0.04,0.48+x,0.03))
		st.add_vertex(Vector3(x+0.05,0,0))
	var blade = st.commit()
	var mm = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = blade
	mm.instance_count = 800
	for i in range(800):
		var p = Vector3(rng.randf_range(-18,-9),0.1,rng.randf_range(10,24)) if i<500 else Vector3(rng.randf_range(-7,7),0.02,rng.randf_range(-49,-39))
		mm.set_instance_transform(i,Transform3D(Basis(Vector3.UP,rng.randf_range(0,TAU)).scaled(Vector3.ONE*rng.randf_range(0.6,1.2)),p))
	var n = MultiMeshInstance3D.new()
	n.multimesh = mm
	n.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var shader = Shader.new()
	shader.code = "shader_type spatial;render_mode cull_disabled;void vertex(){VERTEX.x+=sin(TIME*1.7+MODEL_MATRIX[3].x*1.8+MODEL_MATRIX[3].z)*VERTEX.y*0.18;}void fragment(){ALBEDO=vec3(0.32,0.44,0.35);ROUGHNESS=1.0;}"
	var m = ShaderMaterial.new()
	m.shader = shader
	n.material_override = m
	add_child(n)
	var pm = MultiMesh.new()
	pm.transform_format = MultiMesh.TRANSFORM_3D
	var leaf = QuadMesh.new()
	leaf.size = Vector2(0.055,0.09)
	pm.mesh = leaf
	pm.instance_count = 80
	for i in range(80): pm.set_instance_transform(i,Transform3D(Basis(Vector3.UP,rng.randf_range(0,TAU)),Vector3(rng.randf_range(-18,8),rng.randf_range(0.5,5),rng.randf_range(-45,30))))
	var pn = MultiMeshInstance3D.new()
	pn.multimesh = pm
	var ps = Shader.new()
	ps.code = "shader_type spatial;render_mode cull_disabled,unshaded;void vertex(){VERTEX.x+=sin(TIME*0.45+MODEL_MATRIX[3].z)*0.8;VERTEX.y+=sin(TIME*0.8+MODEL_MATRIX[3].x)*0.6;VERTEX.z+=sin(TIME*0.3)*1.5;}void fragment(){ALBEDO=vec3(0.8,0.65,0.44);}"
	var pmat = ShaderMaterial.new()
	pmat.shader = ps
	pn.material_override = pmat
	add_child(pn)
func details() -> void:
	for i in range(40):
		var tile = G.box(self,Vector3(rng.randf_range(-6,5),0.008,rng.randf_range(-19,18)),Vector3(rng.randf_range(0.25,0.7),0.018,rng.randf_range(0.3,0.8)),["7e8c87","9ba39a","8d9b91"][i%3])
		tile.rotation.y = rng.randf_range(-0.1,0.1)
	for z in [-16,-5,8,17]:
		G.box(self,Vector3(6.7,0.035,z),Vector3(0.55,0.045,1.2),"445961")
		for dz in range(7): G.box(self,Vector3(6.7,0.06,z-0.5+dz*0.16),Vector3(0.48,0.02,0.025),"81918f")
	for p in [Vector3(-7,0,5),Vector3(-7,0,-5),Vector3(-16,0,10),Vector3(-10,0,12)]:
		G.cylinder(self,p+Vector3(0,0.25,0),0.28,0.5,"9b795d",0.35)
		for j in range(7):
			var o = Vector3(rng.randf_range(-0.2,0.2),rng.randf_range(0.65,0.9),rng.randf_range(-0.2,0.2))
			G.cylinder(self,p+o-Vector3(0,0.14,0),0.015,0.3,"637b66")
			G.sphere(self,p+o,Vector3(0.14,0.09,0.14),"cfb47e")
	for z in [-10,3,12]:
		G.cylinder(self,Vector3(1,4.2,z),0.025,0.6,"3b4d55")
		G.sphere(self,Vector3(1,3.8,z),Vector3(0.55,0.65,0.55),"b7ab89")
	for x in [-6,5]:
		for z in range(-20,16): G.box(self,Vector3(x,4.15+sin(z*0.35)*0.12,z),Vector3(0.025,0.025,1.02),"374e57")
func point(id: String, title: String, pos: Vector3, memory: bool = false) -> void:
	var gem = G.sphere(self,pos,Vector3(0.16,0.28,0.16),"89c4c6" if memory else "cbb58a",0.45)
	points.append({"id":id,"title":title,"pos":pos,"gem":gem})
func set_power(value: bool) -> void:
	gate.position.y = -3.5 if value else 0
func _process(dt: float) -> void:
	for p in points:
		p.gem.position.y = p.pos.y+sin(Time.get_ticks_msec()*0.0018+p.pos.x)*0.12
		p.gem.rotation.y += dt
