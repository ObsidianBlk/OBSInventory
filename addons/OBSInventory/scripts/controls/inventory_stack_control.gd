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

# ------------------------------------------------------------------------------
# Setters / Getters
# ------------------------------------------------------------------------------
func set_stack (s : ItemStack) -> void:
	if s != stack:
		_PreStackChange()
		_DisconnectItemStack()
		stack = s
		_ConnectItemStack()
		_PostStackChange()

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not Engine.is_editor_hint():
		_ConnectItemStack()

# ------------------------------------------------------------------------------
# "Virtual" Methods
# ------------------------------------------------------------------------------
func _PreStackChange() -> void:
	pass

func _PostStackChange() -> void:
	pass

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _ConnectItemStack() -> void:
	if stack == null: return
	if not stack.quantity_changed.is_connected(_on_quantity_changed):
		stack.quantity_changed.connect(_on_quantity_changed)
	if not stack.item_changed.is_connected(_on_item_changed):
		stack.item_changed.connect(_on_item_changed)

func _DisconnectItemStack() -> void:
	if stack == null: return
	if stack.quantity_changed.is_connected(_on_quantity_changed):
		stack.quantity_changed.disconnect(_on_quantity_changed)
	if stack.item_changed.is_connected(_on_item_changed):
		stack.item_changed.disconnect(_on_item_changed)

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------


# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_item_changed() -> void:
	pass

func _on_quantity_changed() -> void:
	pass


