extends Node
## Автозагрузка "Economy": монеты, энергия, уровни апгрейдов, пассивный и офлайн-доход.
## Все расчёты времени — по UTC (Save.now_utc()). Офлайн-доход считается при запуске
## из Save.seconds_away_on_load и хранится в сейве, пока игрок его не заберёт.

signal coins_changed(coins: float)
signal energy_changed(energy: int, energy_max: int, seconds_to_next: int)
signal upgrade_changed(upgrade_id: String, level: int)
signal offline_reward_ready(seconds: int, coins: float)

const Formulas := preload("res://scripts/gameplay/formulas.gd")
const GameData := preload("res://scripts/data/game_data.gd")
const SECTION: String = "economy"

var coins: float = 0.0
var energy: int = 0
var energy_updated_utc: int = 0
var upgrade_levels: Dictionary = {}
var pending_offline_seconds: int = 0
var pending_offline_coins: float = 0.0

var _tick: Timer


func _ready() -> void:
	_apply_section(Save.get_section(SECTION), Save.is_new_game)
	_accrue_offline(Save.seconds_away_on_load)
	_regen_energy()
	_commit()
	Save.loaded.connect(_on_save_loaded)
	_tick = Timer.new()
	_tick.wait_time = 1.0
	_tick.autostart = true
	_tick.timeout.connect(_on_tick)
	add_child(_tick)


func energy_max() -> int:
	return int(GameData.num("energy_max"))


func seconds_to_next_energy() -> int:
	if energy >= energy_max():
		return 0
	var regen: int = int(GameData.num("energy_regen_seconds"))
	return maxi(regen - (Save.now_utc() - energy_updated_utc), 0)


func try_spend_energy(amount: int) -> bool:
	_regen_energy()
	if energy < amount:
		return false
	if energy >= energy_max():
		energy_updated_utc = Save.now_utc()
	energy -= amount
	_commit()
	return true


func add_coins(amount: float) -> void:
	if amount <= 0.0:
		return
	coins += amount
	_commit()


func get_upgrade_level(upgrade_id: String) -> int:
	return int(upgrade_levels.get(upgrade_id, 0))


func is_upgrade_maxed(upgrade_id: String) -> bool:
	var upgrade: Dictionary = GameData.upgrade(upgrade_id)
	return upgrade.is_empty() or get_upgrade_level(upgrade_id) >= int(upgrade["max_level"])


func upgrade_cost(upgrade_id: String) -> float:
	var upgrade: Dictionary = GameData.upgrade(upgrade_id)
	if upgrade.is_empty():
		return INF
	return Formulas.upgrade_cost(upgrade, get_upgrade_level(upgrade_id))


func can_buy_upgrade(upgrade_id: String) -> bool:
	return not is_upgrade_maxed(upgrade_id) and coins >= upgrade_cost(upgrade_id)


func buy_upgrade(upgrade_id: String) -> bool:
	if not can_buy_upgrade(upgrade_id):
		return false
	coins -= upgrade_cost(upgrade_id)
	var new_level: int = get_upgrade_level(upgrade_id) + 1
	upgrade_levels[upgrade_id] = new_level
	_commit()
	upgrade_changed.emit(upgrade_id, new_level)
	Save.save_now()
	return true


## Множитель охвата: 1 + Σ(уровень * reach_bonus_per_level).
func reach_multiplier() -> float:
	var total: float = 1.0
	for upgrade: Dictionary in GameData.upgrades():
		total += float(get_upgrade_level(str(upgrade["id"]))) * float(upgrade["reach_bonus_per_level"])
	return total


## Множитель дохода: 1 + Σ(уровень * income_bonus_per_level).
func income_multiplier() -> float:
	var total: float = 1.0
	for upgrade: Dictionary in GameData.upgrades():
		total += float(get_upgrade_level(str(upgrade["id"]))) * float(upgrade["income_bonus_per_level"])
	return total


func passive_per_second() -> float:
	return Formulas.passive_per_second(Progress.subscribers, income_multiplier())


func has_pending_offline() -> bool:
	return pending_offline_coins >= 1.0 and pending_offline_seconds >= int(GameData.num("offline_min_seconds_to_show"))


## Забирает офлайн-доход. Возвращает сумму.
func claim_offline() -> float:
	var amount: float = pending_offline_coins
	pending_offline_coins = 0.0
	pending_offline_seconds = 0
	coins += amount
	_commit()
	Save.save_now()
	return amount


func _accrue_offline(seconds_away: int) -> void:
	if seconds_away <= 0:
		return
	var room: int = maxi(Formulas.offline_cap_seconds() - pending_offline_seconds, 0)
	var counted: int = mini(seconds_away, room)
	if counted <= 0:
		return
	pending_offline_seconds += counted
	pending_offline_coins += Formulas.offline_coins(counted, Progress.subscribers, income_multiplier())


func _regen_energy() -> void:
	var now: int = Save.now_utc()
	var max_e: int = energy_max()
	if energy >= max_e:
		energy = max_e
		energy_updated_utc = now
		return
	if now < energy_updated_utc:
		energy_updated_utc = now
		return
	var regen: int = maxi(int(GameData.num("energy_regen_seconds")), 1)
	var gained: int = (now - energy_updated_utc) / regen
	if gained <= 0:
		return
	energy = mini(energy + gained, max_e)
	energy_updated_utc = now if energy >= max_e else energy_updated_utc + gained * regen


func _on_tick() -> void:
	var before: int = energy
	_regen_energy()
	coins += passive_per_second()
	Save.set_section(SECTION, _to_section())
	coins_changed.emit(coins)
	if energy != before or energy < energy_max():
		energy_changed.emit(energy, energy_max(), seconds_to_next_energy())


func _commit() -> void:
	Save.set_section(SECTION, _to_section())
	coins_changed.emit(coins)
	energy_changed.emit(energy, energy_max(), seconds_to_next_energy())


func _to_section() -> Dictionary:
	return {
		"coins": coins,
		"energy": energy,
		"energy_updated_utc": energy_updated_utc,
		"upgrade_levels": upgrade_levels,
		"pending_offline_seconds": pending_offline_seconds,
		"pending_offline_coins": pending_offline_coins,
	}


func _apply_section(section: Dictionary, new_game: bool) -> void:
	if new_game or section.is_empty():
		coins = GameData.num("start_coins")
		energy = energy_max()
		energy_updated_utc = Save.now_utc()
		upgrade_levels = {}
		pending_offline_seconds = 0
		pending_offline_coins = 0.0
		return
	coins = maxf(float(section.get("coins", 0.0)), 0.0)
	energy = clampi(int(section.get("energy", energy_max())), 0, energy_max())
	energy_updated_utc = int(section.get("energy_updated_utc", Save.now_utc()))
	pending_offline_seconds = maxi(int(section.get("pending_offline_seconds", 0)), 0)
	pending_offline_coins = maxf(float(section.get("pending_offline_coins", 0.0)), 0.0)
	upgrade_levels = {}
	var raw_levels: Variant = section.get("upgrade_levels", {})
	if raw_levels is Dictionary:
		for key: Variant in (raw_levels as Dictionary).keys():
			upgrade_levels[str(key)] = maxi(int((raw_levels as Dictionary)[key]), 0)


## Сброс прогресса из отладки: Save.reset() шлёт loaded — начинаем с нуля.
func _on_save_loaded(_data: Dictionary) -> void:
	_apply_section(Save.get_section(SECTION), Save.is_new_game)
	_commit()
	for upgrade: Dictionary in GameData.upgrades():
		upgrade_changed.emit(str(upgrade["id"]), get_upgrade_level(str(upgrade["id"])))
	if has_pending_offline():
		offline_reward_ready.emit(pending_offline_seconds, pending_offline_coins)
