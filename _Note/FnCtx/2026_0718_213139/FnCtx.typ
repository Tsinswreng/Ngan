-Sesn[
	-T[2026_0718_213206][
		先看skill、
		然看CsNgan.Dict這個項目。
		然後看 
```yaml
- E:\_code\CsNgan.Dict\Doc\Spec\Db.typ
    - E:\_code\CsNgan.Dict\Doc\Spec\Entity.typ
    - E:\_code\CsNgan.Dict\Doc\Spec\SvcDao.typ
```
		如
		`E:\_code\CsNgan.Dict\Ngan.Dict.Backend\Domains\Word\Svc\SvcWordV2.Crud.cs`
		有沒有甚麼辦法能更方便地在函數間傳上下文?
		
		我的問題是 Dao和Svc裏每個函數都有一個Ctx和一個Ct  比較麻煩。我想要簡化的辦法
	][
明白。你要簡化的是這種普遍重複：

```csharp
FnA(Ctx, ..., Ct)
FnB(Ctx, ..., Ct)
FnC(Ctx, ..., Ct)
```

關鍵要先確認你希望簡化到哪個程度，因為方案完全不同：

1. 合併成一個參數：

```csharp
FnA(FnCtx, ...)
```

其中 `FnCtx` 同時包含 `IDbFnCtx`、`CancellationToken`，Svc 場景還可包含 `UserCtx`。這最安全、改造也最直接，但每個函數仍有一個上下文參數。

2. 函數完全不傳上下文：

```csharp
FnA(...)
```

讓 Dao/Svc 從當前操作作用域中取得 `Ctx` 和 `Ct`。這需要使用以下其中一種機制：

- 每次操作建立一個綁定上下文的 Dao/Svc scope 對象；
- `AsyncLocal` ambient context；
- 將上下文放進 Dao/Svc 實例字段。

後兩種有並發和上下文洩漏風險，能否使用取決於 Dao/Svc 實例生命週期。

所以我需要你確認兩點：

- 你想要的是「合成一個 `FnCtx` 參數」，還是「普通內部函數連 `FnCtx` 都不用傳」？
- 同一個 `SvcWordV2`／`DaoWordV2` 實例，是否可能被多個異步操作並發調用？

我目前傾向推薦「每次操作建立綁定上下文的 scope 對象」：外層只綁定一次 `Ctx + Ct`，scope 裏的所有內部函數都不再傳它們，同時不依賴 `AsyncLocal`。但需要先知道你是否接受為每次操作建立一個輕量對象。
	]
	
	-T[2026_0718_215901][
		目前的代碼規範是要求所有異步函數、末個參數都傳一個CT。
		
		我的想法是弄得更通用一點。比如固定讓所有需要上下文的函數 和 異步函數
		的第一個參數都固定成上下文(也可能是末個)。用類似 `IDict<obj, obj?> Ctx`的方式。
		然後 爲防止鍵衝突、所有的鍵都弄成唯一的obj引用、類似TS的symbol。
		如
		```cs
		//公用符號:
		static readonly obj SymCt = new Symbol("Ct"); //也可以不傳字符串參數
		
		//在CsSql程序集中定義此符號:
		static readonly obj SymDbFnCtx = new Symbol("Tsinswreng.CsSql.DbFnCtx");
		
		//在自己的業務程序在中定義此符號:
		static readonly obj SymUserCtx = new Symbol("Ngan.Dict.UserCtx");
		
		
		var calcellationToken = Ctx[SymCt]
		var dbFnCtx = Ctx[SymDbFnCtx]
		```
		
		這樣方便擴展、方便結合不同的框架、方便在不同項目間複用。
		就是不知道有沒有性能問題。
		你有沒有甚麼想法 或者別的辦法
		
	][
		
	]
]
