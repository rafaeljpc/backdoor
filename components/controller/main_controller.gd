
extends "res://components/controller/default_controller.gd"

const Action = preload("res://model/action.gd")

var player
var hand
var display_popup
var focuses_popup

func _ready():
  self.disable()

func event_save():
  get_node("/root/database/scene_manager").close_route()
  self.disable()

func event_idle():
  player.add_action(Action.Idle.new())

func event_up():
  move(Vector2(0, -1))

func event_down():
  move(Vector2(0, 1))

func event_right():
  move(Vector2(1, 0))

func event_left():
  move(Vector2(-1, 0))

func move(direction):
  if player.is_ready():
    var map = get_node("../../SectorView").get_current_sector()
    var target_pos = map.get_actor_body(player).pos + direction
    var body = map.get_body_at(target_pos)
    if body != null:
      player.add_action(Action.MeleeAttack.new(body))
    else:
      player.add_action(Action.Move.new(target_pos))

func set_player_map(player, hand):
  self.player = player
  self.hand = hand
  display_popup = get_node("../CardDisplay")
  focuses_popup = get_node("../FocussDisplay")
  call_deferred("enable")

func event_next_sector():
  player.add_action(Action.ChangeSector.new(1))

func event_create_slime():
  var map = get_node("../../SectorView").get_current_sector()
  var monsters = get_node("/root/database/monsters").get_children()
  monsters[randi()%monsters.size()].create(map, map.get_random_free_pos())

func event_display_card():
  if get_node("/root/RouteView/HUD/CardDisplay").is_hidden():
    self.disable()
    self.display_popup.connect("close_popup", self, "restore_input")
    self.display_popup.display(hand.get_selected_card())

func event_show_focuses():
  if get_node("/root/RouteView/HUD/FocussDisplay").is_hidden():
    self.disable()
    self.focuses_popup.connect("close_popup", self, "restore_input")
    self.focuses_popup.display(player.focuses)

func event_focus_next():
  hand.next_card()

func event_focus_prev():
  hand.prev_card()

func event_select():
  if get_node("/root/RouteView/HUD/CardDisplay").is_hidden():
    hand.get_selected_cardsprite().connect("selecting_target", self, "block_input")
    hand.get_selected_cardsprite().connect("target_selected", self, "restore_input")
    hand.user_selected_card()

func block_input():
  self.disable()

func restore_input():
  # This is necessary in order to avoid a frame where multiple controllers
  # become enabled at the same time.
  yield(get_tree(), "fixed_frame")
  self.enable()
