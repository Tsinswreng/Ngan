#import "@preview/tsinswreng-auto-heading:0.1.0": auto-heading
#let H = auto-heading;

// cwln . -i cs$ -e bin -e obj


#H[測試規範][
使用的測試框架: 自研的 `Tsinswreng.CsTreeTest`
]

#H[參考示例代碼][
	*!!看同目錄下 `TestSample.typ`!!*  重要!!  一定要看!!
	 
	強調幾個注意事項:
	不要把不同API的所有測試用例全寫在一個文件裏！
	`TestSample.typ`裏明確要求你按不同的被測函數 分開不同的文件！嚴格按照規範來做！
]


#H[用例命名][
	用例名應當滿足:
	- 在同一個測試類內易於辨認
	- 能看出測什麼行爲
	- 不要寫成含糊的 `Test1`, `Try`, `Temp`
]


#H[怎麼收編子程序集(csproj)測試][
	如果是更上層的 TestMgr 
	不直接註冊每個測試類, 而是收編下級 TestMgr。

	參考:
	- `Ngaq.Test/proj/Ngaq.Windows.Test/WindowsTestMgr.cs`

	參考寫法:
	```cs
	public class WindowsTestMgr: DiEtTestMgr{
		public static WindowsTestMgr Inst = new();
		public override ITestNode RegisterTestsInto(ITestNode? Test){
			Test = this.TestNode;
			this.RegisterSubMgr(LocalTestMgr.Inst);
			return Test;
		}
	}
	```
]

#H[測試執行入口][
非必要 不需關心入口
]

#H[AI 新增測試時的最小操作清單][
	如果你是 AI, 當用戶要求“爲某個類補測試”時, 按這個順序做:
	+ 找到對應模塊下最近的測試目錄
	+ 新建 `TestXxx.cs`, 實現 `ITester`
	+ 在 `RegisterTestsInto` 中用 `MkFnRegisterTest` 註冊用例
	+ 在最近的 `TestMgr` 補 `RegisterTester<TestXxx>()`
	+ 若該模塊尚未被上層收編, 再補 `RegisterSubMgr(...)`
	+ 不看主入口, 除非用戶明確要求
]

#H[測試涉及數據庫操作的函數][
要先自行把測試數據插入數據庫、
注意構造的測試數據要足夠獨特、避免與其他已有數據重複
測試結束後(不管成功還是失敗)都要把插入的數據都硬刪除

不需要在每個測試用例都做一遍插入測試數據 再清理測試數據的操作
可以把Node設爲有序、在最開始的用例做插入數據、在最後一個用例清理數據。

]


#H[本項目的幾個測試程序集][
	Ngaq.Test/proj/Ngaq.Core.Test/Ngaq.Core.Test.csproj
	Ngaq.Test/proj/Ngaq.Backend.Test/Ngaq.Backend.Test.csproj
	Ngaq.Test/proj/Ngaq.Windows.Test/Ngaq.Windows.Test.csproj
]


#H[斷言][
	能用斷言就用斷言、如
	```cs
	var T = Assert.IsTrue;
	T(Add(1,2)==3);
	T(Add(4,5)==6);
	```
	避免自己`if(Add(1,2)!=3){throw new Exception("...");}`
]

#H[注意事項][
	- 代碼複用 減少重複代碼
	- 當你在外部調用ISvcXxx裏的Api時、若函數第一個參數爲`IDbFnCtx?`
		或`IDbUserCtx`時、保持`IDbFnCtx`的位置爲 null (不要自己初始化 IDbFnCtx)
]
