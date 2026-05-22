extends CharacterBody3D

@export var walk_speed := 2.2
@export var run_speed := 4.0
@export var crouch_speed := 1.2
@export var acceleration := 10.0
@export var gravity := 20.0

@export var mouse_sensitivity := 0.12

@onready var camera_pivot = $CameraPivot
@onready var camera = $CameraPivot/Camera3D

@export var heal_time := 8.0

@export var is_dummy := false

var heal_progress := 0.0
var is_being_healed := false

var nearby_player = null

enum HealthState {
	HEALTHY,
	INJURED,
	DYING
}

var health_state = HealthState.HEALTHY

var current_speed := 0.0
var is_crouching := false

var pitch := 0.0

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	if is_dummy:
		health_state = HealthState.INJURED

func _unhandled_input(event):

	# mouse look
	if event is InputEventMouseMotion:

		# horizontal look
		rotate_y(deg_to_rad(-event.relative.x * mouse_sensitivity))

		# vertical look
		pitch -= event.relative.y * mouse_sensitivity
		pitch = clamp(pitch, -80, 80)

		camera_pivot.rotation_degrees.x = pitch

func _physics_process(delta):

	if is_dummy:
		return

	if Input.is_action_just_pressed("ui_accept"):
		health_state = HealthState.INJURED
		print("INJURED")

	handle_healing(delta)

	# gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

	# input
	var input_dir := Input.get_vector(
		"move_left",
		"move_right",
		"move_forward",
        "move_back"
	)

	# convert movement relative to camera/player direction
	var direction := (
		transform.basis * Vector3(
			input_dir.x,
			0,
			input_dir.y
		)
	).normalized()

	# choose speed
	if is_crouching:
		current_speed = crouch_speed
	elif Input.is_action_pressed("sprint") and input_dir.y < 0:
		current_speed = run_speed
	else:
		current_speed = walk_speed

	# smooth movement
	var target_velocity := direction * current_speed

	velocity.x = lerp(
		velocity.x,
		target_velocity.x,
		acceleration * delta
	)

	velocity.z = lerp(
		velocity.z,
		target_velocity.z,
		acceleration * delta
	)

	# crouch
	if Input.is_action_pressed("crouch"):
		crouch()
	else:
		uncrouch()

	move_and_slide()

func crouch():
	is_crouching = true

	scale.y = lerp(scale.y, 0.6, 0.2)

	camera_pivot.position.y = lerp(
		camera_pivot.position.y,
		1.0,
		0.2
	)

func uncrouch():
	is_crouching = false

	scale.y = lerp(scale.y, 1.0, 0.2)

	camera_pivot.position.y = lerp(
		camera_pivot.position.y,
		1.6,
		0.2
	)

func _on_heal_area_body_entered(body):

	if body != self and body.name == "Player":
		nearby_player = body
		print("ENTERED AREA: ", body.name)

func _on_heal_area_body_exited(body):

	if body == nearby_player:
		nearby_player = null
		print("EXITED AREA: ", body.name)

func handle_healing(delta):

	if nearby_player == null:
		return

	if nearby_player.health_state != HealthState.INJURED:
		return

	if Input.is_action_pressed("interact"):

		print("HEAL FUNCTION RUNNING")

		nearby_player.heal_progress += delta

		print(nearby_player.heal_progress / nearby_player.heal_time)

		if nearby_player.heal_progress >= nearby_player.heal_time:

			nearby_player.health_state = HealthState.HEALTHY
			nearby_player.heal_progress = 0.0

			print("PLAYER HEALED")
