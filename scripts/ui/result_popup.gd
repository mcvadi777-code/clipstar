extends Control
## Итог ролика: просмотры, монеты, подписчики, опыт, качество съёмки, «вирусный» баннер и новый уровень.

signal closed

const Formulas := preload("res://scripts/gameplay/formulas.gd")

@onready var _title_label: Label = %ResultTitle
@onready var _viral_label: Label = %ViralLabel
@onready var _views_label: Label = %ViewsLabel
@onready var _coins_label: Label = %ResultCoinsLabel
@onready var _subs_label: Label = %ResultSubsLabel
@onready var _xp_label: Label = %XpLabel
@onready var _quality_label: Label = %QualityLabel
@onready var _level_label: Label = %ResultLevelLabel
@onready var _ok_button: Button = %OkButton


func _ready() -> void:
	visible = false
	_ok_button.pressed.connect(_on_ok)


func show_result(result: Dictionary) -> void:
	_title_label.text = "«%s» опубликован!" % str(result["topic_name"])
	_viral_label.visible = bool(result["viral"])
	_viral_label.text = "Ролик залетел в рекомендации!"
	_views_label.text = "Просмотры: %s" % Formulas.format_number(float(result["views"]))
	_coins_label.text = "Монеты: +%s" % Formulas.format_number(float(result["coins"]))
	_subs_label.text = "Подписчики: +%s" % Formulas.format_number(float(result["subscribers"]))
	_xp_label.text = "Опыт: +%d" % int(roundf(float(result["xp"])))
	_quality_label.text = "Качество съёмки: %d%%" % int(roundf(float(result["quality"]) * 100.0))
	var levels: int = int(result["levels_gained"])
	_level_label.visible = levels > 0
	_level_label.text = "Новый уровень канала: %d" % int(result["level"])
	visible = true
	Audio.play("level_up" if levels > 0 else "success")


func _on_ok() -> void:
	Audio.play("click")
	visible = false
	closed.emit()
