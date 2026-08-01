# 始終以腳本所在目錄作爲根目錄，避免從其他目錄調用時相對路徑失效。
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
DIR_LINUX="$SCRIPT_DIR/Ngan.Dict.Frontend/proj/Ngan.Dict.Linux"
DIR_DEBUG="$DIR_LINUX/bin/Debug/net10.0"

# 配置文件中有 LLM Key，不宜置於版本控制文件中，故不自動複製資產。
# "$SCRIPT_DIR/CpAssets.sh"

mkdir -p "$DIR_DEBUG"

# 勿在倉庫根目錄直接 dotnet build，否則可能誤構建整個 solution（會拉上 android workload）。
# 在 Linux 入口項目目錄顯式構建該 csproj。
cd "$DIR_LINUX"
dotnet build "./Ngan.Dict.Linux.csproj" # --verbosity detailed -p:AllowMissingPrunePackageData=true

cd "$DIR_DEBUG"
dotnet ./Ngan.Dict.Linux.dll
# dotnet watch --project ../../../

