#import "@preview/tsinswreng-auto-heading:0.1.0": auto-heading
#let H = auto-heading;
\-\-\-

name: write-csharp-code

description: 編寫C\#代碼

\-\-\-

`<項目根目錄>/Doc/Spec/`
這個目錄下有項目說明和代碼規範。

#H[Common.typ][
	通用
]

#H[DocSpec.typ][
	在代碼加註釋文檔的規範
	(大多數情況你不需要讀此文件 除非明確要求)
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
#H[Ctrlr.typ][
	WebApi 端點層(Controller) 規範
]
#H[IView.typ][
	前端接口 IViewXxx 規範與實現規範
]


#H[skill][
	在 .agents/skills/下
	
	有
	#H[ngaq-code-doc][
		業務代碼文檔介紹
	]
]

#H[寫代碼前該看哪些文件][
*Common.typ是必看項*

ngaq-code-doc 也看、知道在哪裏找文檔

根據當前分配的任務、看看要用哪些skill

其次、根據你這次要做的任務、在上述文件中挑選你所需的來看。
比如我現在要你做前端的任務、你就得看Frontend.typ文件、別的就先不看。
]

#H[寫代碼時嚴格按照規範][
	
]

#H[寫完代碼之後做甚麼][
	按 ngaq-code-doc 的規範 更新文檔
	*除非用戶明確要求、不要給我跑編譯！*節約token
]


再次強調三點:
- 所有代碼必須兼容AOT
- 可迭代集合應當保持流式、禁止用ToList()或類似API全部加載到內存裏
- 代碼要有註釋!代碼要有註釋!代碼要有註釋! 最起碼的 函數參數 返回值要寫清楚。函數內部實現該寫註釋的也要寫註釋


*遇到任何疑問/不確定 立即停下手頭的工作 來找我確認！*
疑問包括:
- 你不確定的地方
- 你覺得有設計問題的地方
	- 比如讓你在當前框架下實現指定功能會很彆扭或者難以實現、這時候你應該停下來和我確認、看看是不是我設計有誤、不要硬着頭皮做下去。
*建議多問 不要帶着疑問幹活*
