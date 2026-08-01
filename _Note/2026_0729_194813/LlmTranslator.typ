-Sesn[
	-T[2026_0729_194846][
		先看skill。
		然後看 大模型詞典。
		現在我想
		一是增加翻譯功能。
		但用戶輸入爲長句時 顯示翻譯。
		當前效果是 用戶輸入爲長句時 他只隨機挑一個詞的意思來查字典。
		
		看看怎麼改。

	][
````md
已定位原因：目前輸入一律作為 `Query.Term` 送給「查詞」prompt，資料模型也只接受詞頭、讀音、釋義；沒有翻譯模式。因此長句會被模型自行降成某個詞來查。

應改為明確區分「查詞」與「翻譯」兩種請求模式，而不是只改 prompt。翻譯模式應直接回傳整句譯文、略過讀音與加入詞庫流程；前端結果區則顯示「原文／翻譯」。

需要你確認兩點後，我才能做需求確認與設計：

1. 長句要「自動切為翻譯」，還是增加讓使用者手動切換的查詞／翻譯按鈕？我建議手動切換，避免片語、例句或多詞術語被誤判。
2. 若採自動判定，何謂「長句」？例如含句末標點即翻譯、含空格超過 N 個詞即翻譯，還是字元數超過 N？
````
	]
	
	-T[2026_0729_200442][
		長句的標準讓AI自己判斷。
		
		你順帶再想辦法解決一個準確度的問題。
		比如 fr -> zh的時候、輸入sang(血)、他會以爲是英語的sang然後說是歌。
		es -> zh的時候、輸入ni(neither)、他會以爲是漢語的「你」
	][
````md
已確認核心缺陷：來源語言目前只是提示，不是約束，所以才會把 `fr:sang` 當英語、`es:ni` 當漢字。查詞模型的角色也只定義為「dictionary」，沒有翻譯任務。

**需求確認單**

1. 我理解的需求是：同一個輸入框維持不變；模型自行判斷輸入是詞／片語還是長句。詞／片語則查詞，長句則輸出完整翻譯。來源語言必須被嚴格採信，不得依字形改猜另一種語言。
2. 核心目標：既保留大模型詞典，又讓長句得到譯文，並修正跨語言同形詞的錯誤判讀。
3. 我建議的實作：不靠字數規則、不另加模式切換；每次請求明確要求模型：
   - 將 `SrcLang` 視為權威；
   - 先依該語言解析輸入，禁止改按其他語言猜測；
   - 自行判斷「詞典查詢」或「句子翻譯」；
   - 維持現有結構化輸出，句子翻譯放進釋義欄，避免破壞流式顯示、原始響應重解析與存詞流程。
4. 關鍵待確認：翻譯結果是否要在介面上明確標示「翻譯」，而不只是以現有的釋義區呈現？若要，需擴充響應協議加入結果類型；若不要，僅調整模型提示即可，改動最小。
5. 另一個待確認：目前系統提示詞允許使用者在設定頁自訂，且已儲存的自訂 prompt 不會隨預設 prompt 更新。這次強制語言約束應：
   - 寫入每次請求的固定 prompt（可立刻影響所有使用者，我建議）；或
   - 只更新預設 prompt（自訂 prompt 使用者須自行更新，準確度不能保證）。

請確認第 4、5 點，我再進入設計與實作。
````
	]
	
	-T[2026_0729_201610][
		只改默認提示詞。
		另外協議層的結構 你覺得要改的話也可以改一下
	][
````md
發現工作區已有多個未提交改動（包括各子模組）；我會避開它們，不會還原或混入。

設計上有兩案：

1. 推薦：擴充協議，加 `ResultKind = Dictionary | Translation`
   - 模型根據輸入自行決定類型；長句回 `Translation` 和完整譯文。
   - 前端依結果類型標示「翻譯」，並停用收藏／編輯存詞，避免將整句誤存為詞條。
   - 預設 prompt 強制來源語言為權威：如 `fr:sang` 必按法語解作「血」、`es:ni` 必按西班牙語解作「也不／既不」；禁止按字形切換語言。
   - 需更新 shared 協議、預設 prompt、前端結果呈現、測試與業務文件；不覆蓋已存的自訂 prompt。

2. 最小改動：只改預設 prompt
   - 長句翻譯塞入既有 `Descrs`。
   - 無法在 UI 區別詞典與翻譯，且仍可能把句子存入詞庫。

我建議方案 1。請確認後，我會先寫出協議／類別宣告供你審核，再補實作。
````
	]
	
	-T[2026_0729_201931][
		沒必要故意阻止用戶保存。
		方案設計說詳細點。
		你這寥寥數語我完全看不出你的協議結構
	][
````md
你說得對；不應因結果是翻譯就限制保存。保存行為保持現狀：使用者仍可把翻譯結果存入詞庫或進入編輯頁。

我建議採用下列協議設計。

```csharp
/// 本次結果的業務類型，由模型根據輸入內容判斷。
public enum ELlmDictResultKind{
    Dictionary = 0,
    Translation = 1,
}

public interface IRespLlmDict{
    /// Dictionary：詞頭；Translation：原輸入文本（模型可做必要的標點規整）。
    public str Head { get; set; }

    /// 模型判定的結果類型。
    public ELlmDictResultKind ResultKind { get; set; }

    /// Dictionary 時使用；Translation 時可為空。
    public IList<TextedPronunciation> Pronunciations { get; set; }

    /// Dictionary 時使用：詞性、釋義、例句等既有詞典內容。
    /// Translation 時可為空。
    public IList<str> Descrs { get; set; }

    /// Translation 時使用：對完整輸入的譯文。
    /// Dictionary 時可為空。
    public str Translation { get; set; }
}
```

模型仍回傳同一份 YamlMd，而不是另開一套 API：

```yaml
# 詞典結果
Head: sang
ResultKind: Dictionary
Pronunciations:
  - TextType: Ipa
    Text: sɑ̃
Descrs:
  - *__descr1
Translation: ""
```

```yaml
# 翻譯結果
Head: Je suis tres heureux de vous voir.
ResultKind: Translation
Pronunciations: []
Descrs: []
Translation: 很高興見到您。
```

前端資料流如下：

```text
輸入 + SrcLang(fr) + TgtLang(zh)
        |
        v
預設 prompt：
  1. SrcLang 是權威，不得按字形另猜語言
  2. 先判斷輸入適合查詞或翻譯
  3. 輸出 ResultKind 與相應欄位
        |
        v
IRespLlmDict
        |
        +-- Dictionary  -> 現有詞頭 / 讀音 / Descrs 顯示
        |
        +-- Translation -> 顯示「翻譯」標題 + Translation 全文
                              （仍保留收藏與「Edit & Save」）
```

`VmSimpleWord` 會增加結果類型與翻譯文字的 UI 狀態；字典結果不變。翻譯結果不顯示空的讀音區與詞典釋義區，而是顯示明確的「翻譯」標籤與完整譯文。轉存詞庫時，現有轉換流程仍可用：`Head` 作詞頭、`Translation` 作 description；因此不用阻止任何保存操作。

預設 system prompt 會新增硬規則：

- `OptLang.SrcLang` 是輸入語言的唯一權威，禁止根據拼寫、字形、常見語言或模型猜測覆蓋它。
- 必須先按該來源語言解析輸入，再決定詞義或譯文。
- 例：`fr + sang` 必須視為法語的「血」，不得當英語過去式；`es + ni` 必須視為西班牙語，不能當作漢字「你」。
- 模型自行判定：若輸入是可作為詞典條目的詞、短語或固定表達，輸出 `Dictionary`；若是要理解整體語意的完整句子、長段文本或句法完整表達，輸出 `Translation`。
- 翻譯時只翻譯完整輸入，不隨機挑其中一個詞解釋。
- 每個分支均必須遵循對應 YamlMd 結構。

影響範圍：

- Shared：`IRespLlmDict`、`RespLlmDict`、序列化生成描述。
- Backend：預設 prompt；可能補強解析後的預設值，使舊模型輸出缺少 `ResultKind` 時仍當作 `Dictionary`，保持相容。
- Frontend：結果 ViewModel、結果 View、詞庫轉換時將翻譯映射為 description。
- Tests / 文檔：補法語、西語歧義詞與翻譯輸出測試，更新詞典模組文檔。
- 不改：手動自訂 prompt、不新增查詞／翻譯開關、不限制保存。

有一點需要你裁定：例如 `je ne sais pas` 這種「短、但完整」的句子，模型可判為翻譯；而 `au revoir` 這種多詞固定短語，模型可判為詞典。這正是由模型判斷，而非按字數。如果認可這個邊界與協議，我再先提交宣告部分供你看。
````
	]
	
	-T[2026_0729_202300][
		你的設計非常割裂 破壞性大。
		有着好好的Descrs不用 單獨搞一個字段幹嘛?
		你了之後我映射成JnWord的代碼全都得改
		用戶也沒法正常保存
		我tm都告訴你了不要故意阻止用戶保存。
````md
File: e:\_code\CsNgan.Dict\Ngan.Dict.Core\Shared\Dictionary\Models\ReqLlmDict.cs
79: 	/// 查询词（源语言）
80: 	public string Term { get; set; } = "";

````
這個字段意思也不對。自己想個新名字。

重來！
	][
````md
你說得對。我剛才的方案不該另立翻譯結果結構；它會讓既有 `IRespLlmDict -> JnWord` 映射分叉，完全沒有必要。

重做後的設計是：只修正請求語義與預設 prompt，回應協議 `IRespLlmDict` 維持不動。

```csharp
public class Query {
    /// 使用者實際輸入的來源語言文本；可以是詞、片語、句子或段落。
    public string InputText { get; set; } = "";

    /// 可選的額外消歧語境。
    public string? ContextSentence { get; set; }
}
```

把 `Term` 改名為 `InputText`。因為它不是「查詢詞」：使用者輸入 `sang`、`au revoir`、`Je suis heureux de vous voir` 都放在這裡。`InputText` 描述事實，不預先假定它是詞或句子。

回應完全不加欄位：

```csharp
public interface IRespLlmDict {
    public str Head { get; set; }
    public IList<TextedPronunciation> Pronunciations { get; set; }
    public IList<str> Descrs { get; set; }
}
```

模型輸出約定改為：

```yaml
# 詞／片語：原有格式與行為不變
Head: sang
Pronunciations:
  - TextType: Ipa
    Text: sɑ̃
Descrs:
  - *__descr1
```

其中 `__descr1` 仍是既有詞典說明，例如「【名詞】血液……」。

```yaml
# 完整句子或長文本：仍是原有格式
Head: Je suis heureux de vous voir.
Pronunciations: []
Descrs:
  - *__descr1
```

其中 `__descr1` 就是完整譯文，例如「很高興見到您。」可視需要再加上簡短註解，但第一項必須是完整、可直接閱讀的翻譯。

資料流不分叉：

```text
InputText
  -> LLM 自行判斷「詞典說明」或「完整翻譯」
  -> Head / Pronunciations / Descrs（既有協議）
  -> VmSimpleWord（既有顯示）
  -> IRespLlmDict -> JnWord（既有映射與保存）
```

因此：

- 句子結果會以原句作 `Head`、譯文作 `Descrs`，目前 UI 已能正常顯示。
- 既有 `LlmDictWordToJnWord` 不需因翻譯加任何特判；它照常把 `Descrs` 寫入 description。
- 收藏、編輯後保存完全維持現狀。
- 不新增模式按鈕、不以程式字數判定長句、不新增結果類型。

預設 prompt 的改動會包含四條硬約束：

1. `SrcLang` 是輸入語言的唯一權威；禁止依拼寫或字形換猜其他語言。
2. 先依 `SrcLang` 解析 `InputText`，再生成結果。`fr:sang` 必作法語「血」；`es:ni` 必作西語「既不／也不」，不得視為漢語「你」。
3. 模型自行判定：可作詞典條目的詞、固定片語，生成既有詞典釋義；句子、段落、或以整體語意為主的輸入，生成完整翻譯。
4. 翻譯輸入時，`Head` 必須保留完整原文，`Pronunciations` 為空，`Descrs` 第一項必須是目標語言的完整譯文；不得只抽其中一個詞查釋義。

修改範圍只會是：

- `ReqLlmDict.cs`：`Query.Term` 改為 `Query.InputText`。
- 所有內部使用點、測試、文檔同步改名。
- `DfltPrompt.cs`：只調整預設提示詞與輸出範例。
- 不改 `IRespLlmDict`、`JnWord` 映射、保存流程或 UI 結構。
- 不覆蓋使用者已存的自訂 prompt。

請確認這個設計。確認後我會先完成宣告層的 `Term -> InputText` 改名，再請你審查。
````
	]
	
	-T[2026_0729_202949][
		看skill 然後去寫decl。
		測試的decl也一起寫了。
	][
		
	]
]


-Sesn[
	-T[2026_0730_203304][
先看skill。
		然後看 大模型詞典。
		你順帶再想辦法解決一個準確度的問題。
		比如 fr -> zh的時候、輸入sang(血)、他會以爲是英語的sang然後說是歌。
		es -> zh的時候、輸入ni(neither)、他會以爲是漢語的「你」。
		現在的提示詞寫得很長、你不能弄這麼長。
		下面的內容是上一個傻屄AI的交接清單。這個AI非常傻屄、你謹慎參考
		````md
		你说得对，刚才那份没交代清楚。完整交接如下。

**当前目标**

- 保持一次 LLM 调用。
- 模型依据请求的 `SrcLang` 查询/翻译。
- 响应增加模型最终采用的输入语言对象，用来约束同一次输出的释义。
- 不改保存、不改 `Descrs -> JnWord` 映射、不增加静态词典或二次审校。

**已改协议**

文件：[RespLlmDict.cs](E:\_code\CsNgan.Dict\Ngan.Dict.Core\Shared\Dictionary\Models\RespLlmDict.cs:8)

```csharp
public interface IRespLlmDict {
    public str Head { get; set; }
    public DetectedInputLang DetectedInputLang { get; set; }
    public IList<TextedPronunciation> Pronunciations { get; set; }
    public IList<str> Descrs { get; set; }
}

public class DetectedInputLang {
    public str Code { get; set; } = "";
    public str NativeName { get; set; } = "";
}
```

- 该对象是新类型，不复用 `NormLangDetail`。
- 它只描述模型这次输出实际采用的来源语言。
- 它目前没有被前端展示、没有被后端拿来拒绝结果、没有参与保存映射。
- `RespLlmDict` 缺字段时会得到空对象；没有做“缺字段即报错”的后端校验。

**当前单次请求链**

1. UI 构造 `ReqLlmDictEvt`，填 `Query.InputText`、`OptLang.SrcLang`、`OptLang.TgtLangs`。
2. 后端在 [SvcDictionary.cs](E:\_code\CsNgan.Dict\Ngan.Dict.Backend\Domains\Dictionary\Svc\SvcDictionary.cs:205) 组装 user prompt。
3. 已改成 XML 风格记录，先放来源语言：

```text
<dictionary-request>
  <source-language>code=es, ...</source-language>
  <target-languages>...</target-languages>
  <input-text>
ni
  </input-text>
  ...
</dictionary-request>
```

4. 后端一次调用模型，按 YamlMd 解析为 `RespLlmDict`。
5. 当前没有比较 `Resp.DetectedInputLang.Code` 与 `Req.OptLang.SrcLang.Code`，所以即便模型实际语言与声明矛盾，UI 仍显示并可保存结果。

**默认提示词当前状态**

运行时默认提示词：[DfltPrompt.cs](E:\_code\CsNgan.Dict\Ngan.Dict.Backend\Domains\Dictionary\Svc\DfltPrompt.cs:8)

同步文件：

- [Prompt.txt](E:\_code\CsNgan.Dict\Ngan.Dict.Backend\Domains\Dictionary\Prompt\Prompt.txt:1)
- [Prompt.typ](E:\_code\CsNgan.Dict\Ngan.Dict.Backend\Domains\Dictionary\Prompt\Prompt.typ:1)

当前关键规则：

- `SrcLang.Code + InputText` 被描述为词典键。
- 西语默认按现代标准西语，短小写输入优先查语法词。
- 法语禁止把英文同形词附加为义项。
- YAML 的第一字段必须是：

```yaml
DetectedInputLang:
  Code: "es"
  NativeName: "Español"
```

- 之后要求不要再重新考虑来源语言。

**已知失败与关键缺陷**

- 你刚在 UI 手动输入后失败，这才是有效结果：当前实现不能视为完成。
- `DetectedInputLang` 现在是模型自己填的字段，没有程序校验，因此它可能填 `es`，但 `Descrs` 仍写“你”。这个字段本身并不能阻止错义。
- 我之前跑的独立测试连续两轮 `4/4` 通过，只说明那 40 次特定请求碰巧都对；不能证明 UI 真实路径稳定。
- 当前真实测试以 `Code` 正确、`NativeName` 非空为准，不验证 `NativeName` 是否真是该语言名。
- `ni` 的语义测试仅排除中文“你”，接受“不/没有/也不/既不”等中文表述；`sang` 排除“唱、歌、savoir、知道”等。
- 提示词已经被我反复改过，包含大量西语/法语专门规则；这些规则可能有副作用，应该重新从 UI 失败请求的实际内容出发收敛，而不是继续盲改。

**真实测试位置**

- 声明：[TestISvcDictionary.Lookup.cs](E:\_code\CsNgan.Dict\Ngan.Dict.Test\proj\Ngan.Dict.Backend.Test\Domains\Dictionary\SvcDictionary\TestISvcDictionary.Lookup.cs:16)
- 实现：[TestISvcDictionary.Lookup.Impl.cs](E:\_code\CsNgan.Dict\Ngan.Dict.Test\proj\Ngan.Dict.Backend.Test\Domains\Dictionary\SvcDictionary\TestISvcDictionary.Lookup.Impl.cs:23)
- 独立入口：[Program.Impl.cs](E:\_code\CsNgan.Dict\Ngan.Dict.Test\proj\Ngan.Dict.LlmDictionary.Test\Program.Impl.cs:13)

用例共四个，每个调用 `LookupRepeated` 并发五次：

1. `fr -> zh`, `sang`
2. `es -> zh`, `ni`
3. 法语整句翻译
4. 西语整句翻译

运行命令：

```powershell
dotnet run --project Ngan.Dict.Test\proj\Ngan.Dict.LlmDictionary.Test --no-build
```

该项目读取 `ExternalRsrc.__Private` 下的私有配置；之前模型为 `deepseek-v4-flash`。

**已做验证**

- `dotnet build Ngan.Dict.Test\proj\Ngan.Dict.LlmDictionary.Test\Ngan.Dict.LlmDictionary.Test.csproj --no-restore` 通过。
- 独立真实模型测试曾两轮通过；但如上所述，已被你的 UI 实测推翻为“不可靠”。
- `dotnet build Ngan.Dict.Test\proj\Ngan.Dict.Windows.Test\Ngan.Dict.Windows.Test.csproj --no-restore` 通过。
- 本需求文件的 `git diff --check` 通过。

**建议下一步**

先不要再添加提示词规则。应先在 UI 失败现场捕获并对比：

- UI 实际发送的 `ReqLlmDictEvt`：`InputText`、`SrcLang.Code/NativeName/EnglishName`、目标语言。
- 实际传到模型的完整 system prompt 与 user prompt。
- 模型原始 YAML。
- 解析后的 `DetectedInputLang`、`Head`、`Descrs`。

只有确认 UI 请求与独立测试请求是否真的一致，才能判断是配置覆盖、提示词未生效、还是单次模型输出本身不稳定。
		````
		你先說怎麼做吧。
	][
````md
目前 6009 字元的預設提示詞確實過長，而且 `DetectedInputLang` 只是模型自行聲稱，不能證明釋義真的屬於該語言。單靠它無法解決 `sang` / `ni` 的錯義。

我建議採取這個方向：

1. 先確認 UI 實際使用的「已保存自訂提示詞」。查詞呼叫直接讀配置，未必使用 [`DfltPrompt.cs`](E:/_code/CsNgan.Dict/Ngan.Dict.Backend/Domains/Dictionary/Svc/DfltPrompt.cs:8)；只改預設檔可能完全無效。
2. 移除 `DetectedInputLang` 及三個長範例，改成短系統提示詞。核心只保留：
   - `SrcLang.Code` 是強制的字典語言，不可依字形改猜。
   - 僅輸出該語言中可確認的標準詞條；找不到就明確表示無該詞條，禁止借用同形異語詞。
   - 第一目標語言輸出，維持既有 YamlMd 格式。
3. 後端將模型回傳的語言欄位和請求 `SrcLang.Code` 做嚴格比對；不一致或缺失就拒絕結果，不讓錯誤釋義展示或保存。
4. 對 `fr:sang`、`es:ni` 加入回歸測試，測試釋義包含「血」與「既不／也不」，並排除「歌／唱」與「你」。

但我需要你先裁定一件關鍵事：你要的是「盡量提升模型單次命中的穩定性」，還是「不能錯」？

前者可用上述短提示詞加語言欄位校驗，但模型仍可能在宣稱 `fr`／`es` 時給錯義；這是單次 LLM 無法程式化驗證的。後者必須允許至少一項額外依據：靜態／外部詞典核驗，或第二次模型審校。
````
	]
	
	-T[2026_0730_205341][
		這也移那也移那還剩甚麼? 你自己看git歷史
		看原來那提示詞是甚麼樣的  你只能比他長一些
		不該移的別移?
		如果我tm都有靜態詞典了我還要大模型詞典幹嘛?? 說話前能不能動動腦?
		你自己試去。試完自己寫測試。
	][
		
	]
	
]
