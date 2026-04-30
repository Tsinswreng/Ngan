# Client Release

统一客户端发版入口：

```bash
sh ./ReleaseClients.sh --version 1.2.2
```

## 功能

- 同步更新 `Ngaq.Core/Infra/AppVersion.cs`
- 同步更新 `Ngaq.Frontend/proj/Ngaq.Android/Ngaq.Android.csproj`
- 可选执行 `GenI18n.sh`
- 可选执行 `Ngaq.Windows.Test` 的 `Release + win-x64` 发布并运行
- 构建 Windows / Linux / Android 客户端
- 将产物整理到 `artifacts/client/<display-version>/`

## 参数

```bash
sh ./ReleaseClients.sh --version 1.2.2 --platforms win,android
sh ./ReleaseClients.sh --version 1.2.2 --skip-tests
sh ./ReleaseClients.sh --version 1.2.2 --skip-i18n
sh ./ReleaseClients.sh --version 1.2.2 --build-id 261191530
```

参数说明：

- `--version <x.y.z>`：必填，语义化版本号
- `--build-id <yydddHHMM>`：可选，默认取 Asia/Shanghai 当前时间
- `--platforms <list>`：可选，逗号分隔，支持 `win,linux,android`
- `--skip-tests`：跳过测试
- `--skip-i18n`：跳过 i18n 生成
- `--allow-dirty`：允许未提交改动时执行

## 版本规则

- `AppVersion.cs` 中的 `Version` / `CoreVer` 会被写成：`major.minor.patch.buildId`
- Android 的 `ApplicationDisplayVersion` 会被写成：`major.minor.patch.yyddd`
- Android 的 `ApplicationVersion` 会被写成完整 `buildId`

例如：

- `--version 1.2.2`
- 自动生成 `buildId=261191530`

则：

- App 内版本：`1.2.2.261191530`
- Android 显示版本：`1.2.2.26119`

## 产物目录

```text
artifacts/client/<display-version>/
  release-info.txt
  test-runner/
  windows/
  linux/
  android/
```

说明：

- Windows 和 Linux 会额外生成 `.tar.gz`
- Android 会拷贝 `publish` 目录下生成的 `.apk` 或 `.aab`

## 当前取舍

- 首版不会自动 commit
- 首版不会自动打 tag
- 首版不会自动创建 GitHub Release

这样可以先把“改版本、测、构建、收集产物”稳定下来，再接第二步自动 tag / GitHub Actions。
