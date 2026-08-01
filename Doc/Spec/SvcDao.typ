#import "@preview/tsinswreng-auto-heading:0.1.0": auto-heading
#let H = auto-heading;

#H[Dao][
	數據訪問層
	
	- 命名規範: DaoXxx
	- 可以在此層寫 Sql 與調用 IRepo
]

#H[Svc][
	`Service`之簡稱
	
	- 命名規範: SvcXxx
	- 可在此層調用 Dao 與 IRepo
	- 不應在此層直接寫Sql
	
	- 前端不應直接依賴SvcXxx
	- 規範做法: 做一個 `ISvcXxx` 接口、前端通過接口來訪問。
	#H[事務相關][
一般的涉及操作數據庫的函數、第一次參數通常定義爲 `IDbFnCtx Ctx`、用上下文來儲存數據庫連接與事務
```cs
public interface ISvcKv{
	// ISvc接口中定義的API 涉及修改數據庫的 一定要在事務中執行
	// 函數第一個參數定義成`IDbFnCtx? Ctx`
	// 若傳入的Ctx不爲null則使用傳入的上下文 若爲空則自己開一個帶事務的上下文
	// 這樣前端通過接口調用API時就有事務了。
	// 優先定義批量API
	public Task<nil> OrdSet(
		IDbFnCtx? Ctx
		,IAsyncEnumerable<PoKv> Kvs, CT Ct
	);
}

public class SvcKv:ISvcKv{
	//此函數是 ISvcKv 的方法實現
	[Impl]
	public async Task<nil> OrdSet(
		IDbFnCtx? Ctx,
		IAsyncEnumerable<PoKv> Kvs, CT Ct
	) {
		//如果操作涉及修改數據庫即需用RunInTxnIfNoCtx
		//如果是純讀 則用 Ctx??=new DbFnCtx();
		return await SqlCmdMkr.RunInTxnIfNoCtx(Ctx, Ct, async(Ctx)=>{
			return await OrdSet(Ctx, Kvs, Ct);
		});
	}
}

```
		#H[UserCtx][
			`/Ngan.Dict.Core/Shared/User/UserCtx/IUserCtx.cs`
			常用API:
			- `UserCtx.UserId`
			
			Svc層中、若函數的前兩個參數爲`IDbFnCtx? Ctx, IUserCtx User`、
			則應改定義成 `IDbUserCtx`
			`/Ngan.Dict.Core/Infra/DbUserCtx.cs`
			以減少重複參數數量
		]
	]
	

]

#H[調用其他批量函數的規範][
	- 善用 BatchCollector
	- 調用支持批量操作的函數的時候 避免在for循序中多次調用且每次調用時只傳一個參數
		- 接收批量參數的函數 你就得批量地傳 不能把原本成批量的數據拆成一個 逐個傳
]

#H[安全相關][
	對于 實現了 I_Owner接口的 實體、操作該實體時、
	調用Ngan.Dict.Core/Shared/Base/Models/Po/I_Owner.cs 下 的 CheckOwner 擴展方法
	
	要求: 在 Svc和Dao 及 必要的其他地方
	
	添加和修改操作時 要對待添加實體過一遍 CheckOwner 方法。
	CheckOwner方法無誤後會原樣返回。故直接
	`entities = CheckOwner(entities)`
]

#H[異常處理][
	Doc/Spec/Err.typ
	
	Svc層應拋出 項目自定義的異常 即 ItemsErr中的異常
	#H[幾種常用異常][
		#H[ItemsErr.Common.DataIllegalOrConflict][
			數據不合法或衝突。
			當Svc中的添加或修改操作失敗時、默認拋出此異常。
		]
		上述兩種情況是一般/默認場景的情況、若定義了更細分的專用異常則應用㞢。
	]
	
]
