extends CharacterBody2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var jump_buffer_timer: Timer = $Timer

const bomb_scene = preload("res://scenes/bomb.tscn")

const SPEED = 160.0
const JUMP_VELOCITY = -350.0

var direction = 0
var is_jumping = false
var is_grounding = false
var was_on_floor = true
var jump_buffer_active = false

func _ready():
	jump_buffer_timer.wait_time = 0.15
	jump_buffer_timer.one_shot = true

func _physics_process(delta) -> void:
	if is_on_floor():
		if (Input.is_action_just_pressed("up") and not is_jumping) or (jump_buffer_active and not is_jumping):
			start_jump()
			jump_buffer_timer.stop()
			jump_buffer_active = false

		if not was_on_floor and not is_grounding:
			play_ground_animation()

	was_on_floor = is_on_floor()
	
	if Input.is_action_just_pressed("interact"):
		spawn_bomb()

	handle_movement(delta)
	move_and_slide()
	update_animation()



func spawn_bomb() -> void:
	if not bomb_scene:
		push_error("Bomb scene not assigned!")
		return

	var bomb = bomb_scene.instantiate()
	bomb.global_position = global_position
	get_parent().add_child(bomb)

func handle_movement(delta) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("up") and not is_on_floor():
		jump_buffer_active = true
		jump_buffer_timer.start()

	direction = Input.get_axis("left", "right")
	velocity.x = direction * SPEED

func start_jump() -> void:
	is_jumping = true
	jump()

func jump() -> void:
	sprite.play("jump_anticipation")
	await sprite.animation_finished
	velocity.y = JUMP_VELOCITY
	sprite.play("jump")
	is_jumping = false
	
func play_ground_animation() -> void:
	velocity.x = 0
	is_grounding = true
	sprite.play("ground")
	await sprite.animation_finished
	is_grounding = false

func update_animation() -> void:
	if is_grounding or sprite.animation == "jump_anticipation":
		return
	if not is_on_floor():
		play_anim("jump") if velocity.y < 0 else play_anim("fall")
	elif abs(velocity.x) > 0:
		play_anim("run")
	else:
		play_anim("idle")
	if direction > 0:
		sprite.flip_h = false
	elif direction < 0:
		sprite.flip_h = true

func play_anim(name: String) -> void:
	if sprite.animation != name:
		sprite.play(name)

func _on_timer_timeout() -> void:
	jump_buffer_active = false
