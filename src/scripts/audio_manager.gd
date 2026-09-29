extends Node

const SAMPLE_RATE := 22050
const MUSIC_SECONDS := 12.0

var _music_player: AudioStreamPlayer
var _sfx_cache: Dictionary = {}
var _audio_enabled := true


func _ready() -> void:
	_audio_enabled = DisplayServer.get_name() != "headless"
	if not _audio_enabled:
		return
	_music_player = AudioStreamPlayer.new()
	_music_player.name = "MusicPlayer"
	_music_player.stream = _build_music_loop()
	add_child(_music_player)
	_refresh_volume()
	_music_player.play()
	if GameSession.progress_changed.is_connected(_refresh_volume) == false:
		GameSession.progress_changed.connect(_refresh_volume)


func play_ui() -> void:
	play_sfx("ui", 1.0, 0.72)


func play_sfx(sound_name: String, pitch_scale: float = 1.0, gain: float = 1.0) -> void:
	if not _audio_enabled:
		return
	var setting := GameSession.get_sfx_volume()
	if setting <= 0.001:
		return
	var stream: AudioStreamWAV = _sfx_cache.get(sound_name)
	if stream == null:
		stream = _build_sfx(sound_name)
		_sfx_cache[sound_name] = stream
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.pitch_scale = clampf(pitch_scale, 0.65, 1.5)
	player.volume_db = linear_to_db(clampf(setting * gain, 0.001, 1.0))
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()


func stop_all() -> void:
	if not _audio_enabled:
		return
	for child in get_children():
		if child is AudioStreamPlayer:
			child.stop()
			child.stream = null
	_sfx_cache.clear()


func _refresh_volume() -> void:
	if not is_instance_valid(_music_player):
		return
	var setting := GameSession.get_music_volume()
	_music_player.volume_db = linear_to_db(maxf(setting * 0.52, 0.001))
	_music_player.stream_paused = setting <= 0.001


func _build_sfx(sound_name: String) -> AudioStreamWAV:
	var duration := 0.14
	var start_frequency := 260.0
	var end_frequency := 160.0
	var noise_mix := 0.08
	match sound_name:
		"fire":
			duration = 0.11
			start_frequency = 210.0
			end_frequency = 82.0
			noise_mix = 0.34
		"enemy_fire":
			duration = 0.1
			start_frequency = 150.0
			end_frequency = 70.0
			noise_mix = 0.28
		"impact":
			duration = 0.13
			start_frequency = 120.0
			end_frequency = 58.0
			noise_mix = 0.62
		"explosion":
			duration = 0.34
			start_frequency = 96.0
			end_frequency = 38.0
			noise_mix = 0.7
		"pickup":
			duration = 0.28
			start_frequency = 420.0
			end_frequency = 940.0
			noise_mix = 0.03
		"wave":
			duration = 0.42
			start_frequency = 360.0
			end_frequency = 760.0
			noise_mix = 0.02
		"victory":
			duration = 0.72
			start_frequency = 440.0
			end_frequency = 880.0
			noise_mix = 0.01
		"defeat":
			duration = 0.58
			start_frequency = 190.0
			end_frequency = 72.0
			noise_mix = 0.18
		_:
			duration = 0.075
			start_frequency = 520.0
			end_frequency = 690.0
			noise_mix = 0.02

	var sample_count := int(duration * SAMPLE_RATE)
	var bytes := PackedByteArray()
	bytes.resize(sample_count * 2)
	var phase := 0.0
	var noise_state := absi(sound_name.hash()) + 7919
	for index in range(sample_count):
		var progress := float(index) / float(maxi(sample_count - 1, 1))
		var frequency := lerpf(start_frequency, end_frequency, progress)
		phase += TAU * frequency / float(SAMPLE_RATE)
		noise_state = int((noise_state * 1103515245 + 12345) & 0x7fffffff)
		var noise := float(noise_state % 65536) / 32767.5 - 1.0
		var attack := minf(progress / 0.035, 1.0)
		var decay := pow(1.0 - progress, 1.7)
		var harmonic := sin(phase) * 0.72 + sin(phase * 2.01) * 0.18
		if sound_name in ["pickup", "wave", "victory"]:
			harmonic += sin(phase * 1.5) * 0.16
		var sample := clampf((harmonic * (1.0 - noise_mix) + noise * noise_mix) * attack * decay, -1.0, 1.0)
		bytes.encode_s16(index * 2, int(sample * 24500.0))
	return _make_wav(bytes)


func _build_music_loop() -> AudioStreamWAV:
	var sample_count := int(MUSIC_SECONDS * SAMPLE_RATE)
	var bytes := PackedByteArray()
	bytes.resize(sample_count * 2)
	var roots := [55.0, 65.41, 49.0, 73.42]
	for index in range(sample_count):
		var time := float(index) / float(SAMPLE_RATE)
		var section := mini(int(time / 3.0), roots.size() - 1)
		var root: float = roots[section]
		var beat_phase := fmod(time, 0.5) / 0.5
		var pulse := pow(1.0 - beat_phase, 4.0)
		var bass := sin(TAU * root * time) * (0.22 + pulse * 0.16)
		var fifth := sin(TAU * root * 1.5 * time) * 0.09
		var shimmer := sin(TAU * root * 4.0 * time + sin(time * 0.7)) * (0.035 + pulse * 0.025)
		var boundary_fade := minf(minf(time / 0.08, (MUSIC_SECONDS - time) / 0.08), 1.0)
		var sample := clampf((bass + fifth + shimmer) * boundary_fade, -1.0, 1.0)
		bytes.encode_s16(index * 2, int(sample * 24500.0))
	var stream := _make_wav(bytes)
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = sample_count
	return stream


func _make_wav(bytes: PackedByteArray) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = bytes
	return stream
