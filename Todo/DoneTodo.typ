#let H(title, doc)=[]
+ [bug] 岡背過之詞 權重猶甚大 似debuff不效[2025-06-07T21:48:15.427+08:00_W23-6,2025-10-16T10:04:51.825+08:00_W42-4]
+ [bug] 緟加詞旹 diff不效、'add'ˉ學習記錄續ˣ增 [o at 2025-06-07T23:08:02.425+08:00_W23-6]
+ 插入詞後改UpdateAt[2025-06-07T10:02:56.835+08:00_W23-6,2025-10-16T10:05:10.644+08:00_W42-4]


#H[][
	#H[,2025-11-08T22:29:16.808+08:00_W45-6][
		在appiniter中 初始化ClientId
	]
]

#H[2025-11-15T22:41:02.610+08:00_W46-6][
	#H[2025-11-16T10:23:07.423+08:00_W46-7][
- 導出文件旹 提示覆蓋文件確認
	]
]

#H[PreFilter Lang=italian 不生效][
[2026_0407_210519,2026_0407_210722]
```json
{"Version":"1.0.0.0","CoreFilter":[{"Fields":["Lang"],"Filters":[{"Operation":"Eq","ValueType":"String","Values":["italian"]}]}],"PropFilter":[]}
```
要點 「設爲當前」 按鈕纔生效
]



#H[2025-11-30T22:54:35.098+08:00_W48-7][
	[,2026_0407_210900]
	不打算實現。
```cs
FnXxx(IDbFnCtx Ctx, CT CT){
	//斯處(上層)拋異常旹 事務似未回滾、再發則報 sqlite 不支持嵌套事務
	return async(...)=>{
		...
	}
}
```
]


#H[2025-11-22T13:44:38.647+08:00_W47-6][
	[,2026_0407_210918]
- WordInfo中顯示稍多之文字旹則卡頓、于androidʸ則卡頓甚巨、蜮致閃退。 以`dip`潙例
	#H[2025-11-28T22:21:57.727+08:00_W48-5][
		疑StrokeTextʃ致。可試引入虛擬渲染
	]
]


#H[後端統一響應格式][
	[2025-10-25T12:01:13.225+08:00_W43-6,2026_0407_211013]

如
```json
{
	"code": 0
	,"data": {}// 實際Service層響應的數據
}
```
、前端亦按此格式接收
]


#H[][
[2025-10-21T00:10:20.072+08:00_W43-2,2026_0407_211035]
+ 避免在sqlite中用null
+ 軟刪除改用刪除時間標志
+ 避免硬編碼`AND {T.Fld(nameof(PoKv.DelId))} IS NULL`、緩存ᵣˌ軟刪除條件比較ˉ子句、各自引用
]

#H[改單詞編輯頁][
	[2026_0407_210553,2026_0413_110942]
]


#H[改 單詞查找分頁][
	[2026_0407_210613,2026_0413_110953]
	分頁樣式 用 自封裝之 PageBar
]

#H[可長按按鈕 在手機端 表現不佳。][
	[2026_0407_210819,2026_0413_111002]
	邊移動邊長按也會觸發。 應爲 靜止時長按纔觸發。
]

#H[][
	[2025-12-25T16:42:27.335+08:00_W52-4,2026_0414_105608]
	底菜單蘭 當前所在標籤 高亮
]

#H[詞典 存入 用戶詞典後、連續存入兩次 會被軟刪 且 添加事件數量爲1][
	[2026_0420_101742,2026_0420_194143]
]


#H[登錄註冊頁][
	[2026_0417_142554,2026_0421_110854]
	按鈕文字要居中 換成MainColor
	密碼用 密碼專用輸入框。
	
	區域都集中一點
	
	目前是這樣的: 以登錄頁面爲例:
	
	```
	登錄|註冊
	電子郵件:
	電子郵件輸入框
	密碼:
	密碼輸出框
	
	
	(大段空白)
	
	
	登錄按鈕
	```
	
	你改成
	
	
	```
	登錄|註冊
	
	(均等的空白)
	
	電子郵件:
	電子郵件輸入框
	密碼:
	密碼輸出框
	
	登錄按鈕
	
	(均等的空白)
	
	```

]


#H[viewWordEditV2 無法刪除單詞(可能是API未實現)][
	[2026_0407_222106,2026_0421_110947]
]


#H[安卓 通知欄查詞入口][
	[2026_0422_094925,2026_0424_220635]
]


#H[登錄成功後無提示][
	[2026_0420_194128,2026_0424_220651]
]

#H[學習方案管理頁面入口放到 背單詞頁面 settings下][
	[2026_0409_151340,2026_0424_220726]
]


#H[從llm詞典保存生詞 點save後無效][
	[2026_0409_143920,2026_0424_220744]
]

#H[PreFilter 分頁表 應顯示詳情][
	[2026_0409_150231,2026_0424_220746]
	如 core filter中只設了一項Field和FilterItem時(如Lang=italian)
	在外層表格行中顯示 Lang=italian
]


#H[JS權重算法 注入ILogger 使Js側能調用; 減 JS全局變量][
	[2026_0424_221053,2026_0424_224721]
]


#H[ItblToStream 不應用 MemoryStream][
	[2026_0425_114358,2026_0425_154429]
	`E:\_code\CsNgan.Dict\Tsinswreng.CsTools\proj\Tsinswreng.CsTools\ItblToStream.cs`
]


#H[UserLangToNormLang 配置界面 不能選擇NormLang 必須手動輸入][
	[2026_0414_105753,2026_0425_191218]
	`E:\_code\CsNgan.Dict\Ngan.Dict.Frontend\proj\Ngan.Dict.Ui\Views\Word\WordManage\UserLang\UserLangEdit\ViewUserLangEdit.cs`
	
	關聯語言 輸入框 後面加一個選擇按鈕、點擊之後 轉到 
	`E:\_code\CsNgan.Dict\Ngan.Dict.Frontend\proj\Ngan.Dict.Ui\Views\Word\WordManage\NormLang\NormLangPage\ViewNormLangPage.cs`
	的頁面、點擊其中一項就能選擇
	
	然後這個 ViewUserLangEdit 頁面 還要顯示 關聯語言類型。
]


#H[從llm dict進入語言選擇頁 無法添加][
	[2026_0414_105711,2026_0425_191406]
	`E:\_code\CsNgan.Dict\Ngan.Dict.Frontend\proj\Ngan.Dict.Ui\Views\Dictionary\ViewDictionary.cs`
	進入
	
	`E:\_code\CsNgan.Dict\Ngan.Dict.Frontend\proj\Ngan.Dict.Ui\Views\Word\WordManage\NormLang\NormLangPage\ViewNormLangPage.cs`
	本來 ViewNormLangPage是有添加按鈕的。 如果是從 ViewDictionary 進入 ViewNormLangPage的話、 ViewNormLangPage 的添加按鈕就不見了。應該要有。
	
	此外、 
	`E:\_code\CsNgan.Dict\Ngan.Dict.Frontend\proj\Ngan.Dict.Ui\Views\Word\WordManage\NormLang\NormLangEdit\ViewNormLangEdit.cs` 要顯示 語言類型 如 Bcp47
]


#H[ViewNormLangToUserLangPage][
	[2026_0425_113205,2026_0425_191909]
	`E:\_code\CsNgan.Dict\Ngan.Dict.Frontend\proj\Ngan.Dict.Ui\Views\Word\WordManage\NormLangToUserLang\NormLangToUserLangPage\ViewNormLangToUserLangPage.cs`
	
	這裏的表格 不用顯示 標準語言類型 和 描述。
	
	`E:\_code\CsNgan.Dict\Ngan.Dict.Frontend\proj\Ngan.Dict.Ui\Views\Word\WordManage\NormLangToUserLang\NormLangToUserLangEdit\VmNormLangToUserLangEdit.cs`
	這裏纔要顯示 標準語言類型。
	然後 VmNormLangToUserLangEdit 的 選擇按鈕 的 圖標 改成 `E:\_code\CsNgan.Dict\Ngan.Dict.Frontend\proj\Ngan.Dict.Ui\Icons\Icons.Decl.cs` 的 ListSelect
	
]

#H[備份同步頁 操作成功後要有Toast提示][
	[2026_0421_200917,2026_0425_192104]
	`E:\_code\CsNgan.Dict\Ngan.Dict.Frontend\proj\Ngan.Dict.Ui\Views\Word\WordManage\WordSyncV2\ViewWordSyncV2.cs`
]

#H[優化 GlobalErrHandler 異常處理][
	[2026_0421_201226,2026_0425_192137]
	`E:\_code\CsNgan.Dict\Ngan.Dict.Server\proj\Ngan.Dict.Server.Http\GlobalErrHandler.cs`
	- 要注入Logger輸入異常信息
]

#H[單詞添加頁][
	[2026_0423_222156,2026_0425_192202]
	- 增 格式說明
	- 用 文本編輯器控件
	- 刪 他ʹ 功能、只留 文本添加

E:\_code\CsNgan.Dict\Ngan.Dict.Frontend\proj\Ngan.Dict.Ui\Views\Word\WordManage\AddWord\ViewAddWord.cs
]


#H[NormLangPage 本土名稱列 放後面][
	[2026_0423_222433,2026_0425_192213]
	
	E:\_code\CsNgan.Dict\Ngan.Dict.Frontend\proj\Ngan.Dict.Ui\Views\Word\WordManage\NormLang\NormLangPage\ViewNormLangPage.cs
]

#H[詞典 大模型 提示詞 強調 用戶輸入拼寫不正確時要在Head糾正][
	[2026_0420_101710,2026_0425_200443]
	`E:\_code\CsNgan.Dict\Ngan.Dict.Backend\Domains\Dictionary\Prompt\Prompt.typ`
	強調 Head字段 是 規範化後的詞頭
	假如用戶輸入了 dictioary、那返回的Head字段應該是 dictionary
]


#H[統計圖 應顯示年份][
	[2026_0413_221853,2026_0425_200513]
	`E:\_code\CsNgan.Dict\Ngan.Dict.Frontend\proj\Ngan.Dict.Ui\Views\Word\WordManage\Statistics\ViewStatistics.cs`
	下方橫坐標軸  顯示的格式是 `04-26`這樣的、豎着的
	假如我統計的時間跨度超過一年 看座標軸就不知道是哪一年的。
	且 橫坐標軸 標籤 和 橫坐標軸線 相交了、容易看不清楚。
	
	再把這裏的默認分頁大小改成10。原先20太大了。只改這裏的。
	
	[2026_0425_191626,2026_0425_200513]
	- 橫座標軸下方有大段空白
	- 座標軸標籤 年份只用2位、標籤換成不同顏色
]


#H[單詞編輯頁 之 刪除時間 宜譯爲 軟刪除時間][
	[2026_0425_111148,2026_0425_201437]
	控件用 TempusBox 勿直ᵈ顯 unixMs
	
	E:\_code\CsNgan.Dict\Ngan.Dict.Frontend\proj\Ngan.Dict.Ui\Views\Word\WordEditV2\ViewWordEditV2.cs
	
	[2026_0425_192304,2026_0425_201439]
	軟刪除時間 值爲0 或爲空時 不顯示內容。
	當前的效果是 顯示爲當前時間。 不對。
	
]

#H[快捷鍵查詞][
	[2026_0421_212925,2026_0428_205107]
	目前差linux版
]


#H[跨平臺 音頻播放][
	[2026_0422_094904,2026_0428_205114]
	目前差linux版
]

#H[統計頁面 學習結果 要I18n][
	[2026_0421_111530,2026_0428_205140]
	E:\_code\CsNgan.Dict\Ngan.Dict.Frontend\proj\Ngan.Dict.Ui\Views\Word\WordManage\Statistics\ViewStatistics.cs
	Add/Fgt/Rmb 這幾樣 在下拉框裏。
	先標上Todo.I18n先
]


#H[js 權重算法自定義 增 文檔][
	[2026_0423_222328,2026_0428_205150]
	或統一作進階文檔
]


#H[View/NormLangToUserLangPage/ModifiedTime
not found][
	[2026_0416_224448,2026_0428_205202]
]

#H[下拉框選項也要i18n][
	[2026_0407_212317,2026_0428_205225]
]

#H[多增內置js權重算法與參數][
	[2026_0423_222256,2026_0429_095707]
]


#H[WordEditV2 無法修改 DelAt字段、改了 點保存則不效][
	[2026_0425_201514,2026_0429_095708]
]


#H[標準語言 支持編輯 EnglishName與權重][
	[2026_0429_095729,2026_0429_105814]
]

#H[安卓入口 配 i18n][
	[2026_0429_101113,2026_0429_105814]
	參照 `E:\_code\CsNgan.Dict\Ngan.Dict.Frontend\proj\Ngan.Dict.Windows\Ngan.Dict.Windows.cs`
	
	改`E:\_code\CsNgan.Dict\Ngan.Dict.Frontend\proj\Ngan.Dict.Android\MainActivity.cs`
	
]


#H[][
	[2026_0519_235432,2026_0520_083126]
	WordEditV2
	無法新增Prop
	可能學習記錄亦無法新增
]
