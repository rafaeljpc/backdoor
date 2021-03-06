
extends Node2D

const ViewScene     = preload("res://game/sector/sector_view.tscn")
const Parallax      = preload("res://components/util/parallax_background.tscn")

const Tiles         = preload("res://game/sector/tiles.gd")
const Actor         = preload("res://model/actor.gd")
const Body          = preload("res://model/body.gd")
const BodyView      = preload("res://components/bodyview.gd")
const Identifiable  = preload("res://model/identifiable.gd")

var current_sector

onready var floors = get_node("floors")
onready var walls = get_node("walls")
onready var cursor = floors.get_node("cursor")
onready var matcher = get_node("Matcher")

func _ready():
  hide()

func get_cursor():
  return cursor

func get_current_sector():
  return current_sector

func load_sector(sector):
  self.current_sector = sector
  self.floors.clear()
  self.walls.clear()
  for body_view in self.walls.get_children():
    body_view.queue_free()
  for tile in sector.get_tiles():
    var value = sector.get_tile_v(tile)
    if Tiles.is_floor(value):
      self.floors.set_cell(tile.x, tile.y, value)
    if Tiles.is_wall(value):
      var match = sector.has_pattern_v(matcher, tile)
      if match != null:
        self.floors.set_cell(tile.x, tile.y, Tiles.FLOOR)
        self.walls.set_cell(tile.x, tile.y, match)
      else:
        self.walls.set_cell(tile.x, tile.y, value)
  for body in sector.get_bodies():
    _add_body_view(body)
  sector.connect("body_added", self, "_add_body_view")
  sector.connect("body_removed", self, "_remove_body_view")
  show()

func unload_sector():
  self.floors.clear()
  self.walls.clear()
  self.current_sector.disconnect("body_added", self, "_add_body_view")
  self.current_sector.disconnect("body_removed", self, "_remove_body_view")
  hide()

func _add_body_view(body):
  var bodyview = BodyView.create(body)
  if body.type != "hero":
    bodyview.set_hl_color(Color(1.0, .1, .2, .3))
  else:
    bodyview.highlight()
  get_node("walls").add_child(bodyview)
  body.connect("moved", bodyview, "set_dir")

func _remove_body_view(body):
  find_body_view(body).queue_free()

func attach_camera(actor):
  print("attaching camera")
  var bodyview = find_body_view(current_sector.get_actor_body(actor))
  var camera = Camera2D.new()
  camera.make_current()
  camera.set_enable_follow_smoothing(true)
  camera.set_follow_smoothing(5)
  bodyview.add_child(camera)
  add_bg()

func add_bg():
  var parallax_bg = Parallax.instance()
  get_node("background").add_child(parallax_bg)

func find_body_view(body):
  for bodyview in get_node("walls").get_children():
    if bodyview.body == body:
      return bodyview
  assert(false)
