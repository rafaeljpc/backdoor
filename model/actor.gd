
extends "res://game/core/backdoor_node.gd"

const SlotItem = preload("res://model/cards/card_item.gd").SlotItem

const FOCUS_SLOT_MAX  = 3

const ATTR_ATHLETICS    = 0
const ATTR_ARCANA       = 1
const ATTR_TECH         = 2
const ATTR_MAX          = 3

const DRAW_TIME         = 120
const BASE_COOLDOWN     = 100
const HAND_MAX          = 5
const ACC_CONSUME       = 10

class Card:
  var card_ref
  func _init(ref):
    card_ref = ref
  func get_name():
    return card_ref.get_name()
  func get_description():
    return card_ref.get_description()
  func get_ref():
    return card_ref


# Stats
var char_name
var base_attributes_
var speed = 10
var draw_rate = 5
var draw_rate_bonus_multiplier = 1

# Play state
var cooldown
var draw_cooldown
var action

# Play zones
var hand
var deck
var focuses
# Item slots
var weapon
var suit
var accessory

signal has_action
signal spent_action
signal draw_card(card)
signal consumed_card(card)
signal update_deck
signal equipped_item(item, slot_type)

func _init(name):
  hand = []
  deck = []
  focuses = []
  char_name = name
  base_attributes_ = []
  base_attributes_.resize(ATTR_MAX)
  for attr in range(ATTR_MAX):
    base_attributes_[attr] = 0

func _ready():
  cooldown = 100/speed
  draw_cooldown = DRAW_TIME
  if weapon != null:
    emit_signal("equipped_item", weapon.get_ref(), SlotItem.WEAPON)
  if suit != null:
    emit_signal("equipped_item", suit.get_ref(), SlotItem.SUIT)
  if accessory != null:
    emit_signal("equipped_item", accessory.get_ref(), SlotItem.ACCESSORY)

func get_attribute(which):
  assert(which >= 0 and which < ATTR_MAX)
  var value = base_attributes_[which]
  for focus in focuses:
    var card = focus.get_ref()
    if card.get_card_attribute() == which:
      value += card.get_bonus_amount()
  return value

func get_static_effect(which):
  var value = 0
  for focus in focuses:
    var card = focus.get_ref()
    if card.has_static_effect(which):
      value += card.get_static_effect()
  return value

func check_triggers(which, params):
  for focus in focuses:
    var card = focus.get_ref()
    if card.has_trigger_effect(which):
      card.trigger(self, params)

func get_athletics():
  return get_attribute(ATTR_ATHLETICS)

func get_arcana():
  return get_attribute(ATTR_ARCANA)

func get_tech():
  return get_attribute(ATTR_TECH)

func get_speed():
  return speed + get_static_effect("speed_bonus")

func get_melee_damage():
  if weapon != null:
    weapon.get_ref().consume_item()
    var damage = weapon.get_ref().calculate_damage(self)
    #printt("Hit with", weapon.get_ref().get_name(), "damage done", damage)
    if weapon.get_ref().get_durability() < 0:
      weapon = null
      emit_signal("equipped_item", null, SlotItem.WEAPON)
    return damage
  return get_athletics() + 1 + randi()%6

func get_body():
  return get_node("/root/Route").get_current_sector().get_actor_body(self)

func get_body_pos():
  return get_body().pos

func can_draw():
  return hand.size() < HAND_MAX and deck.size() > 0

func consume_card(card):
  hand.erase(card)
  emit_signal("consumed_card", card)

func step_time():
  cooldown = max(0, cooldown - 1)
  while draw_cooldown <= 0 and can_draw():
    hand.append(deck[0])
    deck.remove(0)
    draw_cooldown += DRAW_TIME
    emit_signal("draw_card", hand[hand.size() - 1])
    emit_signal("update_deck")
  if accessory != null:
    if accessory.get_ref().get_durability() > 0:
      accessory.get_ref().consume_item()
    else:
      accessory.get_ref().finish_effect(self)
      accessory = null
      emit_signal("equipped_item", self.accessory, SlotItem.ACCESSORY)
  if can_draw():
    draw_cooldown -= draw_rate()

func draw_rate():
  return draw_rate * draw_rate_bonus_multiplier

func set_draw_rate_bonus_multiplier(bonus_multiplier):
  self.draw_rate_bonus_multiplier = bonus_multiplier

func set_focus(focus):
  if focuses.size() == FOCUS_SLOT_MAX:
    return
  if focus extends Card:
    focuses.push_back(focus)
  else:
    focuses.push_back(Card.new(focus))

func equip_item(card):
  if card.get_slot() == SlotItem.WEAPON:
    self.weapon = Card.new(card)
  elif card.get_slot() == SlotItem.SUIT:
    self.suit = Card.new(card)
    get_body().set_absorption(card.get_absorption())
    get_body().connect("damage_taken", self, "consume_armory")
    get_body().connect("damage_taken", self, "_on_damage_taken")
  elif card.get_slot() == SlotItem.ACCESSORY:
    self.accessory = Card.new(card)
    card.init_effect(self)
  emit_signal("equipped_item", card, card.get_slot())

func _on_damage_taken(amount, source):
  check_triggers("damage_taken", { "amount": amount, "source": source })

func consume_armory():
  if self.suit == null:
    return
  self.suit.get_ref().consume_item()
  printt("consume armor durability=", self.suit.get_ref().get_durability())
  if self.suit.get_ref().get_durability() < 0:
    get_body().set_absorption(0)
    get_body().disconnect("damage_taken", self, "consume_armory")
    self.suit = null
    emit_signal("equipped_item", self.suit, SlotItem.SUIT)

func is_ready():
  return cooldown == 0

func has_action():
  return action != null

func add_action(the_action):
  if !has_action() and the_action.can_be_used(self):
    action = the_action
    #print(get_name(), ": added action ", action.get_type())
    emit_signal("has_action")

func use_action():
  #print(get_name(), ": used action ", action.get_type())
  if self.suit != null and !get_body().is_connected("damage_taken", self, "consume_armory"):
    get_body().connect("damage_taken", self, "consume_armory")
  cooldown += action.get_cost(self)/get_speed()
  action.use(self)
  action = null
  emit_signal("spent_action")

func pick_ai_module():
  var total = 0
  for module in get_children():
    total += module.chance
  var roll = total*randf()
  var acc = 0
  for module in get_children():
    acc += module.chance
    if acc >= roll:
      return module
  return get_child(0)

static func get_card_id(cards_db, card):
  return cards_db.get_card_id(card.get_ref())

static func serialize_card_array(cards_db, card_array):
  var array_data = []
  for card in card_array:
    array_data.append(get_card_id(cards_db, card))
  return array_data

func serialize(db):
  var sector = get_parent().get_parent()
  var actor_data = {}
  actor_data["name"] = char_name
  actor_data["cooldown"] = cooldown
  actor_data["drawcooldown"] = draw_cooldown

  var cards_db = db.get_node("cards")
  printt("cards_db", cards_db)

  if weapon != null:
    actor_data["weapon"] = get_card_id(cards_db, weapon)
  if suit != null:
    actor_data["suit"] = get_card_id(cards_db, suit)
  if accessory != null:
    actor_data["accessory"] = get_card_id(cards_db, accessory)

  actor_data["hand"] = serialize_card_array(cards_db, hand)
  actor_data["deck"] = serialize_card_array(cards_db, deck)
  actor_data["focuses"] = serialize_card_array(cards_db, focuses)

  actor_data["body_id"] = sector.get_actor_body(self).get_id()
  var ai_modules_data = []
  for module in get_children():
    var module_data = {}
    module_data["name"] = module.get_name()
    module_data["chance"] = module.chance
    ai_modules_data.append(module_data)
  actor_data["ai_modules"] = ai_modules_data
  return actor_data

static func load_card(cards_db, card_id):
  return Card.new(cards_db.get_child(card_id))

static func unserialize_card_array(cards_db, actor_property, card_array):
  for card_id in card_array:
    actor_property.append(load_card(cards_db, card_id))

static func unserialize(data, db):
  var actor = new(data["name"])
  actor.cooldown = data["cooldown"]
  actor.draw_cooldown = data["drawcooldown"]

  var cards_db = db.get_node("cards")

  print("data=", data)

  if data.has("weapon"):
    actor.weapon = load_card(cards_db, data["weapon"])
  if data.has("suit"):
    actor.suit = load_card(cards_db, data["suit"])
  if data.has("accessory"):
    actor.accessory = load_card(cards_db, data["accessory"])

  unserialize_card_array(cards_db, actor.hand, data["hand"])
  unserialize_card_array(cards_db, actor.deck, data["deck"])

  if data.has("focuses"):
    for card_id in data["focuses"]:
      var upg = load_card(cards_db, card_id)
      actor.set_focus(upg)

  var ai_modules = data["ai_modules"]
  for module in ai_modules:
    var ai = Node.new()
    ai.set_script(load("res://model/ai/" + module["name"] + ".gd"))
    ai.set_name(module["name"])
    ai.chance = module["chance"]
    actor.add_child(ai)
  return actor
