@tool
extends EditorPlugin

## 叙事编辑器插件

const NarrativeDockScene = preload("res://addons/narrative_editor/NarrativeDock.tscn")
var dock_instance

func _enter_tree():
	# 从tscn文件实例化dock界面
	dock_instance = NarrativeDockScene.instantiate()
	add_control_to_dock(DOCK_SLOT_LEFT_UL, dock_instance)
	print("叙事编辑器插件已加载")

func _exit_tree():
	# 移除dock
	if dock_instance:
		remove_control_from_docks(dock_instance)
		dock_instance.queue_free()
	print("叙事编辑器插件已卸载") 