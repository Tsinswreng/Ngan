= Custom JS Weight Algorithm Plugin Format

This document is intended for plugin developers. It describes how to write a js algorithm script that can be executed by `Ngan.Dict.Core.Shared.Word.Svc.JsWeightCalctr`.

== Mounting Method

- In `Ngan.Dict.Core.Shared.StudyPlan.Models.Po.WeightCalculator.PoWeightCalculator`:
  - Set `Type` to `EWeightCalculatorType.JsV1`.
  - Set `Text` to the complete js script.
- At runtime, an instance of the algorithm is constructed by `Ngan.Dict.Backend.Domains.StudyPlan.Svc.SvcStudyPlan`.

== Runtime Context

The script is executed in the Jint engine and can directly use the following global variables:

- `Ngan.Dict.WordsJson`:
  - A string containing the JSON of the word list.
  - Recommended usage: `const words = JSON.parse(Ngan.Dict.WordsJson ?? "[]")`.
- `Ngan.Dict.CalcArgJson`:
  - A string containing the JSON of weight parameters, may be `"null"`.
  - Recommended usage: `const arg = JSON.parse(Ngan.Dict.CalcArgJson ?? "{}")`.
- `console.log(...args)`:
  - Can output runtime logs to the backend logger.

== Return Value Contract

- The script **must** `return` a JSON string.
- Returning an empty string triggers a business error.
- The returned content must be deserializable into `Ngan.Dict.Core.Shared.Word.Svc.JsWeightResult`.

Recommended return structure:

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

Field descriptions:

- `Opt.SortBy`:
  - Supports `Weight` or `Index`.
  - Corresponds to `Ngan.Dict.Core.Shared.Word.Models.Weight.ESortBy`.
- `Opt.ResultType`:
  - It is recommended to always fill in `AsyEIWordWeightResult`.
- `Results`:
  - Each item corresponds to `Ngan.Dict.Core.Word.Models.Weight.WordWeightResult`.
  - `StrId` is required; `Weight` should be a finite number; `Index` can be used for stable sorting.
- `Props`:
  - Optional. Used to return plugin-specific diagnostic information.

== Minimal Working Example

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

== Common Errors

- Empty or completely blank script:
  - Triggers `JsWeightCalcCodeEmpty`.
- Script returns an empty string:
  - Triggers `JsWeightCalcReturnedEmpty`.
- Returned content is not valid JSON or has mismatched structure:
  - Triggers `JsWeightCalcReturnedInvalidJson`.
- Exception thrown inside the script:
  - Wrapped as `JsWeightCalcExecFailed`.

== Development Recommendations

- Provide fallback handling for every field in `Ngan.Dict.CalcArgJson` to avoid `NaN`.
- Defensively handle empty values and missing fields in the input word array.
- First ensure every item in `Results` has a `StrId`, then gradually add more complex strategies.
- Keep a version field in `Props` when iterating on the algorithm to facilitate troubleshooting in production.
