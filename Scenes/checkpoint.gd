extends Node2D
@onready var collision_shape_2d = $Area2D/CollisionShape2D

func _ready():
	Stats.connect("checkpoint", enable)

func _on_area_2d_body_entered(body):
	if body.is_in_group("player"):
		Stats.checkpoint.emit(body.global_position)
		collision_shape_2d.set_deferred("disabled", true)

func enable(v):
	collision_shape_2d.set_deferred("disabled", false)
