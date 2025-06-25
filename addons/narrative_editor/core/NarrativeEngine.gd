extends Node2D

## 叙事引擎主控制器
## 整合所有组件，提供简单的API

var event_executor: EventExecutor
var player_node: Node2D
var dialogue_ui: CanvasLayer

func _ready():
	setup_engine()
	create_test_scenario()

## 初始化引擎
func setup_engine():
	# 创建事件执行器
	event_executor = EventExecutor.new()
	add_child(event_executor)
	
	# 加载并创建对话UI
	print("🔄 开始加载对话UI...")
	var dialogue_ui_scene = preload("res://assets/ui/DialogueUI.tscn")
	dialogue_ui = dialogue_ui_scene.instantiate()
	add_child(dialogue_ui)
	print("✅ 对话UI已创建并添加到场景树")
	
	# 将对话UI传递给事件执行器
	event_executor.set_dialogue_ui(dialogue_ui)
	print("🔗 对话UI已连接到事件执行器")
	
	# 连接对话完成信号
	dialogue_ui.dialogue_finished.connect(event_executor._on_dialogue_completed)
	print("📡 对话完成信号已连接")
	
	# 获取玩家节点
	player_node = $Player
	if player_node:
		event_executor.register_character("player", player_node)
		print("✅ 叙事引擎初始化完成")
		print("📍 玩家位置: ", player_node.position)
	else:
		print("❌ 错误: 找不到Player节点")

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
			print("解析移动事件: 移动到 ", dest)
			
		elif event_dict.type == "dialogue":
			var dialogue_event = DialogueEvent.new("editor_event_" + str(events.size()), event_dict.character, event_dict.text)
			events.append(dialogue_event)
			print("解析对话事件: ", event_dict.character, " 说: ", event_dict.text)
			
		elif event_dict.type == "image":
			var pos: Vector2
			# 处理position可能是字符串或对象的情况
			if event_dict.position is String:
				# 如果是字符串，尝试解析
				var pos_str = event_dict.position as String
				pos_str = pos_str.strip_edges()
				if pos_str.begins_with("(") and pos_str.ends_with(")"):
					pos_str = pos_str.substr(1, pos_str.length() - 2)
					var coords = pos_str.split(",")
					if coords.size() == 2:
						pos = Vector2(coords[0].to_float(), coords[1].to_float())
					else:
						pos = Vector2.ZERO
				else:
					pos = Vector2.ZERO
			elif event_dict.position is Dictionary:
				# 如果是字典，直接取x和y
				pos = Vector2(event_dict.position.x, event_dict.position.y)
			else:
				print("无法解析position: ", event_dict.position)
				pos = Vector2.ZERO
			
			var image_event = ImageEvent.new("editor_event_" + str(events.size()), event_dict.image_path, pos)
			# 设置可选参数
			if "scale" in event_dict:
				if event_dict.scale is Dictionary:
					image_event.scale = Vector2(event_dict.scale.x, event_dict.scale.y)
			if "duration" in event_dict:
				image_event.duration = event_dict.duration
			if "fade_in" in event_dict:
				image_event.fade_in = event_dict.fade_in
			if "wait_for_completion" in event_dict:
				image_event.wait_for_completion = event_dict.wait_for_completion
			
			events.append(image_event)
			print("解析图片事件: ", event_dict.image_path, " 位置: ", pos)
			
		elif event_dict.type == "clear_image":
			var clear_image_event = ClearImageEvent.new("editor_event_" + str(events.size()), event_dict.get("image_id", ""))
			# 设置可选参数
			if "fade_out" in event_dict:
				clear_image_event.fade_out = event_dict.fade_out
			if "fade_duration" in event_dict:
				clear_image_event.fade_duration = event_dict.fade_duration
			if "wait_for_completion" in event_dict:
				clear_image_event.wait_for_completion = event_dict.wait_for_completion
			
			events.append(clear_image_event)
			if clear_image_event.image_id.is_empty():
				print("解析清除图片事件: 清除所有图片")
			else:
				print("解析清除图片事件: 清除图片 ", clear_image_event.image_id)
			
		else:
			print("未知的事件类型: ", event_dict.type)
	
	if events.size() > 0:
		event_executor.set_event_queue(events)
		print("从编辑器加载了 ", events.size(), " 个事件")
		return true
	
	return false

## 输入处理 - 按空格开始执行
func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE:
			print("🔍 NarrativeEngine收到空格键")
			print("   对话UI存在: ", dialogue_ui != null)
			print("   对话UI可见: ", dialogue_ui.visible if dialogue_ui else "N/A")
			print("   事件执行中: ", event_executor.is_executing if event_executor else "N/A")
			
			# 如果对话UI正在显示，不处理空格键（让对话UI处理）
			if dialogue_ui and dialogue_ui.visible:
				print("   ❌ 对话UI正在显示，跳过空格键处理")
				return
			print("   ✅ 开始执行事件")
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
