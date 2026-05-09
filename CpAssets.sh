WindowsDirDebug="./Ngaq.Frontend/proj/Ngaq.Windows/bin/Debug/net10.0/"
mkdir -p $WindowsDirDebug
cp -r ./ExternalRsrc/*  $WindowsDirDebug
cp -r ./ExternalRsrc.__Private/*  $WindowsDirDebug

DirLinuxDebug="./Ngaq.Frontend/proj/Ngaq.Linux/bin/Debug/net10.0/"
mkdir -p $DirLinuxDebug
cp -r ./ExternalRsrc/*  $DirLinuxDebug
cp -r ./ExternalRsrc.__Private/*  $DirLinuxDebug

DirLinuxPublish="./Ngaq.Frontend/proj/Ngaq.Linux/bin/Release/net10.0//linux-x64/publish/"
mkdir -p $DirLinuxPublish
cp -r ./ExternalRsrc/*  $DirLinuxPublish
cp -r ./ExternalRsrc.__Private/*  $DirLinuxPublish


DirWinPublish=./Ngaq.Frontend/proj/Ngaq.Windows/bin/Release/net10.0/win-x64/publish
mkdir -p $DirWinPublish
cp -r ./ExternalRsrc/*  $DirWinPublish

DirAndroidAssets=./Ngaq.Frontend/proj/Ngaq.Android/Assets
mkdir -p $DirAndroidAssets
cp -r ./ExternalRsrc/*  $DirAndroidAssets


WebDirDebug=./Ngaq.Server/proj/Ngaq.Server.Http/bin/Debug/net10.0/
mkdir -p $WebDirDebug
cp -r ./Ngaq.Server/ExternalRsrc/*  $WebDirDebug
