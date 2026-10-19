class_name VirtualStick
extends Control
# Each finger owns its control. Read raw touch events rather than relying on
# emulated mouse clicks (which may only follow the first finger).
var value = Vector2.ZERO
var finger = -1
var knob = Vector2.ZERO
var input_enabled = false
const KNOB_RADIUS = 54.0
const DEAD_ZONE = 8.0
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
func _draw() -> void:
	var center = size / 2.0
	var running = value.length() >= 0.82
	draw_circle(center,65,Color(0.8,0.88,0.86,0.09))
	draw_arc(center,65,0,TAU,64,Color("e0c393") if running else Color(0.85,0.9,0.86,0.4),2.5 if running else 1.5,true)
	draw_circle(center+knob,25,Color(0.88,0.88,0.77,0.34 if running else 0.24))
	draw_arc(center+knob,25,0,TAU,48,Color("e0c393") if running else Color(0.95,0.9,0.77,0.6),1.5,true)
func update_knob(pos: Vector2) -> void:
	knob = (pos-size/2.0).limit_length(KNOB_RADIUS)
	var distance = knob.length()
	var strength = clampf((distance-DEAD_ZONE)/(KNOB_RADIUS-DEAD_ZONE),0.0,1.0)
	value = knob/distance*strength if distance > 0.0 else Vector2.ZERO
	queue_redraw()
func reset() -> void:
	finger = -1
	knob = Vector2.ZERO
	value = Vector2.ZERO
	queue_redraw()
func _input(e: InputEvent) -> void:
	if not input_enabled or not is_visible_in_tree(): return
	var rect = get_global_rect()
	if e is InputEventScreenTouch:
		if e.pressed and finger == -1 and rect.has_point(e.position):
			finger = e.index
			update_knob(e.position-rect.position)
			get_viewport().set_input_as_handled()
		elif not e.pressed and e.index == finger:
			reset()
			get_viewport().set_input_as_handled()
	elif e is InputEventScreenDrag and e.index == finger:
		update_knob(e.position-rect.position)
		get_viewport().set_input_as_handled()
	# Mouse support is only for desktop debugging. Don't treat touch-emulated
	# mouse events as a second joystick finger on Android.
	elif not OS.has_feature("mobile") and e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		if e.pressed and finger == -1 and rect.has_point(e.position):
			finger = -2
			update_knob(e.position-rect.position)
			get_viewport().set_input_as_handled()
		elif not e.pressed and finger == -2:
			reset()
			get_viewport().set_input_as_handled()
	elif not OS.has_feature("mobile") and e is InputEventMouseMotion and finger == -2:
		update_knob(e.position-rect.position)
		get_viewport().set_input_as_handled()
