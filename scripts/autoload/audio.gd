extends Node
## Синтезированные SFX: в проекте нет аудиофайлов.

const RATE: int = 22050
const POOL: int = 6

const SOUNDS: Dictionary = {
	"click": [[[880.0], 0.03, "square", 0.20]],
	"tap": [[[1320.0], 0.03, "sine", 0.45]],
	"coin": [[[988.0], 0.05, "square", 0.28], [[1319.0], 0.10, "square", 0.28]],
	"cash": [[[0.0], 0.04, "noise", 0.35], [[2093.0, 2637.0], 0.08, "square", 0.20], [[2637.0, 3136.0], 0.20, "sine", 0.45]],
	"fanfare": [[[523.0], 0.08, "square", 0.22], [[659.0], 0.08, "square", 0.22], [[784.0], 0.08, "square", 0.22], [[1046.0, 784.0, 659.0], 0.35, "square", 0.20]],
	"error": [[[220.0], 0.07, "square", 0.22], [[180.0], 0.12, "square", 0.22]],
}

var muted: bool = false
var _streams: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _next: int = 0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rng.seed = 7
	for key: String in SOUNDS.keys():
		_streams[key] = _synth(SOUNDS[key] as Array)
	for i: int in POOL:
		var p: AudioStreamPlayer = AudioStreamPlayer.new()
		p.volume_db = -8.0
		add_child(p)
		_players.append(p)


func play(name: String, pitch: float = 1.0) -> void:
	if muted or not _streams.has(name):
		return
	if _players.is_empty():
		return
	var p: AudioStreamPlayer = _players[_next]
	_next = (_next + 1) % _players.size()
	p.stream = _streams[name] as AudioStreamWAV
	p.pitch_scale = pitch
	p.play()


func _synth(notes: Array) -> AudioStreamWAV:
	var total: int = 0
	for n: Variant in notes:
		total += int(float((n as Array)[1]) * RATE)
	var bytes: PackedByteArray = PackedByteArray()
	bytes.resize(total * 2)
	var offset: int = 0
	for n: Variant in notes:
		var freqs: Array = (n as Array)[0]
		var count: int = int(float((n as Array)[1]) * RATE)
		var wave: String = str((n as Array)[2])
		var vol: float = float((n as Array)[3])
		for i: int in count:
			var t: float = float(i) / float(RATE)
			var env: float = minf(float(i) / float(maxi(int(0.003 * RATE), 1)), 1.0) * pow(1.0 - float(i) / float(count), 1.5)
			var sample: float = 0.0
			if wave == "noise":
				sample = _rng.randf_range(-1.0, 1.0)
			else:
				for f: Variant in freqs:
					var ph: float = sin(TAU * float(f) * t)
					if wave == "square":
						sample += signf(ph) * 0.6
					else:
						sample += ph
				sample /= float(maxi(freqs.size(), 1))
			bytes.encode_s16(offset, int(clampf(sample * env * vol, -1.0, 1.0) * 32767.0))
			offset += 2
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.stereo = false
	stream.data = bytes
	return stream
