#let N(doc)={
	text(green)[#doc]
}
#let Delimiter = "````"
\<metadata> \
{ \
	"belong": "english" #N[The language of this vocabulary list] \
	,"delimiter": "#Delimiter" #N[Delimiter for each word block] \
} \
</metadata> \

#N[
Time block. The time in a time block marks the addition event of the words, and is also used later for weight calculation.
Only ISO 8601 format as shown below is supported.
]
[2024-07-27T16:48:19.795+08:00] \
{{ #N[A time block starts with double braces and ends with reverse double braces] \
triumph #N[The first line of a word block is treated as the headword. The program uses (headword, language) as the word's identifier – words with the same headword and language are considered the same word] \
#N[The remaining lines after the headword are treated as the word's description or definition] \
US: [ˈtraɪəmf] \
UK: [ˈtraɪʌmf] \
v.	to defeat; to succeed; to triumph over \
n.	a great success; a major achievement; a great victory; joy \
Internet	Diane Fen; Triumph (brand); to achieve victory \
#Delimiter \
jubilation \
US: [ˌdʒubɪˈleɪʃ(ə)n] \
UK: [ˌdʒuːbɪˈleɪʃ(ə)n] \
n.	great joy; jubilant celebration; exultation \
Internet	celebration; cheering; delight \
#N[Custom key-value pairs can be added to a word.
Format: [[key|value]]
For example, the line below adds the tag 'my custom tag' to this word] \
[[tag|my custom tag]] \
//# for more keys, see Ngan.Dict.Core/Word/Models/Po/Kv/ConstPropKey.cs \
#Delimiter \
fervent \
US: [ˈfɜrv(ə)nt] \
UK: [ˈfɜː(r)v(ə)nt] \
adj.	passionate; ardent; zealous; heartfelt \
Internet	intense; fervid; enthusiastic \
#Delimiter \
fervid \
US: [ˈfɜrvɪd] \
UK: [ˈfɜː(r)vɪd] \
adj.	intensely emotional; impassioned; full of fervor \
Internet	passionate; fervent; fiery \
 \
}} \
 \
[2024-07-27T21:40:15.717+08:00] \
#N[You can also write key-value pairs below the date; all words in this time block will then inherit these key-value pairs] \
[[source|xxxxxx]] \
{{ \
#N[The headword `jubilation` already appeared in the previous time block.
As mentioned earlier, words with the same headword and language are considered the same word.
Therefore, when the user imports this vocabulary list into the database, the program will treat this word as having been added multiple times.
The more times a word is added, the higher its weight will be when studying.] \
jubilation \
US: [ˌdʒubɪˈleɪʃ(ə)n] \
UK: [ˌdʒuːbɪˈleɪʃ(ə)n] \
n.	great joy; jubilant celebration; exultation \
Internet	celebration; cheering; delight \
#Delimiter \
clover \
US: [ˈkloʊvər] \
UK: [ˈkləʊvə(r)] \
n.	clover; trefoil \
Internet	shamrock; four‑leaf clover; lucky plant \
 \
}} \
 \
[2024-07-28T16:13:25.195+08:00] \
{{ \
crunch time \
UK [ˈkrʌntʃ taɪm] US [ˈkrʌntʃ taɪm] \
a critical moment or critical period (e.g., near the end of a game) when decisive action needs to be taken \
#Delimiter \
 \
} \

#N[You can copy multiple delimiters in advance and then paste new words in. This way you don't have to type a delimiter manually for each new word.] \
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


#N[A text‑based vocabulary list can be reused across multiple imports. If you have already imported a word list into the program and later want to add new words, you can simply append them to the same file – no need to create a new one. The program will determine which words are new and which are duplicate imports based on the headword and timestamp.]
