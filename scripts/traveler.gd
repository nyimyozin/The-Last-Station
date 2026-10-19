class_name Traveler
extends CharacterBody3D
const G = preload("res://scripts/geometry.gd")
var rig: Node3D
var limbs: Array[Node3D] = []
var eyes: Array[MeshInstance3D] = []
var scarf: MeshInstance3D
var pivot: Node3D
var spring: SpringArm3D
var camera: Camera3D
var yaw = 0.0
var pitch = -0.2
var phase = 0.0
var foot_clock = 0.0
var landed = 0.0
var was_floor = false
var move_input = Vector2.ZERO
var enabled = false
var sprinting = false
var jump_requested = false
signal footstep
func _ready() -> void:
	var c = CollisionShape3D.new()
	var capsule = CapsuleShape3D.new()
	capsule.radius = 0.3
	capsule.height = 1.65
	c.shape = capsule
	c.position.y = 0.83
	add_child(c)
	floor_snap_length = 0.35
	rig = Node3D.new()
	add_child(rig)
	G.cylinder(rig,Vector3(0,0.94,0),0.39,0.72,"526c7b",0.25)
	G.cylinder(rig,Vector3(0,0.59,0),0.40,0.12,"314958",0.38)
	G.sphere(rig,Vector3(0,1.59,0),Vector3(0.72,0.74,0.64),"d9bc9d")
	G.sphere(rig,Vector3(0,1.76,0.055),Vector3(0.79,0.55,0.72),"354755")
	for x in [-0.3,0.3]: G.sphere(rig,Vector3(x,1.54,0.05),Vector3(0.22,0.57,0.52),"354755")
	for i in range(5):
		var bang = G.cylinder(rig,Vector3(-0.25+i*0.12,1.72,-0.295),0.085,0.31,"354755",0.02)
		bang.rotation.z = PI+(i-2)*0.12
	for x in [-0.145,0.145]:
		eyes.append(G.sphere(rig,Vector3(x,1.58,-0.295),Vector3(0.115,0.15,0.055),"eee5cd"))
		eyes.append(G.sphere(rig,Vector3(x,1.57,-0.323),Vector3(0.065,0.105,0.025),"678f92"))
		eyes.append(G.sphere(rig,Vector3(x,1.57,-0.337),Vector3(0.027,0.07,0.014),"233847"))
		eyes.append(G.sphere(rig,Vector3(x-0.012,1.6,-0.348),Vector3(0.023,0.026,0.01),"ffffff"))
	G.box(rig,Vector3(0,1.42,-0.308),Vector3(0.065,0.015,0.016),"a87976")
	G.cylinder(rig,Vector3(0,1.3,0),0.29,0.17,"c18b65")
	scarf = G.box(rig,Vector3(0.19,1.12,0.39),Vector3(0.2,0.62,0.06),"c18b65")
	for y in [0.82,1.02,1.19]: G.sphere(rig,Vector3(0,y,-0.29),Vector3(0.055,0.055,0.025),"d5c89c")
	G.box(rig,Vector3(0,0.99,0.32),Vector3(0.42,0.48,0.23),"826c57")
	G.box(rig,Vector3(0,1.16,0.45),Vector3(0.46,0.12,0.12),"ab9272")
	for i in range(4):
		var arm = i < 2
		var l = Node3D.new()
		rig.add_child(l)
		l.position = Vector3((-1 if i%2 == 0 else 1)*(0.32 if arm else 0.16),1.16 if arm else 0.61,0)
		G.cylinder(l,Vector3(0,-0.2,0),0.105,0.4,"526c7b" if arm else "394b59",0.13 if arm else 0.105)
		G.sphere(l,Vector3(0,-0.44 if arm else -0.48,0 if arm else -0.06),Vector3(0.17,0.2,0.17) if arm else Vector3(0.24,0.22,0.39),"d9bc9d" if arm else "443f41")
		limbs.append(l)
	apply_toon(rig)
	pivot = Node3D.new()
	add_child(pivot)
	pivot.position.y = 1.35
	spring = SpringArm3D.new()
	pivot.add_child(spring)
	spring.spring_length = 5.2
	spring.margin = 0.2
	var probe = SphereShape3D.new()
	probe.radius = 0.2
	spring.shape = probe
	spring.add_excluded_object(get_rid())
	camera = Camera3D.new()
	spring.add_child(camera)
	camera.fov = 61
	camera.far = 600
	camera.current = true
func apply_toon(n: Node) -> void:
	for ch in n.get_children():
		if ch is MeshInstance3D:
			var base = ch.material_override as StandardMaterial3D
			var s = Shader.new()
			s.code = "shader_type spatial; uniform vec4 ink:source_color; void fragment(){ALBEDO=ink.rgb;ROUGHNESS=1.0;} void light(){float band=dot(NORMAL,LIGHT)>0.35?0.9:0.25;DIFFUSE_LIGHT+=band*ATTENUATION*LIGHT_COLOR/3.14159265;}"
			var m = ShaderMaterial.new()
			m.shader = s
			m.set_shader_parameter("ink",base.albedo_color)
			ch.material_override = m
		apply_toon(ch)
func look(delta: Vector2) -> void:
	yaw -= delta.x*0.005
	pitch = clampf(pitch-delta.y*0.004,-0.85,0.4)
func _physics_process(dt: float) -> void:
	var input = move_input if enabled else Vector2.ZERO
	if enabled:
		var keyboard = Input.get_vector("left","right","forward","back")
		if keyboard.length() > 0: input = keyboard
	var speed = 5.2 if sprinting or Input.is_action_pressed("run") else 3.0
	var dir = Basis(Vector3.UP,yaw)*Vector3(input.x,0,input.y)
	velocity.x = move_toward(velocity.x,dir.x*speed,dt*13)
	velocity.z = move_toward(velocity.z,dir.z*speed,dt*13)
	if not is_on_floor(): velocity.y -= dt*20
	if enabled and is_on_floor() and (jump_requested or Input.is_action_just_pressed("jump")): velocity.y = 6.6
	jump_requested = false
	move_and_slide()
	if not was_floor and is_on_floor(): landed = 0.17
	was_floor = is_on_floor()
	landed = move_toward(landed,0,dt*0.8)
	var moving = Vector2(velocity.x,velocity.z).length()
	phase += dt*moving*2.5
	if moving > 0.15: rig.rotation.y = lerp_angle(rig.rotation.y,atan2(-velocity.x,-velocity.z),minf(dt*12,1))
	var swing = sin(phase)*minf(moving*0.18,0.8) if is_on_floor() else 0.25
	for i in range(4): limbs[i].rotation.x = lerpf(limbs[i].rotation.x,swing*(-1 if i%2 == 0 else 1)*(-0.75 if i<2 else 1.0),dt*12)
	rig.position.y = absf(sin(phase))*minf(moving*0.015,0.065)-landed*0.3+sin(Time.get_ticks_msec()*0.002)*0.008
	rig.scale.y = 1-landed*0.35
	rig.rotation.x = lerpf(rig.rotation.x,-moving*0.015,dt*6)
	for eye in eyes: eye.visible = fmod(Time.get_ticks_msec()*0.001,4.7)<4.56
	scarf.rotation.x = -0.35-moving*0.12+sin(Time.get_ticks_msec()*0.004)*0.12
	pivot.rotation.y = lerp_angle(pivot.rotation.y,yaw,1-exp(-dt*18))
	pivot.rotation.x = lerpf(pivot.rotation.x,pitch,1-exp(-dt*18))
	if is_on_floor() and moving>0.5:
		foot_clock += dt*moving
		if foot_clock>1.45:
			foot_clock=0
			footstep.emit()
