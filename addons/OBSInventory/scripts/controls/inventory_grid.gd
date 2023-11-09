@tool
@icon("res://addons/OBSInventory/icons/icon_inventory_grid.svg")
extends Control
class_name InventoryGrid


# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const DEFAULT_NODE_GROUP : StringName = &"InventoryGrid"
const DEFAULT_THEME : Theme = preload("res://addons/OBSInventory/inventory_default_theme.tres")

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export_category("Inventory Grid")
@export var grid_stash : ItemGridStash = null:			set = set_grid_stash
@export var cell_size : int = 1:						set = set_cell_size
@export_subgroup("Input Events")
@export var event_interact : StringName = &""


# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _inv_stacks : Dictionary = {}
var _active_id : int = -1

var _hover_coord : Vector2i = Vector2i(-1, -1)
var _inv_item_container : WeakRef = weakref(null)

# ------------------------------------------------------------------------------
# Setters
# ------------------------------------------------------------------------------
func set_grid_stash(g : ItemGridStash) -> void:
	if g != grid_stash:
		_DisconnectGridStash()
		_ClearStacks()
		grid_stash = g
		_ConnectGridStash()
		queue_redraw()
		_AdjustControlSize()


func set_cell_size(s : int) -> void:
	if s > 0 and s != cell_size:
		cell_size = s
		queue_redraw()
		_AdjustControlSize()


# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	focus_mode = Control.FOCUS_ALL
	set_process_unhandled_input(false)
	add_to_group(DEFAULT_NODE_GROUP)

func _draw() -> void:
	if grid_stash == null: return
	var item_mask : Grid = null
	var origin : Vector2i = Vector2i.ZERO
	if _active_id >= 0:
		item_mask = _inv_stacks[_active_id].get_item_mask()
		origin = _inv_stacks[_active_id].get_origin()
	
	var normal_style : StyleBox = _GetThemeStylebox(&"normal")
	var hover_style : StyleBox = _GetThemeStylebox(&"hover")
	var hover_filled_style : StyleBox = _GetThemeStylebox(&"hover_filled")
	for y in range(grid_stash.grid.dimensions.y):
		for x in range(grid_stash.grid.dimensions.x):
			var rect : Rect2 = Rect2(x * cell_size, y * cell_size, cell_size, cell_size)
			var occupied : bool = false
			if item_mask != null:
				occupied = item_mask.has_value(Vector2i(x,y) - origin)
			if occupied:
				draw_style_box(hover_filled_style, rect)
			else:
				if Vector2i(x, y) == _hover_coord:
					draw_style_box(hover_style, rect)
				else:
					draw_style_box(normal_style, rect)
			#draw_rect(Rect2(x * cell_size, y * cell_size, cell_size, cell_size), Color.ANTIQUE_WHITE, false, 2.0)

func _get_minimum_size() -> Vector2:
	if grid_stash == null: return Vector2.ZERO
	return grid_stash.grid.dimensions * cell_size

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_RESIZED:
			pass
		NOTIFICATION_THEME_CHANGED:
			queue_redraw()
		NOTIFICATION_MOUSE_ENTER:
			grab_focus.call_deferred()
			grab_click_focus.call_deferred()
			_InformContainerOverGrid()
		NOTIFICATION_MOUSE_EXIT:
			_hover_coord = Vector2i(-1,-1)
			_active_id = -1
			_InformContainerOverGrid(false)
			queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if grid_stash == null: return
	
	if event is InputEventMouseMotion:
		#print(self)
		var mpos : Vector2 = get_global_mouse_position()
		var coord : Vector2i = get_grid_coord_from_world(mpos)
		if coord != _hover_coord:
			_hover_coord = coord
			queue_redraw()
		var id : int = grid_stash.get_id_at(coord)
		if id in _inv_stacks:
			#if _active_id >= 0 and _active_id != id:
			#	_inv_stacks[_active_id].highlight = false
			_active_id = id
			queue_redraw()
			#_inv_stacks[_active_id].highlight = true
		elif _active_id >= 0:
			#_inv_stacks[_active_id].highlight = false
			_active_id = -1
			queue_redraw()
		accept_event()
	if event.is_action(event_interact):
		var container : InventoryTransitionContainer = _FindContainerNode()
		if container == null: return
		if event.pressed and _active_id >= 0:
			_InventoryStackGrabbed(_inv_stacks[_active_id], container)
			accept_event()
		elif not event.pressed:
			if container.is_holding_stack():
				var stack : InventoryGridStack = container.peek_stack()
				
				var stack_grid_offset : Vector2i = container.get_stack_grid_offset()
				var mouse_coord : Vector2i = get_grid_coord_from_world(get_global_mouse_position())
				var coord : Vector2i = mouse_coord - stack_grid_offset
				
				if grid_stash.can_item_fit(coord, stack.get_item(), stack.get_orientation()):
					_TakeInventoryStack.call_deferred(container, coord)
			accept_event()
			

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _AdjustControlSize() -> void:
	size = get_minimum_size()

func _FindContainerNode() -> InventoryTransitionContainer:
	if _inv_item_container.get_ref() != null:
		return _inv_item_container.get_ref()
	
	var nodes : Array = get_tree().get_nodes_in_group(InventoryTransitionContainer.DEFAULT_NODE_GROUP)
	if nodes.size() > 0:
		for node in nodes:
			if node is InventoryTransitionContainer:
				_inv_item_container = weakref(node)
				return node
	
	return null

func _InformContainerOverGrid(is_over : bool = true) -> void:
	var container : InventoryTransitionContainer = _FindContainerNode()
	if container == null: return
	

func _ConnectGridStash() -> void:
	if grid_stash == null: return
	if not grid_stash.data_reset.is_connected(_on_grid_stash_data_reset):
		grid_stash.data_reset.connect(_on_grid_stash_data_reset)
	if not grid_stash.emptied.is_connected(_on_grid_stash_emptied):
		grid_stash.emptied.connect(_on_grid_stash_emptied)
	if not grid_stash.item_added.is_connected(_on_grid_stash_item_added):
		grid_stash.item_added.connect(_on_grid_stash_item_added)
	if not grid_stash.item_removed.is_connected(_on_grid_stash_item_removed):
		grid_stash.item_removed.connect(_on_grid_stash_item_removed)
	if not grid_stash.dimensions_changed.is_connected(_on_grid_stash_dimensions_changed):
		grid_stash.dimensions_changed.connect(_on_grid_stash_dimensions_changed)

func _DisconnectGridStash() -> void:
	if grid_stash == null: return
	if grid_stash.data_reset.is_connected(_on_grid_stash_data_reset):
		grid_stash.data_reset.disconnect(_on_grid_stash_data_reset)
	if grid_stash.emptied.is_connected(_on_grid_stash_emptied):
		grid_stash.emptied.disconnect(_on_grid_stash_emptied)
	if grid_stash.item_added.is_connected(_on_grid_stash_item_added):
		grid_stash.item_added.disconnect(_on_grid_stash_item_added)
	if grid_stash.item_removed.is_connected(_on_grid_stash_item_removed):
		grid_stash.item_removed.disconnect(_on_grid_stash_item_removed)
	if grid_stash.dimensions_changed.is_connected(_on_grid_stash_dimensions_changed):
		grid_stash.dimensions_changed.disconnect(_on_grid_stash_dimensions_changed)

func _AddStack(stack : ItemStack) -> void:
	if stack.id < 0: return
	if not (stack.has_metadata(ItemGridStash.GRID_META_ORIGIN) and stack.has_metadata(ItemGridStash.GRID_META_ORIENTATION)):
		return
	var origin : Vector2i = stack.get_metadata(ItemGridStash.GRID_META_ORIGIN)
	var igstack : InventoryGridStack = InventoryGridStack.new()
	#igstack.grabbed.connect(_on_stack_grabbed.bind(igstack))
	igstack.stack = stack
	igstack.cell_size = cell_size
	igstack.show_grid_mask = false
	add_child(igstack)
	igstack.position = origin * cell_size
	_inv_stacks[stack.id] = igstack

func _RemoveStack(stack : ItemStack, free_stack : bool = true) -> void:
	if stack.id < 0: return
	if stack.id in _inv_stacks:
		if stack.id == _active_id:
			_active_id = -1
		remove_child(_inv_stacks[stack.id])
		if free_stack:
			_inv_stacks[stack.id].queue_free()
		_inv_stacks.erase(stack.id)

func _InventoryStackGrabbed(igstack : InventoryGridStack, container : InventoryTransitionContainer) -> void:	
	if container.is_holding_stack(): return
	#igstack.follow_mouse()
	igstack.show_grid_mask = true
	igstack.highlight = false
	
	var gpos : Vector2 = igstack.global_position
	
	_RemoveStack(igstack.stack, false)
	grid_stash.remove_stack_by_id(igstack.stack.id)
	container.add_child(igstack)
	igstack.global_position = gpos
	queue_redraw()

func _TakeInventoryStack(container : InventoryTransitionContainer, coord : Vector2i) -> void:
	var stack : InventoryGridStack = container.take_stack()
	stack.global_position = global_position + Vector2(coord * cell_size)
	stack = add_inventory_grid_stack(stack)
	if stack != null:
		container.add_child(stack)
	queue_redraw()

func _ClearStacks() -> void:
	for id in _inv_stacks.keys():
		remove_child(_inv_stacks[id])
		_inv_stacks[id].queue_free()
		_inv_stacks.erase(id)

func _GetThemeStylebox(style_name : StringName) -> StyleBox:
	var type_name : StringName = DEFAULT_NODE_GROUP if theme_type_variation == &"" else theme_type_variation
	if has_theme_stylebox(style_name, type_name):
		return get_theme_stylebox(style_name, type_name)
	return DEFAULT_THEME.get_stylebox(style_name, DEFAULT_NODE_GROUP)

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------	
func get_grid_coord_from_world(pos : Vector2) -> Vector2i:
	if grid_stash == null: return Vector2i.ZERO
	return (pos - global_position) / cell_size

func get_inventory_rect() -> Rect2:
	if grid_stash == null or grid_stash.grid == null: return Rect2(Vector2.ZERO, Vector2.ZERO)
	return Rect2(global_position, grid_stash.grid.dimensions * cell_size)

func can_item_fit(coord : Vector2, item : Item, orientation : int = Grid.ROT_NONE) -> bool:
	if grid_stash == null: return false
	return grid_stash.can_item_fit(coord, item, orientation)

func can_inventory_grid_stack_fit(igs : InventoryGridStack) -> bool:
	if grid_stash == null: return false
	if igs == null: return false
	#if not is_inside_tree() or not igs.is_inside_tree(): return false
	
	var rect : Rect2 = get_inventory_rect()
	var igrect : Rect2 = igs.get_stack_rect()
	
	if not rect.encloses(igrect): return false
	
	var origin : Vector2i = get_grid_coord_from_world(igs.global_position)
	return grid_stash.can_item_fit(origin, igs.get_item(), igs.get_orientation())

func add_item_at(coord : Vector2i, item : Item, amount : int = 1, orientation : int = Grid.ROT_NONE) -> Dictionary:
	if grid_stash == null: return {}
	return grid_stash.add_item_at(coord, item, amount, orientation)

func add_inventory_grid_stack(igs : InventoryGridStack) -> InventoryGridStack:
	if not can_inventory_grid_stack_fit(igs): return igs
	
	var origin : Vector2i = get_grid_coord_from_world(igs.global_position)
	var res : Dictionary = grid_stash.add_item_at(
		origin,
		igs.get_item(),
		igs.get_quantity(),
		igs.get_orientation()
	)
	if res.is_empty():
		return igs
	
	if res.remaining > 0:
		var stack : ItemStack = ItemStack.new()
		stack.item = igs.get_item()
		stack.quantity = res.remaining
		stack.set_metadata(ItemGridStash.GRID_META_ORIENTATION, igs.get_orientation())
		var nigs : InventoryGridStack = InventoryGridStack.new()
		nigs.stack = stack
		nigs.cell_size = cell_size
		return nigs
		
	return null

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_grid_stash_data_reset() -> void:
	if grid_stash == null: return
	_ClearStacks()
	for id in grid_stash.stash.get_ids():
		var stack : ItemStack = grid_stash.stash.get_item_stack(id)
		if stack == null: continue
		_AddStack(stack)

func _on_grid_stash_emptied() -> void:
	if grid_stash == null: return
	_ClearStacks()

func _on_grid_stash_item_added(id : int) -> void:
	if grid_stash == null: return
	var stack : ItemStack = grid_stash.stash.get_item_stack(id)
	if stack == null: return
	_AddStack(stack)

func _on_grid_stash_item_removed(id : int) -> void:
	if grid_stash == null: return
	if not grid_stash.stash.has_id(id) and id in _inv_stacks:
		remove_child(_inv_stacks[id])
		_inv_stacks[id].queue_free()
		_inv_stacks.erase(id)

func _on_grid_stash_dimensions_changed() -> void:
	if grid_stash == null: return
	_on_grid_stash_data_reset()
	queue_redraw()

#func _on_stack_grabbed(igstack : InventoryGridStack) -> void:
#	igstack.grabbed.disconnect(_on_stack_grabbed.bind(igstack))
#	_RemoveStack(igstack.stack, false)
#	grid_stash.remove_stack_by_id(igstack.stack.id)
#	stack_grabbed.emit(igstack)
	
