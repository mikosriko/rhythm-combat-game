extends Control

const VIEWPORT_LENGTH : float = 1920 # HACK - Potentially might break if float and not int?

@export var start_point : Vector2

var start_point_offset : float
var beat_scene = load("res://Scenes/beat.tscn")
var beats_array_left = []
var beats_array_right = []
var tweens_array_left = []
var tweens_array_right = []
var tweens_playing_left = []
var tweens_playing_right = []

var beat_length : float
var num_of_beats := 0
var newest_beat := 0
var oldest_beat := 0
var total_beats_spawned := 0

#var is_mouse_clicked = false
var is_mouse_disabled = false
var is_tween_done = false
var is_timer_done = false

var score := 0

#var previous_print = str("")

@onready var time_between_beats: Timer = $time_between_beats
@onready var container: AspectRatioContainer = $AspectRatioContainer
@onready var timing_result: Label = $TimingResult
@onready var timing_score: Label = $TimingScore
@onready var conductor: AudioStreamPlayer = $Conductor

# NEXT - Change variables to match music conventions (BPM, Bars, Signature, etc.)
# NEXT - Able to insert a song that matches with the tracker

func _ready() -> void:
	num_of_beats = conductor.stream.bar_beats
	
	for i in num_of_beats:
		var beat_left = beat_scene.instantiate()
		var beat_right = beat_scene.instantiate()
		container.add_child(beat_left)
		container.add_child(beat_right)
		#beat_left.set_global_position(Vector2(-9999,-9999))
		#beat_right.set_global_position(Vector2(-9999,-9999))
		beats_array_left.append(beat_left)
		beats_array_right.append(beat_right)
		tweens_playing_left.append(false)
		tweens_playing_right.append(false)
	
	timing_result.text = ""
	timing_score.text = "0"
	score = 0
	
	updating_start_point()
	
	time_between_beats.wait_time = 60 / conductor.stream.bpm
	beat_length = time_between_beats.wait_time * num_of_beats
	pass
	
	#if (beats_array_left.size() == 0 || num_of_beats == 0):
		#queue_free()
		#pass
	#
	#if (beats_array_left.size() == 1 || num_of_beats == 1):
		#time_between_beats.wait_time = beat_length
		#pass
		#
	#if (beats_array_left.size() > 1 || num_of_beats > 1):
		#time_between_beats.wait_time = beat_length / num_of_beats
		#pass

func _physics_process(delta: float) -> void:
	pass
				
func _process(delta: float) -> void:
	#if previous_print != str("Newest Beat: ", newest_beat, " | Oldest Beat: ", oldest_beat):
		#print("Newest Beat: ", newest_beat, " | Oldest Beat: ", oldest_beat)
		#previous_print = str("Newest Beat: ", newest_beat, " | Oldest Beat: ", oldest_beat)
	
	#print(time_between_beats.time_left)
	updating_start_point()
	#print(get_viewport().get_visible_rect().size)
	
	if !conductor.has_stream_playback():
		return
		
	if tweens_playing_left[newest_beat] == false && tweens_playing_right[newest_beat] == false:
		print("Time started")
		time_between_beats.start()
		play_tween()
		
		if total_beats_spawned != num_of_beats:
			total_beats_spawned += 1
		print(total_beats_spawned)
		
	if !is_mouse_disabled && Input.is_action_just_pressed("click") && tweens_array_left.size() > 0:
		if total_beats_spawned == num_of_beats && time_between_beats.time_left < 0.1:
			timing_result.text = "GOOD"
			timing_result.label_settings.font_color = Color.LIME_GREEN
			score += 1
		else:
			timing_result.text = "EARLY"
			timing_result.label_settings.font_color = Color.PERU
			score = 0
		timing_score.text = str(score)
			
		is_mouse_disabled = true
		is_tween_done = true
		kill_oldest_tweens()
		
	elif is_tween_done && is_timer_done:
		print("Tween done & Timer done")
		if !is_mouse_disabled:
			kill_oldest_tweens()
			
		tweens_playing_left[oldest_beat] = false
		tweens_playing_right[oldest_beat] = false
		reset_bools(true)

		if newest_beat == num_of_beats - 1:
			newest_beat = 0
		else:
			newest_beat += 1
		
		if oldest_beat == num_of_beats - 1:
			oldest_beat = 0
		else:
			oldest_beat += 1
		
	elif is_timer_done:
		print("Timer done")
		if newest_beat == num_of_beats - 1:
			newest_beat = 0
		else:
			newest_beat += 1
		reset_bools(true)

func play_tween() -> void:
	add_tween("position", Vector2(VIEWPORT_LENGTH / 2, start_point.y), beat_length)
	tweens_playing_left[newest_beat] = true
	tweens_playing_right[newest_beat] = true

func add_tween(property: String, value, seconds: float) -> void:
	beats_array_left[newest_beat].position = start_point
	beats_array_right[newest_beat].position = Vector2((get_viewport().get_visible_rect().size).x - start_point.x, start_point.y)
	
	var tween = get_tree().create_tween()
	tween.tween_property(beats_array_left[newest_beat], property, value, seconds).set_trans(Tween.TRANS_LINEAR)
	if tweens_array_left.size() == num_of_beats:
		tweens_array_left[newest_beat] = tween
	else:
		tweens_array_left.append(tween)
		
	tween.set_parallel()
	
	tween.tween_property(beats_array_right[newest_beat], property, value, seconds).set_trans(Tween.TRANS_LINEAR)
	if tweens_array_right.size() == num_of_beats:
		tweens_array_right[newest_beat] = tween
	else:
		tweens_array_right.append(tween)
	tween.connect("finished", _on_tween_finished)
	
	print("TWEEN ADDED")

func _on_tween_finished() -> void:
	is_tween_done = true

func _on_time_between_beats_timeout() -> void:
	#time_between_beats.stop()
	is_timer_done = true

func kill_oldest_tweens() -> void:
	tweens_array_left[oldest_beat].kill()
	beats_array_left[oldest_beat].set_position(Vector2(-9999, -9999))
	tweens_array_right[oldest_beat].kill()
	beats_array_right[oldest_beat].set_position(Vector2(-9999, -9999))
	print("DELETE TWEEN ", oldest_beat)
	total_beats_spawned -= 1

func reset_bools(enable_mouse : bool) -> void:
	if enable_mouse:
		is_mouse_disabled = false
	
	is_tween_done = false
	is_timer_done = false

func updating_start_point() -> void:
	start_point_offset = get_viewport().get_visible_rect().size.x - VIEWPORT_LENGTH
	start_point = Vector2(-start_point_offset, start_point.y)
