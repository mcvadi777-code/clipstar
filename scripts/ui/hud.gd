extends Control
## HUD поверх студии: монеты, доход/сек, подписчики, уровень и опыт, энергия,
## кнопки «Снять ролик», «Апгрейды», звук; панель съёмки с кнопкой «Фокус»; всплывающие подсказки.

signal shoot_pressed
signal upgrades_pressed
signal focus_tapped

const Formulas := preload("res://scripts/gameplay/formulas.gd")

@onready var _coins_label: Label = %CoinsLabel
@onready var _income_label: Label = %IncomeLabel
@onready var _subs_label: Label = %SubsLabel
@onready var _level_label: Label = %LevelLabel
@onready var _xp_bar: ProgressBar = %XpBar
@onready var _energy_label: Label = %EnergyLabel
@onready var _energy_timer_label: Label = %EnergyTimerLabel
@onready var _shoot_button: Button = %ShootButton
@onready var _upgrades_button: Button = %UpgradesButton
@onready var _sound_button: Button = %SoundButton
@onready var _shoot_panel: Control = %ShootPanel
@onready var _shoot_topic_label: Label = %ShootTopicLabel
@onready var _shoot_progress: ProgressBar = %ShootProgress
@onready var _quality_bar: ProgressBar = %QualityBar
@onready var _focus_button: Button = %FocusButton
@onready var _toast: Label = %Toast

var _toast_tween: Tween


func _ready() -> void:
	_shoot_button.pressed.connect(_on_shoot_button)
	_upgrades_button.pressed.connect(_on_upgrades_button)
	_sound_button.pressed.connect(_on_sound_button)
	_focus_button.pressed.connect(_on_focus_button)
	Economy.coins_changed.connect(_on_coins_changed)
	Economy.energy_changed.connect(_on_energy_changed)
	Progress.stats_changed.connect(_refresh_progress)
	_shoot_panel.visible = false
	_toast.visible = false
	_update_sound_button()
	_on_coins_changed(Economy.coins)
	_on_energy_changed(Economy.energy, Economy.energy_max(), Economy.seconds_to_next_energy())
	_refresh_progress()


func show_shooting(topic_name: String) -> void:
	_shoot_topic_label.text = "Снимаем: %s" % topic_name
	_shoot_progress.value = 0.0
	_quality_bar.value = 0.0
	_shoot_panel.visible = true
	_shoot_button.disabled = true
	_upgrades_button.disabled = true


func update_shooting(progress01: float, quality01: float) -> void:
	_shoot_progress.value = progress01 * 100.0
	_quality_bar.value = quality01 * 100.0


func hide_shooting() -> void:
	_shoot_panel.visible = false
	_shoot_button.disabled = false
	_upgrades_button.disabled = false


func show_toast(text: String) -> void:
	_toast.text = text
	_toast.visible = true
	_toast.modulate.a = 1.0
	if _toast_tween != null and _toast_tween.is_valid():
		_toast_tween.kill()
	_toast_tween = create_tween()
	_toast_tween.tween_interval(1.6)
	_toast_tween.tween_property(_toast, "modulate:a", 0.0, 0.4)
	_toast_tween.tween_callback(_toast.hide)


func _on_coins_changed(coins: float) -> void:
	_coins_label.text = "Монеты: %s" % Formulas.format_number(coins)
	_income_label.text = "+%s/с" % Formulas.format_number(Economy.passive_per_second()) if Economy.passive_per_second() >= 1.0 \
		else "+%.1f/с" % Economy.passive_per_second()


func _on_energy_changed(energy: int, energy_max: int, seconds_to_next: int) -> void:
	_energy_label.text = "Энергия: %d/%d" % [energy, energy_max]
	_energy_timer_label.text = "" if energy >= energy_max else "+1 через %s" % Formulas.format_duration(seconds_to_next)


func _refresh_progress() -> void:
	_subs_label.text = "Подписчики: %s" % Formulas.format_number(Progress.subscribers)
	_level_label.text = "Уровень %d" % Progress.level
	_xp_bar.max_value = Progress.xp_to_next_level()
	_xp_bar.value = Progress.xp


func _update_sound_button() -> void:
	_sound_button.text = "Звук: выкл" if Audio.muted else "Звук: вкл"


func _on_shoot_button() -> void:
	Audio.play("click")
	shoot_pressed.emit()


func _on_upgrades_button() -> void:
	Audio.play("click")
	upgrades_pressed.emit()


func _on_sound_button() -> void:
	Audio.toggle_muted()
	_update_sound_button()


func _on_focus_button() -> void:
	Audio.play("tap")
	focus_tapped.emit()
