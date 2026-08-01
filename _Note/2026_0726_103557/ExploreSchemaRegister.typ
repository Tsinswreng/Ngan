-Sesn[
	-T[2026_0726_103627][
		先看skill和記憶。
		然後看
````md
File: d:\Program Files\Rime\User_Data\user.yaml
09:   schema_access_time:
10:     092H: 1738751230
11:     3dgx: 1676805659
12:     DksNoAbbrev: 1744459785
13:     MinimalTemplate: 1763988053
14:     OC_schuesslerOC: 1690708453
15:     TswgEnglish: 1764054817
16:     TswgIpa: 1764336787
17:     bopomofo_tw: 1669516862

````
說一下這些時間有甚麼用
	][
````md
`schema_access_time` 記錄的是：每個輸入方案最近一次被切換使用的時間。

這些數字是 Unix 時間戳，單位為秒。換算為上海時間：

| 方案 ID | 最近使用時間 |
|---|---|
| `092H` | 2025-02-05 18:27:10 |
| `3dgx` | 2023-02-19 19:20:59 |
| `DksNoAbbrev` | 2025-04-12 20:09:45 |
| `MinimalTemplate` | 2025-11-24 20:40:53 |
| `OC_schuesslerOC` | 2023-07-30 17:14:13 |
| `TswgEnglish` | 2025-11-25 15:13:37 |
| `TswgIpa` | 2025-11-28 21:33:07 |
| `bopomofo_tw` | 2022-11-27 10:41:02 |

它主要有兩個相關行為：

- 每次套用、切換輸入方案時，librime 執行 `time(NULL)`，更新該方案的時間戳，見 [engine.cc](E:/_code/_clone/rime/librime/src/rime/engine.cc:281)。
- 顯示方案選單時，通常按照這些時間戳由新至舊排列，讓最近用過的方案更靠前，見 [schema_list_translator.cc](E:/_code/_clone/rime/librime/src/rime/gear/schema_list_translator.cc:120)。

如果配置：

```yaml
switcher:
  fix_schema_list_order: true
```

則不再按照最近使用時間重新排序，而是保持 `schema_list` 中寫定的順序。

另外：

- `previously_selected_schema` 記錄最後選中的方案，主要用於下次初始化時恢復方案。
- `schema_access_time` 則主要用來排列方案選單。
- 它不是方案建立時間、配置修改時間，也不影響詞頻學習。
- 一般不需要手動修改；刪掉後只會失去既有的「最近使用」排序，Rime 後續切換方案時會重新生成。
- 如果某個時間戳晚於當前系統時間，librime 會忽略它，不用它參與最近使用排序，見 [schema_list_translator.cc](E:/_code/_clone/rime/librime/src/rime/gear/schema_list_translator.cc:107)。
````
	]

	-T[2026_0726_104331][
		UserData下面 哪些是Rime引擎的配置?
		不屬于任何一個方案專屬的、引擎層面的
	][
````md
嚴格按「不屬於任何方案、由 Rime 引擎全局使用」來分，`User_Data` 下主要是以下幾個。

| 文件 | 性質 | 用途 |
|---|---|---|
| [default.yaml](<D:/Program Files/Rime/User_Data/default.yaml>) | 引擎全局配置 | 方案列表、方案選單、全局選項保存、默認候選數、全局按鍵與標點引用等 |
| [default.custom.yaml](<D:/Program Files/Rime/User_Data/default.custom.yaml>) | 引擎全局補丁 | 覆蓋 `default.yaml`；通常應修改這個，而非直接改 `default.yaml` |
| [user.yaml](<D:/Program Files/Rime/User_Data/user.yaml>) | 引擎全局運行狀態 | 上次方案、方案使用時間、保存的全局選項、上次部署時間 |
| [installation.yaml](<D:/Program Files/Rime/User_Data/installation.yaml>) | 引擎部署／安裝信息 | 安裝 ID、Rime 版本、發行版信息、同步目錄等 |
| [rime.lua](<D:/Program Files/Rime/User_Data/rime.lua>) | librime-lua 全局入口 | 引擎載入 Lua 插件時執行一次；不是 YAML 配置，但也是引擎級文件 |

其中最核心的是：

### `default.yaml` / `default.custom.yaml`

這是實際的全局行為配置，例如：

```yaml
schema_list:       # 可用方案
switcher:          # 方案選單
menu:              # 候選菜單
ascii_composer:    # 中英文切換
```

你現在的 `default.yaml` 還引用了：

```yaml
punctuation:/...
key_bindings:/...
```

因此下面兩個文件雖然可供所有方案共用，但嚴格說不是「自動全局生效」的配置：

- [key_bindings.yaml](<D:/Program Files/Rime/User_Data/key_bindings.yaml>)
- [punctuation.yaml](<D:/Program Files/Rime/User_Data/punctuation.yaml>)

它們屬於共享配置模塊。只有被 `default.yaml` 或某個方案以 `__include`、`__patch` 引用後，相應內容才生效。

### `user.yaml`

這不是主要供人編輯的配置，而是 Rime 自動維護的全局狀態：

```yaml
var:
  last_build_time:
  option:
  previously_selected_schema:
  schema_access_time:
```

它不屬於任何單獨方案，但裏面可以按方案 ID 保存訪問時間。

### `installation.yaml`

這也是引擎／部署器級別，但偏向安裝元數據，而非輸入行為配置：

```yaml
installation_id:
distribution_code_name:
distribution_version:
rime_version:
install_time:
update_time:
```

其中 `installation_id` 也會用於用戶詞典同步身份。

### 不算引擎全局配置的文件

- `*.schema.yaml`：方案配置。
- `*.dict.yaml`：詞典配置及數據。
- `方案名.custom.yaml`：特定方案補丁。
- `weasel.yaml`、`weasel.custom.yaml`：小狼毫前端配置，不是 Rime 引擎配置。
- `*.trime.yaml`：同文前端配置。
- `processor_plugin.yaml`：你自己的共享配置模塊；目前由 `weasel.custom.yaml` 引用，本身不會自動全局生效。
- `build/`：部署生成結果，不是配置源文件。
- `*.userdb`、`*.ldb`、`*.commit`：用戶數據庫或運行數據，不是配置。
- `lua/`：Lua 模塊；可被方案或全局 `rime.lua` 使用，但不等於引擎配置。

所以，如果目的是為 Ngan.Ime 找出應當跨前端共用的 Rime 引擎文件，核心集合可以理解為：

```text
default.yaml
default.custom.yaml
user.yaml
installation.yaml
rime.lua                 # 啟用 librime-lua 時
key_bindings.yaml        # 被引用的共享模塊
punctuation.yaml         # 被引用的共享模塊
```

而 `weasel*` 和 `*.trime.yaml` 應留在各自前端層。
````
	]

	-T[2026_0726_111212][
		當前正在使用哪個方案
		當前可以切換到哪個方案
		是哪裏的配置決定的
	][
````md
這三件事由不同位置決定。

### 當前正在使用哪個方案

對於正在運行的某個 Rime session，真正的當前方案保存在該 session 的內存狀態中，需要調用：

```c
RimeGetCurrentSchema(session_id, ...)
```

才能準確得知。

僅看文件，不能百分之百確定某個正在運行的 session 當前用了甚麼，因為文件可能尚未落盤，或者不同 session 曾分別切換方案。

不過 [user.yaml](<D:/Program Files/Rime/User_Data/user.yaml:8>) 中記錄：

```yaml
previously_selected_schema: dks
```

表示最後一次選中的方案是 `dks`。新建 session 時，Rime 通常會據此選擇 `dks`。

切換方案時，librime 會同時更新：

```yaml
previously_selected_schema: dks
schema_access_time:
  dks: ...
```

實現位置是 [engine.cc](E:/_code/_clone/rime/librime/src/rime/engine.cc:281)。

因此可以表述為：

- 最後選中的方案：`dks`
- 新建 session 預期使用：`dks`
- 正在運行的 session 實際方案：應使用 `RimeGetCurrentSchema()` 查詢

### 當前可以切換到哪些方案

標準方案選單由部署後的 [build/default.yaml](<D:/Program Files/Rime/User_Data/build/default.yaml:124>) 中的 `schema_list` 決定。

當前實際列表是：

```yaml
schema_list:
  - schema: luna_pinyin
  - schema: dks_v
  - schema: ipa_yunlong
  - schema: cangjie5
  - schema: prd
  - schema: dks_phrase
  - schema: dks_
  - schema: dks
  - schema: dkp
  - schema: dkz
  - schema: dkn
  - schema: DksNoAbbrev
  - schema: MinimalTemplate
  - schema: TswgIpa
  - schema: TswgEnglish
```

也就是標準方案選單可以切換到這 15 個方案。

這份列表的源配置是 [default.custom.yaml](<D:/Program Files/Rime/User_Data/default.custom.yaml:44>)：

```yaml
patch:
  schema_list:
    ...
```

配置關係為：

```text
default.yaml
    +
default.custom.yaml 的 patch
    ↓ 重新部署
build/default.yaml
    ↓ librime 實際讀取
方案切換選單
```

所以修改方案列表應修改 `default.custom.yaml`，然後重新部署。

### 啟動時怎樣決定方案

正常情況下：

1. 從部署後的 `build/default.yaml/schema_list` 取得可選方案。
2. 從 `user.yaml/var/previously_selected_schema` 讀取上次方案。
3. 如果上次方案仍在 `schema_list` 中，就使用它。
4. 如果它不存在，就回退到 `schema_list` 中第一個有效方案。

你當前是：

```text
previously_selected_schema = dks
dks 存在於 schema_list
→ 新 session 選擇 dks
```

相關邏輯見 [switcher.cc](E:/_code/_clone/rime/librime/src/rime/switcher.cc:166)。

如果配置：

```yaml
switcher:
  fix_schema_list_order: true
```

Rime 會忽略 `previously_selected_schema` 的恢復邏輯，啟動時直接使用 `schema_list` 中第一個方案。你當前部署配置沒有設置它，所以默認是 `false`。

### 一句話概括

| 問題 | 決定位置 |
|---|---|
| 當前 session 實際使用甚麼 | session 內存；用 `RimeGetCurrentSchema()` 查 |
| 上次／新 session 使用甚麼 | `user.yaml/var/previously_selected_schema` |
| 方案選單可以切換到甚麼 | `build/default.yaml/schema_list` |
| 人應該在哪裏修改列表 | `default.custom.yaml/patch/schema_list` |
| 最近使用順序 | `user.yaml/var/schema_access_time` |
````
	]

	-T[2026_0726_112234][
		那說說部署的時候編譯dict的策略。
		你用adb 看 /sdcard/Android/data/Tsinswreng.Ngan.Ime/files/UserData/下面。
		當前啓用的方案是 dks。
		這個方案是依賴了 nonKanji, emoji, cangjie7-1, 日語假名 等dict的。
		但是部署的時候好像只編譯了dks, dks_v, dkn 的詞典
		其他的全都用不了。
		電腦上的就都能用。
		看看是怎麼回事

	][
````md
查清楚了。Ngan.Ime 的部署調用本身正常，主要問題是 `dks` 的依賴聲明和 7 月 5 日整理後的文件位置不再匹配；電腦端則被舊 `build` 產物掩蓋了。

### librime 編譯詞典的策略

完整部署時，librime：

1. 讀取部署後的 `default.yaml/schema_list`。
2. 對列表中的每個方案執行 `SchemaUpdate`。
3. 讀取每個方案的 `schema/dependencies`，再部署這些依賴方案。
4. 每次 `SchemaUpdate` 只檢查該方案的：

```yaml
translator:
  dictionary: xxx
```

然後編譯 `xxx.dict.yaml`。

它不會遍歷：

```yaml
table_translator@nonKanji
script_translator@hiragana
emoji:
  dictionary: emoji
```

因此，在 `dks` 裏引用一個具名 translator，並不會自動編譯其詞典。要生成詞典，必須存在對應方案：

```text
nonKanji.schema.yaml
emoji.schema.yaml
hiragana.schema.yaml
...
```

並把方案 ID 放進 `schema/dependencies` 或全局 `schema_list`。

上游邏輯見 [deployment_tasks.cc](E:/_code/_clone/rime/librime/src/rime/lever/deployment_tasks.cc:222) 和 [deployment_tasks.cc](E:/_code/_clone/rime/librime/src/rime/lever/deployment_tasks.cc:326)。

### Android 當前的問題

[dks.schema.yaml](<D:/Program Files/Rime/User_Data/dks.schema.yaml:86>) 聲明：

```yaml
dependencies:
  - blaGam1.0
  - nonKanji
  - Dks_v
  - cangjie5
  - cangjie7-1
  - cangjie7-1ForLookUp
  - terra_pinyin
  - emoji
  - dkp
  - ptl
  - zyenpheng
  - terra_pinyin
  - prd
```

但 Android 實際文件如下：

| 依賴 | Android 根目錄源文件 | 結果 |
|---|---|---|
| `nonKanji` | 只有 `nonKanji.dict.yaml`，沒有 `nonKanji.schema.yaml` | 無法作為依賴方案部署 |
| `emoji` | schema 和 dict 都被移到 `Stuff/` | 根目錄解析器找不到 |
| `cangjie7-1ForLookUp` | schema 和 dict 都不存在 | 無法部署 |
| `hiragana` | schema、dict 都存在，但 dependencies 中被註釋 | 不會編譯 |
| `katakana` | schema、dict 都存在，但 dependencies 中被註釋 | 不會編譯 |
| `chineseDict` | schema、dict 都存在，但未列入 dependencies | 不會編譯 |
| `dks_v` | 有依賴方案並成功部署 | 可用 |
| `cangjie7-1` | 有完整方案並成功部署 | 已有產物 |
| `terra_pinyin` | 有完整方案並成功部署 | 已有產物 |

Android `build` 中確實沒有：

```text
nonKanji.table.bin
emoji.table.bin
hiragana.table.bin
katakana.table.bin
cangjie7-1ForLookUp.table.bin
chineseDict.table.bin
```

所以 [dks.schema.yaml](<D:/Program Files/Rime/User_Data/dks.schema.yaml:205>) 中相應 translator 初始化後自然不能正常查詞。

### 為何電腦可以使用

Git 歷史已直接證明：2026-07-05 的提交 `67e6e8e 整理文件` 做了以下操作：

```text
emoji.dict.yaml       → Stuff/emoji.dict.yaml
emoji.schema.yaml     → Stuff/emoji.schema.yaml
nonKanji.schema.yaml  → Stuff/nonKanji.schema.yaml

刪除：
cangjie7-1ForLookUp.dict.yaml
cangjie7-1ForLookUp.schema.yaml
```

但是電腦的 `build/` 仍保留整理前生成的：

```text
emoji.table.bin
nonKanji.table.bin
cangjie7-1ForLookUp.table.bin
hiragana.table.bin
katakana.table.bin
```

librime 找不到源文件時，可以繼續重用既有 `.table.bin`。因此：

```text
電腦：舊 build 產物仍在 → 表面正常
Android：較乾淨地重新部署 → 缺陷暴露
```

如果清空電腦 `build` 再完整部署，預計也會遇到同樣問題。

### Ngan.Ime 本身

Ngan.Ime 啟動時已經執行完整維護：

```csharp
var full_check = RimeUtil.True;
apiFn.start_maintenance(full_check);
apiFn.join_maintenance_thread();
```

見 [RimeSetup.cs](E:/_code/CsRime/Ngan.Ime/Ngan.Ime.Rime/proj/Ngan.Ime.Rime/RimeSetup.cs:226)。

所以不是 Ngan.Ime 只要求編譯 `dks/dks_v/dkn`，而是 librime 只會編譯：

```text
schema_list 中的方案
+
schema/dependencies 中能找到同名 *.schema.yaml 的方案
```

### 尚有一個獨立問題

`cangjie5` 明明在 `schema_list` 且源文件存在，但 Android `build` 沒有它的產物，說明它進入部署後編譯失敗了。

目前 `Ngan.Ime.Rw.jsonc` 配置：

```json
"log_dir": ""
```

這會讓 librime 只寫 stderr，不保留原生日誌；現有 logcat 已沒有部署時的具體錯誤，所以我不能確定 `cangjie5` 失敗的精確原因。需要開啟原生日誌後重新部署才能繼續確認。

此外，[RimeSetupAndProcessor.cs](E:/_code/CsRime/Ngan.Ime/Ngan.Ime.Doc/proj/Ngan.Ime.Doc/Rime/RimeSetupAndProcessor.cs) 尚未記錄上述部署／依賴編譯規則。你要我下一步：

1. 修正所有依賴方案與文件位置，並補文檔；
2. 先只開啟部署日誌，重新部署確認全部失敗項。
````
	]

	-T[2026_0726_113632][
		那你幫我處理一下、幫我按最小的改動恢復回去
	][
````md
依照 `tsinswreng-design-before-coding`，修改前需要你先選定方案。

方案 1（推薦，最小恢復）：

- 把 `nonKanji.schema.yaml` 恢復到根目錄。
- 把 `emoji.schema.yaml`、`emoji.dict.yaml` 複製回根目錄，保留 `Stuff/` 中的副本。
- 從整理前提交恢復 `cangjie7-1ForLookUp.schema.yaml`、`cangjie7-1ForLookUp.dict.yaml`。
- 在 `dks.schema.yaml/schema/dependencies` 中啟用 `hiragana`、`katakana`，加入 `chineseDict`。
- 不清理其他無效依賴，不改 Ngan.Ime 代碼。
- 同步到手機，重新部署並檢查所有 `.table.bin`。
- 若 `cangjie5` 仍失敗，再單獨診斷，避免擴大本次改動。

方案 2（完整整理）：

- 除上述操作外，清理 `blaGam1.0`、`ptl` 等無法解析的依賴。
- 統一 `Dks_v`/`dks_v` 大小寫。
- 檢查 `dks` 所有 translator 的 dictionary，確保每個都有可部署方案。
- 改動更完整，但不符合「最小改動」。

我建議方案 1。你確認後我就實施、同步手機並實際部署驗證。
````
	]

	-T[2026_0726_113956][
		2吧。移到根目录了就不要放stuff了
	][

	]

	-T[2026_0726_115226][
		差一个nonKanji的行爲不一致。
		在電腦上、他能提前顯示未輸入完碼的候選。
		比如 😭 的編碼是 !xvk、
		那我輸 !x 他就會把 😭 也出到候選裏。
		在手機上則需要我完整輸入 !xvk
		看看怎麼回事
	][
````md
原因已找到：手機上的 `nonKanji` 方案編譯失敗，因此 `table_translator@nonKanji` 根本沒有成功載入。

Android 日誌明確報錯：

```text
failed to include section symbols:punctuator
error building config: nonKanji.schema
```

`nonKanji.schema.yaml` 中有：

```yaml
punctuator:
  import_preset: symbols
```

但手機 `UserData` 根目錄沒有 `symbols.yaml`。所以沒有生成：

```text
build/nonKanji.table.bin
build/nonKanji.prism.bin
```

結果就是：

- 電腦：舊的 `nonKanji.table.bin` 尚在，`enable_completion: true` 生效，輸入 `!x` 即可提前列出 `!xvk → 😭`。
- 手機：`nonKanji` 表未載入；完整輸入 `!xvk` 時顯示的 😭 來自 `DksUserDict`，而用戶詞典不提供這種前綴補全，所以必須輸入完整碼。

同一問題也導致 Android 的以下方案編譯失敗：

```text
nonKanji
hiragana
katakana
cangjie5
dks_phrase
dkz
```

它們都引用了缺失的 `symbols:/punctuator`。

最小且正確的修復是把現有：

```text
UserData/從程序文件夾/symbols.yaml
```

恢復到：

```text
UserData/symbols.yaml
```

然後同步手機並重新部署。這一個文件即可同時修復上述方案，不需要分別改動每個 schema。

這是實施中發現的新配置缺口。按照設計／停疑規則，我先停在這裏確認：是否按此方案把 `symbols.yaml` 移回根目錄（不保留 `從程序文件夾` 中的副本），再重新部署驗證？
````
	]

	-T[2026_0726_120503][
對。然後你去dks.schema裏寫清楚需要的文件清單。 lua/ ts 不寫、其他的寫。按文件寫 寫到註釋裏。 相于UserData根目錄。
	][
````md
電腦端已處理完成：

- `symbols.yaml` 已從 `從程序文件夾/` 移回 UserData 根目錄，原位置不再保留。
- [dks.schema.yaml](<D:/Program Files/Rime/User_Data/dks.schema.yaml:7>) 已加入必需文件清單。
- 清單使用相對 UserData 根目錄的路徑。
- 已排除 `lua/`、TypeScript、`build/`、`*.userdb`、`user.yaml` 等生成或用戶數據。

手機目前突然變成 ADB `offline`，因此同步和重新部署未能完成，不能確認 `nonKanji.table.bin` 已生成。請重新插拔 USB 或重新允許 USB 調試；設備恢復 `device` 狀態後告訴我，我會繼續同步並驗證 `!x` 提前顯示 😭。
````
	]

	-T[2026_0726_121339][
		把symbols弄回去之後也沒用。cangjie5也沒有。
		adb連回去了、你再看看
	][
````md
已修復並重新部署。

真正阻塞原因是 Android 上的 `installation.yaml` 被 ADB 推送後變成只讀，librime 無法保存安裝信息，因此根本沒有啟動部署。已修正其權限。

驗證結果：

- `nonKanji.table.bin`、`nonKanji.prism.bin`、`nonKanji.reverse.bin` 已生成並成功載入。
- `cangjie5.table.bin`、`cangjie5.prism.bin`、`cangjie5.reverse.bin` 已生成並成功載入。
- `symbols.yaml` 位於 UserData 根目錄，舊位置副本已刪除。
- [dks.schema.yaml](<D:/Program Files/Rime/User_Data/dks.schema.yaml:7>) 的必需文件清單已補上 `essay.txt`。
- 更新後的 `dks.schema.yaml` 已同步到手機。

librime 日誌確認：

```text
dictionary 'cangjie5' is ready.
dictionary 'nonKanji' is ready.
```

現在 `nonKanji` 的 `enable_completion: true` 已具備生效條件，輸入 `!x` 應能提前顯示 `!xvk → 😭`。

部署摘要仍有 3 個失敗，是方案列表中缺少源文件的其他方案，不影響 `dks`、`nonKanji` 和 `cangjie5`。
````
	]
]
