@tool
extends Control

## 重构后的叙事编辑器主界面 - 使用事件注册系统
## 大大简化了代码，添加新事件类型只需在EventTypeRegistry中配置

# 预加载必需的类
const EventTypeRegistryScript = preload("res://addons/narrative_editor/core/EventTypeRegistry.gd")
const EventUIBuilderScript = preload("res://addons/narrative_editor/core/EventUIBuilder.gd")

var events: Array = []
var ui_initialized: bool = false

# 核心UI节点
var events_list: VBoxContainer
var event_type_option: OptionButton
var right_panel: Control

# 动态生成的UI控件存储
var event_ui_controls: Dictionary = {}

# UI构建器实例
var ui_builder

# 编辑模式相关
var editing_mode: bool = false
var editing_event_index: int = -1

func _ready():
	print("🎭 重构版叙事编辑器已准备就绪")
	# 初始化事件类型注册表
	EventTypeRegistryScript.initialize_default_types()
	
	# 创建UI构建器实例
	ui_builder = EventUIBuilderScript.new()
	
	if not ui_initialized:
		call_deferred("setup_ui")

## 设置UI
func setup_ui():
	if ui_initialized:
		return
	
	print("开始设置重构版UI...")
	
	# 获取基础UI节点
	events_list = get_node_or_null("HSplitContainer/LeftPanel/EventsGroup/EventsScroll/EventsList")
	event_type_option = get_node_or_null("HSplitContainer/RightPanel/RightPanelScroll/RightPanelContent/EventTypeGroup/EventTypeOption")
	right_panel = get_node_or_null("HSplitContainer/RightPanel/RightPanelScroll/RightPanelContent")
	
	if not event_type_option or not right_panel:
		print("⚠️ 关键UI节点未找到，延迟重试...")
		call_deferred("setup_ui")
		return
	
	# 动态创建事件类型选项
	setup_event_type_options()
	
	# 动态创建所有事件类型的UI
	create_all_event_uis()
	
	# 创建编辑状态面板
	create_edit_status_panel()
	
	# 连接信号
	connect_signals()
	
	# 默认显示第一个事件类型
	if event_type_option.get_item_count() > 0:
		_on_event_type_changed(0)
	
	ui_initialized = true
	print("重构版UI设置完成")

## 设置事件类型选项
func setup_event_type_options():
	event_type_option.clear()
	
	var event_types = EventTypeRegistryScript.get_all_event_types()
	for type_id in event_types:
		var config = event_types[type_id]
		event_type_option.add_item(config.display_name)
	
	# 连接事件类型改变信号
	if not event_type_option.item_selected.is_connected(_on_event_type_changed):
		event_type_option.item_selected.connect(_on_event_type_changed)

## 动态创建所有事件类型的UI
func create_all_event_uis():
	var event_types = EventTypeRegistryScript.get_all_event_types()
	var type_ids = event_types.keys()
	
	for i in range(type_ids.size()):
		var type_id = type_ids[i]
		var group = ui_builder.create_event_ui_group(type_id, right_panel, self)
		
		# 设置UI组的位置（在已有组件之后）
		if i > 0:
			var prev_group = event_ui_controls[type_ids[i-1]].group
			var prev_index = prev_group.get_index()
			right_panel.move_child(group, prev_index + 1)

## 创建编辑状态面板
func create_edit_status_panel():
	var edit_status_group = VBoxContainer.new()
	edit_status_group.name = "EditStatusGroup"
	edit_status_group.visible = false
	
	# 编辑状态标签
	var status_label = Label.new()
	status_label.name = "EditStatusLabel"
	status_label.text = "正在编辑事件 [0]"
	status_label.add_theme_color_override("font_color", Color.ORANGE)
	edit_status_group.add_child(status_label)
	
	# 取消编辑按钮
	var cancel_btn = Button.new()
	cancel_btn.name = "CancelEditButton"
	cancel_btn.text = "取消编辑"
	cancel_btn.pressed.connect(_on_cancel_edit)
	edit_status_group.add_child(cancel_btn)
	
	# 添加分隔线
	var separator = HSeparator.new()
	edit_status_group.add_child(separator)
	
	# 将编辑状态组添加到事件类型组之前
	var event_type_group = right_panel.get_node("EventTypeGroup")
	var event_type_index = event_type_group.get_index()
	right_panel.add_child(edit_status_group)
	right_panel.move_child(edit_status_group, event_type_index)

## 连接信号
func connect_signals():
	# 左侧按钮
	var load_btn = get_node_or_null("HSplitContainer/LeftPanel/ButtonsContainer/LoadEvents")
	var clear_btn = get_node_or_null("HSplitContainer/LeftPanel/ButtonsContainer/ClearEvents")
	var execute_btn = get_node_or_null("HSplitContainer/LeftPanel/ButtonsContainer/ExecuteEvents")
	
	if load_btn and not load_btn.pressed.is_connected(_on_load_events):
		load_btn.pressed.connect(_on_load_events)
	if clear_btn and not clear_btn.pressed.is_connected(_on_clear_events):
		clear_btn.pressed.connect(_on_clear_events)
	if execute_btn and not execute_btn.pressed.is_connected(_on_execute_events):
		execute_btn.pressed.connect(_on_execute_events)

## 事件类型改变
func _on_event_type_changed(index: int):
	print("事件类型改变为: ", index)
	
	var type_ids = EventTypeRegistryScript.get_all_event_types().keys()
	
	# 隐藏所有事件UI组
	for type_id in type_ids:
		if type_id in event_ui_controls:
			event_ui_controls[type_id].group.visible = false
	
	# 显示选中的事件UI组
	if index >= 0 and index < type_ids.size():
		var selected_type_id = type_ids[index]
		if selected_type_id in event_ui_controls:
			event_ui_controls[selected_type_id].group.visible = true
			print("显示事件界面: ", selected_type_id)

## 通用添加事件方法
func _on_add_event_generic(type_id: String, ui_controls: Dictionary):
	var config = EventTypeRegistryScript.get_event_type(type_id)
	var event_data = {"type": type_id}
	
	# 从UI控件收集数据
	for field_config in config.ui_fields:
		var field_name = field_config.name
		var field_type = field_config.type
		var control = ui_controls[field_name]
		
		var value = ui_builder.get_field_value(control, field_type, field_name)
		
		# 验证必需字段
		if _is_field_required(field_config) and _is_field_empty(value, field_type):
			print("字段 '%s' 不能为空" % field_config.label)
			return
		
		event_data[field_name] = value
	
	# 添加或更新事件
	if editing_mode:
		events[editing_event_index] = event_data
		print("更新%s [%d]" % [config.display_name, editing_event_index])
		exit_editing_mode()
	else:
		events.append(event_data)
		print("添加%s" % config.display_name)
		# 清空输入框（仅在添加模式下）
		_clear_ui_inputs(type_id, ui_controls)
	
	update_events_list()

## 检查字段是否为必需
func _is_field_required(field_config: Dictionary) -> bool:
	return field_config.get("required", false) or field_config.name in ["text", "image_path"]

## 检查字段是否为空
func _is_field_empty(value, field_type: String) -> bool:
	match field_type:
		"line_edit", "text_edit", "resource_picker":
			return str(value).strip_edges().is_empty()
		_:
			return false

## 清空UI输入框
func _clear_ui_inputs(type_id: String, ui_controls: Dictionary):
	var config = EventTypeRegistryScript.get_event_type(type_id)
	
	for field_config in config.ui_fields:
		var field_name = field_config.name
		var field_type = field_config.type
		var control = ui_controls[field_name]
		
		# 只清空文本输入类型的字段
		match field_type:
			"line_edit":
				if field_name != "character":  # 保留角色名
					control.text = ""
			"text_edit":
				control.text = ""
			"resource_picker":
				control.input.text = ""
				control.picker.edited_resource = null

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
		label.text = _get_event_display_text(event, i)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		container.add_child(label)
		
		# 上移按钮
		var move_up_btn = Button.new()
		move_up_btn.text = "↑"
		move_up_btn.tooltip_text = "向上移动"
		move_up_btn.disabled = (i == 0)  # 第一个事件不能上移
		move_up_btn.pressed.connect(_on_move_event_up.bind(i))
		container.add_child(move_up_btn)
		
		# 下移按钮
		var move_down_btn = Button.new()
		move_down_btn.text = "↓"
		move_down_btn.tooltip_text = "向下移动"
		move_down_btn.disabled = (i == events.size() - 1)  # 最后一个事件不能下移
		move_down_btn.pressed.connect(_on_move_event_down.bind(i))
		container.add_child(move_down_btn)
		
		# 编辑按钮
		var edit_btn = Button.new()
		edit_btn.text = "编辑"
		edit_btn.pressed.connect(_on_edit_event.bind(i))
		container.add_child(edit_btn)
		
		# 删除按钮
		var delete_btn = Button.new()
		delete_btn.text = "删除"
		delete_btn.pressed.connect(_on_delete_event.bind(i))
		container.add_child(delete_btn)
		
		events_list.add_child(container)

## 获取事件显示文本
func _get_event_display_text(event: Dictionary, index: int) -> String:
	var type_id = event.type
	var config = EventTypeRegistryScript.get_event_type(type_id)
	
	match type_id:
		"movement":
			var dest = event.destination
			return "[%d] %s 移动到 (%.0f, %.0f)" % [index, event.character, dest.x, dest.y]
		"dialogue":
			var preview_text = event.text
			if preview_text.length() > 30:
				preview_text = preview_text.substr(0, 30) + "..."
			return "[%d] %s: %s" % [index, event.character, preview_text]
		"image":
			var filename = event.image_path.get_file()
			return "[%d] 显示图片: %s (%.0f, %.0f)" % [index, filename, event.position.x, event.position.y]
		"clear_image":
			if event.image_id.is_empty():
				return "[%d] 清除所有图片" % index
			else:
				return "[%d] 清除图片: %s" % [index, event.image_id]
		"sound":
			var filename = event.sound_path.get_file()
			if filename.is_empty():
				filename = "未选择文件"
			return "[%d] 播放音效: %s (音量: %.1f)" % [index, filename, event.get("volume", 1.0)]
		_:
			return "[%d] %s" % [index, config.get("display_name", type_id)]

## 编辑事件
func _on_edit_event(index: int):
	if index < 0 or index >= events.size():
		print("无效的事件索引: ", index)
		return
	
	var event = events[index]
	var type_id = event.type
	
	editing_mode = true
	editing_event_index = index
	
	print("开始编辑事件 [%d]: %s" % [index, type_id])
	
	# 切换到对应的事件类型
	var type_ids = EventTypeRegistryScript.get_all_event_types().keys()
	var type_index = type_ids.find(type_id)
	if type_index >= 0:
		event_type_option.selected = type_index
		_on_event_type_changed(type_index)
		
		# 填充事件数据到UI
		_populate_event_data(type_id, event)
		
		# 更新按钮状态
		update_button_modes()

## 填充事件数据到UI
func _populate_event_data(type_id: String, event: Dictionary):
	var config = EventTypeRegistryScript.get_event_type(type_id)
	var ui_controls = event_ui_controls[type_id].controls
	
	for field_config in config.ui_fields:
		var field_name = field_config.name
		var field_type = field_config.type
		
		if field_name in event:
			var control = ui_controls[field_name]
			var value = event[field_name]
			
			# 处理Vector2数据的特殊情况
			if field_type == "vector2" and value is Dictionary:
				value = Vector2(value.x, value.y)
			
			ui_builder.set_field_value(control, field_type, value)

## 更新按钮模式
func update_button_modes():
	var event_types = EventTypeRegistryScript.get_all_event_types()
	
	for type_id in event_types:
		if type_id in event_ui_controls:
			var config = event_types[type_id]
			var button = event_ui_controls[type_id].button
			
			if editing_mode:
				button.text = config.button_text.update
			else:
				button.text = config.button_text.add
	
	# 更新编辑状态面板
	update_edit_status_panel()

## 更新编辑状态面板
func update_edit_status_panel():
	var edit_status_group = right_panel.get_node_or_null("EditStatusGroup")
	if not edit_status_group:
		return
	
	if editing_mode:
		edit_status_group.visible = true
		var status_label = edit_status_group.get_node("EditStatusLabel")
		if status_label:
			var event = events[editing_event_index]
			var config = EventTypeRegistryScript.get_event_type(event.type)
			status_label.text = "正在编辑事件 [%d]: %s" % [editing_event_index, config.display_name]
	else:
		edit_status_group.visible = false

## 取消编辑
func _on_cancel_edit():
	exit_editing_mode()

## 退出编辑模式
func exit_editing_mode():
	editing_mode = false
	editing_event_index = -1
	update_button_modes()
	print("退出编辑模式")

## 上移事件
func _on_move_event_up(index: int):
	if index <= 0 or index >= events.size():
		return
	
	# 交换事件位置
	var temp = events[index]
	events[index] = events[index - 1]
	events[index - 1] = temp
	
	# 更新编辑模式的索引
	if editing_mode:
		if editing_event_index == index:
			editing_event_index = index - 1
		elif editing_event_index == index - 1:
			editing_event_index = index
	
	update_events_list()
	print("事件 [%d] 上移到 [%d]" % [index, index - 1])

## 下移事件
func _on_move_event_down(index: int):
	if index < 0 or index >= events.size() - 1:
		return
	
	# 交换事件位置
	var temp = events[index]
	events[index] = events[index + 1]
	events[index + 1] = temp
	
	# 更新编辑模式的索引
	if editing_mode:
		if editing_event_index == index:
			editing_event_index = index + 1
		elif editing_event_index == index + 1:
			editing_event_index = index
	
	update_events_list()
	print("事件 [%d] 下移到 [%d]" % [index, index + 1])

## 删除事件
func _on_delete_event(index: int):
	if index >= 0 and index < events.size():
		events.remove_at(index)
		update_events_list()
		print("删除事件 [%d]" % index)
		# 如果删除的是正在编辑的事件，退出编辑模式
		if editing_mode and editing_event_index == index:
			exit_editing_mode()
		# 如果删除的事件在当前编辑事件之前，需要调整编辑索引
		elif editing_mode and editing_event_index > index:
			editing_event_index -= 1

## 载入事件（复用原有逻辑）
func _on_load_events():
	var file_path = "res://data/current_events.json"
	
	if not FileAccess.file_exists(file_path):
		print("❌ 事件文件不存在: ", file_path)
		return
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		print("无法打开事件文件: ", file_path)
		return
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		print("JSON解析失败")
		return
	
	# 解析事件数据（复用原有逻辑）
	events.clear()
	var event_data_list = json.data
	
	for event_dict in event_data_list:
		var event_data = {}
		event_data.type = event_dict.type
		
		# 根据事件类型解析数据
		var config = EventTypeRegistryScript.get_event_type(event_dict.type)
		for field_config in config.ui_fields:
			var field_name = field_config.name
			if field_name in event_dict:
				var value = event_dict[field_name]
				# 处理Vector2类型
				if field_config.type == "vector2" and value is Dictionary:
					value = Vector2(value.x, value.y)
				event_data[field_name] = value
		
		events.append(event_data)
	
	update_events_list()
	print("成功载入 ", events.size(), " 个事件")

## 清空事件
func _on_clear_events():
	events.clear()
	update_events_list()
	print("清空所有事件")

## 保存事件（复用原有逻辑）
func _on_execute_events():
	if events.is_empty():
		print("没有事件可保存")
		return
	
	save_events_to_file()
	print("事件已保存，运行游戏后按空格键开始执行")

## 保存事件到文件
func save_events_to_file():
	var file_path = "res://data/current_events.json"
	
	# 转换Vector2为可序列化的格式
	var serializable_events = []
	for event in events:
		var serializable_event = event.duplicate()
		
		# 处理Vector2类型字段
		var config = EventTypeRegistryScript.get_event_type(event.type)
		for field_config in config.ui_fields:
			var field_name = field_config.name
			if field_config.type == "vector2" and field_name in serializable_event:
				var vec = serializable_event[field_name] as Vector2
				serializable_event[field_name] = {"x": vec.x, "y": vec.y}
		
		serializable_events.append(serializable_event)
	
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(serializable_events)
		file.store_string(json_string)
		file.close()
		print("事件保存到: ", file_path)
	else:
		print("无法保存事件文件: ", file_path) 
