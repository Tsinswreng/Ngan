#import "@preview/tsinswreng-auto-heading:0.1.0": auto-heading
#let H = auto-heading;

數據庫操作規範

*所有操作都要兼容AOT!!!*

#H[使用的庫][
	#H[ORM][
		- 自研的`Tsinswreng.CsSql`
		#H[文檔][
			在`CsDeclOut/Tsinswreng.CsSql/`
				- 優先看`<項目根目錄>/CsDeclOut/`下的文檔、以節約Token
				- 不建議直接翻`<項目根目錄>/Tsinswreng.CsSql/`下的代碼
		]
		#H[常用API][
			#H[表對象][
				`CsDeclOut/Tsinswreng.CsSql/ExtnITable.cs`
			]
			#H[常用Crud操作][
				`IRepo`
				- (IRepo中、以Fn開頭且返回內部函數的函數已廢棄、不建議用)
			]
			#H[`SqlSplicer`][
				- 需要寫Sql時 能用 `SqlSplicer` 實現的就不要用字符串拼Sql。
				- 如果 `SqlSplicer` 缺少功能但該功能易于實現則優先爲 `SqlSplicer` 補上該功能
				- 實在不行再考慮字符串拼sql
			]
			
			#H[代碼實體與數據庫表間的字段與類型映射][
				代碼: 指*編程語言*的代碼、在當前項目中 「代碼」 即指 C\# 代碼
				
				幾個基本概念
				- 列:
					- CodeCol: 代碼中實體類的字段名
					- DbCol: 數據庫表中的列名
				- 值: 
					- UpperValue: 代碼中實體類的值
					- RawValue: 未經映射的 初從數據庫取出的值
				- 字典:
					- UpperDict/CodeDict: CodeCol -> UpperValue
					- RawDict/DbDict: DbCol -> RawValue
				
				例(非本項目代碼風格、僅展示概念):
				```cs
				public enum EStatus{ON=0,OFF=1}
				public class User{
					public IdUser Id{get;set;}
					public str Name{get;set;}
					public EStatus Status{get;set;}
				}
				var u = new User{
					Status = EStatus.ON
				}
				```
				
				```sql
				CREATE TABLE "user"(
					"id" BLOB PRIMARY KEY
					,"name" TEXT
					,"status" INT
				)
				```
				以 Status字段爲例
				#table(
					[CodeCol],[DbCol],[UpperValue],[RawValue],
					[`nameof(User.Status)`],[`status`],[`EStatus.ON`],[`0`]
				)
				
				*在本項目中、我們會使數據庫表的列名與代碼中定義的實體字段名保持一致*
			]
			#H[在Sql中引用成員名][
				- 需要獲取成員名旹、若有[能用表達式樹拿到成員名]的API 就不要用nameof、
				- 例: 有`T.Fld(x=>x.Id)`就勿用`T.Fld(nameof(MyEntity.Id))`
				- 實在沒有纔考慮nameof。但是*絕對禁止硬編碼字段與表名*!
			]
		]
	]
	#H[強類型Id][
		命名: Id+實體名 如`IdUser`
		
		內部封裝了 UInt128、生成的羅輯是ULID (前48位是unix毫秒時間戳、後80位是隨機數)
		
		在數據庫存儲時被映射到`byte[]`類型
	]

]

#H[批量操作][
	
	此處的批量操作 包括讀與寫的批量 不只是寫入的批量。
	
	*!!設計 讀寫數據庫相關的函數, API時 優先提供批量版本!!*
	批量函數接收參數時 優先用 `IAsyncEnumerable<>` !
	
	實現量操作旹, 一般有兩種思路
	
	一種是使用專爲批量設計的sql語法 如 `IN`子句 但是這種做法適配性有限、與非批量寫法差異較大、
	且IN子句不保證返回順序
	
	所以一般只有在 只操作單個字段的時候、我們纔考慮用`IN`子句的批量實現
	
	其他大多數時候都是用 基于拼接同結構sql語句的批量操作
	
	#H[基于拼接同結構sql語句的批量操作][

		原理: 把多個同結構的Sql語句拼進同一個sqlCmd.CommandText中, 一次執行多條sql語句。
		以下簡體「同構批量」

		代碼示例
		
		```cs
using Tsinswreng.CsSql;
using IStr_Obj = IDictionary<str, obj?>;
public class DaoWord{
	public async Task<IAsyncEnumerable<IdWord?>> OrdSlctIdByOwnerHead(//同構批量函數名稱必須以Ord開頭
		IDbFnCtx Ctx, //涉及同構批量的函數 第一個參數必須爲IDbFnCtx Ctx
		IdUser Owner, IAsyncEnumerable<str> Heads // 優先接收異步迭代器
		,CT Ct // 異步函數必須以CT Ct參數結尾、函數名不另加Async後綴
	){
		//此處使用了 SqlSplicer 工具、文檔見 CsDeclOut/Tsinswreng.CsSql/ISqlSplicer.cs
		// T是Dao的成員變量 代表ITable<PoWord>
		// 此處的Sql的類型是 IAutoBindSqlDuplicator 、 不是str
		var Sql = T.SqlSplicer().Select(x=>x.Id).From().WhereNonDel() //.From()不傳參數則默認用T的表名; 
		// WhereNonDel 即排除 被軟刪除的 一般首選 WhereNonDel
		.AndEq(x=>x.Owner, y=>y.One(Owner))//綁固定參數、後期生成多條同結構sql時 此位置的實參始終于同一個
		.AndEq(x=>x.Head, y=>y.Many(Heads))//綁定列表參數、後期生成多條同結構sql時 此位置的實參爲列表對應位置的元素
		;
		// Many支持  Many(myItbl, x=>x.NeededField)這種寫法
		
		var GotDicts = SqlCmdMkr.RunBatSql(Ctx, Sql, Ct);//返值類型爲 IAsyncEnumerate
		return GotDicts.Select(x=>{
			if(x is null){
				return null;
			}
			//因为在Sql中我們只Select了Id一個字段、所以取得的字典只有 Id一個鍵
			//結果字典的鍵名 和 程序中實體類的字段名相同、與數據庫的列名未必相同
			// 用 T.Memb(x=>x.SomeField)獲取 實體類的字段名、也可以用 nameof(PoMyEntity.SomeField)
			// 從數據庫取出的裸Id是 byte[]、後轉自定義強類型Id
			var ans = x[T.Memb(x=>x.Id)];
			return (IdWord?)IdWord.FromByteArr((u8[])ans!);
		});
	}
}
		```
	]
	
	#H[函數命名規範][
		- 批量函數 若返回的可迭代集合元素做不到與入參元素位置一一對應(無則對應null)、則函數命名不得以 `Ord`開頭;
			- (同構批量應以Ord開頭)
			例: 
			- `OrdScltEntityById` 表示 返回的可迭代集合元素與入參元素位置一一對應。 
			- `ScltEntityInId` 函數命名中明確提及`IN`返回的可迭代集合元素與入參元素位置不一一對應。
	]
]

#H[文件命名][
	- `IRepo<TEntity>`: 通用倉儲類、封裝了常用且通用的Crud方法。接口見`CsDeclOut\Tsinswreng.CsSql\IRepo.cs`
	- `DaoXxx`: 數據訪問層。寫Sql操作數據庫
	- `SvcXxx`: 服務層、寫業務理則。不應直接在此層寫Sql操作數據庫、可調用DaoXxx或RepoXxx
]

#H[常用API(重要)][
	#H[表][
		在`<項目根目錄>/CsDeclOut/Tsinswreng.CsSql/`下:
		- `ITable.cs`
		- `ExtnITable.cs`
		- `IRepo.cs`
	]
	#H[常用工具][
		在`<項目根目錄>/CsDeclOut/Tsinswreng.CsSql/CsTools/`下:
		- `BatchCollector.cs`  *這個很重要！至少這個文件你必須得先看過一遍！*
		//AutoBatch
	]
	#H[分頁][
		在`<項目根目錄>/CsDeclOut/Tsinswreng.CsSql/CsPage/`下:

	]

]

#H[其他有用的工具(你不一定會用到、按需讀取)][
	- 分頁模型: `IPageAsyE<>`
		- 在CsDeclOut/Tsinswreng.CsPage/下
	- 攢批發送: `BatchCollector`
		- 在CsDeclOut/Tsinswreng.CsTools/下
]

#H[注意事項][
	- 默認情況下、查找的數據都是不包含被軟刪除的。使用SqlSplicer時記得`.WhereNonDel()`
		- 如果明確希望查找的數據包含已刪除的條目、則方法要帶上`WithDel`後綴
]

#H[事務][
非純查詢的函數、最終在Svc層作API導出旹必須要帶事務

寫法如下
```cs
public class SvcWord{
	public async Task<nil> OrdInsertJnWord(IAsyncEnumerable<IJnWord> Words, CT Ct){
		await SqlCmdMkr.RunInTxn(Ct, async(Ctx)=>
			DaoWord.OrdInsertJnWord(Ctx,Words, Ct)
		);
		return NIL;
	}
}
```
]

#H[調用其他批量函數的規範][
	- 善用 BatchCollector
	- 調用支持批量操作的函數的時候 避免在for循序中多次調用且每次調用時只傳一個參數
		- 接收批量參數的函數 你就得批量地傳 不能把原本成批量的數據拆成一個 逐個傳!
	錯誤示例:
	```cs
	void fn(IDbUserCtx Ctx, IAsyncEnumerable<MyObj> Itbl, CT Ct){
		await foreach(var obj in Itbl){
			//這種情況是 拆散批量 變逐個傳 性能極差
			OrdHandleObj(Ctx, ToolAsyE.ToAsyE([obj]), Ct);
		}
	}
	```
	
	正確示例:
	用`BatchCollector`。 後文有示例。
]

#H[廢棄的閉包模式][
	原架構中使用的模式爲
	以Fn開頭的操作數據庫的函數返回一個內部函數、在外層函數做命令初始化與預編譯等、在內部函數做實際數據庫操作。
	
	當前 這種模式已經被棄用、請改用 IAsyncEnumerable批量+BatchCollector(如需要)的模式。
]


#H[BatchCollector 示例][
完整Api在`<項目根目錄>/CsDeclOut/Tsinswreng.CsSql/CsTools/`下:
- `BatchCollector.cs`  *這個很重要！至少這個文件你必須得先看過一遍！*
```cs
public async Task<nil> OrdUpsert(
		IDbFnCtx Ctx, IAsyncEnumerable<TEntity> Ents, CT Ct
	){
	var batchSize = T.DbStuff.DfltOptBatch.DupliSqlBatchSize;
	var batch = new BatchCollector<TEntity, nil>(async(EntList, Ct)=>{
		//此處的 EntList 是 IList<TEntity>、只包含了當前批次的實體
		// 因此他不會把所有IAsyncEnumerable<TEntity> Ents一次性載入內存、滿足流式加載、空間複雜度O(常數)
		var ids = EntList.Select(x=>(TId)T.GetEntityId(x)!).ToAsyncEnumerable();
		var existList = OrdExistsById(Ctx, ids, Ct);
		var toInsert = new List<TEntity>();
		var toUpdate = new List<TEntity>();
		await foreach(var (i,isExist) in existList.Index()){
			var ent = EntList[i];
			if(isExist){
				toUpdate.Add(ent);
			}else{
				toInsert.Add(ent);
			}
		}
		await OrdAdd(Ctx, ToolAsyE.ToAsyE(toInsert), Ct);
		await OrdUpd(Ctx, ToolAsyE.ToAsyE(toUpdate), Ct);
		return NIL;
	},batchSize);//此batchSize是可選參數、有默認值。
	await batch.ConsumeAll(Ents, Ct); //因爲此方法是 寫 操作、故用ConsumeAll。他會把Ents 轉成List、確保消費。如果是讀操作則可用return AddToEnd(Ents, Ct)
	return NIL;
}
```
]
