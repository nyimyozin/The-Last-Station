extends Control
var value = Vector2.ZERO
var finger = -1
var knob = Vector2.ZERO
func _ready() -> void: mouse_filter = Control.MOUSE_FILTER_STOP
func _draw() -> void:
	draw_circle(size/2,65,Color(0.8,0.88,0.86,0.09))
	draw_arc(size/2,65,0,TAU,64,Color(0.85,0.9,0.86,0.4),1.5,true)
	draw_circle(size/2+knob,25,Color(0.88,0.88,0.77,0.24))
	draw_arc(size/2+knob,25,0,TAU,48,Color(0.95,0.9,0.77,0.6),1.5,true)
func update_knob(pos: Vector2) -> void:
	knob = (pos-size/2).limit_length(54)
	value = knob/54
	queue_redraw()
func reset() -> void:
	finger = -1
	knob = Vector2.ZERO
	value = Vector2.ZERO
	queue_redraw()
func _gui_input(e: InputEvent) -> void:
	if e is InputEventScreenTouch:
		if e.pressed and finger == -1:
			finger = e.index
			update_knob(e.position)
		elif not e.pressed and e.index == finger: reset()
		accept_event()
	elif e is InputEventScreenDrag and e.index == finger:
		update_knob(e.position)
		accept_event()
	elif e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		if e.pressed:
			finger = -2
			update_knob(e.position)
		else: reset()
		accept_event()
	elif e is InputEventMouseMotion and finger == -2:
		update_knob(e.position)
		accept_event()
