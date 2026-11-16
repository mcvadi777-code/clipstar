extends Node
## Автозагрузка "Save".
## Хранит всё состояние игры в user://save.json.
## Формат файла: {"v": <версия схемы>, "sha": <sha256 от payload>, "payload": "<JSON-строка>"}.
## Запись атомарная: сначала .tmp, предыдущий файл уходит в .bak, затем .tmp переименовывается.
## Если основной файл повреждён, загружается .bak, если и он плох — чистый старт.
## Время — только UTC (Unix-секунды), поэтому смена часового пояса не ломает офлайн-доход.

signal loaded(data: Dictionary)
signal saved(timestamp_utc: int)

const SAVE_PATH: String = "user://save.json"
const TMP_PATH: String = "user://save.json.tmp"
const BAK_PATH: String = "user://save.json.bak"
const SCHEMA_VERSION: int = 1
const AUTOSAVE_INTERVAL_SEC: float = 30.0
## Если часы устройства ушли назад, офлайн-время не начисляем; вперёд — не больше этого предела.
const MAX_AWAY_SEC: int = 60 * 60 * 24 * 30

var data: Dictionary = {}
## Сколько секунд игрок отсутствовал на момент загрузки (UTC). 0 при первом запуске.
var seconds_away_on_load: int = 0
var is_new_game: bool = true

var _autosave_timer: Timer
var _dirty: bool = false
## true, если основной файл на диске проверен (читается и совпадает sha). Битый файл в .bak не копируем.
var _main_file_valid: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_from_disk()
	_autosave_timer = Timer.new()
	_autosave_timer.wait_time = AUTOSAVE_INTERVAL_SEC
	_autosave_timer.autostart = true
	_autosave_timer.timeout.connect(_on_autosave_timeout)
	add_child(_autosave_timer)
	loaded.emit(data)


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_WM_CLOSE_REQUEST:
			save_now()


static func now_utc() -> int:
	return int(Time.get_unix_time_from_system())


## Раздел состояния конкретного сервиса ("economy", "progress", ...). Возвращает копию.
func get_section(section: String) -> Dictionary:
	var value: Variant = data.get(section, {})
	if value is Dictionary:
		return (value as Dictionary).duplicate(true)
	return {}


## Сервис отдаёт свой раздел целиком; запись на диск — по таймеру или при сворачивании.
func set_section(section: String, value: Dictionary) -> void:
	data[section] = value.duplicate(true)
	_dirty = true


func save_now() -> bool:
	data["version"] = SCHEMA_VERSION
	data["last_seen_utc"] = now_utc()
	var payload: String = JSON.stringify(data, "", true, true)
	var envelope: Dictionary = {
		"v": SCHEMA_VERSION,
		"sha": payload.sha256_text(),
		"payload": payload,
	}
	var file: FileAccess = FileAccess.open(TMP_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Save: не удалось открыть %s (%s)" % [TMP_PATH, error_string(FileAccess.get_open_error())])
		return false
	file.store_string(JSON.stringify(envelope))
	file.flush()
	file.close()

	if _main_file_valid and FileAccess.file_exists(SAVE_PATH):
		var copy_err: Error = DirAccess.copy_absolute(SAVE_PATH, BAK_PATH)
		if copy_err != OK:
			push_warning("Save: резервная копия не создана (%s)" % error_string(copy_err))
	var rename_err: Error = DirAccess.rename_absolute(TMP_PATH, SAVE_PATH)
	if rename_err != OK:
		push_error("Save: не удалось записать %s (%s)" % [SAVE_PATH, error_string(rename_err)])
		return false
	_dirty = false
	_main_file_valid = true
	saved.emit(int(data["last_seen_utc"]))
	return true


## Полный сброс прогресса (кнопка в отладочном меню).
func reset() -> void:
	for path: String in [SAVE_PATH, BAK_PATH, TMP_PATH]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	data = _default_data()
	seconds_away_on_load = 0
	is_new_game = true
	save_now()
	loaded.emit(data)


func _on_autosave_timeout() -> void:
	if _dirty:
		save_now()


func _load_from_disk() -> void:
	var result: Dictionary = _read_envelope(SAVE_PATH)
	_main_file_valid = not result.is_empty()
	if result.is_empty():
		result = _read_envelope(BAK_PATH)
		if not result.is_empty():
			push_warning("Save: основной файл повреждён, загружена резервная копия")
	if result.is_empty():
		data = _default_data()
		is_new_game = true
		seconds_away_on_load = 0
		return
	data = _migrate(result)
	is_new_game = false
	var last_seen: int = int(data.get("last_seen_utc", now_utc()))
	seconds_away_on_load = clampi(now_utc() - last_seen, 0, MAX_AWAY_SEC)


## Возвращает payload как Dictionary или {} если файла нет / он битый.
func _read_envelope(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var text: String = FileAccess.get_file_as_string(path)
	if text.is_empty():
		return {}
	var envelope: Variant = _parse_json_quiet(text)
	if not envelope is Dictionary:
		return {}
	var env: Dictionary = envelope
	var payload: Variant = env.get("payload")
	if not payload is String:
		return {}
	if (payload as String).sha256_text() != str(env.get("sha", "")):
		return {}
	var parsed: Variant = _parse_json_quiet(payload as String)
	if not parsed is Dictionary:
		return {}
	return parsed


## JSON.parse_string печатает ERROR на битом вводе; здесь битый файл — штатная ситуация.
func _parse_json_quiet(text: String) -> Variant:
	var json: JSON = JSON.new()
	if json.parse(text) != OK:
		return null
	return json.data


func _default_data() -> Dictionary:
	return {
		"version": SCHEMA_VERSION,
		"created_utc": now_utc(),
		"last_seen_utc": now_utc(),
	}


## Миграции схемы сейва. JSON хранит числа как float, поэтому версии приводим к int.
func _migrate(loaded_data: Dictionary) -> Dictionary:
	var version: int = int(loaded_data.get("version", 0))
	if version < 1:
		loaded_data["created_utc"] = int(loaded_data.get("created_utc", now_utc()))
		version = 1
	loaded_data["version"] = version
	return loaded_data
