#import "@preview/tsinswreng-auto-heading:0.1.0": auto-heading
#let H = auto-heading;
\-\-\-

name: tsinswreng-ai-memory

description: AI的持久化記憶。此skill爲必讀。執行任務前先看記憶、執行任務後再按需更新記憶

\-\-\-

`<項目根目錄>/.Tsinswreng/AiMemory/` 下爲全局AI記憶。
其中 `<項目根目錄>/.Tsinswreng/AiMemory/Main.typ`爲主文檔入口

#H[何時讀取記憶][
	每次執行任務前先看一遍主文檔入口 `Main.typ`。
	`Main.typ`中可能會引用其他文檔、你按需讀取。
]

#H[何時更新記憶][
	- 每次執行任務後、根據任務結果按需更新記憶。
]

#H[記憶的組織方式][
	`Main.typ`爲記憶入口。
	由于記憶入口爲必讀項、所以一般我們不在`Main.typ`放置大量內容、而是將他作爲摘要和目錄使用。
	具體內容放到其他文件夾下、然後在`Main.typ`中用`#link`函數引用。
	
	例:
	
	文件結構:
	在項目根目錄下:
	````
	.Tsinswreng/
		AiMemory/
			Main.typ
			Startup/
				LaunchFrontend.typ
				LaunchBackend.typ
	````
	
	`Main.typ`:
	
	````typ
	#import "@preview/tsinswreng-auto-heading:0.1.0": auto-heading
	#let H = auto-heading;
	
	此項目是xxx(概述)
	
	#H[項目啓動][
		前端項目啓動參照 #link("./Startup/LaunchFrontend.typ")[前端啓動文檔]
		後端項目啓動參照 #link("./Startup/LaunchBackend.typ")[後端啓動文檔]
	]
	
	````
]

要求:
- 必須使用typst語法、使用.typ文件、不使用markdown
- 標題盡量用 auto-heading 庫