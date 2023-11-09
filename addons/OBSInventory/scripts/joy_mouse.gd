extends Node
class_name JoyMouse


# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export_category("Joy Mouse")
@export var enabled : bool = false
@export_range(0.0, 1.0) var initial_x : float = 0.5
@export_range(0.0, 1.0) var initial_y : float = 0.5
@export_enum("Left", "Right") var joy_pad_axis : int = 0
@export var joy_pixels_per_second : float = 800.0

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _axis : Vector2 = Vector2.ZERO

# ------------------------------------------------------------------------------
# Setters
# ------------------------------------------------------------------------------
func set_enabled(e : bool) -> void:
	enabled = e
	set_process(enabled)

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	set_enabled(enabled)

func _process(delta: float) -> void:
	_axis += _CalculateJoyAxis() * joy_pixels_per_second * delta
	if _axis.length_squared() > 0.0:
		var axis_floored = _axis.floor()
		var mpos : Vector2 = _GetMousePos() + axis_floored
		_axis -= axis_floored
		Input.warp_mouse(mpos)

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _CalculateJoyAxis() -> Vector2:
	var axis_x = JOY_AXIS_LEFT_X if joy_pad_axis == 0 else JOY_AXIS_RIGHT_X
	var axis_y = JOY_AXIS_LEFT_Y if joy_pad_axis == 0 else JOY_AXIS_RIGHT_Y
	
	for jid in Input.get_connected_joypads():
		var x : float = Input.get_joy_axis(jid, axis_x)
		var y : float = Input.get_joy_axis(jid, axis_y)
		var axis : Vector2 = Vector2(x, y)
		if axis.length() > 0.1:
			return axis
	
	return Vector2.ZERO

func _GetMousePos() -> Vector2:
	var view : Viewport = get_viewport()
	if view != null:
		return view.get_mouse_position()
	
	return Vector2.ZERO

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------


# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------



