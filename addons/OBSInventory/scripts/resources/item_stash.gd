@tool
extends Resource
class_name ItemStash


# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal emptied()
signal data_reset()
signal item_added(id : int)
signal item_quantity_changed(id : int)
signal item_removed(id : int)
signal item_changed(id : int)

# ------------------------------------------------------------------------------
# Constants and ENUMs
# ------------------------------------------------------------------------------
const MAX_ID_ATTEMPTS : int = 10

# ------------------------------------------------------------------------------
# Exports
# ------------------------------------------------------------------------------
@export_category("Item Stash")
@export var max_stacks : int = 1:							set = set_max_stacks
@export var stack_list : Array[ItemStack]:					set = set_stack_list, get = get_stack_list


# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _data : Dictionary = {}


# ------------------------------------------------------------------------------
# Setters/Getters
# ------------------------------------------------------------------------------
func set_max_stacks(ms : int) -> void:
	if max_stacks > 0:
		max_stacks = ms
		_UpdateStackCount.call_deferred()

func set_stack_list(sl : Array[ItemStack]) -> void:
	_DisconnectStacksInData()
	_data.clear()
	for stack in sl:
		if stack == null:
			stack = ItemStack.new(_GenRandomID(10))
			#print(stack.id)
			if stack.id < 0: continue
		if stack.id in _data:
			printerr("STASH WARNING: Stack list contains duplicate stack entry (id: ", stack.id, "). Skipping.")
			continue
		if _data.size() >= max_stacks:
			printerr("STASH WARNING: Stack list exceeds size.")
			break
		_data[stack.id] = stack
	_ConnectStacksInData()
	data_reset.emit()
	changed.emit()

func get_stack_list() -> Array[ItemStack]:
	var list : Array[ItemStack] = []
	for id in _data.keys():
		list.append(_data[id])
	return list

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _to_string() -> String:
	var idlist : Array = _data.keys()
	var strarr : Array[String] = []
	var joiner : Callable = func(item, str):
		return "%s\n%s"%[str, item]
	
	for id in idlist:
		strarr.append("Item: %s | Quantity: %s | Id: %s"%[
			_data[id].item.name,
			_data[id].quantity,
			id
		])
	
	return strarr.reduce(joiner, "")

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _UpdateStackCount() -> void:
	var keys : Array = _data.keys()
	if keys.size() <= max_stacks: return
	for i in range(keys.size() - max_stacks):
		var key : int = keys.pop_back()
		var stack : ItemStack = remove_item_from(key)
		if stack == null:
			printerr("STACK UPDATE WARNING: Removed empty ID.")
	changed.emit()

func _DisconnectStacksInData() -> void:
	for stack : ItemStack in _data.values():
		if stack.changed.is_connected(_on_stack_item_changed.bind(stack.id)):
			stack.changed.disconnect(_on_stack_item_changed.bind(stack.id))

func _ConnectStacksInData() -> void:
	for stack : ItemStack in _data.values():
		if not stack.changed.is_connected(_on_stack_item_changed.bind(stack.id)):
			stack.changed.connect(_on_stack_item_changed.bind(stack.id))

func _GenRandomID(attempts : int) -> int:
	var id = randi()
	if not id in _data: return id
	if attempts > 0:
		return _GenRandomID(attempts - 1)
	return -1

func _AddDiscreteItem(item : Item, amount : int = 1) -> Dictionary:
	var id : int = _GenRandomID(MAX_ID_ATTEMPTS)
	if id < 0: return {}
	
	_data[id] = ItemStack.new(id, item, min(amount, item.inventory_stack_size))
	
	item_added.emit(id)
	changed.emit()
	return {"id":id, "remaining": amount - _data[id].quantity}

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func clear() -> void:
	_data.clear()
	emptied.emit()

func size() -> int:
	return _data.size()

func is_full() -> bool:
	return _data.size() >= max_stacks

func has_id(id : int) -> bool:
	return id in _data

func get_ids() -> PackedInt64Array:
	return PackedInt64Array(_data.keys())

func get_item_stacks(item : Item) -> Array[ItemStack]:
	var items : Array[ItemStack] = []
	for id in _data.keys():
		if _data[id].item == item:
			items.append(_data[id].item)
	return items

func get_item(id : int) -> Item:
	if id in _data:
		return _data[id].item
	return null

func get_quantity(id : int) -> int:
	if id in _data:
		return _data[id].quantity
	return 0

func get_item_stack(id : int) -> ItemStack:
	if id in _data:
		return _data[id]
	return null

func has_metadata(id : int, key : String) -> bool:
	if not id in _data: return false
	return _data[id].has_metadata(key)

func set_metadata_dict(id : int, meta : Dictionary) -> void:
	if not id in _data: return
	_data[id].set_metadata_dict(meta)

func set_metadata(id : int, key : String, value : Variant) -> void:
	if not id in _data: return
	_data[id].set_metadata(key, value)

func get_metadata(id : int, key : String, default : Variant = null) -> Variant:
	if not id in _data: return default
	return _data[id].get_metadata(key, default)

func get_metadata_dict(id : int) -> Dictionary:
	if not id in _data: return {}
	return _data[id].get_metadata_dict()

func clear_metadata(id : int) -> void:
	if not id in _data: return
	_data[id].clear_metadata()

func add_item(item : Item, amount : int = 1, auto_fill_stacks : bool = false) -> Dictionary:
	if item == null: return {}
	if amount <= 0: return {}
	if _data.size() >= max_stacks: return {}
	
	# If auto_fill_stacks is true then check if this item can stack multiple
	if auto_fill_stacks and item.inventory_stack_size > 1:
		# Check to see if there's already a stack for this item in the stash
		for id in _data.keys():
			# If the stack isn't full...
			if _data[id].item == item and _data[id].available_stack_space() > 0:
				amount = add_item_to(id, item, amount)
				if amount <= 0: # If there's no remaining items, we're done.
					return {"id":id, "remaining": 0}
	
	# If the item isn't stackable, or there are no more existing stacks to fill, then add
	# the item with the given amount to the stash
	return _AddDiscreteItem(item, amount)


func add_item_to(id : int, item : Item, amount : int = 1) -> int:
	if not id in _data: return 0
	if _data[id].item != item: return 0
	
	var remaining : int = _data[id].add_item_amount(item, amount)
	if remaining > 0 and remaining < amount:
		item_quantity_changed.emit(id)
	return remaining


func remove_item_from(id : int, amount : int = -1) -> ItemStack:
	if not id in _data or amount == 0: return null
	var stack : ItemStack = null
	if amount < 0 or amount >= _data[id].quantity:
		stack = _data[id]
		_data.erase(id)
		item_removed.emit(id)
		changed.emit()
	else:
		_data[id].quantity -= amount
		item_quantity_changed.emit(id)
		#item_removed.emit(id, _data[id].item, amount)
		stack = ItemStack.new(-1, _data[id].item, amount)
	return stack


# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_stack_item_changed(id : int) -> void:
	item_changed.emit(id)
	changed.emit()
