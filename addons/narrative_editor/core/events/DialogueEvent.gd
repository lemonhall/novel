class_name DialogueEvent
extends EventData

## 对话事件类
## 显示角色对话内容

@export var target_character: String = ""  # 说话的角色ID
@export var dialogue_text: String = ""  # 对话内容
@export var wait_for_user_input: bool = true  # 是否等待用户输入

func _init(p_id: String = "", character_id: String = "", text: String = ""):
	super._init(p_id, "dialogue")
	target_character = character_id
	dialogue_text = text

## 执行对话事件
func execute(executor) -> bool:
	print("执行对话事件: 角色 ", target_character, " 说: ", dialogue_text)
	
	# 显示对话
	executor.show_dialogue(target_character, dialogue_text)
	
	return true

## 对话事件通常需要等待用户输入
func is_blocking() -> bool:
	return wait_for_user_input

## 获取事件描述
func get_description() -> String:
	var preview_text = dialogue_text
	if preview_text.length() > 20:
		preview_text = preview_text.substr(0, 20) + "..."
	return "%s: %s" % [target_character, preview_text] 