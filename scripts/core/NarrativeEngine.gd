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
	
	print("测试场景创建完成，包含 ", events.size(), " 个移动事件")

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
		player_node.position = Vector2(909, 222)  # 回到初始位置
	create_test_scenario()
	print("场景已重置") 