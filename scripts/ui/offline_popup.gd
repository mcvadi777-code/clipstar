extends Control
## «Пока тебя не было…»: сколько времени прошло (по UTC, не больше лимита) и сколько монет накопилось.

signal claimed(amount: float)

const Formulas := preload("res://scripts/gameplay/formulas.gd")

@onready var _away_label: Label = %AwayLabel
@onready var _coins_label: Label = %OfflineCoinsLabel
@onready var _claim_button: Button = %ClaimButton


func _ready() -> void:
	visible = false
	_claim_button.pressed.connect(_on_claim)


func show_reward(seconds: int, coins: float) -> void:
	var capped: String = " (лимит %d ч)" % (Formulas.offline_cap_seconds() / 3600) if seconds >= Formulas.offline_cap_seconds() else ""
	_away_label.text = "Пока тебя не было %s%s, Мира монтировала старые ролики." % [Formulas.format_duration(seconds), capped]
	_coins_label.text = "+%s монет" % Formulas.format_number(coins)
	visible = true


func _on_claim() -> void:
	var amount: float = Economy.claim_offline()
	Audio.play("coin")
	visible = false
	claimed.emit(amount)
