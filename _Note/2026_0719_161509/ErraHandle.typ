-Sesn[
	-T[2026_0719_161531][
		先看skill。
		然後看CsNgan.Dict這個項目。
		當前有全局異常處理`E:\_code\CsNgan.Dict\Ngan.Dict.Frontend\proj\Ngan.Dict.Ui\Infra\GlobalExceptionGuard.cs`。
		在Vm中、大多數的方法都是手動
		```cs
		try{
			
		}catch(Exception e){
			this.HandleErr(e);
		}
		```
		這樣子的、很麻煩。
		看看有沒有甚麼辦法優化一下。
		我的寫法是、都不要寫try catch、
		如果是業務異常就直接讓全局異常處理器調HandleErr。
		你覺得呢
	][
````md
我認同「VM 不應到處寫純樣板 `try/catch + HandleErr`」這個目標，但不建議把正常業務異常直接交給全局異常事件處理。

原因是：

- `TaskScheduler.UnobservedTaskException` 可能等到 Task 被 GC 才觸發，不能保證即時提示。
- `AppDomain.UnhandledException` 通常已接近程序終止，不能作正常業務流程。
- 全局 UI 異常目前一律設置 `E.Handled = true`，若異常發生後狀態已損壞，強行繼續運行可能更危險，見 [GlobalExceptionGuard.cs](E:\_code\CsNgan.Dict\Ngan.Dict.Frontend\proj\Ngan.Dict.Ui\Infra\GlobalExceptionGuard.cs:31)。
- 全局守衛現在並未調用 `HandleErr`，而是自己展示 UnknownErr，業務異常的本地化信息會丟失，見 [GlobalExceptionGuard.cs](E:\_code\CsNgan.Dict\Ngan.Dict.Frontend\proj\Ngan.Dict.Ui\Infra\GlobalExceptionGuard.cs:49)。

更合適的結構是：

```text
VM 方法直接拋異常
        ↓
OpBtn / Command / UI事件執行邊界
        ↓
立即捕獲 Task 異常
        ↓
統一的 ExceptionHandler.HandleErr
        ↓
日誌 + 業務錯誤本地化 + UI 提示

GlobalExceptionGuard
        ↓
只作最後兜底
```

項目其實已經有這個雛形：

- `OpBtn` 會觀察 Task 並調用 `FnFail`，見 [OpBtn.cs](E:\_code\CsNgan.Dict\Ngan.Dict.Frontend\proj\Ngan.Dict.Ui\Infra\Ctrls\OpBtn.cs:108)。
- `SetExe` 已經把 `FnFail` 接到 `MainView.Inst.HandleErr`，見 [AppOpBtn.cs](E:\_code\CsNgan.Dict\Ngan.Dict.Frontend\proj\Ngan.Dict.Ui\Infra\Ctrls\AppOpBtn.cs:30)。

因此，經 `OpBtn.SetExe(...)` 調用、catch 中僅有 `HandleErr(ex)` 的 VM 方法，原則上可以直接移除該 catch，讓 Task 失敗後由按鈕執行邊界處理。

但是不能批量刪除所有 catch。例如：

- [VmAddWord.cs](E:\_code\CsNgan.Dict\Ngan.Dict.Frontend\proj\Ngan.Dict.Ui\Views\Word\WordManage\AddWord\VmAddWord.cs:60) 的 catch 還設置了 `ErrStr`。
- 詞典查詢的 catch 會處理取消、恢復舊狀態、保留流式輸出以及提供替代操作。
- 有些方法用 `bool` 返回成功與否，catch 還負責返回 `false`。
- `OperationCanceledException` 通常不應作業務錯誤彈窗。
- 普通 `Click`、`Loaded` 和 `async void` 事件未必經過 `OpBtn`，需要另一個統一事件包裝器。

我的建議方案是：

1. 把 `HandleErr` 從 `MainView`/VM 轉發方法抽成獨立的全局異常服務；全局守衛和 UI 操作邊界共用它。
2. 強化 `OpBtn`：同時捕獲調用委託時的同步異常和返回 Task 後的異步異常。
3. 為普通 Avalonia 事件提供 `Guard(Action)` / `Guard(Func<Task>)` 一類執行入口。
4. VM 中只保留真正承擔恢復、回滾、取消或替代流程的 catch。
5. `GlobalExceptionGuard` 只兜底記錄逃逸異常，不把它當正常業務異常管線，也不應無條件把所有 UI 異常標記為可繼續。

需求確認如下：

1. **我理解的需求是**：消除 VM 中只為調用 `HandleErr` 而存在的重複 catch，讓業務方法可以自然拋出異常。
2. **核心目標**：統一異常展示與日誌，同時保證異常能被立即觀察，不依賴 GC 或進程級事件。
3. **隱含需求**：取消不彈錯誤、業務異常保留本地化、普通事件也受保護、帶回滾邏輯的 catch 保留。
4. **範圍建議**：先完善統一執行邊界，再逐步清理純樣板 catch；不一次性機械刪除全部 catch。
5. **業務影響**：主要影響所有 `OpBtn` 操作、普通 UI 事件及錯誤展示方式；不涉及數據庫結構。

有一個範圍需要你裁定：你希望第一階段只處理經過 `OpBtn.SetExe` 的 VM 方法，還是連普通 `Click`、`Loaded`、`async void` 事件也一起統一？
````
	]
]
