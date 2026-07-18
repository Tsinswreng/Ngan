---

name: tsinswreng-cstreetest

description: CsTreeTest測試框架寫法規範

---

## 測試規範

使用的測試框架: 自研的 `Tsinswreng.CsTreeTest`

## 參考示例代碼

**!!看同目錄下 `TestSample.typ`!!** 重要!! 一定要看!!

強調幾個注意事項: 不要把不同API的所有測試用例全寫在一個文件裏！ `TestSample.typ`裏明確要求你按不同的被測函數 分開不同的文件！嚴格按照規範來做！

## 用例命名

用例名應當滿足:

- 在同一個測試類內易於辨認
- 能看出測什麼行爲
- 不要寫成含糊的 `Test1`, `Try`, `Temp`

## 怎麼收編子程序集(csproj)測試

如果是更上層的 TestMgr 不直接註冊每個測試類, 而是收編下級 TestMgr。

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

## 測試執行入口

如非必要 不需關心入口

## AI 新增測試時的最小操作清單

如果你是 AI, 當用戶要求“爲某個類補測試”時, 按這個順序做:

1. 找到對應模塊下最近的測試目錄
2. 新建 `_TestXxx.cs` 作爲實現 `ITester` 的主檔, 再按被測函數新建 `TestXxx.cs`
3. 在各 `RegisterXxx` 中用 `MkTestFnRegister` 註冊用例
4. 在最近的 `TestMgr` 補 `RegisterTester<TestXxx>()`
5. 若該模塊尚未被上層收編, 再補 `RegisterSubMgr(...)`
6. 不看主入口, 除非用戶明確要求

## 測試涉及數據庫操作的函數

要先自行把測試數據插入數據庫、 注意構造的測試數據要足夠獨特、避免與其他已有數據重複 測試結束後(不管成功還是失敗)都要把插入的數據都硬刪除

不需要在每個測試用例都做一遍插入測試數據 再清理測試數據的操作 可以把Node設爲有序、在最開始的用例做插入數據、在最後一個用例清理數據。

## 斷言

能用斷言就用斷言、如

```cs
var T = Assert.IsTrue;
T(Add(1,2)==3);
T(Add(4,5)==6);
```

避免自己`if(Add(1,2)!=3){throw new Exception("...");}`

## 聲明與實現分離

當用戶要求你聲明與實現分離時:

- 僅在Impl.cs中實現函數與註冊用例
- 每個測試用例函數用常態函數聲明和實現、不用匿名函數

例:

```cs
File: MyDomains/Calculator/TestAdd.cs
using Tsinswreng.CsTreeTest;

namespace MyProj1.Test.MyDomains.Calculator;
// each part should only mainly test one function. in this part we test Add
public partial class TestCalculator {
	public partial void RegisterAdd(ITestNode Node);
	
	///don't forget to write comment here
	public partial Task<nil> AddPositiveNumbers(obj? O);
	
	///don't forget to write comment here
	public partial Task<nil> AddPositiveAndNegativeNumbers(obj? O);
}
```

```cs
File: MyDomains/Calculator/TestAdd.Impl.cs
using Tsinswreng.CsTreeTest;

namespace MyProj1.Test.MyDomains.Calculator;
// each part should only mainly test one function. in this part we test Add
public partial class TestCalculator {
	public partial void RegisterAdd(ITestNode Node) {
		var register = Node.MkTestFnRegister(
			typeof(TestCalculator), // tester type
			[typeof(ICalculator)], // testee types
			[nameof(MyDomains.Calculator.ICalculator.Add)], // testee fn names, must use nameof()
			"YourTestNamePrefix" // optional
		);
		var R = register.Register;
		var T = Assert.IsTrue;
		R(nameof(AddPositiveNumbers), AddPositiveNumbers!);
		R(nameof(AddPositiveAndNegativeNumbers), AddPositiveAndNegativeNumbers!);
	}
	
	///don't forget to write comment here
	public partial async Task<nil> AddPositiveNumbers(obj? O){
			T(Calculator.Add(5, 3)==8);
			T(Calculator.Add(6, 4)==10);
			return NIL;
	}
	
	///don't forget to write comment here
	public partial async Task<nil> AddPositiveAndNegativeNumbers(obj? O){
		var r = Calculator.Add(5, -3);
		T(r==2);
		return NIL;
	}
}
```

## 總結注意事項和禁止事項

- 一個 tester 通常對應一個 testee；不同 tester 放在不同目錄。
- tester 使用 partial class：以 `_TestXxx.cs` 作爲主檔，只負責組裝；每個 `TestXxx.cs` 只主要測試一個被測函數。
- 每個測試 csproj 都要有 TestMgr；上層 TestMgr 只收編下級 TestMgr，不直接註冊下級的各個 tester。
- 註冊測試時，使用 `nameof(...)` 指明被測函數，且用例名必須能辨認所測行爲。
- 能使用 `Assert` 時，不要手動以 `if` 加 `throw` 實現斷言。
- 涉及數據庫時，測試數據必須唯一，並確保無論測試結果如何都會硬刪除；可使用有序 Node 集中完成建置與清理。
- 禁止把不同 API 的所有測試用例寫進同一個文件；
- 禁止使用含糊的用例名，如 `Test1`、`Try`、`Temp`。
