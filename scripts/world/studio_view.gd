class_name StudioView
extends Control
## Сцена: фон по стадии + персонаж из слоёв, анимация на тап.

signal tapped(pos: Vector2)

const ART: String = "res://assets/art_hi/"
const BG_STAGES: Array = ["bg_yard", "bg_yard", "bg_bridge", "bg_bridge", "bg_rich"]
const CHAR_SCALE: float = 0.72

var bg: TextureRect
var char_root: Control
var shadow: TextureRect
var mouth: TextureRect
var arm: TextureRect
var stage: int = 0
var expression: String = "smile"
var _time: float = 0.0
var _tap_scale: float = 1.0
var _mouth_timer: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	build()


func build() -> void:
	var sky: ColorRect = ColorRect.new()
	sky.color = Color("#6ec6f5")
	sky.set_anchors_preset(Control.PRESET_FULL_RECT)
	sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sky)

	bg = TextureRect.new()
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	char_root = Control.new()
	char_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	char_root.size = Vector2(760.0, 1060.0)
	char_root.scale = Vector2(CHAR_SCALE, CHAR_SCALE)
	add_child(char_root)

	shadow = _part("char_shadow", Vector2(-10.0, 960.0), Vector2(1000.0, 176.0))

	var leg_l: TextureRect = _part("char_leg", Vector2(210.0, 520.0), Vector2(150.0, 970.0))
	leg_l.modulate = Color("#5b6478")
	var leg_r: TextureRect = _part("char_leg", Vector2(400.0, 520.0), Vector2(150.0, 970.0))
	leg_r.modulate = Color("#525b6e")

	var body: TextureRect = _part("char_body_hoodie", Vector2(290.0, 230.0), Vector2(310.0, 440.0))
	body.modulate = Color("#8e93a1")

	arm = _part("char_arm", Vector2(540.0, 300.0), Vector2(120.0, 520.0))
	arm.pivot_offset = Vector2(60.0, 60.0)
	arm.modulate = Color("#8e93a1")

	var head: TextureRect = _part("char_head", Vector2(330.0, -110.0), Vector2(310.0, 344.0))

	var hair: TextureRect = _part("char_hair", Vector2(320.0, -150.0), Vector2(330.0, 200.0))
	hair.modulate = Color("#5b3f2e")

	mouth = _part("mouth_smile", Vector2(445.0, 130.0), Vector2(78.0, 52.0))


func _part(file: String, pos: Vector2, sz: Vector2) -> TextureRect:
	var t: TextureRect = TextureRect.new()
	t.texture = load(ART + file + ".webp")
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.position = pos
	t.size = sz
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	char_root.add_child(t)
	return t


func set_stage(value: int) -> void:
	stage = clampi(value, 0, 4)
	if bg != null:
		bg.texture = load(ART + str(BG_STAGES[stage]) + ".webp")


func set_expression(name: String) -> void:
	if expression == name or mouth == null:
		return
	expression = name
	match name:
		"wow":
			mouth.texture = load(ART + "mouth_open.webp")
		"happy":
			mouth.texture = load(ART + "mouth_smile.webp")
		_:
			mouth.texture = load(ART + "mouth_neutral.webp")
	_mouth_timer = 1.4


func play_tap() -> void:
	_tap_scale = 1.05
	set_expression("wow")
	var tw: Tween = create_tween()
	tw.tween_property(arm, "rotation", -0.5, 0.1)
	tw.tween_property(arm, "rotation", 0.0, 0.24)


func _process(delta: float) -> void:
	_time += delta
	if char_root == null:
		return
	var bob: float = sin(_time * 2.1) * 8.0
	char_root.position = Vector2(size.x * 0.5 - 380.0, size.y - 800.0 + bob)
	_tap_scale = lerpf(_tap_scale, 1.0, minf(delta * 8.0, 1.0))
	char_root.scale = Vector2(CHAR_SCALE * _tap_scale, CHAR_SCALE * (2.0 - _tap_scale))
	if _mouth_timer > 0.0:
		_mouth_timer -= delta
		if _mouth_timer <= 0.0:
			set_expression("neutral")


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch: InputEventScreenTouch = event
		if touch.pressed:
			emit_signal("tapped", touch.position)
	elif event is InputEventMouseButton:
		var mouse: InputEventMouseButton = event
		if mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT:
			emit_signal("tapped", mouse.position)
