extends Control
## HUD поверх студии.
## Верх: монеты (со свечением) и доход/с с кнопкой «откуда доход», подписчики, энергия, уровень с полосой опыта.
## Низ: панель съёмки (тикающие просмотры, прогресс, качество, кнопка «Фокус!»), «Снять ролик», «Апгрейды», звук.
## Сок: вспышка, всплывающие цифры, партиклы сердечек и лайков, подсказки-тосты.
## Отступы от краёв учитывают безопасную зону экрана (вырез, жестовая панель).

signal shoot_pressed
signal upgrades_pressed
signal focus_tapped

const Formulas := preload("res://scripts/gameplay/formulas.gd")
const UiFx := preload("res://scripts/fx/ui_fx.gd")
const ICON_COIN: Texture2D = preload("res://assets/icons/coin.svg")
const ICON_USER: Texture2D = preload("res://assets/icons/user.svg")
const ICON_STAR: Texture2D = preload("res://assets/icons/star.svg")
const ICON_SOUND_ON: Texture2D = preload("res://assets/icons/sound_on.svg")
const ICON_SOUND_OFF: Texture2D = preload("res://assets/icons/sound_off.svg")
const BASE_MARGIN_SIDE: int = 28
const BASE_MARGIN_TOP: int = 36
const BASE_MARGIN_BOTTOM: int = 56

@onready var _safe: MarginContainer = %Safe
@onready var _coins_label: Label = %CoinsLabel
@onready var _coin_box: Control = %CoinBox
@onready var _income_button: Button = %IncomeButton
@onready var _income_info: PanelContainer = %IncomeInfo
@onready var _income_info_label: Label = %IncomeInfoLabel
@onready var _subs_label: Label = %SubsLabel
@onready var _level_label: Label = %LevelLabel
@onready var _xp_bar: ProgressBar = %XpBar
@onready var _xp_label: Label = %XpLabel
@onready var _energy_label: Label = %EnergyLabel
@onready var _energy_timer_label: Label = %EnergyTimerLabel
@onready var _shoot_button: Button = %ShootButton
@onready var _upgrades_button: Button = %UpgradesButton
@onready var _sound_button: Button = %SoundButton
@onready var _shoot_panel: Control = %ShootPanel
@onready var _shoot_topic_label: Label = %ShootTopicLabel
@onready var _live_views_label: Label = %LiveViewsLabel
@onready var _shoot_progress: ProgressBar = %ShootProgress
@onready var _quality_bar: ProgressBar = %QualityBar
@onready var _focus_button: Button = %FocusButton
@onready var _toast: Label = %Toast
@onready var _float_layer: Control = %FloatLayer
@onready var _hearts_stream: CPUParticles2D = %HeartsStream
@onready var _heart_burst: CPUParticles2D = %HeartBurst
@onready var _like_burst: CPUParticles2D = %LikeBurst
@onready var _flash: ColorRect = %Flash

var _toast_tween: Tween
var _flash_tween: Tween
var _shown_coins: float = -1.0
var _last_tick_views: float = 0.0


func _ready() -> void:
	_shoot_button.pressed.connect(_on_shoot_button)
	_upgrades_button.pressed.connect(_on_upgrades_button)
	_sound_button.pressed.connect(_on_sound_button)
	_focus_button.pressed.connect(_on_focus_button)
	_income_button.pressed.connect(_toggle_income_info)
	Economy.coins_changed.connect(_on_coins_changed)
	Economy.energy_changed.connect(_on_energy_changed)
	Economy.upgrade_changed.connect(_on_upgrade_changed)
	Progress.stats_changed.connect(_refresh_progress)
	resized.connect(_layout_effects)
	get_viewport().size_changed.connect(_apply_safe_area)
	UiFx.apply_press_feedback(self)
	_shoot_panel.visible = false
	_income_info.visible = false
	_toast.visible = false
	_set_flash(0.0)
	_hearts_stream.emitting = false
	_apply_safe_area()
	_layout_effects()
	_update_sound_button()
	_on_coins_changed(Economy.coins)
	_on_energy_changed(Economy.energy, Economy.energy_max(), Economy.seconds_to_next_energy())
	_refresh_progress()


# --- Съёмка -----------------------------------------------------------------

func show_shooting(topic_name: String) -> void:
	_shoot_topic_label.text = "Снимаем: %s" % topic_name
	_live_views_label.text = "0"
	_last_tick_views = 0.0
	_shoot_progress.value = 0.0
	_quality_bar.value = 0.0
	_shoot_panel.visible = true
	_shoot_button.visible = false
	_upgrades_button.disabled = true
	_income_info.visible = false
	_hearts_stream.emitting = true
	UiFx.pop(_shoot_panel, 1.05)


func update_shooting(progress01: float, quality01: float, live_views: float) -> void:
	_shoot_progress.value = progress01 * 100.0
	_quality_bar.value = quality01 * 100.0
	_live_views_label.text = Formulas.format_number(live_views)
	if live_views - _last_tick_views >= maxf(5.0, live_views * 0.08):
		_last_tick_views = live_views
		Audio.play("tick", 1.0 + progress01 * 0.5)
	_hearts_stream.amount = 6
	_hearts_stream.speed_scale = 0.8 + quality01 * 1.2


func hide_shooting() -> void:
	_shoot_panel.visible = false
	_shoot_button.visible = true
	_upgrades_button.disabled = false
	_hearts_stream.emitting = false


func pulse_quality() -> void:
	UiFx.pop(_quality_bar, 1.08)


# --- Сок --------------------------------------------------------------------

func flash(strength: float = 0.8) -> void:
	if _flash_tween != null and _flash_tween.is_valid():
		_flash_tween.kill()
	_set_flash(strength)
	_flash_tween = create_tween()
	_flash_tween.tween_method(_set_flash, strength, 0.0, 0.45).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)


func burst_reactions() -> void:
	_heart_burst.restart()
	_like_burst.restart()


## Всплывающая цифра «+22 монеты» с иконкой: вылетает вверх, пружинит и тает.
func spawn_float(text: String, icon: Texture2D, color: Color, start: Vector2, delay: float = 0.0) -> void:
	var row: HBoxContainer = HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 8)
	var tex: TextureRect = TextureRect.new()
	tex.texture = icon
	tex.custom_minimum_size = Vector2(52, 52)
	tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var label: Label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 44)
	label.add_theme_color_override("font_color", color)
	label.add_theme_constant_override("outline_size", 12)
	row.add_child(tex)
	row.add_child(label)
	row.modulate.a = 0.0
	_float_layer.add_child(row)
	row.reset_size()
	row.position = start - row.size * 0.5
	row.pivot_offset = row.size * 0.5
	row.scale = Vector2.ONE * 0.4
	var tween: Tween = row.create_tween()
	tween.tween_interval(delay)
	tween.tween_property(row, "modulate:a", 1.0, 0.01)
	tween.parallel().tween_property(row, "scale", Vector2.ONE * 1.2, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(row, "scale", Vector2.ONE, 0.12)
	tween.parallel().tween_property(row, "position:y", row.position.y - 170.0, 1.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(row, "modulate:a", 0.0, 0.3)
	tween.tween_callback(row.queue_free)


func float_origin() -> Vector2:
	return Vector2(size.x * 0.5, size.y * 0.52)


func show_toast(text: String) -> void:
	_toast.text = text
	_toast.visible = true
	_toast.modulate.a = 1.0
	UiFx.pop(_toast, 1.1)
	if _toast_tween != null and _toast_tween.is_valid():
		_toast_tween.kill()
	_toast_tween = create_tween()
	_toast_tween.tween_interval(1.8)
	_toast_tween.tween_property(_toast, "modulate:a", 0.0, 0.4)
	_toast_tween.tween_callback(_toast.hide)


# --- Обновление значений ----------------------------------------------------

func _on_coins_changed(coins: float) -> void:
	_coins_label.text = Formulas.format_number(coins)
	_income_button.text = "+%s/с" % Formulas.format_rate(Economy.passive_per_second())
	if _shown_coins >= 0.0 and coins - _shown_coins >= 10.0:
		UiFx.pop(_coin_box, 1.2)
	_shown_coins = coins
	if _income_info.visible:
		_refresh_income_info()


func _on_energy_changed(energy: int, energy_max: int, seconds_to_next: int) -> void:
	_energy_label.text = "%d/%d" % [energy, energy_max]
	_energy_timer_label.text = "" if energy >= energy_max else "+1 через %s" % Formulas.format_duration(seconds_to_next)


func _on_upgrade_changed(_upgrade_id: String, _level: int) -> void:
	if _income_info.visible:
		_refresh_income_info()


func _refresh_progress() -> void:
	_subs_label.text = Formulas.format_number(Progress.subscribers)
	_level_label.text = "Ур. %d" % Progress.level
	var need: float = Progress.xp_to_next_level()
	_xp_bar.max_value = need
	_xp_bar.value = Progress.xp
	_xp_label.text = "до уровня %d: %d/%d XP" % [Progress.level + 1, int(Progress.xp), int(ceilf(need))]


func _toggle_income_info() -> void:
	Audio.play("click")
	_income_info.visible = not _income_info.visible
	if _income_info.visible:
		_refresh_income_info()
		UiFx.pop(_income_info, 1.04)


func _refresh_income_info() -> void:
	var b: Dictionary = Economy.passive_breakdown()
	_income_info_label.text = "\n".join([
		"Пассивный доход канала — старые ролики продолжают смотреть:",
		"• база: %s/с" % Formulas.format_rate(float(b["base"])),
		"• подписчики: %s × %s = %s/с" % [Formulas.format_number(float(b["subscribers"])), str(b["per_subscriber"]), Formulas.format_rate(float(b["from_subscribers"]))],
		"• апгрейды дохода (камера, стол): ×%.2f" % float(b["income_multiplier"]),
		"Итого: %s/с" % Formulas.format_rate(float(b["total"])),
		"Офлайн: %d%% от этого, до %d ч." % [int(float(b["offline_efficiency"]) * 100.0), int(float(b["offline_max_hours"]))],
		"Ролики дают основной доход — снимай!",
	])


# --- Кнопки -----------------------------------------------------------------

func _update_sound_button() -> void:
	_sound_button.icon = ICON_SOUND_OFF if Audio.muted else ICON_SOUND_ON


func _on_shoot_button() -> void:
	Audio.play("click")
	shoot_pressed.emit()


func _on_upgrades_button() -> void:
	Audio.play("click")
	_income_info.visible = false
	upgrades_pressed.emit()


func _on_sound_button() -> void:
	Audio.toggle_muted()
	_update_sound_button()


func _on_focus_button() -> void:
	Audio.play("tap", 0.9 + _quality_bar.value / 100.0 * 0.6)
	focus_tapped.emit()


# --- Раскладка --------------------------------------------------------------

func _set_flash(amount: float) -> void:
	(_flash.material as ShaderMaterial).set_shader_parameter("amount", amount)
	_flash.visible = amount > 0.001


func _layout_effects() -> void:
	var center: Vector2 = Vector2(size.x * 0.5, size.y * 0.5)
	_hearts_stream.position = Vector2(size.x * 0.5, size.y * 0.62)
	_heart_burst.position = center
	_like_burst.position = center


## Отступы = базовые + безопасная зона экрана (в координатах вьюпорта).
func _apply_safe_area() -> void:
	var top: float = BASE_MARGIN_TOP
	var bottom: float = BASE_MARGIN_BOTTOM
	var screen_size: Vector2i = DisplayServer.screen_get_size()
	var safe: Rect2i = DisplayServer.get_display_safe_area()
	var viewport_size: Vector2 = get_viewport_rect().size
	if screen_size.y > 0 and safe.size.y > 0 and OS.has_feature("mobile"):
		var k: float = viewport_size.y / float(screen_size.y)
		top += float(safe.position.y) * k
		bottom += float(screen_size.y - safe.end.y) * k
	_safe.add_theme_constant_override("margin_left", BASE_MARGIN_SIDE)
	_safe.add_theme_constant_override("margin_right", BASE_MARGIN_SIDE)
	_safe.add_theme_constant_override("margin_top", int(top))
	_safe.add_theme_constant_override("margin_bottom", int(bottom))
