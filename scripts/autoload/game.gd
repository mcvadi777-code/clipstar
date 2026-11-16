extends Node
## Состояние и экономика игры. UI только подписывается на сигналы.

signal stats_changed
signal task_changed
signal stage_changed(stage: int)
signal float_text(text: String, color: Color)
signal offline_ready(amount: float)

var BASE_INCOME: float = 0.4
var ENERGY_MAX: int = 20
var ENERGY_RESTORE_SEC: float = 45.0
var STAGE_FOLLOWERS: Array = [0.0, 20.0, 100.0, 500.0, 2000.0]

var UPGRADES: Dictionary = {
	"camera": {"name": "Камера", "desc": "+0.35 к доходу в секунду", "base": 30.0, "growth": 1.55, "add": 0.35},
	"light": {"name": "Свет", "desc": "+0.25 к доходу в секунду", "base": 80.0, "growth": 1.60, "add": 0.25},
	"desk": {"name": "Стол", "desc": "+0.20 к доходу в секунду", "base": 200.0, "growth": 1.65, "add": 0.20},
	"edit": {"name": "Монтаж", "desc": "+0.50 к доходу в секунду", "base": 600.0, "growth": 1.70, "add": 0.50},
}

var TASKS: Array = [
	{"title": "Заработай первые $100", "kind": "earned", "target": 100.0, "reward": 60.0},
	{"title": "Улучши камеру до 2 уровня", "kind": "camera", "target": 2.0, "reward": 150.0},
	{"title": "Сними 3 ролика", "kind": "videos", "target": 3.0, "reward": 250.0},
	{"title": "Набери 100 подписчиков", "kind": "followers", "target": 100.0, "reward": 600.0},
	{"title": "Улучши свет до 3 уровня", "kind": "light", "target": 3.0, "reward": 1500.0},
	{"title": "Заработай $5 000 всего", "kind": "earned", "target": 5000.0, "reward": 2500.0},
]

var money: float = 0.0
var followers: float = 0.0
var videos: int = 0
var energy: int = ENERGY_MAX
var total_earned: float = 0.0
var upgrades: Dictionary = {"camera": 0, "light": 0, "desk": 0, "edit": 0}
var task_index: int = 0
var stage: int = 0
var offline_gain: float = 0.0
var boost_until: int = 0
var piggy: float = 0.0
var DEV_MONEY: float = 0.0
var DEV_FOLLOWERS: float = 0.0

var _energy_progress: float = 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_state()
	if Save.is_new_game:
		money += DEV_MONEY
		total_earned += DEV_MONEY
		followers += DEV_FOLLOWERS
	stage = stage_for_followers()
	if Save.seconds_away > 30:
		offline_gain = per_sec() * float(Save.seconds_away)
		if offline_gain > 0.5:
			money += offline_gain
			total_earned += offline_gain
			call_deferred("emit_signal", "offline_ready", offline_gain)
	call_deferred("emit_signal", "stats_changed")


func _process(delta: float) -> void:
	var gain: float = per_sec() * delta
	money += gain
	total_earned += gain
	piggy = minf(piggy + gain * 0.1, 5000.0)
	if energy < ENERGY_MAX:
		_energy_progress += delta
		if _energy_progress >= ENERGY_RESTORE_SEC:
			_energy_progress = 0.0
			energy += 1
			emit_signal("stats_changed")
	_check_tasks()
	var new_stage: int = stage_for_followers()
	if new_stage != stage:
		stage = new_stage
		emit_signal("stage_changed", stage)


func per_sec() -> float:
	var value: float = BASE_INCOME
	if is_boost():
		value *= 2.0
	for id: String in UPGRADES.keys():
		var level: int = int(upgrades.get(id, 0))
		value += float((UPGRADES[id] as Dictionary)["add"]) * float(level)
	return value


func is_boost() -> bool:
	return Save.now_utc() < boost_until


func boost_left() -> int:
	return maxi(boost_until - Save.now_utc(), 0)


func start_boost() -> void:
	boost_until = Save.now_utc() + 900
	emit_signal("stats_changed")
	emit_signal("float_text", "Буст x2 на 15 минут", Color(1.0, 0.72, 0.3))


func claim_piggy() -> float:
	var value: float = piggy
	piggy = 0.0
	money += value
	total_earned += value
	emit_signal("stats_changed")
	return value


func tap_value() -> float:
	return maxf(1.0, per_sec() * 0.6)


func do_tap() -> void:
	var gain: float = tap_value()
	money += gain
	total_earned += gain
	emit_signal("float_text", "+$" + format_money(gain), Color(0.55, 0.92, 0.62))
	emit_signal("stats_changed")


func can_shoot() -> bool:
	return energy > 0


func shoot() -> Dictionary:
	if energy <= 0:
		emit_signal("float_text", "Нет энергии", Color(1.0, 0.55, 0.6))
		return {}
	energy -= 1
	videos += 1
	var views: float = 40.0 + followers * 0.08 + per_sec() * 25.0
	var gain: float = maxf(2.0, per_sec() * (6.0 + randf() * 6.0))
	var new_followers: float = views * (0.06 + randf() * 0.05)
	money += gain
	total_earned += gain
	followers += new_followers
	emit_signal("stats_changed")
	return {"views": views, "money": gain, "followers": new_followers}


func upgrade_cost(id: String) -> float:
	var info: Dictionary = UPGRADES[id] as Dictionary
	var level: int = int(upgrades.get(id, 0))
	return float(info["base"]) * pow(float(info["growth"]), float(level))


func upgrade_level(id: String) -> int:
	return int(upgrades.get(id, 0))


func buy_upgrade(id: String) -> bool:
	if not UPGRADES.has(id):
		return false
	var cost: float = upgrade_cost(id)
	if money < cost:
		emit_signal("float_text", "Не хватает денег", Color(1.0, 0.55, 0.6))
		return false
	money -= cost
	upgrades[id] = int(upgrades.get(id, 0)) + 1
	emit_signal("stats_changed")
	emit_signal("float_text", (UPGRADES[id] as Dictionary)["name"] + " улучшена", Color(0.62, 0.78, 1.0))
	return true


func current_task() -> Dictionary:
	if task_index >= TASKS.size():
		return {}
	return TASKS[task_index] as Dictionary


func task_value(kind: String) -> float:
	match kind:
		"earned":
			return total_earned
		"videos":
			return float(videos)
		"followers":
			return followers
		"camera":
			return float(upgrade_level("camera"))
		"light":
			return float(upgrade_level("light"))
	return 0.0


func task_progress() -> Vector2:
	var task: Dictionary = current_task()
	if task.is_empty():
		return Vector2(0.0, 1.0)
	var target: float = float(task["target"])
	var value: float = task_value(str(task["kind"]))
	return Vector2(minf(value, target), target)


func _check_tasks() -> void:
	var task: Dictionary = current_task()
	if task.is_empty():
		return
	if task_value(str(task["kind"])) >= float(task["target"]):
		_claim_task(task)


func _claim_task(task: Dictionary) -> void:
	var reward: float = float(task["reward"])
	money += reward
	total_earned += reward
	task_index += 1
	emit_signal("task_changed")
	emit_signal("float_text", "Задача! +$" + format_money(reward), Color(1.0, 0.84, 0.4))
	emit_signal("stats_changed")


func stage_for_followers() -> int:
	var result: int = 0
	for i: int in STAGE_FOLLOWERS.size():
		if followers >= float(STAGE_FOLLOWERS[i]):
			result = i
	return result


func level() -> int:
	return 1 + int(followers / 100.0)


func level_progress() -> Vector2:
	var lvl: int = level()
	var cur: float = followers - float((lvl - 1) * 100)
	return Vector2(clampf(cur, 0.0, 100.0), 100.0)


static func format_money(value: float) -> String:
	if value < 1000.0:
		return "%.2f" % value
	if value < 1000000.0:
		return "%.2fK" % (value / 1000.0)
	if value < 1000000000.0:
		return "%.2fM" % (value / 1000000.0)
	return "%.2fB" % (value / 1000000000.0)


func save_state() -> void:
	var data: Dictionary = Save.get_state()
	data["money"] = money
	data["followers"] = followers
	data["videos"] = videos
	data["energy"] = energy
	data["total_earned"] = total_earned
	data["upgrades"] = upgrades.duplicate(true)
	data["task_index"] = task_index
	data["boost_until"] = boost_until
	data["piggy"] = piggy
	Save.save_now()


func _load_state() -> void:
	var data: Dictionary = Save.get_state()
	money = float(data.get("money", 0.0))
	followers = float(data.get("followers", 0.0))
	videos = int(data.get("videos", 0))
	energy = int(data.get("energy", ENERGY_MAX))
	total_earned = float(data.get("total_earned", 0.0))
	task_index = int(data.get("task_index", 0))
	boost_until = int(data.get("boost_until", 0))
	piggy = float(data.get("piggy", 0.0))
	var saved_up: Variant = data.get("upgrades", {})
	if saved_up is Dictionary:
		for id: String in UPGRADES.keys():
			upgrades[id] = int((saved_up as Dictionary).get(id, 0))


func reset_progress() -> void:
	money = 0.0
	followers = 0.0
	videos = 0
	energy = ENERGY_MAX
	total_earned = 0.0
	upgrades = {"camera": 0, "light": 0, "desk": 0, "edit": 0}
	task_index = 0
	stage = 0
	save_state()
	emit_signal("stats_changed")
	emit_signal("stage_changed", stage)
	emit_signal("task_changed")
