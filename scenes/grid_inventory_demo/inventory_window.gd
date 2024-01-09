extends Control


# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export_category("Inventory Window")
@export var titlebar : PanelContainer = null:		set = set_titlebar
@export var input_interact : StringName = &""
@export var animation_player : AnimationPlayer = null
@export var focus_animation : StringName = &""


# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _offset : Vector2 = Vector2.ZERO
var _drag_enabled : bool = false

# ------------------------------------------------------------------------------
# Setters
# ------------------------------------------------------------------------------
func set_titlebar(tb : PanelContainer) -> void:
	if tb == titlebar: return
	_DisconnectTitlebar()
	titlebar = tb
	_ConnectTitlebar()


# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	_ConnectTitlebar()

func _process(delta : float) -> void:
	if not _drag_enabled: return
	global_position = get_global_mouse_position() - _offset

func _input(event : InputEvent) -> void:
	# This method exists because, while dragging, the mouse cursor may not always remain on the
	#  titlebar control (update lag). This just makes sure we can read a release of the <input_interact>
	#  input even if there's update lag going on.
	if not _drag_enabled: return
	if event.is_action_released(input_interact):
		_drag_enabled = false

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _DisconnectTitlebar() -> void:
	if titlebar == null: return
	if titlebar.gui_input.is_connected(_on_titlebar_gui_input):
		titlebar.gui_input.disconnect(_on_titlebar_gui_input)

func _ConnectTitlebar() -> void:
	if titlebar == null: return
	if not titlebar.gui_input.is_connected(_on_titlebar_gui_input):
		titlebar.gui_input.connect(_on_titlebar_gui_input)

func _MakeTopWindow() -> void:
	var parent : Node = get_parent()
	if parent == null: return
	parent.move_child(self, -1)
	if animation_player != null:
		if not animation_player.is_playing():
			animation_player.play(focus_animation)

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_titlebar_gui_input(event : InputEvent) -> void:
	if event.is_action_pressed(input_interact):
		_MakeTopWindow()
		_drag_enabled = true
		_offset = get_global_mouse_position() - global_position
	elif event.is_action_released(input_interact):
		_drag_enabled = false
