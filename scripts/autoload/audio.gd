extends Node
## Автозагрузка "Audio": короткие UI-звуки, синтезированные в коде (без аудиофайлов в проекте).
## Пул из нескольких AudioStreamPlayer, чтобы звуки не обрывали друг друга.
## Настройка "звук вкл/выкл" хранится в разделе "settings" сейва.

const SECTION: String = "settings"
const MIX_RATE: int = 22050
const POOL_SIZE: int = 4

## Имя звука → список нот [частота Гц, длительность с].
const SOUND_NOTES: Dictionary = {
	"click": [[880.0, 0.04]],
	"tap": [[1320.0, 0.03]],
	"coin": [[1046.5, 0.06], [1568.0, 0.09]],
	"success": [[523.25, 0.08], [659.25, 0.08], [783.99, 0.14]],
	"level_up": [[523.25, 0.07], [659.25, 0.07], [783.99, 0.07], [1046.5, 0.18]],
	"error": [[220.0, 0.08], [185.0, 0.12]],
}

var muted: bool = false

var _streams: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _next_player: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for sound_name: String in SOUND_NOTES.keys():
		_streams[sound_name] = _synthesize(SOUND_NOTES[sound_name] as Array)
	for i: int in POOL_SIZE:
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		player.volume_db = -8.0
		add_child(player)
		_players.append(player)
	muted = bool(Save.get_section(SECTION).get("muted", false))


func play(sound_name: String) -> void:
	if muted or not _streams.has(sound_name):
		return
	var player: AudioStreamPlayer = _players[_next_player]
	_next_player = (_next_player + 1) % _players.size()
	player.stream = _streams[sound_name] as AudioStreamWAV
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


## Синус с короткой атакой и затуханием, 16 бит моно.
func _synthesize(notes: Array) -> AudioStreamWAV:
	var bytes: PackedByteArray = PackedByteArray()
	var total_samples: int = 0
	for note: Variant in notes:
		total_samples += int(float((note as Array)[1]) * MIX_RATE)
	bytes.resize(total_samples * 2)
	var offset: int = 0
	for note: Variant in notes:
		var freq: float = float((note as Array)[0])
		var count: int = int(float((note as Array)[1]) * MIX_RATE)
		var attack: int = maxi(int(0.004 * MIX_RATE), 1)
		for i: int in count:
			var t: float = float(i) / MIX_RATE
			var env: float = minf(float(i) / attack, 1.0) * (1.0 - float(i) / count)
			var sample: float = sin(TAU * freq * t) * env * 0.6
			bytes.encode_s16(offset, int(sample * 32767.0))
			offset += 2
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.data = bytes
	return stream
