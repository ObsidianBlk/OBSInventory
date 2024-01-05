@tool
@icon("res://addons/OBSInventory/icons/icon_inventory_grid_stack.svg")
extends InventoryStackControl
class_name InventoryGridStack


# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------

const DEFAULT_NODE_GROUP : StringName = &"InventoryGridStack"

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export_category("Inventory Grid Stack")
@export var cell_size : int = 0:					set = set_cell_size
@export var show_grid_mask : bool = true:			set = set_show_grid_mask
@export var highlight : bool = false:				set = set_highlight

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _tex_rect : TextureRect = null
var _follow_mode : bool = false
var _follow_offset : Vector2 = Vector2.ZERO

var _themectrl : ThemeCTRL = ThemeCTRL.new([
	["grid_cell", Theme.DATA_TYPE_STYLEBOX],
	["font", Theme.DATA_TYPE_FONT],
	["font_size", Theme.DATA_TYPE_FONT_SIZE]
])

# ------------------------------------------------------------------------------
# Setters
# ------------------------------------------------------------------------------
func set_stack (s : ItemStack) -> void:
	if s != stack:
		_DisconnectItemStack()
		stack = s
		_ConnectItemStack()
		queue_redraw()
		_AdjustControlSize()

func set_cell_size (s : int) -> void:
	if s != cell_size:
		cell_size = s
		queue_redraw()
		_AdjustControlSize()

func set_show_grid_mask(s : bool) -> void:
	if s != show_grid_mask:
		show_grid_mask = s
		queue_redraw()

func set_highlight(h : bool) -> void:
	if h != highlight:
		highlight = h
		queue_redraw()

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	_tex_rect = TextureRect.new()
	_tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_tex_rect.stretch_mode = TextureRect.STRETCH_SCALE
	_tex_rect.show_behind_parent = true
	add_child(_tex_rect)
	super._ready()

func _get(property : StringName) -> Variant:
	if _themectrl.has_override(property):
		return _themectrl.get_override(property)
	return null

func _set(property : StringName, value : Variant) -> bool:
	if _themectrl.has_override(property):
		var res : bool = _themectrl.set_override(property, value)
		if res:
			queue_redraw()
		return res
	return false

func _get_property_list() -> Array[Dictionary]:
	return _themectrl.get_theme_override_property_list()

func _process(delta: float) -> void:
	if not _follow_mode: return
	if not is_inside_tree(): return
	if get_parent() is InventoryGrid: return
	position = get_global_mouse_position() - _follow_offset

func _get_minimum_size() -> Vector2:
	if stack == null or stack.item == null: return Vector2.ZERO
	if cell_size > 0:
		return stack.item.inventory_mask.dimensions * cell_size
	elif stack.item.inventory_texture != null:
		return stack.item.inventory_texture.get_size()
	return Vector2.ZERO

func _draw() -> void:
	if stack == null or stack.item == null: return
	if stack.item.inventory_mask == null or stack.item.inventory_mask.max_coords() <= 0: return
	
	var vcell_size : Vector2 = _GetSizeVector()
	if vcell_size.x < 1 or vcell_size.y < 1: return
	
	if show_grid_mask:
		var style : StyleBox = _GetThemeStylebox(&"grid_cell", _GetThemeType(), _themectrl)
		for y in range(stack.item.inventory_mask.dimensions.y):
			for x in range(stack.item.inventory_mask.dimensions.x):
				var coord : Vector2i = Vector2i(x, y)
				if not stack.item.inventory_mask.has_value(coord): continue
				var rect : Rect2 = Rect2(Vector2(x, y) * vcell_size, vcell_size)
				draw_style_box(style, rect)
				#draw_rect(rect, Color.WHITE, false, 1.0)
	
	if _tex_rect != null and stack.item.inventory_texture != null:
		var tscale : Vector2 = _TexScaleFromCellSize()
		_tex_rect.size = stack.item.inventory_texture.get_size() * tscale
		if _tex_rect.texture == null:
			_tex_rect.texture = stack.item.inventory_texture
	
	if stack.quantity > 1:
		var str : String = "%s"%[stack.quantity]
		var font_origin : Vector2 = vcell_size * Vector2(stack.item.inventory_mask.dimensions)
		var font : Font = _GetThemeFont(&"font", _GetThemeType(), _themectrl)
		var font_size : int = _GetThemeFontSize(&"font_size", _GetThemeType(), _themectrl)
		var string_size : Vector2 = font.get_string_size(str, HORIZONTAL_ALIGNMENT_RIGHT, -1, font_size)
		draw_string(font, font_origin - Vector2(string_size.x, 0), str, HORIZONTAL_ALIGNMENT_RIGHT, -1, font_size)

func _notification(what : int):
	match what:
		NOTIFICATION_RESIZED:
			pass
		NOTIFICATION_THEME_CHANGED:
			queue_redraw()

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _ConnectItemStack() -> void:
	if stack == null: return
	super._ConnectItemStack()
	if _tex_rect != null and stack.item != null and stack.item.inventory_texture != null:
		_tex_rect.texture = stack.item.inventory_texture

func _DisconnectItemStack() -> void:
	if stack == null: return
	super._DisconnectItemStack()
	if _tex_rect != null:
		_tex_rect.texture = null

func _TexScaleFromCellSize() -> Vector2:
	if stack == null or stack.item == null or stack.item.inventory_texture == null:
		return Vector2.ZERO
	if cell_size <= 0: return Vector2.ONE
	
	var tsize : Vector2 = stack.item.inventory_texture.get_size()
	var mask_size : Vector2 = stack.item.inventory_mask.dimensions * cell_size
	if mask_size.x <= 0 or mask_size.y <= 0:
		return Vector2.ONE
	return mask_size / tsize

func _AdjustControlSize() -> void:
	size = get_minimum_size()

func _GetSizeVector() -> Vector2:
	var vcell_size : Vector2 = Vector2.ONE * cell_size
	if cell_size <= 0 and stack.item.inventory_texture != null:
		vcell_size = Vector2(
			stack.item.inventory_texture.get_width() / stack.item.inventory_mask.dimensions.x,
			stack.item.inventory_texture.get_height() / stack.item.inventory_mask.dimensions.y
		)
	return vcell_size

func _GetThemeType() -> StringName:
	if theme_type_variation != &"":
		return theme_type_variation
	return DEFAULT_NODE_GROUP

#func _GetThemeFont(font_name : StringName) -> Font:
	#var type_name : StringName = DEFAULT_NODE_GROUP if theme_type_variation == &"" else theme_type_variation
	#if has_theme_font(font_name, type_name):
		#return get_theme_font(font_name, type_name)
	#return DEFAULT_THEME.get_font(font_name, type_name)
#
#func _GetThemeFontSize(font_size_name : StringName) -> int:
	#var type_name : StringName = DEFAULT_NODE_GROUP if theme_type_variation == &"" else theme_type_variation
	#if has_theme_font_size(font_size_name, type_name):
		#return get_theme_font_size(font_size_name, type_name)
	#return DEFAULT_THEME.get_font_size(font_size_name, type_name)
#
#func _GetThemeStylebox(style_name : StringName) -> StyleBox:
	#var type_name : StringName = DEFAULT_NODE_GROUP if theme_type_variation == &"" else theme_type_variation
	#if has_theme_stylebox(style_name, type_name):
		#return get_theme_stylebox(style_name, type_name)
	#return DEFAULT_THEME.get_stylebox(style_name, DEFAULT_NODE_GROUP)


# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func get_stack_rect() -> Rect2:
	if stack == null or stack.item == null: return Rect2(Vector2.ZERO, Vector2.ZERO)
	return Rect2(global_position, _GetSizeVector())

func get_item() -> Item:
	if stack == null: return null
	return stack.item

func get_item_mask() -> Grid:
	if stack == null: return null
	return stack.item.inventory_mask.rotated(get_orientation())

func get_quantity() -> int:
	if stack == null: return 0
	return stack.quantity

func get_orientation() -> int:
	if stack == null: return Grid.ROT_NONE
	return stack.get_metadata(ItemGridStash.GRID_META_ORIENTATION, Grid.ROT_NONE)

func get_origin() -> Vector2i:
	if stack == null: return Vector2i(-1, -1)
	return stack.get_metadata(ItemGridStash.GRID_META_ORIGIN, Vector2i(-1, -1))

func follow_mouse() -> void:
	if _follow_mode == true: return
	_follow_mode = true
	_follow_offset = get_local_mouse_position()

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------

func _on_quantity_changed() -> void:
	queue_redraw()
	_AdjustControlSize()

