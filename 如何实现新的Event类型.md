# 如何实现新的Event类型

> **最后更新：2024年12月** - 添加了ClearImageEvent示例、载入功能、图片事件阻塞逻辑修复等重要更新

本文档详细说明了在叙事引擎中实现新事件类型的完整步骤。以DialogueEvent和ClearImageEvent的实现为例。

## 📅 更新日志

- **2024.12** - 🎉 **重大更新：实现事件编辑功能** - 支持直接编辑现有事件，告别删除重建
- **2024.12** - 新增ClearImageEvent完整实现示例
- **2024.12** - 添加编辑器载入事件功能
- **2024.12** - 修复图片事件阻塞逻辑和duration=0问题
- **2024.12** - 更新编辑器UI，重命名"执行事件"为"保存事件"

## 📋 实现步骤总览

1. [创建Event类](#1-创建event类)
2. [更新EventExecutor](#2-更新eventexecutor)
3. [更新NarrativeEngine](#3-更新narrativeengine)
4. [更新编辑器UI](#4-更新编辑器ui)
5. [测试验证](#5-测试验证)

---

## 1. 创建Event类

### 1.1 文件位置
在 `addons/narrative_editor/core/events/` 目录下创建新的Event类文件。

### 1.2 基础结构
```gdscript
class_name YourEvent
extends EventData

## 你的事件类型说明
## 描述事件的功能和用途

@export var your_parameter: String = ""  # 事件参数
@export var wait_for_completion: bool = true  # 是否等待完成

func _init(p_id: String = "", param: String = ""):
	super._init(p_id, "your_event_type")
	your_parameter = param

## 执行事件的核心逻辑
func execute(executor) -> bool:
	print("执行你的事件: ", your_parameter)
	
	# 调用executor的相应方法
	executor.your_method(your_parameter)
	
	return true

## 是否需要等待事件完成
func is_blocking() -> bool:
	return wait_for_completion

## 获取事件描述（用于编辑器显示）
func get_description() -> String:
	return "你的事件: " + your_parameter
```

### 1.3 DialogueEvent示例
```gdscript
class_name DialogueEvent
extends EventData

@export var target_character: String = ""
@export var dialogue_text: String = ""
@export var wait_for_user_input: bool = true

func _init(p_id: String = "", character_id: String = "", text: String = ""):
	super._init(p_id, "dialogue")
	target_character = character_id
	dialogue_text = text

func execute(executor) -> bool:
	print("执行对话事件: 角色 ", target_character, " 说: ", dialogue_text)
	executor.show_dialogue(target_character, dialogue_text)
	return true

func is_blocking() -> bool:
	return wait_for_user_input

func get_description() -> String:
	var preview_text = dialogue_text
	if preview_text.length() > 20:
		preview_text = preview_text.substr(0, 20) + "..."
	return "%s: %s" % [target_character, preview_text]
```

### 1.4 ClearImageEvent示例（完整实现）
```gdscript
class_name ClearImageEvent
extends EventData

## 清除图片事件类
## 用于清除之前显示的图片，支持按ID清除特定图片或清除所有图片

@export var image_id: String = ""  # 要清除的图片ID（空字符串表示清除所有）
@export var fade_out: bool = true  # 是否淡出清除
@export var fade_duration: float = 0.5  # 淡出持续时间
@export var wait_for_completion: bool = false  # 是否等待清除完成

func _init(p_id: String = "", img_id: String = ""):
	super._init(p_id, "clear_image")
	image_id = img_id

## 执行图片清除事件
func execute(executor) -> bool:
	print("执行图片清除事件: 图片ID ", image_id if not image_id.is_empty() else "全部")
	
	# 清除图片
	if image_id.is_empty():
		executor.clear_all_images(fade_out, fade_duration)
	else:
		executor.clear_image(image_id, fade_out, fade_duration)
	
	return true

## 根据fade_duration和wait_for_completion决定是否阻塞
func is_blocking() -> bool:
	return wait_for_completion or (fade_out and fade_duration > 0)

## 获取事件描述
func get_description() -> String:
	if image_id.is_empty():
		return "清除所有图片"
	else:
		return "清除图片: %s" % image_id
```

---

## 2. 更新EventExecutor

### 2.1 添加执行方法
在 `EventExecutor.gd` 中添加新事件类型的执行方法：

```gdscript
## 你的事件执行方法
func your_method(parameter: String):
	print("执行你的方法: ", parameter)
	
	# 实现具体逻辑
	# ...
	
	# 如果需要等待，不要立即调用完成回调
	# 如果不需要等待，可以立即调用：
	# _on_your_event_completed()

## 你的事件完成回调
func _on_your_event_completed():
	print("你的事件完成，继续下一个事件")
	current_event_index += 1
	execute_next_event()
```

### 2.2 DialogueEvent示例
```gdscript
## 显示对话
func show_dialogue(character: String, text: String):
	print("显示对话: [", character, "] ", text)
	
	if dialogue_ui:
		if dialogue_ui.has_method("show_dialogue"):
			dialogue_ui.show_dialogue(character, text)
	else:
		print("对话 - %s: %s" % [character, text])
		print("按任意键继续...")
	
	dialogue_displayed.emit(character, text)

## 对话完成回调
func _on_dialogue_completed():
	print("对话完成，继续下一个事件")
	current_event_index += 1
	execute_next_event()

## 处理用户输入（示例）
func _input(event):
	if is_executing and event.is_action_pressed("ui_accept"):
		if current_event_index < event_queue.size():
			var current_event = event_queue[current_event_index]
			if current_event is DialogueEvent:
				_on_dialogue_completed()
```

## 2.3 ClearImageEvent示例
```gdscript
## 清除指定图片
func clear_image(image_id: String, fade_out: bool = true, fade_duration: float = 0.5):
	print("🗑️ 清除图片: ", image_id)
	
	if image_id in displayed_images:
		var sprite = displayed_images[image_id]
		displayed_images.erase(image_id)
		
		if fade_out and fade_duration > 0:
			# 淡出动画
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
			sprite.queue_free()
			_on_image_clear_completed()
	else:
		print("❌ 未找到图片: ", image_id)
		_on_image_clear_completed()

## 清除所有图片
func clear_all_images(fade_out: bool = true, fade_duration: float = 0.5):
	print("🗑️ 清除所有图片")
	
	if displayed_images.is_empty():
		_on_image_clear_completed()
		return
	
	var sprites_to_clear = displayed_images.values()
	displayed_images.clear()
	
	for sprite in sprites_to_clear:
		if fade_out and fade_duration > 0:
			var tween = create_tween()
			tween.tween_property(sprite, "modulate:a", 0.0, fade_duration)
			tween.tween_callback(func(): sprite.queue_free())
		else:
			sprite.queue_free()
	
	if fade_out and fade_duration > 0:
		var timer = Timer.new()
		timer.wait_time = fade_duration
		timer.one_shot = true
		timer.timeout.connect(_on_image_clear_completed)
		get_tree().current_scene.add_child(timer)
		timer.start()
	else:
		_on_image_clear_completed()

## 图片清除完成回调
func _on_image_clear_completed():
	print("图片清除完成，继续下一个事件")
	current_event_index += 1
	execute_next_event()
```

---

## 3. 更新NarrativeEngine

### 3.1 添加JSON解析
在 `NarrativeEngine.gd` 的 `load_events_from_file()` 方法中添加新事件类型的解析：

```gdscript
# 在for event_dict in event_data_list循环中添加：
elif event_dict.type == "your_event_type":
	var your_event = YourEvent.new("editor_event_" + str(events.size()), event_dict.your_parameter)
	# 设置其他参数
	events.append(your_event)
	print("解析你的事件: ", event_dict.your_parameter)
```

### 3.2 DialogueEvent示例
```gdscript
elif event_dict.type == "dialogue":
	var dialogue_event = DialogueEvent.new("editor_event_" + str(events.size()), event_dict.character, event_dict.text)
	events.append(dialogue_event)
	print("解析对话事件: ", event_dict.character, " 说: ", event_dict.text)
```

### 3.3 ClearImageEvent示例
```gdscript
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
```

---

## 4. 更新编辑器UI

### 4.1 添加事件类型选项
在 `narrative_editor_main.gd` 的 `setup_ui()` 方法中添加：

```gdscript
event_type_option.add_item("你的事件类型")
```

### 4.1.1 ClearImageEvent示例
```gdscript
event_type_option.add_item("清除图片事件")
```

### 4.2 创建UI组
```gdscript
## 创建你的事件UI组
func create_your_event_group():
	var right_panel = $HSplitContainer/RightPanel
	
	# 创建UI组
	your_event_group = VBoxContainer.new()
	your_event_group.name = "YourEventGroup"
	your_event_group.visible = false
	
	# 添加输入控件
	var label = Label.new()
	label.text = "你的参数:"
	your_event_group.add_child(label)
	
	your_parameter_input = LineEdit.new()
	your_parameter_input.placeholder_text = "请输入参数..."
	your_event_group.add_child(your_parameter_input)
	
	# 添加按钮
	var button = Button.new()
	button.text = "添加你的事件"
	button.pressed.connect(_on_add_your_event)
	your_event_group.add_child(button)
	
	# 添加到面板
	right_panel.add_child(your_event_group)
```

### 4.3 添加事件类型切换
在 `_on_event_type_changed()` 方法中添加：

```gdscript
elif index == 2:  # 你的事件类型（假设索引是2）
	movement_group.visible = false
	dialogue_group.visible = false
	your_event_group.visible = true
```

### 4.4 添加事件创建方法
```gdscript
## 添加你的事件
func _on_add_your_event():
	var parameter = your_parameter_input.text
	
	if parameter.strip_edges().is_empty():
		print("参数不能为空")
		return
	
	var event_data = {
		"type": "your_event_type",
		"your_parameter": parameter
	}
	
	events.append(event_data)
	update_events_list()
	print("添加你的事件: ", parameter)
```

### 4.5 更新事件列表显示
在 `update_events_list()` 方法中添加：

```gdscript
elif event.type == "your_event_type":
	label.text = "[%d] 你的事件: %s" % [i, event.your_parameter]
```

### 4.6 载入事件功能 🆕
为编辑器添加载入已保存事件的功能：

#### 4.6.1 添加载入按钮
在 `NarrativeEditor.tscn` 中添加：
```gdscript
[node name="LoadEvents" type="Button" parent="HSplitContainer/LeftPanel/ButtonsContainer"]
layout_mode = 2
text = "载入事件"
```

#### 4.6.2 实现载入方法
```gdscript
## 载入事件
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
	
	# 警告用户当前事件将被替换
	if not events.is_empty():
		print("⚠️ 当前编辑器中有事件，载入将覆盖这些事件")
	
	# 清空现有事件并解析载入的事件
	events.clear()
	# ... 解析逻辑（类似NarrativeEngine中的实现）
	
	update_events_list()
	print("成功载入 ", events.size(), " 个事件")
```

#### 4.6.3 连接载入按钮
在 `connect_signals()` 方法中添加：
```gdscript
var load_btn = get_node_or_null("HSplitContainer/LeftPanel/ButtonsContainer/LoadEvents")
if load_btn and not load_btn.pressed.is_connected(_on_load_events):
	load_btn.pressed.connect(_on_load_events)
```

### 4.7 事件编辑功能 🆕
为编辑器添加直接编辑现有事件的功能：

#### 4.7.1 编辑按钮实现
在 `update_events_list()` 方法中为每个事件添加编辑按钮：
```gdscript
# 编辑按钮
var edit_btn = Button.new()
edit_btn.text = "编辑"
edit_btn.pressed.connect(_on_edit_event.bind(i))
container.add_child(edit_btn)
```

#### 4.7.2 编辑事件处理
```gdscript
## 编辑事件
func _on_edit_event(index: int):
	var event = events[index]
	editing_mode = true
	editing_event_index = index
	
	# 根据事件类型切换UI并填充数据
	if event.type == "movement":
		event_type_option.selected = 0
		_on_event_type_changed(0)
		_populate_movement_event(event)
	elif event.type == "dialogue":
		event_type_option.selected = 1
		_on_event_type_changed(1)
		_populate_dialogue_event(event)
	# ... 其他事件类型
	
	update_button_modes()
```

#### 4.7.3 数据填充方法
```gdscript
## 填充对话事件数据
func _populate_dialogue_event(event):
	var character_input_node = dialogue_group.get_node("CharacterContainer/DialogueCharacterInput")
	character_input_node.text = event.character
	dialogue_text_input.text = event.text

## 填充图片事件数据
func _populate_image_event(event):
	image_path_input.text = event.image_path
	image_x_input.value = event.position.x
	image_y_input.value = event.position.y
	# ... 填充其他参数
```

#### 4.7.4 编辑模式支持
修改各个事件的添加方法以支持编辑模式：
```gdscript
## 添加/更新对话事件
func _on_add_dialogue_event():
	# ... 获取参数
	
	if editing_mode:
		# 编辑模式：更新现有事件
		events[editing_event_index] = event_data
		print("更新对话事件 [%d]" % editing_event_index)
		exit_editing_mode()
	else:
		# 添加模式：创建新事件
		events.append(event_data)
		print("添加对话事件")
	
	update_events_list()
```

#### 4.7.5 编辑状态UI
创建编辑状态提示面板：
```gdscript
## 创建编辑状态面板
func create_edit_status_panel():
	var edit_status_group = VBoxContainer.new()
	edit_status_group.name = "EditStatusGroup"
	edit_status_group.visible = false
	
	# 状态标签
	var status_label = Label.new()
	status_label.text = "正在编辑事件 [0]"
	status_label.add_theme_color_override("font_color", Color.ORANGE)
	edit_status_group.add_child(status_label)
	
	# 取消编辑按钮
	var cancel_btn = Button.new()
	cancel_btn.text = "取消编辑"
	cancel_btn.pressed.connect(_on_cancel_edit)
	edit_status_group.add_child(cancel_btn)
```

---

## 5. 测试验证

### 5.1 检查清单
- [ ] Event类文件创建正确，继承自EventData
- [ ] EventExecutor添加了相应的执行方法
- [ ] NarrativeEngine能正确解析JSON中的新事件类型
- [ ] 编辑器UI能显示新事件类型的编辑界面
- [ ] 能成功添加新事件到事件列表
- [ ] JSON保存包含新事件数据
- [ ] 运行时能正确执行新事件

### 5.2 测试步骤
1. 重新加载插件
2. 选择新的事件类型
3. 填写参数并添加事件
4. 点击"执行事件"保存到JSON
5. 运行游戏（F5）并按空格键测试

### 5.3 调试技巧
- 在关键方法中添加 `print()` 调试输出
- 检查JSON文件内容是否正确
- 查看Godot编辑器的输出面板确认事件执行
- 确保所有必需的参数都已设置

---

## 🚨 常见问题

### Q1: 事件不执行
- 检查 `execute()` 方法是否返回 `true`
- 确认EventExecutor中有对应的执行方法
- 验证JSON解析是否正确

### Q2: UI界面不显示
- 确认UI组已正确创建
- 检查事件类型切换逻辑
- 验证UI组的可见性设置

### Q3: JSON保存失败
- 确认事件数据结构正确
- 检查保存方法中的序列化逻辑
- 验证文件权限

### Q4: 编辑功能异常 🆕
- 检查 `editing_mode` 状态是否正确设置
- 确认 `editing_event_index` 在有效范围内
- 验证数据填充方法是否正确获取UI节点
- 确保按钮文本更新逻辑正常工作

### Q5: 编辑状态UI不显示 🆕
- 确认 `create_edit_status_panel()` 被正确调用
- 检查UI组的可见性设置
- 验证 `update_edit_status_panel()` 逻辑

---

## 💡 最佳实践

1. **命名规范**: 使用清晰的命名，如 `DialogueEvent`、`SoundEvent`
2. **参数验证**: 在事件执行前验证必需参数
3. **错误处理**: 添加适当的错误处理和日志输出
4. **文档注释**: 为事件类添加详细的文档注释
5. **测试覆盖**: 确保每种事件类型都有完整的测试
6. **编辑功能支持** 🆕: 为新事件类型实现数据填充和编辑模式支持
7. **状态管理**: 正确处理编辑模式的进入和退出
8. **用户体验**: 提供清晰的编辑状态提示和取消机制

## 🔧 重要设计考虑 🆕

### is_blocking() 方法的使用
```gdscript
## 正确的阻塞逻辑
func is_blocking() -> bool:
	return wait_for_completion  # 只有明确需要等待时才阻塞
	# 避免: return duration > 0  # 这会导致不必要的阻塞
```

### 图片ID管理
```gdscript
# 使用稳定的ID生成策略
var filename = image_path.get_file().get_basename()
var image_id = filename + "_0"  # 基于文件名的稳定ID

# 管理图片字典
var displayed_images: Dictionary = {}  # 存储所有显示的图片
```

### EventExecutor中的资源管理
```gdscript
# 正确处理duration=0的情况
if duration > 0:
	# 设置定时器自动移除图片
	var timer = Timer.new()
	timer.timeout.connect(func(): remove_image_only(image_id))
# duration=0时图片永久显示，直到手动清除
```

### 编辑功能的设计模式 🆕
```gdscript
# 编辑模式状态管理
var editing_mode: bool = false
var editing_event_index: int = -1

# 智能按钮文本切换
func update_button_modes():
	if editing_mode:
		# 显示"更新XX事件"
		button.text = "更新对话事件"
	else:
		# 显示"添加XX事件"
		button.text = "添加对话事件"

# 统一的添加/编辑处理逻辑
func _on_add_dialogue_event():
	var event_data = create_event_data()
	
	if editing_mode:
		events[editing_event_index] = event_data  # 更新
		exit_editing_mode()
	else:
		events.append(event_data)  # 添加
	
	update_events_list()
```

---

## 📚 参考示例

本指南基于DialogueEvent和ClearImageEvent的完整实现。你可以参考以下文件：
- `addons/narrative_editor/core/events/DialogueEvent.gd` - 对话事件示例
- `addons/narrative_editor/core/events/ClearImageEvent.gd` - 清除图片事件示例 🆕
- `addons/narrative_editor/core/events/ImageEvent.gd` - 图片显示事件
- `addons/narrative_editor/core/EventExecutor.gd` - 事件执行器
- `addons/narrative_editor/core/NarrativeEngine.gd` - 叙事引擎
- `addons/narrative_editor/narrative_editor_main.gd` - 编辑器界面

## 🎯 编辑器工作流程 🆕

1. **创建事件** - 在编辑器中设计事件序列
2. **编辑事件** - 点击事件的"编辑"按钮直接修改 🆕
3. **保存事件** - 点击"保存事件"按钮存储到JSON
4. **载入事件** - 点击"载入事件"按钮从JSON读取
5. **测试执行** - 运行游戏按空格键测试
6. **继续编辑** - 载入后可继续修改和完善

### 📝 编辑事件详细流程 🆕

```
点击事件列表中的"编辑"按钮
          ↓
右侧面板自动切换到对应事件类型
          ↓
所有参数自动填充到输入框中
          ↓
顶部显示"正在编辑事件 [索引]: 事件类型"
          ↓
修改参数后点击"更新XX事件"按钮
          ↓
事件更新完成，自动退出编辑模式
```

## 🚀 完整功能清单

### 事件类型支持
- ✅ 移动事件 (MovementEvent)
- ✅ 对话事件 (DialogueEvent) 
- ✅ 图片显示事件 (ImageEvent)
- ✅ 清除图片事件 (ClearImageEvent)

### 编辑器核心功能
- ✅ **事件编辑功能** 🆕 - 直接修改现有事件
- ✅ 事件保存功能 - 存储到JSON文件
- ✅ 事件载入功能 - 从JSON文件读取
- ✅ 事件删除功能 - 删除不需要的事件
- ✅ 可视化编辑器 - 友好的图形界面
- ✅ 实时预览和测试 - 即时查看效果

### 用户体验特性 🆕
- ✅ **智能编辑模式** - 一键切换添加/编辑状态
- ✅ **参数自动填充** - 编辑时自动加载现有数据
- ✅ **编辑状态提示** - 清晰显示当前编辑的事件
- ✅ **取消编辑功能** - 随时退出编辑模式
- ✅ **按钮文本动态切换** - "添加事件" ↔ "更新事件"

按照这个指南，你可以轻松扩展叙事引擎，添加任何新的事件类型！ 