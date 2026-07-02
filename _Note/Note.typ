//#let Chap()={}
#let Time(doc)={}
= 64進制
#Time[2025-05-05T09:37:46.634+08:00_W19-1]
```
64	16	10	2
0	00	00	000000
1	01	01	000001
2	02	02	000010
3	03	03	000011
4	04	04	000100
5	05	05	000101
6	06	06	000110
7	07	07	000111
8	08	08	001000
9	09	09	001001
A	0A	10	001010
B	0B	11	001011
C	0C	12	001100
D	0D	13	001101
E	0E	14	001110
F	0F	15	001111
G	10	16	010000
H	11	17	010001
I	12	18	010010
J	13	19	010011
K	14	20	010100
L	15	21	010101
M	16	22	010110
N	17	23	010111
O	18	24	011000
P	19	25	011001
Q	1A	26	011010
R	1B	27	011011
S	1C	28	011100
T	1D	29	011101
U	1E	30	011110
V	1F	31	011111
W	20	32	100000
X	21	33	100001
Y	22	34	100010
Z	23	35	100011
a	24	36	100100
b	25	37	100101
c	26	38	100110
d	27	39	100111
e	28	40	101000
f	29	41	101001
g	2A	42	101010
h	2B	43	101011
i	2C	44	101100
j	2D	45	101101
k	2E	46	101110
l	2F	47	101111
m	30	48	110000
n	31	49	110001
o	32	50	110010
p	33	51	110011
q	34	52	110100
r	35	53	110101
s	36	54	110110
t	37	55	110111
u	38	56	111000
v	39	57	111001
w	3A	58	111010
x	3B	59	111011
y	3C	60	111100
z	3D	61	111101
-	3E	62	111110
_	3F	63	111111

```




= 使Efcore僅用于遷移
[2025-05-17T10:57:19.480+08:00_W20-6]
```xml
<ItemGroup>
	<PackageReference
		Include="Microsoft.EntityFrameworkCore.Tasks"
		Version="9.0.0"
		PrivateAssets="all"
		IncludeAssets="runtime; build; native; contentfiles; analyzers; buildtransitive"
	/>
</ItemGroup>
```
不要上面一段。則efcore自定義理則不會干擾AOT編譯而致錯



= ADO.NET sqlite sql參數
[2025-05-18T18:43:53.957+08:00_W20-7]
似必須用`@param` 作命名參數、`?`不支持



=
[2025-05-24T19:15:09.864+08:00_W21-6]
```bash
// adb install --no-streaming ./bin/Debug/net9.0-android/com.Tsinswreng.Ngaq-Signed.apk

// adb push ./bin/Debug/net9.0-android/com.Tsinswreng.Ngaq-Signed.apk /sdcard/_/a.apk
// adb shell pm install /sdcard/_/a.apk


```



= Popup用例
[2025-05-25T10:12:58.966+08:00_W21-7]
```cs
public partial class MainView : UserControl {
	Button Btn = new();
	public MainView() {
		//InitializeComponent();
		//Content = new View_WordCard();
		//Content = new ViewAddWord();
		//Content = new ViewBottomBar();

		var s = new StackPanel();
		Content = s;
		{{
			s.Children.Add(Btn);
			var p = new Popup();
			s.Children.Add(p);
			{
				var o = p;
				o.PlacementTarget = Btn;
				o.Placement = PlacementMode.Bottom;
				o.HorizontalOffset = 10.0;
				o.VerticalOffset = 10.0;
				o.Child = new TextBlock{Text = "Text"};
			}

			{
				var o = Btn;
				o.Content = "123";
				o.Click += (s,e)=>{
					p.IsOpen = ! p.IsOpen;
				};
			}

			p.PlacementTarget = Btn;
			p.IsOpen = true;
			for(var i = 0; i < 10; i++){
				s.Children.Add(new Button{Content = i});
			}

		}}



	}
}

```


=
[2025-07-08T21:08:40.810+08:00_W28-2]




=
[2025-07-09T15:04:11.549+08:00_W28-3]
```bash
docker volume create ngaq-postgres-data
docker run \
	--name ngaq-postgres \
	-e POSTGRES_PASSWORD=Tsinswreng \
	-p 5432:5432 \
	-v ngaq-postgres-data:/var/lib/postgresql/data \
	-d postgres

```

=
[2025-07-12T10:40:20.107+08:00_W28-6]
//docker pull redis
```bash
docker volume create ngaq-redis-data
docker run \
	--name ngaq-redis \
	-p 6379:6379 \
	# Redis 默认数据目录是 /data \
	-v ngaq-redis-data:/data \
	-d redis
```
