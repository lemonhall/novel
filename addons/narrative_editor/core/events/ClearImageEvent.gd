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