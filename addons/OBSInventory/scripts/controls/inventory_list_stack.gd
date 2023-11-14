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
var _ilsbase : PanelContainer = null
var _icon : TextureRect = null
var _item_name : Label = null
var _quantity_label : Label = null
var _quantity_value : Label = null

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Setters / Getters
# ------------------------------------------------------------------------------
func set_stack (s : ItemStack) -> void:
	if s != stack:
		_DisconnectItemStack()
		stack = s
		_ConnectItemStack()
		queue_redraw()

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
		add_child(_ilsbase)
		_icon = _ilsbase.get_node_or_null("HLayout/Icon")
		_item_name = _ilsbase.get_node_or_null("HLayout/ItemName")
		_quantity_label = _ilsbase.get_node_or_null("HLayout/VLayout/QuantityLabel")
		_quantity_value = _ilsbase.get_node_or_null("HLayout/VLayout/QuantityValue")
	_UpdateTheme()

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _UpdateTheme() -> void:
	if _ilsbase == null: return
	var panel : StyleBox = _GetThemeStylebox("panel_normal")
	_ilsbase.add_theme_stylebox_override("panel", panel)
	
	if _item_name != null:
		pass

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


