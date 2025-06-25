extends RefCounted

## 动态UI生成器
## 根据事件类型配置自动生成UI界面，消除重复代码

## 为事件类型创建UI组
func create_event_ui_group(type_id: String, parent: Control, editor_main) -> VBoxContainer:
	var EventTypeRegistryScript = preload("res://addons/narrative_editor/core/EventTypeRegistry.gd")
	var config = EventTypeRegistryScript.get_event_type(type_id)
	if config.is_empty():
		print("未找到事件类型配置: ", type_id)
		return null
	
	var group = VBoxContainer.new()
	group.name = type_id.capitalize() + "Group"
	group.visible = false
	
	# 添加标题
	var title_label = Label.new()
	title_label.text = config.display_name + "设置:"
	group.add_child(title_label)
	
	# 存储UI控件引用
	var ui_controls = {}
	
	# 根据配置创建UI字段
	for field_config in config.ui_fields:
		var field_container = create_field_ui(field_config, editor_main)
		if field_container:
			group.add_child(field_container)
			# 存储控件引用以便后续访问
			ui_controls[field_config.name] = get_control_from_container(field_container, field_config.type)
	
	# 添加按钮
	var button = Button.new()
	button.name = "Add" + type_id.capitalize() + "Button"
	button.text = config.button_text.add
	button.pressed.connect(func(): editor_main._on_add_event_generic(type_id, ui_controls))
	group.add_child(button)
	
	# 存储UI控件引用到编辑器主类
	editor_main.event_ui_controls[type_id] = {
		"group": group,
		"controls": ui_controls,
		"button": button
	}
	
	parent.add_child(group)
	print("创建事件UI组: ", type_id)
	return group

## 创建单个字段的UI
func create_field_ui(field_config: Dictionary, editor_main) -> Control:
	var container = null
	
	match field_config.type:
		"line_edit":
			container = create_line_edit_field(field_config)
		"text_edit":
			container = create_text_edit_field(field_config)
		"spin_box":
			container = create_spin_box_field(field_config)
		"vector2":
			container = create_vector2_field(field_config, editor_main)
		"check_box":
			container = create_check_box_field(field_config)
		"resource_picker":
			container = create_resource_picker_field(field_config, editor_main)
		_:
			print("未知字段类型: ", field_config.type)
	
	return container

## 创建文本输入字段
func create_line_edit_field(field_config: Dictionary) -> HBoxContainer:
	var container = HBoxContainer.new()
	
	var label = Label.new()
	label.text = field_config.label
	container.add_child(label)
	
	var line_edit = LineEdit.new()
	line_edit.name = field_config.name.capitalize() + "Input"
	if "default" in field_config:
		line_edit.text = str(field_config.default)
	if "placeholder" in field_config:
		line_edit.placeholder_text = field_config.placeholder
	line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.add_child(line_edit)
	
	return container

## 创建多行文本字段
func create_text_edit_field(field_config: Dictionary) -> VBoxContainer:
	var container = VBoxContainer.new()
	
	var label = Label.new()
	label.text = field_config.label
	container.add_child(label)
	
	var text_edit = TextEdit.new()
	text_edit.name = field_config.name.capitalize() + "Input"
	if "placeholder" in field_config:
		text_edit.placeholder_text = field_config.placeholder
	if "min_size" in field_config:
		text_edit.custom_minimum_size = field_config.min_size
	container.add_child(text_edit)
	
	return container

## 创建数值输入字段
func create_spin_box_field(field_config: Dictionary) -> HBoxContainer:
	var container = HBoxContainer.new()
	
	var label = Label.new()
	label.text = field_config.label
	container.add_child(label)
	
	var spin_box = SpinBox.new()
	spin_box.name = field_config.name.capitalize() + "Input"
	if "default" in field_config:
		spin_box.value = field_config.default
	if "min_value" in field_config:
		spin_box.min_value = field_config.min_value
	if "max_value" in field_config:
		spin_box.max_value = field_config.max_value
	if "step" in field_config:
		spin_box.step = field_config.step
	if "tooltip" in field_config:
		spin_box.tooltip_text = field_config.tooltip
	container.add_child(spin_box)
	
	return container

## 创建Vector2字段
func create_vector2_field(field_config: Dictionary, editor_main) -> VBoxContainer:
	var container = VBoxContainer.new()
	
	var label = Label.new()
	label.text = field_config.label
	container.add_child(label)
	
	var coord_container = HBoxContainer.new()
	
	# X轴
	var x_label = Label.new()
	x_label.text = "X:"
	coord_container.add_child(x_label)
	
	var x_input = SpinBox.new()
	x_input.name = field_config.name.capitalize() + "XInput"
	if "default" in field_config:
		x_input.value = field_config.default.x
	if "min_value" in field_config:
		x_input.min_value = field_config.min_value
	if "max_value" in field_config:
		x_input.max_value = field_config.max_value
	if "step" in field_config:
		x_input.step = field_config.step
	coord_container.add_child(x_input)
	
	# Y轴
	var y_label = Label.new()
	y_label.text = "Y:"
	coord_container.add_child(y_label)
	
	var y_input = SpinBox.new()
	y_input.name = field_config.name.capitalize() + "YInput"
	if "default" in field_config:
		y_input.value = field_config.default.y
	if "min_value" in field_config:
		y_input.min_value = field_config.min_value
	if "max_value" in field_config:
		y_input.max_value = field_config.max_value
	if "step" in field_config:
		y_input.step = field_config.step
	coord_container.add_child(y_input)
	
	container.add_child(coord_container)
	
	# 如果是位置字段且有自定义UI，添加预设位置网格
	if field_config.name == "destination" and "custom_ui" in field_config and field_config.custom_ui == "preset_position_grid":
		add_preset_position_grid(container, x_input, y_input, editor_main)
	
	return container

## 创建复选框字段
func create_check_box_field(field_config: Dictionary) -> CheckBox:
	var check_box = CheckBox.new()
	check_box.name = field_config.name.capitalize() + "Check"
	check_box.text = field_config.label
	if "default" in field_config:
		check_box.button_pressed = field_config.default
	return check_box

## 创建资源选择器字段
func create_resource_picker_field(field_config: Dictionary, editor_main) -> VBoxContainer:
	var container = VBoxContainer.new()
	
	var label = Label.new()
	label.text = field_config.label
	container.add_child(label)
	
	var resource_picker = EditorResourcePicker.new()
	resource_picker.name = field_config.name.capitalize() + "Picker"
	if "resource_type" in field_config:
		resource_picker.base_type = field_config.resource_type
	container.add_child(resource_picker)
	
	# 添加手动输入框作为备选
	var manual_label = Label.new()
	manual_label.text = "或手动输入路径:"
	manual_label.add_theme_font_size_override("font_size", 10)
	container.add_child(manual_label)
	
	var path_input = LineEdit.new()
	path_input.name = field_config.name.capitalize() + "Input"
	if "placeholder" in field_config:
		path_input.placeholder_text = field_config.placeholder
	container.add_child(path_input)
	
	# 连接资源选择器和文本输入的同步
	resource_picker.resource_changed.connect(func(resource): 
		if resource:
			path_input.text = resource.resource_path
		else:
			path_input.text = ""
	)
	
	path_input.text_changed.connect(func(new_text):
		if new_text.strip_edges().is_empty():
			resource_picker.edited_resource = null
		elif FileAccess.file_exists(new_text):
			var texture = load(new_text) as Texture2D
			if texture:
				resource_picker.edited_resource = texture
	)
	
	return container

## 添加预设位置网格（仅用于移动事件）
func add_preset_position_grid(container: VBoxContainer, x_input: SpinBox, y_input: SpinBox, editor_main):
	var grid_label = Label.new()
	grid_label.text = "预设位置:"
	container.add_child(grid_label)
	
	# 创建预设位置网格
	var grid = GridContainer.new()
	grid.columns = 4
	
	# 预设位置映射
	var preset_positions = {
		"左上": Vector2(100, 100),
		"上中": Vector2(500, 100), 
		"右上": Vector2(900, 100),
		"当前": Vector2(909, 222),
		"左中": Vector2(100, 300),
		"中心": Vector2(500, 300),
		"右中": Vector2(900, 300),
		"刷新": Vector2.ZERO,  # 特殊按钮
		"左下": Vector2(100, 500),
		"下中": Vector2(500, 500),
		"右下": Vector2(900, 500),
		"添加事件": Vector2.ZERO  # 特殊按钮
	}
	
	for button_text in preset_positions:
		var btn = Button.new()
		btn.text = button_text
		
		if button_text == "刷新":
			btn.pressed.connect(func(): _refresh_position(editor_main))
		elif button_text == "添加事件":
			# 这个按钮会在后面被移动事件的主按钮替代
			btn.pressed.connect(func(): editor_main._on_add_event_generic("movement", editor_main.event_ui_controls["movement"].controls))
		elif button_text == "当前":
			btn.pressed.connect(func(): _use_current_position(x_input, y_input, editor_main))
		else:
			var pos = preset_positions[button_text]
			btn.pressed.connect(func(): _set_position(x_input, y_input, pos))
		
		grid.add_child(btn)
	
	container.add_child(grid)

## 设置预设位置
func _set_position(x_input: SpinBox, y_input: SpinBox, position: Vector2):
	x_input.value = position.x
	y_input.value = position.y
	print("选择预设位置: ", position)

## 使用当前位置
func _use_current_position(x_input: SpinBox, y_input: SpinBox, editor_main):
	_refresh_position(editor_main)
	# 这里需要从场景中获取Player位置，暂时使用默认值
	x_input.value = 909
	y_input.value = 222
	print("使用当前位置")

## 刷新角色位置
func _refresh_position(editor_main):
	var main_scene = EditorInterface.get_edited_scene_root()
	if not main_scene:
		print("请先打开main.tscn场景")
		return
	
	var player_node = main_scene.find_child("Player")
	if player_node:
		var pos = player_node.position
		print("刷新角色位置: ", pos)
	else:
		print("找不到Player节点")

## 从容器中获取控件
func get_control_from_container(container: Control, field_type: String):
	match field_type:
		"line_edit":
			return container.get_children().back()
		"text_edit":
			return container.get_children().back()
		"spin_box":
			return container.get_children().back()
		"vector2":
			var coord_container = container.get_children()[1]
			return {
				"x": coord_container.get_children()[1],
				"y": coord_container.get_children()[3]
			}
		"check_box":
			return container
		"resource_picker":
			return {
				"picker": container.get_children()[1],
				"input": container.get_children()[3]
			}
		_:
			return container

## 从UI控件获取值
func get_field_value(control, field_type: String, field_name: String):
	match field_type:
		"line_edit":
			return control.text
		"text_edit":
			return control.text
		"spin_box":
			return control.value
		"vector2":
			return Vector2(control.x.value, control.y.value)
		"check_box":
			return control.button_pressed
		"resource_picker":
			var path = ""
			if control.picker.edited_resource:
				path = control.picker.edited_resource.resource_path
			else:
				path = control.input.text
			return path
		_:
			return null

## 设置UI控件的值
func set_field_value(control, field_type: String, value):
	match field_type:
		"line_edit":
			control.text = str(value)
		"text_edit":
			control.text = str(value)
		"spin_box":
			control.value = value
		"vector2":
			control.x.value = value.x
			control.y.value = value.y
		"check_box":
			control.button_pressed = value
		"resource_picker":
			control.input.text = str(value)
			if FileAccess.file_exists(str(value)):
				var texture = load(str(value)) as Texture2D
				if texture:
					control.picker.edited_resource = texture
		_:
			pass 