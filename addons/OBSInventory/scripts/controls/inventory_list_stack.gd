@tool
extends InventoryStackControl
class_name InventoryListStack

# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------


# ------------------------------------------------------------------------------
# Constants and ENUMs
# ------------------------------------------------------------------------------
const DEFAULT_NODE_GROUP : StringName = &"InventoryListStack"
const ILS_BASE_CONTROL : PackedScene = preload("res://addons/OBSInventory/sub_controls/ils_base_a.tscn")

const DEFAULT_ITEM_ICON : Texture = preload("res://icon.svg")

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export_category("Inventory List Stack")
@export var highlight : bool = false:				set = set_highlight

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
#var highlight : bool = false
var _ilsbase : PanelContainer = null
var _icon_container : AspectRatioContainer = null
var _icon : TextureRect = null
var _item_name : Label = null
var _quantity_label : Label = null
var _quantity_value : Label = null

var _themectrl : ThemeCTRL = ThemeCTRL.new([
	["item_font", Theme.DATA_TYPE_FONT],
	["quantity_font", Theme.DATA_TYPE_FONT],
	["quantity_value_font", Theme.DATA_TYPE_FONT],
	["item_font_color", Theme.DATA_TYPE_COLOR],
	["item_font_shadow_color", Theme.DATA_TYPE_COLOR],
	["item_font_outline_color", Theme.DATA_TYPE_COLOR],
	["quantity_font_color", Theme.DATA_TYPE_COLOR],
	["quantity_font_shadow_color", Theme.DATA_TYPE_COLOR],
	["quantity_font_outline_color", Theme.DATA_TYPE_COLOR],
	["quantity_value_font_color", Theme.DATA_TYPE_COLOR],
	["quantity_value_font_shadow_color", Theme.DATA_TYPE_COLOR],
	["quantity_value_font_outline_color", Theme.DATA_TYPE_COLOR],
	["icon_size", Theme.DATA_TYPE_CONSTANT],
	["item_shadow_offset_x", Theme.DATA_TYPE_CONSTANT],
	["item_shadow_offset_y", Theme.DATA_TYPE_CONSTANT],
	["item_outline_size", Theme.DATA_TYPE_CONSTANT],
	["item_shadow_outline_size", Theme.DATA_TYPE_CONSTANT],
	["item_line_spacing", Theme.DATA_TYPE_CONSTANT],
	["quantity_shadow_offset_x", Theme.DATA_TYPE_CONSTANT],
	["quantity_shadow_offset_y", Theme.DATA_TYPE_CONSTANT],
	["quantity_outline_size", Theme.DATA_TYPE_CONSTANT],
	["quantity_shadow_outline_size", Theme.DATA_TYPE_CONSTANT],
	["quantity_line_spacing", Theme.DATA_TYPE_CONSTANT],
	["quantity_value_shadow_offset_x", Theme.DATA_TYPE_CONSTANT],
	["quantity_value_shadow_offset_y", Theme.DATA_TYPE_CONSTANT],
	["quantity_value_outline_size", Theme.DATA_TYPE_CONSTANT],
	["quantity_value_shadow_outline_size", Theme.DATA_TYPE_CONSTANT],
	["quantity_value_line_spacing", Theme.DATA_TYPE_CONSTANT],
	["item_font", Theme.DATA_TYPE_FONT],
	["quantity_font", Theme.DATA_TYPE_FONT],
	["quantity_value_font", Theme.DATA_TYPE_FONT],
	["item_font_size", Theme.DATA_TYPE_FONT_SIZE],
	["quantity_font_size", Theme.DATA_TYPE_FONT_SIZE],
	["quantity_value_font_size", Theme.DATA_TYPE_FONT_SIZE],
	["normal", Theme.DATA_TYPE_STYLEBOX],
	["hover", Theme.DATA_TYPE_STYLEBOX],
	["focus", Theme.DATA_TYPE_STYLEBOX],
	["pressed", Theme.DATA_TYPE_STYLEBOX],
])

var _mouse_within : bool = false
var _focused : bool = false
var _pressed : bool = false

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Setters / Getters
# ------------------------------------------------------------------------------
func set_highlight(h : bool) -> void:
	if h != highlight:
		highlight = h
		queue_redraw()

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	_ilsbase = ILS_BASE_CONTROL.instantiate()
	if _ilsbase:
		_ilsbase.mouse_entered.connect(_on_mouse_entered)
		_ilsbase.mouse_exited.connect(_on_mouse_exited)
		_ilsbase.resized.connect(_on_resized)
		add_child(_ilsbase)
		_icon_container = _ilsbase.get_node_or_null("HLayout/IconContainer")
		_icon = _ilsbase.get_node_or_null("HLayout/IconContainer/Icon")
		_item_name = _ilsbase.get_node_or_null("HLayout/ItemName")
		_quantity_label = _ilsbase.get_node_or_null("HLayout/VLayout/QuantityLabel")
		_quantity_value = _ilsbase.get_node_or_null("HLayout/VLayout/QuantityValue")
	_PostStackChange()
	_UpdateTheme()

func _notification(what : int) -> void:
	match what:
		NOTIFICATION_THEME_CHANGED:
			_UpdateTheme()

func _get(property : StringName) -> Variant:
	if _themectrl.has_override(property):
		return _themectrl.get_override(property)
	return null

func _set(property : StringName, value : Variant) -> bool:
	if _themectrl.has_override(property):
		var res : bool = _themectrl.set_override(property, value)
		if res:
			_UpdateTheme()
		return res
	return false

func _get_property_list() -> Array[Dictionary]:
	return _themectrl.get_theme_override_property_list()

func _get_minimum_size() -> Vector2:
	if _ilsbase == null: return Vector2.ZERO
	return _ilsbase.get_minimum_size()

# ------------------------------------------------------------------------------
# "Virtual" Methods
# ------------------------------------------------------------------------------
func _PostStackChange() -> void:
	if _item_name == null: return
	if stack != null:
		if stack.item != null:
			_item_name.text = stack.item.name
			_icon.texture = stack.item.inventory_texture
		else:
			_item_name.text = ""
			_icon.texture = DEFAULT_ITEM_ICON
		_quantity_value.text = "%s"%[stack.quantity]
	else:
		_item_name.text = ""
		_icon.texture = DEFAULT_ITEM_ICON
		_quantity_value.text = "0"

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------

func _UpdateTheme() -> void:
	if _ilsbase == null: return
	_UpdatePanelTheme()
	_UpdateIconTheme()
	_UpdateItemNameLabelTheme()
	_UpdateQuantityLabelTheme()
	_UpdateQuantityValueLabelTheme()

func _UpdatePanelTheme() -> void:
	if _ilsbase == null: return
	var panel_var_name : StringName = &"normal"
	if _pressed:
		panel_var_name = &"pressed"
	elif _mouse_within:
		panel_var_name = &"hover"
	elif _focused:
		panel_var_name = &"focus"
	var panel : StyleBox = _GetThemeStylebox(panel_var_name, _GetThemeType(), _themectrl)
	_ilsbase.add_theme_stylebox_override("panel", panel)

func _UpdateIconTheme() -> void:
	if _icon_container == null: return
	var icon_size : int = _GetThemeConstant("icon_size", _GetThemeType(), _themectrl)
	_icon_container.custom_minimum_size = Vector2i(icon_size, icon_size)

func _UpdateItemNameLabelTheme() -> void:
	_UpdateLabelTheme(_item_name, [
		["font_color", "item_font_color", Theme.DATA_TYPE_COLOR],
		["font_shadow_color", "item_font_shadow_color", Theme.DATA_TYPE_COLOR],
		["font_outline_color", "item_font_outline_color", Theme.DATA_TYPE_COLOR],
		["shadow_offset_x", "item_shadow_offset_x", Theme.DATA_TYPE_CONSTANT],
		["shadow_offset_y", "item_shadow_offset_y", Theme.DATA_TYPE_CONSTANT],
		["outline_size", "item_outline_size", Theme.DATA_TYPE_CONSTANT],
		["shadow_outline_size", "item_shadow_outline_size", Theme.DATA_TYPE_CONSTANT],
		["line_spacing", "item_line_spacing", Theme.DATA_TYPE_CONSTANT],
		["font", "item_font", Theme.DATA_TYPE_FONT],
		["font_size", "item_font_size", theme.DATA_TYPE_FONT_SIZE]
	])

func _UpdateQuantityLabelTheme() -> void:
	_UpdateLabelTheme(_quantity_label, [
		["font_color", "quantity_font_color", Theme.DATA_TYPE_COLOR],
		["font_shadow_color", "quantity_font_shadow_color", Theme.DATA_TYPE_COLOR],
		["font_outline_color", "quantity_font_outline_color", Theme.DATA_TYPE_COLOR],
		["shadow_offset_x", "quantity_shadow_offset_x", Theme.DATA_TYPE_CONSTANT],
		["shadow_offset_y", "quantity_shadow_offset_y", Theme.DATA_TYPE_CONSTANT],
		["outline_size", "quantity_outline_size", Theme.DATA_TYPE_CONSTANT],
		["shadow_outline_size", "quantity_shadow_outline_size", Theme.DATA_TYPE_CONSTANT],
		["line_spacing", "quantity_line_spacing", Theme.DATA_TYPE_CONSTANT],
		["font", "quantity_font", Theme.DATA_TYPE_FONT],
		["font_size", "quantity_font_size", theme.DATA_TYPE_FONT_SIZE]
	])

func _UpdateQuantityValueLabelTheme() -> void:
	_UpdateLabelTheme(_quantity_value, [
		["font_color", "quantity_value_font_color", Theme.DATA_TYPE_COLOR],
		["font_shadow_color", "quantity_value_font_shadow_color", Theme.DATA_TYPE_COLOR],
		["font_outline_color", "quantity_value_font_outline_color", Theme.DATA_TYPE_COLOR],
		["shadow_offset_x", "quantity_value_shadow_offset_x", Theme.DATA_TYPE_CONSTANT],
		["shadow_offset_y", "quantity_value_shadow_offset_y", Theme.DATA_TYPE_CONSTANT],
		["outline_size", "quantity_value_outline_size", Theme.DATA_TYPE_CONSTANT],
		["shadow_outline_size", "quantity_value_shadow_outline_size", Theme.DATA_TYPE_CONSTANT],
		["line_spacing", "quantity_value_line_spacing", Theme.DATA_TYPE_CONSTANT],
		["font", "quantity_value_font", Theme.DATA_TYPE_FONT],
		["font_size", "quantity_value_font_size", theme.DATA_TYPE_FONT_SIZE]
	])

func _UpdateLabelTheme(lbl : Label, name_list : Array[Array]) -> void:
	if lbl == null: return
	for item in name_list:
		match item[2]:
			Theme.DATA_TYPE_COLOR:
				lbl.add_theme_color_override(item[0], _GetThemeColor(item[1], _GetThemeType(), _themectrl))
			Theme.DATA_TYPE_CONSTANT:
				lbl.add_theme_constant_override(item[0], _GetThemeConstant(item[1], _GetThemeType(), _themectrl))
			Theme.DATA_TYPE_FONT:
				lbl.add_theme_font_override(item[0], _GetThemeFont(item[1], _GetThemeType(), _themectrl))
			Theme.DATA_TYPE_FONT_SIZE:
				lbl.add_theme_font_size_override(item[0], _GetThemeFontSize(item[1], _GetThemeType(), _themectrl))

func _GetThemeType() -> StringName:
	if theme_type_variation != &"":
		return theme_type_variation
	return DEFAULT_NODE_GROUP

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
	return DEFAULT_THEME.get_stylebox(style_name, DEFAULT_NODE_GROUP)

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------


# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_item_changed() -> void:
	_PostStackChange()

func _on_quantity_changed() -> void:
	if _quantity_value != null and stack != null:
		_quantity_value.text = "%s"%[stack.quantity]

func _on_mouse_entered() -> void:
	_mouse_within = true
	_UpdatePanelTheme()

func _on_mouse_exited() -> void:
	_mouse_within = false
	_UpdatePanelTheme()

func _on_resized() -> void:
	reset_size()
