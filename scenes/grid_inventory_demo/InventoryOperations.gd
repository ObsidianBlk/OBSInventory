extends Control


# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _ig : InventoryGrid = null
var _id : int = -1

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var _slider_stack : HSlider = %SliderStack
@onready var _lbl_stack : Label = %LBLStack


# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	visible = false
	_slider_stack.value_changed.connect(_on_slider_stack_value_changed)

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func grid_inventory_operation(id : int, ig : InventoryGrid) -> void:
	if visible: return # if we're visible, we're already handing an operation.
	if ig == null or ig.grid_stash == null: return
	if not ig.grid_stash.stash.has_id(id): return
	
	var amount : int = ig.grid_stash.stash.get_quantity(id)
	# TODO: Update this when we have a drop operations ready. We CAN drop a stack of 1 after all.
	if amount <= 1: return # Need 2 or more
	
	_id = id
	_ig = ig

	_slider_stack.value = 0
	_slider_stack.max_value = amount
	_lbl_stack.text = "0"

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_slider_stack_value_changed(value : float) -> void:
	_lbl_stack.text = "%s"%[value]


func _on_btn_split_pressed():
	pass # Replace with function body.


func _on_btn_cancel_pressed():
	if not visible: return
	visible = false
	_id = -1
	_ig = null
