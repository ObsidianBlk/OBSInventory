@tool
extends Resource
class_name ItemStack

# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal quantity_changed()
signal item_changed()

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export_category("Item Stack")
@export var id : int = -1:					set = set_id
@export var item : Item = null:				set = set_item
@export var quantity : int = 0:				set = set_quantity
@export var meta_data : Dictionary:			set = set_metadata_dict, get = get_metadata_dict

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _meta_data : Dictionary = {}

# ------------------------------------------------------------------------------
# Setters
# ------------------------------------------------------------------------------
func set_id(nid : int) -> void:
	# <id> can only be set once, then it's "read only"
	if id < 0 and nid >= 0:
		id = nid
		changed.emit()

func set_item(itm : Item) -> void:
	if itm == item: return
	item = itm
	if item == null:
		quantity = 0
	elif quantity > item.inventory_stack_size:
		quantity = item.inventory_stack_size
	quantity_changed.emit()
	item_changed.emit()
	changed.emit()

func set_quantity(q : int) -> void:
	if q < 0: return
	if item != null:
		var nq : int = min(q, item.inventory_stack_size)
		if nq != quantity:
			quantity = nq
			quantity_changed.emit()
			changed.emit()
	else:
		quantity = q
		quantity_changed.emit()
		changed.emit()

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _init(nid : int = -1, stack_item : Item = null, stack_quantity : int = 0) -> void:
	id = nid
	item = stack_item
	quantity = stack_quantity

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func clear_metadata() -> void:
	_meta_data.clear()

func has_metadata(key : String) -> bool:
	return key in _meta_data

func set_metadata_dict(meta : Dictionary) -> void:
	_meta_data.clear()
	for key in meta:
		if typeof(key) == TYPE_STRING:
			_meta_data[key] = meta[key]
	changed.emit()

func set_metadata(key : String, value : Variant) -> void:
	if value == null:
		if key in meta_data:
			_meta_data.erase(key)
			changed.emit()
	else:
		_meta_data[key] = value
		changed.emit()

func get_metadata(key : String, default : Variant = null) -> Variant:
	if key in _meta_data:
		return _meta_data[key]
	return default

func get_metadata_dict() -> Dictionary:
	return _meta_data.duplicate()

func is_empty() -> bool:
	return item == null or quantity <= 0

func available_stack_space() -> int:
	if item == null: return 0
	return item.inventory_stack_size - quantity

func add_item_amount(itm : Item, amount : int = 1) -> int:
	if item == null or itm == null: return -1
	if itm != item: return -1
	if amount <= 0: return 0
	if quantity >= item.inventory_stack_size: return 0
	var available : int = available_stack_space()
	if available >= amount:
		quantity += amount
		return 0
	quantity += available
	return amount - available

func add_stack(stack : ItemStack) -> void:
	if item == null or stack.item == null: return
	if stack == self: return
	if stack.item != item: return
	if quantity >= item.inventory_stack_size: return
	var available : int = available_stack_space()
	if available >= stack.quantity:
		quantity += stack.quantity
		stack.quantity = 0
	else:
		quantity += available
		stack.quantity -= available
