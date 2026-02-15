extends Node2D
## Minimal test: draws directly to viewport. If you see a red screen, rendering works.

func _ready() -> void:
	queue_redraw()

func _draw() -> void:
	var vp := get_viewport()
	var size := vp.get_visible_rect().size
	# Draw bright red rect covering visible area
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.9, 0.15, 0.15, 1))
