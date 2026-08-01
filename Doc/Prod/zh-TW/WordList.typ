#let N(doc)={

	text(green)[#doc]
}
#let Delimiter = "````"
\<metadata> \
{ \
	"belong": "english" #N[此文本生詞表的語言] \
	,"delimiter": "#Delimiter" #N[每個單詞塊的分隔符] \
} \
</metadata> \

#N[
時間塊。時間塊中的時間以標示該單詞的添加事件、後續計算權重時會用到。
目前只支持下面這樣的ISO 8601格式。
]
[2024-07-27T16:48:19.795+08:00] \
{{ #N[時間塊以雙大括號起始、以反雙大括號結束] \
triumph #N[單詞塊的第一行內容將被視爲詞頭。程序會將(詞頭, 語言)爲單詞的標識、即詞頭與語言相同的單詞將被視爲同一單詞] \
#N[詞頭下面剩下幾行內容將被視爲詞的描述 或說釋義] \
美: [ˈtraɪəmf] \
英: [ˈtraɪʌmf] \
v.	戰胜；成功；打敗 \
n.	巨大成功；重大成就；偉大胜利；喜悅 \
网絡	黛安芬；凱旋；獲得胜利 \
#Delimiter \
jubilation \
美: [ˌdʒubɪˈleɪʃ(ə)n] \
英: [ˌdʒuːbɪˈleɪʃ(ə)n] \
n.	歡騰；歡欣鼓舞；歡慶 \
网絡	慶祝；歡呼；喜悅 \
#N[支持給單詞添加自定義鍵值對 \
格式爲 [[key|value]] \
如下面這個寫法即表示給這個單詞加上`my custom tag` 這個標籤 \
] \
[[tag|my custom tag]] \
//# for more keys, see Ngan.Dict.Core/Word/Models/Po/Kv/ConstPropKey.cs \
#Delimiter \
fervent \
美: [ˈfɜrv(ə)nt] \
英: [ˈfɜː(r)v(ə)nt] \
adj.	熱情的；熱忱的；熱誠的；熱烈的 \
网絡	強烈的；熾熱的；熱心的 \
#Delimiter \
fervid \
美: [ˈfɜrvɪd] \
英: [ˈfɜː(r)vɪd] \
adj.	情感異常強烈的；激昂的；充滿激情的 \
网絡	熱情的；熱烈的；熾熱的 \
 \
}} \
 \
[2024-07-27T21:40:15.717+08:00] \
#N[你也可以在日期下面寫鍵值對、這樣整個時間塊中的單詞都會有這些鍵值對] \
[[source|xxxxxx]] \
{{ \
#N[此單詞詞頭`jubilation`在上個時間塊中已經出現過。 \
如前面所言、詞頭與語言相同的單詞將被視爲同一單詞。 \
所以當用戶將此文本生詞表導入數據庫時、程序會將這個單詞視爲被添加了多次。 \
單詞被添加的次數越多、背單詞時單詞的權重就越高。 \
] \
jubilation \
美: [ˌdʒubɪˈleɪʃ(ə)n] \
英: [ˌdʒuːbɪˈleɪʃ(ə)n] \
n.	歡騰；歡欣鼓舞；歡慶 \
网絡	慶祝；歡呼；喜悅 \
#Delimiter \
clover \
美: [ˈkloʊvər] \
英: [ˈkləʊvə(r)] \
n.	三葉草；車軸草 \
网絡	苜蓿；四葉草；幸運草 \
 \
}} \
 \
[2024-07-28T16:13:25.195+08:00] \
{{ \
crunch time \
英 [ˈkrʌntʃ taɪm]美 [ˈkrʌntʃ taɪm] \
關鍵時刻或關鍵時期（比如在比賽接近結束時），需要采取決定性的行動 \
#Delimiter \
 \
} \

#N[我們可以事先複製粘貼好多個分隔符、再將生詞複製進來。這樣不用每記一個新詞就手動打一次分隔符。] \
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


#N[文本生詞表可以多次導入複用。如您已經將某文本生詞表中的內容導入進程序中了、後續需要新記單詞時 直接在記在舊的文本生詞表後面則可、無需新建一個文件。程序會根據單詞詞頭和時間判斷哪些是新加的、哪些是重複導入的。]
