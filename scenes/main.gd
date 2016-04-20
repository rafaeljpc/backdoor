
extends Node2D

const Action   = preload("res://model/action.gd")
const Actor    = preload("res://model/actor.gd")
const Body     = preload("res://model/body.gd")
const BodyView = preload("res://scenes/bodyview.gd")

onready var preload_bodies = [
	[Body.new("hero", Vector2(22,8), 10), get_node("/root/player")],
	[Body.new("slime", Vector2(22,6), 10), Actor.new()],
	[Body.new("slime", Vector2(24,6), 10), Actor.new()],
	[Body.new("slime", Vector2(26,6), 10), Actor.new()],
	[Body.new("slime", Vector2(28,6), 10), Actor.new()],
]

var bodies
var actor_bodies
onready var player = get_node("/root/player")
onready var map    = get_node("map")

func _ready():
	set_fixed_process(true)
	bodies = []
	actor_bodies = {}
	for entry in preload_bodies:
		add_body(entry[0])
		add_actor(entry[0],entry[1])
	manage_actors()
	set_process_input(true)

func add_body(body):
	var bodyview = BodyView.create(body)
	bodies.append(body)
	map.walls.add_child(bodyview)

func add_actor(body, actor):
	get_node("map/actors").add_child(actor)
	actor_bodies[actor] = body
	var module = preload("res://model/ai/wander.gd").new()
	actor.add_child(module)

func move_actor(actor, new_pos):
	move_body(actor_bodies[actor], new_pos)

func move_body(body, new_pos):
	body.pos = new_pos

func get_actor_body(actor):
	return actor_bodies[actor]

func get_body_at(pos):
	for body in bodies:
		if body.pos == pos:
			return body
	return null

func manage_actors():
	while true:
		for actor in actor_bodies:
			actor.step_time()
			if actor.is_ready():
				if !actor.has_action():
					yield(actor, "has_action")
				actor.use_action()
		yield(get_tree(), "fixed_frame" )

func _fixed_process(delta):
	for actor in actor_bodies:
		if actor != player and !actor.has_action() and actor.is_ready():
			actor.pick_ai_module().think()

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		get_tree().finish()
	if player.is_ready():
		var move = Vector2(0,0)
		if event.is_action_pressed("ui_down"):
			move.y += 1
		elif event.is_action_pressed("ui_up"):
			move.y -= 1
		elif event.is_action_pressed("ui_right"):
			move.x += 1
		elif event.is_action_pressed("ui_left"):
			move.x -= 1
		if event.is_action_pressed("ui_idle"):
			player.add_action(Action.Idle.new())
		elif move.length_squared() > 0:
			var target_pos = bodies[0].pos + move
			var body = get_body_at(target_pos)
			if body != null:
				player.add_action(Action.MeleeAttack.new(body))
			else:
				player.add_action(Action.Move.new(target_pos))
