#import "@preview/tsinswreng-auto-heading:0.1.0": auto-heading
#let H = auto-heading;

數據傳輸對象 規範

#H[Req][
作入參的 命名前綴爲 Req、 需要實現 IReq接口

文件放置在 `<MyDomain>/Models/Req/`下

例
```cs
namespace Ngan.Dict.Core.Shared.User.Models.Req;
using Ngan.Dict.Core.Shared.Base.Models.Req;
public partial class ReqAddUser: IReq{
	public str? UniqName{get;set;} = "";
	public str Email{get;set;} = "";
	public str Password{get;set;} = "";
}

```
]

#H[Resp][
返回的 命名前綴爲 Resp、 需要實現 IResp接口

]
