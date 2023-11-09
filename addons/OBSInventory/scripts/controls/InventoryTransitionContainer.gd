@icon("res://addons/OBSInventory/icons/icon_inventory_transition_control.svg")
extends Control
class_name InventoryTransitionContainer


# ------------------------------------------------------------------------------
# Signal
# ------------------------------------------------------------------------------
signal stack_obtained(stack : InventoryGridStack)
signal stack_released()
signal stack_dropped(stack : InventoryGridStack)

# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const DEFAULT_NODE_GROUP : StringName = &"InventoryTransitionContainer"

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export_category("Inventory Transition Control")
@export_subgroup("Input Events")
@export var event_interact : StringName = &""

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _active_stack : InventoryGridStack = null
var _mouse_offset : Vector2 = Vector2.ZERO
var _last_mouse_position : Vector2 = Vector2.ZERO
var _mouse_position : Vector2 = Vector2.ZERO
var _mouse_mode : bool = true
var _drop_on_interact : bool = false

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	add_to_group(DEFAULT_NODE_GROUP)
	child_entered_tree.connect(_on_child_entered_tree)
	child_exiting_tree.connect(_on_child_exited_tree)


func _process(_delta: float) -> void:
	if _active_stack == null: return
	_active_stack.global_position = get_global_mouse_position() - _mouse_offset
	_CheckForDrop()

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _UpdateMouseOffset() -> void:
	_mouse_offset = get_global_mouse_position() - _active_stack.global_position

func _UpdateMousePosition() -> void:
	if not _last_mouse_position.is_equal_approx(get_global_mouse_position()):
		_last_mouse_position = get_global_mouse_position()
		_mouse_position = _last_mouse_position

	#var axis : Vector2 = Input.get_vector(event_left, event_right, event_up, event_down)
	#_mouse_position += axis

func _CheckForDrop() -> void:
	if _drop_on_interact and Input.is_action_just_released(event_interact):
		stack_dropped.emit(take_stack())

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func is_holding_stack() -> bool:
	return _active_stack != null

func peek_stack() -> InventoryGridStack:
	return _active_stack

func get_stack_offset() -> Vector2:
	if _active_stack == null: return Vector2.ZERO
	return _mouse_offset

func get_stack_grid_offset() -> Vector2i:
	if _active_stack == null: return Vector2i.ZERO
	return Vector2i(_mouse_offset / _active_stack.cell_size)

func take_stack() -> InventoryGridStack:
	if _active_stack == null: return null
	var stack : InventoryGridStack = _active_stack
	remove_child(_active_stack)
	#_active_stack = null
	return stack

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_child_entered_tree(child : Node) -> void:
	if _active_stack == null and child is InventoryGridStack:
		_active_stack = child
		_UpdateMouseOffset.call_deferred()
		stack_obtained.emit(child)

func _on_child_exited_tree(child : Node) -> void:
	if child == _active_stack:
		_active_stack = null
		stack_released.emit()


