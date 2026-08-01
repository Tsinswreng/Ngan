= 自定义 js 权重算法插件格式

本文面向插件开发者，说明如何编写可被
`Ngan.Dict.Core.Shared.Word.Svc.JsWeightCalctr`
执行的 js 算法脚本。

== 挂载方式

- 在 `Ngan.Dict.Core.Shared.StudyPlan.Models.Po.WeightCalculator.PoWeightCalculator` 中：
  - `Type` 设为 `EWeightCalculatorType.JsV1`。
  - `Text` 填入完整 js 脚本。
- 运行时由 `Ngan.Dict.Backend.Domains.StudyPlan.Svc.SvcStudyPlan` 构造算法实例。

== 运行时上下文

脚本在 Jint 引擎中执行，可直接使用以下全局变量：

- `Ngan.Dict.WordsJson`:
  - 字符串，内容是单词列表 JSON。
  - 建议使用 `const words = JSON.parse(Ngan.Dict.WordsJson ?? "[]")` 解析。
- `Ngan.Dict.CalcArgJson`:
  - 字符串，内容是权重参数 JSON，可能为 `"null"`。
  - 建议使用 `const arg = JSON.parse(Ngan.Dict.CalcArgJson ?? "{}")` 解析。
- `console.log(...args)`:
  - 可输出运行日志到后端 logger。

== 返回值契约

- 脚本必须 `return` 一个 JSON 字符串。
- 返回空字符串会触发业务错误。
- 返回内容可被反序列化到 `Ngan.Dict.Core.Shared.Word.Svc.JsWeightResult`。

推荐返回结构：

```json
{
  "Opt": {
    "SortBy": "Weight",
    "ResultType": "AsyEIWordWeightResult"
  },
  "Results": [
    {
      "StrId": "word-id",
      "Weight": 1.23,
      "Index": 0
    }
  ],
  "Props": {
    "Algo": "YourPluginName"
  }
}
```

字段说明：

- `Opt.SortBy`:
  - 支持 `Weight` 或 `Index`。
  - 对应 `Ngan.Dict.Core.Shared.Word.Models.Weight.ESortBy`。
- `Opt.ResultType`:
  - 建议固定填 `AsyEIWordWeightResult`。
- `Results`:
  - 每项对应 `Ngan.Dict.Core.Word.Models.Weight.WordWeightResult`。
  - `StrId` 必填；`Weight` 建议为有限数字；`Index` 可用于稳定排序。
- `Props`:
  - 可选。用于回传插件自定义诊断信息。

== 最小可用示例

```js
const words = JSON.parse(Ngan.Dict.WordsJson ?? "[]");
const arg = JSON.parse(Ngan.Dict.CalcArgJson ?? "{}");
const baseWeight = Number(arg.BaseWeight ?? 0);
const step = Number(arg.Step ?? 1);

const results = words.map((w, i) => ({
  StrId: String(w.Id ?? w.StrId ?? ""),
  Weight: baseWeight + i * step,
  Index: i
}));

return JSON.stringify({
  Opt: {
    SortBy: "Weight",
    ResultType: "AsyEIWordWeightResult"
  },
  Results: results,
  Props: {
    Algo: "SampleFromWordsAndArg",
    Count: results.length
  }
});
```

== 常见错误

- 脚本为空或全空白：
  - 会触发 `JsWeightCalcCodeEmpty`。
- 脚本返回空字符串：
  - 会触发 `JsWeightCalcReturnedEmpty`。
- 返回内容不是合法 JSON 或结构不匹配：
  - 会触发 `JsWeightCalcReturnedInvalidJson`。
- 脚本内抛异常：
  - 会被包装为 `JsWeightCalcExecFailed`。

== 开发建议

- 对 `Ngan.Dict.CalcArgJson` 的每个字段做兜底处理，避免 `NaN`。
- 对输入单词数组做空值与字段缺失防御。
- 先保证 `Results` 中每项都有 `StrId`，再逐步增加复杂策略。
- 在算法迭代时保留 `Props` 版本字段，便于排查线上问题。
