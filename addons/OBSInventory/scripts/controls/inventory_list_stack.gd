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
		add_child(_ilsbase)
		_icon = _ilsbase.get_node_or_null("HLayout/Icon")
		_item_name = _ilsbase.get_node_or_null("HLayout/ItemName")
		_quantity_label = _ilsbase.get_node_or_null("HLayout/VLayout/QuantityLabel")
		_quantity_value = _ilsbase.get_node_or_null("HLayout/VLayout/QuantityValue")
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
		return _themectrl.set_override(property, value)
	return false

func _get_property_list() -> Array[Dictionary]:
	return _themectrl.get_theme_override_property_list()

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _UpdateTheme() -> void:
	return
	if _ilsbase == null: return
	var panel : StyleBox = _GetThemeStylebox("panel_normal")
	_ilsbase.add_theme_stylebox_override("panel", panel)
	
	if _item_name != null:
		pass

func _UpdatePanelTheme() -> void:
	if _ilsbase == null: return
	var panel_var_name : StringName = &"normal"
	if _pressed:
		panel_var_name = &"pressed"
	elif _mouse_within:
		panel_var_name = &"hover"
	elif _focused:
		panel_var_name = &"focus"

func _GetThemeFont(font_name : StringName) -> Font:
	var type_name : StringName = DEFAULT_NODE_GROUP if theme_type_variation == &"" else theme_type_variation
	if has_theme_font(font_name, type_name):
		return get_theme_font(font_name, type_name)
	return DEFAULT_THEME.get_font(font_name, type_name)

func _GetThemeFontSize(font_size_name : StringName) -> int:
	var type_name : StringName = DEFAULT_NODE_GROUP if theme_type_variation == &"" else theme_type_variation
	if has_theme_font_size(font_size_name, type_name):
		return get_theme_font_size(font_size_name, type_name)
	return DEFAULT_THEME.get_font_size(font_size_name, type_name)

func _GetThemeStylebox(style_name : StringName) -> StyleBox:
	var type_name : StringName = DEFAULT_NODE_GROUP if theme_type_variation == &"" else theme_type_variation
	if has_theme_stylebox(style_name, type_name):
		return get_theme_stylebox(style_name, type_name)
	return DEFAULT_THEME.get_stylebox(style_name, DEFAULT_NODE_GROUP)

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------


# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_quantity_changed() -> void:
	queue_redraw()

func _on_mouse_entered() -> void:
	_mouse_within = true

func _on_mouse_exited() -> void:
	_mouse_within = false

