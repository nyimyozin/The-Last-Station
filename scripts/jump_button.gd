extends Control
signal jump_pressed

# Raw per-finger input lets the player jump while a different finger holds
# the joystick or drags the camera. A normal Button can depend on mouse
# emulation, which isn't reliable for secondary touches.
var finger = -1
var input_enabled = false
var held = false
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var title = Label.new()
	title.text = "JUMP"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.add_theme_font_size_override("font_size",20)
	title.add_theme_color_override("font_color",Color("f4e8c9"))
	add_child(title)
func _draw() -> void:
	var center = size/2.0
	var radius = minf(size.x,size.y)*0.43
	draw_circle(center,radius,Color(0.32,0.42,0.43,0.94) if held else Color(0.10,0.20,0.24,0.87))
	draw_arc(center,radius,0,TAU,64,Color("e0c393") if held else Color(0.86,0.81,0.66,0.72),2.5,true)
func reset() -> void:
	finger = -1
	held = false
	queue_redraw()
func trigger(index: int) -> void:
	finger = index
	held = true
	queue_redraw()
	jump_pressed.emit()
func _input(e: InputEvent) -> void:
	if not input_enabled or not is_visible_in_tree(): return
	var rect = get_global_rect()
	if e is InputEventScreenTouch:
		if e.pressed and finger == -1 and rect.has_point(e.position):
			trigger(e.index)
			get_viewport().set_input_as_handled()
		elif not e.pressed and e.index == finger:
			reset()
			get_viewport().set_input_as_handled()
	elif not OS.has_feature("mobile") and e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		if e.pressed and finger == -1 and rect.has_point(e.position):
			trigger(-2)
			get_viewport().set_input_as_handled()
		elif not e.pressed and finger == -2:
			reset()
			get_viewport().set_input_as_handled()
