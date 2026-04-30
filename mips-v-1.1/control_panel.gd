extends HBoxContainer

signal step_pressed
signal run_pressed
signal reset_pressed
signal speed_changed(value)

@onready var step_btn = $ButtonStep
@onready var run_btn = $ButtonRun
@onready var reset_btn = $ButtonReset
@onready var speed_slider = $HSliderSpeed

func _ready():
	step_btn.pressed.connect(func(): step_pressed.emit())
	run_btn.pressed.connect(func(): run_pressed.emit())
	reset_btn.pressed.connect(func(): reset_pressed.emit())
	speed_slider.value_changed.connect(func(v): speed_changed.emit(v))
	
	speed_slider.min_value = 0.1
	speed_slider.max_value = 2.0
	speed_slider.value = 0.5

func set_running(running: bool):
	if running:
		run_btn.text = "⏸ Pause"
		step_btn.disabled = true
	else:
		run_btn.text = "▶ Run"
		step_btn.disabled = false
