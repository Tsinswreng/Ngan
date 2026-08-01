//此文件爲AI生成 與實際情況可能不符
#import "@preview/tsinswreng-auto-heading:0.1.0": auto-heading
#let H = auto-heading;

數據庫遷移

#H[目標][
	當你需要對*現有數據庫*做結構變更（增表、增列、刪列、改名、索引調整等）時：

	- 保持 `TblMgrIniter` 中的實體映射始終是*最新版*。
	- 另外新增一條「增量遷移」記錄，讓舊庫可升級到最新版。
	- 禁止降級遷移（不做自動 Down）。
]

#H[三層分工][
	- `Tsinswreng.CsSql`
		- 放通用遷移抽象與執行器（`IMigrationMgr`、`MigrationMgr`、`MigrationRunner` 等）。
		- 不放業務遷移內容。

	- `Ngan.Dict.Backend`
		- 放客戶端遷移清單（`UseLocalMigrations()`）與本地遷移類。

	- `Ngan.Dict.Server`
		- 放服務端遷移清單（`UseServerMigrations()`）與服務端遷移類。
]

#H[新增遷移的標準流程][
	#H[先改最新版映射（必做）][
		先在 `TblMgrIniter` 對應位置修改最新版表結構（這一步是權威來源）。

		例如新增 `PoStudyPlan` 系列：

		- 在 `LocalTblMgrIniter` 中補充/調整 `InitStudyPlan()`。
		- 若服務端也用到，確保 `ServerTblMgrIniter` 最終映射含該結構。
	]

	#H[新建一個遷移類][
		在對應程序集新增 `SqlMigrationInfo` 類：

		- 類名建議：`MYYYY_MMDD_HHMMSS_描述`
		- 必填：`CreatedMs`（全局唯一、遞增）
		- `Init()` 中生成 `SqlsUp`

		推薦做法：

		- *純加表/加索引*：直接用 `TblMgr` + DSL 生成 DDL（最不易與最新版不一致）
		- *改名/複雜改造*：可手寫 SQL
	]

	#H[註冊到遷移清單][
		把新遷移加入清單函數：

		- 客戶端：`UseLocalMigrations()`
		- 服務端：`UseServerMigrations()`

		使用 `AddMigrationsIfAbsent([...])` 註冊，按 `CreatedMs` 去重。
	]

	#H[執行方式][
		- 客戶端啓動：
			- 新安裝：建最新版庫 + `MarkAllApplied()`
			- 舊庫升級：`RunPendingMigrations()`

		- 服務端部署：
			- 在部署腳本/工具中調 `MigrationRunner.UpAsy()`，僅執行未應用遷移。
	]

	#H[驗證][
		至少做兩類驗證：

		- 新庫驗證：從 0 建庫後可正常跑。
		- 升級驗證：拿一個舊版本庫，升級後可正常跑。
	]
]

#H[常見變更怎麼做][
	#H[新增表][
		1. 在最新版 `TblMgrIniter` 註冊新表。
		2. 新建一條遷移，輸出該表 DDL。
		3. 註冊遷移。
	]

	#H[新增列][
		1. 先改最新版映射（加屬性、映射、必要索引）。
		2. 遷移 SQL 用 `ALTER TABLE ADD COLUMN ...`。
		3. 如需回填默認值，緊接 `UPDATE ...`。
	]

	#H[刪除列][
		1. 先評估數據保留策略（備份/搬遷）。
		2. 再改最新版映射。
		3. 遷移中做安全刪除（不同方言可能需要中間表策略）。
	]

	#H[改名（表/列）][
		1. 改最新版映射名稱。
		2. 遷移中明確寫 rename SQL（必要時兼容舊查詢過渡）。
		3. 不要依賴自動 diff 猜改名。
	]
]

#H[規則][
	- 每次結構變更都要「*改最新版映射 + 新增一條遷移*」。
	- `CreatedMs` 不可重複。
	- 已發佈遷移只追加，不回寫歷史。
	- 遷移失敗必須整體回滾（單事務執行）。
	- 禁止自動降級。
]

