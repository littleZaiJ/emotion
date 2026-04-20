🚀 Claude Code 开发指令集 (Project Clarity)
使用说明：

请确保你已经安装好 Flutter 环境。

打开你的 IDE (VS Code) 和 Claude 插件（或网页版）。

不要一次性把所有指令发给它。请按步骤（Step）发送，每完成一步，Check 代码无误后，再发下一步。

🛠️ Step 0: 注入项目灵魂 (Context Injection)
操作： 复制之前生成的 [Technical Spec: Project Clarity] (即上一轮回复中的 PRD 内容)，直接发送给 Claude。并附带以下话术：

Prompt:
"你好，我准备开发一个 Flutter App。这是项目的完整技术规格说明书 (Technical Spec)。请仔细阅读并理解项目的架构、数据库设计和核心业务逻辑。

暂时不要写任何代码，理解完成后，请回复：'Project Clarity 上下文已接收，准备就绪'。"

🏗️ Step 1: 脚手架与基础设施 (Scaffolding)
操作： 待它回复就绪后，发送以下指令。这步建立地基。

Prompt:
"现在开始 Step 1：初始化项目结构和依赖。

依赖管理： 请更新 pubspec.yaml，添加以下核心库（请使用兼容的最新版本）：

状态管理: flutter_riverpod, riverpod_annotation

代码生成: build_runner, riverpod_generator, isar_generator

数据库: isar, isar_flutter_libs

图表: fl_chart

路由: go_router

工具: intl, gap, google_fonts, uuid

目录结构： 请在 lib/ 下创建 Clean Architecture 风格的目录：

core/ (theme, utils, constants)

data/ (local, models, repositories)

features/ (dashboard, input, interaction, settings)

main.dart

基础配置：

配置 GoRouter 并创建基础路由表。

创建 AppTheme，定义一套‘金融终端’风格的暗黑主题（背景纯黑 #000000，主色高亮红 #FF2D55 和 荧光绿 #00E676）。"

💾 Step 2: 数据层与实体 (Data Layer)
操作： 只有数据结构对了，逻辑才跑得通。

Prompt:
"Step 2：实现数据层。我们需要使用 Isar 数据库。

定义实体 (Entities): 在 data/local/entities/ 下创建以下 Class：

Transaction: 包含字段 id, timestamp, type (enum: money, labor), monetaryAmount, laborDurationHours, hourlyRateSnapshot。请实现一个 getter totalValue 来计算实际价值。

Interaction: 包含 startTime, endTime, isCompleted。实现 getter waitDurationMinutes。

UserSettings: 包含 hourlyRate (默认 50.0) 和 dignityThresholdMin (默认 240)。

生成代码： 请指导我运行 build_runner 生成 Isar 的适配代码。

Repository: 创建 TransactionsRepository 和 InteractionsRepository，实现基本的 CRUD 操作（增加、查询当日数据、查询最近7天数据）。"

🧠 Step 3: 业务逻辑层 (Domain Logic)
操作： 这里是 App 的“大脑”。

Prompt:
"Step 3：实现业务逻辑 (Providers)。请使用 Riverpod Generator (@riverpod)。

SettingsLogic: 创建一个 Provider 管理用户设置（时薪），支持修改和持久化。

InputLogic:

创建一个 AddTransactionController。

实现核心逻辑：当用户选择‘劳务模式’输入时长时，自动根据 Settings 中的时薪计算 value。

TimerLogic:

创建一个 InteractionTimerNotifier。

实现状态机：Idle -> Running (记录 startTime) -> Finished (记录 endTime 并保存到数据库)。

实现‘红区检测’：如果 Running 时间超过 dignityThresholdMin，状态变为 Warning。"

🎨 Step 4: 核心 UI - 仪表盘 (Dashboard UI)
操作： 不需要原型图，用文字描述布局。

Prompt:
"Step 4：开发核心页面 DashboardScreen。UI 风格参考‘股票交易终端’，高对比度。

顶部 Header:

大字显示‘总情感赤字’ (Total Deficit)。

如果数值为负（投入>回馈），使用鲜红色 (#FF2D55)；否则使用绿色。

核心图表 (Chart):

使用 fl_chart 的 BarChart。

展示最近 7 天的每日 totalValue 投入。

背景要有网格线，去掉边框，保持极简科技感。

底部操作区:

放置两个并排的大按钮。

左边：‘记一笔’ (打开 Input Sheet)。

右边：‘回复计时器’ Widget (显示当前计时状态，如果超时显示红色背景警告)。"

📝 Step 5: 核心 UI - 记账弹窗 (Input Sheet)
操作： 实现那个“劳务折算”的关键功能。

Prompt:
"Step 5：开发 TransactionInputSheet (底部弹窗)。

顶部切换器: 使用 SegmentedButton 切换 [金钱投入] / [劳务付出]。

表单逻辑:

金钱模式: 显示金额输入框 + 类别标签 (红包/吃饭/礼物)。

劳务模式: 显示‘时长滑块’ (Slider) 和输入框。

核心交互: 在劳务模式下，当用户拖动滑块（例如 2.5小时），界面下方要实时大字显示：‘折合价值: ¥125.0’ (基于当前时薪计算)。

保存: 点击保存后，写入数据库并刷新仪表盘。"

💡 给你的 Check 建议 (如何验收)
每完成一个 Step，不要只看代码，要运行起来（flutter run）看效果。

Check Step 1: App 能跑起来，不报错，屏幕可能是黑的或空的。

Check Step 2: 运行 flutter pub run build_runner build 成功，生成 .g.dart 文件。

Check Step 3: 这一步是纯逻辑，看不到界面。你可以让 Claude 写一个简单的 Test 用例打印一下计算结果。

Check Step 4 (关键): 首页应该出来了。看看那个红绿配色是不是够“扎心”。

Check Step 5: 点开记账，试一下“劳务模式”，拖动滑块，看看钱数会不会自动变。如果会变，这个 MVP 就成功了一半。

❓ 为什么不需要原型图？
因为在这个 Prompt 中，我已经用文字把 UI 锁死了：

"股票交易终端风格" -> 它知道要用黑底、红绿、大数字。

"SegmentedButton" -> 它知道要用分段选择器。

"BarChart" -> 它知道要画柱状图。

对于 Claude 这种级别的 AI，这种结构化的文字指令比模糊的手绘图更精准。你可以先试着用这套指令跑一遍，看看生成的 UI 是否符合你心中的“冤种”气质。如果不满意，再截图让它微调即可