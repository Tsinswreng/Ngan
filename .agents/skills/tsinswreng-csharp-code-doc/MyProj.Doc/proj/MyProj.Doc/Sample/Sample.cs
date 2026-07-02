namespace MyProj.Doc; // MyProj.Doc命名空間聲明寫在最上面。這裏以MyProj爲例、你要把MyProj換成實際的項目名。

using Tsinswreng.CsCore;

[Doc($$"""
代碼文檔示例。
#H[內容寫法規範][
	- 必須使用一對 三個雙引號 的 文本塊寫法。
	- 內部使用 typst 語法。
	- 不要用加粗語法。
	- 引用符號時 需要使用 `nameof()` 的寫法、不要硬編碼。
	- 標題使用 `#H[標題內容][正文內容]` 的寫法。可嵌套。
]

#H[文件位置規範][
	代碼文檔要按模塊/領域劃分文件夾。不要全寫在一起。
	如 {{nameof(MyProj.Doc.DictHotKey)}} 就放 查詞快捷鍵 相關文檔。
	(這裏nameof中引用的`MyProj.Doc`中的符號名是命名空間的名字、不是file class的類名。)
]

#H[目錄][
	`Ngaq.Doc/proj/Ngaq.Doc/Catalog.cs` 是目錄文件。
	當你新增文檔文件時 要在目錄文件中添加對應的條目。
]


""")]
file class _{
	
}
