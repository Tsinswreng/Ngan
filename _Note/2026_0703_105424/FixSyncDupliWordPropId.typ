先看 skill
單詞同步這遇到了個bug

在`E:\_code\CsNgan.Dict\tmp`下面

有

Ngan.Dict.sqlite_FromAndroid (sqlite數據庫)

2026_0703_005840.ngan.dict (Windows端輸出的單詞包)

當我的程序用的數據庫是 Ngan.Dict.sqlite_FromAndroid 時
我在單詞同步頁面中選擇 2026_0703_005840.ngan.dict 來合入
就會報錯 WordProp.Id違反唯一約束

還有一個

Ngan.Dict.sqlite_FromWin

這個文件是
運行新程序實例 單詞庫中沒有數據時、在單詞同步頁面從
2026_0703_005840.ngan.dict
合入 得到的sqlite數據庫文件

也就是說 Ngan.Dict.sqlite_FromWin 的內容 和 2026_0703_005840.ngan.dict 理論上是等同的。

你覺得怎麼debug比較好?

我的想法是
你去另外建一個測試程序集
仿照 E:\_code\CsNgan.Dict\Ngan.Dict.Test\proj\Ngan.Dict.Windows.Test\Ngan.Dict.Windows.Test.csproj
然後連上 Ngan.Dict.sqlite_FromAndroid
然後注入ISvcWordV2服務、調裏面的單詞同步接口
在代碼中加日誌
中間你可以嘗試多次運行 自己看日誌輸出

你覺得呢

注意:  不得修改`E:\_code\CsNgan.Dict\tmp/`下面的文件
當他們是只讀的、debug要被改到的時候起碼要複製一份


2026_0703_111101[
補充一點、現在WordProp中可能有Id爲全0(二進制下全128位都是0)的行
這是之前前端設計錯誤導致插入的
這是不應該有的
你實際修的時候把全0的行 自己改一個ID  

不要做只讀檢查 必須自己跑過 加日誌來debug

DB路徑不是在配置文件裏寫的嗎  哪裏硬編碼了
你建新程序集的時候自己把你這次debug專用配置弄一份在exe同目錄下 不就能連上了
]
````md
我先停在這裏，因爲現在有一個需要你定的邊界。

已經確認的一點是：報錯不是單純全 0 `WordProp.Id` 造成的；更直接的根因在 `RepoProp.BatUpsert()` 這條路上。`BatUpsert` 判斷“Id 是否已存在”時排除了軟刪行，但 SQLite 主鍵唯一約束不會排除軟刪行，所以會出現“明明庫裏已有同 Id 軟刪行，卻被當成新增再插一次”，最後就炸在 `UNIQUE constraint failed: WordProp.Id`。這個現象和我跑出來的 raw / normalize 日誌是對上的。

但你剛補充說同步功能是接 `V2` 實現，這就引出一個設計邊界問題：我是保留共享層 `SqlRepo` 的修正，還是把修復只收斂到 `SvcWordV2` 的同步流程裏。這個我不該帶着疑問繼續改，所以先停下來等你定。  
如果你允許動共享層，我會繼續保留 `SqlRepo` 修正，再在 `SvcWordV2` 補上“本地/遠端全 0 `WordProp.Id` 自動換新 Id”的修復並回歸跑通。  
如果你要嚴格限制在 V2，我就把思路改成只在 `SvcWordV2` 裏處理軟刪同 Id 與全 0 Id。


現在我看到的是兩個層次的問題，得分開說。

第一層是“爲什麼會報 `WordProp.Id` 唯一約束”。

你這次的報錯，實際落點不在 `LocalNotExist`，而是在 V2 同步這條鏈路：

[SvcWordV2.Sync.cs](/E:/_code/CsNgan.Dict/Ngan.Dict.Backend/Domains/Word/Svc/SvcWordV2.Sync.cs:208)  
`ApplyRemoteWordsAsBatchUpdate()`  
→ `RepoProp.BatUpsert(...)`

再往下進 repo：

[SqlRepo.cs](/E:/_code/CsNgan.Dict/Tsinswreng.CsSql/proj/Tsinswreng.CsSql/SqlRepo.cs:1152)  
`BatUpsert()` 先判斷每個 Id “存不存在”，存在就 `BatUpd`，不存在就 `BatAdd`。

問題在這個“存不存在”的判斷用的是：

[SqlRepo.cs](/E:/_code/CsNgan.Dict/Tsinswreng.CsSql/proj/Tsinswreng.CsSql/SqlRepo.cs:1143)  
`BatExistsById()`

它查詢時自帶了“只看未軟刪”的過濾。  
但 `WordProp` 表的主鍵唯一約束是全表生效的，不會因爲 `DelAt != 0` 就失效。

所以就會出現這種情況：

1. 某個 `WordProp.Id` 在庫裏其實已經有一行了。
2. 但那行是軟刪狀態。
3. `BatExistsById()` 說“不存在”。
4. `BatUpsert()` 就把它塞進 `toInsert`。
5. `BatAdd()` 真插入時撞上同一個主鍵。
6. 報 `UNIQUE constraint failed: WordProp.Id`。

這個邏輯上是完全自洽的，而且和你現在的堆棧完全吻合，因爲異常就是炸在 `BatUpsert -> BatAdd`，不是炸在 `BatUpd`。

第二層是“全 0 `WordProp.Id` 是不是根因”。

我已經實跑過兩個場景：

1. `raw`
2. `normalize-zero-prop-id`

`raw` 場景確認本地 Android DB 裏確實有全 0 `WordProp.Id`，例如：

- `head=てどり`
- `propKey=alias`
- `propId=0`

但我又跑了 `normalize-zero-prop-id`，也就是：

1. 先把複製出來的 sqlite 裏全 0 `WordProp.Id` 改成新 Id
2. 遠端包內存裏如果有全 0 `WordProp.Id` 也改成新 Id
3. 再跑同步

結果還是報同樣的唯一約束。

所以結論是：

- 全 0 `WordProp.Id` 確實是髒數據，之後正式修一定要處理。
- 但它不是這次報錯的唯一根因。
- 即使把全 0 Id 修掉，`BatUpsert` 對軟刪行的存在性判斷問題仍然會單獨把同步炸掉。

你剛纔提醒“同步功能接的是 V2”，我停下來是因爲這裏有個設計邊界：

`SvcWord` 舊實現是不是棄用，不影響這次定位到的核心 bug。  
因爲真正炸的是共享層 `SqlRepo.BatUpsert()`，而 V2 只是調用了它。

所以我想確認的是：

- 你是否接受我修共享層 `SqlRepo`？
- 還是你要我把修復嚴格限制在 `SvcWordV2`，哪怕共享層邏輯明顯有問題也不動它？

這兩種修法的差別是：

如果修 `SqlRepo`
- 優點是根因修正最直接。
- `RepoProp.BatUpsert`、`RepoLearn.BatUpsert` 以及其他同類 upsert 都會一起變正確。
- 這是我目前認爲最合理的修法。

如果只修 `SvcWordV2`
- 我就得在 V2 同步前先手動消解衝突，例如：
  - 把全 0 `WordProp.Id` 換掉
  - 對“遠端 Id 命中本地軟刪行”的情況先做 revive / hard delete / 改 Id 之類的定向處理
- 這樣可以不碰 shared repo，但會更繞，且本質上是在業務層補 repo 層的洞。

還有一點我需要坦白說明：我剛纔已經先在 [SqlRepo.cs](/E:/_code/CsNgan.Dict/Tsinswreng.CsSql/proj/Tsinswreng.CsSql/SqlRepo.cs) 打了一個本地 patch，目的是驗證這個判斷是否真是根因；在你提醒後我就停住了，還沒繼續擴大修改，也還沒做最終回歸結論。  
如果你不想動 shared repo，我下一步可以把那個 patch 撤掉，改走純 `SvcWordV2` 方案。

你只要拍板一件事就行：

“允許修 `SqlRepo`”  
或者  
“只准修 `SvcWordV2`，不要動 shared repo”

你定了，我就繼續跑通並把全 0 `WordProp.Id` 的正式修復一起補上。
````
