# Controls imported VRM humanoid clips through a Godot AnimationTree.
# Texture-bearing mesh surfaces are left unchanged.
extends Node

const CLIPS: Array[String] = ["idle", "walk", "run", "jump", "fall", "land"]
var player: AnimationPlayer
var tree: AnimationTree
var playback: AnimationNodeStateMachinePlayback
var state: String = ""
var land_remaining: float = 0.0
var configured: bool = false

func configure(character: Node3D) -> bool:
	player = character.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if player == null:
		push_warning("Futaba model has no AnimationPlayer; using original character instead")
		return false
	var imported = player.get_animation_list()
	for clip in CLIPS:
		if not imported.has(StringName(clip)):
			push_warning("Missing Futaba animation clip: " + clip)
			return false
	for clip in ["idle", "walk", "run"]:
		player.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
	# The AnimationTree and imported AnimationPlayer have the same root.
	tree = AnimationTree.new()
	player.get_parent().add_child(tree)
	tree.anim_player = tree.get_path_to(player)
	var machine = AnimationNodeStateMachine.new()
	for i in range(CLIPS.size()):
		var motion = AnimationNodeAnimation.new()
		motion.animation = StringName(CLIPS[i])
		machine.add_node(CLIPS[i], motion, Vector2(i * 180.0, 100))
	for src in CLIPS:
		for dst in CLIPS:
			if src == dst:
				continue
			var transition = AnimationNodeStateMachineTransition.new()
			transition.xfade_time = 0.17 if dst != "land" else 0.10
			transition.switch_mode = AnimationNodeStateMachineTransition.SWITCH_MODE_IMMEDIATE
			machine.add_transition(src, dst, transition)
	tree.tree_root = machine
	tree.active = true
	playback = tree.get("parameters/playback") as AnimationNodeStateMachinePlayback
	if playback == null:
		return false
	playback.start("idle")
	state = "idle"
	configured = true
	return true

func update_motion(speed: float, grounded: bool, vertical_speed: float, just_landed: bool, dt: float) -> void:
	if not configured:
		return
	if just_landed:
		land_remaining = 0.30
	land_remaining = maxf(0.0, land_remaining - dt)
	var desired = "idle"
	if not grounded:
		desired = "jump" if vertical_speed > 0.35 else "fall"
	elif land_remaining > 0.0:
		desired = "land"
	elif speed > 4.0:
		desired = "run"
	elif speed > 0.15:
		desired = "walk"
	if desired != state:
		playback.travel(desired)
		state = desired
