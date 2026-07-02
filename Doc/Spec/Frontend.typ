#import "@preview/tsinswreng-auto-heading:0.1.0": auto-heading
#let H = auto-heading;
前端代碼規範
#H[項目技術棧][
- 語言C\#
- 平臺: .NET 10 AOT發佈(所有代碼必須兼容AOT)
- 框架: Avalonia (純C\# 不用Xaml)
//- UI工具庫: `<項目根目錄>/CsDeclOut/Tsinswreng.AvlnTools/`
- 因爲要一套UI同時兼容移動端平臺與桌面端平臺、所以所有UI佈局都按豎屏移動端的來做

]

#H[架構][
- MVVM模式

#H[規範示例(*重要!下面列出的文件一定要看！*)][
- `Ngaq.Frontend/proj/Ngaq.Ui/CodeTemplate/Sample/ViewSample.cs`
- `Ngaq.Frontend/proj/Ngaq.Ui/CodeTemplate/Sample/VmSample.cs`
- `Ngaq.Frontend/proj/Ngaq.Ui/Infra/ViewModelBase.cs`
- `Ngaq.Frontend/proj/Ngaq.Ui/Views/MainView.Decl.cs`
]


#H[模板(可不看)][
- `Ngaq.Frontend/proj/Ngaq.Ui/CodeTemplate/ViewXxx.cs`
- `Ngaq.Frontend/proj/Ngaq.Ui/CodeTemplate/VmXxx.cs`
]

]


#H[UI設計風格][
	- 不要圓角
]

#H[常用工具][
帶標題修飾器:
`Ngaq.Frontend\proj\Ngaq.Ui\Tools\ToolView.cs`

#H[視圖導航][
用ViewModelBase的
```cs
public IViewNavi? ViewNavi{get;set;}
```
]
]

#H[UiCfg][
`Ngaq.Frontend\proj\Ngaq.Ui\UiCfg.cs`
內有字體大小, 主題色與窗口大小。
]


#H[字體大小設置][
	勿硬編碼字體大小
	應當用`UiCfg.Inst.BaseFontSize` 乘以一個系數
]

#H[AI調用後端接口的注意事項][
	- 當你正在做 純前端的任務時、你只需看用戶提供給你的接口文件即可。
	- 不要翻閱實現的部分、節約token。
	- 當你進行純前端的任務時、你只能通過interface等 調用後端API。
		- 不要查看函數實現
		- 更不能修改(包括新增)函數實現。
	- 如果你發現當前給你提供的接口 不夠用、有些操作無法實現時、應當*請示用戶*、禁止擅自亂動！
		- 也不要用不適宜的接口去強行適配你的操作！(分頁接口只用于分頁查詢批量數據、不要拿他當查詢特定實體的接口用！)
]

#H[項目使用到的圖標][
	`Ngaq.Frontend/proj/Ngaq.Ui/Icons/Icons.Decl.cs`
	禁止讀 Icons.Impl.cs 文件! 否則會消耗大量token
]

#H[文件(命名空間)位置][
	- View和ViewModel(Vm)放在同一文件夾下。
	- 用來放View 和 Vm的文件夾 除了本View和Vm之外 不要再放別的View和Vm！

	正確示例
	```
	WordCard/
		ViewWordCard.cs
		VmWordCard.cs
	WordInfo/
		ViewWordInfo.cs
		VmWordInfo.cs
	```
	
	錯誤示例
	```
	Word/
		ViewWordCard.cs
		VmWordCard.cs
		ViewWordInfo.cs
		VmWordInfo.cs
	```
	
	多數情況下、View和Vm應該一一對應。少數情況下可以不這樣。(如多個View共同一個Vm)
]

#H[跨平臺要求][
	確保`Ngaq.Core`和`Ngaq.Ui`兩個程序集 是 平臺無關的(即跨平臺的、包括Web平臺)
	禁止直接在 Ngaq.Ui 裏面使用任何 非跨平臺的API 如
	- 讀寫文件(Web端不支持)
	- 硬耦合特定操作系統特定API(如剪貼板等)

要讀文件就用 System.IO.Abstractions
]


#H[DI註冊][
	在`Ngaq.Frontend/proj/Ngaq.Ui/DiUi.cs`
	如果你的 ViewModel 需要被注入服務、那你需要在 DiUi中註冊 ViewModel。
]
