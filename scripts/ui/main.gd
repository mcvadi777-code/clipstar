extends Node
## Корень главной сцены: связывает студию, HUD, окна и сервисы, режиссирует «сок» съёмки.

const HudScript := preload("res://scripts/ui/hud.gd")
const TopicSelectScript := preload("res://scripts/ui/topic_select.gd")
const ResultPopupScript := preload("res://scripts/ui/result_popup.gd")
const UpgradePanelScript := preload("res://scripts/ui/upgrade_panel.gd")
const OfflinePopupScript := preload("res://scripts/ui/offline_popup.gd")
const StudioScript := preload("res://scripts/studio/studio.gd")
const VideoShootScript := preload("res://scripts/gameplay/video_shoot.gd")
const Formulas := preload("res://scripts/gameplay/formulas.gd")
const GameData := preload("res://scripts/data/game_data.gd")
const Palette := preload("res://scripts/studio/palette.gd")
const ICON_COIN: Texture2D = preload("res://assets/icons/coin.svg")
const ICON_USER: Texture2D = preload("res://assets/icons/user.svg")
const ICON_STAR: Texture2D = preload("res://assets/icons/star.svg")
const RESULT_DELAY: float = 1.1

@onready var _studio: StudioScript = $Studio
@onready var _shoot: VideoShootScript = $VideoShoot
@onready var _hud: HudScript = $UI/HUD
@onready var _topic_select: TopicSelectScript = $UI/TopicSelect
@onready var _result: ResultPopupScript = $UI/ResultPopup
@onready var _upgrades: UpgradePanelScript = $UI/UpgradePanel
@onready var _offline: OfflinePopupScript = $UI/OfflinePopup


func _ready() -> void:
	_hud.shoot_pressed.connect(_on_shoot_pressed)
	_hud.upgrades_pressed.connect(_upgrades.open)
	_hud.focus_tapped.connect(_on_focus_tapped)
	_topic_select.topic_chosen.connect(_on_topic_chosen)
	_shoot.shoot_started.connect(_on_shoot_started)
	_shoot.shoot_progress.connect(_hud.update_shooting)
	_shoot.shoot_finished.connect(_on_shoot_finished)
	_offline.claimed.connect(_on_offline_claimed)
	Economy.offline_reward_ready.connect(_offline.show_reward)
	Economy.upgrade_changed.connect(_on_upgrade_changed)
	Progress.level_up.connect(_on_level_up)
	for upgrade: Dictionary in GameData.upgrades():
		var upgrade_id: String = str(upgrade["id"])
		_studio.set_upgrade_level(upgrade_id, Economy.get_upgrade_level(upgrade_id))
	if Economy.has_pending_offline():
		_offline.show_reward(Economy.pending_offline_seconds, Economy.pending_offline_coins)


func _on_shoot_pressed() -> void:
	if _shoot.is_shooting:
		return
	if Economy.energy <= 0:
		Audio.play("error")
		_studio.mira().play_emotion("sad")
		_hud.show_toast("Нет энергии. Следующая через %s" % Formulas.format_duration(Economy.seconds_to_next_energy()))
		return
	_topic_select.open()


func _on_topic_chosen(topic_id: String) -> void:
	var reason: String = _shoot.block_reason(topic_id)
	if not reason.is_empty():
		Audio.play("error")
		_hud.show_toast(reason)
		return
	_shoot.start(topic_id)


func _on_shoot_started(topic: Dictionary) -> void:
	Audio.play("shutter")
	_hud.flash(0.55)
	_studio.flash(3.0)
	_studio.shake(0.05, 0.25)
	_studio.set_recording(true)
	_hud.show_shooting(str(topic["name"]))


func _on_focus_tapped() -> void:
	_shoot.register_tap()
	_hud.pulse_quality()
	_studio.shake(0.012, 0.08)


func _on_shoot_finished(result: Dictionary) -> void:
	_hud.hide_shooting()
	_studio.set_recording(false)
	Audio.play("shutter")
	Audio.play("cash")
	_hud.flash(0.9)
	_studio.flash(5.0)
	_studio.shake(0.14 if bool(result["viral"]) else 0.08, 0.45)
	_studio.react_to_result(result)
	_hud.burst_reactions()
	var origin: Vector2 = _hud.float_origin()
	var coins: float = float(result["coins"])
	var subs: float = float(result["subscribers"])
	_hud.spawn_float("+%s %s" % [Formulas.format_number(coins), Formulas.plural_ru(coins, "монета", "монеты", "монет")],
		ICON_COIN, Palette.SUN, origin)
	_hud.spawn_float("+%s %s" % [Formulas.format_number(subs), Formulas.plural_ru(subs, "подписчик", "подписчика", "подписчиков")],
		ICON_USER, Palette.MINT, origin + Vector2(0, 80), 0.2)
	_hud.spawn_float("+%d XP" % int(roundf(float(result["xp"]))), ICON_STAR, Palette.CREAM, origin + Vector2(0, 160), 0.4)
	await get_tree().create_timer(RESULT_DELAY).timeout
	_result.show_result(result)


func _on_offline_claimed(amount: float) -> void:
	_hud.spawn_float("+%s" % Formulas.format_number(amount), ICON_COIN, Palette.SUN, _hud.float_origin())
	_studio.mira().play_emotion("happy")


func _on_upgrade_changed(upgrade_id: String, level: int) -> void:
	_studio.set_upgrade_level(upgrade_id, level)
	_studio.celebrate_upgrade(upgrade_id)


func _on_level_up(new_level: int) -> void:
	_hud.show_toast("Уровень канала %d!" % new_level)
