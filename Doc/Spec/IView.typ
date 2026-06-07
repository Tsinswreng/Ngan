#import "@preview/tsinswreng-auto-heading:0.1.0": auto-heading
#let H = auto-heading;

#H[`IView`規範][
`IView` 指 前端頁面契約接口。

它的定位不是 `ViewModel` 接口、也不是控件樹聲明、
而是 *用戶可觀察/可操作行爲* 的抽象。

用此模式、可使前端像後端的 `ISvc` 一樣:
- 先手寫抽象
- 再讓AI實現 `View + Vm + Converter`
- 最後只對接口做測試
]

#H[目標][
- 讓前端也能採用「先定契約、後寫實現、最後測接口」的協作模式
- 讓測試入口更接近真實用戶操作
- 使 `View -> Converter -> Vm -> Svc -> DB` 整條鏈路可被驗證
- 使代碼審查時 先看契約 再看實現
]

#H[`IView` 的邊界][
`IView` 表達的必須是 *頁面語義*、不是實現細節。

應當放入接口的內容:
- 用戶可輸入的原始值。如 `RawHead`、`RawStoredAt`
- 用戶可點擊的動作。如 `ClickSave()`、`ClickDelete()`
- 用戶可讀取的輸出。如 `ErrorText`、`Descrs`
- 用戶能感知到的狀態。如 `IsLoading`、`VisibleWordCount`

不應放入接口的內容:
- 具體控件類型 如 `TextBox`、`Button`
- 佈局細節 如 `GridRow3Text`、`BtnBottomLeft`
- `ViewModel` 內部強類型字段
- 純內部輔助狀態
]

#H[設計規範][

	#H[保持薄接口][
		先只放測試真正需要的能力。
		不要一開始就把整個頁面所有控件全暴露出去。

		若後續測試需要更多行爲、再增量擴展接口。
	]
]

#H[實現規範][
	#H[接口由 View 實現][
		`IViewXxx` 應當由 `ViewXxx` 實現。

		不應當由 `VmXxx` 實現。

		因爲:
		- 用戶交互入口在 `View`
		- `Converter` 位於 `View` 與 `Vm` 之間
		- 若讓 `Vm` 實現、就繞過了綁定與轉換鏈路
	]

	#H[必須從控件讀寫][
		*這是最重要的規則。*

		`IView` 的實現、必須從 *實際控件* 讀取或寫入值。

		禁止:
		- getter 直接返回 `Ctx` / `Vm` 中的值
		- setter 直接寫 `Ctx` / `Vm`
		- 爲了省事 繞過控件與綁定鏈路

		因爲 `IView` 測試的目的之一、
		就是覆蓋 `View -> Converter -> Vm` 這段鏈路。

		若直接讀寫 `Ctx`、則測不到:
		- 控件綁定是否接對
		- converter 是否正確
		- 顯示層是否真的更新
	]

	#H[正確示例][
		```cs
		
		```
	]


	#H[實現類內部可以有控件抓手][
		爲了實作 `IView`、允許 `View` 類保存少量控件引用。

		如:
		- `public TextBlock? HeadTextCtrl{get;set;}`
		- `public TextBox? TbHead{get;set;}`
		- `public Button? BtnSave{get;set;}`
		- `public List<Control> DescriptionTextCtrls{get;set;}`
		

		但這些控件抓手 *只放在實現類中*、
		不要暴露到接口中。
	]

	#H[不要讓接口污染頁面結構][
		爲了支持 `IView` 接口、可以在 `View` 類內補少量控件引用字段。

		但不要因爲接口存在、
		就把整個 `View` 結構改成“到處都是公開控件字段”的樣子。

		接口只負責契約、
		控件抓手只作爲實現細節。
	]
]

#H[與 `ViewModel` 的分工][
- `IView` 負責原始輸入/輸出與點擊動作
- `Converter` 負責字符串與強類型之間轉換
- `Vm` 負責業務狀態、規則判斷、服務調用

禁止把以下邏輯留在 `View` 裏:
- 業務判斷分支
- 保存前 DTO/Po/JnWord 組裝
- 導航目標決策
- 調 service 前數據清洗

若 `View` 中出現上述邏輯、應下沉到 `Vm` 或 helper。
]

#H[測試規範][
	#H[測甚麼][
		測 `IView` 時、重點驗證:
		- 原始輸入是否真的進入頁面
		- 點擊是否真的觸發
		- 顯示文本是否真的從頁面讀出
		- 綁定/轉換鏈路是否接通

		如果涉及改庫:
		- 自行準備種子數據
		- 操作 `IView`
		- 查庫驗證結果
		- 最後還原數據庫
	]

	#H[不要只測 `Vm`][
		`Vm` 測試仍然重要、
		但 `IView` 測試更接近真實用戶操作。

		推薦分層:
		- `IView` 作爲高層契約測試
		- `Vm` 作爲主要業務測試
		- `Converter` 作爲純函數邊界測試
	]
]

#H[注意事項][
- `IView` 不等於控件樹接口
- `IView` 不等於 `Vm` 接口
- `IView` 不應直接暴露平臺控件類型
- `IView` 的 getter/setter 不準偷讀偷寫 `Ctx`
- 若接口能力不夠用、先擴展接口、不要繞過契約亂測
]
