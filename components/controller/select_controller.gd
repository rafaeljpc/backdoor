
extends "res://components/controller/default_controller.gd"

signal move_selection(direction)
signal confirm()
signal cancel()

func event_up():
  emit_signal("move_selection", Vector2(0, -1))

func event_down():
  emit_signal("move_selection", Vector2(0, 1))

func event_right():
  emit_signal("move_selection", Vector2(1, 0))

func event_left():
  emit_signal("move_selection", Vector2(-1, 0))

func event_select():
  self.disable()
  emit_signal("confirm")

func event_cancel():
  self.disable()
  emit_signal("cancel")
  self.get_tree().set_input_as_handled()
