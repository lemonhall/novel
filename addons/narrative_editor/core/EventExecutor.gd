class_name EventExecutor
extends Node

## 事件执行器
## 负责执行事件队列，管理角色移动、对话等操作

signal event_completed(event_id: String)
signal all_events_completed()
signal dialogue_displayed(character: String, text: String)
signal image_displayed(image_path: String, position: Vector2)

var event_queue: Array[EventData] = []
var current_event_index: int = 0
var is_executing: bool = false
var characters: Dictionary = {}  # 存储角色节点的字典
var dialogue_ui: CanvasLayer = null  # 对话UI引用
var displayed_images: Dictionary = {}  # 存储显示的图片节点

## 设置对话UI
func set_dialogue_ui(ui: CanvasLayer):
	dialogue_ui = ui
	print("设置对话UI")

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
		# 否则等待相应的完成信号
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

## 显示对话
func show_dialogue(character: String, text: String):
	print("🎬 EventExecutor.show_dialogue被调用")
	print("   角色: ", character)
	print("   内容: ", text)
	print("   dialogue_ui: ", dialogue_ui)
	print("   dialogue_ui是否存在: ", dialogue_ui != null)
	
	if dialogue_ui:
		print("✅ 找到对话UI，检查show_dialogue方法...")
		if dialogue_ui.has_method("show_dialogue"):
			print("✅ 调用dialogue_ui.show_dialogue()")
			dialogue_ui.show_dialogue(character, text)
		else:
			print("❌ 对话UI没有show_dialogue方法")
	else:
		# 简单的控制台输出（作为后备）
		print("⚠️ 没有对话UI，使用控制台输出")
		print("对话 - %s: %s" % [character, text])
		print("按任意键继续...")
	
	# 发送信号
	dialogue_displayed.emit(character, text)
	print("📡 dialogue_displayed信号已发送")

## 显示图片
func show_image(image_path: String, position: Vector2, scale: Vector2 = Vector2.ONE, duration: float = 0.0, fade_in: bool = true):
	print("🖼️ EventExecutor.show_image被调用")
	print("   图片路径: ", image_path)
	print("   位置: ", position)
	print("   缩放: ", scale)
	print("   持续时间: ", duration)
	
	# 创建图片节点
	var sprite = Sprite2D.new()
	var texture = load(image_path) as Texture2D
	
	if not texture:
		print("❌ 无法加载图片: ", image_path)
		_on_image_completed()
		return
	
	sprite.texture = texture
	sprite.position = position
	sprite.scale = scale
	
	# 添加到场景
	get_tree().current_scene.add_child(sprite)
	
	# 生成稳定的图片ID（基于文件名+时间戳）
	var filename = image_path.get_file().get_basename()
	var image_id = filename + "_0"  # 默认使用_0
	
	# 如果同名图片已存在，先清除旧的
	if image_id in displayed_images:
		print("📝 发现同名图片，清除旧的: ", image_id)
		var old_sprite = displayed_images[image_id]
		old_sprite.queue_free()
		displayed_images.erase(image_id)
	
	displayed_images[image_id] = sprite
	print("📝 图片已存储，ID: ", image_id)
	
	# 淡入效果
	if fade_in:
		sprite.modulate.a = 0.0
		var tween = create_tween()
		tween.tween_property(sprite, "modulate:a", 1.0, 0.5)
	
	# 如果设置了持续时间，自动隐藏
	if duration > 0:
		var timer = Timer.new()
		timer.wait_time = duration
		timer.one_shot = true
		timer.timeout.connect(func(): 
			# 只移除图片，不触发事件完成
			if image_id in displayed_images:
				var sprite_to_remove = displayed_images[image_id]
				displayed_images.erase(image_id)
				sprite_to_remove.queue_free()
				print("⏰ 图片自动移除: ", image_id)
		)
		get_tree().current_scene.add_child(timer)
		timer.start()
	# duration=0时图片将永久显示直到手动清除
	
	# 发送信号
	image_displayed.emit(image_path, position)
	print("📡 image_displayed信号已发送")

## 清除指定图片
func clear_image(image_id: String, fade_out: bool = true, fade_duration: float = 0.5):
	print("🗑️ EventExecutor.clear_image被调用")
	print("   图片ID: ", image_id)
	print("   淡出: ", fade_out)
	print("   淡出时长: ", fade_duration)
	
	if image_id in displayed_images:
		var sprite = displayed_images[image_id]
		displayed_images.erase(image_id)
		
		if fade_out and fade_duration > 0:
			# 淡出动画
			var tween = create_tween()
			tween.tween_property(sprite, "modulate:a", 0.0, fade_duration)
			tween.tween_callback(func(): sprite.queue_free())
			
			# 如果需要等待完成
			if fade_duration > 0:
				var timer = Timer.new()
				timer.wait_time = fade_duration
				timer.one_shot = true
				timer.timeout.connect(_on_image_clear_completed)
				get_tree().current_scene.add_child(timer)
				timer.start()
			else:
				_on_image_clear_completed()
		else:
			# 立即删除
			sprite.queue_free()
			_on_image_clear_completed()
		
		print("✅ 图片已清除: ", image_id)
	else:
		print("❌ 未找到图片: ", image_id)
		_on_image_clear_completed()

## 清除所有图片
func clear_all_images(fade_out: bool = true, fade_duration: float = 0.5):
	print("🗑️ EventExecutor.clear_all_images被调用")
	print("   淡出: ", fade_out)
	print("   淡出时长: ", fade_duration)
	
	if displayed_images.is_empty():
		print("⚠️ 没有要清除的图片")
		_on_image_clear_completed()
		return
	
	var sprites_to_clear = displayed_images.values()
	displayed_images.clear()
	
	if fade_out and fade_duration > 0:
		# 为所有图片创建淡出动画
		for sprite in sprites_to_clear:
			var tween = create_tween()
			tween.tween_property(sprite, "modulate:a", 0.0, fade_duration)
			tween.tween_callback(func(): sprite.queue_free())
		
		# 等待动画完成
		var timer = Timer.new()
		timer.wait_time = fade_duration
		timer.one_shot = true
		timer.timeout.connect(_on_image_clear_completed)
		get_tree().current_scene.add_child(timer)
		timer.start()
	else:
		# 立即删除所有图片
		for sprite in sprites_to_clear:
			sprite.queue_free()
		_on_image_clear_completed()
	
	print("✅ 所有图片已清除，数量: ", sprites_to_clear.size())

## 图片清除完成回调
func _on_image_clear_completed():
	print("图片清除完成，继续下一个事件")
	current_event_index += 1
	execute_next_event()

## 图片显示完成回调
func _on_image_completed():
	print("图片显示完成，继续下一个事件")
	current_event_index += 1
	execute_next_event()

## 对话完成（由用户输入或UI触发）
func _on_dialogue_completed():
	print("对话完成，继续下一个事件")
	current_event_index += 1
	execute_next_event()

## 移动完成回调
func _on_movement_completed():
	print("移动完成，继续下一个事件")
	current_event_index += 1
	execute_next_event()

## 停止执行
func stop_execution():
	is_executing = false
	print("停止事件执行")

## 处理用户输入（用于对话继续）
func _input(event):
	if is_executing and event.is_action_pressed("ui_accept"):
		# 检查当前事件是否是对话事件且没有UI处理
		if current_event_index < event_queue.size():
			var current_event = event_queue[current_event_index]
			if current_event is DialogueEvent:
				# 如果有对话UI，让UI处理输入；否则直接完成对话
				if not dialogue_ui or not dialogue_ui.visible:
					_on_dialogue_completed() 