#let H(Title, Body) = [
	== #Title
	#Body
]

#H[既有代碼重構流程][
	基於原有代碼進行「聲明與實現分離」等重構時，
	不需要先只寫聲明再等待審查；
	可一次完成聲明、實現與編譯驗證。
]

#H[Ngan.Dict Android NativeAOT][
	Avalonia 12.1.0 升級後，應在 WSL 沙箱外執行
	`Ngan.Dict.Frontend/proj/Ngan.Dict.Android/PublishNativeAot.sh`。

	腳本必須傳入專用的 `Ngan.DictAndroidNativeAot=true`，再由
	`Ngan.Dict.Android.csproj` 僅在 Android 主項目內設置 `PublishAot=true`；
	禁止從命令列直接傳入全局 `PublishAot=true`，否則它會傳播到
	netstandard 與源生成器 ProjectReference，觸發 `NETSDK1207`。

	本機已驗證的 WSL 路徑：Android SDK 爲
	`/mnt/d/ENV/Android/Sdk`，NDK r27c 爲
	`/mnt/d/ENV/_wsl/android-ndk-r27c`。
]
