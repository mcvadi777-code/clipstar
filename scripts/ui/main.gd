extends Node
## Корень главной сцены: связывает студию, HUD, окна и сервисы.

const HudScript := preload("res://scripts/ui/hud.gd")
const TopicSelectScript := preload("res://scripts/ui/topic_select.gd")
const ResultPopupScript := preload("res://scripts/ui/result_popup.gd")
const UpgradePanelScript := preload("res://scripts/ui/upgrade_panel.gd")
const OfflinePopupScript := preload("res://scripts/ui/offline_popup.gd")
const StudioScript := preload("res://scripts/studio/studio.gd")
const VideoShootScript := preload("res://scripts/gameplay/video_shoot.gd")
const Formulas := preload("res://scripts/gameplay/formulas.gd")

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
	_hud.focus_tapped.connect(_shoot.register_tap)
	_topic_select.topic_chosen.connect(_on_topic_chosen)
	_shoot.shoot_started.connect(_on_shoot_started)
	_shoot.shoot_progress.connect(_hud.update_shooting)
	_shoot.shoot_finished.connect(_on_shoot_finished)
	_offline.claimed.connect(_on_offline_claimed)
	Economy.offline_reward_ready.connect(_offline.show_reward)
	Economy.upgrade_changed.connect(_on_upgrade_changed)
	Progress.level_up.connect(_on_level_up)
	_studio.set_camera_level(Economy.get_upgrade_level("camera"))
	if Economy.has_pending_offline():
		_offline.show_reward(Economy.pending_offline_seconds, Economy.pending_offline_coins)


func _on_shoot_pressed() -> void:
	if _shoot.is_shooting:
		return
	if Economy.energy <= 0:
		Audio.play("error")
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
	_hud.show_shooting(str(topic["name"]))
	_studio.set_recording(true)


func _on_shoot_finished(result: Dictionary) -> void:
	_hud.hide_shooting()
	_studio.set_recording(false)
	_studio.celebrate()
	_result.show_result(result)


func _on_offline_claimed(amount: float) -> void:
	_hud.show_toast("+%s монет за время отсутствия" % Formulas.format_number(amount))


func _on_upgrade_changed(upgrade_id: String, level: int) -> void:
	if upgrade_id == "camera":
		_studio.set_camera_level(level)
		_studio.celebrate()


func _on_level_up(new_level: int) -> void:
	_hud.show_toast("Уровень канала %d!" % new_level)
