extends Node
## Сохранение в user://save.json: атомарная запись, .bak, время в UTC.

const SAVE_PATH: String = "user://save.json"
const BAK_PATH: String = "user://save.json.bak"
const TMP_PATH: String = "user://save.json.tmp"
const MAX_OFFLINE_SEC: int = 8 * 3600
const AUTOSAVE_SEC: float = 15.0

var data: Dictionary = {}
var seconds_away: int = 0
var is_new_game: bool = true

var _timer: float = 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	data = _read(SAVE_PATH)
	if data.is_empty():
		data = _read(BAK_PATH)
		if not data.is_empty():
			push_warning("Save: загружена резервная копия")
	if data.is_empty():
		is_new_game = true
		seconds_away = 0
	else:
		is_new_game = false
		var last: int = int(data.get("last_seen", now_utc()))
		seconds_away = clampi(now_utc() - last, 0, MAX_OFFLINE_SEC)


func _process(delta: float) -> void:
	_timer += delta
	if _timer >= AUTOSAVE_SEC:
		_timer = 0.0
		save_now()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_now()


static func now_utc() -> int:
	return int(Time.get_unix_time_from_system())


func get_state() -> Dictionary:
	return data


func save_now() -> void:
	data["last_seen"] = now_utc()
	var file: FileAccess = FileAccess.open(TMP_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(data))
	file.close()
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.copy_absolute(SAVE_PATH, BAK_PATH)
	DirAccess.rename_absolute(TMP_PATH, SAVE_PATH)


func _read(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var text: String = FileAccess.get_file_as_string(path)
	if text.is_empty():
		return {}
	var json: JSON = JSON.new()
	if json.parse(text) != OK:
		return {}
	var parsed: Variant = json.data
	if parsed is Dictionary:
		return parsed as Dictionary
	return {}
