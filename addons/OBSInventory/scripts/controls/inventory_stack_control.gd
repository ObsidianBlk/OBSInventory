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
	#if not Engine.is_editor_hint():
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

func _GetThemeColor(color_name : StringName, type_name : StringName, themectrl : ThemeCTRL = null) -> Color:
	if themectrl != null:
		var property : StringName = ThemeCTRL.Generate_Property_Name(color_name, Theme.DATA_TYPE_COLOR)
		if themectrl.is_override_set(property):
			return themectrl.get_override(property)
	
	if has_theme_color(color_name, type_name):
		return get_theme_color(color_name, type_name)
	return DEFAULT_THEME.get_color(color_name, type_name)

func _GetThemeConstant(const_name : StringName, type_name : StringName, themectrl : ThemeCTRL = null) -> int:
	if themectrl != null:
		var property : StringName = ThemeCTRL.Generate_Property_Name(const_name, Theme.DATA_TYPE_CONSTANT)
		if themectrl.is_override_set(property):
			return themectrl.get_override(property)
	
	if has_theme_constant(const_name, type_name):
		return get_theme_constant(const_name, type_name)
	return DEFAULT_THEME.get_constant(const_name, type_name)

func _GetThemeFont(font_name : StringName, type_name : StringName, themectrl : ThemeCTRL = null) -> Font:
	if themectrl != null:
		var property : StringName = ThemeCTRL.Generate_Property_Name(font_name, Theme.DATA_TYPE_FONT)
		if themectrl.is_override_set(property):
			return themectrl.get_override(property)
	
	# This is a hackey workaround to test if font_name and type_name are explicitly
	# defined for a Font. If the returned get_theme_font() call returns the same Font
	# object as get_theme_default_font(), then the Font was NOT overridden in a theme, so
	# use the DEFAULT_THEME font.
	var def_font : Font = get_theme_default_font()
	var theme_font : Font = get_theme_font(font_name, type_name)
	if def_font == theme_font:
		return DEFAULT_THEME.get_font(font_name, type_name)
	return theme_font
	#if has_theme_font(font_name, type_name):
	#	return get_theme_font(font_name, type_name)

func _GetThemeFontSize(font_size_name : StringName, type_name : StringName, themectrl : ThemeCTRL = null) -> int:
	if themectrl != null:
		var property : StringName = ThemeCTRL.Generate_Property_Name(font_size_name, Theme.DATA_TYPE_FONT_SIZE)
		if themectrl.is_override_set(property):
			return themectrl.get_override(property)
	
	if has_theme_font_size(font_size_name, type_name):
		return get_theme_font_size(font_size_name, type_name)
	return DEFAULT_THEME.get_font_size(font_size_name, type_name)

func _GetThemeStylebox(style_name : StringName, type_name : StringName, themectrl : ThemeCTRL = null) -> StyleBox:
	if themectrl != null:
		var property : StringName = ThemeCTRL.Generate_Property_Name(style_name, Theme.DATA_TYPE_STYLEBOX)
		if themectrl.is_override_set(property):
			return themectrl.get_override(property)
			
	if has_theme_stylebox(style_name, type_name):
		return get_theme_stylebox(style_name, type_name)
	return DEFAULT_THEME.get_stylebox(style_name, type_name)

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_item_changed() -> void:
	pass

func _on_quantity_changed() -> void:
	pass


