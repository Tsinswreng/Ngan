cd Ngan.Dict.Frontend/proj/Ngan.Dict.Android
# 陞級至.net10後不設AllowMissingPrunePackageData則報錯
dotnet publish -c Release -p:AllowMissingPrunePackageData=true
# dotnet build -c Release -p:AllowMissingPrunePackageData=true -t:InstallAndroidDependencies
