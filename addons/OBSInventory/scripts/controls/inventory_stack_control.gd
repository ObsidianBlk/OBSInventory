@tool
extends Control
class_name InventoryStackControl

# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal grabbed()
signal grab_released()

# ------------------------------------------------------------------------------
# Constants and ENUMs
# ------------------------------------------------------------------------------
const DEFAULT_THEME : Theme = preload("res://addons/OBSInventory/inventory_default_theme.tres")

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export_category("Inventory Stack Control")
@export var stack : ItemStack = null:				set = set_stack

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------


# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not Engine.is_editor_hint():
		_ConnectItemStack()

# ------------------------------------------------------------------------------
# Setters / Getters
# ------------------------------------------------------------------------------
func set_stack (s : ItemStack) -> void:
	if s != stack:
		_DisconnectItemStack()
		stack = s
		_ConnectItemStack()
		queue_redraw()

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------


# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _ConnectItemStack() -> void:
	if stack == null: return
	if not stack.quantity_changed.is_connected(_on_quantity_changed):
		stack.quantity_changed.connect(_on_quantity_changed)

func _DisconnectItemStack() -> void:
	if stack == null: return
	if stack.quantity_changed.is_connected(_on_quantity_changed):
		stack.quantity_changed.disconnect(_on_quantity_changed)

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------


# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_quantity_changed() -> void:
	pass


