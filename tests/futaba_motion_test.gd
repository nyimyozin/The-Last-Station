# Automated test for the skeletal animation controller without redistributing
# Futaba-chan's copyrighted avatar. Run: godot --headless --path . --script tests/futaba_motion_test.gd
extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var root_node := Node3D.new()
	root.add_child(root_node)
	var player := AnimationPlayer.new()
	player.name = "AnimationPlayer"
	root_node.add_child(player)
	var library := AnimationLibrary.new()
	for clip in ["idle", "walk", "run", "jump", "fall", "land"]:
		var animation := Animation.new()
		animation.length = 0.6
		library.add_animation(clip, animation)
	player.add_animation_library("", library)
	var controller = load("res://scripts/futaba_motion.gd").new()
	root_node.add_child(controller)
	if not controller.configure(root_node):
		push_error("FUTABA MOTION FAIL: could not configure six-clip player")
		quit(1)
		return
	for sample in [[0.0, true, 0.0, false, "idle"], [2.5, true, 0.0, false, "walk"],
		[5.0, true, 0.0, false, "run"], [1.0, false, 5.0, false, "jump"],
		[1.0, false, -2.0, false, "fall"], [0.5, true, 0.0, true, "land"]]:
		controller.update_motion(sample[0], sample[1], sample[2], sample[3], 0.016)
		if controller.state != sample[4]:
			push_error("FUTABA MOTION FAIL: expected " + sample[4] + " got " + controller.state)
			quit(1)
			return
	print("FUTABA MOTION PASS")
	quit()
