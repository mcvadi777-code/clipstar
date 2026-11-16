extends Node
## Автозагрузка "Audio": все SFX синтезируются в коде (AudioStreamWAV из тонов и шума) —
## в проекте нет аудиофайлов. Пул AudioStreamPlayer, чтобы звуки не обрывали друг друга.
## Чтобы заменить звук на свой файл позже: положи .ogg в assets/sfx и в _ready()
## присвой _streams["cash"] = load("res://assets/sfx/cash.ogg").
## Настройка «звук вкл/выкл» хранится в разделе "settings" сейва.

const SECTION: String = "settings"
const MIX_RATE: int = 22050
const POOL_SIZE: int = 6

## Звук → ноты: [частоты (аккорд), длительность с, форма волны sine|square|noise, громкость 0..1].
const SOUNDS: Dictionary = {
	"click": [[[900.0], 0.035, "square", 0.25]],
	"tap": [[[1400.0], 0.03, "sine", 0.6]],
	"tick": [[[2200.0], 0.012, "square", 0.12]],
	"coin": [[[988.0], 0.06, "square", 0.3], [[1319.0], 0.12, "square", 0.3]],
	"cash": [[[0.0], 0.05, "noise", 0.45], [[2093.0, 2637.0], 0.07, "square", 0.22], [[2637.0, 3136.0], 0.24, "sine", 0.55]],
	"fanfare": [[[523.25], 0.09, "square", 0.25], [[659.25], 0.09, "square", 0.25], [[783.99], 0.09, "square", 0.25],
		[[1046.5, 783.99, 659.25], 0.4, "square", 0.22]],
	"level_up": [[[523.25], 0.07, "sine", 0.6], [[659.25], 0.07, "sine", 0.6], [[783.99], 0.07, "sine", 0.6],
		[[1046.5], 0.07, "sine", 0.6], [[1318.5, 1046.5], 0.3, "sine", 0.5]],
	"error": [[[220.0], 0.08, "square", 0.25], [[185.0], 0.14, "square", 0.25]],
	"shutter": [[[0.0], 0.025, "noise", 0.7], [[0.0], 0.05, "noise", 0.3]],
}

var muted: bool = false

var _streams: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _next_player: int = 0
var _noise: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_noise.seed = 1337
	for sound_name: String in SOUNDS.keys():
		_streams[sound_name] = _synthesize(SOUNDS[sound_name] as Array)
	for i: int in POOL_SIZE:
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		player.volume_db = -6.0
		add_child(player)
		_players.append(player)
	muted = bool(Save.get_section(SECTION).get("muted", false))


func play(sound_name: String, pitch: float = 1.0) -> void:
	if muted or not _streams.has(sound_name):
		return
	var player: AudioStreamPlayer = _players[_next_player]
	_next_player = (_next_player + 1) % _players.size()
	player.stream = _streams[sound_name] as AudioStreamWAV
	player.pitch_scale = pitch
	player.play()


func set_muted(value: bool) -> void:
	muted = value
	var section: Dictionary = Save.get_section(SECTION)
	section["muted"] = muted
	Save.set_section(SECTION, section)


func toggle_muted() -> bool:
	set_muted(not muted)
	if not muted:
		play("click")
	return muted


func _synthesize(notes: Array) -> AudioStreamWAV:
	var total_samples: int = 0
	for note: Variant in notes:
		total_samples += int(float((note as Array)[1]) * MIX_RATE)
	var bytes: PackedByteArray = PackedByteArray()
	bytes.resize(total_samples * 2)
	var offset: int = 0
	var attack: int = maxi(int(0.003 * MIX_RATE), 1)
	for note: Variant in notes:
		var freqs: Array = (note as Array)[0]
		var count: int = int(float((note as Array)[1]) * MIX_RATE)
		var wave: String = str((note as Array)[2])
		var volume: float = float((note as Array)[3])
		for i: int in count:
			var t: float = float(i) / MIX_RATE
			var env: float = minf(float(i) / attack, 1.0) * pow(1.0 - float(i) / count, 1.5)
			var sample: float = 0.0
			if wave == "noise":
				sample = _noise.randf_range(-1.0, 1.0)
			else:
				for f: Variant in freqs:
					var phase: float = sin(TAU * float(f) * t)
					sample += (signf(phase) * 0.6) if wave == "square" else phase
				sample /= float(maxi(freqs.size(), 1))
			bytes.encode_s16(offset, int(clampf(sample * env * volume, -1.0, 1.0) * 32767.0))
			offset += 2
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.data = bytes
	return stream
