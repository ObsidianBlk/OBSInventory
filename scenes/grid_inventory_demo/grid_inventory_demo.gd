extends Control


var _potion : Item = preload("res://items/item_potion.tres")
var _sword : Item = preload("res://items/item_sword.tres")
var _small_sword : Item = preload("res://items/item_small_sword.tres")

@onready var _inventory_grid_4x_8: Control = %InventoryGrid4x8
@onready var _inventory_grid_6x_12: Control = %InventoryGrid6x12


func _ready() -> void:
	_inventory_grid_4x_8.grid_stash.add_item(_potion, 10)
	_inventory_grid_4x_8.grid_stash.add_item(_sword)
	_inventory_grid_4x_8.grid_stash.add_item(_potion, 2)
	_inventory_grid_4x_8.grid_stash.add_item(_sword)
	_inventory_grid_6x_12.grid_stash.fill_add_item(_small_sword, 10)
	_inventory_grid_6x_12.grid_stash.fill_add_item(_potion, 100)

