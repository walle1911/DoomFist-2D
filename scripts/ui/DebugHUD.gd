extends CanvasLayer

@export var refresh_interval: float = 0.08

@onready var status_label: Label = $Panel/MarginContainer/StatusLabel

var target_player: Node = null
var refresh_timer: float = 0.0


func _ready() -> void:
	target_player = get_parent()
	update_debug_text()


func _process(delta: float) -> void:
	refresh_timer -= delta

	if refresh_timer > 0.0:
		return

	refresh_timer = refresh_interval
	update_debug_text()


func update_debug_text() -> void:
	if target_player == null or not target_player.has_method("get_debug_text"):
		status_label.text = "NO PLAYER"
		return

	status_label.text = str(target_player.call("get_debug_text"))
