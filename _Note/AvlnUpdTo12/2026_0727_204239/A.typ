-Sesn[
	-T[2026_0727_204311][
		我要把CsNgan.Dict 前端升級到Avalonia12。
		現在是Avalonia11。
		原先我嘗試過一次升級、在  Avln12 分支。
		但是失敗了。
		
		失敗的原因是、當時 TreeDataGrid 和 Scotplot畫圖庫 不支持Avalonia12。
		
		現在又過了一段時間。我想再試一下。
		
		對于不支持的庫、可以把他的源碼clone下來、
		本地修改、本地引用。
		
		如果實在不行那就不用 他的庫、自己做個 API相似的或者換掉。
		
		有幾點要注意的:
		- Avln12分支只能看、不能動。
		- Avln12分支已經比主分支落後很多了、非Avalonia版本改造相關的變動、都以主分支爲準。
		- #[Avalonia12 最新的版本號 和 Avln12的 不一樣、你這次改造要用最新的Avalonia版本來。
		`E:\_code\CsRime\Ngan.Ime\Ngan.Ime.Frontend\proj\Ngan.Ime.UI\Ngan.Ime.UI.csproj`
		這個是一個比較成功的Avalonia12項目。可以參照他的來。但他的Avalonia12小版本也不是最新的。
		]
		- Avln.Dsl 這些的 在Nuget上已經有適配Avalonia12的版本的包了。看Ngan.Ime引用的是哪個。
		
		你先看看怎麼樣。
		其他有不懂就問。

	][
````md
目前看，這次升級已經可行，之前兩個主要阻塞都基本解除：

- 最新穩定 Avalonia 是 `12.1.0`。
- `Avalonia.Controls.TreeDataGrid 12.1.1` 已支持 Avalonia 12，但新增 `AvaloniaUI.Licensing` 依賴。
- `ScottPlot.Avalonia 5.1.59` 已明確依賴 Avalonia 12，不需要 clone 源碼修改。
- `Tsinswreng.Avln.Dsl 0.3.0-alpha` 是 Avalonia 12 版本，和 Ngan.Ime 一致。
- `Avalonia.AvaloniaEdit 12.0.0`、`Semi.Avalonia 12.1.0`、`Irihi.Ursa 2.1.0` 也都有 Avalonia 12 版本。

上次的 `Avln12` 分支不能直接合併：它相對當前主分支涉及 183 個文件，混入大量業務功能刪改。這次應從當前 `master` 新開分支，只參考其中 Avalonia 12 相關改法。

TreeDataGrid 是現在唯一需要你裁定的問題。主分支約有 18 個實際頁面使用它，而且基本都是平面表格；上次分支曾寫過 `TdgCompat.cs`，用免費 `DataGrid` 模擬部分 TreeDataGrid API。

我建議優先方案是：

1. 使用官方 `TreeDataGrid 12.1.1`，保留現有代碼結構，改造量最小。
2. 如果不接受它現在的授權依賴，改用免費 `Avalonia.Controls.DataGrid`，重新做一個薄兼容層；但需要逐頁驗證選中、行點擊、列寬及刷新行為。

需求確認如下：

- 核心目標：以當前主分支業務代碼為準，將整個 Ngan.Dict 前端升到最新 Avalonia 12。
- 範圍內：集中包版本、Windows/Linux/Browser/Android/UI 工程、Avalonia API 破壞性變更、第三方 UI 包、編譯及基本啟動驗證。
- 範圍外：不合併 `Avln12` 的業務改動，不修改 `Avln12` 分支。
- ScottPlot：直接升級到 `5.1.59`。
- Avln.Dsl：由本地 Avalonia 11 項目引用切換到 NuGet `0.3.0-alpha`。
- Avalonia 主版本：使用 `12.1.0`，不是 Ngan.Ime 的 `12.0.4`。

開始設計和修改前，需要你確認兩點：

1. TreeDataGrid 可以使用帶 `AvaloniaUI.Licensing` 依賴的官方 `12.1.1` 嗎？還是要求使用免費 DataGrid 兼容方案？
2. 本次是否要求 Windows、Linux、Browser、Android 全部編譯通過？iOS 工程目前沒有啟用 Avalonia.iOS，是否仍維持不處理？
````
	]
	
	-T[2026_0727_205834][
		TreeDataGrid不要付費的！
		TreeDataGrid不要付費的！
		TreeDataGrid不要付費的！
		官方維護的那個就是付費的
		
		只要Windows和安卓上能用就行。
	][
````md
明白：絕不使用任何付費 TreeDataGrid，也不引入 `AvaloniaUI.Licensing`。

需求確認：

- 基於當前 `master` 升級至 Avalonia `12.1.0`。
- Windows、Android 必須可編譯和使用。
- Linux、Browser、iOS 本次不作驗收目標。
- ScottPlot 升至支持 Avalonia 12 的 `5.1.59`。
- TreeDataGrid 使用免費的 `Avalonia.Controls.DataGrid` 替代，必要時提供 API 相似的兼容層。
- 現有業務頁面的 TreeDataGrid 都是平面表格，適合此方案。
- 不修改、不合併 `Avln12`，只參考其中與升級直接相關的做法。
- 使用 Avalonia 12 的 NuGet 版 `Tsinswreng.Avln.Dsl 0.3.0-alpha`。

還有一處需要你確認：[`TryTreeDataGrid.cs`](E:/_code/CsNgan.Dict/Ngan.Dict.Frontend/proj/Ngan.Dict.Ui/Try/TryTreeDataGrid.cs) 是試驗代碼，使用了真正的樹形 `HierarchicalTreeDataGridSource`，免費 DataGrid 不能直接等價替代。

我的建議是：本次刪除或停用這個試驗頁面；正式業務頁面全部保留並遷移。可以嗎？
````
	]
	
	-T[2026_0727_210246][
		隨便你。
		代碼改動要儘量少。別每個用了TreeDataGrid的地方都要大改
	][
````md
遇到一個需要你確認的跨模塊問題：

`Ngan.Dict.Frontend` 有 97 個文件直接使用本地 `Tsinswreng.AvlnTools`。這個庫的 `Directory.Build.props` 又強制引用本地 Avalonia 11 版 `Tsinswreng.Avln.Dsl`，導致 NuGet 的 Avalonia 12 DSL 被覆蓋，產生 `CBE` API 衝突。

我建議：

- 同步升級本地 `Tsinswreng.AvlnTools` 至 Avalonia 12。
- 將它對 DSL 的本地項目引用改成 NuGet `Tsinswreng.Avln.Dsl 0.3.0-alpha`。
- 不改其公開 API，讓前端 97 個使用文件保持不動。
- 若該庫自身出現 Avalonia 12 編譯錯誤，只做必要兼容修改。

這會修改 `Ngan.Dict.Frontend` 以外的共用庫 `Tsinswreng.AvlnTools`。可以這樣做嗎？
````
	]
	
	-T[2026_0727_211023][
		可。
	][
````md
Android 的 Avalonia 12 代碼已通過編譯，目前只剩兩個平台配置問題，需要你確認：

1. Android NativeAOT

現有配置強制啟用實驗性 NativeAOT，但當前 NDK 23 在原生鏈接時缺少 C++ `to_chars` 符號。Ngan.Ime 也是使用 `PublishAot=false`。

建議永久關閉：

- `PublishAot=false`
- `AndroidEnableAot=false`
- 使用 Mono runtime
- Release 仍可保留 trimming/linker

2. Android 最低版本

Avalonia 12 的 AndroidX 依賴要求最低 API 23，現在項目是 API 21。Ngan.Ime 同樣設為 23。

建議把：

```xml
<SupportedOSPlatformVersion>21</SupportedOSPlatformVersion>
```

改成：

```xml
<SupportedOSPlatformVersion>23</SupportedOSPlatformVersion>
```

也就是不再支持 Android 5.0/5.1，最低改為 Android 6.0。

可以同時採用這兩項嗎？
````
	]
	
	
	-T[2026_0727_212645][
		安卓端NativeAot的配置你也可以參考Ngan.Ime。
		Ngan.Ime.Android是能NativeAot編譯成功的。
		
		然後我運行了一下Windows的、所有用到TreeDataGrid的地方還是全部沒顯示。
		看看怎麼回事。
		
	][
````md
已定位 TreeDataGrid 不顯示的根因：

`TreeDataGrid` 是自定義的 `DataGrid` 子類，但缺少：

```csharp
protected override Type StyleKeyOverride => typeof(DataGrid);
```

Avalonia 因此找不到 DataGrid 的 ControlTheme，控件沒有視覺模板，所有表格一起完全不顯示。只需修改兼容層，不需要改業務頁。

Android NativeAOT 也查清了：Ngan.Ime 使用兩套配置：

- 日常 IDE/build：Mono，`PublishAot=false`
- NativeAOT：通過 WSL 專用腳本，使用 NDK r27c 顯式執行 `dotnet publish`
- 最低 Android API 23
- 額外保留 TLS trust-manager JNI 符號

我準備：

- 修復 DataGrid 的 `StyleKeyOverride`
- 將 Android 日常配置改成 Ngan.Ime 的 Mono 模式
- 添加 Ngan.Dict 的 `PublishNativeAot.sh`
- 加入 Ngan.Ime 的 NativeAOT TLS linker workaround
- 最低 Android API 改成 23

可以直接這樣改嗎？
````
	]
	
	-T[2026_0727_213014][
		那你先改改看。
	][
````md
已改好並完成編譯驗證。

- 修復 DataGrid 完全不顯示：兼容控件現在複用原生 `DataGrid` 的 ControlTheme，[TreeDataGridCompat.cs](E:/_code/CsNgan.Dict/Ngan.Dict.Frontend/proj/Ngan.Dict.Ui/TreeDataGridCompat.cs:8)。
- Android 日常構建改為 Mono，最低 API 23，[Ngan.Dict.Android.csproj](E:/_code/CsNgan.Dict/Ngan.Dict.Frontend/proj/Ngan.Dict.Android/Ngan.Dict.Android.csproj:5)。
- Android 入口升級為 Avalonia 12 的 Application + 非泛型 MainActivity 結構，[Application.cs](E:/_code/CsNgan.Dict/Ngan.Dict.Frontend/proj/Ngan.Dict.Android/Application.cs:25)、[MainActivity.cs](E:/_code/CsNgan.Dict/Ngan.Dict.Frontend/proj/Ngan.Dict.Android/MainActivity.cs:44)。
- 新增 WSL NativeAOT 腳本：[PublishNativeAot.sh](E:/_code/CsNgan.Dict/Ngan.Dict.Frontend/proj/Ngan.Dict.Android/PublishNativeAot.sh:1)。
- 沒有引用付費 TreeDataGrid 或 `AvaloniaUI.Licensing`。

驗證結果：

- Windows Release：通過，0 errors。
- `Ngan.Dict.Ui` Release：通過，0 errors。
- Android Debug/Mono：通過，0 errors。
- NativeAOT 腳本未實跑：本機有 NDK r27c，但 WSL 回報沒有可啟動的 Linux 發行版。
- Windows Debug 構建曾被你正在運行的舊程序鎖住 DLL；停止並重新啟動程序後，才能看到新的表格修復。
````
	]
	
	-T[2026_0727_214019][
		你改完之後 TreeDataGrid列不可排序。
		然後列不能調寬度。
		橫向顯示不下之後也不能橫向滾動。
		看看有沒有辦法解決。
		實在不行就算了。
	][
````md
有辦法，而且都能集中在兼容層解決，不需要修改每個業務頁。

原因與方案：

- 列調寬：目前被 `CanUserResizeColumns = false` 主動關閉，改成 `true` 即可。
- 排序：目前被主動關閉。可為每個 `TextColumn` 設置 `CustomSortComparer`，直接使用原有的 `Getter` 比較行值，因此即使是 `x => GetIdxText(x)` 這類表達式也能排序。
- 橫向滾動：設置 `HorizontalScrollBarVisibility = Auto`。用戶把列拖寬至超過視口後，DataGrid 應顯示水平滾動條。
- 最後的 `Star` 列仍會初始填滿剩餘寬度；拖動後若 DataGrid 仍強制重新壓縮，再考慮把兼容層中的 `Star` 轉成帶最小寬度的固定列。先不做這個行為變更。

建議先實施前三項，改動只涉及兩個兼容層文件。要我直接改嗎？
````
	]
	
	-T[2026_0727_214631][
那你去改改。
	][
````md
已改完，集中修改兼容層：

- 開啟列拖動調寬。
- 開啟點擊表頭排序。
- 排序使用每列原有 Getter 比較，不依賴反射。
- 水平滾動條設為 `Auto`，列拖寬超過視口後應出現。
- 沒有修改任何業務表格頁面。

`Ngan.Dict.Ui Release` 編譯通過，0 errors。

請重啟 Windows 程序測試。若最後一個 `Star` 列仍阻止水平滾動，再考慮只調整兼容層的 Star 列策略。
````
	]
	
	-T[2026_0727_214300][
		安卓NativeAOT編譯的腳本好像跑不了。
		你去wsl裏跑試試。
		記住 用wsl的時候必須在沙箱外執行。
	][
````
````
	]
	
	
	
]
