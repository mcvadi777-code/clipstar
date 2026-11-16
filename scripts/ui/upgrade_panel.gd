extends Control
## Окно апгрейда. В вертикальном срезе один апгрейд — камера (upgrades.json, id "camera").

signal closed

const Formulas := preload("res://scripts/gameplay/formulas.gd")
const GameData := preload("res://scripts/data/game_data.gd")
const UPGRADE_ID: String = "camera"

@onready var _name_label: Label = %UpgradeName
@onready var _desc_label: Label = %UpgradeDesc
@onready var _level_label: Label = %UpgradeLevel
@onready var _effect_label: Label = %UpgradeEffect
@onready var _buy_button: Button = %BuyButton
@onready var _close_button: Button = %UpgradeCloseButton


func _ready() -> void:
	visible = false
	_buy_button.pressed.connect(_on_buy)
	_close_button.pressed.connect(close)
	Economy.coins_changed.connect(_on_coins_changed)
	Economy.upgrade_changed.connect(_on_upgrade_changed)


func open() -> void:
	_refresh()
	visible = true


func close() -> void:
	Audio.play("click")
	visible = false
	closed.emit()


func _refresh() -> void:
	var upgrade: Dictionary = GameData.upgrade(UPGRADE_ID)
	if upgrade.is_empty():
		_name_label.text = "Апгрейд не найден"
		_buy_button.disabled = true
		return
	var level: int = Economy.get_upgrade_level(UPGRADE_ID)
	var max_level: int = int(upgrade["max_level"])
	_name_label.text = str(upgrade["name"])
	_desc_label.text = str(upgrade.get("description", ""))
	_level_label.text = "Уровень %d из %d" % [level, max_level]
	_effect_label.text = "Охват x%.2f · доход x%.2f" % [Economy.reach_multiplier(), Economy.income_multiplier()]
	if Economy.is_upgrade_maxed(UPGRADE_ID):
		_buy_button.text = "Максимум"
		_buy_button.disabled = true
	else:
		_buy_button.text = "Улучшить за %s" % Formulas.format_number(Economy.upgrade_cost(UPGRADE_ID))
		_buy_button.disabled = not Economy.can_buy_upgrade(UPGRADE_ID)


func _on_buy() -> void:
	if Economy.buy_upgrade(UPGRADE_ID):
		Audio.play("coin")
	else:
		Audio.play("error")
	_refresh()


func _on_coins_changed(_coins: float) -> void:
	if visible:
		_refresh()


func _on_upgrade_changed(_upgrade_id: String, _level: int) -> void:
	if visible:
		_refresh()
