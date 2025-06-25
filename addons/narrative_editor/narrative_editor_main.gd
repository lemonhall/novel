@tool
extends Control

## 叙事编辑器主界面控制器

var events: Array = []

# UI节点引用
var events_list: VBoxContainer
var character_input: LineEdit
var x_input: SpinBox
var y_input: SpinBox
var speed_input: SpinBox
var current_pos_label: Label
var event_type_option: OptionButton

# 预设位置映射 (4x3网格)
var preset_positions = {
	"LeftTop": Vector2(100, 100),
	"TopCenter": Vector2(500, 100), 
	"RightTop": Vector2(900, 100),
	"Current": Vector2(909, 222),  # 当前角色位置
	"LeftCenter": Vector2(100, 300),
	"Center": Vector2(500, 300),
	"RightCenter": Vector2(900, 300),
	"RefreshPos": Vector2.ZERO,  # 特殊按钮
	"LeftBottom": Vector2(100, 500),
	"BottomCenter": Vector2(500, 500),
	"RightBottom": Vector2(900, 500),
	"AddEvent": Vector2.ZERO  # 特殊按钮
}

func _ready():
	print("🎭 叙事编辑器主界面已准备就绪")
	call_deferred("setup_ui")

## 设置UI
func setup_ui():
	# 获取UI节点引用
	events_list = $HSplitContainer/LeftPanel/EventsGroup/EventsScroll/EventsList
	character_input = $HSplitContainer/RightPanel/MovementGroup/CharacterContainer/CharacterInput
	x_input = $HSplitContainer/RightPanel/MovementGroup/PositionGroup/CoordinateContainer/XInput
	y_input = $HSplitContainer/RightPanel/MovementGroup/PositionGroup/CoordinateContainer/YInput
	speed_input = $HSplitContainer/RightPanel/MovementGroup/SpeedContainer/SpeedInput
	current_pos_label = $HSplitContainer/RightPanel/StatusGroup/CurrentPosLabel
	event_type_option = $HSplitContainer/RightPanel/EventTypeGroup/EventTypeOption
	
	# 设置事件类型选项
	event_type_option.add_item("移动事件")
	event_type_option.add_item("对话事件 (待实现)")
	event_type_option.add_item("特效事件 (待实现)")
	
	connect_signals()
	print("主编辑器UI设置完成")

## 连接信号
func connect_signals():
	# 左侧按钮
	$HSplitContainer/LeftPanel/ButtonsContainer/ClearEvents.pressed.connect(_on_clear_events)
	$HSplitContainer/LeftPanel/ButtonsContainer/ExecuteEvents.pressed.connect(_on_execute_events)
	
	# 预设位置按钮
	var preset_grid = $HSplitContainer/RightPanel/MovementGroup/PositionGroup/PresetGrid
	for button_name in preset_positions:
		var button = preset_grid.get_node_or_null(button_name)
		if button:
			if button_name == "RefreshPos":
				button.pressed.connect(_on_refresh_position)
			elif button_name == "AddEvent":
				button.pressed.connect(_on_add_event)
			elif button_name == "Current":
				button.pressed.connect(_on_current_position)
			else:
				button.pressed.connect(_on_preset_selected.bind(preset_positions[button_name]))

## 选择预设位置
func _on_preset_selected(position: Vector2):
	x_input.value = position.x
	y_input.value = position.y
	print("选择预设位置: ", position)

## 使用当前位置
func _on_current_position():
	_on_refresh_position()
	if current_pos_label:
		var pos_text = current_pos_label.text
		# 解析位置文本 "角色位置: (x, y)"
		var start = pos_text.find("(")
		var end = pos_text.find(")")
		if start != -1 and end != -1:
			var coords_text = pos_text.substr(start + 1, end - start - 1)
			var coords = coords_text.split(",")
			if coords.size() == 2:
				x_input.value = coords[0].strip_edges().to_float()
				y_input.value = coords[1].strip_edges().to_float()

## 刷新角色位置
func _on_refresh_position():
	var main_scene = EditorInterface.get_edited_scene_root()
	if not main_scene:
		current_pos_label.text = "请先打开main.tscn场景"
		return
	
	var player_node = main_scene.find_child("Player")
	if player_node:
		var pos = player_node.position
		current_pos_label.text = "角色位置: (%.0f, %.0f)" % [pos.x, pos.y]
		print("刷新角色位置: ", pos)
	else:
		current_pos_label.text = "找不到Player节点"

## 添加事件
func _on_add_event():
	var destination = Vector2(x_input.value, y_input.value)
	var character = character_input.text
	var speed = speed_input.value
	
	var event_data = {
		"type": "movement",
		"character": character,
		"destination": destination,
		"speed": speed
	}
	
	events.append(event_data)
	update_events_list()
	print("添加移动事件: %s -> %s (速度: %.0f)" % [character, destination, speed])

## 清空事件
func _on_clear_events():
	events.clear()
	update_events_list()
	print("清空所有事件")

## 执行事件
func _on_execute_events():
	if events.is_empty():
		print("没有事件可执行")
		return
	
	save_events_to_file()
	print("事件已保存，运行游戏后按空格键测试")

## 更新事件列表显示
func update_events_list():
	# 清空现有显示
	for child in events_list.get_children():
		child.queue_free()
	
	# 重新创建事件显示
	for i in range(events.size()):
		var event = events[i]
		var container = HBoxContainer.new()
		
		var label = Label.new()
		var dest = event.destination
		label.text = "[%d] %s 移动到 (%.0f, %.0f)" % [i, event.character, dest.x, dest.y]
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		container.add_child(label)
		
		var delete_btn = Button.new()
		delete_btn.text = "删除"
		delete_btn.pressed.connect(_on_delete_event.bind(i))
		container.add_child(delete_btn)
		
		events_list.add_child(container)

## 删除事件
func _on_delete_event(index: int):
	if index >= 0 and index < events.size():
		events.remove_at(index)
		update_events_list()
		print("删除事件 [%d]" % index)

## 保存事件到文件 (复用之前的逻辑)
func save_events_to_file():
	var file_path = "res://data/current_events.json"
	
	# 转换Vector2为可序列化的格式
	var serializable_events = []
	for event in events:
		var serializable_event = event.duplicate()
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
	else:
		print("无法保存事件文件: ", file_path) 