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

var _active_item : InventoryListStack = null

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

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_SORT_CHILDREN:
			var rect : Rect2 = Rect2()
			for child : Control in get_children():
				child.reset_size()
				var child_size : Vector2 = child.get_size()
				if child_size.x > rect.size.x:
					rect.size.x = child_size.x
				rect.size.y += child_size.y
			
			if not get_size().is_equal_approx(rect.size):
				set_size(rect.size)
			
			for child : Control in get_children():
				var child_size : Vector2 = child.get_size()
				child_size.x = rect.size.x
				child.set_size(child_size)

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
	if stash.item_changed.is_connected(_on_stash_item_changed):
		stash.item_changed.disconnect(_on_stash_item_changed)
	if stash.changed.is_connected(_on_stash_changed):
		stash.changed.disconnect(_on_stash_changed)

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
	if not stash.item_changed.is_connected(_on_stash_item_changed):
		stash.item_changed.connect(_on_stash_item_changed)
	if not stash.changed.is_connected(_on_stash_changed):
		stash.changed.connect(_on_stash_changed)

func _EmptyList() -> void:
	for id : int in _stack_nodes.keys():
		_RemoveItemFromList(id)

func _BuildListFromStash() -> void:
	if stash == null: return
	
	var ids : PackedInt64Array = stash.get_ids()
	for idx : int in range(ids.size()):
		_AddItemToList(ids[idx])
	queue_sort()
	#sort_children.emit()

func _AddItemToList(id : int) -> void:
	if id in _stack_nodes: return
	var stack : ItemStack = stash.get_item_stack(id)
	if stack != null:
		var list_stack : InventoryListStack = InventoryListStack.new()
		list_stack.stack = stack
		list_stack.size_flags_horizontal = Control.SIZE_FILL
		list_stack.event_interact = event_interact
		list_stack.event_alt_interact = event_alt_interact
		_AddListStackNode(list_stack)

func _AddListStackNode(list_stack : InventoryListStack) -> void:
	if list_stack == null: return
	if list_stack.stack == null: return
	if list_stack.stack.id < 0 or list_stack.stack.id in _stack_nodes: return
	if not list_stack.grabbed.is_connected(_on_stash_item_grabbed.bind(list_stack.stack.id)):
		list_stack.grabbed.connect(_on_stash_item_grabbed.bind(list_stack.stack.id))
	add_child(list_stack)
	_stack_nodes[list_stack.stack.id] = list_stack

func _RemoveItemFromList(id : int) -> void:
	if not id in _stack_nodes: return
	remove_child(_stack_nodes[id])
	_stack_nodes[id].queue_free()
	_stack_nodes.erase(id)

func _RemoveListStackNode(id : int) -> InventoryListStack:
	if not id in _stack_nodes: return null
	var list_stack : InventoryListStack = _stack_nodes[id]
	_stack_nodes.erase(id)
	remove_child(list_stack)
	if list_stack.grabbed.is_connected(_on_stash_item_grabbed.bind(id)):
		list_stack.grabbed.disconnect(_on_stash_item_grabbed.bind(id))
	return list_stack

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

#TODO: Instead of passing an InventoryListStack directly, send just the ID?
func _InventoryStackGrabbed(ilstack : InventoryListStack, container : InventoryTransitionContainer) -> void:	
	if container.is_holding_stack(): return
	#igstack.follow_mouse()
	ilstack.highlight = false
	
	var gpos : Vector2 = ilstack.global_position
	
	#TODO: Rethink the Add/Remove Stack helper methods
	# I'm forgetting that "moving" a stack removes a stack from the stash.
	
	#_RemoveStack(ilstack.stack, false)
	#grid_stash.remove_stack_by_id(igstack.stack.id)
	#container.add_child(ilstack)
	#ilstack.global_position = gpos

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
	queue_sort()
	#sort_children.emit()

func _on_stash_item_added(id : int) -> void:
	_AddItemToList(id)
	queue_sort()
	#sort_children.emit()

func _on_stash_item_removed(id : int) -> void:
	_RemoveItemFromList(id)
	queue_sort()
	#sort_children.emit()

func _on_stash_item_changed(id : int) -> void:
	print("Stack changed: ", id)
	queue_sort()
	#sort_children.emit()

func _on_stash_item_highlighted(active : bool, id : int) -> void:
	if not id in _stack_nodes: return
	
	if active:
		if _active_item == null or _active_item.stack.id != id:
			_active_item = _stack_nodes[id]
	else:
		if _active_item != null and _active_item.stack.id == id:
			_active_item = null

func _on_stash_item_grabbed(id : int) -> void:
	if not id in _stack_nodes: return
	
	var container : InventoryTransitionContainer = _FindContainerNode()
	if container == null: return
	_InventoryStackGrabbed(_stack_nodes[id], container)

func _on_stash_changed() -> void:
	queue_sort()
	#sort_children.emit()
