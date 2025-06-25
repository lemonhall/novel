# 🎭 叙事引擎项目 (重构版)

> **基于Godot 4.4的现代化视觉小说/叙事游戏引擎**  
> **特色：配置驱动开发 + 自动化UI生成 + 极简扩展**

## ✨ 项目亮点

- 🚀 **代码量减少70%**：从1100+行重构到400+行
- ⚡ **极简扩展**：添加新事件类型只需几十行配置代码
- 🎨 **UI完全自动生成**：包括编辑、保存、载入等所有功能
- 🔧 **配置驱动开发**：无需修改UI代码，只需配置即可
- 🎯 **开箱即用**：支持5种事件类型，满足大部分叙事需求

## 📁 项目结构

```
novel/
├── addons/narrative_editor/          # 重构版叙事编辑器插件
│   ├── core/                        # 核心系统
│   │   ├── EventTypeRegistry.gd      # 事件类型注册表（配置中心）
│   │   ├── EventUIBuilder.gd         # 自动UI生成器
│   │   ├── EventExecutor.gd          # 事件执行引擎
│   │   ├── NarrativeEngine.gd        # 叙事引擎主控制器
│   │   └── events/                   # 事件类型实现
│   │       ├── DialogueEvent.gd      # 对话事件
│   │       ├── MovementEvent.gd      # 移动事件
│   │       ├── ImageEvent.gd         # 图片事件
│   │       ├── ClearImageEvent.gd    # 清除图片事件
│   │       └── SoundEvent.gd         # 音效事件
│   ├── examples/                    # 示例和文档
│   └── NarrativeEditor.tscn         # 编辑器UI场景
├── assets/                          # 游戏资源
│   ├── images/                      # 图片资源
│   ├── audio/sfx/                   # 音效资源
│   └── ui/DialogueUI.tscn          # 对话UI
├── data/                           # 游戏数据
│   ├── current_events.json         # 当前事件序列
│   └── stories/                    # 故事数据目录
├── main.tscn                       # 主场景
└── 叙事引擎设计文档.md              # 设计文档
```

## 🎮 支持的事件类型

| 事件类型 | 功能描述 | 配置字段 | 使用场景 |
|---------|---------|---------|---------|
| **对话事件** | 显示角色对话 | 角色名、对话内容 | 角色对话、旁白 |
| **移动事件** | 角色位置移动 | 角色、目标位置、移动速度 | 角色走动、场景切换 |
| **图片事件** | 显示图片/立绘 | 图片路径、位置、缩放、持续时间 | 角色立绘、CG显示 |
| **清除图片事件** | 移除指定图片 | 图片ID、淡出效果、淡出时长 | 角色退场、场景清理 |
| **音效事件** | 播放音效 | 音效路径、音量、等待完成 | 背景音乐、音效 |

## 🚀 快速开始

### 1. 基础设置

1. **启用插件**：
   - 打开项目设置 → 插件
   - 启用 "narrative_editor"

2. **打开编辑器**：
   - 点击编辑器顶部的 "🧩 叙事编辑器" 页签

### 2. 创建你的第一个故事

1. **添加对话事件**：
   ```
   角色: 主角
   对话内容: 你好，这是我的第一句话！
   ```

2. **添加图片事件**：
   ```
   图片路径: res://assets/images/Actor2_4.png
   位置: (400, 300)
   缩放: (1.0, 1.0)
   ```

3. **添加音效事件**：
   ```
   音效文件: res://assets/audio/sfx/player_death.wav
   音量: 1.0
   等待播放完成: false
   ```

4. **保存并测试**：
   - 点击 "保存事件"
   - 运行项目 (F5)
   - 按空格键开始执行事件序列

## 🎨 编辑器功能

### 事件管理
- ✅ **添加事件** - 通过配置化界面轻松添加
- ✅ **编辑事件** - 点击"编辑"按钮修改现有事件
- ✅ **删除事件** - 一键删除不需要的事件
- ✅ **调整顺序** - 使用↑↓按钮调整事件执行顺序
- ✅ **实时预览** - 事件列表实时显示当前配置

### 高级功能
- 🎯 **预设位置网格** - 移动事件支持快速选择预设位置
- 🎛️ **资源选择器** - 图片和音效支持可视化资源选择
- 📊 **范围验证** - 自动验证输入范围和必填字段
- 💾 **自动保存** - 支持JSON格式保存和载入

## 🔧 开发者指南

### 添加新事件类型（只需5步）

#### 1️⃣ 在注册表中配置
```gdscript
# addons/narrative_editor/core/EventTypeRegistry.gd
register_event_type("your_event", {
    "display_name": "你的事件",
    "class_name": "YourEvent",
    "ui_fields": [
        {
            "name": "your_field",
            "type": "line_edit",
            "label": "你的字段:",
            "default": "默认值"
        }
    ],
    "button_text": {
        "add": "添加你的事件",
        "update": "更新你的事件"
    }
})
```

#### 2️⃣ 创建事件类
```gdscript
# addons/narrative_editor/core/events/YourEvent.gd
class_name YourEvent
extends EventData

@export var your_field: String = ""

func _init(p_id: String = "", field_value: String = ""):
    super._init(p_id, "your_event")
    your_field = field_value

func execute(executor) -> bool:
    # 实现你的逻辑
    return true
```

#### 3️⃣ 添加执行方法
```gdscript
# addons/narrative_editor/core/EventExecutor.gd
func your_action(field_value: String):
    # 实现执行逻辑
    _on_your_event_completed()

func _on_your_event_completed():
    current_event_index += 1
    execute_next_event()
```

#### 4️⃣ 添加解析逻辑
```gdscript
# addons/narrative_editor/core/NarrativeEngine.gd
elif event_dict.type == "your_event":
    var your_event = YourEvent.new("editor_event_" + str(events.size()), event_dict.your_field)
    events.append(your_event)
```

#### 5️⃣ 添加显示文本
```gdscript
# addons/narrative_editor/narrative_editor_main_refactored.gd
"your_event":
    return "[%d] 你的事件: %s" % [index, event.your_field]
```

### 支持的字段类型

| 类型 | 描述 | 配置选项 |
|------|------|---------|
| `line_edit` | 单行文本 | default, placeholder |
| `text_edit` | 多行文本 | placeholder, min_size |
| `spin_box` | 数值输入 | default, min_value, max_value, step |
| `vector2` | 坐标输入 | default, min_value, max_value, step |
| `check_box` | 复选框 | default |
| `resource_picker` | 资源选择器 | resource_type, placeholder |

## 🎯 重构成果

### 代码量对比
- **重构前**: 1100+ 行代码
- **重构后**: 400+ 行代码
- **减少比例**: 70%

### 开发效率提升
- **添加新事件类型**：从几百行代码 → 几十行配置
- **UI开发**：从手写UI代码 → 完全自动生成
- **维护成本**：从复杂的UI逻辑 → 简单的配置管理

### 架构优势
- 🏗️ **职责分离**：注册表、UI构建器、事件执行器各司其职
- 🔄 **配置驱动**：通过配置文件驱动整个系统
- 🧩 **高度模块化**：每个事件类型独立，易于扩展
- 🛡️ **错误处理**：完善的验证和错误处理机制

## 🎪 项目配置

### 窗口设置
```ini
[display]
window/size/viewport_width=1152
window/size/viewport_height=648
window/size/mode=3  # 最大化窗口
window/size/resizable=true
window/stretch/mode="canvas_items"
window/stretch/aspect="expand"
```

### 开发环境
- **Godot版本**: 4.4.1.stable
- **操作系统**: Windows 11
- **终端**: PowerShell
- **脚本语言**: GDScript

## 🐛 常见问题解决

### Vector2字段显示问题
**问题**: 编辑模式下坐标显示不正确  
**原因**: SpinBox默认范围限制  
**解决**: 为位置字段设置合适的范围 (0-6000)

### 插件UI混合问题
**问题**: 插件UI与主界面重叠  
**原因**: 场景布局设置不当  
**解决**: 使用动态添加/移除而不是显示/隐藏

### PowerShell命令连接
**注意**: 在PowerShell中使用 `;` 连接命令而不是 `&&`

## 📚 相关文档

- [如何实现新的Event类型.md](如何实现新的Event类型.md) - 详细的扩展教程
- [叙事引擎设计文档.md](叙事引擎设计文档.md) - 系统设计文档
- [测试对话UI.md](测试对话UI.md) - UI测试说明

## 🤝 贡献

欢迎提交问题和改进建议！这个项目展示了如何用配置驱动的方式简化复杂的编辑器开发。

## 📄 许可证

MIT License - 自由使用和修改

---

> **💡 设计理念**: "用配置代替代码，用自动化代替重复劳动"  
> **🎯 项目目标**: 让叙事游戏开发变得简单而高效 