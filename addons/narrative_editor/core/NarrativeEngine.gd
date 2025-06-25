extends Node2D

## 叙事引擎主控制器
## 整合所有组件，提供简单的API

var event_executor: EventExecutor
var player_node: Node2D

func _ready():
	setup_engine()
	create_test_scenario()

## 初始化引擎
func setup_engine():
	# 创建事件执行器
	event_executor = EventExecutor.new()
	add_child(event_executor)
	
	# 获取玩家节点
	player_node = $Player
	if player_node:
		event_executor.register_character("player", player_node)
		print("叙事引擎初始化完成")
	else:
		print("错误: 找不到Player节点")

## 创建测试场景
func create_test_scenario():
	# 优先尝试加载编辑器中设置的事件
	if load_events_from_file():
		print("已加载编辑器中设置的事件")
		return
	
	# 如果没有编辑器事件，使用默认测试事件
	var events: Array[EventData] = []
	
	# 创建一系列移动事件
	var move1 = MovementEvent.new("move1", "player", Vector2(400, 200))
	var move2 = MovementEvent.new("move2", "player", Vector2(800, 400))
	var move3 = MovementEvent.new("move3", "player", Vector2(200, 500))
	
	events.append(move1)
	events.append(move2)
	events.append(move3)
	
	# 设置事件队列
	event_executor.set_event_queue(events)
	
	print("使用默认测试场景，包含 ", events.size(), " 个移动事件")

## 从文件加载事件
func load_events_from_file() -> bool:
	var file_path = "res://data/current_events.json"
	
	if not FileAccess.file_exists(file_path):
		print("事件文件不存在: ", file_path)
		return false
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		print("无法打开事件文件: ", file_path)
		return false
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		print("JSON解析失败: ", json_string)
		return false
	
	var event_data_list = json.data
	if not event_data_list is Array:
		print("事件数据格式错误")
		return false
	
	# 转换为EventData对象
	var events: Array[EventData] = []
	for event_dict in event_data_list:
		if event_dict.type == "movement":
			var dest: Vector2
			# 处理destination可能是字符串或对象的情况
			if event_dict.destination is String:
				# 如果是字符串，尝试解析
				var dest_str = event_dict.destination as String
				dest_str = dest_str.strip_edges()
				if dest_str.begins_with("(") and dest_str.ends_with(")"):
					dest_str = dest_str.substr(1, dest_str.length() - 2)
					var coords = dest_str.split(",")
					if coords.size() == 2:
						dest = Vector2(coords[0].to_float(), coords[1].to_float())
					else:
						dest = Vector2.ZERO
				else:
					dest = Vector2.ZERO
			elif event_dict.destination is Dictionary:
				# 如果是字典，直接取x和y
				dest = Vector2(event_dict.destination.x, event_dict.destination.y)
			else:
				print("无法解析destination: ", event_dict.destination)
				dest = Vector2.ZERO
			
			var movement_event = MovementEvent.new("editor_event_" + str(events.size()), event_dict.character, dest)
			movement_event.speed = event_dict.speed
			events.append(movement_event)
			print("解析事件: 移动到 ", dest)
	
	if events.size() > 0:
		event_executor.set_event_queue(events)
		print("从编辑器加载了 ", events.size(), " 个事件")
		return true
	
	return false

## 输入处理 - 按空格开始执行
func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE:
			print("按下空格键，开始执行事件")
			event_executor.start_execution()
		elif event.keycode == KEY_R:
			print("按下R键，重置场景")
			reset_scenario()

## 重置场景
func reset_scenario():
	if player_node:
		# 回到场景中设置的初始位置
		player_node.position = Vector2(909, 222)
		print("重置角色位置到: ", player_node.position)
	create_test_scenario()
	print("场景已重置") 
