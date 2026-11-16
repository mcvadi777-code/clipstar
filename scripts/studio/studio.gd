extends Node3D
## 3D-студия: свет, пропсы, Мира и визуальные уровни апгрейдов.
##   camera: уровень 0 — телефон на коробке; с 1-го — камера на штативе, объектив растёт, с 3-го — накамерный свет.
##   light:  с 1-го уровня — кольцевая лампа, с каждым уровнем ярче и сама лампа, и ключевой свет.
##   desk:   стол шире с каждым уровнем; 2 — второй монитор, 3 — настольная лампа, 4 — колонки, 5 — кубок.
## Сок: тряска камеры, вспышка, мигающая лампа REC, реакция Миры на итог ролика.

const MiraScript := preload("res://scripts/studio/mira.gd")

@onready var _camera: Camera3D = $Camera3D
@onready var _key_light: DirectionalLight3D = $KeyLight
@onready var _mira: MiraScript = $Mira
@onready var _phone_setup: Node3D = $CameraUpgrade/PhoneSetup
@onready var _tripod: Node3D = $CameraUpgrade/Tripod
@onready var _lens: Node3D = $CameraUpgrade/Tripod/Head/Lens
@onready var _top_led: Node3D = $CameraUpgrade/Tripod/Head/TopLed
@onready var _rec_phone: Node3D = $CameraUpgrade/PhoneSetup/RecDot
@onready var _rec_tripod: Node3D = $CameraUpgrade/Tripod/Head/RecDot
@onready var _rec_light: OmniLight3D = $CameraUpgrade/RecLight
@onready var _ring_light: Node3D = $LightUpgrade/RingLight
@onready var _ring_glow: OmniLight3D = $LightUpgrade/RingLight/Glow
@onready var _ring_mesh: MeshInstance3D = $LightUpgrade/RingLight/Ring
@onready var _desk: Node3D = $DeskUpgrade/Desk
@onready var _desk_top: Node3D = $DeskUpgrade/Desk/Top
@onready var _desk_extras: Array[Node3D] = [
	$DeskUpgrade/Desk/Top/Monitor2, $DeskUpgrade/Desk/Top/DeskLamp,
	$DeskUpgrade/Desk/Top/Speakers, $DeskUpgrade/Desk/Top/Trophy,
]
@onready var _flash_light: OmniLight3D = $FlashLight

const KEY_LIGHT_BASE: float = 1.0
const KEY_LIGHT_PER_LEVEL: float = 0.02

var _time: float = 0.0
var _recording: bool = false
var _shake_strength: float = 0.0
var _shake_time_left: float = 0.0
var _shake_duration: float = 0.0
var _ring_material: ShaderMaterial
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	_flash_light.light_energy = 0.0
	var base_ring: Material = _ring_mesh.get_active_material(0)
	if base_ring is ShaderMaterial:
		_ring_material = (base_ring as ShaderMaterial).duplicate() as ShaderMaterial
		_ring_mesh.material_override = _ring_material
	set_recording(false)
	for upgrade_id: String in ["camera", "light", "desk"]:
		set_upgrade_level(upgrade_id, 0)


func _process(delta: float) -> void:
	_time += delta
	if _recording:
		var blink: bool = fmod(_time, 1.0) < 0.6
		_rec_light.light_energy = 1.2 if blink else 0.0
		_rec_phone.visible = blink
		_rec_tripod.visible = blink
	if _shake_time_left > 0.0:
		_shake_time_left -= delta
		var k: float = clampf(_shake_time_left / maxf(_shake_duration, 0.001), 0.0, 1.0)
		_camera.h_offset = _rng.randf_range(-1.0, 1.0) * _shake_strength * k
		_camera.v_offset = _rng.randf_range(-1.0, 1.0) * _shake_strength * k
	else:
		_camera.h_offset = 0.0
		_camera.v_offset = 0.0


func mira() -> MiraScript:
	return _mira


func set_recording(value: bool) -> void:
	_recording = value
	_rec_light.light_energy = 0.0
	_rec_phone.visible = value
	_rec_tripod.visible = value
	_mira.set_talking(value)


func shake(strength: float, duration: float) -> void:
	_shake_strength = maxf(strength, _shake_strength if _shake_time_left > 0.0 else 0.0)
	_shake_duration = duration
	_shake_time_left = duration


## Вспышка в 3D: белый точечный свет у камеры, быстро гаснет.
func flash(strength: float = 4.0) -> void:
	_flash_light.light_energy = strength
	var tween: Tween = create_tween()
	tween.tween_property(_flash_light, "light_energy", 0.0, 0.35).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)


## Реакция Миры на итог ролика.
func react_to_result(result: Dictionary) -> void:
	if bool(result.get("viral", false)):
		_mira.dance_for(2.5)
	elif bool(result.get("is_record", false)) or float(result.get("quality", 0.0)) >= 0.6:
		_mira.play_emotion("happy")
	elif float(result.get("quality", 0.0)) < 0.25:
		_mira.play_emotion("sad")
	else:
		_mira.play_emotion("surprised")


func set_upgrade_level(upgrade_id: String, level: int) -> void:
	match upgrade_id:
		"camera":
			_phone_setup.visible = level <= 0
			_tripod.visible = level >= 1
			_lens.scale = Vector3.ONE * (1.0 + 0.12 * float(maxi(level - 1, 0)))
			_top_led.visible = level >= 3
		"light":
			_ring_light.visible = level >= 1
			_ring_glow.light_energy = 0.12 + 0.07 * float(level)
			if _ring_material != null:
				_ring_material.set_shader_parameter("emission_strength", 0.5 + 0.15 * float(level))
			_key_light.light_energy = KEY_LIGHT_BASE + KEY_LIGHT_PER_LEVEL * float(level)
		"desk":
			_desk_top.scale = Vector3(1.0 + 0.12 * float(level), 1.0, 1.0 + 0.05 * float(level))
			for i: int in _desk_extras.size():
				_desk_extras[i].visible = level >= i + 2
				_desk_extras[i].scale = Vector3(1.0 / _desk_top.scale.x, 1.0, 1.0 / _desk_top.scale.z)


## Показ апгрейда: Мира машет, предмет подпрыгивает.
func celebrate_upgrade(upgrade_id: String) -> void:
	_mira.play_emotion("wave")
	var target: Node3D = _tripod if upgrade_id == "camera" else (_ring_light if upgrade_id == "light" else _desk)
	var base_scale: Vector3 = Vector3.ONE
	var tween: Tween = create_tween()
	tween.tween_property(target, "scale", base_scale * 1.15, 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(target, "scale", base_scale, 0.35).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	shake(0.04, 0.25)
