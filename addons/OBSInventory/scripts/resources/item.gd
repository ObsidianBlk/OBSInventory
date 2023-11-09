@tool
extends Resource
class_name Item


# ------------------------------------------------------------------------------
# Exports
# ------------------------------------------------------------------------------
@export_category("Item")
@export var name : StringName = &""
@export_subgroup("Inventory Data")
@export var inventory_texture : Texture2D = null
@export var inventory_mask : Grid = Grid.new()
@export var inventory_stack_size : int = 1:			set = set_inventory_stack_size


# ------------------------------------------------------------------------------
# Setters
# ------------------------------------------------------------------------------
func set_inventory_stack_size(stack : int) -> void:
	if stack > 0:
		inventory_stack_size = stack

