@tool
extends Control

## 叙事编辑器UI控制器 - 使用tscn界面

var events: Array = []

# UI节点引用 - 不使用@onready，在运行时获取
var event_list: VBoxContainer
var x_input: SpinBox
var y_input: SpinBox
var current_pos_label: Label

# 初始位置记录
var initial_player_position: Vector2 = Vector2(909, 222)

# 预设位置映射
var preset_positions = {
	"LeftTop": Vector2(100, 100),
	"TopCenter": Vector2(500, 100),
	"RightTop": Vector2(900, 100),
	"LeftCenter": Vector2(100, 300),
	"Center": Vector2(500, 300),
	"RightCenter": Vector2(900, 300),
	"LeftBottom": Vector2(100, 500),
	"BottomCenter": Vector2(500, 500),
	"RightBottom": Vector2(900, 500)
}

func _ready():
	print("🚀 NarrativeDock UI 已准备就绪")
	# 延迟一帧确保所有节点都已准备好
	call_deferred("connect_signals")
	# 再次延迟调用，确保一切都准备好了
	call_deferred("setup_test")

## 连接所有信号
func connect_signals():
	print("开始连接信号...")
	
	# 获取UI节点引用
	event_list = $VBoxContainer/ScrollContainer/EventList
	x_input = $VBoxContainer/PositionGroup/CustomContainer/XInput
	y_input = $VBoxContainer/PositionGroup/CustomContainer/YInput
	current_pos_label = $VBoxContainer/InfoContainer/CurrentPos
	
	# 设置初始位置显示
	if current_pos_label:
		current_pos_label.text = "当前位置: (%.0f, %.0f)" % [initial_player_position.x, initial_player_position.y]
	
	print("获取到的节点:")
	print("  event_list: ", event_list)
	print("  x_input: ", x_input)
	print("  y_input: ", y_input)
	print("  current_pos_label: ", current_pos_label)
	
	# 预设位置按钮
	var preset_grid = $VBoxContainer/PositionGroup/PresetGrid
	print("preset_grid: ", preset_grid)
	
	if preset_grid:
		for button_name in preset_positions:
			var button = preset_grid.get_node_or_null(button_name)
			if button:
				button.pressed.connect(_on_preset_selected.bind(preset_positions[button_name]))
				print("连接预设按钮: ", button_name)
			else:
				print("找不到按钮: ", button_name)
	
	# 主要按钮
	var add_btn = $VBoxContainer/ButtonContainer/AddMovement
	var clear_btn = $VBoxContainer/ButtonContainer/ClearEvents
	var refresh_btn = $VBoxContainer/InfoContainer/RefreshPos
	var execute_btn = $VBoxContainer/ExecuteButton
	
	print("获取到的按钮:")
	print("  add_btn: ", add_btn)
	print("  clear_btn: ", clear_btn)
	print("  refresh_btn: ", refresh_btn)
	print("  execute_btn: ", execute_btn)
	
	if add_btn:
		add_btn.pressed.connect(_on_add_movement)
		print("✅ 连接添加移动按钮成功")
	else:
		print("❌ 添加移动按钮未找到")
		
	if clear_btn:
		clear_btn.pressed.connect(_on_clear_events)
		print("✅ 连接清空按钮成功")
	else:
		print("❌ 清空按钮未找到")
		
	if refresh_btn:
		refresh_btn.pressed.connect(_on_refresh_position)
		print("✅ 连接刷新位置按钮成功")
	else:
		print("❌ 刷新位置按钮未找到")
		
	if execute_btn:
		execute_btn.pressed.connect(_on_execute_events)
		print("✅ 连接执行按钮成功")
	else:
		print("❌ 执行按钮未找到")
	
	print("信号连接完成")

## 测试函数
func setup_test():
	print("🧪 开始测试设置")
	# 手动测试添加一个事件
	events.append({
		"type": "test",
		"character": "test",
		"destination": Vector2(100, 100),
		"speed": 200.0
	})
	print("测试事件数量: ", events.size())

## 选择预设位置
func _on_preset_selected(position: Vector2):
	x_input.value = position.x
	y_input.value = position.y

## 添加移动事件
func _on_add_movement():
	print("点击了添加移动按钮")
	
	if not x_input or not y_input:
		print("输入框未找到")
		return
	
	var destination = Vector2(x_input.value, y_input.value)
	var event_data = {
		"type": "movement",
		"character": "player",
		"destination": destination,
		"speed": 200.0
	}
	
	events.append(event_data)
	print("添加了移动事件: ", destination)
	print("当前事件数量: ", events.size())
	update_event_list()

## 清空所有事件
func _on_clear_events():
	events.clear()
	update_event_list()

## 刷新角色位置
func _on_refresh_position():
	var main_scene = EditorInterface.get_edited_scene_root()
	if not main_scene:
		return
	
	var player_node = main_scene.find_child("Player")
	if player_node:
		var pos = player_node.position
		current_pos_label.text = "当前位置: (%.0f, %.0f)" % [pos.x, pos.y]

## 执行事件序列
func _on_execute_events():
	if events.is_empty():
		print("没有事件可执行")
		return
		
	print("执行事件序列 (共%d个):" % events.size())
	for i in range(events.size()):
		var event = events[i]
		print("  [%d] %s -> %s" % [i, event.type, event.destination])
	
	# 保存事件到文件，供运行时使用
	save_events_to_file()
	print("事件已保存，请运行游戏并按空格键测试")

## 保存事件到文件
func save_events_to_file():
	var file_path = "res://data/current_events.json"
	
	# 转换Vector2为可序列化的格式
	var serializable_events = []
	for event in events:
		var serializable_event = event.duplicate()
		# 将Vector2转换为字典
		if serializable_event.destination is Vector2:
			var vec = serializable_event.destination as Vector2
			serializable_event.destination = {"x": vec.x, "y": vec.y}
		serializable_events.append(serializable_event)
	
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(serializable_events)
		file.store_string(json_string)
		file.close()
		print("事件保存到: ", file_path)
		print("保存的JSON内容: ", json_string)
	else:
		print("无法保存事件文件: ", file_path)

## 更新事件列表显示
func update_event_list():
	print("更新事件列表，事件数量: ", events.size())
	
	if not event_list:
		print("事件列表节点未找到")
		return
	
	# 清空现有显示
	for child in event_list.get_children():
		child.queue_free()
	
	# 重新创建事件显示
	for i in range(events.size()):
		var event = events[i]
		var label = Label.new()
		var dest = event.destination
		label.text = "[%d] 移动到 (%.0f, %.0f)" % [i, dest.x, dest.y]
		event_list.add_child(label)
		print("添加事件标签: ", label.text) 