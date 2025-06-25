@tool
extends EditorPlugin

## 叙事编辑器插件

const NarrativeDock = preload("res://addons/narrative_editor/narrative_dock.gd")
var dock_instance

func _enter_tree():
	# 添加自定义dock
	dock_instance = NarrativeDock.new()
	add_control_to_dock(DOCK_SLOT_LEFT_UL, dock_instance)
	print("叙事编辑器插件已加载")

func _exit_tree():
	# 移除dock
	if dock_instance:
		remove_control_from_docks(dock_instance)
		dock_instance.queue_free()
	print("叙事编辑器插件已卸载") 