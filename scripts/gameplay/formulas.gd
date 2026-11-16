extends RefCounted
## Все формулы экономики в одном месте (те же, что в первом ТЗ). Только чистые функции, без состояния.

const GameData := preload("res://scripts/data/game_data.gd")

const SUFFIXES: Array[String] = ["", "K", "M", "B", "T", "Qa", "Qi"]


## Качество съёмки 0..1 → множитель 0.6..1.5.
static func quality_multiplier(quality01: float) -> float:
	return lerpf(GameData.num("quality_multiplier_min"), GameData.num("quality_multiplier_max"), clampf(quality01, 0.0, 1.0))


## Шанс «взрыва» ролика: 5% при плохой съёмке, 15% при идеальной.
static func viral_chance(quality01: float) -> float:
	return lerpf(GameData.num("viral_chance_min"), GameData.num("viral_chance_max"), clampf(quality01, 0.0, 1.0))


static func _viral_k(viral: bool) -> float:
	return GameData.num("viral_multiplier") if viral else 1.0


## Просмотры = (base_views + подписчики * subscriber_reach) * сила темы * апгрейды охвата * качество * вирал.
static func views(reach_power: float, subscribers: float, reach_multiplier: float, quality01: float, viral: bool) -> float:
	var audience: float = GameData.num("base_views") + subscribers * GameData.num("subscriber_reach")
	return floorf(audience * reach_power * reach_multiplier * quality_multiplier(quality01) * _viral_k(viral))


## Монеты = base_income * апгрейды дохода * сила темы * качество * вирал + просмотры * coins_per_view * апгрейды дохода.
static func video_coins(reach_power: float, income_multiplier: float, quality01: float, viral: bool, video_views: float) -> float:
	var fixed: float = GameData.num("base_video_income") * income_multiplier * reach_power * quality_multiplier(quality01) * _viral_k(viral)
	var from_views: float = video_views * GameData.num("coins_per_view") * income_multiplier
	return floorf(fixed + from_views)


static func subscribers_gain(video_views: float, rng: RandomNumberGenerator) -> float:
	var share: float = rng.randf_range(GameData.num("subscribers_from_views_min"), GameData.num("subscribers_from_views_max"))
	return floorf(video_views * share)


static func video_xp(reach_power: float, quality01: float, viral: bool) -> float:
	return GameData.num("xp_per_video") * reach_power * quality_multiplier(quality01) * (2.0 if viral else 1.0)


## Опыт, нужный чтобы перейти с уровня level на level + 1.
static func xp_to_next_level(level: int) -> float:
	return GameData.num("xp_base") * pow(GameData.num("xp_growth"), float(maxi(level, 1) - 1))


## Пассивный доход в секунду: (база + подписчики * k) * апгрейды дохода.
static func passive_per_second(subscribers: float, income_multiplier: float) -> float:
	return (GameData.num("passive_base_per_second") + subscribers * GameData.num("passive_per_subscriber_per_second")) * income_multiplier


static func offline_cap_seconds() -> int:
	return int(GameData.num("offline_max_hours") * 3600.0)


## Офлайн-доход за seconds секунд (уже обрезанных лимитом): пассивный доход * КПД офлайна.
static func offline_coins(seconds: int, subscribers: float, income_multiplier: float) -> float:
	return floorf(float(seconds) * passive_per_second(subscribers, income_multiplier) * GameData.num("offline_efficiency"))


## Цена следующего уровня апгрейда: base_cost * cost_growth ^ текущий_уровень.
static func upgrade_cost(upgrade: Dictionary, current_level: int) -> float:
	return floorf(float(upgrade["base_cost"]) * pow(float(upgrade["cost_growth"]), float(current_level)))


## 950 → "950", 12 345 → "12.3K", 4 560 000 → "4.56M".
static func format_number(value: float) -> String:
	var v: float = absf(value)
	var sign_text: String = "-" if value < 0.0 else ""
	if v < 1000.0:
		return sign_text + str(int(floorf(v)))
	var tier: int = 0
	while v >= 1000.0 and tier < SUFFIXES.size() - 1:
		v /= 1000.0
		tier += 1
	var text: String
	if v >= 100.0:
		text = "%.0f" % floorf(v)
	elif v >= 10.0:
		text = "%.1f" % (floorf(v * 10.0) / 10.0)
	else:
		text = "%.2f" % (floorf(v * 100.0) / 100.0)
	return sign_text + text + SUFFIXES[tier]


## 3725 → "1 ч 2 мин", 95 → "1 мин 35 с".
static func format_duration(seconds: int) -> String:
	var s: int = maxi(seconds, 0)
	var hours: int = s / 3600
	var minutes: int = (s % 3600) / 60
	var secs: int = s % 60
	if hours > 0:
		return "%d ч %d мин" % [hours, minutes]
	if minutes > 0:
		return "%d мин %d с" % [minutes, secs]
	return "%d с" % secs
