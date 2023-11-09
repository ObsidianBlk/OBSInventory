@tool
extends Resource
class_name ItemGridStash


# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal data_reset()
signal emptied()
signal item_added(id : int)
signal item_quantity_changed(id : int)
signal item_removed(id : int)
signal dimensions_changed()

# ------------------------------------------------------------------------------
# Constants and ENUMs
# ------------------------------------------------------------------------------
const GRID_META_ORIGIN : String = "GRID_ORIGIN"
const GRID_META_ORIENTATION : String = "GRID_ORIENTATION"

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export_category("Item Grid Stash")
@export var stash : ItemStash = ItemStash.new():		set = set_stash
@export var grid : Grid = Grid.new():					set = set_grid

# ------------------------------------------------------------------------------
# Settings
# ------------------------------------------------------------------------------
func set_grid(g : Grid) -> void:
	if g == null: return
	if stash == null:
		_DisconnectGrid()
		grid = g
		_ConnectGrid()
		data_reset.emit()
	else:
		if not _GridContainsStash(g, stash):
			printerr("ITEM GRID STASH: Given Grid does not match ItemStash")
			return
		_DisconnectGrid()
		grid = g
		_ConnectGrid()
		data_reset.emit()

func set_stash(s : ItemStash) -> void:
	if s == null: return
	if grid == null:
		_DisconnectStash()
		stash = s
		_ConnectStash()
		data_reset.emit()
	else:
		if not _GridContainsStash(grid, s):
			printerr("ITEM GRID STASH: Given ItemStash does not match grid.")
			return
		_DisconnectStash()
		stash = s
		_ConnectStash()
		data_reset.emit()

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _init() -> void:
	_ConnectStash()
	_ConnectGrid()

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _ConnectGrid() -> void:
	if grid == null: return
	if not grid.dimensions_changed.is_connected(_on_grid_dimensions_changed):
		grid.dimensions_changed.connect(_on_grid_dimensions_changed)

func _DisconnectGrid() -> void:
	if grid == null: return
	if grid.dimensions_changed.is_connected(_on_grid_dimensions_changed):
		grid.dimensions_changed.disconnect(_on_grid_dimensions_changed)


func _ConnectStash() -> void:
	if stash == null: return
	if not stash.emptied.is_connected(_on_stash_emptied):
		stash.emptied.connect(_on_stash_emptied)
	if not stash.item_quantity_changed.is_connected(_on_item_quantity_changed):
		stash.item_quantity_changed.connect(_on_item_quantity_changed)

func _DisconnectStash() -> void:
	if stash == null: return
	if stash.emptied.is_connected(_on_stash_emptied):
		stash.emptied.disconnect(_on_stash_emptied)
	if stash.item_quantity_changed.is_connected(_on_item_quantity_changed):
		stash.item_quantity_changed.disconnect(_on_item_quantity_changed)

func _GridContainsStash(g : Grid, s : ItemStash) -> bool:
	var idlist : PackedInt32Array = s.get_ids()
	for id in idlist:
		if g.find_value(id).size() <= 0:
			return false
	return true

func _FindAvailableGridCoord(icoords : Array[Vector2i]) -> Vector2i:
	for y in range(grid.dimensions.y):
		for x in range(grid.dimensions.x):
			var offset : Vector2i = Vector2i(x, y)
			if grid.are_coords_empty(icoords, offset):
				return offset
	return Vector2i(-1,-1)

func _AvailableItemStack(coord : Vector2i, item : Item, item_grid : Grid) -> int:
	var icoords : Array[Vector2i] = item_grid.get_used_coords()
	
	var stack_id : int = -1
	# TODO: This MIGHT overlap two stacks of the same type... not sure if this should
	#  be considered a problem. Ignoring it for now.
	for icoord in icoords:
		if not grid.has_value(icoord + coord): return -1
		var id = grid.get_value(icoord + coord, -1)
		if stash.get_item(id) != item: return -1
		if stash.get_quantity(id) >= item.inventory_stack_size: return -1
		if stack_id < 0:
			stack_id = id
	return stack_id

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func clear() -> void:
	grid.clear()
	stash.clear()

func get_id_at(coord : Vector2i) -> int:
	return grid.get_value(coord, -1)

func get_id_coords(id : int) -> Array[Vector2i]:
	return grid.find_value(id)

func get_item_at(coord : Vector2i) -> Item:
	var id : int = grid.get_value(coord, -1)
	if id < 0: return null
	return stash.get_item(id)

func get_item_orientation(id : int) -> int:
	if stash == null: return Grid.ROT_NONE
	return stash.get_metadata(id, GRID_META_ORIENTATION, Grid.ROT_NONE)

func get_grid_info_for_id(id : int) -> Dictionary:
	if not stash.has_id(id): return {}
	return {
		"origin": stash.get_metadata(id, GRID_META_ORIGIN, Vector2i(-1, -1)),
		"orientation": stash.get_metadata(id, GRID_META_ORIENTATION, Grid.ROT_NONE)
	}

func can_item_fit(coord : Vector2i, item : Item, orientation : int = Grid.ROT_NONE) -> bool:
	if item == null: return false
	if coord.x < 0 or coord.y < 0: return false
	if coord.x > grid.dimensions.x or coord.y > grid.dimensions.y: return false
	var igrid : Grid = item.inventory_mask.rotated(orientation)
	if not grid.are_coords_empty(igrid.get_used_coords(), coord):
		return _AvailableItemStack(coord, item, igrid) >= 0
	return true

func can_item_fit_any(item : Item, orientation : int = Grid.ROT_NONE) -> bool:
	var igrid : Grid = item.inventory_mask.rotated(orientation)
	var icoords : Array[Vector2i] = igrid.get_used_coords()
	var coord : Vector2i = _FindAvailableGridCoord(icoords)
	return coord.x >= 0

func add_item(item : Item, amount : int = 1, orientation : int = Grid.ROT_NONE) -> Dictionary:
	if item == null or amount <= 0: return {}
	var igrid : Grid = item.inventory_mask.rotated(orientation)
	var icoords : Array[Vector2i] = igrid.get_used_coords()
	var coord : Vector2i = _FindAvailableGridCoord(icoords)
	if coord.x < 0:
		return {}
	
	var res : Dictionary = stash.add_item(item, amount)
	if res.is_empty():
		return {}
	
	var id : int = res.id
	stash.set_metadata(id, GRID_META_ORIGIN, coord)
	stash.set_metadata(id, GRID_META_ORIENTATION, orientation)
	
	for icoord in icoords:
		grid.set_value(icoord + coord, id)
	
	item_added.emit(id)
	return res

func add_item_at(coord : Vector2i, item : Item, amount : int = 1, orientation : int = Grid.ROT_NONE) -> Dictionary:
	if item == null or amount <= 0: return {}
	var igrid : Grid = item.inventory_mask.rotated(orientation)
	var icoords : Array[Vector2i] = igrid.get_used_coords()
	if not grid.are_coords_empty(icoords, coord):
		var id : int = _AvailableItemStack(coord, item, igrid)
		if id >= 0:
			var remaining : int = stash.add_item_to(id, item, amount)
			return {"id": id, "remaining": remaining}
		return {}
	
	var res : Dictionary = stash.add_item(item, amount)
	if res.is_empty():
		return {}
	
	var id : int = res.id
	stash.set_metadata(id, GRID_META_ORIGIN, coord)
	stash.set_metadata(id, GRID_META_ORIENTATION, orientation)
	
	for icoord in icoords:
		grid.set_value(icoord + coord, id)
	
	item_added.emit(id)
	return res

func fill_add_item(item : Item, amount : int = 1, orientation : int = Grid.ROT_NONE) -> Dictionary:
	if item == null or amount <= 0: return {}
	
	var stacks : Array[ItemStack] = stash.get_item_stacks(item)
	for stack in stacks:
		amount = stash.add_item_to(stack.id, item, amount)
		if amount <= 0:
			return {"id": stack.id, "remaining": 0}
	
	var last_stack_id : int = -1
	while not stash.is_full() and amount > 0:
		var res : Dictionary = add_item(item, amount, orientation)
		if res.is_empty():
			return {}
		last_stack_id = res.id
		amount = res.remaining
	return {"id": last_stack_id, "remaining": amount}

func remove_item_at_coord(coord : Vector2i, amount : int = -1) -> ItemStack:
	if amount == 0: return null
	var id : int = grid.get_value(coord, -1)
	if id < 0: return null
	
	var stack : ItemStack = stash.remove_item_from(id, amount)
	if stack == null: return null
	
	if stack.id >= 0:
		var gcoords : Array[Vector2i] = grid.find_value(stack.id)
		for gcoord in gcoords:
			grid.set_value(gcoord, null)
		item_removed.emit(stack.id)
	
	return stack

func remove_stack_by_id(id : int, amount : int = -1) -> ItemStack:
	var stack : ItemStack = stash.remove_item_from(id, amount)
	
	if stack.id >= 0:
		var gcoords : Array[Vector2i] = grid.find_value(id)
		for gcoord in gcoords:
			grid.set_value(gcoord, null)
		item_removed.emit(stack.id)
	
	return stack

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_grid_dimensions_changed():
	dimensions_changed.emit()

func _on_stash_emptied() -> void:
	emptied.emit()

func _on_item_quantity_changed(id : int) -> void:
	item_quantity_changed.emit(id)


