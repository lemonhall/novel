# 如何实现新的Event类型 (重构版)

> **重构完成！** 🎉 添加新事件类型现在只需要**几行配置代码**，告别几百行重复代码！

## 🚀 重构后的优势

- **从 1100+ 行代码减少到 400+ 行**
- **添加新事件类型从几百行代码变成几十行配置**
- **UI界面完全自动生成，包括编辑功能**
- **配置驱动开发，无需修改UI代码**

## 📋 添加新事件类型的简化流程

### 1️⃣ 在注册表中配置事件类型

在 `EventTypeRegistry.gd` 的 `initialize_default_types()` 方法中添加配置：

```gdscript
# 音效事件示例
register_event_type("sound", {
	"display_name": "音效事件",
	"class_name": "SoundEvent",
	"ui_fields": [
		{
			"name": "sound_path",
			"type": "resource_picker",
			"label": "音效文件:",
			"resource_type": "AudioStream"
		},
		{
			"name": "volume",
			"type": "spin_box",
			"label": "音量:",
			"default": 1.0,
			"min_value": 0.0,
			"max_value": 2.0
		},
		{
			"name": "wait_for_completion",
			"type": "check_box",
			"label": "等待播放完成",
			"default": false
		}
	],
	"button_text": {
		"add": "添加音效事件",
		"update": "更新音效事件"
	}
})
```

### 2️⃣ 创建事件类

```gdscript
# 文件: addons/narrative_editor/core/events/SoundEvent.gd
class_name SoundEvent
extends EventData

@export var sound_path: String = ""
@export var volume: float = 1.0
@export var wait_for_completion: bool = false

func _init(p_id: String = "", path: String = ""):
	super._init(p_id, "sound")
	sound_path = path

func execute(executor) -> bool:
	executor.play_sound(sound_path, volume)
	return true

func is_blocking() -> bool:
	return wait_for_completion
```

### 3️⃣ 在EventExecutor中添加执行方法

```gdscript
# 在EventExecutor.gd中添加：
func play_sound(sound_path: String, volume: float = 1.0):
	print("🔊 播放音效: ", sound_path)
	# 播放逻辑...
	_on_sound_completed()

func _on_sound_completed():
	current_event_index += 1
	execute_next_event()
```

### 4️⃣ 在NarrativeEngine中添加解析

```gdscript
# 在NarrativeEngine.gd的load_events_from_file()方法中添加：
elif event_dict.type == "sound":
	var sound_event = SoundEvent.new("editor_event_" + str(events.size()), event_dict.sound_path)
	sound_event.volume = event_dict.get("volume", 1.0)
	sound_event.wait_for_completion = event_dict.get("wait_for_completion", false)
	events.append(sound_event)
```

### 5️⃣ 添加显示文本（可选）

```gdscript
# 在narrative_editor_main_refactored.gd的_get_event_display_text()方法中添加：
"sound":
	var filename = event.sound_path.get_file()
	return "[%d] 播放音效: %s" % [index, filename]
```

## ✅ 完成！

就这样，一个完整的音效事件类型就添加完成了！UI界面会自动生成，包括：

- 事件类型选项
- 参数输入界面
- 编辑功能
- 数据验证
- 保存/载入

## 🎯 支持的字段类型

| 类型 | 用途 | 示例 |
|------|------|------|
| `line_edit` | 单行文本 | 角色名、文件路径 |
| `text_edit` | 多行文本 | 对话内容 |
| `spin_box` | 数值输入 | 音量、速度、时间 |
| `vector2` | 坐标输入 | 位置、缩放 |
| `check_box` | 开关选项 | 是否等待、淡入效果 |
| `resource_picker` | 资源选择 | 图片、音效文件 |

## 🚀 更多事件类型示例

### 等待事件
```gdscript
register_event_type("wait", {
	"display_name": "等待事件",
	"ui_fields": [
		{
			"name": "duration",
			"type": "spin_box",
			"label": "等待时间(秒):",
			"default": 1.0,
			"min_value": 0.1,
			"max_value": 10.0
		}
	]
})
```

### 背景切换事件
```gdscript
register_event_type("background", {
	"display_name": "背景事件",
	"ui_fields": [
		{
			"name": "background_path",
			"type": "resource_picker",
			"label": "背景图片:",
			"resource_type": "Texture2D"
		},
		{
			"name": "fade_duration",
			"type": "spin_box",
			"label": "淡入时长:",
			"default": 1.0
		}
	]
})
```

## 🔧 高级配置选项

### 字段配置属性
- `name` - 字段名称（必需）
- `type` - 字段类型（必需）
- `label` - 显示标签（必需）
- `default` - 默认值
- `min_value` / `max_value` - 数值范围
- `step` - 数值步进
- `placeholder` - 占位符文本
- `resource_type` - 资源类型限制
- `required` - 是否必填

### 自定义UI
对于特殊需求（如移动事件的预设位置网格），可以在字段配置中添加：
```gdscript
{
	"name": "destination",
	"type": "vector2",
	"custom_ui": "preset_position_grid"  # 触发自定义UI
}
```

## 💡 最佳实践

1. **命名规范** - 使用清晰的事件类型ID和显示名称
2. **参数验证** - 在事件类中添加适当的参数验证
3. **错误处理** - 在执行方法中添加错误处理
4. **文档注释** - 为事件类添加详细注释
5. **测试** - 确保新事件类型在各种情况下都能正常工作

## 🎊 总结

重构后的叙事引擎具有以下特点：

- **极简配置** - 几行代码即可添加新事件类型
- **自动化UI** - 无需手写任何UI代码
- **完整功能** - 自动支持编辑、保存、载入等所有功能
- **易于维护** - 代码结构清晰，职责分离
- **高度扩展** - 轻松添加新字段类型和自定义UI

现在你可以专注于设计有趣的游戏逻辑，而不是编写重复的UI代码！🚀 