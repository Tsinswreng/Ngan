---

name: tsinswreng-write-comment

description: 寫代碼一定要有註釋。寫代碼寫註釋時使用此skill

---

## 代碼註釋規範

AI新寫代碼的時候即默認需要詳盡地添加註釋。 **!應加盡加 寧濫勿缺!**

### 添加註釋的位置

- 文件頭部
- 類型(class/interface/struct/enum等)
- 方法(不管是不是public)
- 類型的成員(包括字段和訪問器 事件等等、不管是不是public)
- 函數內部實現

### 目標

- 讓讀者快速理解「意圖、約束、邊界條件」等等，而不是重複代碼表面含義。

### 函數內部實現 加註釋的要求

- 應加盡加 寧濫勿缺 尤其是難一眼看懂的複雜邏輯 包括但不限于: 分支/狀態轉換
- 函數實現內 如果可以劃分出多個子步驟時、 在每個子步驟的開頭 添加概括性註釋。 如

```cs
DoSomething() {
	// step 1: xxx
	......
	// step 2: yyy
}
```

### 禁止事項

- 不爲顯而易見的代碼添加機械式註釋。
- **修改代碼時禁止隨意刪除已有的註釋**

### 示例

```cs
/// 提供輕量級內存緩存，支持絕對過期和滑動過期策略。
/// 非線程安全，僅適用於單線程環境；緩存容量無上限。

using System;
using System.Collections.Generic;

/// 簡單的內存緩存管理器。
/// 避免重複計算或頻繁 I/O，適用於配置數據、臨時結果等場景。
/// 鍵不能爲 null；過期時間爲 UTC 時間；容量無限制。
public class CacheManager {
	/// 存儲緩存項的字典，鍵爲 string，值爲 (object 數據, DateTime 過期時間)
	private readonly Dictionary<string, (object Value, DateTime Expiry)> _cache = new();

	/// 獲取當前緩存中的條目數量（用於監控）。
	public int Count => _cache.Count;

	/// 添加或更新緩存項。
	/// <param name="key">緩存鍵，不能爲 null 或空字符串。</param>
	/// <param name="value">要緩存的值。</param>
	/// <param name="absoluteExpiration">絕對過期時間（UTC），必須大於當前時間。</param>
	/// <exception cref="ArgumentNullException">當 key 爲 null 或空時拋出。</exception>
	/// <exception cref="ArgumentException">當 absoluteExpiration 小於等於當前 UTC 時間時拋出。</exception>
	public void Set(string key, object value, DateTime absoluteExpiration) {
		// 邊界條件校驗
		if (string.IsNullOrEmpty(key)){
			throw new ArgumentNullException(nameof(key), "鍵不能爲空");
		}
			
		if (absoluteExpiration <= DateTime.UtcNow){
			throw new ArgumentException("過期時間必須晚於當前時間", nameof(absoluteExpiration));
		}
		// 直接覆蓋已有鍵，實現“添加或更新”語義
		_cache[key] = (value, absoluteExpiration);
	}

	/// 嘗試獲取緩存值。若鍵不存在或已過期，返回 false。
	/// 注意：該方法不會主動觸發過期清理，只檢查指定項。
	/// <param name="key">緩存鍵。</param>
	/// <param name="value">輸出參數，若成功則返回緩存值，否則爲 default。</param>
	/// <returns>是否成功獲取到未過期的值。</returns>
	public bool TryGet(string key, out object? value) {
		value = null;

		// 鍵不存在時直接返回，避免不必要的過期檢查
		if (!_cache.TryGetValue(key, out var entry))
			return false;

		// 檢查過期時間，已過期則視同未命中並移除該條目（惰性刪除策略）
		if (entry.Expiry <= DateTime.UtcNow) {
			_cache.Remove(key);
			return false;
		}

		value = entry.Value;
		return true;
	}
}
```
