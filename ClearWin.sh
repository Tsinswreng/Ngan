# #注意 斷點調試旹蜮不珩下ʹ複製流程
# DirRoot=$(pwd)
# DirDebug="./Ngan.Dict.Frontend/proj/Ngan.Dict.Windows/bin/Debug/net10.0/"
# DirWin="./Ngan.Dict.Frontend/proj/Ngan.Dict.Windows/"
# mkdir -p $DirDebug
# cp -r ./Assets/*  $DirDebug
# #勿用此dotnet run --project ./Ngan.Dict.Frontend/proj/Ngan.Dict.Windows 先cd到目標目錄再運行、否則pwd與可執行程序不一致 影響相對路經解析
# cd $DirWin
# dotnet build
# cd ./bin/Debug/net10.0/
# ./Ngan.Dict.Windows.exe
