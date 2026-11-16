extends Node
## Автозагрузка "Progress": подписчики, опыт, уровень канала, статистика, кулдауны тем.
## Своё состояние хранит в разделе "progress" сейва (Save идёт в автозагрузке раньше).

signal stats_changed
signal level_up(new_level: int)

const Formulas := preload("res://scripts/gameplay/formulas.gd")
const GameData := preload("res://scripts/data/game_data.gd")
const SECTION: String = "progress"

var subscribers: float = 0.0
var xp: float = 0.0
var level: int = 1
var total_views: float = 0.0
var videos_made: int = 0
## Рекорд просмотров одного ролика — для полосы на экране итога.
var best_views: float = 0.0
## topic_id → UTC-время, когда тема снова доступна.
var topic_ready_utc: Dictionary = {}


func _ready() -> void:
	_apply_section(Save.get_section(SECTION))
	Save.loaded.connect(_on_save_loaded)


func xp_to_next_level() -> float:
	return Formulas.xp_to_next_level(level)


func is_topic_unlocked(topic: Dictionary) -> bool:
	return level >= int(topic["required_level"])


func topic_cooldown_left(topic_id: String) -> int:
	var ready_at: int = int(topic_ready_utc.get(topic_id, 0))
	return maxi(ready_at - Save.now_utc(), 0)


## Применяет итог ролика. Возвращает число полученных уровней.
func apply_video(topic_id: String, views: float, subscribers_gain: float, xp_gain: float) -> int:
	var topic: Dictionary = GameData.topic(topic_id)
	subscribers += subscribers_gain
	total_views += views
	videos_made += 1
	best_views = maxf(best_views, views)
	xp += xp_gain
	if not topic.is_empty():
		topic_ready_utc[topic_id] = Save.now_utc() + int(topic["cooldown_seconds"])
	var gained_levels: int = 0
	while xp >= xp_to_next_level():
		xp -= xp_to_next_level()
		level += 1
		gained_levels += 1
		level_up.emit(level)
	_commit()
	return gained_levels


func _commit() -> void:
	Save.set_section(SECTION, {
		"subscribers": subscribers,
		"xp": xp,
		"level": level,
		"total_views": total_views,
		"videos_made": videos_made,
		"best_views": best_views,
		"topic_ready_utc": topic_ready_utc,
	})
	stats_changed.emit()


func _apply_section(section: Dictionary) -> void:
	subscribers = maxf(float(section.get("subscribers", 0.0)), 0.0)
	xp = maxf(float(section.get("xp", 0.0)), 0.0)
	level = maxi(int(section.get("level", 1)), 1)
	total_views = maxf(float(section.get("total_views", 0.0)), 0.0)
	videos_made = maxi(int(section.get("videos_made", 0)), 0)
	best_views = maxf(float(section.get("best_views", 0.0)), 0.0)
	topic_ready_utc = {}
	var raw_cooldowns: Variant = section.get("topic_ready_utc", {})
	if raw_cooldowns is Dictionary:
		for key: Variant in (raw_cooldowns as Dictionary).keys():
			topic_ready_utc[str(key)] = int((raw_cooldowns as Dictionary)[key])
	stats_changed.emit()


func _on_save_loaded(_data: Dictionary) -> void:
	_apply_section(Save.get_section(SECTION))
