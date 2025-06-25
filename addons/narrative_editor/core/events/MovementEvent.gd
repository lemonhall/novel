class_name MovementEvent
extends EventData

## 移动事件类
## 控制角色从当前位置移动到目标位置

@export var target_character: String = ""  # 目标角色ID
@export var destination: Vector2 = Vector2.ZERO  # 目标位置
@export var speed: float = 200.0  # 移动速度
@export var wait_for_completion: bool = true  # 是否等待移动完成

func _init(p_id: String = "", character_id: String = "", dest: Vector2 = Vector2.ZERO):
	super._init(p_id, "movement")
	target_character = character_id
	destination = dest

## 执行移动事件
func execute(executor) -> bool:
	print("执行移动事件: 角色 ", target_character, " 移动到 ", destination)
	
	# 获取目标角色节点
	var character_node = executor.get_character(target_character)
	if not character_node:
		print("错误: 找不到角色 ", target_character)
		return false
	
	# 开始移动
	executor.move_character(character_node, destination, speed)
	
	return true

## 移动事件通常需要等待完成
func is_blocking() -> bool:
	return wait_for_completion

## 获取事件描述
func get_description() -> String:
	return "移动 %s 到 (%d, %d)" % [target_character, destination.x, destination.y] 