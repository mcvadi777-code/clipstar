extends RefCounted
## Эффекты интерфейса: нажатие кнопок (сжатие и пружина), «поп» элемента, счётчик, тикающий вверх.

const PRESS_META: String = "_ui_fx_press"


## Добавляет кнопке анимацию нажатия. Повторный вызов ничего не делает.
static func add_press_feedback(button: BaseButton) -> void:
	if button.has_meta(PRESS_META):
		return
	button.set_meta(PRESS_META, true)
	button.resized.connect(_center_pivot.bind(button))
	_center_pivot(button)
	button.button_down.connect(_animate_scale.bind(button, 0.92, 0.06))
	button.button_up.connect(_animate_scale.bind(button, 1.0, 0.18))


## Проходит по всем потомкам и добавляет анимацию нажатия каждой кнопке.
static func apply_press_feedback(root: Node) -> void:
	for child: Node in root.get_children():
		if child is BaseButton:
			add_press_feedback(child as BaseButton)
		apply_press_feedback(child)


static func pop(control: Control, strength: float = 1.15) -> void:
	_center_pivot(control)
	var tween: Tween = control.create_tween()
	tween.tween_property(control, "scale", Vector2.ONE * strength, 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(control, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Тикает число в label от from_value до to_value; formatter: Callable(float) -> String.
static func count_up(label: Label, from_value: float, to_value: float, duration: float, formatter: Callable) -> Tween:
	var tween: Tween = label.create_tween()
	tween.tween_method(func(v: float) -> void: label.text = formatter.call(v), from_value, to_value, duration) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	return tween


static func _center_pivot(control: Control) -> void:
	control.pivot_offset = control.size * 0.5


static func _animate_scale(control: Control, target: float, duration: float) -> void:
	var tween: Tween = control.create_tween()
	tween.tween_property(control, "scale", Vector2.ONE * target, duration) \
		.set_trans(Tween.TRANS_BACK if target >= 1.0 else Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
