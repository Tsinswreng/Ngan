#import "@preview/tsinswreng-auto-heading:0.1.0": auto-heading
#let H = auto-heading;

此文件僅指導 按keys.ts給指定的語言添加翻譯


#H[模板][
完整的譯文鍵模板: `Ngan.Dict.Frontend/I18n/keys.ts`

添加指定語言:
如 `Ngan.Dict.Frontend/I18n/langs/en.ts`

```ts
import type { TI18nKv } from "../i18n";
const a: TI18nKv = {
	
}
export default a
```

此時a爲空對象、不滿足 `TI18nKv` 類型、會有編譯錯誤。你需要按 `keys.ts`補全鍵與譯文。
]

#H[鍵格式與譯文格式][
	#H[譯文格式][
		使用 ICU MessageFormat 格式。 僅支持數字參數 如 `{0}` `{1}`、不支持名稱參數！

		參數後面可做條件判斷

		示例:
		```cs
		var pattern = "there are {0, plural, =0 {zero} =1 {one} =2 {two} other {#}}"
		```
		- `are` 後面的`0` 代表這是0號參數
		- plural 表示一種選擇模式
		- `=0{zero}` 即 `if(arg==0){return "zero";}`
		- `other{#}` 即 `else{return arg;}`
	]

	約定 連續的兩個下劃線 表示參數佔位符
	如
	:
	- 鍵定義: `Select__From__:K`
	- 翻譯(zh-TW): `Select__From__: '從{1}選取{0}'`
	- 翻譯(en): `Select__From__: 'select {0} from {1}'`
		約定 參數的順序和*鍵定義的標識符*的順序一致。

		例: en: `From__Select__: 'select {1} from {0}'`

		葉子節點的鍵格式最好接近英文版的譯文。
]

#H[ts中的大括弧對象字面量必須尾隨逗號 以統一格式][
	
]
