# 状态大圆盘 (Status Circle) - Flutter 动效实现规范 v1.6

**`[AI 编程助手指令：请严格按照以下 Tween、Curve、Duration 和 Color 插值参数实现动画。这是一个基于状态机 (FSM)、清醒指数 (CI, 0.0~1.0) 和等待时长 (Duration) 联合驱动的复合动画系统。]`**

## Changelog
* **v1.6 (UI 调色与对比度重构)**:
  * **暗黑调色板升级**: 废弃高饱和度的亮绿/亮黄，改为低明度、低饱和度的“深海绿”、“暗铁锈红”和“血痂暗红”，强化压抑的情绪质感。
  * **文本对比度修复**: 废弃同色系文字。OS 文案与副标题统一采用带有 Opacity 的纯白色，主计时器采用纯白配纯黑阴影。
  * **Layout 修复**: 处理控制台区域可能出现的溢出边界 (Overflow) 异常。

## 一、 核心动画引擎与控制器
圆盘的动画由一个无限循环的 `AnimationController` (负责呼吸节奏) 和多个基于状态改变的隐式动画 (负责颜色和模糊度) 组成。

### 1. 基础呼吸动效 (Breathing Effect)
* **实现方式**: 控制圆盘的 `Scale` (缩放) 和外围 `BoxShadow.spreadRadius` (光晕扩散) 与 `BoxShadow.color.opacity` (光晕透明度)。
* **缩放范围**:
  * 阶段 1: `Tween<double>(begin: 1.0, end: 1.04)`
  * 阶段 2: `Tween<double>(begin: 1.0, end: 1.07)`（焦躁期更“顶”，需要从中心扩到周边的跳动感）
  * 阶段 3: `Tween<double>(begin: 1.0, end: 1.02)`（枯竭期更克制）

## 二、 基于等待时长的动效演变 (时长轴)
根据等待时间，动态修改 `AnimationController.duration` 和 `Curve`。

### 阶段 1：发酵期 (0 ~ 1小时) -> 【平稳理智】
* **周期 (Duration)**: `2500ms` (单程)。
* **曲线 (Curve)**: `Curves.easeInOutSine` (极其平滑、匀速的呼吸)。
* **视觉表现**: 像人在安静睡觉时的深呼吸。

### 阶段 2：应激期 (1 ~ 4小时) -> 【焦躁不安】
* **周期 (Duration)**: 缩短至 `1000ms`。
* **曲线 (Curve)**: `Curves.easeInOutBack` 或自定义一个带有轻微回弹的曲线。
* **视觉表现**: 呼吸急促，圆盘在收缩时有一种“顿挫感”，模拟人不耐烦时的急躁。

### 阶段 3：枯竭期 (> 4小时) -> 【解离死寂】
* **周期 (Duration)**: 延长至 `4000ms` (极慢)。
* **曲线 (Curve)**: 非对称动画。展开极慢 `Curves.easeOutExp`，收缩略快。
* **视觉表现**: 像心跳过缓，失去生命力。光晕几乎不怎么扩散。

## 三、 基于等待时长的暗黑调色板 (ColorTween)
废弃高饱和度绿/黄，圆盘背景仅使用暗黑情绪色系；在 `AnimationController` 驱动的颜色渐变里，必须使用以下 Hex 作为关键帧色值（可用 `ColorTween` / `Color.lerp` 插值）。

### 1. 状态大圆盘颜色映射表 (中心色 / 边缘光晕)
* **阶段 1 (0~1h) - 平静/压抑**
  * 背景渐变中心色: `#1E3F33` (深墨绿)
  * 背景边缘/光晕: `#0B1B15` (极暗绿)
* **阶段 2 (1~4h) - 焦虑/不耐烦**
  * 背景渐变中心色: `#8C4A19` (暗铁锈红/焦糖色)
  * 背景边缘/光晕: `#3A1E08` (深褐)
* **阶段 3 (>4h) - 无力/深渊**
  * 背景渐变中心色: `#4A1515` (血痂暗红)
  * 背景边缘/光晕: `#1A0505` (近乎纯黑)

### 2. CI 轴：边缘模糊 (Blur / 下沉感)
CI 不再主导主题色相，但仍可用于“下沉感”（边缘模糊）惩罚。
* **实现方式**: `ImageFilter.blur` / 外阴影 `blurRadius` 动态映射。
* **参数映射**:
  * `CI = 1.0` -> `sigma: 0.0` (边缘极其锐利)
  * `CI = 0.0` -> `sigma: 8.0` (边缘模糊，像沉入水底)

## 四、 文本对比度与排版规范 (Typography)
* **主计时器 (HH:mm:ss)**: `Colors.white` + `FontWeight.w900`，阴影使用纯黑（如 `color: Colors.black87, blurRadius: 12, offset: Offset(0, 4)`），严禁同色系投影。
* **状态副标题 & OS 漂浮文案**: `Colors.white.withOpacity(0.6)`（依赖白色+透明度在暗色背景上建立对比）。
* **【回了么？】底部挂件按钮**:
  * Border: `Border.all(color: Colors.white.withOpacity(0.3))`
  * Text: `Colors.white.withOpacity(0.8)`
  * Background: `Colors.transparent` 或 `Colors.black26`

## 五、 内心戏 (OS) 文本漂浮系统
在圆盘中心区域（跳动时间戳的周围或底部）实现的随机微交互。

* **组件构成**: 绝对定位的 `Text` Widget。
* **触发机制**: 在 `Running` 状态下，启动一个 `Timer.periodic`，每隔 `3 ~ 8` 秒随机触发一次。
* **动效组合 (Fade + Slide)**:
  1. **出现**: `Opacity` 从 0 到 0.4 (或更低，需隐蔽)，配合向上平移 `Offset(0, 0.2) -> Offset(0, 0)`，耗时 1000ms。
  2. **悬停**: 保持 2000ms。
  3. **消散**: `Opacity` 从 0.4 到 0，同时字号轻微变大（模拟气泡破裂），耗时 1500ms。
* **文本池抽取**:
  * 如果 `CI > 0.6`: 随机抽取 ["应该在忙吧", "到底在忙什么", "浪费时间", "又装死"]。
  * 如果 `CI <= 0.6`: 随机抽取 ["看见了为什么不回", "Ta 根本不在乎吧", "算了，不指望了", "没意思"]。
* **可读性约束**: 文案必须有中性暗色底（如黑色半透明胶囊）和轻微阴影，文字优先 `Colors.white.withOpacity(0.6)`，避免与背景渐变冲突。

## 六、 特殊交互反馈
* **点击【开始熬】**: 执行一次短暂的冲击波涟漪动效 (Ripple Effect)，然后立刻进入呼吸循环。
* **点击【回了么？】悬浮挂件**: 立即停止 `AnimationController`，将圆盘定格，执行 `Transform(rotate)` 翻转动画，进入 `Evaluating` 结算表单形态。

## 七、 布局健壮性修复 (Overflow)
* `DEBUG 控制台` 区域在小屏幕或键盘弹出时，需使用 `SingleChildScrollView` 或合适的约束（`Flexible` / `Expanded`）避免 `BOTTOM OVERFLOWED BY ... PIXELS`。
