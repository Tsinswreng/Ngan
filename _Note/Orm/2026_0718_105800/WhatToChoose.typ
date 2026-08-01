-Sesn[
	-T[2026_0718_105824][
		我想要一個C\#的ORM。
		我目前的主要使用場景包括:
			- #[
			操作 客戶端程序的 數據庫(主要是sqlite)
			既然是客戶端程序 那就得要用AOT編譯
			]
			- #[
				操作 服務端程序的 數據庫(例如postgresql)
				我個人的項目一般都用pg。但也不排除可能會切換到其他數據庫去用。
			]
			我希望這個ORM要支持AOT編譯、支持多種數據庫、
			且能用統一的抽象層屏蔽不同數據庫的差異(這一的理念類似Efcore)。
			
			要求:
			- #[兼容AOT編譯
				
				- Efcore只是實驗性支持、實際配置很麻煩、各種功能都不全、還會極大增大編譯產物的體積
				- SqlSugar/FreeSql 據說支持
			]

			- #[
				要支持自定義類型轉換、即代碼層和Sql層的類型轉換
				如我自己定義代碼層的enum類型對應數據庫層的int或string
				或代碼層的UInt128對應數據庫層的blob 等等
				- Efcore支持
				- SqlSugar/FreeSql當時沒試出來、文檔比較稍、當時我也沒開始用AI Agent
			]
			- #[
				操作數據庫時不要硬編碼符號(如表名 列名)等、要能讓IDE/LSP發揮出 查找引用/重命名符號 的功能
				- EfCore 支持。他是用Linq的
				- SqlSugar/FreeSql 不知道
			]
			
			- #[
				上層抽象可屏蔽數據庫差異、能在不同數據庫源間切換
				- EfCore那些好像都支持
			]
			
			- #[從Dsl生成DDL(建庫建表語句等)、不要自己手寫原始sql。
					要用流式非侵入的寫法、即 不在實體類上打Attr
				- Efcore支持
				- SqlSugar/FreeSql 支持打Attr的寫法、不打Attr的不清楚
			]
			
			
			我現在 CsNgan.Dict這個項目選擇了自研的CsSql。支持上面的所有要求。
			
			CsSql源碼在: `E:\_code\CsNgan.Dict\Tsinswreng.CsSql\proj\Tsinswreng.CsSql\Tsinswreng.CsSql.csproj`
			具體用法參考:
````yaml
    - E:\_code\CsNgan.Dict\Doc\Spec\Db.typ
    - E:\_code\CsNgan.Dict\Doc\Spec\Entity.typ
    - E:\_code\CsNgan.Dict\Doc\Spec\SvcDao.typ
````
			`E:\_code\CsNgan.Dict\Ngan.Dict.Backend\Db\TswG\LocalTblMgrIniter.cs`
			`E:\_code\CsNgan.Dict\Ngan.Dict.Backend\Db\TswG\SchemaCfg\UserWord.cs`
			`E:\_code\CsNgan.Dict\Ngan.Dict.Backend\Domains\Word\Dao\DaoWordV2.cs`
			`E:\_code\CsNgan.Dict\Ngan.Dict.Backend\Domains\Word\Svc\SvcWordV2.cs`
			`E:\_code\CsNgan.Dict\Ngan.Dict.Backend\Domains\Word\Svc\SvcWordV2.Crud.cs`
			
			
			最開始搭基礎的時候CsSql和CsNgan.Dict項目主要是我自己手寫代碼開發的、
			那時候我還沒有用AI智能體。
			
			現在我覺得我的CsSql用起來還是有些問題:
			- #[比較煩瑣
				- 如到處都要傳一個DbFnCtx
				- 批量操作的設計比較煩瑣
				- 新項目的配置比較複雜、做不到開箱即用
			]
			- #[可能有很多Bug和性能問題。
				- 當前CsSql的測試項目未完善。不過功能正確性的測試目前是跟着主程序集一起測的、有Bug就直接改了
			]
			- #[不穩定
				- 還在迭代階段、隨時可能有破壞性變更、若同時給多個項目引用則不便
			]
			- #[其他我沒發現或沒說的問題
				- 你自己看去
			]
			
			我以後可能會開多個涉及數據庫操作的項目。
			你覺得我應該怎麼辦?
			- 結合AI改善CsSql
			- 還是借助AI試驗證其他ORM通不通
			- 或者借助基于其他ORM做二次開發
			- 或者是別的辦法
	][
		
	]
]
