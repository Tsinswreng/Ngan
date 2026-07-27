-Sesn[
	-T[2026_0723_200745][
		先看Skill和記憶。
		然後看CsNgaq這個項目。
		看
		`E:\_code\CsNgaq\Ngaq.Core\Shared\Word\Svc\ISvcWordV2.cs`。
		這裏有個單詞備份同步功能。
		有個雲端同步。
		目前雲端同步要連服務器、比較費錢且麻煩。
		我想再弄個基于git同步的同步功能。
		
		大致想法是:
		windows版和安卓版都調用本機的git命令、
		如果環境變量沒有 就支持設置git路徑。
		
		然後把詞庫當成git倉庫、自己設置源
		git push; git pull。
		
		想想是否可行、具體應該怎麼實施
		
	][
````md
初步判斷：Windows 版可行；Android 版「直接調本機 `git` 命令」通常不可行，因為 Android 沒有系統 Git，也沒有普通桌面環境的 PATH。這是目前必須先定下來的設計分叉。

另外，不能簡單地對同一個詞庫包執行 `git push; git pull`：

- 現有 `PackAllWordWithDel()` 產生的是壓縮二進制包，兩端同時修改後 Git 無法合併，只會產生 binary conflict。
- 正確順序至少應是：`pull/rebase → 導入遠端詞庫 → 業務同步合併 → 重新導出 → commit → push`。
- 更穩妥的做法是每臺設備寫自己的快照，例如 `devices/{DeviceId}/words.pack`。設備之間不修改同一文件，Git 只負責傳輸和保存歷史；拉取後，應用讀取其他設備快照，再交給現有 `OrdSyncJnWordByBizIdFromStream()` 做真正的業務合併。
- 這樣可以直接複用現有包含軟刪除的打包與按 `(Head, Lang)`、時間戳同步機制，不讓 Git 負責理解詞庫內容。

在繼續形成正式實施方案前，需要你先確認三點：

1. Android 端你希望選哪個方向？

   - 第一階段只支持 Windows 外部 Git，Android 後續單獨研究。
   - Android 要求用戶安裝 Termux/git，Ngaq 通過 Termux 接口調用。
   - App 自帶 Git 實現或 Git 可執行文件；工程量、AOT/原生庫和認證處理都會明顯增加。
   - 可以不執行真正的 Git 命令，改用 GitHub/GitLab/Gitea API 操作倉庫。

2. 你是否接受「每臺設備一份詞庫快照」？我推薦這個方案。若堅持所有設備共用一個 `words.pack`，就必須增加 Git 衝突處理，而且二進制包無法自動合併。

3. 遠端主要準備使用哪種認證？

   - HTTPS + Personal Access Token。
   - SSH key。
   - 依賴用戶電腦現有的 Git Credential Manager；這只適合 Windows，Android 無法保持相同體驗。

相關現有入口是 [ISvcWordV2.cs](E:/_code/CsNgaq/Ngaq.Core/Shared/Word/Svc/ISvcWordV2.cs:258)、[SvcWordV2.Sync.cs](E:/_code/CsNgaq/Ngaq.Backend/Domains/Word/Svc/SvcWordV2.Sync.cs:217) 和 [ClientWordSyncV2.cs](E:/_code/CsNgaq/Ngaq.Frontend/proj/Ngaq.Client/Word/Svc/ClientWordSyncV2.cs:15)。目前業務文檔目錄沒有詞庫備份同步的專門文檔；如果後續實施，應一併補上。
````
	]
	
	-T[2026_0723_214450][
		那算了、
		那就不讓程序強耦合git了。
		換一種方式用git、
		就是我專門弄一個git倉庫放文件、
		然後手動用git同步。
		手動git同步完了之後我再進程序裏同步。
		
		我想到幾種做法:
		一是直接把sqlite文件放去git版本控制。目前我的sqlite有30MB。
		Sqlite的東西最完整、不止單詞庫、還有別的 學習方案相關的、
		但是別的東西不常變、只有詞庫最常變。
		
		二是放二進制單詞包。我的sqlite輸出的單詞包有4MB多。
		
		三是壓縮前的原始jsonl。
		單個jsonl會大很多、但是方便diff。
		但是diff也沒甚麼用、每次輸出詞包的時候不知道順序固不固定。
		
		我希望持續長久用的時候整個倉庫的體積(包括.git文件夾)盡量少。
		還有沒有別的方案?
		你覺得怎麼做好? 我的程序需要做哪些配合的地方?
	][
````md
我建議不要把 SQLite 或目前的 GZip 詞包作為主要 Git 同步格式，而是新增一種「Git 友好的確定性分片 JSONL 導出格式」。

核心方案：

```text
repo/
  ngaq-sync.json
  devices/
    windows-pc/
      words/
        00.jsonl
        01.jsonl
        ...
        ff.jsonl
    android-phone/
      words/
        00.jsonl
        ...
        ff.jsonl
```

每臺設備只寫自己的目錄；Git 負責搬運文件，Ngaq 負責把其他設備的快照合入本地資料庫。

**三種現有方案比較**

| 方案 | 工作區體積 | `.git` 長期增長 | 可讀 Diff | 完整程度 | 建議 |
|---|---:|---:|---:|---:|---|
| SQLite 30MB | 中 | 較大且不穩定 | 不可讀 | 最完整 | 僅作災難備份 |
| 現有 GZip 詞包 4MB | 最小 | 容易每次接近新增整包 | 不可讀 | 僅詞庫 | 適合傳輸，不適合 Git |
| 單個原始 JSONL | 最大 | 通常較小 | 可讀 | 僅詞庫 | 可作第一版 |
| 分片、排序 JSONL | 較大 | 最小、最穩定 | 可讀 | 僅詞庫 | 最推薦 |

### 為甚麼不推薦 SQLite

SQLite 是分頁二進制文件。增刪資料、頁面分裂、索引調整、`VACUUM` 都可能改動大量二進制位置，Git 的增量壓縮效果不可預測。

而且不能直接複製正在使用的 SQLite：

- 連接未關閉時可能取得不一致快照。
- 如果以後啟用 WAL，還涉及 `-wal`、`-shm` 文件。
- 整庫恢復是「替換資料庫」，不適合兩臺設備各自修改後做業務合併。
- 不同版本的資料庫結構可能需要 migration，直接覆蓋風險較高。

如果需要完整災難恢復，可以另外提供「導出完整 SQLite 備份」，通過 SQLite Backup API 或 `VACUUM INTO` 產生一致快照。但它不應承擔日常同步。

### 現有二進制詞包的問題

目前詞包實際是：

```text
所有 JnWord → JSONL → 整體單一 GZip → TextWithStream
```

實現在 [Packer.cs](E:/_code/CsNgaq/Ngaq.Core/Shared/Sync/Packer.cs:16)。

單一 GZip 流中間發生少量變化，後續壓縮字節也可能大量變化，所以 Git 很難復用上一版本。即使工作區每次只有 4MB，持續提交後 `.git` 仍可能快速增加。

此外，目前導出查詢是普通 `SELECT`，沒有 `ORDER BY`，因此輸出順序沒有契約保證，見 [SqlRepo.cs](E:/_code/CsNgaq/Tsinswreng.CsSql/proj/Tsinswreng.CsSql/SqlRepo.cs:110) 和 [SvcWordV2.Sync.cs](E:/_code/CsNgaq/Ngaq.Backend/Domains/Word/Svc/SvcWordV2.Sync.cs:227)。

### 推薦的分片 JSONL

將每個 `JnWord` 序列化成一行，使用穩定算法分到固定數量的文件：

```text
shard = SHA-256(stable-key)[0]
```

第一版可以用 256 片，即 `00.jsonl` 到 `ff.jsonl`。如果詞庫不大，64 片也夠。

每個分片內必須：

- 按穩定鍵排序，例如 `(Head, Lang, Id)`。
- JSON 字段順序固定。
- 時間、數字、空值格式固定。
- 使用 UTF-8、固定 `\n` 換行。
- 包含軟刪除資料。
- 相同資料重複導出時，文件字節完全一致。
- 沒有內容的分片可以不建立，或始終建立空文件，但規則必須固定。

這樣修改一個詞通常只會改一個小文件。詞頭或 ID 改變導致分片遷移時，也只會涉及兩個分片。

不建議壓縮 JSONL 分片。Git 自己會壓縮及做 delta；預先 GZip 反而會破壞差異復用。

### 為甚麼要按設備分目錄

如果 Windows 和 Android 都生成同一組 `words/*.jsonl`，它們在同步前各自修改詞庫，Git 仍會發生內容衝突。

按設備保存快照後：

```text
devices/windows-pc/words/*.jsonl
devices/android-phone/words/*.jsonl
```

- Windows 只重寫 `windows-pc`。
- Android 只重寫 `android-phone`。
- 手動 Git 合併通常只是兩邊各增加自己的文件變更。
- Ngaq 導入其他設備的快照，利用現有業務同步規則合併。
- 導入完成後再重新導出自己的快照。

推薦操作順序：

```text
git pull
→ Ngaq 導入其他設備快照
→ Ngaq 導出當前設備快照
→ git add/commit/push
```

現有 `OrdSyncJnWordByBizId()` 已經可以承擔真正的合併工作，見 [ISvcWordV2.cs](E:/_code/CsNgaq/Ngaq.Core/Shared/Word/Svc/ISvcWordV2.cs:258)。因此不需要讓 Git 理解詞庫語義。

**程序需要配合的功能**

1. 新增「導出 Git 同步目錄」

   - 選擇倉庫或同步根目錄。
   - 設置穩定的 `DeviceId`，例如 `windows-pc`。
   - 確定性序列化及分片。
   - 先寫臨時目錄，成功後再原子替換，避免留下半套快照。
   - 刪除這臺設備上已經不再需要的舊分片。

2. 新增「從 Git 同步目錄導入」

   - 掃描其他 `DeviceId` 目錄。
   - 驗證 manifest 和格式版本。
   - 逐行流式解析，不一次把全部 JSONL 載入記憶體。
   - 送入現有 `OrdSyncJnWordByBizId()`。
   - 可以重複導入，操作必須冪等。

3. 增加 manifest

```json
{
  "format": "Ngaq.WordGitSync",
  "version": 1,
  "deviceId": "windows-pc",
  "shardCount": 256,
  "hash": "sha256",
  "wordSchemaVersion": 1
}
```

不要把每次變化的導出時間放入每個分片；否則即使沒有詞庫變動，也會產生 Git 修改。若需要時間，可以只放在一個很小的狀態文件中。

4. 增加導入檢查與結果報告

   - 格式版本不支持。
   - JSON 行損壞。
   - 分片位置與穩定鍵不匹配。
   - 重複 BizId 或重複 ID。
   - 導入多少、新增多少、更新多少、忽略多少、失敗多少。
   - 導入中途失敗時，最好整批事務回滾。

5. 保留現有詞包

現有 4MB GZip 詞包仍適合：

- 手工傳文件。
- HTTP 上傳下載。
- 單次備份。
- 快速導入導出。

不必用 Git 格式取代它，而是增加另一種專門面向版本控制的格式。

**完整資料的處理**

學習方案等其他資料不常變，我建議分兩層：

- 日常同步：分片 JSONL 詞庫。
- 偶爾完整備份：一致性 SQLite 快照，放在 Git 之外，或只保留最新一份。

如果你堅持把完整備份也放進倉庫，可以使用單獨分支或單獨倉庫，並定期重建歷史；否則完整 SQLite 的每次備份會抵消詞庫格式節省下來的空間。

**需求確認**

1. 我理解的需求是：程序不調 Git，只提供適合放進 Git 倉庫的導入、導出格式，由你手動執行 Git 操作。
2. 核心目標：多設備可合併詞庫，同時讓長期 `.git` 體積增長盡量小。
3. 建議納入：確定性輸出、分片、設備隔離、軟刪除、格式版本、流式導入、導入報告。
4. 建議不做：直接同步 SQLite、程序執行 Git、Git 衝突自動處理。
5. 建議保留：現有壓縮詞包作普通備份與傳輸格式。

正式設計前需要你確認兩個選擇：

- 是否接受「每臺設備一個目錄」？
- 第一版做簡單的「單個確定性 JSONL」，還是直接做我推薦的「64/256 分片 JSONL」？
````
	]
	
	-T[2026_0723_215901][
		那要分也是應該按客戶端實例爲單位分啊 按平臺分有甚麼用?? 根本不嚴謹。
		- 要  ngaq-sync.json 有甚麼用??
		- 你有沒有搞清楚本地.git的儲存機制?? 搞清對于可diff文本 每次commit之後他是存完整副本還是變化量
		- 有必要分片嗎??
		00.jsonl完了又01.jsonl  每個實例節點一個文件還不夠嗎?
		弄分片還更麻煩 要是變化的單詞散落在不同分片上呢?? 我又要同時寫?
		
	][
````md
你說得對。上一版有兩個判斷不嚴謹：

- 節點身份應是持久化的客戶端實例 `InstanceId`，不是 Windows/Android 平台。
- 在目前幾 MB 到幾十 MB 的規模下，我沒有充分理由直接引入 64/256 分片。每實例一個穩定 JSONL 文件更簡單，也很可能已經足夠。

**Git 實際怎麼存**

Git 的提交、樹、blob 模型中，每個文件版本對應一個 blob。從邏輯上看，blob 表示完整文件內容，不是補丁。

實際磁盤儲存分兩個階段：

1. 新提交最初通常成為 loose object。

   - 當前版本的完整文件內容經 zlib 壓縮後儲存。
   - 此時每個不同版本基本都有一份各自壓縮的完整 blob。
   - 相同內容不會重複存，因為 blob 以內容 hash 尋址。

2. 執行 `git gc`、`git repack`，或者遠端接收/傳輸時生成 packfile。

   - Git 可以選擇一個 blob 作基底。
   - 其他相似 blob 可以保存成 delta：從基底複製哪些區域、插入哪些新字節。
   - 它不是把 `git diff` 顯示出的文本行補丁直接存進去。
   - pack delta 本質上按字節尋找可複用區域，文本和二進制都可能 delta 壓縮。
   - 是否選中哪個基底、delta 深度、壓縮效果屬於 Git 的啟發式結果，不是嚴格保證。

所以答案是：

> 每次提交在 Git 的對象模型中是完整文件內容；新 loose object 通常也獨立保存完整壓縮內容；經過 `git gc/repack` 後，相似歷史版本通常會在 packfile 中按變化量儲存。

`git diff` 是否漂亮與 `.git` 如何儲存不是同一件事。但「穩定、相似的文本內容」同時有利於人類 diff 和 pack delta。

**一個 JSONL 文件夠不夠**

夠，而且我現在建議第一版就這樣做：

```text
repo/
  words/
    019f8f-client-a.jsonl
    019f90-client-b.jsonl
```

每個客戶端實例只重寫自己的文件。

即使一次修改的單詞散落在文件各處，也不需要分片。Git pack delta 可以表達多段變化：

```text
複製舊文件區段 A
插入修改內容
複製舊文件區段 B
插入修改內容
複製舊文件區段 C
```

它不要求變化集中在一處。

分片的主要作用不是「Git 才能儲存差異」，而是：

- 限制每次需要重寫的工作區文件大小。
- 降低極大文件的序列化和替換成本。
- 允許局部處理。
- 在文件達到幾百 MB 或上 GB 後改善部分 Git 操作。

你現在壓縮詞包只有 4MB，原始 JSONL 即使是幾十 MB，也沒有充分理由分片。分片反而增加文件管理、原子更新、殘留舊分片和格式設計的複雜度。

**`ngaq-sync.json` 有甚麼用**

主要用途本來是保存：

- 格式名稱和版本。
- `InstanceId`。
- 序列化格式版本。
- 分片算法與分片數量。
- 完整性校驗。

但如果不分片，它不是必需的。

更簡單的方案是將元信息放在 JSONL 第一行：

```json
{"$type":"NgaqWordSnapshot","formatVersion":1,"instanceId":"019f8f...","wordSchemaVersion":1}
{"word":{...},"props":[...],"learns":[...]}
{"word":{...},"props":[...],"learns":[...]}
```

或者文件中只保存 `JnWord`，格式版本放進文件名：

```text
words/{InstanceId}.v1.jsonl
```

我的傾向是首行元信息，因為程序拿到單個文件即可驗證，不依賴旁邊一定存在另一個文件。但如果你追求最純粹的 JSONL，每行都必須是 `JnWord`，那麼單獨的 manifest 才有價值。

全局 `ngaq-sync.json` 還有一個問題：所有實例都可能改它，會重新製造共享文件衝突。因此若需要元信息，也應放在實例文件內，或者：

```text
instances/{InstanceId}/meta.json
instances/{InstanceId}/words.jsonl
```

不能讓所有節點頻繁共同修改一個全局 manifest。

**推薦方案**

```text
repo/
  instances/
    {InstanceId-A}/
      words.v1.jsonl
    {InstanceId-B}/
      words.v1.jsonl
```

程序需要配合：

- 首次使用時生成並持久化一個真正的客戶端實例 ID，不能根據平台、機器名或用戶名臨時計算。
- 每個實例只寫自己的文件。
- 導出時按穩定鍵排序，建議至少按 `PoWord.Id`；如果同步的業務標識是 `(Head, Lang)`，可按 `(Head, Lang, Id)`。
- `Props`、`Learns` 內部也必須按各自 ID 排序，否則根詞順序固定了，聚合內部仍可能亂序。
- JSON 屬性順序、空值規則、時間格式、換行符必須固定。
- 相同資料連續導出兩次，文件應逐字節完全相同。
- 不寫每次都變的 `ExportedAt`；否則沒有業務變化也會產生提交。
- 導出到臨時文件，完成後原子替換自己的 JSONL。
- 導入其他實例的 JSONL，繼續走現有 `OrdSyncJnWordByBizId()`。
- 導入應記錄每個來源文件上次已處理的 Git commit 或文件 hash；文件沒變便不用重複解析。
- 保留軟刪除資料，否則刪除無法傳播。

**對倉庫體積的預期**

若原始 JSONL 是 20MB，首次提交可能增加接近「JSONL 自身壓縮後大小」。以後每次只改少量、且排序和序列化完全穩定，`git gc` 後新增歷史通常會遠小於完整 20MB。

這一般會顯著優於：

- 每次提交一個新的整體 GZip 流。
- 每次提交頁面位置可能變化的 SQLite。
- 每次輸出順序不固定的 JSONL。

但有一個同步語義問題需要你確認：已淘汰的客戶端實例文件要如何處理？如果它永久留在倉庫，而本地以後硬刪除了軟刪除墓碑，重新導入這個陳舊快照可能讓舊資料復活。可選方案是「禁止日常硬刪墓碑」，或者提供明確的「註銷實例快照」機制。這一點必須在實施前定下來。
````
	]
	
	-T[2026_0723_221126][
		最後一段提問沒看懂
	][
````md
意思是：倉庫中每個客戶端實例都有一份完整詞庫快照。如果某個實例以後不再使用，它留下的快照可能成為「過期資料來源」。

例如：

1. 手機 A 導出 `A/words.jsonl`，裏面有單詞 `apple`。
2. 電腦 B 同步後刪除 `apple`，先產生軟刪除記錄。
3. 後來程序執行 `HardDelSoftDeleted()`，把 `apple` 從數據庫徹底刪除。
4. 但倉庫中手機 A 的舊快照仍然保存着未刪除的 `apple`。
5. 電腦 B 再導入 A 的舊快照時，本地已經完全找不到 `apple`。
6. 現有同步邏輯會把它判定為 `LocalNotExist`，於是重新添加，`apple` 就「復活」了。

如果只軟刪、不硬刪，通常沒有這個問題，因為本地還保留着時間更新的刪除記錄，可以判斷舊快照更舊。

所以需要一條簡單規則。我推薦：

- 日常同步期間不執行 `HardDelSoftDeleted()`，永久保留軟刪除墓碑。
- 確定某個舊實例不再使用時，從當前版本的倉庫中刪除它的整個目錄。
- 如果將來需要清理墓碑，先確保所有仍有效的實例都完成同步並重新導出快照，再統一清理。

這不是分片或 Git 儲存問題，而是「完整快照同步 + 徹底刪除」本身的資料復活風險。
````
	]
	
	-T[2026_0726_164207][
		那就用這種方案:
		````
		<ClientId64進制>/
			
		
		````
	][
		
	]
	
]

