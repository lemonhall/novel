# 如何实现新的Event类型

本文档详细说明了在叙事引擎中实现新事件类型的完整步骤。以DialogueEvent的实现为例。

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

---

## 4. 更新编辑器UI

### 4.1 添加事件类型选项
在 `narrative_editor_main.gd` 的 `setup_ui()` 方法中添加：

```gdscript
event_type_option.add_item("你的事件类型")
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

---

## 💡 最佳实践

1. **命名规范**: 使用清晰的命名，如 `DialogueEvent`、`SoundEvent`
2. **参数验证**: 在事件执行前验证必需参数
3. **错误处理**: 添加适当的错误处理和日志输出
4. **文档注释**: 为事件类添加详细的文档注释
5. **测试覆盖**: 确保每种事件类型都有完整的测试

---

## 📚 参考示例

本指南基于DialogueEvent的完整实现。你可以参考以下文件：
- `addons/narrative_editor/core/events/DialogueEvent.gd`
- `addons/narrative_editor/core/EventExecutor.gd`
- `addons/narrative_editor/core/NarrativeEngine.gd`
- `addons/narrative_editor/narrative_editor_main.gd`

按照这个指南，你可以轻松扩展叙事引擎，添加任何新的事件类型！ 