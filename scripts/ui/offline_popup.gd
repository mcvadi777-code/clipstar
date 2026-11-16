extends Control
## «Пока тебя не было…»: сколько времени прошло (по UTC, не больше лимита) и сколько монет накопилось.

signal claimed(amount: float)

const Formulas := preload("res://scripts/gameplay/formulas.gd")
const UiFx := preload("res://scripts/fx/ui_fx.gd")

@onready var _away_label: Label = %AwayLabel
@onready var _coins_label: Label = %OfflineCoinsLabel
@onready var _claim_button: Button = %ClaimButton


func _ready() -> void:
	visible = false
	_claim_button.pressed.connect(_on_claim)
	UiFx.apply_press_feedback(self)


func show_reward(seconds: int, coins: float) -> void:
	var capped: String = " (лимит %d ч)" % (Formulas.offline_cap_seconds() / 3600) if seconds >= Formulas.offline_cap_seconds() else ""
	_away_label.text = "Тебя не было %s%s. Старые ролики продолжали собирать просмотры: офлайн канал приносит %d%% пассивного дохода." % [
		Formulas.format_duration(seconds), capped, int(Economy.passive_breakdown()["offline_efficiency"] * 100.0)]
	_coins_label.text = "+%s" % Formulas.format_number(coins)
	visible = true
	UiFx.pop($Center/Panel as Control, 1.06)


func _on_claim() -> void:
	var amount: float = Economy.claim_offline()
	Audio.play("coin")
	visible = false
	claimed.emit(amount)
