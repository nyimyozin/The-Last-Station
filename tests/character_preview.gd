# Reproducible rendered QA: godot --path . --script tests/character_preview.gd
extends SceneTree
func _initialize() -> void:
	call_deferred("capture")
func capture() -> void:
	root.size = Vector2i(960,960)
	root.content_scale_size = Vector2i(960,960)
	root.msaa_3d = Viewport.MSAA_2X
	var stage = Node3D.new()
	root.add_child(stage)
	var environment = WorldEnvironment.new()
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("798b91")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("d8e1e6")
	env.ambient_light_energy = 0.65
	environment.environment = env
	stage.add_child(environment)
	var sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-30,-35,0)
	sun.light_energy = 0.8
	stage.add_child(sun)
	var traveler = load("res://scripts/traveler.gd").new()
	stage.add_child(traveler)
	traveler.set_physics_process(false)
	var camera = Camera3D.new()
	stage.add_child(camera)
	camera.current = true
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 2.02
	for view in ["front","three-quarter","back","stride"]:
		traveler.rig.rotation.y = 0
		if view == "three-quarter": traveler.rig.rotation.y = -0.55
		if view == "back": traveler.rig.rotation.y = PI
		if view == "stride":
			traveler.rig.rotation.y = -0.8
			traveler.limbs[2].rotation.x = -0.7
			traveler.limbs[3].rotation.x = 0.7
			traveler.knees[0].rotation.x = 0.7
			traveler.limbs[0].rotation.x = 0.45
			traveler.limbs[1].rotation.x = -0.45
			traveler.elbows[0].rotation.x = -0.4
			traveler.elbows[1].rotation.x = -0.4
			traveler.skirt.scale.z = 1.18
		camera.position = Vector3(0,1.05,-4)
		camera.look_at(Vector3(0,.86,0))
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/character-"+view+".png")
	print("CHARACTER CAPTURE PASS")
	quit()
