#import "@preview/tsinswreng-auto-heading:0.1.0": auto-heading
#let H = auto-heading;
\-\-\-

name: ngan-dict-code-doc

description: 業務模塊文檔讀寫規範。涉及業務代碼的讀或寫時需要使用此技能

\-\-\-


Ngan.Dict.Doc 程序集是專門用來寫文檔的程序集。
此程序集下放 與業務的具體功能模塊相關的介紹文檔，不放通用的代碼規範文檔

#H[讀][
	#H[何時讀][
		寫業務代碼時 需要先找一下有沒有相關文檔。
	]
	#H[如何讀][
		找代碼 先去 Ngan.Dict.Doc/proj/Ngan.Dict.Doc/Catalog.cs 看目錄
		如果目錄裏有相關模塊的文檔的索引 就看相關模塊的文檔。
	]
	
]

#H[寫][
	#H[何時寫][
		- 更改了業務代碼之後 需要同步對應文檔
			- 如果本來沒有文檔就要加上
			- 如果文檔與新改動對不上 或缺東西 就要同步
		- 即使你只是 閱讀代碼 但未修改代碼 如果你發現 文檔與代碼對不上 或缺東西 你也要主動問用戶 要不要改文檔
	]
	#H[如何寫][
		看 Ngan.Dict.Doc/proj/Ngan.Dict.Doc/Sample.cs
	]
	
]
