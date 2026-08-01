#import "@preview/tsinswreng-auto-heading:0.1.0": auto-heading
#let H = auto-heading;
\-\-\-

name: ngan-ime-doc

description: Ngan.Ime項目的文檔。開發Ngan.Ime項目時必須閱讀此skill

\-\-\-

#H[CodeDoc文檔][
	看 skills/tsinswreng-csharp-code-doc
	然後看 `Ngan.Ime/Ngan.Ime.Doc/proj/Ngan.Ime.Doc/Catalog.cs`
]

#H[Spec][
	#H[Intro][
		Ngan.Ime 是針對Rime輸入法引擎的跨平臺前端、採用C\# .NET 10 Avalonia12開發。
	]

	#H[Structure][
		#H[Ngan.Ime.Core][
			核心層
			平臺無關 充當抽象
		]
		#H[Ngan.Ime.Rime][
			Rime引擎適配層
		]

		#H[Ngan.Ime.Frontend/][
			前端。在proj/下有多個程序集
			#H[Ngan.Ime.Ui][
				通用平臺無關 UI。
				依賴抽像層而非實現。只能引用Ngan.Ime.Core
				不應引用Ngan.Ime.Rime或一切直接引用Rime的API
			]
			#H[Ngan.Ime.Android][
				安卓適配層與程序入口。可以引用後端具體實現
			]
			#H[Ngan.Ime.Windows][
				Windows適配層與程序入口
				可以引用後端具體實現
			]
		]
	]
]
