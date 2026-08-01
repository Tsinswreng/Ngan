#let N(doc)={

	text(green)[#doc]
}
#let Delimiter = "````"
\<metadata> \
{ \
	"belong": "english" #N[此文本生词表的语言] \
	,"delimiter": "#Delimiter" #N[每个单词块的分隔符] \
} \
</metadata> \

#N[
时间块。时间块中的时间以标示该单词的添加事件、后续计算权重时会用到。
目前只支持下面这样的ISO 8601格式。
]
[2024-07-27T16:48:19.795+08:00] \
{{ #N[时间块以双大括号起始、以反双大括号结束] \
triumph #N[单词块的第一行内容将被视为词头。程序会将(词头, 语言)为单词的标识、即词头与语言相同的单词将被视为同一单词] \
#N[词头下面剩下几行内容将被视为词的描述 或说释义] \
美: [ˈtraɪəmf] \
英: [ˈtraɪʌmf] \
v.	战胜；成功；打败 \
n.	巨大成功；重大成就；伟大胜利；喜悦 \
网络	黛安芬；凯旋；获得胜利 \
#Delimiter \
jubilation \
美: [ˌdʒubɪˈleɪʃ(ə)n] \
英: [ˌdʒuːbɪˈleɪʃ(ə)n] \
n.	欢腾；欢欣鼓舞；欢庆 \
网络	庆祝；欢呼；喜悦 \
#N[支持给单词添加自定义键值对 \
格式为 [[key|value]] \
如下面这个写法即表示给这个单词加上`my custom tag` 这个标签 \
] \
[[tag|my custom tag]] \
//# for more keys, see Ngan.Dict.Core/Word/Models/Po/Kv/ConstPropKey.cs \
#Delimiter \
fervent \
美: [ˈfɜrv(ə)nt] \
英: [ˈfɜː(r)v(ə)nt] \
adj.	热情的；热忱的；热诚的；热烈的 \
网络	强烈的；炽热的；热心的 \
#Delimiter \
fervid \
美: [ˈfɜrvɪd] \
英: [ˈfɜː(r)vɪd] \
adj.	情感异常强烈的；激昂的；充满激情的 \
网络	热情的；热烈的；炽热的 \
 \
 \
[2024-07-27T21:40:15.717+08:00] \
#N[你也可以在日期下面写键值对、这样整个时间块中的单词都会有这些键值对] \
[[source|xxxxxx]] \
{{ \
#N[此单词词头`jubilation`在上个时间块中已经出现过。 \
如前面所言、词头与语言相同的单词将被视为同一单词。 \
所以当用户将此文本生词表导入数据库时、程序会将这个单词视为被添加了多次。 \
单词被添加的次数越多、背单词时单词的权重就越高。 \
] \
jubilation \
美: [ˌdʒubɪˈleɪʃ(ə)n] \
英: [ˌdʒuːbɪˈleɪʃ(ə)n] \
n.	欢腾；欢欣鼓舞；欢庆 \
网络	庆祝；欢呼；喜悦 \
#Delimiter \
clover \
美: [ˈkloʊvər] \
英: [ˈkləʊvə(r)] \
n.	三叶草；车轴草 \
网络	苜蓿；四叶草；幸运草 \
 \
}} \
 \
[2024-07-28T16:13:25.195+08:00] \
{{ \
crunch time \
英 [ˈkrʌntʃ taɪm]美 [ˈkrʌntʃ taɪm] \
关键时刻或关键时期（比如在比赛接近结束时），需要采取决定性的行动 \
#Delimiter \
 \
} \

#N[我们可以事先复制粘贴好多个分隔符、再将生词复制进来。这样不用每记一个新词就手动打一次分隔符。] \
[2025-09-14T11:15:07.302+08:00] \
{{ \

#Delimiter \

#Delimiter \

#Delimiter \

#Delimiter \

#Delimiter \

#Delimiter \

#Delimiter \

#Delimiter \

#Delimiter \

#Delimiter \

#Delimiter \

#Delimiter \


}} \


#N[文本生词表可以多次导入复用。如您已经将某文本生词表中的内容导入进程序中了、后续需要新记单词时 直接在记在旧的文本生词表后面则可、无需新建一个文件。程序会根据单词词头和时间判断哪些是新加的、哪些是重复导入的。]
