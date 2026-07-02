#import "@preview/tsinswreng-auto-heading:0.1.0": auto-heading
#let H = auto-heading;
\-\-\-

name: tsinswreng-separate-decl-and-impl

description: 聲明與實現分離。編碼階段初步設計與詳細實現時必須閱讀此skill

\-\-\-


#H[調用已有代碼的功能][
	當你需要調用已有代碼的API時、大部分情況下你只需要關注函數聲明
	不需要關心內部具體實現 *以節約token*。
	
	有兩種情況、一種是基于接口實現;
	另一種是基于`partial`關鍵字實現(類似于C語言的頭文件);
	
	#H[基于接口][
		優先閱讀接口中的代碼。通過依賴注入系統使用接口。通常不需要閱讀具體實現。
	]
	#H[基于partial][
		約定: 
		- Xxx.Decl.cs 表示 這個文件是專放聲明的;
		- Xxx.Impl.cs 表示 這個文件是專放實現的;
		訪問Xxx中的API時 優先閱讀`*.Decl.cs`。
		
		也可能有`.Decl`省略不寫的情況、即
		`Xxx.cs` vs `Xxx.Impl.cs`的情況
	]
	#H[以下情況你需要關注具體實現][
		- 你正在負責這塊代碼的維護工作、而不是作爲調用API的第三方。
	]
]

#H[新寫的代碼][
	新寫的代碼也要遵從聲明與實現分離的規範、先寫聲明、等用戶確認聲明無誤後再實現。
	當使用 聲明與實現分離的模式時、聲明部分的文件寫在 `Xxx.cs`(記得`.Decl`默認省略!)、有一點類似C語言的頭文件但不完全一樣;
	
	函數實現部分的文件寫在 `Xxx.Impl.cs`。
	
	`Xxx.Impl.cs`中只放函數實現。
	
	如果已經採用了接口(interface)+實現類(class)的模式、則不需要再使用partial關鍵字拆分聲明與實現。
	
	例:
	#H[`TextWithStream.cs`][

`Decl`中、函數聲明中用partial關鍵字、不提供函數實現。
```cs
public partial class TextWithStream{
	public u64 HeaderBytesLen{get;set;}
	public string Text {get;set;}
	public Stream Payload {get;set;}
	public partial TextWithStream();
	
	public static partial Task<TextWithStream> Unpack(Stream stream, CT Ct);
	
}
	```
	
	]
	
	#H[`TextWithStream.Impl.cs`][
		`Impl.cs`中 只給出函數實現 別的不寫
	```cs
public partial class TextWithStream{
	public partial TextWithStream() {
		HeaderBytesLen = 0;
		Text = "";
		Payload = Stream.Null;
	}
	
	public static async partial Task<TextWithStream> Unpack(Stream stream, CT Ct) {
		if(stream is null) {
			throw new ArgumentNullException(nameof(stream));
		}
		//...中略
		return R;
	}
}
	```
	]

	再強調幾點:
	
	- #[Decl和Impl中的聲明與實現分離 僅針對函數(包括構造函數)、訪問器(getter/setter)和字段等還是寫在Decl裏]
	- #[你先寫完Decl的內容後讓用戶審查、審查通過後再寫Impl。
	當你寫好Decl但沒寫Impl時、你去跑編譯肯定多半是跑不通的、不要管他、等你把Impl寫好後再一起跑編譯解決編譯錯誤
	]

]
