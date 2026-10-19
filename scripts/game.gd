extends Node3D
const WORLD = preload("res://scripts/world.gd")
const PLAYER = preload("res://scripts/traveler.gd")
const STICK = preload("res://scripts/stick.gd")
const JUMP_BUTTON = preload("res://scripts/jump_button.gd")
const G = preload("res://scripts/geometry.gd")
const MEMORIES = {
"m1":["01 / THE PROMISE","A little hand closes around yours.\n\n“When the lights go out, wait for me at Platform Zero.”\n\nYou cannot remember who said it. You remember believing them."],
"m2":["02 / THE DEPARTURE","The city did not fall. It rose.\n\nRoofs, rivers, the road to your house — lifted into the clouds. The last evacuation train had room for everyone.\n\nSomeone stayed to keep the signal lit."],
"m3":["03 / THE LAST LIGHT","You were the one who stayed.\n\nNot because you were brave. Because a child had gone back for a yellow scarf.\n\nYou remember a hand finding yours in the dark. Then the rails became stars."],
"m4":["04 / A SMALL KINDNESS","A vending machine. Two warm cans. One left unopened.\n\nThe stationmaster always bought an extra, in case somebody arrived cold.\n\nEven at the end of the world, there were small things worth doing."]}
const INITIAL = {"cell":false,"power":false,"signal":false,"revealed":false,"ended":false,"memories":[],"read":[]}
var state: Dictionary = INITIAL.duplicate(true)
var settings = {"quality":1,"music":0.65,"sound":0.8,"sensitivity":1.0}
var world: StationWorld
var player: Traveler
var menu_camera: Camera3D
var cinema: Camera3D
var hud: Control
var overlay: Control
var panel: VBoxContainer
var stick: VirtualStick
var jump_button: JumpTouchButton
var objective_label: Label
var area_label: Label
var prompt: Button
var toast_label: Label
var fade: ColorRect
var sounds: Dictionary = {}
var mode = "menu"
var started = false
var nearest = ""
var finger = -1
var timer = 0.0
var toast_time = 0.0
var dials: Array[int] = [0,0,0]
var tones: Array[int] = []
var train_arriving = false
var train_ready = false
var train_time = 0.0
var test_mode = false
var save_path = "user://platform_zero.json"
var relay_error: Label
func _ready() -> void:
	test_mode = "--smoke-test" in OS.get_cmdline_user_args()
	if test_mode: save_path = "user://smoke_test_save.json"
	elif "--capture" in OS.get_cmdline_user_args(): save_path = "user://capture_save.json"
	configure_input()
	var cfg = ConfigFile.new()
	if cfg.load("user://settings.cfg") == OK:
		for key in settings: settings[key] = cfg.get_value("settings",key,settings[key])
	world = WORLD.new()
	add_child(world)
	player = PLAYER.new()
	add_child(player)
	player.position = Vector3(0,0.2,11)
	player.footstep.connect(footstep)
	menu_camera = Camera3D.new()
	add_child(menu_camera)
	menu_camera.position = Vector3(21,9,25)
	menu_camera.look_at(Vector3(-1,1,-3))
	cinema = Camera3D.new()
	add_child(cinema)
	setup_audio()
	build_ui()
	apply_settings()
	main_menu()
	if test_mode: call_deferred("smoke_tests")
	if "--capture" in OS.get_cmdline_user_args(): call_deferred("capture_views")
func configure_input() -> void:
	var map = {"left":[KEY_A,KEY_LEFT],"right":[KEY_D,KEY_RIGHT],"forward":[KEY_W,KEY_UP],"back":[KEY_S,KEY_DOWN],"jump":[KEY_SPACE],"run":[KEY_SHIFT],"interact":[KEY_E],"journal":[KEY_J],"pause":[KEY_ESCAPE]}
	for action in map:
		if not InputMap.has_action(action): InputMap.add_action(action)
		for key in map[action]:
			var e = InputEventKey.new()
			e.physical_keycode = key
			InputMap.action_add_event(action,e)
func setup_audio() -> void:
	for bus in ["Music","World"]:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count-1,bus)
	for name in ["music","wind","train","effect","foot"]:
		var p = AudioStreamPlayer.new()
		p.bus = "Music" if name == "music" else "World"
		add_child(p)
		sounds[name] = p
	for name in ["music","wind"]:
		sounds[name].stream = load("res://audio/"+name+".wav")
		sounds[name].play()
func sfx(name: String, channel: String = "effect") -> void:
	sounds[channel].stream = load("res://audio/"+name+".wav")
	sounds[channel].play()
func footstep() -> void:
	sounds.foot.volume_db = -12
	sounds.foot.pitch_scale = randf_range(0.9,1.12)
	sfx("grass" if player.position.x < -8 and player.position.z > 8 else "stone","foot")
func box_style(bg: Color, border: Color = Color(0.8,0.8,0.65,0.25)) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(1)
	s.set_corner_radius_all(8)
	s.content_margin_left = 20
	s.content_margin_right = 20
	s.content_margin_top = 12
	s.content_margin_bottom = 12
	return s
func button(value: String, callback: Callable, parent: Node, width: float = 0) -> Button:
	var b = Button.new()
	b.text = value
	b.custom_minimum_size = Vector2(width,52)
	b.add_theme_font_size_override("font_size",19)
	b.add_theme_color_override("font_color",Color("eee4cd"))
	b.add_theme_stylebox_override("normal",box_style(Color(0.09,0.17,0.21,0.9)))
	b.add_theme_stylebox_override("hover",box_style(Color(0.24,0.35,0.38,0.95)))
	b.add_theme_stylebox_override("pressed",box_style(Color("586c6a"),Color("e0c393")))
	b.add_theme_stylebox_override("focus",box_style(Color(0,0,0,0),Color("dbc293")))
	b.pressed.connect(callback)
	parent.add_child(b)
	return b
func label(value: String, size_v: int, parent: Node, color: String = "eee4cd") -> Label:
	var l = Label.new()
	l.text = value
	l.add_theme_font_size_override("font_size",size_v)
	l.add_theme_color_override("font_color",Color(color))
	l.add_theme_color_override("font_shadow_color",Color(0.03,0.07,0.09,0.65))
	l.add_theme_constant_override("shadow_offset_y",1)
	parent.add_child(l)
	return l
func anchor(c: Control, rect: Vector4, offsets: Vector4) -> void:
	c.anchor_left = rect.x
	c.anchor_top = rect.y
	c.anchor_right = rect.z
	c.anchor_bottom = rect.w
	c.offset_left = offsets.x
	c.offset_top = offsets.y
	c.offset_right = offsets.z
	c.offset_bottom = offsets.w
func build_ui() -> void:
	var canvas = CanvasLayer.new()
	add_child(canvas)
	var root = Control.new()
	canvas.add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var theme_v = Theme.new()
	theme_v.default_font = load("res://art/Interface.ttf")
	root.theme = theme_v
	hud = Control.new()
	root.add_child(hud)
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	area_label = label("PLATFORM ZERO",15,hud,"d7bc8e")
	anchor(area_label,Vector4.ZERO,Vector4(32,23,570,48))
	objective_label = label("",19,hud)
	anchor(objective_label,Vector4(0,0,0.65,0),Vector4(32,49,0,110))
	objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	anchor(button("Ⅱ",pause_menu,hud,58),Vector4(1,0,1,0),Vector4(-90,24,-30,78))
	anchor(button("Journal",journal,hud,110),Vector4(1,0,1,0),Vector4(-218,24,-100,78))
	stick = STICK.new()
	hud.add_child(stick)
	anchor(stick,Vector4(0,1,0,1),Vector4(28,-216,208,-36))
	jump_button = JUMP_BUTTON.new()
	hud.add_child(jump_button)
	anchor(jump_button,Vector4(1,1,1,1),Vector4(-160,-177,-30,-47))
	jump_button.connect("jump_pressed",request_touch_jump)
	prompt = button("",interact_nearest,hud,240)
	prompt.add_theme_font_size_override("font_size",17)
	anchor(prompt,Vector4(0.5,1,0.5,1),Vector4(-220,-102,220,-42))
	toast_label = label("",18,hud)
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	anchor(toast_label,Vector4(0.2,0.2,0.8,0.2),Vector4(0,0,0,80))
	overlay = Control.new()
	root.add_child(overlay)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade = ColorRect.new()
	root.add_child(fade)
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade.color = Color(0.035,0.065,0.09,0)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
func request_touch_jump() -> void:
	if mode == "play": player.jump_requested = true
func clear_overlay() -> void:
	for child in overlay.get_children():
		overlay.remove_child(child)
		child.queue_free()
	overlay.visible = true
func modal(title: String, body: String = "") -> void:
	clear_overlay()
	player.enabled = false
	stick.input_enabled = false
	jump_button.input_enabled = false
	stick.reset()
	jump_button.reset()
	player.jump_requested = false
	finger = -1
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var veil = ColorRect.new()
	veil.color = Color(0.035,0.07,0.1,0.75)
	overlay.add_child(veil)
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center = CenterContainer.new()
	overlay.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var frame = PanelContainer.new()
	frame.custom_minimum_size = Vector2(650,0)
	frame.add_theme_stylebox_override("panel",box_style(Color(0.065,0.12,0.16,0.96)))
	center.add_child(frame)
	frame.modulate.a = 0
	create_tween().tween_property(frame,"modulate:a",1,0.18)
	panel = VBoxContainer.new()
	panel.add_theme_constant_override("separation",14)
	frame.add_child(panel)
	label(title,30,panel)
	if body != "":
		var l = label(body,18,panel,"bcc7bd")
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size.x = 610
func main_menu() -> void:
	mode = "menu"
	player.enabled = false
	stick.input_enabled = false
	jump_button.input_enabled = false
	stick.reset()
	jump_button.reset()
	hud.visible = false
	menu_camera.current = true
	clear_overlay()
	var shade = ColorRect.new()
	shade.color = Color(0.04,0.09,0.13,0.45)
	overlay.add_child(shade)
	anchor(shade,Vector4(0,0,0.52,1),Vector4.ZERO)
	var column = VBoxContainer.new()
	overlay.add_child(column)
	anchor(column,Vector4(0.055,0.16,0.45,0.9),Vector4.ZERO)
	column.add_theme_constant_override("separation",15)
	label("A PLACE FOR THOSE STILL COMING",14,column,"dfc595")
	label("THE LAST\nSTATION",52,column)
	label("C H A P T E R   0  /  P L A T F O R M   Z E R O",13,column,"bac8c4")
	var space = Control.new()
	space.custom_minimum_size.y = 12
	column.add_child(space)
	button("New journey",confirm_new,column,320)
	button("Continue",continue_game,column).disabled = not FileAccess.file_exists(save_path)
	button("Settings",func(): settings_menu("menu"),column)
	button("Exit",quit_game,column)
	label("An original little story about keeping a light on.",14,column,"aebfbc")
func confirm_new() -> void:
	if FileAccess.file_exists(save_path):
		modal("Begin again?","This replaces the saved progress for this chapter.")
		button("Begin a new journey",new_game,panel)
		button("Back",main_menu,panel)
	else: new_game()
func new_game() -> void:
	state = INITIAL.duplicate(true)
	dials = [0,0,0]
	train_ready = false
	train_arriving = false
	world.train.visible = false
	world.set_power(false)
	world.signal_light.material_override = G.material("ba765f",0.4)
	player.visible = true
	player.position = Vector3(0,0.2,11)
	player.velocity = Vector3.ZERO
	player.yaw = 0
	player.pitch = -0.2
	started = true
	player.camera.current = true
	mode = "dialogue"
	hud.visible = false
	modal("00 / PLATFORM ZERO","You wake to a station announcement.\n\nThere is no voice. Only the click before it.\n\nA ticket rests beside you. Beyond the roof, the clouds are below the rails.")
	button("Open your eyes",func(): resume_game(); toast("Left stick: move · push fully to run\nDrag right side to look · tap JUMP with your other thumb\nExamine the glowing ticket.",10); save_game(),panel)
func resume_game() -> void:
	mode = "play"
	stick.reset()
	jump_button.reset()
	stick.input_enabled = true
	jump_button.input_enabled = true
	overlay.visible = false
	for child in overlay.get_children(): child.queue_free()
	hud.visible = true
	player.enabled = true
	player.camera.current = true
	objective_label.text = objective()
func pause_menu() -> void:
	if not started: return
	mode = "pause"
	modal("A moment between stations","Your journey is saved automatically as you discover things.")
	button("Return to the platform",resume_game,panel)
	button("Journal & memories",journal,panel)
	button("Settings",func(): settings_menu("pause"),panel)
	button("Save & title screen",func(): save_game(); main_menu(),panel)
func settings_menu(back: String) -> void:
	mode = "settings"
	modal("Make yourself comfortable","Landscape touch controls · headphones recommended")
	var quality = OptionButton.new()
	quality.custom_minimum_size.y = 50
	for item in ["Low · 30 FPS / no shadows","Balanced · 60 FPS / shadows","High · 60 FPS / 2× antialiasing"]: quality.add_item(item)
	quality.selected = int(settings.quality)
	quality.item_selected.connect(func(i): settings.quality=i; apply_settings(); save_settings())
	panel.add_child(quality)
	for item in [["Music","music",0.0,1.0],["World sounds","sound",0.0,1.0],["Camera sensitivity","sensitivity",0.4,1.8]]:
		label(item[0],16,panel)
		var slider = HSlider.new()
		slider.min_value = item[2]
		slider.max_value = item[3]
		slider.step = 0.05
		slider.value = settings[item[1]]
		slider.custom_minimum_size.y = 32
		var key: String = item[1]
		slider.value_changed.connect(func(v): settings[key]=v; apply_settings(); save_settings())
		panel.add_child(slider)
	button("Credits & licenses",func(): credits(back),panel)
	button("Back",main_menu if back == "menu" else pause_menu,panel)
func apply_settings() -> void:
	Engine.max_fps = 30 if int(settings.quality)==0 else 60
	world.sun.shadow_enabled = int(settings.quality)>0
	get_viewport().msaa_3d = Viewport.MSAA_2X if int(settings.quality)==2 else Viewport.MSAA_DISABLED
	get_viewport().scaling_3d_scale = 0.75 if int(settings.quality)==0 else 1.0
	for entry in [["Music","music"],["World","sound"]]:
		var index = AudioServer.get_bus_index(entry[0])
		var volume: float = settings[entry[1]]
		AudioServer.set_bus_volume_db(index,linear_to_db(maxf(volume,0.001)))
		AudioServer.set_bus_mute(index,volume == 0)
func save_settings() -> void:
	var c = ConfigFile.new()
	for key in settings: c.set_value("settings",key,settings[key])
	c.save("user://settings.cfg")
func credits(back: String) -> void:
	modal("A small light in the dark","Original story, geometry, shaders and synthesized music.\nMade for Nick · Godot 4.5.1 · Font: DejaVu Sans")
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(610,280)
	panel.add_child(scroll)
	var l = Label.new()
	l.custom_minimum_size.x = 580
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size",13)
	for file in ["res://LICENSE","res://licenses/DejaVu.txt","res://licenses/Godot-LICENSE.txt","res://licenses/Godot-COPYRIGHT.txt"]:
		if FileAccess.file_exists(file): l.text += FileAccess.get_file_as_string(file)+"\n\n"
	scroll.add_child(l)
	button("Back",func(): settings_menu(back),panel)
func journal() -> void:
	mode = "journal"
	modal("Things the station remembers",objective()+"\n\n"+str(state.memories.size())+" / 4 memories found")
	for key in MEMORIES:
		if key in state.memories:
			var id: String = key
			button(MEMORIES[id][0],func(): memory(id,true),panel)
	if "notice" in state.read: label("Relay: lantern → rain → dawn / 2 → 1 → 3",17,panel,"d8c69e")
	if "record" in state.read: label("Signal: HOME → NAME → LIGHT",17,panel,"d8c69e")
	if "diary" in state.read: label("The spare cell is in the garden's maintenance shed.",17,panel,"b7c6c0")
	button("Return",resume_game,panel)
func objective() -> String:
	if state.ended: return "A new destination is waiting."
	if state.signal: return "The last train is arriving. Return to the platform."
	if state.power: return "Cross Signal Walk. Find the last memory and tune the signal."
	if state.cell: return "Restore the relay at the north end of the platform."
	if "ticket" in state.read: return "Find the reserve cell. The waiting room may hold a clue."
	return "Examine the ticket beside the bench."
func toast(message: String, duration: float = 5) -> void:
	toast_label.text = message
	toast_time = duration
func _process(dt: float) -> void:
	if not is_instance_valid(player): return
	timer += dt
	if mode == "menu":
		menu_camera.position.x = 20+sin(timer*0.09)*3
		menu_camera.look_at(Vector3(-2,1,-3))
	if mode == "play":
		player.move_input = stick.value
		find_nearest()
		var zone = "SIGNAL WALK" if player.position.z < -22 else ("THE MAINTENANCE GARDEN" if player.position.x < -8 and player.position.z > 9 else ("THE WAITING ROOM" if player.position.x < -8 else "PLATFORM ZERO"))
		area_label.text = zone+" / "+str(state.memories.size())+" MEMORIES"
		if player.position.z < -35 and not state.revealed: reveal_world()
		if player.position.y < -8:
			player.position = Vector3(0,0.3,11)
			player.velocity = Vector3.ZERO
			toast("The station catches you. Your memories are safe.")
		if Input.is_action_just_pressed("interact"): interact_nearest()
		if Input.is_action_just_pressed("journal"): journal()
	if Input.is_action_just_pressed("pause"):
		if mode == "play": pause_menu()
		elif mode not in ["menu","cinematic","ending"]: resume_game()
	toast_time = maxf(0,toast_time-dt)
	toast_label.modulate.a = minf(toast_time,1)
	if train_arriving and mode == "play":
		train_time += dt
		var t = clampf(train_time/16,0,1)
		world.train.position.z = lerpf(-110,-3,1-pow(1-t,3))
		if t >= 1:
			train_arriving = false
			train_ready = true
			toast("Service 00 · The Sea Above\nThe door is open. Someone has been waiting.",8)
func _unhandled_input(e: InputEvent) -> void:
	if mode != "play": return
	if e is InputEventScreenTouch:
		if e.pressed and e.position.x>get_viewport().get_visible_rect().size.x*0.35 and finger == -1: finger=e.index
		elif not e.pressed and e.index == finger: finger = -1
	elif e is InputEventScreenDrag and e.index == finger: player.look(e.relative*float(settings.sensitivity))
	elif e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_RIGHT: Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if e.pressed else Input.MOUSE_MODE_VISIBLE
	elif e is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED: player.look(e.relative*float(settings.sensitivity))
func available(id: String) -> bool:
	if id in state.memories: return false
	if id == "cell" and state.cell: return false
	if id == "relay" and state.power: return false
	if id == "signal" and (not state.power or state.signal): return false
	if id == "train": return train_ready
	return true
func find_nearest() -> void:
	nearest = ""
	var distance = 2.5
	for p in world.points:
		p.gem.visible = available(p.id)
		if not available(p.id): continue
		var d = player.position.distance_to(p.pos)
		if d < distance:
			distance = d
			nearest = p.id
			prompt.text = p.title+" ›"
	prompt.visible = nearest != ""
func interact_nearest() -> void:
	if mode == "play" and nearest != "": interact(nearest)
func story(title: String, body: String) -> void:
	mode = "dialogue"
	modal(title,body)
	button("Carry on",resume_game,panel)
func interact(id: String) -> void:
	if MEMORIES.has(id):
		if not id in state.memories:
			state.memories.append(id)
			sfx("collect")
			save_game()
		memory(id)
		return
	if not id in state.read: state.read.append(id)
	match id:
		"ticket": story("A ticket with no destination","ONE WAY · PLATFORM 0\nPassenger: [the ink has faded]\n\nOn the back, in your handwriting:\n“If the world is gone, why am I still waiting?”\n\nThe signal at the far end of the station is dark.")
		"notice": story("The evacuation notice","FINAL SERVICE — RESTORE THE LINE BEFORE DEPARTURE\n\nBeneath the notice, someone has drawn three pictures:\nA lantern with TWO flames. Rain falling in ONE line. A dawn with THREE rays.\n\nThe relay dials follow the pictures from left to right.\n\n[Clue added to your journal.]")
		"diary": story("The stationmaster's notebook","“The signal eats reserve cells now. I put the last one on the workbench in the maintenance shed, beyond the garden.\n\nThe relay is beside the north end of the platform.\n\nI keep the waiting room open. It seems cruel to lock a door just because nobody is expected.”")
		"record": story("A maintenance record","The old signal listens to memories, not electricity.\n\nFIRST, the promise of a HOME.\nTHEN, the NAME of the one who stayed.\nLAST, a LIGHT carried through the dark.\n\nCollect the three blue memories, then ring the signal in that order.\n\n[Sequence added to your journal.]")
		"cell":
			state.cell = true
			sfx("collect")
			story("The last reserve cell","Still warm. Someone charged it recently.\n\nTake it to the relay cabinet beside the north end of the main platform. The waiting room's evacuation notice explains the dials.")
		"relay": relay_panel()
		"signal": signal_panel()
		"stranger":
			if state.signal: story("The traveler in white","“There you are.”\n\nTheir voice sounds almost like yours, remembered through a wall.\n\n“The train doesn't carry people away from the end. It carries what they refused to leave behind.”")
			else: story("The traveler in white","“You're early,” the stranger says.\n\n“Or very late. The clocks disagree.”\n\nThey turn toward the dark signal.\n\n“Give the station a little light. It will remember the way.”")
		"train": end_chapter()
	save_game()
	objective_label.text = objective()
func memory(id: String, from_journal: bool = false) -> void:
	mode = "memory"
	modal(MEMORIES[id][0],MEMORIES[id][1])
	button("Close the memory",journal if from_journal else resume_game,panel)
func relay_panel() -> void:
	mode = "puzzle"
	if not state.cell:
		story("The relay has no heart","An empty socket. Three numbered dials.\n\nFind the reserve cell in the maintenance shed beyond the garden. The waiting room may have instructions.")
		return
	modal("The signal relay","The reserve cell fits. Set each dial, then close the circuit.\nThe evacuation notice in the waiting room describes the order.")
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation",16)
	panel.add_child(row)
	for i in range(3):
		var index = i
		button(["LANTERN","RAIN","DAWN"][i]+"\n"+str(dials[i]),func(): dials[index]=(dials[index]+1)%4; relay_panel(),row,185)
	relay_error = label("",17,panel,"e7b093")
	button("Close the circuit",attempt_relay,panel)
	button("Step away",resume_game,panel)
func attempt_relay() -> void:
	if dials == [2,1,3] and state.cell:
		state.power = true
		world.set_power(true)
		sfx("success")
		save_game()
		story("A light, kept","The relay clicks. For a moment, every lamp on the platform breathes.\n\nThe gate to Signal Walk sinks into the stone. Beyond it, the horizon waits.\n\nFind the memories, and teach the signal where to go.")
	else:
		sfx("error")
		if is_instance_valid(relay_error): relay_error.text = "The current fades. Check the evacuation notice."
func signal_panel() -> void:
	mode = "puzzle"
	if not ("m1" in state.memories and "m2" in state.memories and "m3" in state.memories):
		story("A signal without a destination","The console hums, but its three glass keys are empty.\n\nFind the blue memories in the waiting room, the maintenance garden, and this overlook.\n\nThe maintenance record explains how to play them.")
		return
	tones.clear()
	draw_tones()
func draw_tones() -> void:
	modal("Teach the rails to remember","Three tones. One way forward.\nThe maintenance record names their order.")
	var names: Array[String] = []
	for n in tones: names.append(["LIGHT","HOME","NAME"][n])
	label(" → ".join(names) if not names.is_empty() else "—    —    —",24,panel,"d9bf8d")
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation",12)
	panel.add_child(row)
	for i in range(3):
		var index = i
		button(["LIGHT","HOME","NAME"][i],func(): ring(index),row,190)
	button("Step away",resume_game,panel)
func ring(index: int) -> void:
	sfx("tone"+str(index))
	tones.append(index)
	if tones.size() == 3:
		if tones == [1,2,0]:
			state.signal = true
			world.signal_light.material_override = G.material("9dc5a4",0.5)
			save_game()
			resume_game()
			world.train.visible = true
			train_arriving = true
			train_ready = false
			train_time = 0
			sfx("train","train")
			toast("A bell answers from somewhere below the clouds.\nReturn to the main platform.",9)
		else:
			tones.clear()
			draw_tones()
			label("A lost echo. The record says: first HOME…",17,panel,"e7b093")
	else: draw_tones()
func reveal_world() -> void:
	state.revealed = true
	save_game()
	mode = "cinematic"
	player.enabled = false
	stick.reset()
	hud.visible = false
	cinema.position = Vector3(1,5,-38)
	cinema.look_at(Vector3(12,2,-120))
	cinema.current = true
	var t = create_tween()
	t.tween_property(cinema,"position",Vector3(1,7,-44),5).set_trans(Tween.TRANS_SINE)
	t.tween_callback(func(): story("The world did not end quietly","There is a city above the clouds.\n\nAnd another. And another.\n\nThe rails lead toward them, broken in places — as if the world forgot how distance works."))
func end_chapter() -> void:
	state.ended = true
	save_game()
	mode = "cinematic"
	player.enabled = false
	stick.reset()
	hud.visible = false
	overlay.visible = false
	player.visible = false
	cinema.position = Vector3(22,7,16)
	cinema.look_at(Vector3(10,1,-4))
	cinema.current = true
	sfx("train","train")
	var t = create_tween()
	t.tween_property(world.train,"position:z",-100,9).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.parallel().tween_property(fade,"color:a",1,9).set_delay(1)
	t.tween_callback(ending)
func ending() -> void:
	mode = "ending"
	fade.color.a = 0
	modal("NEXT STOP / THE SEA ABOVE","In the window, your reflection is holding someone's hand.\n\nThe seat beside you is empty.\n\nThen the announcement speaks.\n\n“Thank you for waiting for me.”\n\nPLATFORM ZERO — COMPLETE\n"+str(state.memories.size())+" / 4 memories carried onward.")
	button("Return to the station · find remaining memories",func(): state.ended=false; player.visible=true; world.train.position.z=-3; player.position=Vector3(3,0.2,0); resume_game(); save_game(),panel)
	button("Title screen",func(): player.visible=true; main_menu(),panel)
func save_game() -> void:
	if not started: return
	var data = state.duplicate(true)
	data.position = [player.position.x,player.position.y,player.position.z]
	data.yaw = player.yaw
	data.version = 1
	var f = FileAccess.open(save_path+".tmp",FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data))
		f.close()
		DirAccess.rename_absolute(save_path+".tmp",save_path)
func continue_game() -> void:
	var f = FileAccess.open(save_path,FileAccess.READ)
	if not f: return
	var data = JSON.parse_string(f.get_as_text())
	if not data is Dictionary or int(data.get("version",0)) != 1:
		modal("This ticket cannot be read","The save file is damaged or from an unsupported version.")
		button("Back",main_menu,panel)
		return
	state = INITIAL.duplicate(true)
	for key in state: state[key] = data.get(key,state[key])
	var pos = data.get("position",[0,0.2,11])
	player.position = Vector3(pos[0],pos[1]+0.1,pos[2])
	player.yaw = float(data.get("yaw",0))
	player.velocity = Vector3.ZERO
	player.visible = true
	world.set_power(state.power)
	train_arriving = false
	train_ready = state.signal
	world.train.visible = state.signal
	if state.signal:
		world.train.position.z = -3
		world.signal_light.material_override = G.material("9dc5a4",0.5)
	started = true
	if state.ended: ending()
	else: resume_game()
func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED:
		save_game()
		if mode == "play": pause_menu()
	elif what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if mode == "play": pause_menu()
		elif started and mode not in ["cinematic","ending"]: resume_game()
func quit_game() -> void:
	for p in sounds.values():
		p.stop()
		p.stream = null
	G.cache.clear()
	await get_tree().process_frame
	await get_tree().process_frame
	get_tree().quit()
func smoke_tests() -> void:
	await get_tree().process_frame
	new_game()
	resume_game()
	assert(world.points.size()==13)
	# Imported character must retain all animation targets after export/import.
	assert(player.limbs.size() == 4 and player.knees.size() == 2 and player.eyes.size() == 2)
	for joint in player.limbs + player.knees + player.elbows + player.eyes:
		assert(is_instance_valid(joint))
	assert(is_instance_valid(player.hair) and is_instance_valid(player.skirt))
	assert(is_instance_valid(player.ribbon) and is_instance_valid(player.head))
	interact("cell")
	assert(state.cell)
	dials = [0,0,0]
	attempt_relay()
	assert(not state.power)
	dials = [2,1,3]
	attempt_relay()
	assert(state.power and world.gate.position.y < -3)
	for id in ["m1","m2","m3","m4"]: interact(id)
	assert(state.memories.size()==4)
	tones.clear()
	for n in [0,1,2]: ring(n)
	assert(not state.signal)
	for n in [1,2,0]: ring(n)
	assert(state.signal and train_arriving)
	resume_game()
	_process(17)
	assert(train_ready and absf(world.train.position.z+3)<0.01)
	save_game()
	state.memories.clear()
	state.power = false
	continue_game()
	assert(state.power and state.memories.size()==4 and train_ready)
	# Two different fingers must move and jump independently in either order.
	var touch = InputEventScreenTouch.new()
	touch.index=2
	touch.pressed=true
	touch.position=stick.get_global_rect().position+Vector2(143,90)
	stick._input(touch)
	assert(stick.value.x>0.8 and stick.finger==2)
	var jump_touch = InputEventScreenTouch.new()
	jump_touch.index=3
	jump_touch.pressed=true
	jump_touch.position=jump_button.get_global_rect().get_center()
	jump_button._input(jump_touch)
	assert(player.jump_requested and jump_button.finger==3 and stick.finger==2)
	assert(stick.value.x>0.8)
	jump_touch.pressed=false
	jump_button._input(jump_touch)
	assert(jump_button.finger==-1 and stick.finger==2)
	touch.pressed=false
	stick._input(touch)
	assert(stick.value==Vector2.ZERO and stick.finger==-1)
	player.jump_requested=false
	# Reversed order: keep Jump held while starting/releasing movement.
	jump_touch.pressed=true
	jump_button._input(jump_touch)
	touch.pressed=true
	stick._input(touch)
	assert(jump_button.finger==3 and stick.finger==2 and player.jump_requested)
	touch.pressed=false
	stick._input(touch)
	assert(stick.value==Vector2.ZERO and jump_button.finger==3)
	jump_touch.pressed=false
	jump_button._input(jump_touch)
	assert(jump_button.finger==-1)
	player.jump_requested=false
	assert(player.movement_speed(0.4)<player.movement_speed(0.8))
	assert(player.movement_speed(0.8)<player.movement_speed(1.0))
	player.position=Vector3(0,0.1,10)
	for i in range(30): await get_tree().physics_frame
	assert(player.is_on_floor())
	Input.action_press("forward")
	for i in range(60): await get_tree().physics_frame
	Input.action_release("forward")
	assert(player.position.z<9)
	player.jump_requested=true
	for i in range(12): await get_tree().physics_frame
	assert(player.position.y>0.2)
	end_chapter()
	await get_tree().create_timer(10.5).timeout
	assert(state.ended and mode=="ending")
	continue_game()
	assert(mode=="ending")
	DirAccess.remove_absolute(save_path)
	print("SMOKE PASS: scene, 13 points, fuse, relay failure/success, memories, tone failure/success, train, disk save/load, concurrent joystick/jump touches, analog auto-run, floor collision, movement, jump, ending and ending reload")
	await quit_game()
func capture_views() -> void:
	new_game()
	resume_game()
	await get_tree().create_timer(2).timeout
	for view in ["platform","title","garden","overlook","memory","settings"]:
		match view:
			"title": main_menu()
			"garden":
				resume_game()
				player.position=Vector3(-13,0.2,16)
				player.yaw=PI
			"overlook":
				resume_game()
				state.power=true
				state.revealed=true
				world.set_power(true)
				player.position=Vector3(0,0.2,-44)
				player.yaw=-0.45
				player.pitch=-0.18
			"memory": memory("m3")
			"settings": settings_menu("pause")
		await get_tree().create_timer(1).timeout
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("user://"+view+".png")
	print("CAPTURE: ",OS.get_user_data_dir())
	DirAccess.remove_absolute(save_path)
	await quit_game()
