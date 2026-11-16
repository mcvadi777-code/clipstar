extends Node3D
## Мира: тело из примитивов с toon-материалами, лицо из отдельных мешей (глаза, зрачки, брови, три формы рта, румянец).
## Эмоции — анимации AnimationPlayer (лежат в mira.tscn):
##   idle (цикл), talk (цикл, во время съёмки), dance (цикл),
##   happy, surprised, sad, wave — одноразовые, после них Мира возвращается в idle.

const LOOPING: Array[String] = ["idle", "talk", "dance"]
const BLEND_SECONDS: float = 0.18

@onready var _anim: AnimationPlayer = $AnimationPlayer

var _dance_timer: SceneTreeTimer


func _ready() -> void:
	_anim.animation_finished.connect(_on_animation_finished)
	_anim.play("idle")


func set_talking(value: bool) -> void:
	play_emotion("talk" if value else "idle")


## Проигрывает эмоцию; одноразовые сами возвращаются в idle.
func play_emotion(emotion: String) -> void:
	if not _anim.has_animation(emotion):
		push_warning("Mira: нет анимации '%s'" % emotion)
		return
	_anim.play(emotion, BLEND_SECONDS)


## Танец на seconds секунд, затем idle.
func dance_for(seconds: float) -> void:
	play_emotion("dance")
	_dance_timer = get_tree().create_timer(seconds)
	_dance_timer.timeout.connect(_end_dance)


func current_emotion() -> String:
	return _anim.current_animation


func _end_dance() -> void:
	if _anim.current_animation == "dance":
		play_emotion("idle")


func _on_animation_finished(anim_name: StringName) -> void:
	if not LOOPING.has(String(anim_name)):
		play_emotion("idle")
