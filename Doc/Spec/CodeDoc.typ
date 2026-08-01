該規範已廢棄。改用 Ngan.Dict.Doc 寫文檔
#import "@preview/tsinswreng-auto-heading:0.1.0": auto-heading
#let H = auto-heading;

#H[目錄文檔][
在每個目錄下都放一個`_.cs`的文件 作爲該目錄的文檔。描述該目錄或所屬模塊/領域的功能職責等。

內容結構:
```cs
file class DirDoc{
	str Doc =
$$"""
#Sum[

]
#Descr[

]
""";
}

```

- 必須定義成`file class DirDoc{}`
- `str Doc`必須使用多行文本塊。其內部使用Typst語法。
- 需要引用符號名稱時使用`nameof()`、不要硬編碼。

]

#H[文件文檔][
在cs文件頂部放`file class __FileDoc{}`來作文件文檔、描述這個文件。
其餘內容同DirDoc。
]


