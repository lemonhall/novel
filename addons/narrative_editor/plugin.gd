@tool
extends EditorPlugin

## 叙事编辑器插件

const MainPanel = preload("res://addons/narrative_editor/NarrativeEditor.tscn")
var main_panel_instance
var main_screen_container

func _enter_tree():
	main_screen_container = EditorInterface.get_editor_main_screen()
	# 不在这里添加面板，等到_make_visible(true)时再添加
	print("叙事编辑器插件已加载")

func _exit_tree():
	if main_panel_instance:
		if main_panel_instance.get_parent():
			main_panel_instance.get_parent().remove_child(main_panel_instance)
		main_panel_instance.queue_free()
		main_panel_instance = null
	print("叙事编辑器插件已卸载")

func _has_main_screen():
	return true

func _get_plugin_name():
	return "叙事编辑器"

func _get_plugin_icon():
	# Must return some kind of Texture for the icon.
	return EditorInterface.get_editor_theme().get_icon("AnimationPlayer", "EditorIcons")

func _make_visible(visible):
	if visible:
		# 显示时：创建并添加面板
		if not main_panel_instance:
			main_panel_instance = MainPanel.instantiate()
		if not main_panel_instance.get_parent():
			main_screen_container.add_child(main_panel_instance)
		print("显示叙事编辑器")
	else:
		# 隐藏时：从场景树中移除面板
		if main_panel_instance and main_panel_instance.get_parent():
			main_panel_instance.get_parent().remove_child(main_panel_instance)
		print("隐藏叙事编辑器") 