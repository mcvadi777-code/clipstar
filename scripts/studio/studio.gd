extends Node3D
## 3D-студия из примитивов: Мира (капсула + сфера) за столом, камера на штативе, лампа «REC».
## Анимации кодом: дыхание в простое, активная жестикуляция при съёмке, прыжок радости.

@onready var _mira: Node3D = $Mira
@onready var _head: MeshInstance3D = $Mira/Head
@onready var _camera_rig: Node3D = $CameraRig
@onready var _lens: MeshInstance3D = $CameraRig/Lens
@onready var _rec_light: OmniLight3D = $RecLight

const LENS_COLORS: Array[Color] = [
	Color(0.25, 0.25, 0.28), Color(0.2, 0.45, 0.85), Color(0.2, 0.75, 0.55),
	Color(0.85, 0.65, 0.2), Color(0.9, 0.35, 0.25), Color(0.75, 0.3, 0.85), Color(1.0, 0.85, 0.3),
]

var _time: float = 0.0
var _recording: bool = false
var _mira_base_y: float = 0.0
var _lens_material: StandardMaterial3D = StandardMaterial3D.new()
var _jump_tween: Tween


func _ready() -> void:
	_mira_base_y = _mira.position.y
	_lens.material_override = _lens_material
	_rec_light.visible = false
	set_camera_level(0)


func _process(delta: float) -> void:
	_time += delta
	var speed: float = 9.0 if _recording else 2.0
	var amount: float = 0.06 if _recording else 0.025
	_head.rotation.z = sin(_time * speed) * amount * 2.0
	_mira.scale = Vector3.ONE * (1.0 + sin(_time * speed * 0.5) * amount * 0.4)
	if _recording:
		_rec_light.light_energy = 1.5 + sin(_time * 8.0) * 1.0


func set_recording(value: bool) -> void:
	_recording = value
	_rec_light.visible = value


## Уровень апгрейда камеры: объектив растёт и меняет цвет.
func set_camera_level(level: int) -> void:
	var idx: int = clampi(level, 0, LENS_COLORS.size() - 1)
	_lens_material.albedo_color = LENS_COLORS[idx]
	_lens_material.metallic = 0.3 + 0.1 * float(idx)
	_lens.scale = Vector3.ONE * (1.0 + 0.12 * float(idx))
	_camera_rig.rotation.y = deg_to_rad(-8.0)


func celebrate() -> void:
	if _jump_tween != null and _jump_tween.is_valid():
		_jump_tween.kill()
	_mira.position.y = _mira_base_y
	_jump_tween = create_tween()
	_jump_tween.tween_property(_mira, "position:y", _mira_base_y + 0.35, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_jump_tween.tween_property(_mira, "position:y", _mira_base_y, 0.25).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
