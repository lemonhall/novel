# 叙事引擎项目

基于Godot 4.4的视觉小说/叙事游戏引擎，包含自定义的叙事编辑器插件。

## 项目结构

- `addons/narrative_editor/` - 叙事编辑器插件
- `addons/dialogue_manager/` - 对话管理器（第三方插件）
- `data/` - 游戏数据文件
- `assets/` - 游戏资源
- `叙事引擎设计文档.md` - 详细的设计文档

## 叙事编辑器插件

位于 `addons/narrative_editor/` 目录的自定义编辑器插件，用于可视化编辑角色移动和叙事事件。

### 主要功能

- 角色移动事件编辑
- 预设位置快速设置
- 事件序列管理
- 实时位置显示和刷新

### 重要问题解决记录

#### 主屏幕插件UI混合问题

**问题**: 在开发过程中遇到插件UI与Godot主界面混合渲染的问题，表现为：
- 插件内容出现在不应该显示的地方
- 与编辑器主界面元素重叠
- 即使在其他页签也能看到插件UI元素

**原因分析**:
1. 场景根节点使用了错误的layout设置
2. 插件加载方式不符合Godot官方规范
3. 使用简单的 `visible = false` 隐藏方式不够彻底

**解决方案**:

1. **正确的场景布局设置** (`NarrativeEditor.tscn`):
   ```
   [node name="NarrativeEditor" type="Control"]
   layout_mode = 1
   anchors_preset = 15
   anchor_right = 1.0
   anchor_bottom = 1.0
   grow_horizontal = 2
   grow_vertical = 2
   size_flags_horizontal = 3
   size_flags_vertical = 3
   ```

2. **动态添加/移除UI** (`plugin.gd`):
   ```gdscript
   func _make_visible(visible):
       if visible:
           # 显示时：创建并添加面板
           if not main_panel_instance:
               main_panel_instance = MainPanel.instantiate()
           if not main_panel_instance.get_parent():
               main_screen_container.add_child(main_panel_instance)
       else:
           # 隐藏时：从场景树中完全移除面板
           if main_panel_instance and main_panel_instance.get_parent():
               main_panel_instance.get_parent().remove_child(main_panel_instance)
   ```

**关键要点**:
- 使用动态添加/移除而不是显示/隐藏
- 确保场景根节点有正确的size flags和grow设置
- 严格遵循Godot官方主屏幕插件开发规范

### 使用方法

1. 在项目设置→插件中启用"narrative_editor"
2. 点击编辑器顶部的"叙事编辑器"页签
3. 使用右侧面板编辑移动事件
4. 点击"执行事件"保存并测试

## 开发环境

- Godot 4.4
- Windows 11
- PowerShell

## 注意事项

- 在PowerShell中连接多个命令需要使用分号 `;` 而不是 `&&`
- 插件开发需要添加 `@tool` 注解
- 主屏幕插件必须实现特定的EditorPlugin方法 