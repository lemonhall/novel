extends CanvasLayer

## 对话UI控制器
## 负责显示角色对话和处理用户输入

signal dialogue_finished()

@onready var dialogue_panel: Panel = $DialoguePanel
@onready var character_label: Label = $DialoguePanel/VBoxContainer/CharacterLabel
@onready var dialogue_label: RichTextLabel = $DialoguePanel/VBoxContainer/DialogueLabel
@onready var continue_button: Button = $DialoguePanel/VBoxContainer/ContinueButton

var is_dialogue_active: bool = false
var input_blocked: bool = false  # 防止立即输入
var show_frame: int = 0  # 记录显示对话的帧数

func _ready():
	# 初始时隐藏对话界面
	visible = false
	
	# 连接按钮信号
	continue_button.pressed.connect(_on_continue_pressed)
	
	print("🎭 对话UI已初始化 (CanvasLayer)")

## 显示对话
func show_dialogue(character: String, text: String):
	print("🗨️ DialogueUI显示对话: [", character, "] ", text)
	
	# 设置角色名和对话内容
	character_label.text = character
	dialogue_label.text = text
	
	# 显示对话界面
	visible = true
	is_dialogue_active = true
	input_blocked = true  # 暂时阻止输入
	
	print("✅ 对话UI已设为可见，is_dialogue_active = ", is_dialogue_active)
	
	# 短暂延迟后允许输入和获得焦点，防止立即关闭
	await get_tree().create_timer(0.2).timeout
	input_blocked = false
	
	# 现在安全地让按钮获得焦点
	continue_button.grab_focus()
	print("🔓 输入已解锁，按钮获得焦点")

## 隐藏对话
func hide_dialogue():
	visible = false
	is_dialogue_active = false
	input_blocked = false  # 重置输入阻止状态
	print("❌ 对话界面已隐藏")

## 继续按钮被点击
func _on_continue_pressed():
	print("🖱️ 继续按钮被点击")
	_finish_dialogue()

## 完成对话
func _finish_dialogue():
	hide_dialogue()
	dialogue_finished.emit()
	print("✅ 对话完成，发送信号")

## 处理输入
func _unhandled_input(event):
	if event is InputEventKey and event.pressed and (event.keycode == KEY_ENTER or event.keycode == KEY_SPACE):
		print("🔍 DialogueUI收到键盘输入: ", OS.get_keycode_string(event.keycode))
		print("   对话激活: ", is_dialogue_active)
		print("   输入阻止: ", input_blocked)
		print("   UI可见: ", visible)
		
	if not is_dialogue_active or input_blocked:
		return
		
	if event is InputEventKey and event.pressed:
		# 回车键或空格键继续对话
		if event.keycode == KEY_ENTER or event.keycode == KEY_SPACE:
			print("✅ DialogueUI处理输入，关闭对话")
			_finish_dialogue()
			get_viewport().set_input_as_handled()  # 防止事件继续传播 
