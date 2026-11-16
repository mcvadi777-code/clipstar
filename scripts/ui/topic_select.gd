extends Control
## Выбор темы ролика. Кнопки строятся из topics.json; закрытые по уровню и «остывающие»
## темы видны, но недоступны. Пока окно открыто, кулдауны обновляются раз в секунду.

signal topic_chosen(topic_id: String)
signal closed

const Formulas := preload("res://scripts/gameplay/formulas.gd")
const GameData := preload("res://scripts/data/game_data.gd")
const UiFx := preload("res://scripts/fx/ui_fx.gd")
const ICON_FILM: Texture2D = preload("res://assets/icons/film.svg")

@onready var _list: VBoxContainer = %TopicList
@onready var _energy_label: Label = %TopicEnergyLabel
@onready var _close_button: Button = %CloseButton

var _refresh_timer: Timer


func _ready() -> void:
	visible = false
	_close_button.pressed.connect(close)
	UiFx.apply_press_feedback(self)
	_refresh_timer = Timer.new()
	_refresh_timer.wait_time = 1.0
	_refresh_timer.timeout.connect(_rebuild)
	add_child(_refresh_timer)


func open() -> void:
	_rebuild()
	visible = true
	UiFx.pop($Center/Panel as Control, 1.04)
	_refresh_timer.start()


func close() -> void:
	visible = false
	_refresh_timer.stop()
	closed.emit()


func _rebuild() -> void:
	for child: Node in _list.get_children():
		_list.remove_child(child)
		child.queue_free()
	_energy_label.text = "Энергия %d/%d · ролик стоит 1" % [Economy.energy, Economy.energy_max()]
	for topic: Dictionary in GameData.topics():
		var topic_id: String = str(topic["id"])
		var button: Button = Button.new()
		button.custom_minimum_size = Vector2(0, 110)
		button.icon = ICON_FILM
		button.expand_icon = false
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var info: String = "%s\nохват x%.1f · энергия %d" % [str(topic["name"]), float(topic["reach_power"]), int(topic["energy_cost"])]
		var cooldown: int = Progress.topic_cooldown_left(topic_id)
		if not Progress.is_topic_unlocked(topic):
			info = "%s\nзакрыто до уровня %d" % [str(topic["name"]), int(topic["required_level"])]
			button.disabled = true
		elif cooldown > 0:
			info = "%s\nостывает: %s" % [str(topic["name"]), Formulas.format_duration(cooldown)]
			button.disabled = true
		button.text = info
		button.pressed.connect(_on_topic_pressed.bind(topic_id))
		UiFx.add_press_feedback(button)
		_list.add_child(button)


func _on_topic_pressed(topic_id: String) -> void:
	Audio.play("click")
	visible = false
	_refresh_timer.stop()
	topic_chosen.emit(topic_id)
