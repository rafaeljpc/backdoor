
extends "res://model/cards/card_skill.gd"

func valid_target(actor, target):
  var map = get_current_sector()
  return dist(actor,target) <= 10 and map.get_body_at(target) != null

func get_options(actor):
  return [
    { "type": "TARGET", "check": funcref(self, "valid_target"), "aoe":null }
  ]

func evoke(actor, options):
  var target = options[0]
  var map = get_current_sector()
  var body = map.get_body_at(target)
  body.take_damage(5, actor)
