extends Control
## Главный экран: HUD, студия, таб-бар, панели.

const ART: String = "res://assets/art/"
const TOP_H: float = 300.0
const BOTTOM_H: float = 330.0

var studio: StudioView
var float_layer: Control
var overlay: Control
var overlay_body: VBoxContainer
var overlay_title: Label

var lbl_money: Label
var lbl_income: Label
var lbl_followers: Label
var lbl_energy: Label
var lbl_level: Label
var pb_level: ProgressBar
var lbl_task: Label
var pb_task: ProgressBar
var lbl_task_reward: Label
var btn_sound: Button
var btn_boost: Button
var lbl_boost: Label
var panel_kind: String = ""
var _ui_timer: float = 0.0
var _panel_timer: float = 0.0


func _ready() -> void:
	_build()
	Game.stats_changed.connect(_tick_ui)
	Game.task_changed.connect(_refresh_task)
	Game.stage_changed.connect(_on_stage_changed)
	Game.float_text.connect(_spawn_float)
	Game.offline_ready.connect(_on_offline)
	studio.set_stage(Game.stage)
	_tick_ui()
	_refresh_task()
	_refresh_sound()


func _build() -> void:
	studio = StudioView.new()
	studio.set_anchors_preset(Control.PRESET_FULL_RECT)
	studio.offset_top = TOP_H
	studio.offset_bottom = -BOTTOM_H
	add_child(studio)
	studio.tapped.connect(_on_studio_tap)

	_build_top_bar()
	_build_task_card()
	_build_bottom_bar()

	float_layer = Control.new()
	float_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	float_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(float_layer)

	_build_overlay()


func _build_top_bar() -> void:
	var bar: Panel = Panel.new()
	bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	bar.offset_bottom = TOP_H
	bar.add_theme_stylebox_override("panel", _panel_style(Color("#262238"), 0, 34))
	bar.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bar)

	var cash: TextureRect = _icon("icon_cash.svg", 92.0)
	cash.position = Vector2(26.0, 20.0)
	bar.add_child(cash)

	lbl_money = _label("0.00", 72, Color.WHITE)
	lbl_money.position = Vector2(132.0, 2.0)
	bar.add_child(lbl_money)

	var bolt: TextureRect = _icon("icon_bolt.svg", 46.0)
	bolt.position = Vector2(30.0, 132.0)
	bar.add_child(bolt)

	lbl_income = _label("0.40/сек", 34, Color("#7ee0c0"))
	lbl_income.position = Vector2(86.0, 128.0)
	bar.add_child(lbl_income)

	var fol: TextureRect = _icon("icon_followers.svg", 62.0)
	fol.position = Vector2(690.0, 22.0)
	bar.add_child(fol)

	lbl_followers = _label("0", 46, Color.WHITE)
	lbl_followers.position = Vector2(762.0, 20.0)
	bar.add_child(lbl_followers)

	var en: TextureRect = _icon("icon_bolt.svg", 52.0)
	en.position = Vector2(700.0, 128.0)
	bar.add_child(en)

	lbl_energy = _label("20/20", 34, Color.WHITE)
	lbl_energy.position = Vector2(762.0, 128.0)
	bar.add_child(lbl_energy)

	btn_sound = _button("", Color("#3a3352"), 30)
	btn_sound.position = Vector2(966.0, 24.0)
	btn_sound.size = Vector2(88.0, 88.0)
	btn_sound.pressed.connect(_on_sound_pressed)
	bar.add_child(btn_sound)

	lbl_level = _label("Ур. 1 · до 2: 0/100 XP", 28, Color("#cfc6e6"))
	lbl_level.position = Vector2(30.0, 190.0)
	bar.add_child(lbl_level)

	pb_level = _progress(Vector2(30.0, 240.0), Vector2(1020.0, 26.0), Color("#63d471"), Color("#3a3352"))
	bar.add_child(pb_level)


func _build_task_card() -> void:
	var card: Panel = Panel.new()
	card.position = Vector2(26.0, 316.0)
	card.size = Vector2(1028.0, 126.0)
	card.add_theme_stylebox_override("panel", _panel_style(Color("#312b48"), 34, 30))
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(card)

	lbl_task = _label("Задача", 30, Color.WHITE)
	lbl_task.position = Vector2(28.0, 12.0)
	card.add_child(lbl_task)

	lbl_task_reward = _label("+$0", 30, Color("#ffd166"))
	lbl_task_reward.position = Vector2(760.0, 12.0)
	card.add_child(lbl_task_reward)

	pb_task = _progress(Vector2(28.0, 72.0), Vector2(820.0, 24.0), Color("#ffb26b"), Color("#211d33"))
	card.add_child(pb_task)

	var chest: TextureRect = _icon("icon_task.svg", 76.0)
	chest.position = Vector2(900.0, 36.0)
	card.add_child(chest)


func _build_bottom_bar() -> void:
	var root: Control = Control.new()
	root.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	root.offset_top = -BOTTOM_H
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	btn_boost = _button("×2", Color("#ffb26b"), 40)
	btn_boost.position = Vector2(950.0, 4.0)
	btn_boost.size = Vector2(122.0, 140.0)
	btn_boost.pressed.connect(_on_boost)
	root.add_child(btn_boost)

	lbl_boost = _label("", 20, Color("#2b2238"))
	lbl_boost.position = Vector2(950.0, 104.0)
	lbl_boost.size = Vector2(122.0, 26.0)
	lbl_boost.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_boost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(lbl_boost)

	var shoot: Button = _button("Снять ролик", Color("#ff4f7b"), 46)
	shoot.position = Vector2(130.0, 4.0)
	shoot.size = Vector2(800.0, 140.0)
	shoot.pressed.connect(_on_shoot)
	root.add_child(shoot)

	var tabs: Panel = Panel.new()
	tabs.position = Vector2(0.0, 158.0)
	tabs.size = Vector2(1080.0, 172.0)
	tabs.add_theme_stylebox_override("panel", _panel_style(Color("#262238"), 0, 0))
	tabs.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(tabs)

	var names: Array = ["Студия", "Апгрейды", "Задачи", "Профиль"]
	var icons: Array = ["icon_home.svg", "icon_camera.svg", "icon_task.svg", "icon_star.svg"]
	for i: int in 4:
		var b: Button = _button("", Color("#2f2a44"), 22)
		b.position = Vector2(float(i) * 270.0 + 8.0, 6.0)
		b.size = Vector2(254.0, 160.0)
		var ic: TextureRect = _icon(str(icons[i]), 64.0)
		ic.position = Vector2(95.0, 14.0)
		ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(ic)
		var nl: Label = _label(str(names[i]), 24, Color("#cfc6e6"))
		nl.position = Vector2(0.0, 92.0)
		nl.size = Vector2(254.0, 30.0)
		nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(nl)
		var idx: int = i
		b.pressed.connect(func() -> void: _on_tab(idx))
		tabs.add_child(b)


func _build_overlay() -> void:
	overlay = Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.visible = false
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)

	var dim: ColorRect = ColorRect.new()
	dim.color = Color(0.05, 0.04, 0.09, 0.78)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(dim)

	var panel: Panel = Panel.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 60.0
	panel.offset_right = -60.0
	panel.offset_top = 330.0
	panel.offset_bottom = -330.0
	panel.add_theme_stylebox_override("panel", _panel_style(Color("#2b2640"), 40, 40))
	overlay.add_child(panel)

	overlay_title = _label("Панель", 44, Color.WHITE)
	overlay_title.position = Vector2(36.0, 28.0)
	panel.add_child(overlay_title)

	var close: Button = _button("Закрыть", Color("#ff4f7b"), 34)
	close.position = Vector2(36.0, 980.0)
	close.size = Vector2(888.0, 110.0)
	close.pressed.connect(_close_panel)
	panel.add_child(close)

	overlay_body = VBoxContainer.new()
	overlay_body.position = Vector2(36.0, 120.0)
	overlay_body.size = Vector2(888.0, 830.0)
	overlay_body.add_theme_constant_override("separation", 18)
	panel.add_child(overlay_body)


func _process(delta: float) -> void:
	_ui_timer += delta
	if _ui_timer >= 0.1:
		_ui_timer = 0.0
		_tick_ui()
	if overlay.visible and panel_kind == "Апгрейды":
		_panel_timer += delta
		if _panel_timer >= 0.7:
			_panel_timer = 0.0
			_fill_upgrades()


func _on_studio_tap(pos: Vector2) -> void:
	Game.do_tap()
	studio.play_tap()
	Sfx.play("tap")
	_bills(pos)


func _on_shoot() -> void:
	if not Game.can_shoot():
		Sfx.play("error")
		return
	var result: Dictionary = Game.shoot()
	if result.is_empty():
		Sfx.play("error")
		return
	Sfx.play("cash")
	_spawn_float("+" + fmt(float(result["money"])), Color("#ffd166"))
	_spawn_float("+%d подписчиков" % int(float(result["followers"])), Color("#8fe6ff"))
	studio.play_tap()
	studio.set_expression("happy")
	Game.save_state()


func _on_tab(index: int) -> void:
	Sfx.play("click")
	match index:
		0:
			_close_panel()
		1:
			_open_upgrades()
		2:
			_open_tasks()
		3:
			_open_profile()


func _on_boost() -> void:
	if Game.is_boost():
		return
	Game.start_boost()
	Sfx.play("fanfare")
	_tick_ui()


func _on_sound_pressed() -> void:
	Sfx.muted = not Sfx.muted
	_refresh_sound()


func _refresh_sound() -> void:
	if btn_sound != null:
		btn_sound.text = "выкл" if Sfx.muted else "вкл"


func _tick_ui() -> void:
	lbl_money.text = fmt(Game.money)
	lbl_income.text = fmt(Game.per_sec()) + "/сек"
	lbl_followers.text = str(int(Game.followers))
	lbl_energy.text = "%d/%d" % [Game.energy, Game.ENERGY_MAX]
	var lv: Vector2 = Game.level_progress()
	lbl_level.text = "Ур. %d · до %d: %d/100 XP" % [Game.level(), Game.level() + 1, int(lv.x)]
	pb_level.max_value = 100.0
	pb_level.value = lv.x
	if Game.is_boost():
		var left: int = Game.boost_left()
		lbl_boost.text = "%d:%02d" % [left / 60, left % 60]
		btn_boost.disabled = true
	else:
		lbl_boost.text = "буст"
		btn_boost.disabled = false
	_refresh_task()


func _refresh_task() -> void:
	var task: Dictionary = Game.current_task()
	if task.is_empty():
		lbl_task.text = "Все задачи выполнены 🎉"
		lbl_task_reward.text = ""
		pb_task.value = 1.0
		pb_task.max_value = 1.0
		return
	var prog: Vector2 = Game.task_progress()
	lbl_task.text = "%s · %d/%d" % [str(task["title"]), int(prog.x), int(prog.y)]
	lbl_task_reward.text = "+$" + fmt(float(task["reward"]))
	pb_task.max_value = maxf(prog.y, 1.0)
	pb_task.value = prog.x


func _on_stage_changed(stage: int) -> void:
	studio.set_stage(stage)
	_flash()
	Sfx.play("fanfare")
	_spawn_float("Студия выросла до %d уровня!" % (stage + 1), Color("#ffd166"))


func _on_offline(amount: float) -> void:
	_open_panel("С возвращением!")
	var l: Label = _label("Пока тебя не было, ты заработал\n$%s" % fmt(amount), 40, Color.WHITE)
	overlay_body.add_child(l)
	var l2: Label = _label("Доход капал в офлайне до 8 часов.", 28, Color("#cfc6e6"))
	overlay_body.add_child(l2)


func _open_panel(title: String) -> void:
	panel_kind = title
	overlay.visible = true
	overlay_title.text = title
	_clear_body()


func _close_panel() -> void:
	panel_kind = ""
	overlay.visible = false
	_clear_body()


func _clear_body() -> void:
	for child: Node in overlay_body.get_children():
		child.queue_free()


func _rebuild_panel() -> void:
	if panel_kind == "Апгрейды":
		_fill_upgrades()
	elif panel_kind == "Задачи":
		_fill_tasks()
	elif panel_kind == "Профиль":
		_fill_profile()


func _open_upgrades() -> void:
	_open_panel("Апгрейды")
	_fill_upgrades()


func _open_tasks() -> void:
	_open_panel("Задачи")
	_fill_tasks()


func _open_profile() -> void:
	_open_panel("Профиль")
	_fill_profile()


func _fill_upgrades() -> void:
	_clear_body()
	for id: String in Game.UPGRADES.keys():
		var info: Dictionary = Game.UPGRADES[id] as Dictionary
		var row: HBoxContainer = HBoxContainer.new()
		row.custom_minimum_size = Vector2(880.0, 120.0)
		var left: VBoxContainer = VBoxContainer.new()
		left.custom_minimum_size = Vector2(520.0, 110.0)
		var name_label: Label = _label("%s · ур. %d" % [str(info["name"]), Game.upgrade_level(id)], 34, Color.WHITE)
		left.add_child(name_label)
		left.add_child(_label(str(info["desc"]), 24, Color("#cfc6e6")))
		row.add_child(left)
		var cost: float = Game.upgrade_cost(id)
		var buy: Button = _button("$" + fmt(cost), Color("#63d471"), 30)
		buy.custom_minimum_size = Vector2(330.0, 100.0)
		buy.disabled = Game.money < cost
		var up_id: String = id
		buy.pressed.connect(func() -> void:
			if Game.buy_upgrade(up_id):
				Sfx.play("coin")
				Game.save_state()
			_fill_upgrades()
		)
		row.add_child(buy)
		overlay_body.add_child(row)


func _fill_tasks() -> void:
	_clear_body()
	for i: int in Game.TASKS.size():
		var task: Dictionary = Game.TASKS[i] as Dictionary
		var done: bool = i < Game.task_index
		var current: bool = i == Game.task_index
		var color: Color = Color("#63d471") if done else (Color.WHITE if current else Color("#8d84a8"))
		var title: Label = _label(("✓ " if done else "• ") + str(task["title"]), 28, color)
		overlay_body.add_child(title)
		var prog_label: Label = _label("награда +$" + fmt(float(task["reward"])), 22, Color("#ffd166"))
		overlay_body.add_child(prog_label)


func _fill_profile() -> void:
	_clear_body()
	var lines: Array = [
		"Уровень: %d" % Game.level(),
		"Подписчики: %d" % int(Game.followers),
		"Доход: %s/сек" % fmt(Game.per_sec()),
		"Роликов снято: %d" % Game.videos,
		"Всего заработано: $%s" % fmt(Game.total_earned),
		"Стадия студии: %d/5" % (Game.stage + 1),
		"Копилка: $%s" % fmt(Game.piggy),
	]
	for line: String in lines:
		overlay_body.add_child(_label(line, 30, Color.WHITE))
	if Game.piggy > 0.0:
		var claim: Button = _button("Забрать копилку", Color("#63d471"), 28)
		claim.custom_minimum_size = Vector2(500.0, 90.0)
		claim.pressed.connect(func() -> void:
			var got: float = Game.claim_piggy()
			Sfx.play("coin")
			_spawn_float("+$" + fmt(got), Color("#63d471"))
			Game.save_state()
			_fill_profile()
		)
		overlay_body.add_child(claim)
	var reset: Button = _button("Сбросить прогресс", Color("#3a3352"), 28)
	reset.custom_minimum_size = Vector2(500.0, 90.0)
	reset.pressed.connect(func() -> void:
		Game.reset_progress()
		_close_panel()
	)
	overlay_body.add_child(reset)


func _flash() -> void:
	var fl: ColorRect = ColorRect.new()
	fl.color = Color(1.0, 1.0, 1.0, 0.0)
	fl.set_anchors_preset(Control.PRESET_FULL_RECT)
	fl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	float_layer.add_child(fl)
	var tw: Tween = create_tween()
	tw.tween_property(fl, "color:a", 0.85, 0.12)
	tw.tween_property(fl, "color:a", 0.0, 0.5)
	tw.tween_callback(fl.queue_free)


func _spawn_float(text: String, color: Color) -> void:
	if float_layer == null:
		return
	var l: Label = _label(text, 44, color)
	var x: float = studio.global_position.x + studio.size.x * 0.5 + randf_range(-160.0, 160.0)
	var y: float = studio.global_position.y + studio.size.y * 0.55 + randf_range(-80.0, 80.0)
	l.position = Vector2(x, y)
	float_layer.add_child(l)
	var tw: Tween = create_tween()
	tw.set_parallel(true)
	tw.tween_property(l, "position:y", y - 190.0, 1.0)
	tw.tween_property(l, "modulate:a", 0.0, 1.0)
	tw.chain().tween_callback(l.queue_free)


func _bills(pos: Vector2) -> void:
	for i: int in 3:
		var bill: TextureRect = _icon("icon_cash.svg", 44.0)
		var start: Vector2 = studio.position + pos + Vector2(randf_range(-50.0, 50.0), randf_range(-30.0, 30.0))
		bill.position = start
		bill.rotation = randf_range(-0.4, 0.4)
		float_layer.add_child(bill)
		var tx: float = start.x + randf_range(-120.0, 120.0)
		var ty: float = start.y - randf_range(220.0, 380.0)
		var tw: Tween = create_tween()
		tw.set_parallel(true)
		tw.tween_property(bill, "position", Vector2(tx, ty), 0.85)
		tw.tween_property(bill, "modulate:a", 0.0, 0.85)
		tw.chain().tween_callback(bill.queue_free)


func fmt(value: float) -> String:
	if value < 1000.0:
		return "%.2f" % value
	if value < 1000000.0:
		return "%.2fK" % (value / 1000.0)
	if value < 1000000000.0:
		return "%.2fM" % (value / 1000000.0)
	return "%.2fB" % (value / 1000000000.0)


func _label(text: String, font_size: int, color: Color) -> Label:
	var l: Label = Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0.09, 0.07, 0.14, 0.85))
	l.add_theme_constant_override("outline_size", 8)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _icon(file: String, px: float) -> TextureRect:
	var t: TextureRect = TextureRect.new()
	t.texture = load(ART + file)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.size = Vector2(px, px)
	t.custom_minimum_size = Vector2(px, px)
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t


func _panel_style(color: Color, radius_top: int, radius_bottom: int) -> StyleBoxFlat:
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = color
	sb.corner_radius_top_left = radius_top
	sb.corner_radius_top_right = radius_top
	sb.corner_radius_bottom_left = radius_bottom
	sb.corner_radius_bottom_right = radius_bottom
	return sb


func _progress(pos: Vector2, bar_size: Vector2, fill: Color, bg: Color) -> ProgressBar:
	var pb: ProgressBar = ProgressBar.new()
	pb.position = pos
	pb.size = bar_size
	pb.show_percentage = false
	pb.value = 0.0
	var sb_bg: StyleBoxFlat = StyleBoxFlat.new()
	sb_bg.bg_color = bg
	sb_bg.corner_radius_top_left = 13
	sb_bg.corner_radius_top_right = 13
	sb_bg.corner_radius_bottom_left = 13
	sb_bg.corner_radius_bottom_right = 13
	var sb_fill: StyleBoxFlat = StyleBoxFlat.new()
	sb_fill.bg_color = fill
	sb_fill.corner_radius_top_left = 13
	sb_fill.corner_radius_top_right = 13
	sb_fill.corner_radius_bottom_left = 13
	sb_fill.corner_radius_bottom_right = 13
	pb.add_theme_stylebox_override("background", sb_bg)
	pb.add_theme_stylebox_override("fill", sb_fill)
	pb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return pb


func _button(text: String, color: Color, font_size: int) -> Button:
	var b: Button = Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", font_size)
	b.add_theme_color_override("font_color", Color.WHITE)
	b.add_theme_color_override("font_pressed_color", Color(0.85, 0.85, 0.85))
	b.add_theme_color_override("font_disabled_color", Color(0.6, 0.6, 0.7))
	var normal: StyleBoxFlat = _round_box(color)
	var pressed: StyleBoxFlat = _round_box(color.darkened(0.22))
	var disabled: StyleBoxFlat = _round_box(color.darkened(0.45))
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("pressed", pressed)
	b.add_theme_stylebox_override("hover", normal)
	b.add_theme_stylebox_override("disabled", disabled)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	return b


func _round_box(color: Color) -> StyleBoxFlat:
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = color
	sb.corner_radius_top_left = 26
	sb.corner_radius_top_right = 26
	sb.corner_radius_bottom_left = 26
	sb.corner_radius_bottom_right = 26
	sb.content_margin_left = 16.0
	sb.content_margin_right = 16.0
	sb.content_margin_top = 8.0
	sb.content_margin_bottom = 8.0
	return sb
