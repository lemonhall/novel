@tool
extends Control

## 叙事编辑器主界面控制器

var events: Array = []
var ui_initialized: bool = false

# UI节点引用
var events_list: VBoxContainer
var character_input: LineEdit
var x_input: SpinBox
var y_input: SpinBox
var speed_input: SpinBox
var current_pos_label: Label
var event_type_option: OptionButton

# 对话事件UI节点
var dialogue_text_input: TextEdit
var movement_group: VBoxContainer
var dialogue_group: VBoxContainer

# 图片事件UI节点
var image_group: VBoxContainer
var image_path_input: LineEdit
var image_resource_picker: EditorResourcePicker
var image_x_input: SpinBox
var image_y_input: SpinBox
var image_scale_x_input: SpinBox
var image_scale_y_input: SpinBox
var image_duration_input: SpinBox
var image_fade_in_check: CheckBox
var image_wait_check: CheckBox

# 清除图片事件UI节点
var clear_image_group: VBoxContainer
var clear_image_id_input: LineEdit
var clear_fade_out_check: CheckBox
var clear_fade_duration_input: SpinBox
var clear_wait_check: CheckBox

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
	if not ui_initialized:
		call_deferred("setup_ui")

## 设置UI
func setup_ui():
	if ui_initialized:
		return
		
	print("开始设置UI...")
	
	# 获取UI节点引用 - 使用安全访问
	events_list = get_node_or_null("HSplitContainer/LeftPanel/EventsGroup/EventsScroll/EventsList")
	character_input = get_node_or_null("HSplitContainer/RightPanel/RightPanelScroll/RightPanelContent/MovementGroup/CharacterContainer/CharacterInput")
	x_input = get_node_or_null("HSplitContainer/RightPanel/RightPanelScroll/RightPanelContent/MovementGroup/PositionGroup/CoordinateContainer/XInput")
	y_input = get_node_or_null("HSplitContainer/RightPanel/RightPanelScroll/RightPanelContent/MovementGroup/PositionGroup/CoordinateContainer/YInput")
	speed_input = get_node_or_null("HSplitContainer/RightPanel/RightPanelScroll/RightPanelContent/MovementGroup/SpeedContainer/SpeedInput")
	current_pos_label = get_node_or_null("HSplitContainer/RightPanel/RightPanelScroll/RightPanelContent/StatusGroup/CurrentPosLabel")
	event_type_option = get_node_or_null("HSplitContainer/RightPanel/RightPanelScroll/RightPanelContent/EventTypeGroup/EventTypeOption")
	movement_group = get_node_or_null("HSplitContainer/RightPanel/RightPanelScroll/RightPanelContent/MovementGroup")
	
	# 检查关键节点是否存在
	if not event_type_option or not movement_group:
		print("⚠️ 关键UI节点未找到，延迟重试...")
		call_deferred("setup_ui")
		return
	
	# 清空现有选项并重新添加
	if event_type_option:
		event_type_option.clear()
		event_type_option.add_item("移动事件")
		event_type_option.add_item("对话事件")
		event_type_option.add_item("图片事件")
		event_type_option.add_item("清除图片事件")
		
		# 连接事件类型改变信号
		if not event_type_option.item_selected.is_connected(_on_event_type_changed):
			event_type_option.item_selected.connect(_on_event_type_changed)
	
	# 创建对话组
	create_dialogue_group()
	
	# 创建图片组
	create_image_group()
	
	# 创建清除图片组
	create_clear_image_group()
	
	# 默认显示移动事件界面
	_on_event_type_changed(0)
	
	connect_signals()
	ui_initialized = true
	print("主编辑器UI设置完成")

## 创建对话事件UI组
func create_dialogue_group():
	var right_panel = get_node_or_null("HSplitContainer/RightPanel/RightPanelScroll/RightPanelContent")
	if not right_panel:
		print("⚠️ RightPanelContent节点未找到")
		return
	
	# 先移除现有的对话组（如果存在）
	var existing_dialogue_group = right_panel.get_node_or_null("DialogueGroup")
	if existing_dialogue_group:
		existing_dialogue_group.queue_free()
	
	# 创建新的对话组
	dialogue_group = VBoxContainer.new()
	dialogue_group.name = "DialogueGroup"
	dialogue_group.visible = false  # 默认隐藏
	
	var dialogue_label = Label.new()
	dialogue_label.text = "对话设置:"
	dialogue_group.add_child(dialogue_label)
	
	var character_container = HBoxContainer.new()
	character_container.name = "CharacterContainer"  # 设置明确的名字
	var character_label = Label.new()
	character_label.text = "角色:"
	character_container.add_child(character_label)
	
	var dialogue_character_input = LineEdit.new()
	dialogue_character_input.name = "DialogueCharacterInput"  # 设置明确的名字
	dialogue_character_input.text = "player"
	dialogue_character_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	character_container.add_child(dialogue_character_input)
	dialogue_group.add_child(character_container)
	
	var dialogue_text_label = Label.new()
	dialogue_text_label.text = "对话内容:"
	dialogue_group.add_child(dialogue_text_label)
	
	dialogue_text_input = TextEdit.new()
	dialogue_text_input.name = "DialogueTextInput"  # 设置明确的名字
	dialogue_text_input.placeholder_text = "请输入对话内容..."
	dialogue_text_input.custom_minimum_size = Vector2(0, 80)
	dialogue_group.add_child(dialogue_text_input)
	
	# 添加按钮
	var dialogue_button = Button.new()
	dialogue_button.name = "AddDialogueButton"  # 设置明确的名字
	dialogue_button.text = "添加对话事件"
	dialogue_button.pressed.connect(_on_add_dialogue_event)
	dialogue_group.add_child(dialogue_button)
	
	# 将对话组添加到MovementGroup之后
	var movement_index = movement_group.get_index()
	right_panel.add_child(dialogue_group)
	right_panel.move_child(dialogue_group, movement_index + 1)
	
	print("对话组创建完成")

## 创建图片事件UI组
func create_image_group():
	var right_panel = get_node_or_null("HSplitContainer/RightPanel/RightPanelScroll/RightPanelContent")
	if not right_panel:
		print("⚠️ RightPanelContent节点未找到")
		return
	
	# 先移除现有的图片组（如果存在）
	var existing_image_group = right_panel.get_node_or_null("ImageGroup")
	if existing_image_group:
		existing_image_group.queue_free()
	
	# 创建新的图片组
	image_group = VBoxContainer.new()
	image_group.name = "ImageGroup"
	image_group.visible = false  # 默认隐藏
	
	var image_label = Label.new()
	image_label.text = "图片设置:"
	image_group.add_child(image_label)
	
	# 图片路径输入
	var path_label = Label.new()
	path_label.text = "图片路径 (支持拖拽):"
	image_group.add_child(path_label)
	
	# 资源选择器（支持拖拽）- 主要方式
	image_resource_picker = EditorResourcePicker.new()
	image_resource_picker.name = "ImageResourcePicker"
	image_resource_picker.base_type = "Texture2D"
	image_resource_picker.resource_changed.connect(_on_image_resource_changed)
	image_group.add_child(image_resource_picker)
	
	# 传统的文本输入框 - 备用方式
	var manual_input_label = Label.new()
	manual_input_label.text = "或手动输入路径:"
	manual_input_label.add_theme_font_size_override("font_size", 10)
	image_group.add_child(manual_input_label)
	
	image_path_input = LineEdit.new()
	image_path_input.name = "ImagePathInput"
	image_path_input.placeholder_text = "res://assets/images/your_image.png"
	image_path_input.text_changed.connect(_on_image_path_text_changed)
	image_group.add_child(image_path_input)
	
	# 位置设置
	var pos_label = Label.new()
	pos_label.text = "位置:"
	image_group.add_child(pos_label)
	
	var pos_container = HBoxContainer.new()
	var x_label = Label.new()
	x_label.text = "X:"
	pos_container.add_child(x_label)
	
	image_x_input = SpinBox.new()
	image_x_input.name = "ImageXInput"
	image_x_input.min_value = -2000
	image_x_input.max_value = 2000
	image_x_input.value = 400
	pos_container.add_child(image_x_input)
	
	var y_label = Label.new()
	y_label.text = "Y:"
	pos_container.add_child(y_label)
	
	image_y_input = SpinBox.new()
	image_y_input.name = "ImageYInput"
	image_y_input.min_value = -2000
	image_y_input.max_value = 2000
	image_y_input.value = 300
	pos_container.add_child(image_y_input)
	
	image_group.add_child(pos_container)
	
	# 缩放设置
	var scale_label = Label.new()
	scale_label.text = "缩放:"
	image_group.add_child(scale_label)
	
	var scale_container = HBoxContainer.new()
	var scale_x_label = Label.new()
	scale_x_label.text = "X:"
	scale_container.add_child(scale_x_label)
	
	image_scale_x_input = SpinBox.new()
	image_scale_x_input.name = "ImageScaleXInput"
	image_scale_x_input.min_value = 0.1
	image_scale_x_input.max_value = 5.0
	image_scale_x_input.step = 0.1
	image_scale_x_input.value = 1.0
	scale_container.add_child(image_scale_x_input)
	
	var scale_y_label = Label.new()
	scale_y_label.text = "Y:"
	scale_container.add_child(scale_y_label)
	
	image_scale_y_input = SpinBox.new()
	image_scale_y_input.name = "ImageScaleYInput"
	image_scale_y_input.min_value = 0.1
	image_scale_y_input.max_value = 5.0
	image_scale_y_input.step = 0.1
	image_scale_y_input.value = 1.0
	scale_container.add_child(image_scale_y_input)
	
	image_group.add_child(scale_container)
	
	# 持续时间
	var duration_container = HBoxContainer.new()
	var duration_label = Label.new()
	duration_label.text = "持续时间(秒):"
	duration_container.add_child(duration_label)
	
	image_duration_input = SpinBox.new()
	image_duration_input.name = "ImageDurationInput"
	image_duration_input.min_value = 0
	image_duration_input.max_value = 30
	image_duration_input.value = 0  # 0表示不限制
	duration_container.add_child(image_duration_input)
	
	image_group.add_child(duration_container)
	
	# 选项复选框
	image_fade_in_check = CheckBox.new()
	image_fade_in_check.name = "ImageFadeInCheck"
	image_fade_in_check.text = "淡入效果"
	image_fade_in_check.button_pressed = true
	image_group.add_child(image_fade_in_check)
	
	image_wait_check = CheckBox.new()
	image_wait_check.name = "ImageWaitCheck"
	image_wait_check.text = "等待完成"
	image_wait_check.button_pressed = false
	image_group.add_child(image_wait_check)
	
	# 添加按钮
	var image_button = Button.new()
	image_button.name = "AddImageButton"
	image_button.text = "添加图片事件"
	image_button.pressed.connect(_on_add_image_event)
	image_group.add_child(image_button)
	
	# 将图片组添加到对话组之后
	var dialogue_index = dialogue_group.get_index()
	right_panel.add_child(image_group)
	right_panel.move_child(image_group, dialogue_index + 1)
	
	print("图片组创建完成")

## 创建清除图片事件UI组
func create_clear_image_group():
	var right_panel = get_node_or_null("HSplitContainer/RightPanel/RightPanelScroll/RightPanelContent")
	if not right_panel:
		print("⚠️ RightPanelContent节点未找到")
		return
	
	# 先移除现有的清除图片组（如果存在）
	var existing_clear_image_group = right_panel.get_node_or_null("ClearImageGroup")
	if existing_clear_image_group:
		existing_clear_image_group.queue_free()
	
	# 创建新的清除图片组
	clear_image_group = VBoxContainer.new()
	clear_image_group.name = "ClearImageGroup"
	clear_image_group.visible = false  # 默认隐藏
	
	var clear_image_label = Label.new()
	clear_image_label.text = "清除图片设置:"
	clear_image_group.add_child(clear_image_label)
	
	# 图片ID输入
	var id_label = Label.new()
	id_label.text = "图片ID (留空清除所有图片):"
	clear_image_group.add_child(id_label)
	
	clear_image_id_input = LineEdit.new()
	clear_image_id_input.name = "ClearImageIdInput"
	clear_image_id_input.placeholder_text = "例如: Actor1_8_0 (留空则清除所有)"
	clear_image_group.add_child(clear_image_id_input)
	
	# 淡出效果设置
	clear_fade_out_check = CheckBox.new()
	clear_fade_out_check.name = "ClearFadeOutCheck"
	clear_fade_out_check.text = "淡出效果"
	clear_fade_out_check.button_pressed = true
	clear_image_group.add_child(clear_fade_out_check)
	
	# 淡出持续时间
	var fade_duration_container = HBoxContainer.new()
	var fade_duration_label = Label.new()
	fade_duration_label.text = "淡出时长(秒):"
	fade_duration_container.add_child(fade_duration_label)
	
	clear_fade_duration_input = SpinBox.new()
	clear_fade_duration_input.name = "ClearFadeDurationInput"
	clear_fade_duration_input.min_value = 0.1
	clear_fade_duration_input.max_value = 5.0
	clear_fade_duration_input.step = 0.1
	clear_fade_duration_input.value = 0.5
	fade_duration_container.add_child(clear_fade_duration_input)
	
	clear_image_group.add_child(fade_duration_container)
	
	# 等待完成选项
	clear_wait_check = CheckBox.new()
	clear_wait_check.name = "ClearWaitCheck"
	clear_wait_check.text = "等待清除完成"
	clear_wait_check.button_pressed = false
	clear_image_group.add_child(clear_wait_check)
	
	# 添加按钮
	var clear_button = Button.new()
	clear_button.name = "AddClearImageButton"
	clear_button.text = "添加清除图片事件"
	clear_button.pressed.connect(_on_add_clear_image_event)
	clear_image_group.add_child(clear_button)
	
	# 将清除图片组添加到图片组之后
	var image_index = image_group.get_index()
	right_panel.add_child(clear_image_group)
	right_panel.move_child(clear_image_group, image_index + 1)
	
	print("清除图片组创建完成")

## 事件类型改变
func _on_event_type_changed(index: int):
	print("事件类型改变为: ", index)
	
	if not movement_group or not dialogue_group or not image_group or not clear_image_group:
		print("UI组件未准备好")
		return
	
	if index == 0:  # 移动事件
		movement_group.visible = true
		dialogue_group.visible = false
		image_group.visible = false
		clear_image_group.visible = false
		print("显示移动事件界面")
	elif index == 1:  # 对话事件
		movement_group.visible = false
		dialogue_group.visible = true
		image_group.visible = false
		clear_image_group.visible = false
		print("显示对话事件界面")
	elif index == 2:  # 图片事件
		movement_group.visible = false
		dialogue_group.visible = false
		image_group.visible = true
		clear_image_group.visible = false
		print("显示图片事件界面")
	elif index == 3:  # 清除图片事件
		movement_group.visible = false
		dialogue_group.visible = false
		image_group.visible = false
		clear_image_group.visible = true
		print("显示清除图片事件界面")
	else:  # 其他事件
		movement_group.visible = false
		dialogue_group.visible = false
		image_group.visible = false
		clear_image_group.visible = false
		print("隐藏所有事件界面")

## 添加对话事件（专用方法）
func _on_add_dialogue_event():
	# 使用正确的节点路径
	var character_input_node = dialogue_group.get_node("CharacterContainer/DialogueCharacterInput")
	var character = character_input_node.text
	var dialogue_text = dialogue_text_input.text
	
	if dialogue_text.strip_edges().is_empty():
		print("对话内容不能为空")
		return
		
	var event_data = {
		"type": "dialogue",
		"character": character,
		"text": dialogue_text
	}
	
	events.append(event_data)
	update_events_list()
	print("添加对话事件: %s 说: %s" % [character, dialogue_text])
	
	# 清空输入框
	dialogue_text_input.text = ""

## 添加图片事件（专用方法）
func _on_add_image_event():
	# 优先从资源选择器获取路径
	var image_path = ""
	if image_resource_picker.edited_resource:
		image_path = image_resource_picker.edited_resource.resource_path
	else:
		image_path = image_path_input.text
	
	var position = Vector2(image_x_input.value, image_y_input.value)
	var scale = Vector2(image_scale_x_input.value, image_scale_y_input.value)
	var duration = image_duration_input.value
	var fade_in = image_fade_in_check.button_pressed
	var wait_for_completion = image_wait_check.button_pressed
	
	if image_path.strip_edges().is_empty():
		print("请选择图片或输入图片路径")
		return
		
	var event_data = {
		"type": "image",
		"image_path": image_path,
		"position": position,
		"scale": scale,
		"duration": duration,
		"fade_in": fade_in,
		"wait_for_completion": wait_for_completion
	}
	
	events.append(event_data)
	update_events_list()
	print("添加图片事件: %s 位置: %s" % [image_path, position])
	
	# 清空输入框
	image_path_input.text = ""
	image_resource_picker.edited_resource = null

## 添加清除图片事件（专用方法）
func _on_add_clear_image_event():
	var image_id = clear_image_id_input.text.strip_edges()
	var fade_out = clear_fade_out_check.button_pressed
	var fade_duration = clear_fade_duration_input.value
	var wait_for_completion = clear_wait_check.button_pressed
	
	var event_data = {
		"type": "clear_image",
		"image_id": image_id,
		"fade_out": fade_out,
		"fade_duration": fade_duration,
		"wait_for_completion": wait_for_completion
	}
	
	events.append(event_data)
	update_events_list()
	
	if image_id.is_empty():
		print("添加清除图片事件: 清除所有图片")
	else:
		print("添加清除图片事件: 清除图片 %s" % image_id)
	
	# 清空输入框
	clear_image_id_input.text = ""

## 图片资源改变回调
func _on_image_resource_changed(resource: Resource):
	if resource and resource is Texture2D:
		var texture = resource as Texture2D
		var resource_path = texture.resource_path
		image_path_input.text = resource_path
		print("通过拖拽选择图片: ", resource_path)
	elif not resource:
		# 如果清空了资源选择器，也清空文本输入框
		image_path_input.text = ""

## 图片路径文本改变回调
func _on_image_path_text_changed(new_text: String):
	# 当用户在文本框中输入路径时，尝试加载对应的资源
	if new_text.strip_edges().is_empty():
		image_resource_picker.edited_resource = null
		return
		
	if FileAccess.file_exists(new_text) and new_text.ends_with(".png") or new_text.ends_with(".jpg") or new_text.ends_with(".jpeg") or new_text.ends_with(".bmp") or new_text.ends_with(".tga") or new_text.ends_with(".webp"):
		var texture = load(new_text) as Texture2D
		if texture:
			image_resource_picker.edited_resource = texture
			print("通过文本输入加载图片: ", new_text)

## 连接信号
func connect_signals():
	# 左侧按钮
	var clear_btn = get_node_or_null("HSplitContainer/LeftPanel/ButtonsContainer/ClearEvents")
	var execute_btn = get_node_or_null("HSplitContainer/LeftPanel/ButtonsContainer/ExecuteEvents")
	
	if clear_btn and not clear_btn.pressed.is_connected(_on_clear_events):
		clear_btn.pressed.connect(_on_clear_events)
	if execute_btn and not execute_btn.pressed.is_connected(_on_execute_events):
		execute_btn.pressed.connect(_on_execute_events)
	
	# 预设位置按钮
	var preset_grid = get_node_or_null("HSplitContainer/RightPanel/RightPanelScroll/RightPanelContent/MovementGroup/PositionGroup/PresetGrid")
	if not preset_grid:
		print("⚠️ PresetGrid节点未找到")
		return
	for button_name in preset_positions:
		var button = preset_grid.get_node_or_null(button_name)
		if button and not button.pressed.is_connected(_on_preset_selected):
			if button_name == "RefreshPos":
				button.pressed.connect(_on_refresh_position)
			elif button_name == "AddEvent":
				button.pressed.connect(_on_add_movement_event)
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

## 添加移动事件（专用方法）
func _on_add_movement_event():
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

## 添加事件（旧方法，保持兼容）
func _on_add_event():
	_on_add_movement_event()

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
	
	print("准备保存事件，当前事件数量: ", events.size())
	for i in range(events.size()):
		var event = events[i]
		var character_info = ""
		if event.has("character"):
			character_info = " - " + event.character
		
		print("  事件[%d]: 类型=%s%s" % [i, event.type, character_info])
		if event.type == "dialogue":
			print("    对话内容: %s" % event.text)
		elif event.type == "movement":
			print("    目标位置: %s" % event.destination)
		elif event.type == "image":
			print("    图片路径: %s" % event.image_path)
			print("    显示位置: %s" % event.position)
	
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
		
		if event.type == "movement":
			var dest = event.destination
			label.text = "[%d] %s 移动到 (%.0f, %.0f)" % [i, event.character, dest.x, dest.y]
		elif event.type == "dialogue":
			var preview_text = event.text
			if preview_text.length() > 30:
				preview_text = preview_text.substr(0, 30) + "..."
			label.text = "[%d] %s: %s" % [i, event.character, preview_text]
		elif event.type == "image":
			var filename = event.image_path.get_file()
			label.text = "[%d] 显示图片: %s (%.0f, %.0f)" % [i, filename, event.position.x, event.position.y]
		elif event.type == "clear_image":
			if event.image_id.is_empty():
				label.text = "[%d] 清除所有图片" % i
			else:
				label.text = "[%d] 清除图片: %s" % [i, event.image_id]
		else:
			label.text = "[%d] %s 事件" % [i, event.type]
			
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

## 保存事件到文件
func save_events_to_file():
	var file_path = "res://data/current_events.json"
	
	print("开始保存事件到文件，原始事件数量: ", events.size())
	
	# 转换Vector2为可序列化的格式
	var serializable_events = []
	for event in events:
		var serializable_event = event.duplicate()
		var character_info = ""
		if event.has("character"):
			character_info = " - " + event.character
		print("处理事件: ", event.type, character_info)
		
		if serializable_event.has("destination") and serializable_event.destination is Vector2:
			var vec = serializable_event.destination as Vector2
			serializable_event.destination = {"x": vec.x, "y": vec.y}
			print("  转换移动事件的Vector2位置")
		
		if serializable_event.has("position") and serializable_event.position is Vector2:
			var vec = serializable_event.position as Vector2
			serializable_event.position = {"x": vec.x, "y": vec.y}
			print("  转换图片事件的Vector2位置")
			
		if serializable_event.has("scale") and serializable_event.scale is Vector2:
			var vec = serializable_event.scale as Vector2
			serializable_event.scale = {"x": vec.x, "y": vec.y}
			print("  转换图片事件的Vector2缩放")
		
		serializable_events.append(serializable_event)
	
	print("序列化后事件数量: ", serializable_events.size())
	
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(serializable_events)
		print("JSON内容: ", json_string)
		file.store_string(json_string)
		file.close()
		print("事件保存到: ", file_path)
	else:
		print("无法保存事件文件: ", file_path) 
