class_name StudioView
extends Control
## Сцена студии: фон по стадии, персонаж, анимация на тап.

signal tapped(pos: Vector2)

const ART: String = "res://assets/art/"
const CHAR_W: float = 300.0
const CHAR_H: float = 733.0

var bg: TextureRect
var char_root: Control
var character: TextureRect
var stage: int = 0
var _time: float = 0.0
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

	var glow: TextureRect = TextureRect.new()
	glow.texture = load(ART + "light.svg")
	glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	glow.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	glow.size = Vector2(1000.0, 1000.0)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glow.name = "Glow"
	add_child(glow)

	char_root = Control.new()
	char_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	char_root.size = Vector2(CHAR_W, CHAR_H)
	add_child(char_root)

	character = TextureRect.new()
	character.texture = load(ART + "char.svg")
	character.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	character.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	character.size = Vector2(CHAR_W, CHAR_H)
	character.pivot_offset = Vector2(CHAR_W * 0.5, CHAR_H)
	character.mouse_filter = Control.MOUSE_FILTER_IGNORE
	char_root.add_child(character)


func set_stage(value: int) -> void:
	stage = clampi(value, 0, 4)
	if bg != null:
		bg.texture = load(ART + "room_" + str(stage) + ".svg")


func _process(delta: float) -> void:
	_time += delta
	if char_root == null:
		return
	var bob: float = sin(_time * 2.2) * 10.0
	char_root.position = Vector2(size.x * 0.5 - CHAR_W * 0.5, size.y - CHAR_H - 90.0 + bob)
	var glow_node: Node = get_node_or_null("Glow")
	if glow_node != null:
		var g2: TextureRect = glow_node as TextureRect
		g2.position = Vector2(size.x * 0.5 - 500.0, size.y - 760.0 + bob * 0.5)
	_tap_scale = lerpf(_tap_scale, 1.0, minf(delta * 9.0, 1.0))
	character.scale = Vector2(_tap_scale, 2.0 - _tap_scale)


func play_tap() -> void:
	_tap_scale = 1.06


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch: InputEventScreenTouch = event
		if touch.pressed:
			emit_signal("tapped", touch.position)
	elif event is InputEventMouseButton:
		var mouse: InputEventMouseButton = event
		if mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT:
			emit_signal("tapped", mouse.position)
