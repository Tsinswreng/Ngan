#import "@preview/tsinswreng-auto-heading:0.1.0": auto-heading
#let H = auto-heading

#H[項目結構介紹][
	#H[CsRimeLua.Core][
		核心層。所有程序集都引用此程序集。
		此程序集不應依賴具體實現、不能依賴Lua API或Rime API等、
		不應使用unsafe
	]

	#H[CsRimeLua.Lua][

	]

	#H[CsRimeLua.Exports][
		定義將用于導出的函數。
		裏面的函數不會直接加上`[UnmanagedCallersOnly(EntryPoint = nameof(GetUnixTimeMs), CallConvs = new[] { typeof(CallConvCdecl) })]`
	]

	#H[CsRimeLua.Windows][
		Windows平臺的編譯目標。
		當先會NativeAOT編譯成 win-x84 的 dll、供weasel調用。
		直接轉發 CsRimeLua.Exports的函數、然後加上`[UnmanagedCallersOnly(EntryPoint = nameof(GetUnixTimeMs), CallConvs = new[] { typeof(CallConvCdecl) })]`。
		何故要多轉發一層、而非直在CsRimeLua中的函數加`UnmanagedCallersOnly`?
		緣 AOT編譯成dll時、ProjectReference引用的程序集裏的`UnmanagedCallersOnly`不效、只看自己入口程序集的`UnmanagedCallersOnly`。
	]

	#H[CsRimeLua.Android][
		Android平臺的編譯目標。
		當先會NativeAOT編譯成 linux-bionic-arm64 的 so、供Ngan.Ime.Android調用。
		亦直接轉發 CsRimeLua.Exports的函數。
	]

]
