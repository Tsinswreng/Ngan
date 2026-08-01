// this project use utf-8
#import "@preview/tsinswreng-auto-heading:0.1.0": auto-heading
#let H = auto-heading;

#H[Encoding][
if you use PowerShell to write file,
do not use the default encoding of `Set-Content`/`Out-File`,
use `Set-Content -Encoding UTF8` or `.NET`'s `new UTF8Encoding(false)` instead.

this project use utf-8. and the following content is written in Chinese.
If you find the following content is already mis-encoding, switch your command and specify to use utf8 and re-read this file again.
]



`E:/_code/CsNgan.Dict/Doc/Spec/`
這個目錄下有項目說明和代碼規範。

#H[Common.typ][
	通用
]

#H[DocSpec.typ][
	在代碼加註釋文檔的規範
	(大多數情況你不需要讀此文件 除非明確要求)
]
#H[CodeDoc.typ][
	在C\#代碼中撰寫目錄文檔的規範 (大多數情況你不需要讀此文件 除非明確要求)
]
#H[Db.typ][
	數據庫操作相關、主要包含自研ORM用法
]
#H[Entity.typ][
	實體類相關
]
#H[Frontend.typ][
	前端相關
]
#H[MapEtSerialization.typ][
	對象映射與序列化、包括 json 與 `IDict<str, obj?>`的操作
]
#H[Cfg.typ][
	配置文件用法 (大部分情況下你不需要讀配置文件)
]
#H[Proj.typ][
	項目結構介紹 (按需閱讀、如果你要做的任務只是一個小功能就可以先不看整個項目結構的介紹)
]
#H[EntryStartup.typ][
	三個入口程序集啓動流程說明 (`Ngan.Dict.Windows` / `Ngan.Dict.Windows.Test` / `Ngan.Dict.Server.Http`)
]
#H[Err.typ][
	自研異常處理框架 (寫業務邏輯可能會涉及到)
]
#H[Dto.typ][
	數據庫傳輸對象規範 (寫Svc和Dao層的函數時可能會涉及)
]
#H[SvcDao.typ][
	Serivce 和 Dao 規範
]
#H[Typst.typ][
	typst文檔(.typ) 撰寫規範 (大多數情況你不需要讀此文件)
]
#H[DbMigration.typ][
	數據庫遷移 (大多數情況你不需要讀此文件)
]
#H[SepDeclEtImpl.typ][
	分離 聲明 與 實現
]

#H[該看哪些文件][
*Common.typ是必看項*

根據當前分配的任務、看看要用哪些skill

其次、根據你這次要做的任務、在上述文件中挑選你所需的來看。
比如我現在要你做前端的任務、你就得看Frontend.typ文件、別的就先不看。
]



*遇到任何不確定的地方一定要先問我。*
*遇到任何疑問 立即停下手頭的工作 來找我確認！*
*建議多問 不要帶着疑問幹活*

再次強調三點:
- 所有代碼必須兼容AOT
- 可迭代集合應當保持流式、禁止用ToList()或類似API全部加載到內存裏
- 代碼要有註釋!代碼要有註釋!代碼要有註釋! 最起碼的 函數參數 返回值要寫清楚。函數內部實現該寫註釋的也要寫註釋
