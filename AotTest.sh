#dotnet run --project Ngan.Dict.Test -c Release -r win-x64
cd ./Ngan.Dict.Test
dotnet publish -c Release -r win-x64
./bin/Release/net10.0/win-x64/publish/Ngan.Dict.Test.exe
