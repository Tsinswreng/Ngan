-Sesn[
	-T[2026_0719_172902][
		先看skill。
		然後想一下前端怎麼自動測試。
		
		原本想了一套IViewXxx接口的做法、但是現在廢棄了。
		
		現在的UI寫法是:
		ViewXxx中會直接把一些關鍵的控件提升爲類成員。
		Converter也作爲類的靜態成員。
		
		在測試用例中能直接拿到上面那些東西。
		現在還有一個試驗中的前端測試程序集
		`E:\_code\CsNgan.Dict\Ngan.Dict.Test\proj\Ngan.Dict.Windows.Test\Ngan.Dict.Windows.Test.cs`。
		
		
		
	][
````md
已看完必读 skill、Avalonia DSL 规范、CsTreeTest 规范和现有测试代码。

目前发现一个必须先确认的设计分叉：

- [Ngan.Dict.Windows.Test.cs](/E:/_code/CsNgan.Dict/Ngan.Dict.Test/proj/Ngan.Dict.Windows.Test/Ngan.Dict.Windows.Test.cs) 目前没有引用 `Ngan.Dict.Ui`，也没有启动 Avalonia UI 线程。
- 仓库已有 [Ngan.Dict.Ui.Test](/E:/_code/CsNgan.Dict/Ngan.Dict.Test/proj/Ngan.Dict.Ui.Test/Ngan.Dict.Ui.Test.csproj) 和 [Ngan.Dict.Ui.Windows.Test](/E:/_code/CsNgan.Dict/Ngan.Dict.Test/proj/Ngan.Dict.Ui.Windows.Test/Ngan.Dict.Ui.Windows.Test.csproj)，但它们采用已废弃的 `IViewXxx` 方案。
- [Ngan.Dict.Ui.Windows.Test/Program.cs](/E:/_code/CsNgan.Dict/Ngan.Dict.Test/proj/Ngan.Dict.Ui.Windows.Test/Program.cs:37) 已经实现了 Avalonia 宿主和 UI 线程启动。这部分基础设施仍有价值，只是测试抽象需要废弃。

我初步建议的新测试方式：

1. 测试器直接依赖具体 `ViewXxx`、`VmXxx`，不再创建任何 `IViewXxx`。
2. 每个测试重新创建 View，避免控件状态、事件订阅和 `DataContext` 相互污染。
3. View 构造完成后，直接断言公开关键控件：
   - 控件是否成功初始化；
   - 控件属性、内容、样式和可见性；
   - 控件与 Vm 的绑定是否双向同步；
   - 点击按钮后 Vm 或导航状态是否改变。
4. 静态 Converter 不启动窗口，直接调用 `Convert`/`ConvertBack`，作为普通单元测试。
5. 所有 View、绑定和控件事件测试统一在 Avalonia UI 线程执行；每次修改 Vm 或触发事件后排空 Dispatcher 队列再断言。
6. 不以遍历视觉树、查控件名字作为主要方式。公开成员就是 View 的测试入口和结构契约。
7. CsTreeTest 继续按“一个 TestViewXxx 对应一个 ViewXxx；每个主要行为单独文件”的方式组织。

有三个问题需要你裁定，我不能带着这些疑问继续设计：

1. 新前端测试最终放在哪里？是把 `Ngan.Dict.Ui.Test`、`Ngan.Dict.Ui.Windows.Test` 废弃并将功能并入你指出的 `Ngan.Dict.Windows.Test`，还是保留这两个程序集，只删除 `IViewXxx` 做法？
2. 自动测试目标是否包含真实控件点击、绑定和 Dispatcher 行为，还是第一阶段只测 View 构造、公开控件及 Converter？
3. 是否要求测试能在 CI 无桌面环境运行？如果要求，我会研究 `Avalonia.Headless`；如果只需 Windows 本机及 AOT 执行，可以沿用当前 Desktop 宿主。
````
	]
	
	-T[2026_0719_192411][
		先聚焦在最重要 最決定性的東西。甚麼文件位置 命名規則這些細枝末節的現在不要浪費精力談。
		現在暫時不用CI。
	][
````md
明白，暂时排除 CI、程序集位置、命名和组织方式。

最决定性的设计是：

**直接把具体 `ViewXxx` 当作被测对象，在真实 Avalonia UI 线程中构造并操作它。**

测试入口就是：

- View 提升出来的关键控件成员；
- View 的 `Ctx`；
- View 的静态 Converter。

核心测试闭环：

```text
构造 View
→ 取得公开控件
→ 设置控件值／触发点击
→ 排空 UI Dispatcher
→ 断言 Vm、控件或导航结果
```

反方向也要测：

```text
修改 Vm
→ 排空 UI Dispatcher
→ 断言控件已通过 Binding 更新
```

这样不需要 `IViewXxx`，也不需要模拟一套假的 View 接口。测试的是应用实际运行的控件、绑定和事件连接。

测试应分成三种性质：

1. Converter 测试  
   直接调用静态 Converter，属于纯函数测试，不需要显示窗口。

2. View 接线测试  
   验证关键控件存在、Binding 方向正确、按钮确实调用对应 Vm 操作。这是当前最有价值的一层，能抓到“界面能编译但接错属性/事件”的问题。

3. View 行为测试  
   给 View 注入可控的 Vm 和假服务，点击真实控件，验证加载、保存、删除、导航等完整行为。

当前不建议优先做截图或像素比对。它脆弱，而且无法准确覆盖绑定和业务行为；以后确实需要验证视觉布局时再单独增加。

现在只剩一个决定性问题需要你确认：

**是否把“自动前端测试”的主要目标定为控件、Binding、事件和 Vm 之间的接线与交互正确，而暂时不测试像素级外观？**

如果是，我下一步就围绕这个目标继续研究：如何稳定构造具体 View、替换其 Vm/依赖，以及怎样可靠触发 Avalonia 控件事件。
````
	]
	
	-T[2026_0719_195513][
		對 不精確測外觀、只要偏向功能方面。
		View修改輸入 觸發點擊這個是不是有點麻煩了?
		我觸發完點擊我怎麼纔知道他甚麼時候執行完呢?
		現在測試庫裏有一套輪詢的工具、
		但這也只是適合UI有變化的。
		對于UI沒變化的就不好弄了。
		
		還有就是我覺得是不是不用mock比較好?
		直接注入真實的依賴、但是用的是測試環境。
		就像後端的測試一樣。涉及數據的、
		每次測試前先準備種子數據(如向數據庫插入種子數據)、
		操作之後查庫驗證、最後再清掉種子數據。
		這樣更通透。用mock的話還要再另外搞mock感覺比較麻煩。
		你覺得呢
	][
````md
我赞成：前端功能测试应以“真实依赖 + 测试环境 + 种子数据”作为主路线。这本质上是 UI 驱动的集成测试，比大量 mock 更通透。

点击完成的问题不应靠观察 UI，也不应主要靠轮询。真正可靠的完成条件应当是：**按钮保存并公开本次业务操作返回的 `Task`。**

当前 [ToolBtn.cs](/E:/_code/CsNgan.Dict/Ngan.Dict.Frontend/proj/Ngan.Dict.Ui/Tools/ToolBtn.cs:31) 的 `ClickAndWaitDone` 是轮询 `OpBtn.State`；而 [OpBtn.cs](/E:/_code/CsNgan.Dict/Ngan.Dict.Frontend/proj/Ngan.Dict.Ui/Infra/Ctrls/OpBtn.cs:78) 取得业务 `Task` 后，只挂了 `ContinueWith`，没有把 Task 暴露出来。因此目前确实不够稳。

建议把语义设计为：

```text
测试触发真实 Button.Click
→ OpBtn 的 Click 处理器取得 FnExeAsy 返回的 Task
→ OpBtn 保存“本次执行 Task”
→ 测试直接 await 该 Task
→ 再排空一次 Dispatcher
→ 查数据库或检查其他最终结果
```

这样即使操作完全不改变 UI，也能准确知道业务执行何时结束。超时只作为防止测试永久挂起的保险，不再作为判断完成的手段。

需要注意，等待的最好不是原始业务 Task，而是一个代表完整按钮流程的 Task：

```text
FnExeAsy 执行
→ FnOk / FnFail / FnCancel
→ State 恢复 Ready
→ UI Dispatcher 收尾完成
```

否则业务已经写库完成，但按钮的完成回调或 UI 收尾可能还没有执行。

输入操作则相对简单：

```text
UI 线程设置 TextBox.Text
→ 排空 Dispatcher
→ 断言 Vm 已更新
→ 触发真实 Click
→ await 按钮本次执行 Task
→ 查库验证
```

这能同时覆盖：

- 控件到 Vm 的 Binding；
- Button.Click 是否接到了正确操作；
- Vm 和真实服务是否正确工作；
- 数据是否真正持久化。

关于 mock，我的判断是：

- 数据库、仓储、领域服务、应用服务：默认使用真实实现和测试数据库。
- 每条测试使用唯一 token/ID 准备数据。
- 操作后直接查库验证。
- `finally` 中硬删除所有种子数据和操作产生的数据。
- UI 测试串行执行，避免共享登录用户、全局 DI、导航和数据库状态互相影响。
- 只有无法稳定放进测试环境的系统边界才使用 fake，例如真实音频播放、系统剪贴板、文件选择器、全局热键和外部收费 API。

这里我倾向区分“mock 业务行为”和“隔离系统副作用”：前者尽量不用；后者仍然有必要，否则测试会播放声音、修改剪贴板或依赖外网。

所以最核心的方案可以定为：

> 具体 View + 真实控件事件 + 可等待的操作 Task + 真实测试依赖 + 种子数据 + 最终状态/数据库验证。

我认为下一步最优先的不是写某个 View 测试，而是先把 `OpBtn` 的“触发并准确等待完整执行”能力设计好。它会成为绝大多数前端功能测试的同步基础。
````
	]
	
	-T[2026_0719_200431][
		你看的那個東西是OpBtn專有的。如果是普通按鈕呢?
		雖說現在 大部份情況是綁非UI的異步操作/複雜操作/調API 就用OpBtn、
		其餘場景用普通按鈕。
		
		我有想法就是讓所有的給按鈕綁定的函數都接收一個上下文、
		然後按鈕執行的時候取上下文 觸發回調。
		然後在測試這邊可以註冊回調。
		類似
		```cs
		public async Task<nil> ForClick(IFnCtx Ctx, CT Ct){
			DoSomething();
			Ctx.Done();
			return NIL;
		}
		```
		每個給按鈕綁定的函數都這樣。
		你覺得怎麼樣?或者有沒有別的更好的
		
		
	][
````md
你的 `IFnCtx` 方向可以保留，但我不建议由业务函数手动调用 `Ctx.Done()`。

问题在于手动完成很容易失真：

- 中途异常，没走到 `Done()`，测试永久等待。
- 多个 `return` 分支漏掉某一处。
- `Done()` 调早了，后续逻辑仍在执行。
- 同一个上下文误调两次。
- 每个按钮函数都多出一条与业务无关的样板代码。

更好的办法是：**上下文负责承载信息，执行框架根据函数返回的 Task 自动标记完成。**

```cs
public async Task<nil> ForClick(IFnCtx Ctx, CT Ct){
	await DoSomething(Ct);
	return NIL;
}
```

按钮统一通过一个执行适配器绑定：

```cs
Btn.SetExe(ForClick);
```

概念上的内部流程是：

```cs
Click
→ 创建 IFnCtx
→ 建立本次 ButtonExecution
→ 调用 ForClick(Ctx, Ct)
→ await 返回的 Task
→ 自动记录成功、失败或取消
→ 自动完成 ButtonExecution
```

测试流程则是：

```cs
var execution = Btn.AwaitNextExecution();

Btn.RaiseClick();

await execution;
```

这里要先取得“下一次执行”的等待对象，再触发点击，避免执行特别快而错过完成信号。

这个执行抽象不应当是 `OpBtn` 专有的：

```text
普通 Button ─┐
             ├→ ButtonExecution / FnExecution
OpBtn ───────┘
```

二者区别只在表现：

- 普通 `Button`：执行期间没有进度条，通常绑定短小同步操作或简单 UI 操作。
- `OpBtn`：使用同一套执行生命周期，额外显示 Working、支持取消和错误处理。
- 测试端：两者都能可靠地等待本次执行完成。

同步按钮也可以统一包装：

```cs
public Task<nil> ForClick(IFnCtx Ctx, CT Ct){
	DoSomething();
	return Task.FromResult(NIL);
}
```

或者执行器同时接受同步委托，但最终都转换成 `Task`。从一致性看，我更倾向按钮回调统一返回 `Task<nil>`，即使它内部是同步操作。

`IFnCtx` 仍然有价值，可以承载：

- `CancellationToken`；
- 本次执行编号；
- 调用来源；
- 日志上下文；
- 测试环境提供的观察器；
- 将来需要扩展的其他信息。

但“完成”不应由业务代码声明，而应由执行边界自动判断。

有一种特殊情况：回调返回时，实际工作还没完成，例如：

```cs
Dispatcher.UIThread.Post(SomeLaterWork);
return NIL;
```

这时不能用 `Ctx.Done()`草率解决，更合理的是让上下文支持登记子任务：

```cs
Ctx.Track(DispatcherOperationTask);
```

执行器最终等待：

```text
回调返回的 Task
+ Ctx 中登记的所有子 Task
```

不过普通 UI 属性修改一般不需要 `Track`；执行完回调后统一排空一次 Dispatcher 即可。只有真正脱离当前调用链的延后任务才登记。

因此我推荐的核心设计是：

```cs
Task<nil> ForClick(IFnCtx Ctx, CT Ct)
```

但函数里不写 `Ctx.Done()`；由普通 Button 和 OpBtn 共用的执行器自动完成，并让测试能够取得、等待本次真实点击产生的执行 Task。

这比轮询 UI、轮询按钮状态和手动 `Done()`都更可靠。
````
	]
	
	
	-T[2026_0719_203507][
		先不講這麼多。
		你去Ui test下面、針對
		
		WordEditV2.cs
		
		寫幾個測試用例讓我看看先。
		
		先寫聲明。
	][
		
	]
	
]
