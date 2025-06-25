extends RefCounted

## 事件类型注册表
## 统一管理所有事件类型的配置信息，简化编辑器代码

static var event_types: Dictionary = {}

## 注册事件类型
static func register_event_type(type_id: String, config: Dictionary):
	event_types[type_id] = config
	print("注册事件类型: ", type_id)

## 获取事件类型配置
static func get_event_type(type_id: String) -> Dictionary:
	return event_types.get(type_id, {})

## 获取所有事件类型
static func get_all_event_types() -> Dictionary:
	return event_types

## 初始化默认事件类型
static func initialize_default_types():
	# 移动事件
	register_event_type("movement", {
		"display_name": "移动事件",
		"class_name": "MovementEvent",
		"ui_fields": [
			{
				"name": "character",
				"type": "line_edit",
				"label": "角色:",
				"default": "player"
			},
			{
				"name": "destination",
				"type": "vector2",
				"label": "目标位置:",
				"default": Vector2(400, 300),
				"custom_ui": "preset_position_grid"
			},
			{
				"name": "speed",
				"type": "spin_box",
				"label": "移动速度:",
				"default": 200,
				"min_value": 50,
				"max_value": 1000
			}
		],
		"button_text": {
			"add": "添加移动事件",
			"update": "更新移动事件"
		}
	})
	
	# 对话事件
	register_event_type("dialogue", {
		"display_name": "对话事件",
		"class_name": "DialogueEvent",
		"ui_fields": [
			{
				"name": "character",
				"type": "line_edit",
				"label": "角色:",
				"default": "player"
			},
			{
				"name": "text",
				"type": "text_edit",
				"label": "对话内容:",
				"placeholder": "请输入对话内容...",
				"min_size": Vector2(0, 80)
			}
		],
		"button_text": {
			"add": "添加对话事件",
			"update": "更新对话事件"
		}
	})
	
	# 图片事件
	register_event_type("image", {
		"display_name": "图片事件",
		"class_name": "ImageEvent",
		"ui_fields": [
			{
				"name": "image_path",
				"type": "resource_picker",
				"label": "图片路径:",
				"resource_type": "Texture2D",
				"placeholder": "res://assets/images/your_image.png"
			},
			{
				"name": "position",
				"type": "vector2",
				"label": "位置:",
				"default": Vector2(400, 300)
			},
			{
				"name": "scale",
				"type": "vector2",
				"label": "缩放:",
				"default": Vector2(1.0, 1.0),
				"min_value": -2.0,
				"max_value": 5.0,
				"step": 0.1
			},
			{
				"name": "duration",
				"type": "spin_box",
				"label": "持续时间(秒):",
				"default": 0,
				"min_value": 0,
				"max_value": 30,
				"tooltip": "0表示永久显示"
			},
			{
				"name": "fade_in",
				"type": "check_box",
				"label": "淡入效果",
				"default": true
			},
			{
				"name": "wait_for_completion",
				"type": "check_box",
				"label": "等待完成",
				"default": false
			}
		],
		"button_text": {
			"add": "添加图片事件",
			"update": "更新图片事件"
		}
	})
	
	# 清除图片事件
	register_event_type("clear_image", {
		"display_name": "清除图片事件",
		"class_name": "ClearImageEvent",
		"ui_fields": [
			{
				"name": "image_id",
				"type": "line_edit",
				"label": "图片ID (留空清除所有图片):",
				"placeholder": "例如: Actor1_8_0 (留空则清除所有)"
			},
			{
				"name": "fade_out",
				"type": "check_box",
				"label": "淡出效果",
				"default": true
			},
			{
				"name": "fade_duration",
				"type": "spin_box",
				"label": "淡出时长(秒):",
				"default": 0.5,
				"min_value": 0.1,
				"max_value": 5.0,
				"step": 0.1
			},
			{
				"name": "wait_for_completion",
				"type": "check_box",
				"label": "等待清除完成",
				"default": false
			}
		],
		"button_text": {
			"add": "添加清除图片事件",
			"update": "更新清除图片事件"
		}
	})
	
	# 音效事件
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
				"max_value": 2.0,
				"step": 0.1
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
	
	print("事件类型注册完成，共注册 ", event_types.size(), " 种事件类型") 