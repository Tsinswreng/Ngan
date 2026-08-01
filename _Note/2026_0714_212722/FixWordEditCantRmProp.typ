-T[2026_0714_212740][
	先看skill。
	然後看`E:\_code\CsNgan.Dict\Ngan.Dict.Frontend\proj\Ngan.Dict.Ui\Views\Word\WordEditV2\ViewWordEditV2.cs`
	及其他相關文件。
	
	現在有個bug、
	單詞Prop和學習記錄 均無法刪除條目。
	點進某一個條目、點刪除、再保存之後只是從UI上消失了。
	重新進來就又有了。
	看看怎麼回事。
	
	還有、看聲明與實現分離的skill 和 avln-dsl、
	把 單詞編輯 這一塊的 全按規範 拆成聲明與實現分離的模式。
	不懂就問。
][
	
]


-NewSesn[]

-T[2026_0714_212740][
	先看Skill
	然後看SvcWordV2。
	在SvcWord(不是V2)裏面有個分頁搜索 接口。
	我想給V2加上。
	你看看怎麼弄。
	按skill流程來
][
	
]


-Sesn[
	-T[2026_0718_165243][
		先看skill
		然後看
		`E:\_code\CsNgan.Dict\Ngan.Dict.Frontend\proj\Ngan.Dict.Ui\Views\Word\WordEditV2\ViewWordEditV2.cs`
		你改一下、
		把ViewWordEditV2 底部的 刪除按鈕 和 保存按鈕 移到 ViewPoWordEdit 下面。
		
		然後按規範 把 ViewWordEditV2引用的其他子View也移到頂層public字段。
		
		不懂就問。先去做。
		先不寫實現。
		
	][
		
	]
]


-Sesn[
	-T[2026_0718_165243][
	先看skill。
	然後看`E:\_code\CsNgan.Dict\Ngan.Dict.Frontend\proj\Ngan.Dict.Ui\Views\Word\WordEditV2\ViewWordEditV2.cs`
	及其他相關文件。
	
	現在有個bug、
	單詞Prop和學習記錄 均無法刪除條目。
	點進某一個條目、點刪除之後只是從UI上消失了。
	重新進來就又有了。
	看看怎麼回事。
	
		
	][
		
	]
]
