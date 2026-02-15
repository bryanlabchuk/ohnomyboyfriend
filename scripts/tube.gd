class_name Tube
extends Node3D
## A 3D dice tube - appears briefly when opening, tips and "pours" contents.

@export var tube_radius: float = 0.035
@export var tube_height: float = 0.12

signal pour_complete


func play_open_animation(duration: float = 0.6) -> void:
	# Tilt tube forward to "pour"
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "rotation:x", deg_to_rad(-75), duration * 0.7)
	tween.tween_callback(func(): pour_complete.emit())
	tween.play()
