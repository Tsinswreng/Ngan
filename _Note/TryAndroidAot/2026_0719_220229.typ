-Sesn[
	-T[2026_0719_220238][
		先看skill。
		看`E:\_code\CsNgan.Dict\Ngan.Dict.Frontend\proj\Ngan.Dict.Android\Ngan.Dict.Android.csproj`
		`E:\_code\CsNgan.Dict\PublishAndroid.sh`
		這個本來不加`<PublishAot>true</PublishAot>`
		在windows上用github執行 `PublishAndroid.sh`就能成功編譯出apk。
		加了PublishAot 就報錯 
		````
		<TEnum> instead.
    ld.lld : error undefined symbol: std::__ndk1::__libcpp_verbose_abort(char const*, ...)
    ld.lld : error undefined symbol: std::__ndk1::to_chars(char*, char*, float, std::__ndk1::chars_format, int)
    ld.lld : error undefined symbol: std::__ndk1::to_chars(char*, char*, float, std::__ndk1::chars_format)
    ld.lld : error undefined symbol: std::__ndk1::to_chars(char*, char*, float)
    ld.lld : error undefined symbol: std::__ndk1::to_chars(char*, char*, double, std::__ndk1::chars_format, int)
    ld.lld : error undefined symbol: std::__ndk1::to_chars(char*, char*, double, std::__ndk1::chars_format)
    ld.lld : error undefined symbol: std::__ndk1::to_chars(char*, char*, double)
    ld.lld : error undefined symbol: std::__ndk1::to_chars(char*, char*, __float128, std::__ndk1::chars_format, int)
    ld.lld : error undefined symbol: std::__ndk1::to_chars(char*, char*, __float128, std::__ndk1::chars_format)
    ld.lld : error undefined symbol: std::__ndk1::to_chars(char*, char*, __float128)
    clang : error linker command failed with exit code 1 (use -v to see invocation)
    C:\Users\lenovo\.nuget\packages\microsoft.dotnet.ilcompiler\10.0.1\build\Microsoft.NETCore.Native.targets(389,5): error MSB3073: 命令“"clang" "obj\Release\net10.0-android\android-x64\native\Ngan.Dict.Android.
		.....
		t10.0-android\android-x64\android\environment.x86_64.o -Wl,--discard-all -Wl,--gc-sections”已退出，代码为 1。
		````
		也可能是因爲我沒切到linux上去編譯、導致不支持的跨平臺編譯。
		你去研究一下、看看PublicAot能不能開起來。
		本機已經裝了wsl ubuntu
	][]
	
	
	-T[2026_0721_194818][
		我試了一下、能成功安裝。
		把apk從wsl移到/mnt/裏的windows目錄再用windows的adb來裝。
		原先我的手機上已經裝了一個coreclr版的 同版本的。此時直接adb install會報錯
````
PS C:\Users\lenovo> adb install "E:\Tsinswreng.Ngan.Dict-Signed.apk"
Performing Streamed Install
adb: failed to install E:\Tsinswreng.Ngan.Dict-Signed.apk: Failure [INSTALL_FAILED_UPDATE_INCOMPATIBLE: Existing package Tsinswreng.Ngan.Dict signatures do not match newer version; ignoring!]
````
	然後我把原來手機上的卸載掉了、再安裝。能安裝成功。但是啓動時就卡在啓動頁面不動了、
	也沒有報無響應啥的、他就是一直卡着不動。
	然後我又卸載了裝回coreclr版的。
	coreclr版 首次安裝 啓動的時候會請求一個通知權限。
	
	以上就是我收集到的信息。
	現在我在手機上把Ngan.Dict卸載了。
	你自己裝一次試試。然後自己看adb的日誌、看看是甚麼原因。
	自己收集信息debug 別亂猜

	][
````md
原因已确定，不是卡住，而是主线程启动时发生致命异常：

```text
System.PlatformNotSupportedException: PlatformNotSupported_ReflectionEmit
```

完整调用链：

```text
Android.Runtime.JNINativeWrapper.CreateDelegate
→ AndroidX.CustomView.Widget.ExploreByTouchHelper
→ Avalonia.Android.AvaloniaAccessHelper
→ Avalonia.Android.AvaloniaView
→ Avalonia.Android.AvaloniaActivity.OnCreate
→ Ngan.Dict.Android.MainActivity.OnCreate
```

具体发生在 [MainActivity.cs](E:\_code\CsNgan.Dict\Ngan.Dict.Frontend\proj\Ngan.Dict.Android\MainActivity.cs:61) 调用 `base.OnCreate()`，Avalonia 创建 Android View 及无障碍辅助对象时。

根因是：

- 项目使用 `Avalonia.Android 11.3.8`，见 [Directory.Packages.props](E:\_code\CsNgan.Dict\Ngan.Dict.Frontend\proj\Directory.Packages.props:25)。
- `AvaloniaAccessHelper` 会创建 AndroidX `ExploreByTouchHelper`。
- AndroidX JNI 绑定需要注册 native callback。
- 当前 NativeAOT 构建没有预生成 marshal methods，因此回退到 `JNINativeWrapper.CreateDelegate()`。
- 该回退使用 `System.Reflection.Emit`，而 NativeAOT 不支持运行时生成代码。

构建属性也已验证：

```text
_AndroidRuntime=NativeAOT
AndroidEnableMarshalMethods=False
_AndroidUseMarshalMethods=False
```

.NET Android SDK 源码明确写着：

```xml
<!-- NOTE: temporarily disable for NativeAOT and CoreCLR for now -->
```

我又实际测试了命令行强制开启：

```text
-p:AndroidEnableMarshalMethods=true
```

但构建失败：

```text
XARMM7009:
required type 'Java.Interop.ManagedMarshalMethodsLookupTable'
in assembly Mono.Android not found
```

所以它不是加一个 MSBuild 属性就能修复的。

其他现象也解释通了：

- 没弹通知权限，是因为程序在 `base.OnCreate()` 内就崩溃了，尚未执行 [MainActivity.cs](E:\_code\CsNgan.Dict\Ngan.Dict.Frontend\proj\Ngan.Dict.Android\MainActivity.cs:62) 的通知初始化。
- 启动页一直保留，是因为 NativeAOT 异常传播又遇到：

```text
No implementation found for mono.android.Runtime.propagateUncaughtException
```

导致 Android 没有正常结束这个 Activity，看起来像永久卡在启动页。
- 之前的签名不一致只因为 CoreCLR APK 和这次 NativeAOT APK 使用了不同 Debug 证书，与启动崩溃无关。

结论：当前 `.NET Android 36.1.69 + Avalonia.Android 11.3.8` 的组合不能直接运行这个 NativeAOT APK。编译成功不代表 Avalonia Android 的 JNI 绑定已兼容 NativeAOT。

可选方向：

1. 查找/升级到已支持 Android NativeAOT marshal methods 的新版 .NET Android SDK 和 Avalonia。
2. 修改或 fork Avalonia Android，NativeAOT 下禁用/替换 `AvaloniaAccessHelper` 无障碍实现。
3. Android 暂时继续使用 CoreCLR，等待上游 NativeAOT 支持成熟。

我没有修改代码。NativeAOT APK 当前仍安装在手机上，进程也仍残留；如需要我可以先卸载，然后继续调查方案 1 或方案 2。另一个需要同步的事项是 [AndroidNativeAotTrial.typ](E:\_code\CsNgan.Dict\_Note\TryAndroidAot\AndroidNativeAotTrial.typ:1) 现在缺少这次真机运行失败的结论。
````
	]
	
	-T[2026_0721_200451][
		那你去查一下 avalonia12支不支持?
		去上網查 或者自己 dotnet new avalonia.xplat的模板來試
		別直接改這個項目的avalonia版本
	][
````md
結論：Avalonia 12.1.0 已經能讓 Android NativeAOT 通過編譯並啓動，避開 Avalonia 11.3.8 的 `Reflection.Emit` 崩潰；但 .NET Android 官方仍將 NativeAOT 樕為 experimental，暫時不能視為正式生產支援。

實測結果：

- 在 WSL 使用 `.NET 10.0.107`、Android workload `36.1.69` 建立獨立 `avalonia.xplat` 項目。
- 使用 Avalonia `12.1.0`、`android-arm64`、`PublishAot=true` 成功產生 Signed APK，約 20.3 MB。
- APK 成功安裝並啓動。
- NativeAOT runtime 載入成功：
  - `NativeAotRuntimeProvider`
  - `Loading Avalonia12AotTest.Android.so`
  - `JNI_OnLoad()`
- Activity 成為前臺 `ResumedActivity`。
- Android Surface 已建立並提交第一幀。
- 進程持續存活。
- 沒有出現 Avalonia 11 的錯誤：
  - `PlatformNotSupported_ReflectionEmit`
  - `JNINativeWrapper.CreateDelegate`
  - `ExploreByTouchHelper`
  - fatal exception

Avalonia 12 仍然使用 `ExploreByTouchHelper`，但 AndroidX binding 已經升級：

- Ngan.Dict/Avalonia 11：`Xamarin.AndroidX.CustomView 1.1.0.20`
- Avalonia 12.1 測試：`Xamarin.AndroidX.CustomView 1.2.0.3`
- Avalonia 12.1 測試：`Xamarin.AndroidX.Core 1.17.0.2`

所以目前證據指向：新版 AndroidX binding/Android workload 已生成 NativeAOT 可用的 JNI marshal 代碼，而不是 Avalonia 12 刪除了 accessibility 功能。

官方 Avalonia 12.1.0 源碼仍繼承 `ExploreByTouchHelper`：

[AvaloniaAccessHelper.cs](https://github.com/AvaloniaUI/Avalonia/blob/12.1.0/src/Android/Avalonia.Android/AvaloniaAccessHelper.cs)

仍有一項未完成驗證：手機現在停在 PIN 鎖屏，adb 無法代替你輸入密碼，所以截圖和 UI hierarchy 都只能看到鎖屏，不能確認 `Welcome to Avalonia!` 是否實際顯示。

請把手機解鎖並保持螢幕亮着，告訴我一聲，我再完成最後的畫面、控件和交互驗證。

現有 Ngan.Dict 項目的 Avalonia 版本沒有修改。
````
	]
	
	-T[2026_0721_202202][
		出一份文檔、寫到這裏來`E:\_code\CsNgan.Dict\_Note\TryAndroidAot\Avln12NativeAot.typ`
	][
		
	]
	
]
