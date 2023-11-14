@tool
extends RefCounted
class_name ThemeCTRL

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _overrides : Dictionary = {}
var _alt_names : Dictionary = {}

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _init(items : Array[Array]):
	for item in items:
		if item.size() != 2: continue
		if not item[1] is Theme.DataType: continue
		if typeof(item[0]) == TYPE_STRING and not item[0].is_empty():
			var full_name : StringName = Generate_Property_Name(item[0], item[1])
			if full_name == &"": continue
			
			_overrides[full_name] = {
				name = item[0],
				type = item[1],
				value = null
			}
			_alt_names[item[0]] = full_name

# ------------------------------------------------------------------------------
# Static Public Methods
# ------------------------------------------------------------------------------
static func Generate_Property_Name(base_name : String, type : Theme.DataType) -> StringName:
	match type:
		Theme.DATA_TYPE_COLOR:
			return &"theme_override_colors/%s"%[base_name]
		Theme.DATA_TYPE_CONSTANT:
			return &"theme_override_constants/%s"%[base_name]
		Theme.DATA_TYPE_FONT:
			return &"theme_override_fonts/%s"%[base_name]
		Theme.DATA_TYPE_FONT_SIZE:
			return &"theme_override_font_sizes/%s"%[base_name]
		Theme.DATA_TYPE_ICON:
			return &"theme_override_icons/%s"%[base_name]
		Theme.DATA_TYPE_STYLEBOX:
			return &"theme_override_styles/%s"%[base_name]
	return &""

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func has_override(property : StringName) -> bool:
	return property in _overrides

func get_override(property : StringName) -> Variant:
	if property in _overrides:
		return _overrides[property].value
	return null

func get_override_short_name(property : StringName) -> StringName:
	if property in _overrides:
		return _overrides[property].name
	return &""

func get_override_from_short_name(short_name : StringName) -> StringName:
	if short_name in _alt_names:
		return _alt_names[short_name]
	return &""

func set_override(property : StringName, value : Variant) -> bool:
	if property in _overrides:
		var allowed : bool = false
		match _overrides[property].type:
			Theme.DATA_TYPE_COLOR:
				allowed = typeof(value) == TYPE_COLOR or value == null
			Theme.DATA_TYPE_CONSTANT:
				allowed = typeof(value) == TYPE_INT or value == null
			Theme.DATA_TYPE_FONT:
				allowed = value is Font or value == null
			Theme.DATA_TYPE_FONT_SIZE:
				allowed = typeof(value) == TYPE_INT or value == null
			Theme.DATA_TYPE_ICON:
				allowed = value is Texture2D or value == null
			Theme.DATA_TYPE_STYLEBOX:
				allowed = value is StyleBox or value == null

		if allowed:
			_overrides[property].value = value
			return true

	return false

func get_theme_override_property_list() -> Array[Dictionary]:
	if _overrides.is_empty():
		return []
	
	var props: Array[Dictionary] = [{
		"name": "Theme Overrides",
		"type": TYPE_NIL,
		"usage": PROPERTY_USAGE_GROUP,
		"hint_string": "theme_override_"
	}]

	for prop_full_name in _overrides.keys():
		var prop_type : Variant.Type
		var prop_hint : PropertyHint
		var prop_hint_string : String
		
		match _overrides[prop_full_name].type:
			Theme.DATA_TYPE_COLOR:
				prop_type = TYPE_COLOR
			Theme.DATA_TYPE_CONSTANT:
				prop_type = TYPE_INT
			Theme.DATA_TYPE_FONT:
				prop_type = TYPE_OBJECT
				prop_hint = PROPERTY_HINT_RESOURCE_TYPE
				prop_hint_string = "Font"
			Theme.DATA_TYPE_FONT_SIZE:
				prop_type = TYPE_INT
			Theme.DATA_TYPE_ICON:
				prop_type = TYPE_OBJECT
				prop_hint = PROPERTY_HINT_RESOURCE_TYPE
				prop_hint_string = "Texture2D"
			Theme.DATA_TYPE_STYLEBOX:
				prop_type = TYPE_OBJECT
				prop_hint = PROPERTY_HINT_RESOURCE_TYPE
				prop_hint_string = "StyleBox"

		var usage: int = PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_CHECKABLE
		if _overrides[prop_full_name].value != null:
			usage = usage | PROPERTY_USAGE_STORAGE
		
		props.append({
			name = prop_full_name,
			type = prop_type,
			hint = prop_hint,
			hint_string = prop_hint_string,
			usage = usage
		})
	
	return props
