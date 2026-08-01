= Android NativeAOT 試驗記錄

本文記錄 Ngan.Dict Android 項目在 `.NET 10` 下啓用 `PublishAot` 的調查、環境配置、故障定位及最終成功流程。

記錄日期：2026-07-19 至 2026-07-20。

涉及文件：

- `E:\_code\CsNgan.Dict\Ngan.Dict.Frontend\proj\Ngan.Dict.Android\Ngan.Dict.Android.csproj`
- `E:\_code\CsNgan.Dict\PublishAndroid.sh`

== 最終結論

`Ngan.Dict.Android` 可以啓用 Android NativeAOT，但目前驗證成功的可靠流程是在 Linux 環境中發布。

本次最終在 WSL2 Ubuntu 中成功完成了單一 `android-arm64` 的 NativeAOT 編譯、Android 資源處理、APK 打包和簽名，`dotnet publish` 的退出碼爲 `0`。

成功產物：

```text
\\wsl.localhost\Ubuntu-20.04\home\tsinswreng\ngan.dict-android-linux-build-clean\artifacts\publish\Ngan.Dict.Android\release_android-arm64\Tsinswreng.Ngan.Dict-Signed.apk
```

產物信息：

- APK 大小：`38,388,009` 字節。
- APK 中包含的 ABI：`arm64-v8a`。
- NativeAOT 生成的 `Ngan.Dict.Android.o` 大小：`334,294,933` 字節。
- 最終 `Ngan.Dict.Android.so` 大小：`69,178,176` 字節。
- APK v1、v2、v3 簽名驗證通過。
- 當前使用 Android Debug 證書簽名，不是正式發布證書。

本次成功所使用的主要工具鏈：

- WSL：`2.7.10.0`。
- WSL kernel：`6.18.33.2-2`。
- Ubuntu userspace：`Ubuntu 22.04.5 LTS`。
- .NET SDK：`10.0.107`。
- .NET Android workload：`36.1.69/10.0.100`。
- Android SDK Platform：API 36。
- Android Build Tools：`36.0.0`。
- Android Platform Tools：`37.0.0`。
- Android NDK：r27c，版本 `27.2.12479018`。

== 原始問題

原項目不設置 `PublishAot` 時，可以在 Windows 上通過 `PublishAndroid.sh` 生成 APK。

加入：

```xml
<PublishAot>true</PublishAot>
```

後，NativeAOT 原生鏈接階段出現大量未定義符號：

```text
ld.lld : error undefined symbol: std::__ndk1::__libcpp_verbose_abort(char const*, ...)
ld.lld : error undefined symbol: std::__ndk1::to_chars(char*, char*, float, ...)
ld.lld : error undefined symbol: std::__ndk1::to_chars(char*, char*, double, ...)
clang : error linker command failed with exit code 1
```

最初需要判斷兩個方向：

1. Windows 到 Android 的 NativeAOT 跨操作系統編譯是否本身不受支持。
2. Android NDK、libc++ 或鏈接配置是否不匹配。

== 項目中的 AOT 配置

調查時 `Ngan.Dict.Android.csproj` 中相關配置爲：

```xml
<AndroidEnableProfiledAot>false</AndroidEnableProfiledAot>
<UseMonoRuntime>false</UseMonoRuntime>

<AndroidEnableAot>true</AndroidEnableAot>
<PublishAot>true</PublishAot>

<AndroidLinkMode>Full</AndroidLinkMode>
<PublishTrimmed>true</PublishTrimmed>
<TrimMode>link</TrimMode>
<AllowMissingPrunePackageData>true</AllowMissingPrunePackageData>
```

其中需要區分兩類 AOT：

- `AndroidEnableAot` 是傳統 Mono Android AOT 相關開關。
- `PublishAot=true` 且 `UseMonoRuntime=false` 時，.NET Android SDK 選擇 NativeAOT runtime。

.NET Android SDK 的實際判斷邏輯大致爲：

```xml
<UseMonoRuntime Condition="'$(PublishAot)' == 'true' and '$(UseMonoRuntime)' == ''">false</UseMonoRuntime>
<_AndroidRuntime Condition="'$(PublishAot)' == 'true' and '$(UseMonoRuntime)' != 'true'">NativeAOT</_AndroidRuntime>
```

因此，這次真正執行的是 NativeAOT，不是 Mono AOT。

`AndroidEnableAot` 在 NativeAOT 模式下沒有必要，後續整理配置時可以考慮移除，但本次試驗沒有修改項目文件。

== Windows 端調查

=== `DisableUnsupportedError` 的作用

Windows 版 .NET Android SDK 的 `Microsoft.Android.Sdk.NativeAOT.targets` 中存在：

```xml
<!-- NativeAOT's targets currently gives an error about cross-compilation -->
<DisableUnsupportedError
    Condition="$([MSBuild]::IsOSPlatform('windows')) and '$(DisableUnsupportedError)' == ''">
    true
</DisableUnsupportedError>
```

它的作用只是關閉 NativeAOT 原本針對“不支持跨操作系統編譯”的阻止性錯誤，讓 Android SDK 可以繼續嘗試調用 NDK 和 clang。

它不代表以下事項：

- Windows 到 Android 的 NativeAOT 已成爲正式支持方案。
- Windows 和 Linux 構建行爲完全一致。
- 多 RID 聚合、鏈接及輸出路徑都已可靠實現。
- Android NativeAOT 已適合生產使用。

構建時 SDK 還會明確輸出：

```text
XA1040: The NativeAOT runtime on Android is an experimental feature
and not yet suitable for production use.
```

=== Windows 鏈接錯誤的直接原因

Windows 環境中雖然設置了：

```text
ANDROID_NDK_HOME=D:\ENV\Android\Sdk\ndk\28.0.12674087
```

但 MSBuild 詳細日誌顯示，實際構建自動選擇的是：

```text
Android NDK: D:\ENV\Android\Sdk\ndk\23.2.8568313\
```

使用 NDK 自帶的 `llvm-nm` 檢查後確認：

- NDK r23 的 `libc++_static.a` 不提供報錯中的浮點 `std::to_chars` 和 `__libcpp_verbose_abort`。
- NDK r28 beta2 的 `libc++_static.a` 提供這些符號。
- Linux NDK r27c 的 `libc++_static.a` 也提供這些符號。

所以原始 `undefined symbol` 的直接原因是構建錯用了過舊的 NDK r23，而不是項目 C\# 代碼直接造成的。

在 Windows 上臨時指定 NDK 28：

```powershell
dotnet publish .\Ngan.Dict.Frontend\proj\Ngan.Dict.Android\Ngan.Dict.Android.csproj `
  -c Release `
  -r android-x64 `
  -p:AllowMissingPrunePackageData=true `
  -p:AndroidNdkDirectory=D:\ENV\Android\Sdk\ndk\28.0.12674087
```

單一 `android-x64` RID 可以完成鏈接和 APK 生成。這證明 NDK 版本確實解決了最初的 libc++ 符號錯誤。

但是，這只是一項 Windows 實驗性單 RID 結果，不能作爲最終推薦發布方案。

=== Windows 無 RID 發布問題

按原 `PublishAndroid.sh` 的方式，不傳 `-r` 進行 NativeAOT 發布時，SDK 會嘗試處理 `android-arm64` 和 `android-x64`。

兩個 RID 的原生庫能分別生成在：

```text
bin\Release\net10.0-android\android-arm64\native\Ngan.Dict.Android.so
bin\Release\net10.0-android\android-x64\native\Ngan.Dict.Android.so
```

但外層 publish 又嘗試複製不存在的無 RID 文件：

```text
bin\Release\net10.0-android\native\Ngan.Dict.Android.so
```

最後報錯：

```text
MSB3030: 無法複製文件“bin\Release\net10.0-android\native\Ngan.Dict.Android.so”，
原因是找不到該文件。
```

因此 Windows 無 RID NativeAOT 發布沒有完成根 `publish` 目錄的 APK 輸出。

== WSL 工具鏈配置

=== .NET Android workload

WSL 中原有 .NET SDK，但最初沒有 Android workload：

```text
.NET SDK 10.0.107
No workloads installed
```

Ubuntu 套件版 .NET 在：

```text
/usr/lib/dotnet
```

並通過以下標記使用 user-local workload 模式：

```text
/usr/lib/dotnet/metadata/workloads/10.0.100/userlocal
```

因此正確安裝方式是不加 `sudo`：

```bash
dotnet workload install android
```

曾經使用 `sudo dotnet workload install android`。命令表面顯示成功，但 workload garbage collection 隨後又卸載了剛安裝的 .NET 10 Android packs。

普通用戶重新安裝後，安裝記錄一度存在但物理 pack 不完整。最後通過：

```bash
dotnet workload repair -v minimal
```

補齊了以下關鍵 pack：

- `Microsoft.Android.Sdk.Linux/36.1.69`
- `Microsoft.Android.Ref.36/36.1.69`
- `Microsoft.Android.Runtime.NativeAOT.36.android-arm64/36.1.69`
- `Microsoft.Android.Runtime.NativeAOT.36.android-x64/36.1.69`
- `Microsoft.NETCore.App.Runtime.AOT.linux-x64.Cross.android-arm64/10.0.10`
- `Microsoft.NETCore.App.Runtime.AOT.linux-x64.Cross.android-x64/10.0.10`

最終 workload 狀態：

```text
Installed Workload Id: android
Manifest Version: 36.1.69/10.0.100
```

=== Android SDK 與 Build Tools

.NET Android workload 不等同於 Google Android SDK。

要完成 APK 構建，另外需要：

- Android SDK Platform 36，其中包含 `android.jar`。
- Android Build Tools 36.0.0，其中包含 `aapt2`、`d8`、`zipalign`、`apksigner` 等工具。
- Platform Tools，其中包含 `adb` 等工具。

.NET SDK 自帶的 `InstallAndroidDependencies` target 曾嘗試下載：

```text
https://aka.ms/AndroidManifestFeed/d18-0
```

但請求超時，且本地備用文件 `AndroidManifestFeed_d18.0.xml` 不存在，所以安裝失敗。

之後改用 Google 官方 command-line tools。

安裝目錄：

```text
/home/tsinswreng/Android/Sdk
```

安裝組件：

```text
platforms;android-36
build-tools;36.0.0
platform-tools
```

最終已驗證文件：

```text
/home/tsinswreng/Android/Sdk/platforms/android-36/android.jar
/home/tsinswreng/Android/Sdk/build-tools/36.0.0/aapt2
/home/tsinswreng/Android/Sdk/build-tools/36.0.0/apksigner
/home/tsinswreng/Android/Sdk/build-tools/36.0.0/zipalign
/home/tsinswreng/Android/Sdk/platform-tools/adb
```

解壓 Google command-line tools 時使用 JDK 的 `jar`，它不會保留 ZIP 中腳本的 executable bit。因此解壓後需要補上：

```bash
chmod 755 "$HOME/Android/Sdk/cmdline-tools/latest/bin/"*
```

否則 `sdkmanager` 雖然存在，但不能執行。

=== Linux NDK

Windows NDK：

```text
D:\ENV\Android\Sdk\ndk\28.0.12674087
```

只有：

```text
toolchains/llvm/prebuilt/windows-x86_64
```

其中是 `clang.exe`、`clang++.exe`，不能直接供 WSL/Linux NativeAOT targets 使用。

可用的 Linux NDK 位於：

```text
D:\ENV\_wsl\android-ndk-r27c
```

WSL 路徑爲：

```text
/mnt/d/ENV/_wsl/android-ndk-r27c
```

版本：

```text
Pkg.Revision = 27.2.12479018
Pkg.ReleaseName = r27c
```

它包含：

```text
toolchains/llvm/prebuilt/linux-x86_64
```

已驗證工具：

- `clang`
- `clang++`
- `llvm-ar`
- `llvm-nm`
- `llvm-objcopy`
- `ld.lld`

它的 `libc++_static.a` 也包含原始報錯所缺少的 `std::to_chars` 和 `__libcpp_verbose_abort`。

== WSL 崩潰及更新

最初使用的 WSL 版本爲：

```text
WSL 2.5.9.0
kernel 6.6.87.2
```

在 ILLink 或 ILC 階段，Linux 構建日誌會突然停止，沒有 MSBuild、ILLink、ILC、clang 或 OOM 錯誤。

Windows 事件日誌曾記錄：

```text
Faulting application: wslservice.exe
Exception code: 0xc00000fd
```

`0xc00000fd` 表示 Windows native stack overflow。事件時間與多次 NativeAOT 中斷時間一致。

更新 WSL 並清理磁盤空間後，版本變爲：

```text
WSL 2.7.10.0
kernel 6.18.33.2-2
```

更新後構建可以穩定越過 ILLink 和 ILC，最終完成 NativeAOT 及 APK 打包。因此，本機舊 WSL service 的崩潰確實是此前的重要阻塞因素。

== 中間產物污染

這次調查中同一工作區曾被 Windows 和 WSL 分別構建。

如果 WSL 直接使用項目默認 `bin/obj`，可能遇到兩類問題：

1. WSL 增量構建復用 Windows 生成的 NativeAOT `.o`、`.so` 或 linked assemblies。
2. WSL/WSL service 異常中止後留下 0 字節或不完整的 AAPT2 `.flat` 文件。

實際遇到的損壞文件：

```text
/home/tsinswreng/ngan.dict-android-linux-build/artifacts/obj/Ngan.Dict.Android/
release_android-arm64/lp/130/jl/flat/values_string.arsc.flat
```

該文件大小爲 `0` 字節，導致：

```text
APT2113: failed to read magic from input
APT2066: failed parsing overlays
```

這不是 Android 資源源文件本身出錯，而是中間緩存損壞。

最終成功時沒有直接刪除舊 artifacts，而是使用全新的目錄：

```text
/home/tsinswreng/ngan.dict-android-linux-build-clean/artifacts
```

這證明 NativeAOT 和 AAPT2 構建應避免混用 Windows 與 Linux 的中間輸出。

== 最終成功命令

在 WSL 中執行：

```bash
cd /mnt/e/_code/CsNgan.Dict/Ngan.Dict.Frontend/proj/Ngan.Dict.Android

dotnet publish Ngan.Dict.Android.csproj \
  -c Release \
  -r android-arm64 \
  --artifacts-path /home/tsinswreng/ngan.dict-android-linux-build-clean/artifacts \
  -p:AllowMissingPrunePackageData=true \
  -p:AndroidSdkDirectory=/home/tsinswreng/Android/Sdk \
  -p:AndroidNdkDirectory=/mnt/d/ENV/_wsl/android-ndk-r27c \
  -p:UseSharedCompilation=false \
  -nodeReuse:false \
  -v:minimal
```

各參數作用：

- `-c Release`：使用 Release 配置。
- `-r android-arm64`：只發布 arm64，生成適合大多數現代 Android 真機的 `arm64-v8a` APK。
- `--artifacts-path`：將所有 `bin/obj/publish` 放到 WSL ext4，避免 Windows/WSL 中間產物互相污染。
- `AndroidSdkDirectory`：指定 Linux Android SDK。
- `AndroidNdkDirectory`：指定 Linux NDK r27c。
- `UseSharedCompilation=false`：不啓用共享 C\# compiler server，減少跨構建殘留狀態。
- `-nodeReuse:false`：禁用 MSBuild node reuse。

成功產物目錄：

```text
/home/tsinswreng/ngan.dict-android-linux-build-clean/artifacts/publish/
Ngan.Dict.Android/release_android-arm64/
```

其中包含：

```text
Tsinswreng.Ngan.Dict-Signed.apk
Tsinswreng.Ngan.Dict.apk
Ngan.Dict.Android.so
```

== APK 驗證

簽名驗證命令：

```bash
SDK="$HOME/Android/Sdk"
APK="$HOME/ngan.dict-android-linux-build-clean/artifacts/publish/Ngan.Dict.Android/release_android-arm64/Tsinswreng.Ngan.Dict-Signed.apk"

"$SDK/build-tools/36.0.0/apksigner" \
  verify --verbose --print-certs "$APK"
```

驗證結果：

```text
Verifies
Verified using v1 scheme: true
Verified using v2 scheme: true
Verified using v3 scheme: true
Number of signers: 1
Signer certificate DN: CN=Android Debug, O=Android, C=US
```

檢查 APK ABI：

```bash
jar tf "$APK" \
  | grep -E '^lib/[^/]+/' \
  | sed -E 's#^lib/([^/]+)/.*#\1#' \
  | sort -u
```

結果：

```text
arm64-v8a
```

== 尚未處理的問題

=== NativeAOT 仍是實驗功能

.NET Android SDK 36.1.69 仍明確警告 Android NativeAOT 不適合生產使用。

在正式投入發布前，至少需要進行：

- 真機啓動測試。
- 主要 UI 流程測試。
- SQLite 讀寫測試。
- 網絡請求測試。
- 音頻、通知、權限等 Android 特有功能測試。
- Release 正式簽名測試。

=== `JsonStringEnumConverter` AOT 警告

ILC 輸出：

```text
IL3050: JsonStringEnumConverter cannot be statically analyzed
and requires runtime code generation.
Applications should use the generic JsonStringEnumConverter<TEnum> instead.
```

涉及：

```text
Ngan.Dict.Core.Infra.AppJsonCtx..cctor()
```

這不是本次 APK 生成的阻止性錯誤，但可能在運行時破壞相關 enum JSON 序列化功能。

後續需要查找非泛型：

```csharp
new JsonStringEnumConverter()
```

並根據實際 enum 類型改用泛型 converter 或源生成器兼容方案。

=== Mono.Android ILC 警告

ILC 還輸出：

```text
Android.Runtime.RuntimeNativeMethods.monodroid_unhandled_exception(...)
will always throw because: Invalid IL or CLR metadata
```

這來自 Android runtime assembly 與實驗性 NativeAOT 集成，需要在真機運行時觀察異常處理路徑是否正常。

=== 只驗證了 arm64

本次最終成功的 APK 只包含：

```text
arm64-v8a
```

尚未完成：

- `android-x64` 的純 Linux 干淨構建。
- 同時包含 arm64 和 x64 的通用 APK。
- 不傳 `-r` 時的 Linux 多 RID 聚合輸出。

如果主要目標是真機安裝，單 `android-arm64` 通常已足夠；如果需要 x64 Android 模擬器，還要另外生成 x64 APK 或研究多 ABI 聚合。

=== 正式簽名

當前 `Tsinswreng.Ngan.Dict-Signed.apk` 使用的是 Android Debug 證書。

正式發布需要配置自己的 keystore、alias 和密碼，不能直接把本次 Debug-signed APK 當作商店或正式分發產物。

=== `PublishAndroid.sh` 尚未更新

本次只完成調查和手動驗證，沒有修改：

- `Ngan.Dict.Android.csproj`
- `PublishAndroid.sh`

後續如果要固化流程，腳本至少應處理：

- 明確在 WSL/Linux 執行。
- 指定 `android-arm64` 或其他所需 RID。
- 指定 Linux Android SDK 和 NDK 路徑。
- 將 artifacts 放在 WSL ext4，而不是與 Windows 共用默認 `bin/obj`。
- 成功後按需把 APK 複製回 Windows 工作區的發布目錄。
- 在複製前驗證 publish 退出碼及 APK 是否存在。

== 建議的後續方向

1. 先修復 `JsonStringEnumConverter` 的 AOT 兼容警告。
2. 將成功 APK 安裝到 arm64 Android 真機，完成啓動和核心功能冒煙測試。
3. 確認是否只需要 arm64；若需要模擬器，再單獨驗證 `android-x64`。
4. 設計新的 WSL 發布腳本，避免 Windows/Linux 共用中間產物。
5. 配置正式 keystore，驗證正式簽名發布。

== 總結

最初的 libc++ 未定義符號由過舊 NDK r23 引起；使用 NDK r27c/r28 可解決該鏈接問題。

Windows Android SDK 雖然通過 `DisableUnsupportedError` 允許實驗性跨平台嘗試，但無 RID 多架構發布存在聚合輸出問題，所以不應把 Windows 單 RID 成功視爲正式可靠方案。

WSL 初期又受到舊版 `wslservice.exe` 崩潰和損壞中間緩存影響。更新到 WSL 2.7.10.0、使用完整 Linux Android 工具鏈，並將全新 artifacts 放到 WSL ext4 後，`android-arm64` NativeAOT APK 最終成功生成。
