@tool
extends VBoxContainer
class_name InventoryList


# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal stack_alt_interacted(id : int)


# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const DEFAULT_NODE_GROUP : StringName = &"InventoryList"
const DEFAULT_THEME : Theme = preload("res://addons/OBSInventory/inventory_default_theme.tres")


# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export_category("Inventory List")
@export var stash : ItemStash = null:					set = set_stash
@export_subgroup("Input Events")
@export var event_interact : StringName = &""
@export var event_alt_interact : StringName = &""


# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _inv_item_container : WeakRef = weakref(null)
var _stack_nodes : Dictionary = {}

# ------------------------------------------------------------------------------
# Setters
# ------------------------------------------------------------------------------
func set_stash (s : ItemStash) -> void:
	_DisconnectStash()
	_EmptyList()
	stash = s
	_ConnectStash()
	_BuildListFromStash()


# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	_ConnectStash()
	_BuildListFromStash()

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _DisconnectStash() -> void:
	if stash == null: return
	if stash.data_reset.is_connected(_on_stash_data_reset):
		stash.data_reset.disconnect(_on_stash_data_reset)
	if stash.emptied.is_connected(_on_stash_emptied):
		stash.emptied.disconnect(_on_stash_emptied)
	if stash.item_added.is_connected(_on_stash_item_added):
		stash.item_added.disconnect(_on_stash_item_added)
	if stash.item_removed.is_connected(_on_stash_item_removed):
		stash.item_removed.disconnect(_on_stash_item_removed)

func _ConnectStash() -> void:
	if stash == null: return
	if not stash.data_reset.is_connected(_on_stash_data_reset):
		stash.data_reset.connect(_on_stash_data_reset)
	if not stash.emptied.is_connected(_on_stash_emptied):
		stash.emptied.connect(_on_stash_emptied)
	if not stash.item_added.is_connected(_on_stash_item_added):
		stash.item_added.connect(_on_stash_item_added)
	if not stash.item_removed.is_connected(_on_stash_item_removed):
		stash.item_removed.connect(_on_stash_item_removed)

func _EmptyList() -> void:
	for id : int in _stack_nodes.keys():
		_RemoveItemFromList(id)

func _BuildListFromStash() -> void:
	if stash == null: return
	
	var ids : PackedInt32Array = stash.get_ids()
	for idx : int in range(ids.size()):
		_AddItemToList(ids[idx])

func _AddItemToList(id : int) -> void:
	if id in _stack_nodes: return
	var list_stack : InventoryListStack = InventoryListStack.new()
	list_stack.stack = stash.get_item_stack(id)
	add_child(list_stack)
	_stack_nodes[id] = list_stack

func _RemoveItemFromList(id : int) -> void:
	if not id in _stack_nodes: return
	remove_child(_stack_nodes[id])
	_stack_nodes[id].queue_free()
	_stack_nodes.erase(id)

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

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------


# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_stash_data_reset() -> void:
	_EmptyList()
	if stash.size() > 0:
		_BuildListFromStash()

func _on_stash_emptied() -> void:
	_EmptyList()

func _on_stash_item_added(id : int) -> void:
	_AddItemToList(id)

func _on_stash_item_removed(id : int) -> void:
	_RemoveItemFromList(id)
