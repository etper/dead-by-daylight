extends Node3D

@export var repair_time := 10.0

var repair_progress := 0.0
var is_player_near := false
var completed := false

@onready var progress_bar = $"../CanvasLayer/ProgressBar"

func _ready():
	progress_bar.visible = false

func _process(delta):

	progress_bar.value = (repair_progress / repair_time) * 100

	if completed:
		return

	if is_player_near and Input.is_action_pressed("interact"):

		repair_progress += delta

		print(repair_progress / repair_time)

		if repair_progress >= repair_time:
			complete_generator()

func complete_generator():

	completed = true

	print("GENERATOR COMPLETE")

func _on_area_3d_body_entered(body):

	if body.name == "Player":
		is_player_near = true
		progress_bar.visible = true

func _on_area_3d_body_exited(body):

	if body.name == "Player":
		is_player_near = false
		progress_bar.visible = false
