class_name Traveler
extends CharacterBody3D
const MODEL = preload("res://art/character/schoolgirl.gltf")
const FUTABA_ASSET = "res://art/character/futaba_animated.glb"
const FUTABA_MOTION = preload("res://scripts/futaba_motion.gd")
var rig: Node3D
var futaba_motion: Node = null
var limbs: Array[Node3D] = []
var eyes: Array[Node3D] = []
var knees: Array[Node3D] = []
var elbows: Array[Node3D] = []
var hair: Node3D
var skirt: Node3D
var ribbon: Node3D
var head: Node3D
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
var jump_requested = false
var jump_buffer = 0.0
var coyote_time = 0.0
const JUMP_BUFFER_SECONDS = 0.16
const COYOTE_SECONDS = 0.10
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
	# The original avatar remains playable whenever the user's private VRM
	# has not been prepared locally. Never commit Futaba's model to this repo.
	var use_futaba := false
	if ResourceLoader.exists(FUTABA_ASSET):
		var candidate_scene = load(FUTABA_ASSET) as PackedScene
		if candidate_scene != null:
			var candidate = candidate_scene.instantiate() as Node3D
			if candidate != null and candidate.find_child("AnimationPlayer", true, false) != null:
				rig = candidate
				use_futaba = true
			elif candidate != null:
				candidate.free()
	if not use_futaba:
		rig = MODEL.instantiate()
	add_child(rig)
	if use_futaba:
		var controller = FUTABA_MOTION.new()
		rig.add_child(controller)
		if controller.configure(rig):
			futaba_motion = controller
		else:
			# Fall back cleanly if the imported model lacks any needed clips.
			rig.remove_child(controller)
			controller.free()
			remove_child(rig)
			rig.queue_free()
			rig = MODEL.instantiate()
			add_child(rig)
	if futaba_motion == null:
		for part in ["LeftArm", "RightArm", "LeftLeg", "RightLeg"]:
			limbs.append(rig.find_child(part, true, false))
		for side in ["Left", "Right"]:
			knees.append(rig.find_child(side+"Knee", true, false))
			elbows.append(rig.find_child(side+"Elbow", true, false))
			eyes.append(rig.find_child(side+"Eye", true, false))
		hair = rig.find_child("Hair", true, false)
		skirt = rig.find_child("Skirt", true, false)
		ribbon = rig.find_child("Ribbon", true, false)
		head = rig.find_child("Head", true, false)
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
	# Share one shader across imported material surfaces, preserving the palette.
	var shader = preload("res://art/character/traveler.gdshader")
	var materials: Dictionary = {}
	for mesh_node in n.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance = mesh_node as MeshInstance3D
		mesh_instance.mesh = mesh_instance.mesh.duplicate()
		for surface_index in range(mesh_instance.mesh.get_surface_count()):
			var base = mesh_instance.mesh.surface_get_material(surface_index) as StandardMaterial3D
			if not base: continue
			var key = base.albedo_color.to_html()
			if not materials.has(key):
				var material = ShaderMaterial.new()
				material.shader = shader
				material.set_shader_parameter("ink", base.albedo_color)
				materials[key] = material
			mesh_instance.mesh.surface_set_material(surface_index, materials[key])
func look(delta: Vector2) -> void:
	yaw -= delta.x*0.005
	pitch = clampf(pitch-delta.y*0.004,-0.85,0.4)
func movement_speed(stick_strength: float) -> float:
	# Gentle tilt for walking, full tilt to run. Keyboard still uses Shift.
	return lerpf(3.0,5.2,smoothstep(0.60,1.0,clampf(stick_strength,0.0,1.0)))
func _physics_process(dt: float) -> void:
	var input = move_input if enabled else Vector2.ZERO
	var using_keyboard = false
	if enabled:
		var keyboard = Input.get_vector("left","right","forward","back")
		if keyboard.length() > 0:
			input = keyboard
			using_keyboard = true
	var speed = 5.2 if Input.is_action_pressed("run") else movement_speed(0.0 if using_keyboard else input.length())
	var dir = Basis(Vector3.UP,yaw)*Vector3(input.x,0,input.y)
	velocity.x = move_toward(velocity.x,dir.x*speed,dt*13)
	velocity.z = move_toward(velocity.z,dir.z*speed,dt*13)
	if not is_on_floor(): velocity.y -= dt*20
	# Keep short taps until a physics tick and allow near-ledge/landing jumps.
	if enabled and (jump_requested or Input.is_action_just_pressed("jump")):
		jump_buffer = JUMP_BUFFER_SECONDS
	jump_requested = false
	if not enabled: jump_buffer = 0.0
	jump_buffer = maxf(0.0,jump_buffer-dt)
	coyote_time = COYOTE_SECONDS if is_on_floor() else maxf(0.0,coyote_time-dt)
	if enabled and jump_buffer > 0.0 and coyote_time > 0.0:
		velocity.y = 6.6
		jump_buffer = 0.0
		coyote_time = 0.0
	move_and_slide()
	var did_land = not was_floor and is_on_floor()
	if did_land: landed = 0.17
	was_floor = is_on_floor()
	landed = move_toward(landed,0,dt*0.8)
	var moving = Vector2(velocity.x,velocity.z).length()
	phase += dt*moving*2.5
	if moving > 0.15:
		rig.rotation.y = lerp_angle(rig.rotation.y,atan2(-velocity.x,-velocity.z),minf(dt*12,1))
	if futaba_motion != null:
		futaba_motion.update_motion(moving,is_on_floor(),velocity.y,did_land,dt)
	else:
		# Preserve the original character's procedural animation when Futaba's
		# locally prepared, textured GLB isn't available.
		var swing = sin(phase)*minf(moving*0.18,0.8) if is_on_floor() else 0.25
		var blend = 1.0-exp(-dt*12.0)
		for i in range(4):
			limbs[i].rotation.x = lerpf(limbs[i].rotation.x,swing*(-1 if i%2 == 0 else 1)*(-0.65 if i<2 else 1.0),blend)
		for i in range(2):
			var stride = sin(phase)*(-1.0 if i == 0 else 1.0)
			knees[i].rotation.x = lerpf(knees[i].rotation.x, maxf(0.0,-stride)*minf(moving*0.20,0.9) if is_on_floor() else 0.45,blend)
			elbows[i].rotation.x = lerpf(elbows[i].rotation.x,-0.12-minf(moving*0.07,0.35),blend)
			limbs[i].rotation.z = (-1.0 if i == 0 else 1.0)*0.08
		var clock = Time.get_ticks_msec()*0.001
		rig.position.y = absf(sin(phase))*minf(moving*0.009,0.035)-landed*0.22+sin(clock*2.0)*0.005
		rig.scale.y = 1-landed*0.18
		rig.rotation.x = lerpf(rig.rotation.x,-moving*0.012,1.0-exp(-dt*6.0))
		var blink_time = fmod(clock,4.7)
		var blink = 1.0-0.96*sin(clampf((blink_time-4.48)/0.22,0.0,1.0)*PI)
		for eye in eyes: eye.scale.y = blink*0.8
		hair.rotation.x = lerpf(hair.rotation.x,moving*0.018+sin(clock*2.2)*0.025,blend)
		hair.rotation.z = sin(phase*0.5)*minf(moving*0.006,0.025)
		skirt.rotation.x = lerpf(skirt.rotation.x,-moving*0.012,blend)
		skirt.scale.z = 1.0+minf(moving*0.035,0.18)
		ribbon.rotation.x = sin(clock*3.0)*0.06+moving*0.035
		head.rotation.z = sin(clock*1.3)*0.012
	pivot.rotation.y = lerp_angle(pivot.rotation.y,yaw,1-exp(-dt*18))
	pivot.rotation.x = lerpf(pivot.rotation.x,pitch,1-exp(-dt*18))
	if is_on_floor() and moving>0.5:
		foot_clock += dt*moving
		if foot_clock>1.45:
			foot_clock=0
			footstep.emit()
