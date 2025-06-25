class_name ImageEvent
extends EventData

## 图片显示事件类
## 在指定位置显示图片，支持淡入淡出效果

@export var image_path: String = ""  # 图片文件路径
@export var position: Vector2 = Vector2.ZERO  # 图片显示位置
@export var scale: Vector2 = Vector2.ONE  # 图片缩放比例
@export var duration: float = 0.0  # 显示持续时间（0表示无限制）
@export var fade_in: bool = true  # 是否淡入显示
@export var wait_for_completion: bool = false  # 是否等待显示完成

func _init(p_id: String = "", img_path: String = "", pos: Vector2 = Vector2.ZERO):
	super._init(p_id, "image")
	image_path = img_path
	position = pos

## 执行图片显示事件
func execute(executor) -> bool:
	print("执行图片显示事件: 图片 ", image_path, " 位置: ", position)
	
	# 显示图片
	executor.show_image(image_path, position, scale, duration, fade_in)
	
	return true

## 根据duration和wait_for_completion决定是否阻塞
func is_blocking() -> bool:
	return wait_for_completion or duration > 0

## 获取事件描述
func get_description() -> String:
	var filename = image_path.get_file()
	if filename.is_empty():
		filename = "未设置"
	return "显示图片: %s (%.1f, %.1f)" % [filename, position.x, position.y] 