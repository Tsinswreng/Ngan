# TODO 打包語言翻譯json文件
#CpAssets="$PWD/CpAssets.sh"
cd Ngan.Dict.Frontend/proj/Ngan.Dict.Windows
mkdir -p publish
mv publish publishOld
dotnet publish -c Release -r win-x64 -p:AllowMissingPrunePackageData=true
rm -r publishOld

#sh $CpAssets
cd ../../../
sh ./CpAssets.sh
cd Ngan.Dict.Frontend/proj/Ngan.Dict.Windows

cd ./bin/Release/net10.0/win-x64
mkdir -p publishNoPdb
rm -r publishNoPdb
cp -r publish publishNoPdb
cd publishNoPdb
rm -r *.pdb
tar -czf ../Ngan.Dict.Windows.tar.gz .
cd ..
mv Ngan.Dict.Windows.tar.gz publishNoPdb/
