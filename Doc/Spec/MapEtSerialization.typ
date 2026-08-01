#import "@preview/tsinswreng-auto-heading:0.1.0": auto-heading
#let H = auto-heading;
#H[序列化][
	#H[Json][
		- 依賴注入 `Ngan.Dict.Core/Tools/Json/IJsonSerializer.cs` (優先)
		- 或用 `AppJsonSerializer.Inst.Parse()` 等(不優先考慮)

			#H[Json與`IDict<str, obj?>`互轉][
				在 Tsinswreng.CsTools下 有 ToolJson類
			]
	]
	#H[Srefl][
		//TODO
	]

]

#H[支持序列化和反序列化的對象][
	實現了 `Ngan.Dict.Core.Infra.IF.IAppSerializable` 接口的 class
	纔能序列化和反序列化。
	
	實現此接口後 會自動註冊
	```cs
	[JsonSerializable(typeof(TheClass))]
	[JsonSerializable(typeof(IList<TheClass>))]
	```
	兩種類型。
	涉及序列化與反序列化時 必須使用 `IList<TheClass>` 不能用 `List<>`、因後者未註冊 會導致失敗
	
	json序列化使用標準庫內置、依賴源生成器。
	但是此項目中 實現了 `IAppSerializable` 接口的類 不會使源生成器自動生成代碼、
	需要cd到 `Ngan.Dict.Core`下 執行 `sh GenAppJsonCtx.sh`
]

#H[Json 與 `IDict<str, obj?>`互轉][
	用 Tsinswreng.CsTools 下之 ToolJson
]

#H[`IDict<str, obj?>` 操作 多級讀寫][
	用 Tsinswreng.CsTools 下之 ToolDict。
	禁止手動多次 TryGet !
]

#H[對象和 `IDict<str, obj?>`互轉][
	注入 Ngan.Dict.Core.Tools.Json 下的 
	IDictJsonSerializer
	
	或使用 AppJsonSerializer.Inst
	
	(他同時實現了 IJsonSerializer 和 IDictJsonSerializer) 接口
	
	
]

#H[json序列化映射規則][
	#H[枚舉][
		枚舉 序列化後 爲 枚舉名字符串(魔法數字可維護性差)
	]
	#H[強類型][
		強類型包裝的 值類型 結構體 序列化 後 即其值字段、不再嵌套
		常見的這種結構體 包含:
		- 強類型Id 如 IdUser, IdWord 等
		- Tempus
	]
	
	例:
	```cs
	var learn = new PoWordLearn{
		IdWord = IdWord.FromLow64Base("1ccGi78qV8SYrXJbcbtba"),
		LearnResult = ELearn.Add,
		BizCreatedAt = new Tempus(){Value = 1776575044094},
	};
	var json = toJson(learn);
	```
	
	此json節選 正確時應爲
	```json
	{
		//...
		"IdWord": "1ccGi78qV8SYrXJbcbtba",
		"LearnResult": "Add",
		"BizCreatedAt": 1776575044094,
		//...
	}
	```
	
	錯誤示例:
	```json
	{
		//...
		"IdWord": {
			"Value": "1ccGi78qV8SYrXJbcbtba"
		},
		"LearnResult": 1,
		"BizCreatedAt": {
			"Value": 1776575044094
		},
		//...
	}
	```
]

