class_name EventData
extends Resource

## 事件数据基类
## 所有具体事件类型都继承自这个基类

@export var id: String = ""
@export var event_type: String = ""
@export var parameters: Dictionary = {}
@export var next_event_id: String = ""

func _init(p_id: String = "", p_type: String = ""):
	id = p_id
	event_type = p_type

## 执行事件的虚方法，由具体事件类型重写
func execute(executor) -> bool:
	print("执行基础事件: ", id)
	return true

## 是否需要等待事件完成
func is_blocking() -> bool:
	return false

## 获取事件的描述信息（用于编辑器显示）
func get_description() -> String:
	return "基础事件: " + id 