= Avalonia 12 Android NativeAOT 獨立試驗記錄

本文記錄使用 Avalonia 12 的全新 `avalonia.xplat` 模板，獨立驗證 Android NativeAOT 編譯及真機啓動情況的過程。

記錄日期：2026-07-21。

本次試驗遵守以下限制：

- 不修改 Ngaq 現有項目的 Avalonia 版本。
- 不修改 `Ngaq.Android.csproj` 中的 Avalonia 套件引用。
- 不使用 Windows 進行 NativeAOT 跨操作系統編譯。
- 在 WSL 使用全新的獨立測試項目和獨立 artifacts 目錄。
- 通過真機進程、Activity 狀態和 `adb logcat` 收集運行證據，不根據編譯成功推測運行一定成功。

== 調查背景

Ngaq 當前使用的主要版本爲：

```text
Avalonia.Android 11.3.8
Xamarin.AndroidX.CustomView 1.1.0.20
Xamarin.AndroidX.Core 1.12.0.2
```

Ngaq 使用 Avalonia 11.3.8 生成的 Android NativeAOT APK 可以完成編譯、打包、簽名和安裝，但在真機啓動時停留在啓動畫面。

`adb logcat` 已確認直接原因不是通知權限，也不是 Ngaq 業務初始化，而是 Avalonia Android accessibility 初始化階段調用了 NativeAOT 不支持的 Reflection.Emit：

```text
System.PlatformNotSupportedException: PlatformNotSupported_ReflectionEmit
at System.Reflection.Emit.ReflectionEmitThrower.ThrowPlatformNotSupportedException()
at Android.Runtime.JNINativeWrapper.CreateDelegate(Delegate dlg)
at AndroidX.CustomView.Widget.ExploreByTouchHelper.GetGetVirtualViewAt_FFHandler()
at Microsoft.Android.Runtime.ManagedTypeManager.RegisterNativeMembers(...)
at Java.Interop.ManagedPeer.RegisterNativeMembers(...)
at AndroidX.CustomView.Widget.ExploreByTouchHelper..ctor(View)
at Avalonia.Android.AvaloniaAccessHelper..ctor(AvaloniaView)
at Avalonia.Android.AvaloniaView..ctor(Context)
at Avalonia.Android.AvaloniaMainActivity.InitializeAvaloniaView(...)
at Avalonia.Android.AvaloniaActivity.OnCreate(Bundle)
```

在 Ngaq 中，異常發生在：

```text
Ngaq.Frontend/proj/Ngaq.Android/MainActivity.cs:61
```

即：

```csharp
base.OnCreate(savedInstanceState);
```

它發生在通知初始化之前，所以 NativeAOT 版本首次啓動時不會像 CoreCLR 版本一樣請求通知權限。

這次試驗要回答的問題是：

1. Avalonia 12 的最小 Android 項目能否完成 NativeAOT 發佈。
2. Avalonia 12 NativeAOT APK 能否在同一臺真機啓動。
3. Avalonia 11.3.8 的 `ExploreByTouchHelper -> JNINativeWrapper.CreateDelegate -> Reflection.Emit` 崩潰是否仍然存在。
4. 如果不再崩潰，差異來自 Avalonia accessibility 實作改變，還是 AndroidX binding／.NET Android 工具鏈更新。

== 結論

Avalonia 12.1.0 的最小 Android 項目可以在 WSL 中成功生成 `android-arm64` NativeAOT Signed APK，也可以在本次測試手機上安裝並啓動。

真機啓動後已確認：

- NativeAOT runtime provider 成功初始化。
- NativeAOT 生成的應用原生庫成功載入。
- JNI `JNI_OnLoad()` 成功。
- Android Activity 成爲前臺 `ResumedActivity`。
- 應用進程在觀察期間持續存活。
- Android `SurfaceView` 和 buffer queue 已建立。
- 日誌顯示 Android 已提交首個 frame。
- 沒有出現 `PlatformNotSupported_ReflectionEmit`。
- 沒有出現 `JNINativeWrapper.CreateDelegate`。
- 沒有出現 `ExploreByTouchHelper` 初始化異常。
- 沒有出現 managed fatal exception 或 native fatal signal。

因此，可以確定 Avalonia 12.1.0 加上本次使用的新版 AndroidX bindings，已經避開 Ngaq/Avalonia 11.3.8 當前遇到的 accessibility JNI 註冊崩潰。

但目前還不能把結論寫成「Avalonia 12 Android NativeAOT 已完整適合生產使用」，原因包括：

- .NET Android SDK 36.1.69 仍明確將 Android NativeAOT 標爲 experimental。
- 編譯時仍有 `Mono.Android` NativeAOT 分析警告。
- 手機在最後的可見 UI 驗證時進入 PIN 鎖屏；adb 不能替代用戶輸入 PIN，所以尚未核對模板中的 `Welcome to Avalonia!` 是否正常顯示及 TextBox 是否可交互。
- 本次只測試了最小模板，尚未測試 Ngaq 的完整依賴、業務代碼、SQLite、網絡、通知、音頻及其他 Android 功能。

準確說法是：

```text
Avalonia 12.1.0 的最小 Android NativeAOT 應用可以成功編譯、安裝和進入前臺運行，
並且沒有重現 Avalonia 11.3.8 的 Reflection.Emit 啓動崩潰；
但完整 UI 交互與生產可用性仍需繼續驗證。
```

== 試驗環境

=== WSL

實際使用的 distro 名稱：

```text
Ubuntu-20.04
```

此前更新後的 WSL 平臺版本：

```text
WSL 2.7.10.0
kernel 6.18.33.2-2
```

本次命令從 Windows 通過以下方式進入正確 distro：

```powershell
wsl.exe -d Ubuntu-20.04 -- bash -lc "..."
```

不能使用：

```powershell
wsl.exe -d Ubuntu -- ...
```

因爲本機沒有名爲 `Ubuntu` 的 distro，會得到：

```text
Wsl/Service/WSL_E_DISTRO_NOT_FOUND
```

=== .NET 與 Android workload

```text
.NET SDK: 10.0.107
Workload version: 10.0.110
Android workload: 36.1.69/10.0.100
```

`dotnet workload list` 顯示：

```text
Installed Workload Id      Manifest Version
android                    36.1.69/10.0.100
```

=== Android SDK 與 NDK

Linux Android SDK：

```text
/home/tsinswreng/Android/Sdk
```

Linux NDK r27c：

```text
/mnt/d/ENV/_wsl/android-ndk-r27c
```

NDK 版本：

```text
27.2.12479018
```

這裏必須使用包含 `toolchains/llvm/prebuilt/linux-x86_64` 的 Linux NDK，不能把只包含 Windows `clang.exe` 的 Windows NDK 直接拿給 WSL 使用。

=== 真機

```text
Device ID: 899PKZQWJ7VCBEWK
Model: 23054RA19C
ABI: arm64-v8a
```

Windows adb：

```text
D:\ENV\Android\Sdk\platform-tools\adb.exe
```

== Avalonia 12 模板

=== 模板版本確認

NuGet 已提供 Avalonia 12 正式版本。調查時 `Avalonia.Android` 和 `Avalonia.Templates` 均已有 `12.1.0`。

官方 NuGet flat-container endpoints：

- #link("https://api.nuget.org/v3-flatcontainer/avalonia.android/index.json")[Avalonia.Android versions]
- #link("https://api.nuget.org/v3-flatcontainer/avalonia.templates/index.json")[Avalonia.Templates versions]

安裝模板：

```bash
dotnet new install Avalonia.Templates::12.1.0
```

命令成功，但 .NET CLI 提示 `::` 分隔符已棄用，今後建議改成：

```bash
dotnet new install Avalonia.Templates@12.1.0
```

`avalonia.xplat` 模板的關鍵預設值：

```text
Target framework: net10.0
Avalonia version: 12.1.0
```

模板還提供：

```text
--remove-view-locator
```

模板說明指出預設 ViewLocator 不利於 trimming。爲了讓最小 NativeAOT 試驗不受已知 trimming 不友好代碼干擾，本次建立項目時使用了：

```text
--remove-view-locator true
```

=== 獨立項目目錄

測試項目建立在 WSL 使用者目錄：

```text
/home/tsinswreng/avalonia12-nativeaot-test
```

它不在 `E:\_code\CsNgaq` 中，因此不會修改 Ngaq 項目文件、NuGet 中間產物或 Avalonia 版本。

建立命令：

```bash
mkdir -p /home/tsinswreng/avalonia12-nativeaot-test
cd /home/tsinswreng/avalonia12-nativeaot-test

dotnet new avalonia.xplat \
  -n Avalonia12AotTest \
  -f net10.0 \
  -av 12.1.0 \
  --remove-view-locator true \
  --no-update-check
```

生成的 Android 項目：

```text
/home/tsinswreng/avalonia12-nativeaot-test/Avalonia12AotTest/
Avalonia12AotTest.Android/Avalonia12AotTest.Android.csproj
```

其應用 ID：

```text
com.CompanyName.Avalonia12AotTest
```

因爲它使用獨立 package ID，所以安裝和測試不需要卸載或覆蓋 `Tsinswreng.Ngaq`。

=== 套件版本

模板生成的 `Directory.Packages.props` 明確使用：

```text
Avalonia 12.1.0
Avalonia.Android 12.1.0
Avalonia.Themes.Fluent 12.1.0
Avalonia.Fonts.Inter 12.1.0
```

restore 後實際解析到的重要 AndroidX binding：

```text
Xamarin.AndroidX.CustomView 1.2.0.3
Xamarin.AndroidX.Core 1.17.0.2
Xamarin.AndroidX.Core.SplashScreen 1.0.1.15
```

== NativeAOT 發佈

本次沒有編輯測試項目的 `.csproj`，而是在命令行傳入 NativeAOT 參數。

完整發佈命令：

```bash
cd /home/tsinswreng/avalonia12-nativeaot-test/Avalonia12AotTest

dotnet publish \
  Avalonia12AotTest.Android/Avalonia12AotTest.Android.csproj \
  -c Release \
  -r android-arm64 \
  --artifacts-path /home/tsinswreng/avalonia12-nativeaot-test-artifacts \
  -p:UseMonoRuntime=false \
  -p:PublishAot=true \
  -p:PublishTrimmed=true \
  -p:AndroidSdkDirectory=/home/tsinswreng/Android/Sdk \
  -p:AndroidNdkDirectory=/mnt/d/ENV/_wsl/android-ndk-r27c \
  -p:AllowMissingPrunePackageData=true \
  -p:UseSharedCompilation=false \
  -nodeReuse:false
```

參數作用：

- `-r android-arm64`：生成適合本次真機的 arm64 APK。
- `UseMonoRuntime=false`：讓 .NET Android SDK 選擇 NativeAOT runtime。
- `PublishAot=true`：啓用 NativeAOT 發佈。
- `PublishTrimmed=true`：執行 trimming，這是 NativeAOT 發佈的重要部分。
- `--artifacts-path`：將測試輸出放在 WSL ext4 的獨立目錄，避免和 Windows 或 Ngaq 的 `bin/obj` 混用。
- `AndroidSdkDirectory`：明確指定 Linux Android SDK。
- `AndroidNdkDirectory`：明確指定 Linux NDK r27c。
- `UseSharedCompilation=false`：禁用共享 `C#` compiler server。
- `-nodeReuse:false`：禁用 MSBuild node reuse，減少殘留進程狀態影響。

=== 發佈結果

`dotnet publish` 退出碼爲 `0`。

Signed APK：

```text
/home/tsinswreng/avalonia12-nativeaot-test-artifacts/publish/
Avalonia12AotTest.Android/release_android-arm64/
com.CompanyName.Avalonia12AotTest-Signed.apk
```

文件大小：

```text
20,290,589 bytes
```

未簽名 APK：

```text
/home/tsinswreng/avalonia12-nativeaot-test-artifacts/publish/
Avalonia12AotTest.Android/release_android-arm64/
com.CompanyName.Avalonia12AotTest.apk
```

文件大小：

```text
20,226,517 bytes
```

=== 編譯警告

.NET Android SDK 明確輸出：

```text
XA1040: The NativeAOT runtime on Android is an experimental feature
and not yet suitable for production use.
```

這表示即使最小模板能夠編譯和啓動，Android NativeAOT 仍不是 .NET Android 官方承諾的穩定生產功能。

ILC 還輸出：

```text
Mono.Android.dll : warning IL3053:
Assembly 'Mono.Android' produced AOT analysis warnings.
```

具體包括：

```text
Android.Runtime.RuntimeNativeMethods.monodroid_unhandled_exception(Exception)
will always throw because: Invalid IL or CLR metadata

Android.Runtime.RuntimeNativeMethods.monodroid_debugger_unhandled_exception(Exception)
will always throw because: Invalid IL or CLR metadata
```

它們沒有阻止本次 APK 生成和正常進程啓動，但表明 NativeAOT 的未處理異常橋接仍有風險。正式採用前需要專門測試 managed 未捕獲異常的行爲。

== 真機安裝

首先確認設備：

```powershell
& 'D:\ENV\Android\Sdk\platform-tools\adb.exe' devices -l
```

結果：

```text
899PKZQWJ7VCBEWK device product:pearl model:23054RA19C
```

安裝時由 Windows adb 直接讀取 WSL 文件：

```powershell
& 'D:\ENV\Android\Sdk\platform-tools\adb.exe' install -r `
  '\\wsl.localhost\Ubuntu-20.04\home\tsinswreng\avalonia12-nativeaot-test-artifacts\publish\Avalonia12AotTest.Android\release_android-arm64\com.CompanyName.Avalonia12AotTest-Signed.apk'
```

結果：

```text
Performing Streamed Install
Success
```

本次測試 package 與 Ngaq 不同，所以沒有遇到 Ngaq CoreCLR APK 與 NativeAOT APK 簽名不一致的覆蓋安裝錯誤。

== 真機啓動與日誌

=== 啓動流程

測試前先停止應用並清空 logcat：

```powershell
$adb = 'D:\ENV\Android\Sdk\platform-tools\adb.exe'
$pkg = 'com.CompanyName.Avalonia12AotTest'

& $adb shell am force-stop $pkg
& $adb logcat -c
& $adb shell monkey -p $pkg -c android.intent.category.LAUNCHER 1
```

啓動後等待約 8 秒，再檢查：

- package 對應進程是否仍存在。
- Activity 是否是 `ResumedActivity`。
- 應用是否是 `mFocusedApp`。
- logcat 是否出現 managed exception、Android fatal exception 或 native fatal signal。
- 是否重現 Avalonia 11 的 Reflection.Emit 調用鏈。

=== NativeAOT runtime 載入證據

進程專屬 logcat 包含：

```text
NativeAotRuntimeProvider: NativeAotRuntimeProvider()
NativeAotRuntimeProvider.attachInfo(): calling JavaInteropRuntime.init()
JavaInteropRuntime: Loading Avalonia12AotTest.Android.so...
JavaInteropRuntime: JNI_OnLoad()
NativeAotRuntimeProvider: NativeAotRuntimeProvider.onCreate()
```

這證明 APK 實際使用的是 NativeAOT runtime，並成功載入 NativeAOT 生成的應用 `.so`，不是意外退回 Mono 或 CoreCLR。

=== 進程與 Activity 狀態

第一次觀察到的應用 PID：

```text
21977
```

喚醒設備後重新啓動，新的 PID：

```text
22285
```

Android Activity Manager 顯示：

```text
ResumedActivity:
com.CompanyName.Avalonia12AotTest/crc644ff725c7da6d39db.MainActivity

mFocusedApp:
com.CompanyName.Avalonia12AotTest/crc644ff725c7da6d39db.MainActivity
```

因此它不只是後臺殘留進程，而是已進入 Android 前臺 Activity 生命週期。

=== Surface 與 frame 證據

啓動後日誌包含：

```text
BufferQueueConsumer: connect: controlledByApp=false
VRI[MainActivity]: vri.reportNextDraw
SurfaceView: UPDATE Surface(...MainActivity...)
BLASTBufferQueue: acquireNextBufferLocked size=1080x2460 mFrameNumber=1
VRI[MainActivity]: vri.reportDrawFinished
```

這說明 Android window、SurfaceView 和 buffer queue 已建立，並至少完成了 Android window 的首幀提交。

需要注意：Android window 首幀提交不能單獨證明 Avalonia 控件內容完全正確，只能證明它不再像 Avalonia 11 那樣在建立 `AvaloniaView` 時立即拋出 Reflection.Emit 異常。

=== 沒有重現的錯誤

本次 Avalonia 12.1.0 真機日誌中沒有找到：

```text
PlatformNotSupported_ReflectionEmit
System.Reflection.Emit.ReflectionEmitThrower
Android.Runtime.JNINativeWrapper.CreateDelegate
ExploreByTouchHelper.GetGetVirtualViewAt_FFHandler
AvaloniaAccessHelper..ctor exception
FATAL EXCEPTION
Fatal signal
propagateUncaughtException
```

這是本次最重要的差異。

== 可見 UI 驗證的限制

模板正常情況下應顯示一個居中的 TextBox，其內容由 ViewModel 提供：

```text
Welcome to Avalonia!
```

第一次截圖是純黑。後續 Activity dump 顯示當時設備：

```text
isSleeping=true
```

因此純黑截圖不能作爲 Avalonia 黑屏的證據，它首先可能只是手機螢幕已熄滅。

之後使用：

```powershell
adb shell input keyevent KEYCODE_WAKEUP
adb shell wm dismiss-keyguard
```

設備電源狀態變爲：

```text
mWakefulness=Awake
```

但手機使用 PIN 鎖屏。`wm dismiss-keyguard` 不能繞過使用者 PIN，`uiautomator dump` 最終看到的是 Android SystemUI 的 PIN 輸入畫面：

```text
請用數字密碼或指紋解鎖
```

所以本次尚未完成以下驗證：

- `Welcome to Avalonia!` 是否肉眼可見。
- Avalonia TextBox 是否可獲得焦點。
- 軟鍵盤是否可彈出。
- 文本輸入是否正常。
- accessibility node 是否能讀到 Avalonia TextBox。
- Activity pause/resume 後畫面是否仍正常。

這是設備外部狀態造成的驗證缺口，不是已確認的 Avalonia 12 故障。

== Avalonia 11 與 12 的關鍵差異

=== Avalonia 12 仍使用 ExploreByTouchHelper

Avalonia 12.1.0 官方源碼中的：

```text
src/Android/Avalonia.Android/AvaloniaAccessHelper.cs
```

仍然是：

```csharp
internal class AvaloniaAccessHelper : ExploreByTouchHelper
```

構造函數仍調用基類：

```csharp
public AvaloniaAccessHelper(AvaloniaView view) : base(view)
```

官方源碼：

#link("https://github.com/AvaloniaUI/Avalonia/blob/12.1.0/src/Android/Avalonia.Android/AvaloniaAccessHelper.cs")[Avalonia 12.1.0 AvaloniaAccessHelper.cs]

所以「Avalonia 12 不崩潰」不能解釋爲 Avalonia 移除了 `ExploreByTouchHelper` 或關閉了 accessibility。

=== AndroidX binding 版本已更新

版本對比：

#table(
  columns: (auto, auto, auto),
  inset: 6pt,
  stroke: 0.5pt,
  [套件], [Ngaq / Avalonia 11], [Avalonia 12.1 測試],
  [`Avalonia.Android`], [`11.3.8`], [`12.1.0`],
  [`Xamarin.AndroidX.CustomView`], [`1.1.0.20`], [`1.2.0.3`],
  [`Xamarin.AndroidX.Core`], [`1.12.0.2`], [`1.17.0.2`],
)

Avalonia 11 的崩潰發生在舊 `Xamarin.AndroidX.CustomView` binding 提供的：

```text
ExploreByTouchHelper.GetGetVirtualViewAt_FFHandler()
```

它在運行時通過 `JNINativeWrapper.CreateDelegate()` 建立 JNI delegate，最終需要 Reflection.Emit。

Avalonia 12 測試仍建立相同的 Java/managed 類型，但新版 binding 加上新版 .NET Android workload 可以完成 JNI 註冊，沒有進入上述 Reflection.Emit 路徑。

目前最符合證據的判斷是：

```text
Avalonia 12 所帶來的新版 AndroidX bindings／生成代碼，
配合 .NET Android 36.1.69 的 NativeAOT Java interop 支援，
解決或繞過了舊 binding 在運行時動態建立 JNI delegate 的問題。
```

這仍是一項基於版本與實際調用結果的因果判斷。若要完全確認具體修復 commit，還需要繼續比對 `Xamarin.AndroidX.CustomView 1.1.0.20` 與 `1.2.0.3` 生成的 marshal/JNI 代碼。

== .NET Android 上游狀態

調查中檢查了與 NativeAOT Java peer、type map 和 marshal methods 相關的 dotnet/android 上游工作。

=== Trimmable Type Map

```text
dotnet/android #10757
Title: [Draft][Proposal] Trimmable Type Map
State: closed
Created: 2026-02-03
Closed: 2026-02-10
```

#link("https://github.com/dotnet/android/pull/10757")[dotnet/android #10757]

=== CoreCLR marshal methods

```text
dotnet/android #10062
Title: [coreclr] Enable R2R builds with marshal methods generation
State: closed
Created: 2025-04-22
Closed: 2026-02-10
```

#link("https://github.com/dotnet/android/issues/10062")[dotnet/android #10062]

這些上游工作說明 .NET Android 的 Java interop、type map、trimming 和預生成 marshal methods 在近期仍持續變動。

即使相關 issue 或 PR 已關閉，SDK 36.1.69 仍輸出 XA1040 experimental 警告，所以不能僅根據 issue closed 就推斷 Android NativeAOT 已成爲穩定功能。

== 對 Ngaq 的意義

=== Avalonia 12 值得作爲下一個獨立驗證方向

本次最小模板已經證明：

- WSL/.NET/Android SDK/NDK 工具鏈可以發佈 Avalonia 12 NativeAOT。
- 同一臺真機可以載入 Avalonia 12 NativeAOT 應用。
- Avalonia 11.3.8 的 accessibility Reflection.Emit 崩潰不是所有 Avalonia Android NativeAOT 版本都必然存在。

因此，升級 Avalonia 12 有實際希望解決 Ngaq 當前的啓動阻塞。

=== 不能直接在現有項目盲目升級

本次沒有修改 Ngaq 的 Avalonia 版本。是否升級需要單獨評估：

- Avalonia 11 到 12 的 API breaking changes。
- `Tsinswreng.AvlnTools`、Avln.Dsl 和自定義控件是否兼容。
- Android、Desktop 等多端項目是否需要同步修改。
- 第三方 Avalonia 套件是否已有 Avalonia 12 兼容版本。
- trimming/AOT warnings 是否增加。
- Ngaq 啓動後是否還會遇到下一個 NativeAOT 不兼容依賴。

最小模板成功只證明「框架最小路徑可行」，不能證明「Ngaq 無需修改即可升級並運行」。

=== 不建議只在 Ngaq 11 中強制覆蓋 AndroidX 版本

從版本對比看，新 `Xamarin.AndroidX.CustomView` 很可能是關鍵因素。但不應未經驗證直接在 Avalonia 11 項目中強制覆蓋到 `1.2.0.3`，原因包括：

- Avalonia 11 編譯時所依賴的 AndroidX API 版本可能不同。
- 強制提升 transitive package 可能產生 binary compatibility 問題。
- Avalonia 12 自身可能還包含配套的 Android 平臺修復。
- 即使能編譯，也需要重新做相同的真機 accessibility 和交互測試。

如果需要判斷最小升級範圍，應另建 Avalonia 11 的獨立測試項目，只提升 AndroidX bindings，再和 Avalonia 12 結果對照；不要直接拿 Ngaq 主項目試錯。

== 建議的後續驗證

=== 完成 Avalonia 12 模板的 UI 冒煙測試

手機解鎖並保持螢幕亮起後，重新執行：

1. 啓動應用。
2. 截圖確認 `Welcome to Avalonia!`。
3. 用 `uiautomator dump` 確認 accessibility tree。
4. 點擊 TextBox 並輸入文字。
5. 按 Home，再切回應用。
6. 鎖屏、解鎖，再切回應用。
7. 再次檢查 logcat 是否有 JNI 或 rendering 異常。

=== 建立 Ngaq 的 Avalonia 12 升級分支或副本

如果決定繼續，不應直接在當前工作樹修改全部套件。較安全的方式是：

- 建立獨立 git branch，或複製一份最小可構建項目。
- 先只處理 Avalonia 12 的編譯兼容問題。
- Desktop/CoreCLR 編譯通過後，再建立 Android CoreCLR APK。
- 確認 Android CoreCLR 正常後，再啓用 NativeAOT。
- NativeAOT 測試仍使用 WSL ext4 的乾淨 artifacts 目錄。

這樣可以把「Avalonia 12 API 升級問題」和「NativeAOT 運行問題」分開定位。

=== Ngaq NativeAOT 功能測試

即使 Ngaq 能進入主界面，仍至少需要驗證：

- 應用配置和依賴注入。
- SQLite 建庫、遷移、查詢和寫入。
- JSON source generation 與 enum converter。
- HTTP/HTTPS 請求。
- 登錄及 cookie/token 保存。
- Avalonia 頁面導航和彈窗。
- 通知權限與通知發送。
- 音頻播放。
- 文件系統和 Android storage 權限。
- 前後臺切換。
- Activity 重建。
- 未捕獲 managed exception 的處理行爲。

== 試驗產物

WSL 測試項目：

```text
/home/tsinswreng/avalonia12-nativeaot-test
```

WSL artifacts：

```text
/home/tsinswreng/avalonia12-nativeaot-test-artifacts
```

發佈日誌：

```text
/home/tsinswreng/avalonia12-nativeaot-publish.log
```

Signed APK：

```text
/home/tsinswreng/avalonia12-nativeaot-test-artifacts/publish/
Avalonia12AotTest.Android/release_android-arm64/
com.CompanyName.Avalonia12AotTest-Signed.apk
```

本次沒有修改：

- `E:\_code\CsNgaq\Ngaq.Frontend\proj\Directory.Packages.props`
- `E:\_code\CsNgaq\Ngaq.Frontend\proj\Ngaq.Android\Ngaq.Android.csproj`
- `E:\_code\CsNgaq\PublishAndroid.sh`

== 最終判斷

Avalonia 12.1.0 對 Android NativeAOT 的實際兼容性明顯好於 Ngaq 當前使用的 Avalonia 11.3.8。

在本次環境中，它已完成：

```text
模板建立
-> NuGet restore
-> trimming
-> NativeAOT code generation
-> Android arm64 native link
-> APK 打包與簽名
-> 真機安裝
-> NativeAOT runtime 載入
-> Activity 進入前臺
-> Surface/首幀建立
```

並且沒有重現 Ngaq/Avalonia 11 的 Reflection.Emit accessibility 崩潰。

因此，若目標是讓 Ngaq Android NativeAOT 真正啓動，Avalonia 12 是一條有實測依據、值得繼續驗證的路線。

但在完成手機解鎖後的可見 UI/交互驗證，以及 Ngaq 全量依賴的 NativeAOT 測試之前，仍應將其視爲實驗方案，而不是已完成的生產遷移方案。
