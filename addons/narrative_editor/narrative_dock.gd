@tool
extends Control

## 叙事编辑器Dock界面

var event_list: VBoxContainer
var add_button: Button
var execute_button: Button
var clear_button: Button

var events: Array = []

func _init():
	create_ui()

## 创建界面
func create_ui():
	name = "叙事编辑器"
	set_custom_minimum_size(Vector2(250, 400))
	
	var vbox = VBoxContainer.new()
	add_child(vbox)
	
	# 标题
	var title = Label.new()
	title.text = "叙事事件编辑器"
	title.add_theme_font_size_override("font_size", 16)
	vbox.add_child(title)
	
	# 分隔线
	vbox.add_child(HSeparator.new())
	
	# 事件列表
	var scroll = ScrollContainer.new()
	scroll.set_custom_minimum_size(Vector2(230, 200))
	vbox.add_child(scroll)
	
	event_list = VBoxContainer.new()
	scroll.add_child(event_list)
	
	# 按钮区域
	var button_container = HBoxContainer.new()
	vbox.add_child(button_container)
	
	# 添加移动事件按钮
	add_button = Button.new()
	add_button.text = "添加移动"
	add_button.pressed.connect(_on_add_movement_event)
	button_container.add_child(add_button)
	
	# 清空按钮
	clear_button = Button.new()
	clear_button.text = "清空"
	clear_button.pressed.connect(_on_clear_events)
	button_container.add_child(clear_button)
	
	# 执行按钮
	execute_button = Button.new()
	execute_button.text = "执行事件"
	execute_button.pressed.connect(_on_execute_events)
	vbox.add_child(execute_button)

## 添加移动事件
func _on_add_movement_event():
	var event_data = {
		"type": "movement",
		"character": "player",
		"destination": Vector2(randf() * 800 + 100, randf() * 400 + 100),
		"speed": 200.0
	}
	
	events.append(event_data)
	update_event_list()
	print("添加移动事件到 ", event_data.destination)

## 清空所有事件
func _on_clear_events():
	events.clear()
	update_event_list()
	print("清空所有事件")

## 执行事件序列
func _on_execute_events():
	if events.is_empty():
		print("没有事件可执行")
		return
	
	# 获取当前场景中的NarrativeEngine
	var main_scene = EditorInterface.get_edited_scene_root()
	if not main_scene:
		print("请先打开main.tscn场景")
		return
	
	# 这里我们先用print输出，实际项目中可以直接调用引擎
	print("执行事件序列:")
	for i in range(events.size()):
		var event = events[i]
		print("  [", i, "] ", event.type, " -> ", event.destination)
	
	print("提示: 运行游戏后按空格键查看效果")

## 更新事件列表显示
func update_event_list():
	# 清空现有显示
	for child in event_list.get_children():
		child.queue_free()
	
	# 重新创建事件显示
	for i in range(events.size()):
		var event = events[i]
		var event_label = Label.new()
		var dest = event.destination
		event_label.text = "[%d] 移动到 (%.0f, %.0f)" % [i, dest.x, dest.y]
		event_list.add_child(event_label) 