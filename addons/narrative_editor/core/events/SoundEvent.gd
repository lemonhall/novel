class_name SoundEvent
extends EventData

## 音效事件类
## 播放指定的音效文件

@export var sound_path: String = ""
@export var volume: float = 1.0
@export var wait_for_completion: bool = false

func _init(p_id: String = "", path: String = ""):
	super._init(p_id, "sound")
	sound_path = path

## 执行音效事件
func execute(executor) -> bool:
	print("🔊 执行音效事件: ", sound_path, " 音量: ", volume)
	
	# 播放音效
	executor.play_sound(sound_path, volume)
	
	return true

## 音效事件是否需要等待完成
func is_blocking() -> bool:
	return wait_for_completion

## 获取事件描述
func get_description() -> String:
	var filename = sound_path.get_file()
	if filename.is_empty():
		filename = "未选择文件"
	return "播放音效: %s (音量: %.1f)" % [filename, volume] 