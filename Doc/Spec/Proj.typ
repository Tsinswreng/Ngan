#import "@preview/tsinswreng-auto-heading:0.1.0": auto-heading
#let H = auto-heading;
#[項目說明]

背單詞軟件
- 技術棧 C\# .NET 10
- 客戶端 Avalonia
- 本地服務端 Sqlite
- Web服務端 Asp.net Core minimal API

*!項目所有程序集都採用AOT編譯。禁止一切不兼容AOT的代碼!*

#H[程序集][
	csproj即程序集。
	#H[Ngan.Dict.Core][
		核心程序集
		- 要求平臺無關(包含Web)
		包含:
		- 通用的基礎設施
		- 實體類定義
			- 前後端通用DTO
		- 平臺無關基礎業務邏輯
		- 接口(interface) 等

		平臺無關的意思是 放在哪裏都能編譯運行。要考慮Web平臺
		所有不能在此程序集中 直接做 文件讀寫, 數據庫操作 等相關IO操作。也不推薦你這麼做、因爲這會破壞架構約定。

		一般的做法是、在此程序集中 定義接口、比如我要操作詞庫 就定義詞庫服務接口、然後在接口中聲明方法。後端程序集再實現接口、在實現的方法體中執行IO操作。

		#H[Shared][
			前後端通用接口, DTO等
		]
		#H[Frontend][
			前端專用接口, DTO等
			
			如自抽象的剪貼板接口
		]
		#H[Backend][
			後端專用接口, DTO等
		]
	]

	#H[Ngan.Dict.Backend][
		後端基礎程序集。 主要負責數據庫IO 等

		本地服務端 與 Web服務端 通用的代碼都被這裏。

		主要有用戶詞庫管理等。
		
		- 當 隨客戶端一起編譯時 連接的數據庫是Sqlite
		- 當 隨Web服務端一起編譯時 連接的數據庫是Pg
	]

	#H[Ngan.Dict.Frontend][
		前端文件夾。Avalonia項目。不是一個單獨的程序集。

		其proj/下有多個程序集。
		#H[Ngan.Dict.UI][
			此程序集同樣要求平臺無關。使用MVVM模式。
			- 包含UI, 交互邏輯 等
			- 此程序集引用程序集:
				- Ngan.Dict.Core 
				- Ngan.Dict.Client
		]
		後續提到的特定平臺的程序集僅有以下職責:
			- 程序入口(有Main方法或頂層語句)
			- 依賴注入 ServiceCollection裝配
			- 平臺特定功能的方法實現
		一般不會有UI、交互邏輯等。
		
		#H[Ngan.Dict.Client][
			Http Client。
			專門用來發網絡請求。
			不能讀寫文件。
			要跨平臺 包括Web平臺
		]
		
		#H[Ngan.Dict.Windows][
			引用以下程序集:
			- Ngan.Dict.UI
			- Ngan.Dict.Backend
			Windows入口。

		]
		#H[Ngan.Dict.Android][
			引用以下程序集:
			- Ngan.Dict.UI
			- Ngan.Dict.Backend
			Android入口。
		]
		#H[Ngan.Dict.Browser][
			瀏覽器入口程序集。
			引用Ngan.Dict.UI但不引用Ngan.Dict.Backend。
			該程序集用wasm跑在瀏覽器上 不能讀寫文件。
			調用後端接口時 全部通過http請求調用。
			
			故Ngan.Dict.Core中定義的接口 ISvcXxx 一般都有兩種以上實現
			一種實現 在 Ngan.Dict.Backend中、作爲非web的客戶端軟件直接讀數據庫;
			另一種實現 在 Ngan.Dict.Client中、作爲瀏覽器入口的Http Client通過http請求調用Server.Http接口。
			其中Server.Http又調用Ngan.Dict.Backend的代碼、只是 數據庫從客戶端的sqlite換成了服務器端的pg。
		]
		後續還有其他平臺特定入口程序集、就不一一列舉了。
		#H[配置文件][
			ExternalRsrc/Ngan.Dict.jsonc
			
			客戶端配置文件
			
			此文件應當與入口exe在同一個目錄下。
			
			開發環境中測試運行時也與exe同一目錄。
			
			該測試文件中定義了客戶端Sqlite的路徑。直接在開發環境中把程序跑起來的話就會連到上面的數據庫。
			裏面的數據的內容是不固定的、就是在開發環境做非自動化的隨手自測時 會改到裏面的數據。
		]
	]
	#H[Ngan.Dict.Test][
		測試目錄。不包含Web服务端测试。
		
		使用的测试框架: 自研 Tsinswreng.CsTreeTest。
		测试用例中使用依赖注入。
		
		按`Test.typ`规范。
		
		其`proj/`下有多個程序集:
		
		#H[Ngan.Dict.Core.Test][
			
		]
		
		#H[Ngan.Dict.Backend.Test][
			
		]
		
		#H[Ngan.Dict.Windows.Test][
			入口程序集。
			引用其他测试程序集。
		]
		- 測試: 指自動化測試、程序自動比較測試用例的預期輸出和實際輸出、批量測試多項
	]

	#H[Ngan.Dict.Server/][
		Web服務端目錄(不是程序集)
		其proj/下有多個程序集。
		#H[Ngan.Dict.Server][
			Web服務端 核心程序集
			
			引用
			- Ngan.Dict.Backend
		]
		#H[Ngan.Dict.Server.Http][
			Web Api程序集。
			
			主要是把Ngan.Dict.Server的接口 實現成Web Api(http)。
			
			引用
			- Ngan.Dict.Server
		]
		
		#H[Ngan.Dict.Server.Test][
			Web 服務端 測試程序集。
			
			引用
			- Ngan.Dict.Server
			- Ngan.Dict.Server.Http
			- Ngan.Dict.Test
		]
		
	]

]

#H[文檔與規範][
	在項目根目錄/Doc下
	#H[Prompt/][
		可複用大模型提示詞
	]
	#H[Spec/][
		代碼規範(不是功能模塊介紹)
	]
]
