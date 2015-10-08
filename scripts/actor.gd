
extends Sprite

class Card:
	var name
	func _init(the_name):
		name = the_name

var cooldown
var draw_cooldown
var action
var hand
var deck
export var speed = 10

const DRAW_TIME = 40

const COSTS = {
	"idle": 100,
	"move": 100
}

signal has_action
signal spent_action
signal draw_card(card)

func _ready():
	cooldown = 0
	draw_cooldown = DRAW_TIME
	hand = []
	deck = []
	deck.append(Card.new("Black Lotus"))
	deck.append(Card.new("Dr. Boom"))
	deck.append(Card.new("Exodia"))

func step_time():
	cooldown = max(0, cooldown - 1)
	draw_cooldown = max(0, draw_cooldown - 1)

func check_draw():
	if draw_cooldown == 0 and deck.size() > 0:
		hand.append(deck[0])
		deck.remove(0)
		draw_cooldown = DRAW_TIME
		emit_signal("draw_card", hand[hand.size() - 1])

func is_ready():
	return cooldown == 0

func has_action():
	return action != null

func get_action():
	var the_action = action
	cooldown += COSTS[action.type]/speed
	action = null
	emit_signal("spent_action")
	return the_action
	
func add_action(the_action):
	if !has_action():
		action = the_action
		emit_signal("has_action")
