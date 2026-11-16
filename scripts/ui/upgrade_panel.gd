extends Control
## Окно апгрейдов: строка на каждый апгрейд из upgrades.json (иконка, уровень, эффект, цена).
## Покупка сразу видна в студии (штатив, кольцевая лампа, стол) — это делает main.gd по сигналу Economy.

signal closed

const Formulas := preload("res://scripts/gameplay/formulas.gd")
const GameData := preload("res://scripts/data/game_data.gd")
const UiFx := preload("res://scripts/fx/ui_fx.gd")
const ICON_COIN: Texture2D = preload("res://assets/icons/coin.svg")

@onready var _panel: Control = $Center/Panel
@onready var _list: VBoxContainer = %UpgradeList
@onready var _totals_label: Label = %UpgradeTotals
@onready var _close_button: Button = %UpgradeCloseButton

## upgrade_id → {"level": Label, "effect": Label, "buy": Button}
var _rows: Dictionary = {}


func _ready() -> void:
	visible = false
	_close_button.pressed.connect(close)
	Economy.coins_changed.connect(_on_coins_changed)
	Economy.upgrade_changed.connect(_on_upgrade_changed)
	_build_rows()
	UiFx.apply_press_feedback(self)


func open() -> void:
	_refresh()
	visible = true
	UiFx.pop(_panel, 1.04)


func close() -> void:
	Audio.play("click")
	visible = false
	closed.emit()


func _build_rows() -> void:
	for upgrade: Dictionary in GameData.upgrades():
		var upgrade_id: String = str(upgrade["id"])
		var row: HBoxContainer = HBoxContainer.new()
		row.add_theme_constant_override("separation", 14)
		var icon: TextureRect = TextureRect.new()
		icon.custom_minimum_size = Vector2(72, 72)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var icon_path: String = str(upgrade.get("icon", ""))
		if not icon_path.is_empty() and ResourceLoader.exists(icon_path):
			icon.texture = load(icon_path) as Texture2D
		var info: VBoxContainer = VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.add_theme_constant_override("separation", 2)
		var name_label: Label = Label.new()
		name_label.text = str(upgrade["name"])
		name_label.add_theme_font_size_override("font_size", 32)
		var level_label: Label = Label.new()
		level_label.add_theme_font_size_override("font_size", 24)
		var effect_label: Label = Label.new()
		effect_label.add_theme_font_size_override("font_size", 22)
		effect_label.add_theme_color_override("font_color", Color("4fd1a5"))
		effect_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		level_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		info.add_child(name_label)
		info.add_child(level_label)
		info.add_child(effect_label)
		var buy: Button = Button.new()
		buy.custom_minimum_size = Vector2(170, 84)
		buy.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		buy.icon = ICON_COIN
		buy.expand_icon = false
		buy.add_theme_constant_override("icon_max_width", 36)
		buy.add_theme_font_size_override("font_size", 28)
		buy.pressed.connect(_on_buy.bind(upgrade_id))
		row.add_child(icon)
		row.add_child(info)
		row.add_child(buy)
		_list.add_child(row)
		_rows[upgrade_id] = {"row": row, "level": level_label, "effect": effect_label, "buy": buy}


func _refresh() -> void:
	for upgrade: Dictionary in GameData.upgrades():
		var upgrade_id: String = str(upgrade["id"])
		if not _rows.has(upgrade_id):
			continue
		var refs: Dictionary = _rows[upgrade_id]
		var level: int = Economy.get_upgrade_level(upgrade_id)
		(refs["level"] as Label).text = "Уровень %d из %d" % [level, int(upgrade["max_level"])]
		(refs["effect"] as Label).text = _effect_text(upgrade)
		var buy: Button = refs["buy"]
		if Economy.is_upgrade_maxed(upgrade_id):
			buy.text = "Макс."
			buy.icon = null
			buy.disabled = true
		else:
			buy.text = Formulas.format_number(Economy.upgrade_cost(upgrade_id))
			buy.icon = ICON_COIN
			buy.disabled = not Economy.can_buy_upgrade(upgrade_id)
	_totals_label.text = "Сейчас: охват ×%.2f · доход ×%.2f" % [Economy.reach_multiplier(), Economy.income_multiplier()]


func _effect_text(upgrade: Dictionary) -> String:
	var parts: PackedStringArray = PackedStringArray()
	var reach: float = float(upgrade["reach_bonus_per_level"])
	var income: float = float(upgrade["income_bonus_per_level"])
	if reach > 0.0:
		parts.append("+%d%% охват" % int(roundf(reach * 100.0)))
	if income > 0.0:
		parts.append("+%d%% доход" % int(roundf(income * 100.0)))
	return ", ".join(parts) + " за ур."


func _on_buy(upgrade_id: String) -> void:
	if Economy.buy_upgrade(upgrade_id):
		Audio.play("cash")
		UiFx.pop((_rows[upgrade_id] as Dictionary)["row"] as Control, 1.06)
	else:
		Audio.play("error")
	_refresh()


func _on_coins_changed(_coins: float) -> void:
	if visible:
		_refresh()


func _on_upgrade_changed(_upgrade_id: String, _level: int) -> void:
	if visible:
		_refresh()
