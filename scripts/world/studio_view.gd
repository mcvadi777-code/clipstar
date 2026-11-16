class_name StudioView
extends Control
## Сцена студии: фон по стадии, персонаж, анимация на тап.

signal tapped(pos: Vector2)

const ART: String = "res://assets/art/"

var bg: TextureRect
var char_root: Control
var body: TextureRect
var head: TextureRect
var arm: TextureRect
var stage: int = 0
var _time: float = 0.0
var _base_y: float = 0.0
var _tap_scale: float = 1.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	build()


func build() -> void:
	bg = TextureRect.new()
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	char_root = Control.new()
	char_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	char_root.size = Vector2(300.0, 780.0)
	add_child(char_root)

	arm = TextureRect.new()
	arm.texture = load(ART + "char_arm.svg")
	arm.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	arm.size = Vector2(90.0, 240.0)
	arm.pivot_offset = Vector2(45.0, 40.0)
	arm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	arm.position = Vector2(214.0, 322.0)
	char_root.add_child(arm)

	body = TextureRect.new()
	body.texture = load(ART + "char_body.svg")
	body.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	body.size = Vector2(300.0, 460.0)
	body.position = Vector2(0.0, 316.0)
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	char_root.add_child(body)

	head = TextureRect.new()
	head.texture = load(ART + "char_head.svg")
	head.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	head.size = Vector2(320.0, 320.0)
	head.position = Vector2(-10.0, 0.0)
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	char_root.add_child(head)


func set_stage(value: int) -> void:
	stage = clampi(value, 0, 4)
	if bg != null:
		bg.texture = load(ART + "room_" + str(stage) + ".svg")


func _process(delta: float) -> void:
	_time += delta
	if char_root == null:
		return
	var target: Vector2 = _layout_char()
	_base_y = target.y
	char_root.position = Vector2(target.x, _base_y + sin(_time * 2.0) * 9.0)
	_tap_scale = lerpf(_tap_scale, 1.0, minf(delta * 8.0, 1.0))
	char_root.scale = Vector2.ONE * _tap_scale
	arm.rotation = sin(_time * 1.7) * 0.06


func _layout_char() -> Vector2:
	var w: float = size.x
	var h: float = size.y
	return Vector2(w * 0.5 - 150.0, h - 700.0)


func play_tap() -> void:
	_tap_scale = 1.07
	var tw: Tween = create_tween()
	tw.tween_property(arm, "rotation", 0.9, 0.09)
	tw.tween_property(arm, "rotation", 0.0, 0.22)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch: InputEventScreenTouch = event
		if touch.pressed:
			emit_signal("tapped", touch.position)
	elif event is InputEventMouseButton:
		var mouse: InputEventMouseButton = event
		if mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT:
			emit_signal("tapped", mouse.position)
