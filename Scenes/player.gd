extends CharacterBody2D

@onready var sfx = $sfx
@onready var light_detection = $SubViewport/LightDetection
@onready var sub_viewport = $SubViewport
@onready var camera_2d = $SubViewport/LightDetection/Camera2D
#@onready var color_rect = $SubViewport/LightDetection/ColorRect
@onready var texture_rect = $SubViewport/LightDetection/TextureRect
@onready var tm_dash = $tmDash

const SPEED = 300.0
const JUMP_VELOCITY = -400.0
const DASH_SPEED = 1500

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var push_force = 80
var isLit = false
var isDashing = false
var maxDashes = 1
var dashes = 1

var dashDirection = Vector2()

var health = 100
var maxHealth = 100

func _ready():
	sub_viewport.debug_draw = 2
	sub_viewport.world_2d = get_tree().root.world_2d
	#Stats.emit_signal("setMaxHealth", maxHealth)

func _process(_delta):
	#camera_2d.global_transform.origin = global_position
	#Light detection
	light_detection.global_position = global_position
	var texture = sub_viewport.get_texture()
	texture_rect.texture = texture
	var color = get_average_color(texture)
	isLit = color.get_luminance() > 0.5
	#print(color.get_luminance())
	if isLit:
		#sfx.playBurning(health)
		#maybe take more damage from brightness
		getHurt(1 * color.get_luminance())
	elif health < maxHealth:
		#sfx.stopBurning()
		heal(1)

func upgradeMaxHealth():
	maxHealth += 50
	Stats.emit_signal("setMaxHealth", maxHealth)

func heal(v):
	health += v
	if health > maxHealth:
		health = maxHealth
	Stats.emit_signal("healthChanged", health)

func getHurt(value):
	health -= value
	Stats.emit_signal("healthChanged", health)
	if health <= 0:
		die()

func die():
	queue_free()

func get_average_color(texture):
	var image = texture.get_image()
	image.resize(1,1, Image.INTERPOLATE_LANCZOS)
	return image.get_pixel(0,0)

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor() && !isDashing:
		velocity.y += gravity * delta
	elif is_on_floor():
		dashes = maxDashes

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction = Input.get_axis("left", "right")
	if direction && !isDashing:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		
	# Handle dash.
	if Input.is_action_just_pressed("dash") && !isDashing && dashes > 0 && direction != 0:
		dashes -= 1
		health -= 25
		if health <= 0:
			health = 1
		isDashing = true
		dashDirection = Vector2(direction, Input.get_axis("up", "down"))
		tm_dash.start(0.1)

	if isDashing && !tm_dash.is_stopped():
		velocity.x = dashDirection.x * DASH_SPEED
		velocity.y = dashDirection.y * (DASH_SPEED / 4)

	move_and_slide()
	
	for i in get_slide_collision_count():
		var c = get_slide_collision(i)
		if c.get_collider() is RigidBody2D:
			c.get_collider().apply_central_impulse(-c.get_normal() * push_force)

#Fall through one way platform
#func _input(event):
	#if(event.is_action_pressed("down") && is_on_floor()):
		#position.y += 1

func _on_tm_dash_timeout():
	isDashing = false