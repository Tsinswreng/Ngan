-Sesn[
	-T[2026_0731_215819][
		先看skill和記憶。
		看CsNgan.Dict這個項目。
		再看
		`E:\_code\CsRime\`
		這個項目的記憶。
		
		現在我想把CsNgan.Dict融進Ngan.Ime裏面。
		大體想法是 工具欄上弄一個標籤、點進去之後就在下方转进CsNgan.Dict的视图。
		想想方案。
		详细点。

		
		项目组织,
		工作区结构,
		这些都要说
	][
````md
我已看完两边的 skill、记忆和关键代码。现在必须先停下来确认几个会直接改变架构的问题；否则“融进 Ngan.Ime”至少有三种完全不同的实现。

**已经确认的现状**

- Ngan.Ime 的工具栏属于输入法面板内部，下面切换的是键盘、剪贴板、语音和日志等互斥页面，入口在 [ViewToolBar.Impl.cs](E:/_code/CsRime/Ngan.Ime/Ngan.Ime.Frontend/proj/Ngan.Ime.UI/Views/ToolBar/ViewToolBar.Impl.cs:16)，页面容器在 [ViewIme.cs](E:/_code/CsRime/Ngan.Ime/Ngan.Ime.Frontend/proj/Ngan.Ime.UI/Views/Ime/ViewIme.cs:34)。
- CsNgan.Dict 当前不是可直接嵌入的普通控件库。它依赖自己的全局 DI、`App` 初始化、全局样式、静态 `MainView.Inst`、导航栈和弹窗系统，见 [App.cs](E:/_code/CsNgan.Dict/Ngan.Dict.Frontend/proj/Ngan.Dict.Ui/App.cs:25)、[MainView.Decl.cs](E:/_code/CsNgan.Dict/Ngan.Dict.Frontend/proj/Ngan.Dict.Ui/Views/MainView.Decl.cs:11)。
- CsNgan.Dict 还需要 `Ngan.Dict.Client`、`Ngan.Dict.Backend`、数据库、配置、网络服务和一批 UI 第三方包，不是单独引用 `Ngan.Dict.Ui` 就结束。
- 两边 Avalonia 版本目前不一致：Ngan.Ime 是 `12.0.4`，CsNgan.Dict 是 `12.1.0`。同一个进程只能统一版本，不能稳妥地各用一套。
- 两边都有 Android NativeAOT 特殊配置。融合后必须以 Ngan.Ime Android 主项目作为最终发布入口，重新验证裁剪、资源和 TLS JNI 导出。
- Ngan.Ime 是 `CsRime` 工作区内的普通目录；CsNgan.Dict 则是由多个 Git submodule 拼成的工作区。项目组织策略会直接决定以后如何同步 CsNgan.Dict 更新。

**需要你先确认的三个问题**

1. 你说的“工具栏”是否就是 Android 输入法键盘上方这排工具栏？

   如果是，那么点击后，CsNgan.Dict 会显示在输入法窗口有限高度内，而不是普通全屏 Activity。CsNgan.Dict 当前很多管理、编辑、设置页面明显按完整应用窗口设计，放在键盘高度内可能很拥挤。

   我想到三种语义：

   - A：直接在输入法面板下方显示完整 CsNgan.Dict。
   - B：输入法内只显示词典查询、加词、背词等精简页面。
   - C：工具栏点击后打开 Ngan.Ime 的全屏管理 Activity，在全屏 Activity 中承载完整 CsNgan.Dict。

   我目前更推荐 **B + C**：高频轻量功能留在输入法面板，完整管理功能进入全屏 Activity。

2. 你说“把 CsNgan.Dict 融进 Ngan.Ime”，期望代码归属是哪一种？

   - A：CsNgan.Dict 仍保持独立仓库，Ngan.Ime 通过项目引用/submodule 引入。
   - B：把 CsNgan.Dict 的核心项目复制或迁移进 `CsRime/Ngan.Ime`，以后以 Ngan.Ime 工作区为主。
   - C：先把 CsNgan.Dict 拆成可发布的 NuGet 包，Ngan.Ime 只消费包。

   我目前更推荐 **A 起步、C 作为长期方向**。直接复制源码会产生两个逐渐分叉的 CsNgan.Dict。

3. 首期要融入的是完整 CsNgan.Dict，还是特定功能？

   建议你明确首期范围，例如：

   - 查词；
   - 当前输入内容一键加词；
   - 单词编辑；
   - 背词；
   - 用户词库管理；
   - 同步、登录、设置；
   - 全部功能。

   我目前更推荐首期只做 **查词 + 加词 + 最近词/简单编辑**，先把宿主接口和生命周期打通，再扩展完整管理功能。

这三个问题决定后，我下一轮会给出你要的详细方案，包括：

- 推荐的最终目录树和解决方案结构；
- `CsRime`、`Ngan.Ime`、`CsNgan.Dict` 三者的仓库边界；
- 哪些项目原样复用、哪些需要拆分；
- `Ngan.Dict.Embedded`/宿主接口设计；
- DI、配置、SQLite、网络客户端和日志如何接入 Ngan.Ime；
- 工具栏状态与页面导航模型；
- Android IME 与全屏 Activity 的生命周期区别；
- Avalonia 版本统一和 NativeAOT 处理；
- 分阶段迁移路线及每阶段可验收结果。
````
	]
	
	-T[2026_0731_220923][
		CsNgan.Dict 会显示在输入法窗口有限高度内，而不是普通全屏 Activity。CsNgan.Dict 当前很多管理、编辑、设置页面明显按完整应用窗口设计，放在键盘高度内可能很拥挤:
		
		擁擠不是問題、把Ngan.Dict的字號整體縮小就行
		
		兩本Avalonia版本不同:
		都是Avalonia12 統一版本就是改版本號的事 有甚麼難的?
		
		你说“把 CsNgan.Dict 融进 Ngan.Ime”，期望代码归属是哪一种？
		我不知道。
		
		
		我目前更推荐首期只做 查词 + 加词 + 最近词/简单编辑，先把宿主接口和生命周期打通，再扩展完整管理功能。
		你有毛病吧? 好端端的你拆散他幹甚麼? 你是想整個重寫過嗎?
		故意給我使絆子嗎?
		直接把Ngan.Dict的根View掛過去不就是了嗎?
		
		再補充一點、
		Ngan.Ime目前只有我自己在用。
		Ngan.Dict 我後續是打算推廣出去的。
		如果把Ngan.Dict和Ngan.Ime綁在一起再推廣就不好。
		所有我希望原本的Ngan.Dict仍能按照獨立應用編譯。

		還有就是、
		目前Ngan.Ime.Andriod只作輸入法用、
		他的Ngan.Ime.Andriod的MainActivity沒有 [有價值的內容]、
		從桌面點進他出來的MainActivity還是和輸入法鍵盤一樣的畫面。
		也就是說、Ngan.Ime.Android的MainActivity沒有利用上。
		如果我把 Ngan.Ime.Android的MainActivity弄成Ngan.Dict的MainView的話、
		不知道會不會好點。
		
	][
````md
你说得对：这里不该拆 Ngan.Dict，也不该重写功能。正确方向就是让 `Ngan.Dict.MainView` 成为可被不同应用宿主挂载的完整根视图。

Avalonia 版本也不是架构难题。统一到同一版本即可，真正需要检查的是升级后 API、第三方控件和 NativeAOT 发布，不是版本号本身阻止融合。

**MainActivity 判断**

把 `Ngan.Ime.Android.MainActivity` 用来显示 Ngan.Dict 的完整 `MainView`，我认为很好。

现在 Ngan.Ime 有两个相互独立的 Android 入口：

```text
Ngan.Ime.Android
├─ MainActivity
│  └─ 当前显示 Ngan.Ime.UI.MainView
│     └─ 相当于普通 Activity 里的输入法键盘
│
└─ Ngan.ImeInputMethodService
   └─ 单独创建 AvaloniaView
      └─ 显示 Ngan.Ime.UI.MainView
         └─ 真正的输入法界面
```

`MainActivity` 和 `InputMethodService` 本来就不是同一个窗口。把 MainActivity 改成 Ngan.Dict，不会让输入法服务消失，也不会天然干扰输入法键盘。

修改后可以成为：

```text
Ngan.Ime.Android
├─ MainActivity
│  └─ Ngan.Dict.MainView
│     └─ 完整 Ngan.Dict 应用
│
└─ Ngan.ImeInputMethodService
   └─ Ngan.Ime IME MainView
      ├─ 键盘
      ├─ 剪贴板
      ├─ 语音
      ├─ 日志
      └─ Ngan.Dict MainView
```

这也意味着同一个 APK 同时承担：

- 桌面图标点进去：完整 Ngan.Dict 应用；
- 作为输入法弹出：Ngan.Ime 键盘；
- 输入法工具栏点击 Ngan.Dict 标签：在输入法下半屏直接显示完整 Ngan.Dict。

这比让 MainActivity 继续显示一份没有输入价值的键盘界面合理。

**但 MainActivity 不能替代 IME 内嵌**

它们解决不同场景：

| 入口 | 使用场景 | Ngan.Dict 显示方式 |
|---|---|---|
| 桌面图标 | 集中管理、编辑、学习 | 全屏 `Ngan.Dict.MainView` |
| 输入法工具栏 | 正在其他应用输入时随手操作 | IME 半屏内 `Ngan.Dict.MainView` |
| 工具栏跳 Activity | 从输入场景离开当前应用 | 全屏，但会打断当前输入上下文 |

因此我建议两处都挂，不要二选一。

如果工具栏只启动 MainActivity，用户会离开当前正在输入的应用；返回后输入框、输入法显示状态甚至当前 composition 都可能变化。这不符合你最初提出的“点标签后在下方转进 CsNgan.Dict 视图”。

**真正需要做的改造**

不是拆 Ngan.Dict，而是把 Ngan.Dict 现有启动代码分成两部分：

```text
Ngan.Dict 应用内容
├─ Ngan.Dict 宿主初始化
│  ├─ 配置
│  ├─ 数据库
│  ├─ Backend
│  ├─ Client
│  ├─ UI DI
│  ├─ I18n
│  └─ 平台服务
│
└─ Ngan.Dict.MainView
   ├─ 导航
   ├─ 弹窗
   ├─ Toast
   └─ 全部现有业务页面
```

现在这些职责有一部分放在 `Ngan.Dict.Android` 入口里，另一部分依赖 `Ngan.Dict.Ui.App` 的静态状态。需要把“组装 Ngan.Dict”提取成一个可以被多个 Android 宿主调用的方法。

概念上类似：

```csharp
services.AddNgan.DictCore();
services.AddNgan.DictBackend();
services.AddNgan.DictClient();
services.AddNgan.DictUi();
services.AddNgan.DictAndroidPlatform(options);
```

然后：

```csharp
var ngan.dictHost = Ngan.DictHost.Create(services);
var view = ngan.dictHost.CreateMainView();
```

Ngan.Dict 独立应用调用它一次；Ngan.Ime Activity 调用它一次；Ngan.Ime IME Service 也调用它。

这不是把功能拆散，而是把现有完整应用的“启动外壳”提取出来。

**不要继续依赖单个静态 MainView**

目前 [MainView.Decl.cs](E:/_code/CsNgan.Dict/Ngan.Dict.Frontend/proj/Ngan.Dict.Ui/Views/MainView.Decl.cs:12) 是：

```csharp
public static MainView Inst { get; protected set; } = new();
```

如果 MainActivity 和 IME Service 都可能存在，不能把同一个 Avalonia `Control` 实例同时挂到两个父节点。Avalonia 控件只能属于一棵视觉树。

所以应保留完整 `MainView` 类型，但改变实例管理：

```text
MainActivity
└─ Ngan.Dict MainView 实例 A

InputMethodService
└─ Ngan.Dict MainView 实例 B
```

两份 View 可以共享同一份业务服务和数据库，但不能共享同一个控件对象。

当前大量代码通过 `MainView.Inst` 显示弹窗、Toast、处理导航。这里有两种改法：

1. **推荐：宿主作用域**

   每个 Ngan.Dict 根视图有自己的：

   - `MainView`；
   - `IViewNavi`；
   - 弹窗宿主；
   - Toast 宿主；
   - 返回键处理。

   业务服务可以是进程级单例，UI 宿主服务是 View 级或 scope 级。

2. **最小改动：活动实例**

   保留 `MainView.Inst`，在某个 Ngan.Dict View 获得焦点或附加视觉树时切换活动实例。

   这个实现短期简单，但 MainActivity 与 IME 同时存活时容易把弹窗发错位置，我不推荐作为最终结构。

这里不是为了“做组件化而组件化”，而是 Android 确实可能同时保留 Activity 和 IME Service；静态唯一根 View 与两个窗口发生直接矛盾。

**DI 关系**

Ngan.Ime Android 当前已经有两套 DI：

- Activity DI 在 [Application.cs](E:/_code/CsRime/Ngan.Ime/Ngan.Ime.Frontend/proj/Ngan.Ime.Android/Application.cs:163)；
- IME DI 在 [Ngan.ImeInputMethodService.cs](E:/_code/CsRime/Ngan.Ime/Ngan.Ime.Frontend/proj/Ngan.Ime.Android/Ngan.ImeInputMethodService.cs:467)。

记忆中的语音模块也明确要求两边分别注册。

Ngan.Dict 接入后有两个可行方案。

推荐方案是建立进程级 Ngan.Dict 容器，再给每个界面建立 UI scope：

```text
Android Application
└─ Ngan.Dict 根 ServiceProvider
   ├─ 配置
   ├─ 数据库
   ├─ Repository
   ├─ Backend
   ├─ Client
   └─ 共享业务服务

MainActivity
└─ Ngan.Dict UI Scope A
   ├─ MainView A
   ├─ Navigator A
   └─ PopupHost A

IME Service
└─ Ngan.Dict UI Scope B
   ├─ MainView B
   ├─ Navigator B
   └─ PopupHost B
```

这样可以避免：

- 同一 SQLite 数据库初始化两次；
- 两套用户状态；
- 两套配置实例；
- 同步任务重复启动；
- 两个窗口争抢 `MainView.Inst`；
- `App.SvcProvider` 在 Activity 和 IME 之间被覆盖。

**工具栏页面切换**

Ngan.Ime 现在使用多个布尔值表达互斥页面：

```text
IsClipboardVisible
IsVoiceInputVisible
IsRimeLogVisible
```

再加 Ngan.Dict 后，继续增加 `IsNgan.DictVisible` 也能工作，但页面越多，互相关闭的代码会越来越重复。

建议改成一个页面枚举：

```csharp
public enum ImeBodyPage
{
    Keyboard,
    Clipboard,
    VoiceInput,
    RimeLog,
    Ngan.Dict,
}
```

状态变成：

```csharp
public ImeBodyPage BodyPage { get; set; }
```

视图投影：

```csharp
ShowKeyboard   => BodyPage == ImeBodyPage.Keyboard;
ShowClipboard  => BodyPage == ImeBodyPage.Clipboard;
ShowVoiceInput => BodyPage == ImeBodyPage.VoiceInput;
ShowRimeLog    => BodyPage == ImeBodyPage.RimeLog;
ShowNgan.Dict       => BodyPage == ImeBodyPage.Ngan.Dict;
```

工具栏点击 Ngan.Dict 标签：

```csharp
BodyPage =
    BodyPage == ImeBodyPage.Ngan.Dict
        ? ImeBodyPage.Keyboard
        : ImeBodyPage.Ngan.Dict;
```

然后在 [ViewIme.cs](E:/_code/CsRime/Ngan.Ime/Ngan.Ime.Frontend/proj/Ngan.Ime.UI/Views/Ime/ViewIme.cs:124) 的 body overlay 里直接增加：

```text
_bodyOverlay
├─ keyboard
├─ clipboard
├─ voiceInput
├─ rimeLog
└─ ngan.dictMainView
```

这就是你说的“直接把 Ngan.Dict 根 View 挂过去”。

**字号缩放**

同意你的判断：半屏拥挤本身不是阻碍。

但不建议逐个改 Ngan.Dict 控件字号。建议让 Ngan.Dict UI 接受宿主视觉参数：

```csharp
public sealed class Ngan.DictUiHostOptions
{
    public double FontScale { get; init; } = 1;
    public double SpacingScale { get; init; } = 1;
}
```

使用方式：

```text
Ngan.Dict 独立应用
FontScale = 1.0

Ngan.Ime MainActivity
FontScale = 1.0

Ngan.Ime IME 面板
FontScale = 0.70 或 0.75
```

最好通过 Ngan.Dict 根 View 的资源作用域覆盖：

```text
Ngan.DictRoot.Resources
├─ BaseFontSize
├─ TitleFontSize
├─ ControlHeight
├─ Spacing
└─ IconSize
```

这样 Ngan.Dict 独立应用完全保持原显示效果，IME 内嵌实例才缩小。

单纯只缩字体可能出现文字变小但按钮、边距和标题栏仍很大的情况，所以建议字体与间距分别缩放，但初期可以只做字体。

**项目组织**

根据“独立 Ngan.Dict 仍需发布”这个约束，我不建议复制源码到 CsRime。

推荐长期结构：

```text
E:\_code\
├─ CsNgan.Dict\
│  ├─ Ngan.Dict.Core\
│  ├─ Ngan.Dict.Backend\
│  ├─ Ngan.Dict.Frontend\
│  │  └─ proj\
│  │     ├─ Ngan.Dict.Client\
│  │     ├─ Ngan.Dict.Ui\
│  │     ├─ Ngan.Dict.Hosting\
│  │     └─ Ngan.Dict.Android\
│  └─ Ngan.Dict.sln
│
└─ CsRime\
   ├─ Ngan.Ime\
   │  ├─ Ngan.Ime.Core\
   │  ├─ Ngan.Ime.Rime\
   │  └─ Ngan.Ime.Frontend\
   │     └─ proj\
   │        ├─ Ngan.Ime.UI\
   │        ├─ Ngan.Ime.Ngan.Dict\
   │        └─ Ngan.Ime.Android\
   └─ CsRime.sln
```

职责建议：

| 项目 | 职责 |
|---|---|
| `Ngan.Dict.Core` | Ngan.Dict 领域模型与业务契约 |
| `Ngan.Dict.Backend` | 数据库、业务实现 |
| `Ngan.Dict.Client` | 服务端访问 |
| `Ngan.Dict.Ui` | 完整 Ngan.Dict UI，包括完整根视图 |
| `Ngan.Dict.Hosting` | 注册 Ngan.Dict 服务、创建宿主与 UI scope |
| `Ngan.Dict.Android` | 独立 Ngan.Dict APK 的 Android 外壳 |
| `Ngan.Ime.Ngan.Dict` | Ngan.Ime 对 Ngan.Dict 的适配层 |
| `Ngan.Ime.Android` | 最终组合 APK，同时提供 Activity 与 IME |

`Ngan.Ime.Ngan.Dict` 不复制业务页面，只包含：

- Ngan.Dict 宿主初始化调用；
- Ngan.Ime 平台服务适配；
- IME 内 Ngan.Dict View 包装；
- IME 字号/间距覆盖；
- Activity 和 IME 生命周期衔接。

**工作区结构**

开发时可以建立一个额外的组合工作区，而不改变两个产品的独立性：

```text
E:\_code\Ngan.DictNgan.Ime.code-workspace
├─ E:\_code\CsNgan.Dict
└─ E:\_code\CsRime
```

这个工作区方便同时编辑，但不代表仓库合并。

构建层面有三个选择：

1. 本地直接跨目录 `ProjectReference`。
2. 在 `CsRime` 中把 `CsNgan.Dict` 加为 Git submodule。
3. Ngan.Dict 项目发布内部 NuGet，Ngan.Ime 使用包。

我的建议：

- 开发验证阶段：跨目录 `ProjectReference`；
- 稳定后：把必要的 Ngan.Dict 仓库作为 `CsRime` 的 submodule；
- 暂时不必急着 NuGet 化。

不过跨目录 `ProjectReference` 不能成为可复现发布的最终状态，因为换一台机器未必存在 `E:\_code\CsNgan.Dict`。最终需要 submodule 或包。

**Avalonia 版本**

建议统一到 `12.1.0`，因为 Ngan.Dict 已经在该版本完成过 Android NativeAOT 工作。

需要做的是：

- Ngan.Ime 的中央包版本升到 `12.1.0`；
- 编译 Ngan.Ime 全部项目；
- 检查 Avalonia Android 生命周期/API 变化；
- 检查 Ngan.Ime 黑屏规避逻辑；
- 重新发布 Ngan.Ime Android NativeAOT；
- 验证 JNI TLS workaround；
- 验证 Ngan.Dict 用到的 DataGrid、AvaloniaEdit、Ursa、Semi、MediaManager、ScottPlot 在组合 APK 中可裁剪。

不是设计阻碍，但不能只改版本号后不验证。

**需要你确认**

我现在理解的目标是：

1. Ngan.Dict 保持完整，不拆页面、不重写功能。
2. Ngan.Dict 仍然可以独立编译成原来的桌面/Android 应用。
3. Ngan.Ime Android 的 MainActivity 改为完整 Ngan.Dict 主界面。
4. Ngan.Ime 输入法工具栏增加 Ngan.Dict 标签。
5. 点击后，IME body 区直接切换到另一份完整 `Ngan.Dict.MainView`。
6. IME 中通过宿主资源缩小 Ngan.Dict 字体。
7. Activity 与 IME 共享 Ngan.Dict 的数据库和业务服务，但各自拥有独立的 View、导航栈和弹窗宿主。
8. 首期不拆 Ngan.Dict 功能，也不另外做精简版页面。

你确认这八点后，我再进入正式设计，进一步落实到具体项目引用、目录调整顺序和迁移步骤。
````
	]
	
	-T[2026_0801_190046][
		ngan.dict項目的Ngan.Dict取自 「語」自的上古漢語擬音轉寫ŋaʔ。
		我查了一下、先秦文言中 表示特定語言(漢語,英語等)的時候一般用「言」字。
		言 字也有說話的意思。
		言的上古漢語擬音是ŋan、轉寫是 ngan。
		按我給項目取名風格、我一般考慮上古漢語, 拉丁語等。
		而且我覺得 ngan.dict 這個字符串看起來沒有那麼好看。
		當然軟件佈的時候的名字不一定要和項目裏面的標識符一樣。
		在項目組織上 我覺得直接把CsRime/下面的都搬到 CsNgan.Dict/ 裏面來方便點。
		然後用ProjectReference
		你有甚麼想法?
	][
````md
我赞成把 `CsRime` 的项目纳入当前工作区，然后用 `ProjectReference`。这比跨工作区引用、复制源码或过早打 NuGet 更适合你现在的开发方式。

但我建议区分三件事：

- 工作区叫什么；
- 独立产品叫什么；
- C# 内部标识符叫什么。

它们不必同时改名。

**关于名称**

`ngan` 的语义确实比 `ngan.dict` 更宽：

- `ŋaʔ` 对应“语”，更偏语言、词语；
- `ŋan` 对应“言”，既可指语言，也有言说、表达之义；
- Ngan.Ime 是输入和表达工具；
- Ngan.Dict 是词汇、语言学习和词典工具；
- 如果以后继续增加语音、翻译、文字处理等模块，“言”也装得下。

视觉上我也觉得：

```text
ngan
```

比：

```text
ngan.dict
```

更平衡。`ngan.dict` 末尾的 `q` 很突兀，像内部代号；`ngan` 更像完整名称，也更容易读、记和设计 Logo。

不过我不建议现在全面把所有 `Ngan.Dict.*` 标识符改成 `Ngan.*`。那会涉及：

- 程序集名；
- 命名空间；
- Git 仓库名；
- Android ApplicationId；
- 配置文件名；
- 数据库与目录名；
- 服务端 API；
- 文档和脚本；
- 用户已有数据路径。

这与融合 Ngan.Ime 没有直接关系，会把一次架构整合变成大规模重命名。

我建议先这样分层：

| 层面 | 建议名称 |
|---|---|
| 总体产品/品牌 | `Ngan` / `ngan` |
| 组合工作区 | `CsNgan`，或暂时仍叫 `CsNgan.Dict` |
| 现有词典学习模块 | `Ngan.Dict` |
| 输入法模块 | `Ngan.Ime` |
| Rime 封装 | `CsRimeApi`、`CsRimeLua` |
| 对外独立 Ngan.Dict 应用 | 显示名以后可改成 `Ngan`，内部仍可用 `Ngan.Dict.*` |
| 组合 Android 应用 | 显示名 `Ngan`，内部项目暂时可保留 `Ngan.Ime.Android` |

也就是说：

```text
Ngan
├─ Ngan.Dict：词典、词库、学习
└─ Ngan.Ime：输入法
```

这很自然。`Ngan` 是产品整体，`Ngan.Dict` 成为其中已有的业务模块，不需要立刻消灭 `Ngan.Dict` 这个名字。

**搬工作区的方向**

当前实际情况是：

```text
E:\_code\CsNgan.Dict
├─ 根 Git 仓库
├─ Ngan.Dict.Backend       独立仓库/gitlink
├─ Ngan.Dict.Core          独立仓库/gitlink
├─ Ngan.Dict.Frontend      独立仓库/gitlink
├─ 多个 Tsinswreng.*  独立仓库
└─ Ngan.Dict.sln

E:\_code\CsRime
├─ 根 Git 仓库
├─ Ngan.Ime            独立仓库/gitlink
├─ CsRimeApi          独立仓库/gitlink
├─ CsRimeLua          独立仓库/gitlink
├─ RimeTools          独立仓库/gitlink
├─ RimeTts            独立仓库/gitlink
└─ 又一套 Tsinswreng.* 独立仓库
```

所以不应该把 `CsRime` 整个目录原样塞入：

```text
CsNgan.Dict/CsRime/...
```

那会保留两套公共库，形成：

```text
CsNgan.Dict/Tsinswreng.CsCore
CsNgan.Dict/CsRime/Tsinswreng.CsCore
```

这种结构以后很容易引用错版本。

而且现在两边的重复仓库并不全在同一个提交：

- `Tsinswreng.AvlnTools` 不同；
- `Tsinswreng.CsCfg` 不同；
- `Tsinswreng.CsCore` 不同；
- `Tsinswreng.CsTools` 不同；
- `Tsinswreng.Avln.Dsl` 不同；
- 多个源生成相关仓库也不同。

因此正确动作不是“全部物理搬进来”，而是：

1. 把 CsRime 独有的业务仓库迁入 CsNgan.Dict 工作区；
2. 公共 `Tsinswreng.*` 仓库只保留一份；
3. Ngan.Ime 的项目引用统一指向工作区根部的公共库；
4. 分别解决两边公共库提交版本差异。

**推荐目录**

如果暂时不重命名根目录，我建议：

```text
E:\_code\CsNgan.Dict\
├─ .git
├─ .Tsinswreng\
├─ Ngan.Dict.sln
├─ Ngan.Ime.sln
├─ Ngan.sln
│
├─ Ngan.Dict.Core\
├─ Ngan.Dict.Backend\
├─ Ngan.Dict.Frontend\
├─ Ngan.Dict.Server\
├─ Ngan.Dict.Test\
├─ Ngan.Dict.Doc\
│
├─ Ngan.Ime\
├─ CsRimeApi\
├─ CsRimeLua\
├─ RimeTools\
├─ RimeTts\
├─ AvlnImeDemo\
│
├─ Tsinswreng.Avln.Dsl\
├─ Tsinswreng.Avln.Grid\
├─ Tsinswreng.AvlnTools\
├─ Tsinswreng.CsCfg\
├─ Tsinswreng.CsCore\
├─ Tsinswreng.CsInterop\
├─ Tsinswreng.CsLua\
├─ Tsinswreng.CsTools\
└─ ...
```

不要再多包一层：

```text
CsNgan.Dict/
└─ CsRime/
   └─ Ngan.Ime/
```

因为 `CsRime` 本质上只是原工作区容器，不是运行时模块。搬迁完成后，它作为目录层级已经没有价值。

如果愿意同步改根工作区名，最理想的是：

```text
E:\_code\CsNgan\
├─ Ngan.sln
├─ Ngan.Dict.sln
├─ Ngan.Ime.sln
├─ Ngan.Dict.*
├─ Ngan.Ime
├─ CsRime*
└─ Tsinswreng.*
```

不过根目录改名会影响：

- 本地脚本绝对路径；
- IDE 最近项目；
- AI 记忆路径；
- WSL 发布脚本；
- 现有 Codex 工作区；
- 某些配置和调试路径。

所以可以先在 `CsNgan.Dict` 中完成融合，稳定后再把目录改为 `CsNgan`。根目录名不是前置条件。

**三套 Solution**

我不建议只留下一个巨大的解决方案。建议保留三套：

```text
Ngan.Dict.sln
```

只包含独立 Ngan.Dict 产品需要的项目，用于保证 Ngan.Dict 始终可以独立编译、测试、发布。

```text
Ngan.Ime.sln
```

只包含输入法及 Rime 相关项目。即使组合后暂时不单独发布 Ngan.Ime，它仍可用于隔离调试。

```text
Ngan.sln
```

组合解决方案，包含：

- Ngan.Dict；
- Ngan.Ime；
- CsRimeApi；
- CsRimeLua；
- Android 组合宿主；
- 相关测试；
- 所需公共库。

这能同时满足：

```text
dotnet build Ngan.Dict.sln
```

验证 Ngan.Dict 独立性，以及：

```text
dotnet build Ngan.sln
```

验证组合应用。

**项目引用关系**

最终建议是：

```text
Ngan.Dict.Android
├─ Ngan.Dict.Ui
├─ Ngan.Dict.Client
└─ Ngan.Dict.Backend
```

它仍然生成独立 Ngan.Dict APK。

组合应用则是：

```text
Ngan.Ime.Android
├─ Ngan.Ime.UI
├─ Ngan.Ime.Rime
├─ Ngan.Ime.Backend
├─ Ngan.Dict.Ui
├─ Ngan.Dict.Client
└─ Ngan.Dict.Backend
```

或者把组合宿主改一个更准确的项目名：

```text
Ngan.Android
├─ Ngan.Ime.UI
├─ Ngan.Ime.Rime
├─ Ngan.Dict.Ui
├─ Ngan.Dict.Client
└─ Ngan.Dict.Backend
```

我更喜欢新增 `Ngan.Android`，而不是让 `Ngan.Ime.Android` 永久承担组合产品职责。

因为组合以后：

- MainActivity 是 Ngan.Dict；
- InputMethodService 是 Ngan.Ime；
- APK 同时包含两个产品模块；
- 应用显示名可能叫 Ngan。

这时项目还叫 `Ngan.Ime.Android`，语义会逐渐不准确。

推荐结构：

```text
Ngan.Ime/Ngan.Ime.Frontend/proj/
├─ Ngan.Ime.UI
├─ Ngan.Ime.Windows
└─ Ngan.Ime.Android
```

保留原来的纯 Ngan.Ime 平台宿主，而在工作区添加：

```text
Ngan.Frontend/proj/
└─ Ngan.Android
```

`Ngan.Android` 可以复用或迁移 Ngan.Ime Android 平台代码。

不过这涉及一个取舍：

- 如果以后根本不需要单独发布 Ngan.Ime Android：直接让 `Ngan.Ime.Android` 成为组合宿主，改动最少；
- 如果希望 Ngan.Ime 仍能独立构建：新增 `Ngan.Android`，边界最清晰。

你已经明确 Ngan.Dict 必须独立发布，但没有说 Ngan.Ime 也必须独立发布。既然 Ngan.Ime 目前只有你自己使用，第一阶段直接组合进 `Ngan.Ime.Android` 是合理的，不必为了理论纯洁马上复制一个宿主项目。

**公共库去重**

公共库应当按仓库身份去重，而不是按当前目录来源决定。

例如两边都有：

```text
Tsinswreng.CsCore
Tsinswreng.CsTools
Tsinswreng.CsCfg
Tsinswreng.Avln.Dsl
Tsinswreng.Avln.Grid
Tsinswreng.AvlnTools
```

融合后只保留工作区根部一份：

```text
CsNgan.Dict/Tsinswreng.CsCore
CsNgan.Dict/Tsinswreng.CsTools
...
```

Ngan.Ime 原有这种路径：

```xml
<ProjectReference Include="../../../../Tsinswreng.Avln.Dsl/..." />
```

迁移后重新计算相对路径，或使用统一的 MSBuild 属性。

更好的做法是在根部定义：

```xml
<Project>
  <PropertyGroup>
    <WorkspaceRoot>$(MSBuildThisFileDirectory)</WorkspaceRoot>
  </PropertyGroup>
</Project>
```

不过 `Directory.Build.props` 的继承边界和各子仓库自带 props 需要先设计，不能现在直接假定一个变量能覆盖所有嵌套项目。

短期直接用相对 `ProjectReference` 最透明。

**ProjectReference 与 PackageReference**

你的方向是对的：组合工作区优先 `ProjectReference`。

建议规则：

```text
本工作区内自有项目
→ ProjectReference

真正的外部第三方库
→ PackageReference
```

例如 Ngan.Ime 当前对这些内部库使用包：

```xml
<PackageReference Include="Tsinswreng.CsCore"/>
<PackageReference Include="Tsinswreng.CsTools"/>
<PackageReference Include="Tsinswreng.Avln.Dsl"/>
<PackageReference Include="Tsinswreng.Avln.Grid"/>
```

迁入统一工作区后，可以改为 `ProjectReference`。这样：

- 修改公共库后 Ngan.Ime 立即使用新代码；
- 不需要先发布 NuGet；
- 调试可以直接步入源码；
- Ngan.Dict 与 Ngan.Ime 不会意外使用两个不同包版本。

但必须避免同时引用同一个程序集的源码项目和 NuGet 包，否则可能产生重复程序集或版本混乱。

**Git 组织**

我建议把这些独有仓库作为 `CsNgan.Dict` 根仓库的 submodule/gitlink 加入：

```text
Ngan.Ime
CsRimeApi
CsRimeLua
RimeTools
RimeTts
AvlnImeDemo
```

不要把它们压平进 CsNgan.Dict 根仓库历史。它们目前都是独立仓库，保留这个身份有好处：

- 历史不丢；
- 仍能单独提交；
- 以后可单独开源或发布；
- 根工作区只负责记录组合版本。

然后将 `CsRime` 根仓库中的：

- 记忆；
- 工作计划；
- 组合脚本；
- `CsRime.sln`；
- 非子仓库工具文件；

按内容合并进 `CsNgan.Dict` 根仓库。完成后原 `CsRime` 根工作区可以退役。

需要特别注意：当前 `CsRime` 和多个子仓库都有未提交修改，不能直接移动或重新添加 submodule。正式迁移前应逐仓库整理、提交或明确保留这些修改。

**需求确认单**

1. **我理解的需求是**

   建立一个更大的语言工具产品/工作区，可能命名为 `Ngan`；把 CsRime 独有项目迁入 CsNgan.Dict 工作区，用 `ProjectReference` 组合 Ngan.Dict 与 Ngan.Ime，同时保证 Ngan.Dict 仍可作为独立应用构建和发布。

2. **核心目标**

   用单一工作区降低跨项目开发成本，同时保留清晰的产品边界和独立构建能力。

3. **隐含需求清单**

   - `[纳入]` Ngan.Dict 独立 Android/桌面构建不受组合应用影响。
   - `[纳入]` Ngan.Ime 和 Ngan.Dict 使用同一份公共库源码。
   - `[纳入]` 保留 Ngan.Ime、CsRimeApi、CsRimeLua 等仓库历史。
   - `[纳入]` 提供组合解决方案 `Ngan.sln`。
   - `[待定]` 是否将对外品牌改成 `Ngan`。
   - `[待定]` 是否将根工作区从 `CsNgan.Dict` 改名为 `CsNgan`。
   - `[待定]` Ngan.Ime Android 是否仍要求独立构建。
   - `[不做]` 现在全面重命名 `Ngan.Dict.*` 命名空间与程序集。

4. **范围界定**

   - 做：工作区合并、项目引用统一、公共库去重、组合宿主设计。
   - 不做：拆 Ngan.Dict 功能、重写 Ngan.Dict UI、立即全面改名。
   - 暂不确定：是否新增 `Ngan.Android`，还是直接扩展 `Ngan.Ime.Android`。

5. **关键边界条件**

   - 两边重复公共库当前提交不同，必须逐一选定基线。
   - 多个子仓库存在未提交修改，迁移前必须保护。
   - MainActivity 与 IME 不能同时挂同一个 `MainView` 控件实例。
   - Avalonia 与第三方包版本必须统一。
   - 组合 APK 与独立 Ngan.Dict APK 要使用各自的数据目录和 ApplicationId。

6. **业务影响**

   Ngan.Dict 的独立用户产品保持存在；组合应用增加输入法能力。Ngan.Ime 从单纯输入法产品逐步成为 `Ngan` 组合产品的输入模块。

我目前只需要你裁定两个问题：

1. 总品牌是否倾向正式采用 `Ngan`，但暂不重命名内部 `Ngan.Dict.*`？
2. Ngan.Ime Android 以后是否还需要独立构建，还是只保留组合后的 Android APK？

这两个答案会决定是直接改 `Ngan.Ime.Android`，还是新增 `Ngan.Android`。
````
	]
	
	
	-T[2026_0801_204042][
		我是說 把 `CsRime/*` 裏面的內容移進 CsNgan.Dict/裏,
		不是把 `CsRime`他自己移進 `CsNgan.Dict/`、
		然後 CsRime/ 這個就不用了。
		
		然後項目叫Ngan的話、裏面又保留原來名字(Ngan.Dict, Ngan.Ime)就感覺很怪、不協調。
		簡單統一作Ngan就又衝突、因爲已經分別有了 Ngan.Dict.Core和Ngan.Ime.Core,
		Ngan.Dict.Backend 和 Ngan.Ime.Backend。
		你有甚麼想法?
	][
````md
对，你的意思现在完全清楚：

```text
移动前
E:\_code\CsNgan.Dict\*
E:\_code\CsRime\*

移动后
E:\_code\CsNgan.Dict\*
```

把 `CsRime` 下面的一级项目平铺进现有工作区，处理重名公共库；迁移完成后废弃 `E:\_code\CsRime`。

关于命名，你指出的问题确实存在：如果总项目叫 `Ngan`，内部仍是 `Ngan.Dict.*` 和 `Ngan.Ime.*`，看起来像把两个旧产品硬塞到新壳里；但全部直接改成 `Ngan.Core` 又会发生职责冲突。

我的建议是：统一品牌前缀为 `Ngan`，第二段使用业务域名，而不是把所有项目压成同一个层级。

**推荐命名**

把现在的两套系统分别定义成两个业务域：

```text
Ngan.Lexicon
```

原 Ngan.Dict，负责：

- 词典；
- 用户词库；
- 单词编辑；
- 单词学习；
- 学习计划；
- 登录和同步。

```text
Ngan.Ime
```

原 Ngan.Ime，负责：

- 输入法 UI；
- 键盘；
- 候选词；
- 剪贴板；
- 语音输入；
- Rime 前端。

这样原来的冲突可以自然解决：

| 现有名称 | 推荐名称 |
|---|---|
| `Ngan.Dict.Core` | `Ngan.Lexicon.Core` |
| `Ngan.Dict.Backend` | `Ngan.Lexicon.Backend` |
| `Ngan.Dict.Client` | `Ngan.Lexicon.Client` |
| `Ngan.Dict.Ui` | `Ngan.Lexicon.UI` |
| `Ngan.Dict.Server` | `Ngan.Lexicon.Server` |
| `Ngan.Dict.Test` | `Ngan.Lexicon.Test` |
| `Ngan.Dict.Doc` | `Ngan.Lexicon.Doc` |
| `Ngan.Ime.Core` | `Ngan.Ime.Core` |
| `Ngan.Ime.Backend` | `Ngan.Ime.Backend` |
| `Ngan.Ime.UI` | `Ngan.Ime.UI` |
| `Ngan.Ime.Rime` | `Ngan.Ime.Rime` |
| `Ngan.Ime.Doc` | `Ngan.Ime.Doc` |

这比以下结构清楚：

```text
Ngan
├─ Ngan.Dict
└─ Ngan.Ime
```

而是：

```text
Ngan
├─ Lexicon
└─ Ime
```

`Ngan.Dict` 和 `Ngan.Ime` 成为旧名称，迁移完成后不继续进入新命名体系。

**为什么用 Lexicon**

我认为 `Lexicon` 比 `Dictionary`、`Word` 更适合原 Ngan.Dict。

`Dictionary` 太窄，因为原 Ngan.Dict 不只是查词典；`Word` 也偏窄，因为还有语言、发音、学习计划、同步和用户系统。

`Lexicon` 可以覆盖：

- 词汇集合；
- 词条；
- 词典；
- 用户词库；
- 词汇学习。

所以：

```text
Ngan.Lexicon.Core
Ngan.Lexicon.UI
```

读起来也比较明确。

如果你觉得 `Lexicon` 生僻或太长，次选是：

```text
Ngan.Vocab.Core
Ngan.Vocab.Backend
Ngan.Vocab.UI
```

但 `Vocab` 更偏“背单词”，不如 `Lexicon` 完整。

**Rime 相关命名**

`CsRimeApi`、`CsRimeLua` 不一定都应该归在 `Ngan.Ime` 下。

建议区分是否是 Ngan 专属：

```text
Ngan.Rime.Api
Ngan.Rime.Lua
```

或者继续保留通用库身份：

```text
Rime.Api
CsRimeLua
```

我的倾向是：

```text
Ngan.Rime
├─ Ngan.Rime.Api
├─ Ngan.Rime.Lua.Core
├─ Ngan.Rime.Lua.Exports
└─ Ngan.Rime.Lua.Mods
```

输入法业务层再引用它：

```text
Ngan.Ime.Rime
└─ 引用 Ngan.Rime.Api
```

两者语义不同：

- `Ngan.Rime.Api`：对 librime C API 的底层封装；
- `Ngan.Ime.Rime`：把 Rime 引擎适配成 Ngan 输入法服务。

这样不会把底层互操作和输入法业务揉在一起。

**应用宿主命名**

业务程序集统一后，宿主也需要按发布物命名，而不是按内部层名。

我建议：

```text
Ngan.Lexicon.Android
```

原 Ngan.Dict 独立 Android 应用，只包含词汇系统，不带输入法。

```text
Ngan.Lexicon.Windows
Ngan.Lexicon.Linux
Ngan.Lexicon.Browser
```

仍然都是可独立发布的原 Ngan.Dict 产品。

输入法宿主：

```text
Ngan.Ime.Android
Ngan.Ime.Windows
```

其中 `Ngan.Ime.Android` 可以同时拥有：

```text
MainActivity
└─ Ngan.Lexicon.UI.MainView

InputMethodService
└─ Ngan.Ime.UI.MainView
   └─ 工具栏可挂 Ngan.Lexicon.UI.MainView
```

虽然项目名是 `Ngan.Ime.Android`，但它包含 Lexicon 不算矛盾：它代表“带输入法能力的 Android 发布物”。

如果你觉得这仍然不准确，可以给组合 APK 单独命名：

```text
Ngan.Android
```

结构变成：

```text
Ngan.Lexicon.Android   独立词汇应用
Ngan.Ime.Android       纯输入法应用，可选保留
Ngan.Android           词汇系统 + 输入法的组合应用
```

不过你当前只有自己使用 Ngan.Ime，我认为第一阶段没必要维护三个 Android APK。可以只保留：

```text
Ngan.Lexicon.Android   对外发布
Ngan.Android           自用组合版
```

纯输入法 `Ngan.Ime.Android` 暂时不保留独立发布入口。

**推荐的最终项目树**

在物理目录上，我建议按业务域分组，不要继续散落几十个 `Ngan.*` 一级目录：

```text
E:\_code\CsNgan\
├─ Ngan.sln
├─ Ngan.Lexicon.sln
├─ Ngan.Ime.sln
│
├─ Ngan.Lexicon\
│  ├─ Ngan.Lexicon.Core\
│  ├─ Ngan.Lexicon.Backend\
│  ├─ Ngan.Lexicon.Client\
│  ├─ Ngan.Lexicon.UI\
│  ├─ Ngan.Lexicon.Server\
│  ├─ Ngan.Lexicon.Doc\
│  ├─ Ngan.Lexicon.Test\
│  └─ Hosts\
│     ├─ Ngan.Lexicon.Android\
│     ├─ Ngan.Lexicon.Windows\
│     ├─ Ngan.Lexicon.Linux\
│     └─ Ngan.Lexicon.Browser\
│
├─ Ngan.Ime\
│  ├─ Ngan.Ime.Core\
│  ├─ Ngan.Ime.Backend\
│  ├─ Ngan.Ime.UI\
│  ├─ Ngan.Ime.Rime\
│  ├─ Ngan.Ime.Doc\
│  └─ Hosts\
│     ├─ Ngan.Ime.Windows\
│     └─ Ngan.Ime.Android\
│
├─ Ngan.Rime\
│  ├─ Ngan.Rime.Api\
│  ├─ Ngan.Rime.Lua.Core\
│  ├─ Ngan.Rime.Lua.Exports\
│  └─ Ngan.Rime.Lua.Mods\
│
├─ Ngan.Frontend\
│  └─ Ngan.Android\
│
├─ RimeTools\
├─ RimeTts\
│
└─ Tsinswreng.*\
```

但这里有一个现实问题：当前 `Ngan.Dict.Core`、`Ngan.Dict.Backend`、`Ngan.Ime` 等都是独立 Git 仓库。如果强行把各仓库再塞入 `Ngan.Lexicon/`、`Ngan.Ime/`，Git 工作区本身没问题，但根仓库的 gitlink 路径全部会变化。

更保守、迁移风险更低的结构是先保持一级目录：

```text
E:\_code\CsNgan.Dict\
├─ Ngan.Lexicon.Core\
├─ Ngan.Lexicon.Backend\
├─ Ngan.Lexicon.Frontend\
├─ Ngan.Lexicon.Server\
├─ Ngan.Ime\
├─ Ngan.Rime.Api\
├─ Ngan.Rime.Lua\
└─ Tsinswreng.*\
```

等命名和引用全部稳定，再考虑物理分组。

**是否应当全部重命名**

既然你已经不喜欢 `ngan.dict`，而且 `Ngan` 是准备作为更大整体的名字，我改变上一轮意见：这次整合确实是全面重命名的合适窗口。

如果现在保留：

```text
Ngan.Dict.Core
Ngan.Ime.Core
CsRimeApi
```

以后项目融合得越深，改名成本只会更高。

但应该分阶段完成，不应在一次机械替换里同时移动所有仓库、改命名空间、升级 Avalonia、融合 DI 和嵌入 UI。建议顺序：

1. 确认完整命名表。
2. 把 `CsRime/*` 平铺迁入工作区，公共库去重。
3. 保持旧命名，先让统一工作区编译。
4. 统一 Avalonia 版本。
5. 按业务域逐个重命名程序集和命名空间。
6. 每完成一个域立即编译测试。
7. 最后建立 `Ngan.Android` 组合宿主。
8. 再把完整 Lexicon 根 View 挂入 IME。
9. 确认稳定后废弃 `CsRime` 根工作区。

这不是主张长期保留旧名，而是避免无法判断错误来自“移动”“改名”“升级”还是“融合”。

**我最推荐的一套名称**

```text
总品牌：Ngan

原 Ngan.Dict：
Ngan.Lexicon.Core
Ngan.Lexicon.Backend
Ngan.Lexicon.Client
Ngan.Lexicon.UI
Ngan.Lexicon.Server
Ngan.Lexicon.Doc
Ngan.Lexicon.Test

原 Ngan.Ime：
Ngan.Ime.Core
Ngan.Ime.Backend
Ngan.Ime.UI
Ngan.Ime.Rime
Ngan.Ime.Doc

原 CsRime：
Ngan.Rime.Api
Ngan.Rime.Lua.Core
Ngan.Rime.Lua.Exports
Ngan.Rime.Lua.Mods

发布宿主：
Ngan.Lexicon.Android
Ngan.Lexicon.Windows
Ngan.Lexicon.Linux
Ngan.Lexicon.Browser
Ngan.Ime.Windows
Ngan.Android
```

核心思想就是：

```text
Ngan.<业务域>.<技术层>
```

而不是：

```text
Ngan.<技术层>
```

这样 `Core`、`Backend`、`UI` 可以在不同业务域里自然重复，不会冲突，也不会显得残留两套旧品牌。

现在需要你确认两个命名选择：

1. 原 Ngan.Dict 业务域是否接受 `Lexicon`，还是你更倾向 `Vocab`、`Word` 或另一个词？
2. 原 Ngan.Ime 业务域是否就叫 `Ime`，还是希望保留一个更具品牌感的子名？

确认这两个词后，整个项目命名表就基本可以定下来。
````
	]
	
	-T[2026_0801_211709][
		Ngan.Dict->Ngan.Dict
		Ngan.Ime->Ngan.Ime
	
		別的不動
		這樣子是不是好點
	][

````md
是，这样明显更好。我赞成：

```text
Ngan.Dict     → Ngan.Dict
Ngan.Ime  → Ngan.Ime
其他项目 → 暂时不动
```

它比我上一轮提出的全面统一命名更克制，也更符合现有项目边界。

**优点**

- `Ngan` 成为统一产品/工作区名称。
- `Dict` 和 `Ime` 清楚表达两个业务模块。
- 原来的同层项目不会冲突：

```text
Ngan.Dict.Core
Ngan.Dict.Backend

Ngan.Ime.Core
Ngan.Ime.Backend
```

- `CsRimeApi`、`CsRimeLua`、`RimeTools` 等底层或周边项目不必被强行包装成 `Ngan.*`。
- `Tsinswreng.*` 公共库完全不动。
- 改名范围清楚，容易分阶段验证。

**建议映射**

原 Ngan.Dict：

```text
Ngan.Dict.Core        → Ngan.Dict.Core
Ngan.Dict.Backend     → Ngan.Dict.Backend
Ngan.Dict.Frontend    → Ngan.Dict.Frontend
Ngan.Dict.Server      → Ngan.Dict.Server
Ngan.Dict.Test        → Ngan.Dict.Test
Ngan.Dict.Doc         → Ngan.Dict.Doc
Ngan.Dict.sln         → Ngan.Dict.sln
```

内部前端项目：

```text
Ngan.Dict.Client      → Ngan.Dict.Client
Ngan.Dict.Ui          → Ngan.Dict.Ui
Ngan.Dict.Android     → Ngan.Dict.Android
Ngan.Dict.Windows     → Ngan.Dict.Windows
Ngan.Dict.Linux       → Ngan.Dict.Linux
Ngan.Dict.Browser     → Ngan.Dict.Browser
```

原 Ngan.Ime：

```text
Ngan.Ime                  → Ngan.Ime
Ngan.Ime.Core             → Ngan.Ime.Core
Ngan.Ime.Backend          → Ngan.Ime.Backend
Ngan.Ime.Rime             → Ngan.Ime.Rime
Ngan.Ime.Doc              → Ngan.Ime.Doc
Ngan.Ime.UI               → Ngan.Ime.Ui
Ngan.Ime.Android          → Ngan.Ime.Android
Ngan.Ime.Windows          → Ngan.Ime.Windows
Ngan.Ime.Desktop          → Ngan.Ime.Desktop
Ngan.Ime.Browser          → Ngan.Ime.Browser
Ngan.Ime.Test             → Ngan.Ime.Test
```

我建议统一使用 `Ui`，不要一边叫 `UI`、另一边叫 `Ui`。既然现有 Ngan.Dict 使用 `Ngan.Dict.Ui`，可以统一为：

```text
Ngan.Dict.Ui
Ngan.Ime.Ui
```

**组合 Android 宿主**

这里甚至不必再增加 `Ngan.Android`。

`Ngan.Ime.Android` 可以自然表示“带输入法服务的 Ngan Android 应用”：

```text
Ngan.Ime.Android
├─ MainActivity
│  └─ Ngan.Dict.Ui.MainView
│
└─ InputMethodService
   └─ Ngan.Ime.Ui.MainView
      └─ 可切换 Ngan.Dict.Ui.MainView
```

独立词典应用继续是：

```text
Ngan.Dict.Android
└─ Ngan.Dict.Ui.MainView
```

因此：

- `Ngan.Dict.Android`：可对外推广的独立语言/词典应用；
- `Ngan.Ime.Android`：你自己使用的带完整 Dict 功能的输入法应用。

语义能够成立。

**工作区最终样子**

将 `CsRime/*` 平铺迁入后：

```text
E:\_code\CsNgan\
├─ Ngan.sln
├─ Ngan.Dict.sln
├─ Ngan.Ime.sln
│
├─ Ngan.Dict.Core\
├─ Ngan.Dict.Backend\
├─ Ngan.Dict.Frontend\
├─ Ngan.Dict.Server\
├─ Ngan.Dict.Test\
├─ Ngan.Dict.Doc\
│
├─ Ngan.Ime\
├─ CsRimeApi\
├─ CsRimeLua\
├─ RimeTools\
├─ RimeTts\
├─ AvlnImeDemo\
│
└─ Tsinswreng.*\
```

其中 `Ngan.Ime` 仍可保留当前 Ngan.Ime 那种内部结构：

```text
Ngan.Ime\
├─ Ngan.Ime.Core\
├─ Ngan.Ime.Backend\
├─ Ngan.Ime.Frontend\
├─ Ngan.Ime.Rime\
└─ Ngan.Ime.Doc\
```

这里有一点不完全对称：

- Dict 被拆成多个一级仓库；
- Ime 是一个包含多个项目的一级仓库。

但这是当前 Git 仓库边界造成的，不是命名问题。如果不准备调整仓库拆分方式，可以接受，不必为了目录对称重构 Git 历史。

**“别的不动”的边界**

我理解为以下名称均保持：

```text
CsRimeApi
CsRimeLua
RimeTools
RimeTts
AvlnImeDemo
Tsinswreng.*
```

只修改它们内部对原 `Ngan.Ime.*`、`Ngan.Dict.*` 的引用；不修改它们自身的项目名和命名空间。

唯一让我有一点疑问的是 `AvlnImeDemo`：它明显是输入法演示项目，但你说“别的不动”，那就先不动。

**推荐迁移顺序**

1. 将 `CsRime/*` 独有目录平铺迁入 CsNgan.Dict 工作区。
2. 对重复 `Tsinswreng.*` 逐项选择保留版本。
3. 先保持全部旧项目名称，修复 `ProjectReference`，让统一工作区编译。
4. `Ngan.Dict.*` 全面改为 `Ngan.Dict.*`。
5. 编译并验证独立 Dict 应用。
6. `Ngan.Ime.*` 全面改为 `Ngan.Ime.*`。
7. 编译并验证输入法。
8. 统一 Avalonia 版本。
9. 在 `Ngan.Ime.Android` 的 MainActivity 挂 `Ngan.Dict.Ui.MainView`。
10. 在输入法工具栏加入 Dict 标签及根 View。
11. 最后把工作区目录和根仓库由 `CsNgan.Dict` 改成 `CsNgan`，废弃 `CsRime`。

不要同时执行移动、去重、改名、版本升级和 UI 融合。分阶段以后，出错时才能知道是哪一层导致。

这套命名可以作为正式方案：

```text
总项目：Ngan
词典/语言学习：Ngan.Dict
输入法：Ngan.Ime
Rime 底层及公共库：保持原名
```
````
	]
	
	-T[2026_0801_212511][

	][
		
	]
	
]

		還有就是、
		目前Ngan.Ime.Andriod只作輸入法用、
		他的Ngan.Ime.Andriod的MainActivity沒有 [有價值的內容]、
		從桌面點進他出來的MainActivity還是和輸入法鍵盤一樣的畫面。
		也就是說、Ngan.Ime.Android的MainActivity沒有利用上。
		我希望合入之後、
		可以從原本輸入法的MainActivity

