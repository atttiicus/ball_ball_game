## 全局音效管理（autoload）
## 所有音效用程序化方式生成，无需外部音频文件
extends Node

var _eat_food_player: AudioStreamPlayer
var _eat_ball_player: AudioStreamPlayer
var _die_player: AudioStreamPlayer


func _ready() -> void:
	_eat_food_player = _make_player(_gen_eat_food())
	_eat_ball_player = _make_player(_gen_eat_ball())
	_die_player = _make_player(_gen_die())


func play_eat_food() -> void:
	if not _eat_food_player.playing:
		_eat_food_player.play()


func play_eat_ball() -> void:
	_eat_ball_player.play()


func play_die() -> void:
	_die_player.play()


func _make_player(stream: AudioStream) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.stream = stream
	p.bus = "Master"
	add_child(p)
	return p


# ── 程序化波形生成 ────────────────────────────────────

func _gen_eat_food() -> AudioStreamWAV:
	return _sine_burst(880.0, 0.06, 0.5)


func _gen_eat_ball() -> AudioStreamWAV:
	return _sine_burst(440.0, 0.18, 0.7)


func _gen_die() -> AudioStreamWAV:
	return _sine_burst(220.0, 0.35, 0.4)


func _sine_burst(freq: float, duration: float, volume: float) -> AudioStreamWAV:
	var sample_rate := 22050
	var sample_count := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(sample_count * 2)  # 16-bit mono

	for i in sample_count:
		var t := float(i) / sample_rate
		var env := 1.0 - (t / duration)  # 线性衰减
		var sample := sin(TAU * freq * t) * env * volume
		var s16 := int(clampf(sample * 32767.0, -32768, 32767))
		data[i * 2]     = s16 & 0xFF
		data[i * 2 + 1] = (s16 >> 8) & 0xFF

	var wav := AudioStreamWAV.new()
	wav.data = data
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	return wav
