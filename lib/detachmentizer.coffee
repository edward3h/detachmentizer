class Category
  @_prefix_map: {}
  
  constructor: (@name, prefixes...) ->
    @constructor._prefix_map[prefix.toLowerCase()] = this for prefix in prefixes
    @constructor._prefix_map[@name.toLowerCase()] = this

  @for_prefix: (prefix) ->
    @_prefix_map[prefix.toLowerCase()]
    
  toString: () ->
    @name
    
  toLowerCase: () ->
    @name.toLowerCase()

HQ = new Category "HQ", "HQ"
TROOPS = new Category "Troops", "Tr", "T"
ELITES = new Category "Elites", "El", "E"
FAST = new Category "Fast Attack", "FA"
HEAVY = new Category "Heavy Support", "HS", "H"
FORTIFICATION = new Category "Fortification", "Ft", "Fn"
LORD_OF_WAR = new Category "Lord of War", "LW", "LOW", "L"
FLYER = new Category "Flyer", "Flier", "Fl"
TRANSPORT = new Category "Dedicated Transport", "Transport", "DT"

ALL_CATEGORIES = [HQ, TROOPS, ELITES, FAST, HEAVY, FORTIFICATION, LORD_OF_WAR, FLYER, TRANSPORT]

Array.prototype.without_first = (element) ->
  index = @indexOf element
  return @slice() if index < 0
  @slice(0, index).concat(@slice(index + 1))

class Bag
  constructor: (items...) ->
    @item_counts = {}
    @size = 0
    for item in items
      @add(item)
      
  add: (item, count = 1) ->
    c = @item_counts[item] || 0
    @item_counts[item] = c + count
    @size += count
    
  remove: (item, count = 1) ->
    c = @item_counts[item] || 0
    if c >= count
      @item_counts[item] = c - count
      @size -= count
      return true
    else 
      return false
      
  count: (item) ->
    @item_counts[item] || 0
      
  is_empty: () ->
    @size is 0
      
class Detachment
  constructor: (@name, @command_points, @allow_transports) ->
    @min_map = {}
    @max_map = {}
    
  toString: () ->
    @name
    
  add_category: (category, min, max) ->
    @min_map[category] = min
    @max_map[category] = max
    this
      
  claim_min: (cats) ->
    for check_cat, min of @min_map
      return false unless cats.remove(check_cat, min)
    return true
    
  claim_max: (cats) ->
    claimed = 0
    for check_cat, max of @max_map
      xmax = Math.min(max, cats.count(check_cat))
      claimed += xmax if cats.remove(check_cat, xmax)
    if @allow_transports
      tcount = Math.min(claimed, cats.count(TRANSPORT))
      cats.remove(TRANSPORT, tcount)
          
class AuxiliaryDetachment extends Detachment
  @POSSIBLES: [HQ, ELITES, TROOPS, FAST, HEAVY, FLYER, TRANSPORT]
  
  constructor: (@name) ->
    super(@name, -1, false)
    
  claim_min: (cats) ->
    for check_cat in @constructor.POSSIBLES
      return true if cats.remove(check_cat)
    return false
    
  claim_max: (cats) ->
    for check_cat in @constructor.POSSIBLES
      return if cats.remove(check_cat)
    
    
PATROL = new Detachment("Patrol", 0, true).add_category(HQ, 1, 2).add_category(TROOPS, 1, 3).add_category(ELITES, 0, 2).add_category(FAST, 0, 2).add_category(HEAVY, 0, 2).add_category(FLYER, 0, 2)  
BATTALION = new Detachment("Battalion", 3, true).add_category(HQ, 2, 3).add_category(TROOPS, 3, 6).add_category(ELITES, 0, 6).add_category(FAST, 0, 3).add_category(HEAVY, 0, 3).add_category(FLYER, 0, 2)  
BRIGADE = new Detachment("Brigade", 9, true).add_category(HQ, 3, 5).add_category(TROOPS, 6, 12).add_category(ELITES, 3, 8).add_category(FAST, 3, 5).add_category(HEAVY, 3, 5).add_category(FLYER, 0, 2)  
VANGUARD = new Detachment("Vanguard", 1, true).add_category(HQ, 1, 2).add_category(TROOPS, 0, 3).add_category(ELITES, 3, 6).add_category(FAST, 0, 2).add_category(HEAVY, 0, 2).add_category(FLYER, 0, 2) 
OUTRIDER = new Detachment("Outrider", 1, true).add_category(HQ, 1, 2).add_category(TROOPS, 0, 3).add_category(ELITES, 0, 2).add_category(FAST, 3, 6).add_category(HEAVY, 0, 2).add_category(FLYER, 0, 2)  
SPEARHEAD = new Detachment("Spearhead", 1, true).add_category(HQ, 1, 2).add_category(TROOPS, 0, 3).add_category(ELITES, 0, 2).add_category(FAST, 0, 2).add_category(HEAVY, 3, 6).add_category(FLYER, 0, 2)       
COMMAND = new Detachment("Supreme Command", 1, true).add_category(HQ, 3, 5).add_category(ELITES, 0, 1).add_category(LORD_OF_WAR, 0, 1)
SUPER_H = new Detachment("Super-Heavy", 3, false).add_category(LORD_OF_WAR, 3, 5)
SUPER_A = new Detachment("Super-Heavy Auxiliary", 0, false).add_category(LORD_OF_WAR, 1, 1)  
FORTIFICATION = new Detachment("Fortification Network", 0, false).add_category(FORTIFICATION, 1, 3)
AIR_WING = new Detachment("Air Wing", 1, false).add_category(FLYER, 3, 5)
AUX = new AuxiliaryDetachment("Auxiliary Support")

# pre-sorted detachments:
dets = [BRIGADE, BATTALION, SUPER_H, COMMAND, VANGUARD, OUTRIDER, SPEARHEAD, AIR_WING, PATROL, SUPER_A, FORTIFICATION, AUX]

# backtracking algorithm - see https://en.wikipedia.org/wiki/Backtracking
root = (p) ->
  []
  
reject = (p, c) ->
  return true if c.length > p.max_size or c.length > p.cats.length
  bp = new Bag(p.cats...)
  for det in c
    return true unless det.claim_min(bp)
  return false
  
accept = (p, c) ->
  bp = new Bag(p.cats...)
  for det in c
    det.claim_max(bp)
  bp.is_empty() and c.length > 0
  
first = (p, c) ->
  c.concat(dets[0])
  
next = (p, c) ->
  i = dets.indexOf(c[-1..][0]) + 1
  if i >= dets.length
    false
  else
    c[0..-2].concat(dets[i])
    
output = (p, c) ->
  score = c.reduce (a, cat) -> 
    a + cat.command_points
  , 3
  if score > p.max_score
    p.max_score = score
    p.results = c
    
bt = (p, c) ->
  return if reject(p, c)
  output(p, c) if accept(p, c)
  s = first(p, c)
  while s
    bt(p, s)
    s = next(p, s)

find_detachment = (callback, desc, icats, beat_score = 0, max_size = 3) ->
  p = 
    desc: desc
    max_size: max_size
    cats: icats
    max_score: 0
    
  bt(p, root(p))
  
  return 0 unless p.max_score > beat_score or p.desc is "Original"
  
  if p.results
    callback
      desc: p.desc
      code: if p.desc is "Original" then "success" else "suggest"
      score: p.max_score
      detachments: p.results
  else
    callback
      desc: p.desc
      code: "warn"
      score: 0
      detachments: []
  p.max_score
    
find_detachments = (callback, args, max_size = 3) ->
  icats = (Category.for_prefix(arg) for arg in args when Category.for_prefix(arg))  
  return unless icats.length > 0
  original_score = find_detachment(callback, "Original", icats, 0, max_size)

  find_detachment(callback, "Add #{c}", icats.concat(c), original_score, max_size) for c in ALL_CATEGORIES
  for c in ALL_CATEGORIES when icats.indexOf(c) > -1
    find_detachment(callback, "Remove #{c}", icats.without_first(c), original_score, max_size) 
    find_detachment(callback, "Replace #{c} with #{d}", icats.without_first(c).concat(d), original_score, max_size) for d in ALL_CATEGORIES 

module.exports = {
  ALL_CATEGORIES
  find_detachments
}