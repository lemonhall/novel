@tool
extends EditorPlugin

## 叙事编辑器插件

const NarrativeEditorScene = preload("res://addons/narrative_editor/NarrativeEditor.tscn")
var main_editor_instance

func _enter_tree():
	# 创建主编辑器界面
	main_editor_instance = NarrativeEditorScene.instantiate()
	
	# 添加为主界面页签 (像AssetLib那样)
	EditorInterface.get_editor_main_screen().add_child(main_editor_instance)
	_make_visible(false)
	print("叙事编辑器插件已加载")

func _exit_tree():
	# 移除主编辑器界面
	if main_editor_instance:
		main_editor_instance.queue_free()
	print("叙事编辑器插件已卸载")

func _has_main_screen():
	return true

func _get_plugin_name():
	return "叙事编辑器"

func _get_plugin_icon():
	# 使用内置图标，你也可以自定义
	return EditorInterface.get_editor_theme().get_icon("AnimationPlayer", "EditorIcons")

func _make_visible(visible):
	if main_editor_instance:
		main_editor_instance.visible = visible 