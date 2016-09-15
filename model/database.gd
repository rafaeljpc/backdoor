
extends Node

const RouteScene = preload("res://model/route.tscn")
const RouteAssembler = preload("res://components/util/mapgen/route_assembler.gd")

const Route = preload("res://model/route.gd")
const Actor = preload("res://model/actor.gd")
const Body = preload("res://model/body.gd")

onready var loading = get_node("/root/loading")
onready var map_generator = get_node("map_generator")
onready var profile = get_node("profile")

func get_profile():
  return profile

func erase_route(id):
  profile.erase_journal(id)

func create_route():
  var route_id = profile.find_free_route_id()
  var assembler = RouteAssembler.new(route_id)
  profile.add_journal(route_id)
  assembler.new_sector()
  var w = 64
  var h = 64
  map_generator.generate_map(w, h, assembler)
  assembler.make_sector_current()
  assembler.new_body("hero", 10, 0, null)
  assembler.new_actor("hero", 10)
  var cards_db = get_node("cards")
  for i in range(20):
    var card_id = i % cards_db.get_child_count()
    assembler.add_to_actor_deck(card_id)
  assembler.make_actor_player()
  do_load_route(assembler.get_route_data())
  ##
  #route.get_node("sectors").add_child(map_node)
  #map_node.show()
  #get_node("/root/sector").set_player(player)
  #get_parent().add_child(route)
  #loading.end()

func load_route(id):
  var file = profile.get_journal_file_reader(id)
  assert(file != null)
  var data = {}
  data.parse_json(file.get_as_text())
  file.close()
  do_load_route(data)

func do_load_route(route_data):
  var route = Route.unserialize(route_data, self)
  get_node("/root/sector").set_player(route.player)
  get_parent().call_deferred("add_child", route)
  loading.end()

func save_route():
  var route = get_node("/root/route")
  do_save_route(route, route.player)

func do_save_route(route, player):
  var file = profile.get_journal_file_writer(route.id)
  assert(file != null)
  file.store_string(route.serialize(self, player).to_json())
  file.close()
  print("SAVED")

func finish():
  if get_node("/root/").has_node("route"):
    save_route()
  profile.save()
  get_tree().quit()
