#import "@preview/tsinswreng-auto-heading:0.1.0": auto-heading
#let H = auto-heading;

實體規範

#H[基實體][
見
- `Ngan.Dict.Core/Shared/Base/Models/Po/IPoBase.cs`
- `Ngan.Dict.Core/Shared/Base/Models/Po/PoBase.cs`

]

文件結構:

`<MyDomain>/Models/Po/<MyEntity>/`

在此文件夾下建立兩個文件
- `PoMyEntity.cs`
- `IdMyEntity.cs`

#H[IdMyEntity][
```cs
namespace Ngan.Dict.Core.Shared.MyDomain.Models.Po.MyEntity;

using Ngan.Dict.Core.Model.Consts;
using StronglyTypedIds;

[StronglyTypedId(ConstStrongTypeIdTemplate.UInt128)]//ulid 48位unix毫秒時間戳+80位隨機數
public partial struct IdMyEntity {

}

```
]

#H[PoMyEntity][
```cs
public partial class PoMyEntity
	:PoBaseBizTime // 若不需要 業務上的時間屬性, 則只繼承 PoBase即可
	,I_Id<IdMyEntity>
{
	public IdMyEntity Id { get; set; } = new(); //必須顯式寫`=new()`來初始化! 否則會變0值
	//...其他成員
}
```
]

#H[PoBase][
	Ngan.Dict.Core/Shared/Base/Models/Po/IPoBase.cs
]


#H[IdMyEntity][
API 僞代碼示意
```cs
[StronglyTypedId(ConstStrongTypeIdTemplate.UInt128)]
public record struct IdMyEntity{
	public UInt128 Value { get; set; }
	public u8[] ToByteArr();
	public static readonly IdMyEntity Zero = default; //表示無效值 語義上相當于null
	public IdMyEntity(){
		Value = Ngan.Dict.Core.Tools.ToolId.NewUlidUInt128();
	}
	//64進制(位值制 不是base64!)  編碼 0~9  A~Z a~z -_
	public static IdMyEntity FromLow64Base(string Low64Base);
	public static IdMyEntity FromByteArr(byte[] bytes);
	public static bool TryParse(string? S, out IdMyEntity R){}
}
```
]

#H[字典映射與序列化][
	見 MapEtSerialization.typ
]

#H[常用映射][
	UpperType -> RawType
	- IdMyEntity -> byte[]
	- 枚舉 -> string (默認情況下都映射到字符串、避免數據庫中出現魔法數字 MapEnumToStr)
	- Tempus -> int64
]
