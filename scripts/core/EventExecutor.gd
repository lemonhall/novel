class_name EventExecutor
extends Node

## 事件执行器
## 负责执行事件队列，管理角色移动等操作

signal event_completed(event_id: String)
signal all_events_completed()

var event_queue: Array[EventData] = []
var current_event_index: int = 0
var is_executing: bool = false
var characters: Dictionary = {}  # 存储角色节点的字典

## 添加角色到管理器
func register_character(character_id: String, character_node: Node2D):
	characters[character_id] = character_node
	print("注册角色: ", character_id)

## 获取角色节点
func get_character(character_id: String) -> Node2D:
	if character_id in characters:
		return characters[character_id]
	return null

## 设置事件队列
func set_event_queue(events: Array[EventData]):
	event_queue = events
	current_event_index = 0
	print("设置事件队列，共 ", events.size(), " 个事件")

## 开始执行事件队列
func start_execution():
	if event_queue.is_empty():
		print("事件队列为空")
		return
	
	is_executing = true
	current_event_index = 0
	print("开始执行事件队列")
	execute_next_event()

## 执行下一个事件
func execute_next_event():
	if current_event_index >= event_queue.size():
		# 所有事件执行完毕
		is_executing = false
		print("所有事件执行完毕")
		all_events_completed.emit()
		return
	
	var event = event_queue[current_event_index]
	print("执行事件 [", current_event_index, "]: ", event.get_description())
	
	# 执行事件
	var success = event.execute(self)
	
	if success:
		event_completed.emit(event.id)
		
		# 如果事件不需要等待，立即执行下一个
		if not event.is_blocking():
			current_event_index += 1
			execute_next_event()
		# 否则等待移动完成的信号
	else:
		print("事件执行失败: ", event.id)
		is_executing = false

## 移动角色到指定位置
func move_character(character_node: Node2D, destination: Vector2, speed: float):
	if not character_node:
		return
	
	# 创建移动动画
	var tween = create_tween()
	var distance = character_node.position.distance_to(destination)
	var duration = distance / speed
	
	print("移动角色从 ", character_node.position, " 到 ", destination, " 耗时 ", duration, " 秒")
	
	tween.tween_property(character_node, "position", destination, duration)
	tween.tween_callback(_on_movement_completed)

## 移动完成回调
func _on_movement_completed():
	print("移动完成，继续下一个事件")
	current_event_index += 1
	execute_next_event()

## 停止执行
func stop_execution():
	is_executing = false
	print("停止事件执行") 