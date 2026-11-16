extends Node
## Съёмка ролика: проверки → списание энергии → таймер съёмки, во время которого игрок
## тапает «Фокус» (тапы = качество 0..1) → расчёт просмотров/монет/подписчиков → начисление.

signal shoot_started(topic: Dictionary)
signal shoot_progress(progress01: float, quality01: float)
signal shoot_finished(result: Dictionary)

const Formulas := preload("res://scripts/gameplay/formulas.gd")
const GameData := preload("res://scripts/data/game_data.gd")

var is_shooting: bool = false

var _topic: Dictionary = {}
var _elapsed: float = 0.0
var _duration: float = 1.0
var _taps: int = 0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	set_process(false)


## Пустая строка — снимать можно; иначе причина для игрока.
func block_reason(topic_id: String) -> String:
	var topic: Dictionary = GameData.topic(topic_id)
	if topic.is_empty():
		return "Тема не найдена"
	if is_shooting:
		return "Уже идёт съёмка"
	if not Progress.is_topic_unlocked(topic):
		return "Откроется на уровне %d" % int(topic["required_level"])
	var cooldown: int = Progress.topic_cooldown_left(topic_id)
	if cooldown > 0:
		return "Тема остывает: %s" % Formulas.format_duration(cooldown)
	if Economy.energy < int(topic["energy_cost"]):
		return "Нет энергии. Следующая через %s" % Formulas.format_duration(Economy.seconds_to_next_energy())
	return ""


func start(topic_id: String) -> bool:
	if not block_reason(topic_id).is_empty():
		return false
	var topic: Dictionary = GameData.topic(topic_id)
	if not Economy.try_spend_energy(int(topic["energy_cost"])):
		return false
	_topic = topic
	_elapsed = 0.0
	_taps = 0
	_duration = maxf(GameData.num("shoot_duration_seconds"), 0.5)
	is_shooting = true
	set_process(true)
	shoot_started.emit(_topic)
	shoot_progress.emit(0.0, 0.0)
	return true


func register_tap() -> void:
	if not is_shooting:
		return
	_taps += 1
	shoot_progress.emit(clampf(_elapsed / _duration, 0.0, 1.0), quality01())


func quality01() -> float:
	return clampf(float(_taps) / maxf(GameData.num("shoot_taps_for_max_quality"), 1.0), 0.0, 1.0)


func _process(delta: float) -> void:
	_elapsed += delta
	shoot_progress.emit(clampf(_elapsed / _duration, 0.0, 1.0), quality01())
	if _elapsed >= _duration:
		_finish()


func _finish() -> void:
	set_process(false)
	is_shooting = false
	var quality: float = quality01()
	var power: float = float(_topic["reach_power"])
	var viral: bool = _rng.randf() < Formulas.viral_chance(quality)
	var views: float = Formulas.views(power, Progress.subscribers, Economy.reach_multiplier(), quality, viral)
	var coins: float = Formulas.video_coins(power, Economy.income_multiplier(), quality, viral, views)
	var subs: float = Formulas.subscribers_gain(views, _rng)
	var xp_gain: float = Formulas.video_xp(power, quality, viral)
	Economy.add_coins(coins)
	var levels: int = Progress.apply_video(str(_topic["id"]), views, subs, xp_gain)
	Save.save_now()
	shoot_finished.emit({
		"topic_id": str(_topic["id"]),
		"topic_name": str(_topic["name"]),
		"quality": quality,
		"viral": viral,
		"views": views,
		"coins": coins,
		"subscribers": subs,
		"xp": xp_gain,
		"levels_gained": levels,
		"level": Progress.level,
	})
