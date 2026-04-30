# TODO 打包語言翻譯json文件
#CpAssets="$PWD/CpAssets.sh"
cd Ngaq.Frontend/proj/Ngaq.Linux
mkdir -p publish
mv publish publishOld
dotnet publish -c Release -r linux-x64
rm -r publishOld

#sh $CpAssets
cd ../../../
sh ./CpAssets.sh
cd Ngaq.Frontend/proj/Ngaq.Linux

cd ./bin/Release/net10.0/linux-x64
mkdir -p publishNoPdb
rm -r publishNoPdb
cp -r publish publishNoPdb
cd publishNoPdb
rm -r *.pdb
tar -czf ../Ngaq.Linux.tar.gz .
cd ..
mv Ngaq.Linux.tar.gz publishNoPdb/
