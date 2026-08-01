#dotnet run --project Ngan.Dict.Test
TestDll="Ngan.Dict.Test/bin/Debug/net10.0/Ngan.Dict.Test.dll"
TestDll=$(realpath -m $TestDll)
cd Ngan.Dict.Frontend/proj/Ngan.Dict.Windows/bin/Debug/net10.0
dotnet $TestDll
