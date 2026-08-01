#import "@preview/tsinswreng-auto-heading:0.1.0": auto-heading
#let H = auto-heading;

#H[三個入口程序集啓動流程][
	本文說明以下三個入口程序集的啓動鏈路:
	- `Ngan.Dict.Frontend/proj/Ngan.Dict.Windows/Ngan.Dict.Windows.cs`
	- `Ngan.Dict.Test/proj/Ngan.Dict.Windows.Test/Ngan.Dict.Windows.Test.cs`
	- `Ngan.Dict.Server/proj/Ngan.Dict.Server.Http/Ngan.Dict.Server.Http.cs`

	文中流程以當前代碼爲準, 便於後續排查「啓動時配置未生效」「服務未註冊」「初始化順序錯」等問題。
]

#H[Ngan.Dict.Windows 啓動流程][
	#H[1. 入口與配置讀取][
		入口函數: `Program.Main(string[] args)`。

		啓動早期做的事:
		- 先調用 `InitAppLog()` 初始化全局日誌源頭:
			- 使用 Serilog 同時輸出到 console 與 `exe` 同目錄下的 `logs/`
			- 文件日誌按日滾動，並限制單文件大小與保留份數
			- 兩個 sink 都放在 async sink 中，儘量降低對主線程的阻塞
			- 若文件 sink 初始化失敗，回退到僅 console
		- 若 `args.Length > 1 && args[0] == "--version"` 則輸出版本時間戳。
		- `BaseDirMgr.Inst._BaseDir = Directory.GetCurrentDirectory()` 設置基準目錄。
		- 通過 `GetCfgFilePath(args)` 決定只讀配置文件路徑:
			- 有命令行參數時使用 `args[0]`
			- 否則使用 `Ngan.Dict.jsonc`
		- `AppCfg.Inst` 使用雙源配置:
			- `RoCfg`: 用戶只讀配置(手寫), 由 `CfgPath` 加載
			- `RwCfg`: GUI 可寫配置, 路徑來自 `KeysClientCfg.RwCfgPath`
		- 讀取語言配置:
			- 語言鍵: `KeysClientCfg.Lang` (缺省 `default`)
			- 語言文件: `Languages/{Lang}.json`
	]

	#H[2. DI 組裝][
		`ServiceCollection` 依次執行:
		- `SetupCore()`:
			- 註冊 `AppCfg.Inst` 爲 `ICfgAccessor`
			- 註冊核心算法/工具服務與全局 `ILogger`
		- `SetupLocal()`:
			- 註冊本地 DB 連接、Repo、遷移管理、本地領域服務
		- `SetupLocalFrontend()`:
			- 註冊前端上下文(`IFrontendUserCtxMgr`)、token 存儲、圖片/TTS 等
		- `SetupClient()`:
			- 註冊 HTTP 調用與客戶端 user/sync 服務
		- `SetupUi()`:
			- 註冊 UI 各 ViewModel 與導航服務
		- `SetupWindows()`:
			- 註冊 Windows 專用能力: 音頻、剪貼板、全局熱鍵
	]

	#H[3. Avalonia 啓動與 AppIniter][
		流程如下:
		- `BuildAvaloniaApp()` 建立 AppBuilder
		- `AfterSetup(...)` 中注入 DI 與本地初始化:
			- `App.SetSvcProvider(svcProvider)` 讓 UI 可全局取服務
			- `AppIniter.Inst.Sp = svcProvider`
			- `AppIniter.Inst.Init(default)` 執行本地啓動初始化
		- `StartWithClassicDesktopLifetime(args)` 進入桌面生命週期

		`AppIniter.Init` 做兩件事:
		- `InitDbSchema`: 觸發本地 DB schema/遷移初始化
		- `InitUserCtx`: 恢復當前本地用戶、登錄態、refresh token、client id

		Avalonia 進入 `App.OnFrameworkInitializationCompleted()` 後:
		- 桌面端設置 `desktop.MainWindow = MkWindow()`
		- 嘗試註冊全局熱鍵 `I_RegisterGlobalHotKeys`
		- `MainWindow` 內容爲 `MainView.Inst`
	]

	#H[4. 典型配置文件][
		默認客戶端配置文件是程序目錄下 `Ngan.Dict.jsonc`。示例中常見鍵:
		- `RwCfgPath` (GUI可寫配置文件路徑)
		- `SqlitePath`
		- `ServerBaseUrl`
		- `Lang`
	]
]

#H[Ngan.Dict.Windows.Test 啓動流程][
	#H[1. 入口特徵][
		入口函數: `Program.Main(string[] args)`。

		此程序集是「測試聚合入口」, 不啓動 UI, 核心目的爲:
		- 裝配可測環境 DI
		- 執行 `WindowsTestMgr` 收編的測試樹
	]

	#H[2. DI 與初始化][
		`SvcColct` 依次註冊:
		- `SetupCore()`
		- `SetupLocal()`
		- `SetupLocalFrontend()`

		然後:
		- 取得 `WindowsTestMgr.Inst`
		- `mgr.InitSvc(...)` 構建 `IServiceProvider`
		- 設置 `AppIniter.Inst.Sp = SvcProvdr`
		- 執行 `AppIniter.Inst.Init(default)`，確保 DB schema/用戶上下文就緒
	]

	#H[3. 測試樹裝配與執行][
		`WindowsTestMgr.RegisterTestsInto` 收編:
		- `LocalTestMgr.Inst`
		- `CoreTestMgr.Inst`

		最後用:
		- `ITestExecutor executor = new TreeTestExecutor();`
		- `await executor.RunEtPrint(mgr.TestNode);`

		即: 測試入口負責「初始化環境 + 觸發測試樹」, 不承擔業務 HTTP/UI 入口職責。
	]
]

#H[Ngan.Dict.Server.Http 啓動流程][
	#H[1. 入口函數][
		入口函數:
		- `Ngan.DictWeb.Main(args)` -> `InitApp(args)` -> `app.Run()`
	]

	#H[2. 服務端配置載入][
		`ServerCfg.Inst.LoadFromArgs(args)`:
		- 若傳參, 用 `args[0]` 作爲配置路徑
		- 否則:
			- `DEBUG`: `Ngan.Dict.Server.dev.jsonc`
			- `RELEASE`: `Ngan.Dict.Server.jsonc`

		典型配置鍵:
		- `Port`
		- `Db.Postgres.*`
		- `Db.Redis.*`
		- `Auth.JwtSecret` 等
	]

	#H[3. WebApplication 建立][
		`WebApplication.CreateSlimBuilder(args)` 後主要配置:
		- `AddCors` 默認策略允許任意 Origin/Header/Method
		- `UseKestrel` 監聽 `KeysServerCfg.Port` 指定的 localhost 端口
		- `ConfigureHttpJsonOptions`:
			- 使用 `AppJsonCtx.Default`
			- `PropertyNamingPolicy = null`
			- `WriteIndented = true`
			- 補充自定義 converters
	]

	#H[4. DI 組裝][
		`builder.Services.SetupEntry(Cfg)` 進入入口 DI:
		- `SetupCore()`
		- `SetupBiz()`:
			- 註冊 `ServerCfg.Inst`
			- 註冊 Postgres/Repo/領域服務
			- 配置 Redis Cache 與 `IConnectionMultiplexer`
		- `SetupWeb()` (目前爲空殼擴展點)

		附加基礎能力:
		- `AddExceptionHandler<GlobalErrHandler>()`
		- `AddProblemDetails()`
	]

	#H[5. 控制器路由與中間件][
		路由初始化:
		- `AppRouterIniter.Init(builder.Services)` 註冊控制器類型
		- `appRouterIniter.InitRouters(app.Services, BaseRoute)` 綁定路由
		- 當前註冊控制器包含 `CtrlrOpenUser`、`CtrlrWord`

		中間件順序:
		- `app.UseExceptionHandler()`
		- `app.UseCors()`
		- `app.UseMiddleware<TokenValidationMidware>()`
		- `app.UseMiddleware<EdgeDebounceMidware>()`

		其中:
		- `TokenValidationMidware` 僅對 `/Api*` 要求 Bearer Token
		- `EdgeDebounceMidware` 用 Redis 做邊緣防抖(重複請求限流)
	]

	#H[6. 啓動後可用路由][
		至少包含:
		- `GET /` -> 返回當前時間字符串
		- `AppRouterIniter` 註冊的業務 API 路由
	]
]

#H[三者對比總結][
	- `Ngan.Dict.Windows`:
		- 面向桌面客戶端
		- 啓動時讀雙源配置 + 啓動 Avalonia + 本地初始化
	- `Ngan.Dict.Windows.Test`:
		- 面向自動化測試
		- 啓動時組測試依賴 + 初始化 DB/UserCtx + 執行測試樹
	- `Ngan.Dict.Server.Http`:
		- 面向 HTTP 服務端
		- 啓動時讀服務端配置 + 建立 ASP.NET Core 管道 + 掛路由/中間件 + `Run()`
]

#H[AppIniter][
	做客戶端初始化。程序啓動時會執行。依賴 IServiceProvider
	檢查是否已初始化。看數據庫架構是否最新
		- 無數據庫則建庫
		- 數據庫架構非最新則自動執行遷移
		- 初始化其他數據  如在Kv表中確保ClientId等已存在。
	
]

#H[注意點][
	當前Ngan.Dict.Windows.Test 未實際接收傳入的配置文件。
	故其sqlite測試數據庫是按默認路徑直接在當前pwd下創建的。
	測試的數據庫和開發環境的數據庫是分開的 開發環境的數據庫在 Ngan.Dict.Windows/bin/Debug/下。
	當測試用例涉及數據庫操作時 會先插入測試數據、測試結束後再清除插入的測試數據使數據庫恢復原狀。
	確保每次執行測試時結果都獨立不干擾。
]
