extends Control
## Короткий экран итога: просмотры тикают вверх и заполняют полосу (относительно рекорда канала),
## затем по очереди появляются монеты и подписчики, в конце — опыт, качество и новый уровень.
## Первое нажатие «Отлично!» во время анимации досчитывает всё сразу, второе — закрывает.

signal closed

const Formulas := preload("res://scripts/gameplay/formulas.gd")
const UiFx := preload("res://scripts/fx/ui_fx.gd")
const VIEWS_SECONDS: float = 1.3

@onready var _panel: Control = $Center/Panel
@onready var _title_label: Label = %ResultTitle
@onready var _viral_label: Label = %ViralLabel
@onready var _views_label: Label = %ViewsLabel
@onready var _views_bar: ProgressBar = %ViewsBar
@onready var _record_label: Label = %RecordLabel
@onready var _coins_row: Control = %CoinsRow
@onready var _coins_label: Label = %ResultCoinsLabel
@onready var _subs_row: Control = %SubsRow
@onready var _subs_label: Label = %ResultSubsLabel
@onready var _xp_label: Label = %XpLabel
@onready var _quality_label: Label = %QualityLabel
@onready var _level_label: Label = %ResultLevelLabel
@onready var _ok_button: Button = %OkButton

var _sequence: Tween
var _result: Dictionary = {}
var _animating: bool = false


func _ready() -> void:
	visible = false
	_ok_button.pressed.connect(_on_ok)
	UiFx.apply_press_feedback(self)


func show_result(result: Dictionary) -> void:
	_result = result
	var views: float = float(result["views"])
	var record: float = maxf(views, float(result.get("previous_best_views", 0.0)))
	_title_label.text = "«%s» опубликован!" % str(result["topic_name"])
	_viral_label.visible = bool(result["viral"])
	_viral_label.text = "Ролик залетел в рекомендации! x8"
	_views_label.text = "0"
	_views_bar.max_value = maxf(record, 1.0)
	_views_bar.value = 0.0
	_record_label.text = "Новый рекорд канала!" if bool(result.get("is_record", false)) else "Рекорд канала: %s" % Formulas.format_number(record)
	_record_label.modulate.a = 0.0
	_coins_label.text = "+%s %s" % [Formulas.format_number(float(result["coins"])), Formulas.plural_ru(float(result["coins"]), "монета", "монеты", "монет")]
	_subs_label.text = "+%s %s" % [Formulas.format_number(float(result["subscribers"])), Formulas.plural_ru(float(result["subscribers"]), "подписчик", "подписчика", "подписчиков")]
	_coins_row.modulate.a = 0.0
	_subs_row.modulate.a = 0.0
	_xp_label.text = "Опыт +%d · качество %d%%" % [int(roundf(float(result["xp"]))), int(roundf(float(result["quality"]) * 100.0))]
	_xp_label.modulate.a = 0.0
	_quality_label.text = _quality_comment(float(result["quality"]))
	_quality_label.modulate.a = 0.0
	var levels: int = int(result["levels_gained"])
	_level_label.visible = levels > 0
	_level_label.text = "Новый уровень канала: %d!" % int(result["level"])
	_level_label.modulate.a = 0.0
	visible = true
	UiFx.pop(_panel, 1.06)
	Audio.play("fanfare")
	_run_sequence(views)


func _run_sequence(views: float) -> void:
	_animating = true
	if _sequence != null and _sequence.is_valid():
		_sequence.kill()
	_sequence = create_tween()
	_sequence.tween_method(_set_views, 0.0, views, VIEWS_SECONDS).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_sequence.tween_property(_record_label, "modulate:a", 1.0, 0.15)
	_sequence.tween_callback(_reveal.bind(_coins_row, "cash"))
	_sequence.tween_interval(0.25)
	_sequence.tween_callback(_reveal.bind(_subs_row, "coin"))
	_sequence.tween_interval(0.25)
	_sequence.tween_property(_xp_label, "modulate:a", 1.0, 0.15)
	_sequence.tween_property(_quality_label, "modulate:a", 1.0, 0.15)
	_sequence.tween_callback(_reveal_level)
	_sequence.tween_callback(func() -> void: _animating = false)


func _set_views(value: float) -> void:
	var before: String = _views_label.text
	_views_label.text = Formulas.format_number(value)
	_views_bar.value = value
	if before != _views_label.text and Engine.get_process_frames() % 3 == 0:
		Audio.play("tick", 1.0 + clampf(value / maxf(_views_bar.max_value, 1.0), 0.0, 1.0) * 0.6)


func _reveal(row: Control, sound: String) -> void:
	row.modulate.a = 1.0
	UiFx.pop(row, 1.25)
	Audio.play(sound)


func _reveal_level() -> void:
	if _level_label.visible:
		_level_label.modulate.a = 1.0
		UiFx.pop(_level_label, 1.3)
		Audio.play("level_up")


func _finish_instantly() -> void:
	if _sequence != null and _sequence.is_valid():
		_sequence.kill()
	_set_views(float(_result.get("views", 0.0)))
	for item: Control in [_record_label, _coins_row, _subs_row, _xp_label, _quality_label, _level_label]:
		item.modulate.a = 1.0
	_animating = false


func _quality_comment(quality: float) -> String:
	if quality >= 0.85:
		return "Идеальный монтаж — зрители в восторге"
	if quality >= 0.5:
		return "Хороший кадр. Больше тапов — выше качество"
	return "Камера мазала фокус — тапай «Фокус!» чаще"


func _on_ok() -> void:
	if _animating:
		_finish_instantly()
		return
	Audio.play("click")
	visible = false
	closed.emit()
