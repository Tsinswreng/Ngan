#import "@preview/tsinswreng-auto-heading:0.1.0": auto-heading
#let H = auto-heading;
\-\-\-

name: ngan-dict-code-review-frontend

description: 審查C\#代碼(前端專用)

\-\-\-

#H[通用規範][
	先自己看一遍 `skill/ngan-dict-code-review`。
	如果你無法訪問skill 就手動翻閱
	`.agents/skills/ngan-dict-code-review/SKILL.typ`
]

#H[前端規範][
	- 如果你當前檢查的代碼不是前端代碼則無需理會此章節。
	- 如果是前端代碼但你無法訪問後面提及的參考文檔 則應向我匯報

	使用`Tsinswreng.AvlnTool`下的寫法。參見
	`/Doc/Spec/Frontend.typ`。

	示例:
	Ngan.Dict.Frontend/proj/Ngan.Dict.Ui/CodeTemplate/Sample/ViewSample.cs
	Ngan.Dict.Frontend/proj/Ngan.Dict.Ui/CodeTemplate/Sample/VmSample.cs

	#H[I18n][
		項目要求I18n。禁止硬編碼文字。
		快速實現時臨時硬編碼則需先打I18n標記。

		錯誤示例
		```cs
		btn.Content="Login"
		```
		正確示例:
		```cs
		btn.Content=Todo.I18n("Login")
		```
		下拉框 等 也要I18n、除非數據源是從後端獲取
	]
	#H[MVVM][
		遵守MVVM模式。
		- 不能在Vm層操作View層的任何東西  包括控件/ 做頁面跳轉 等
	]
	#H[UI寫法][
		- #[添加子控件時使用使用鏈試調用的`.A()` 方法
				能鏈式調用就必須鏈式調用 如
				```cs
				p.A(aaa)
				.A(bbb)
				;
				```

				禁止拆散寫如
				```cs
				p.A(aaa);
				p.A(bbb);
				```
				Styles也同理、必須.A()鏈式調用
			]
		- #[初始化`ContentControl.Content`時使用`o.SetContent(xxx)`;
				不得直接`o.Content=xxx`。
				Border也同理、必須使用`o.SetChild(xxx)`方法。
			]
		- #[
				Grid 必須使用 `g.SetRowDefs()` / `g.SetColDefs()`、
				不能寫 `g.RowDefinitions=...`。
				GridStack同理。GridStack不能寫`g.Grid.SetRowDefs()`、只能寫`g.SetRowDefs()`
			]
		- #[
				組織子控件並加入控件樹時、代碼塊的嵌套 要和 樹的邏輯結構 保持一致 (詳見 ViewSample.cs)
				不能全寫到同一層
			]
		- #[
				能直接寫 `= new(...);` 的 就不要寫 `= new SomeType(...);`。
				如要寫`b.BorderThickness = new(0);`而不是`b.BorderThickness = new Thickness(0);`
			]
		- 避免硬編碼字體大小;
		- 按鈕綁定的事件是 調用後端接口/異步函數/耗時操作 的、必須用`OpBtn`而不是普通 `Button`
		- 避免重複的樣式設置代碼！當出現重複時 考慮用以下兩種辦法抽取複用: 1. 用工廠函數反回設好樣式的控件; 2. 用Avalonia的Classes/Styles系統 爲需要設置相同樣式的控件分配類名並統一設計
	]
	#H[ViewModel寫法][
		#H[按鈕綁定耗時任務(如調用後端異步或同步接口)][
			- 用 `await Task.Run(async()=>{})`
			- 更新UI要 `Dispacher.UIThread.Post(()=>{})`
			- 記得try catch
			具體 看 VmSample.cs
		]
	]
	#H[View層初始化規範][
		- 只在View的構造函數中 做 UI初始化相關操作(包含 初始化`this.Content`, 初始化`this.Ctx`, 初始化`this.Styles`)、除此之外 一般不應該在構造函數中做其他事。
		- 如果希望在進入界面的時候做一些其他的初始化操作 如調用接口獲取數據/耗時操作 等、應放在`this.Loaded`回調中。
	]
	#H[文件位置][
		不能在同一文件夾下放置多個不同的View和Vm
	]
]

#H[當代碼不符合上述規範時如何處理][
	默認情況下、直接把代碼中不符合規範的內容報告給用戶、不需要自行修改代碼。

	如果用戶已經要求你自行迭代修改代碼 那就自行修改。改完一版之後再讀此文件對照評審。
]
