extends RefCounted
## Статические данные игры из res://assets/data/*.json.
## Загружаются один раз (статические переменные общие для всех, кто сделал preload этого скрипта).
## Если json битый или в нём не хватает поля, берётся значение из DEFAULT_BALANCE и пишется ошибка в лог —
## игра не падает из-за опечатки в балансе.

const BALANCE_PATH: String = "res://assets/data/balance.json"
const TOPICS_PATH: String = "res://assets/data/topics.json"
const UPGRADES_PATH: String = "res://assets/data/upgrades.json"

const DEFAULT_BALANCE: Dictionary = {
	"start_coins": 0.0,
	"energy_max": 20.0,
	"energy_regen_seconds": 180.0,
	"energy_per_video": 1.0,
	"base_views": 120.0,
	"subscriber_reach": 0.3,
	"base_video_income": 10.0,
	"coins_per_view": 0.05,
	"subscribers_from_views_min": 0.02,
	"subscribers_from_views_max": 0.05,
	"xp_base": 100.0,
	"xp_growth": 1.6,
	"xp_per_video": 40.0,
	"viral_chance_min": 0.05,
	"viral_chance_max": 0.15,
	"viral_multiplier": 8.0,
	"quality_multiplier_min": 0.6,
	"quality_multiplier_max": 1.5,
	"shoot_duration_seconds": 4.0,
	"shoot_taps_for_max_quality": 12.0,
	"passive_base_per_second": 0.2,
	"passive_per_subscriber_per_second": 0.002,
	"offline_max_hours": 8.0,
	"offline_efficiency": 0.5,
	"offline_min_seconds_to_show": 60.0,
}

const TOPIC_KEYS: Array[String] = ["id", "name", "reach_power", "cooldown_seconds", "required_level", "energy_cost"]
const UPGRADE_KEYS: Array[String] = ["id", "name", "base_cost", "cost_growth", "max_level", "reach_bonus_per_level", "income_bonus_per_level"]

static var _loaded: bool = false
static var _balance: Dictionary = {}
static var _topics: Array[Dictionary] = []
static var _upgrades: Array[Dictionary] = []


static func ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true
	_balance = DEFAULT_BALANCE.duplicate()
	var raw_balance: Variant = _read_json(BALANCE_PATH)
	if raw_balance is Dictionary:
		for key: String in DEFAULT_BALANCE.keys():
			var value: Variant = (raw_balance as Dictionary).get(key)
			if value is float or value is int:
				_balance[key] = float(value)
			else:
				push_error("GameData: в balance.json нет числа '%s', взято значение по умолчанию" % key)
	else:
		push_error("GameData: balance.json не прочитан, используются значения по умолчанию")
	_topics = _read_entries(TOPICS_PATH, TOPIC_KEYS)
	_upgrades = _read_entries(UPGRADES_PATH, UPGRADE_KEYS)


## Числовой параметр баланса.
static func num(key: String) -> float:
	ensure_loaded()
	if not _balance.has(key):
		push_error("GameData: неизвестный параметр баланса '%s'" % key)
		return 0.0
	return float(_balance[key])


static func topics() -> Array[Dictionary]:
	ensure_loaded()
	return _topics


static func topic(id: String) -> Dictionary:
	ensure_loaded()
	for entry: Dictionary in _topics:
		if str(entry["id"]) == id:
			return entry
	return {}


static func upgrades() -> Array[Dictionary]:
	ensure_loaded()
	return _upgrades


static func upgrade(id: String) -> Dictionary:
	ensure_loaded()
	for entry: Dictionary in _upgrades:
		if str(entry["id"]) == id:
			return entry
	return {}


static func _read_entries(path: String, required_keys: Array[String]) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var raw: Variant = _read_json(path)
	if not raw is Array:
		push_error("GameData: %s должен быть массивом" % path)
		return result
	for item: Variant in raw as Array:
		if not item is Dictionary:
			push_error("GameData: в %s элемент не объект, пропущен" % path)
			continue
		var entry: Dictionary = item
		var ok: bool = true
		for key: String in required_keys:
			if not entry.has(key):
				push_error("GameData: в %s у '%s' нет поля '%s', элемент пропущен" % [path, str(entry.get("id", "?")), key])
				ok = false
		if ok:
			result.append(entry)
	return result


static func _read_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		push_error("GameData: файл %s не найден (проверь include_filter=*.json в пресете экспорта)" % path)
		return null
	var json: JSON = JSON.new()
	var err: Error = json.parse(FileAccess.get_file_as_string(path))
	if err != OK:
		push_error("GameData: %s, строка %d: %s" % [path, json.get_error_line(), json.get_error_message()])
		return null
	return json.data
