@tool
extends Resource
class_name Grid


# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal dimensions_changed()
signal values_cleared()
signal value_added(coords : Vector2i, value)
signal value_removed(coords : Vector2i, value)

# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const ROT_CCW90 : int = -1
const ROT_NONE : int = 0
const ROT_CW90 : int = 1
const ROT_180 : int = 2

# ------------------------------------------------------------------------------
# Exports
# ------------------------------------------------------------------------------
@export_category("Grid")
@export var dimensions : Vector2i = Vector2i(1,1)
@export var data : Dictionary:							set = set_data, get = get_data

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _data : Dictionary = {}

# ------------------------------------------------------------------------------
# Setters/Getters
# ------------------------------------------------------------------------------
func set_dimensions(d : Vector2i) -> void:
	if d.x > 0 and d.y > 0 and d.x != dimensions.x and d.y != dimensions.y:
		dimensions = d
		_TrimData()
		dimensions_changed.emit()

func set_data(d : Dictionary) -> void:
	_UpdateDataFrom(d)

func get_data() -> Dictionary:
	return _data.duplicate()


# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _init(g : Variant = null) -> void:
	if typeof(g) == TYPE_VECTOR2I:
		if g.x > 0 and g.y > 0:
			dimensions = g
	elif g is Grid:
		dimensions = g.dimensions
		var coords = g.get_used_coords()
		for coord in coords:
			set_value(coord, g.get_value(coord))


# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _UpdateDataFrom(d : Dictionary) -> void:
	_data.clear()
	values_cleared.emit()
	for key in d.keys():
		if typeof(key) == TYPE_VECTOR2I:
			if key.x >= 0 and key.x < dimensions.x and key.y >= 0 and key.y < dimensions.y:
				_data[key] = d[key]
				value_added.emit(key, d[key])

func _TrimData() -> void:
	for coord in _data.keys():
		if coord.x >= dimensions.x or coord.y >= dimensions.y:
			var v = _data[coord]
			_data.erase(coord)
			value_removed.emit(coord, v)

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func clear() -> void:
	_data.clear()
	values_cleared.emit()

func clone() -> Grid:
	return self.get_script().new(self)

func max_coords() -> int:
	if dimensions.x <= 0 or dimensions.y <= 0: return 0
	return dimensions.x * dimensions.y

func coord_in_grid(coord : Vector2i) -> bool:
	if coord.x < 0 or coord.y < 0: return false
	if coord.x >= dimensions.x or coord.y >= dimensions.y: return false
	return true

func has_value(coord : Vector2i) -> bool:
	return coord in _data

func set_value(coord : Vector2i, value : Variant) -> void:
	if coord.x >= 0 and coord.x < dimensions.x and coord.y >= 0 and coord.y < dimensions.y:
		if value == null:
			var v = _data[coord]
			_data.erase(coord)
			value_removed.emit(coord, v)
		else:
			var v = null
			if coord in _data:
				v = _data[coord]
			_data[coord] = value
			if v != null:
				value_removed.emit(coord, v)
			value_added.emit(coord, value)

func get_value(coord : Vector2i, default : Variant = null) -> Variant:
	if coord in _data:
		return _data[coord]
	return default

func swap_value(coord : Vector2i, value : Variant) -> Variant:
	var v = null
	if coord in _data:
		v = _data[coord]
	set_value(coord, value)
	return v

func pop_value(coord : Vector2i) -> Variant:
	var v = null
	if coord in _data:
		v = _data[coord]
		_data.erase(coord)
		value_removed.emit(coord, v)
	return v

func find_value(value : Variant) -> Array[Vector2i]:
	var value_coords : Array[Vector2i] = []
	var coords : Array[Vector2i] = get_used_coords()
	for coord in coords:
		if _data[coord] == value:
			value_coords.append(coord)
	return value_coords

func get_used_coords() -> Array[Vector2i]:
	var coords : Array[Vector2i] = []
	for key in _data.keys():
		coords.append(key)
	return coords

func are_coords_empty(coords : Array[Vector2i], offset : Vector2i = Vector2i.ZERO) -> bool:
	if offset.x < 0 or offset.y < 0: return false
	if offset.x >= dimensions.x or offset.y >= dimensions.y: return false
	
	for coord in coords:
		var tcoord : Vector2i = coord + offset
		if tcoord.x < 0 or tcoord.y < 0: return false
		if tcoord.x >= dimensions.x or tcoord.y >= dimensions.y: return false
		if tcoord in _data: return false
	
	return true

func is_grid_shadow_empty(coord : Vector2i, g : Grid) -> bool:
	return are_coords_empty(g.get_used_coords(), coord)
#	if coord.x < 0 or coord.y < 0: return false
#	if coord.x + g.dimensions.x > dimensions.x or coord.y + g.dimensions.y > dimensions.y:
#		return false
#
#	var scoords : Array[Vector2i] = g.get_used_cells()
#	for scoord in scoords:
#		if not g.has_value(scoord): continue
#		var tcoord : Vector2i = coord + scoord
#		if tcoord in _data: return false
#
#	return true

func add_grid_at(coord : Vector2i, g : Grid, replace : bool = false) -> void:
	var scoords : Array[Vector2i] = g.get_used_coords()
	for scoord in scoords:
		var tcoord : Vector2i = coord + scoord
		if not coord_in_grid(tcoord): continue
		if not replace and has_value(tcoord): continue
		set_value(tcoord, g.get_value(scoord))


func subtract_grid_at(coord : Vector2i, g : Grid) -> void:
	var scoords : Array[Vector2i] = g.get_used_coords()
	for scoord in scoords:
		var tcoord : Vector2i = coord + scoord
		if not coord_in_grid(tcoord): continue
		if has_value(tcoord):
			set_value(tcoord, null)

func sub_grid(coord : Vector2i, size : Vector2i) -> Grid:
	if size.x <= 0 and size.y <= 0: return null
	if not coord_in_grid(coord): return null
	if coord.x + size.x >= dimensions.x or coord.y + size.y >= dimensions.y: return null
	var g : Grid = Grid.new()
	g.dimensions = size
	for y in range(size.y):
		for x in range(size.x):
			var tcoord : Vector2i = Vector2i(x, y)
			var scoord : Vector2i = Vector2i(coord.x + x, coord.y + y)
			if has_value(scoord):
				g.set_value(tcoord, get_value(scoord))
	return g

# TODO: This should return a "rotated" grid
func rotated(rot : int) -> Grid:
	rot = wrapi(rot, ROT_CCW90, ROT_180)
	# TODO: Actually finish this!
	return clone()

