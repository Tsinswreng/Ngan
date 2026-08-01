#import "@preview/tsinswreng-auto-heading:0.1.0": auto-heading
#let H = auto-heading

#H[範圍與分層][
	Ngan.Ime 的 Windows 語音輸入已完成第一版可用鏈路：
	- `Ngan.Ime.Core` 定義 `IAudioInputSource`、`IAudioInputSession`、`IVoiceRecognitionProvider`、`IVoiceRecognitionSession` 及語音 DTO / 錯誤契約。
	- `Ngan.Ime.Backend` 實現火山引擎 v3 WebSocket 協議，命名空間爲 `Ngan.Ime.Backend.Voice.Volcengine`。
	- `Ngan.Ime.Windows` 使用 NAudio WASAPI 實現 PCM 採集與重採樣；目前 `BuiltInComInteropSupport=true`，NAudio 的 NativeAOT 發布相容性仍是後續驗證項。
	- `Ngan.Ime.UI` 的 `VmVoiceInput` 只編排抽象會話，不直接依賴火山或 Windows API。
]

#H[本機配置與安全][
	- 配置在 `Ngan.Ime/Ngan.Ime.Frontend/proj/Ngan.Ime.Windows/Ngan.Ime.Rw.jsonc` 的 `VoiceInput` 節點。
	- 憑據只能存在本機可寫配置；不得寫入代碼、文檔、AI 記憶或日誌。
	- Windows 運行時診斷檔爲輸出目錄的 `Ngan.Ime.Windows.log`；可記錄 PCM 長度、協議幀類型與快照長度，不記錄音頻內容、識別文本或憑據。
]

#H[火山已驗證結論][
	- 流式 ASR 2.0 小時版的資源 ID 爲 `volc.seedasr.sauc.duration`。
	- 服務端曾返回 `requested resource not granted`；在控制台爲 Ngan.Ime 應用開通「豆包流式語音識別模型 2.0 小時版」後才恢復可用。
	- 首包裸 PCM 應使用 `audio.format = "pcm"`、`codec = "raw"`。使用 `format = "raw"` 會收到 `unsupported format raw`。
	- 空尾包也必須帶合法 gzip 空流；零長壓縮負載會使服務端報 `unable to ungzip payload: EOF`。
	- 火山在最終結果帧後可能主動關閉 WebSocket；收到 `HasNegativeSequence` 最終帧後，不應將後續 close 當作識別失敗。
]

#H[Windows 音頻已修正問題][
	- `BufferedWaveProvider.ReadFully` 必須是 `false`；否則空輸入被補零，重採樣器會持續產生虛假 PCM 並瞬間灌滿網絡管線。
	- 重採樣輸出需要及時切成固定分片寫入 Channel，不能累積到回調結束後才排出，否則會 `Buffer full`。
]

#H[當前交互][
	圓形錄音按鈕有三個階段：
	- 空閒、完成或失敗：開始新會話。
	- 錄音中：停止採集、送尾包並等待最終結果。
	- 等待最終結果：再次點擊取消等待與會話。
	取消要先觸發會話取消令牌，再等待 `SessionGate`，避免收尾持鎖時取消無法即時生效。
]

#H[Android 適配][
	- Android 使用原生 `AudioRecord`，固定輸出 16 kHz、16-bit、單聲道 PCM，直接複用 Core 契約、火山後端與 UI。
	- 採集循環以固定分片寫入有界 Channel；隊列滿時終止會話，不靜默丟包或無限佔用內存。
	- Android 普通 Activity 與 InputMethodService 有兩套 DI 容器，兩邊都必須調用 `AndroidVoiceComposition.AddAndroidVoiceInput`。
	- Manifest 需要 `RECORD_AUDIO`。IME Service 缺權限時以專用 action 打開 MainActivity 申請；該路徑不順帶申請通知或懸浮窗權限。
	- 權限申請會結束當前錄音嘗試；授權後返回輸入法，再點一次錄音。
	- Android 資產配置不得內嵌 ApiKey；初始文件保留空憑據，安裝後在手機外部可寫 `Ngan.Ime.Rw.jsonc` 配置。跨平台默認 ResourceId 已統一爲已驗證的 `volc.seedasr.sauc.duration`。
	- 實現不使用反射掃描、dynamic、Emit 或運行時代碼生成；Android NativeAOT 仍需以 `PublishNativeAot.sh` 實際發布驗證。
	- 2026-07-26 Android 平台層曾完成一次 Debug 編譯（0 error）；後續乾淨重跑與 Release publish 被本機缺少 Android SDK API 36 `android.jar` 阻斷。
	- 同日 `PublishNativeAot.sh` 未進入編譯，原因是 Windows 尚未安裝 WSL Linux distribution；補齊 WSL、Linux Android SDK/NDK 後仍需完成真正 NativeAOT 發布與手機實測。
	- 手機上的 NativeAOT APK 實測 WebSocket TLS 失敗。logcat 明確報 `No implementation found for net.dot.android.crypto.DotnetProxyTrustManager.verifyRemoteCertificate(long)`，隨後爲 `net_http_ssl_connection_failed`；DNS 與目標域名 ping 正常，請求尚未到達火山鑒權層。
	- 已從手機拉取 APK 檢查：APK 使用單一 `libNgan.Ime.Android.so` NativeAOT 主庫，DEX 包含 `DotnetProxyTrustManager` Java 類，但主庫沒有對應的 `Java_net_dot_android_crypto_DotnetProxyTrustManager_verifyRemoteCertificate` JNI 導出。這是 .NET Android NativeAOT TLS Java-to-managed bridge 的打包/工具鏈問題，不是 ApiKey、ResourceId、麥克風或火山協議問題。
]

#H[流式文本現狀][
	目前正式配置回到 `wss://openspeech.bytedance.com/api/v3/sauc/bigmodel_nostream`：本機實測可在尾包後穩定返回最終文本。

	曾測試 `bigmodel` 與火山推薦的 `bigmodel_async`。兩者在錄音中都持續回協議幀，但每個中間帧均爲 `result.text` 空、`utterances` 空，只有最終負序號帧才有文字。這已由僅記錄快照長度的本機日誌驗證，並非 Ngan.Ime UI 綁定或 JSON 解析漏字。

	因此暫不再爲「中途出字」盲改客戶端。若日後重啓此項，需要先向火山確認：當前資源 / 應用是否實際開通能返回非空中間文本的雙向流式能力，或改用另一個明確支持即時 partial 的 ASR 服務。
]
