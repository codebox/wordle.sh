# wordle.sh

The UNIX command-line has a number of tools, such as `grep` and `awk`, that are great at reading text files and finding lines that match a set of criteria.
Solving the word game [Wordle](https://www.nytimes.com/games/wordle/index.html) involves
exactly this process - using the [list of valid words](https://raw.githubusercontent.com/codebox/wordle.sh/main/words/words.txt),
find the one that matches a set of clues.

For example, let's say you guessed that the word was `CRATE` and Wordle gave you the following clues:

<img src="https://codebox.net/assets/images/wordle/word_crate.png" alt="Wordle clues for the word CRATE" width="200">

The grey tiles mean that the letter does not appear in the word, the yellow tile means that the letter is in the word but in a different position,
and the green tile means that the letter is in the correct place. So we know:

* `C`,`A`, `T` and don't appear anywhere in the word
* The second letter is `R`
* There is an `E` somewhere in the word, but it's not the 5th letter

All 3 of these statements can be expressed quite easily using grep:

```
> cat words.txt | grep -v c | grep -v a | grep -v t | grep .r... | grep e | grep '....[^e]'
pries
fryer
greek
brier
...
```

These filters reduce the word list down from 12,971 to just 105. By using the reduced list to choose the next
word, and then adding further grep commands to the list of filters, we can quickly arrive at an answer.

One complication arises due to the way that Wordle handles duplicate letters in guesses. For example, if the
target word is `OLDIE` and we guess `BOOST` we will get the following tiles:

<img src="https://codebox.net/assets/images/wordle/word_boost.png" alt="Wordle clues for the word BOOST" width="200">

Because the target word only has one `O` in it, only one of the `O`s in our guess is coloured yellow, the other is grey.
This extra information is useful, but it means that when transforming tile colours into grep expressions we can no longer
consider the 5 tiles individually as we did in the previous example (doing so would result in the 3rd tile producing a
grep expression of `grep -v o` and excluding any words containing the letter `O`). Instead we must consider
each unique letter rather than each tile, so in this example we would create 4 sets of expressions one for each of the
letters `B`,`O`,`S`, and `T`.

The clues provided by Wordle give us 2 pieces of information about each letter - positional information indicating
where it appears in the word, and also information about how many times the letter appears.

### How many times the letter appears
The number of times a letter appears in the target word is fairly simple to derive: just add together the number of yellow
and green tiles for that letter. If there are also some grey tiles for that letter then we know the 'yellow + green' total
is the exact number, otherwise it is a lower bound. For example, let's say we have the following tiles:

<img src="https://codebox.net/assets/images/wordle/word_greek.png" alt="Wordle clues for the word GREEK" width="200">

We only have one `R` in our guess and it was coloured yellow, so we know there is at least one `R` in the target word,
but there might be more - for example the words `RIVER` and `RISER` would both match this set of clues. In our grep commands we can
express this using the repetition operator `{1,}` which means '1 or more matches'.

We have 2 `E`s in our guess, but one of them was coloured grey. If there were 2 `E`s in the target word then both
of them would have been coloured yellow or green, but that isn't the case here, so we know there is only one `E` in
the word. We can express this using the operator `{1}` which means 'exactly 1 match'.

### Where the letter appears
Creating positional expressions for each letter is also quite easy, we can just replace each letter in our guess with
an expression that either matches that letter (if the tile was green) or does not match that letter (if the tile was
grey or yellow). In our `GREEK` example above we know that:

* The first letter is not `G`
* The second letter is not `R`
* The third letter is not `E`
* The fourth letter is `E`
* The fifth letter is not `K`

These statements can be translated into the grep expression: `[^g][^r][^e]e[^k]`

By combining these 2 types of filters together we can fully utilise the information that Wordle gives us in its clues,
and remove as many non-matching words from the list as possible on each attempt.

### wordle.sh
I have implemented the algorithm described above in [this shell script](https://github.com/codebox/wordle.sh/blob/main/wordle.sh).
I ended up using `awk` rather than `grep` to do the filtering, because that made it easier to string multiple filtering operations together in
a single command. The script automatically downloads [a Wordle word list](https://raw.githubusercontent.com/codebox/wordle.sh/main/words/words.txt) the
first time you use it.

To use the script, run it with one command-line argument for each guess you have made in your game of Wordle. The arguments should be of the
form `<word>,<clues>` where `word` is the 5-letter word that you guessed, and `clues` contains
the colours of the tiles displayed by Wordle for that word. The tile colours are represented by the letters `b` for black (or grey), `y` for yellow
and `g` for green. By default the script will show you up to 10 words that match the clues provided, however this number can be changed using the optional
`--count` parameter.

For example:
```
bash# ./wordle.sh crane,byybb
LARIS LIRAS RAILS RATOS ROTAS SORTA TAROS TORAS SOLAR SORAL
[508 matches found in total]

bash# ./wordle.sh crane,byybb rails,yybbb
AMOUR KORAT ABORT DOUAR DOURA TORAH AMORT MORAT APORT PORTA
[76 matches found in total]

bash# ./wordle.sh --count=30 crane,byybb rails,yybbb
MOWRA FORAM BORAK FORAY GOBAR AORTA OTTAR TORTA ABHOR YURTA KORMA DOWAR BOYAR OMRAH KOURA MORAY ABORD DOBRA DORBA GOURA AMOUR KORAT ABORT DOUAR DOURA TORAH AMORT MORAT APORT PORTA
[76 matches found in total]

bash# ./wordle.sh crane,byybb rails,yybbb abort,ybyyb
QORMA JORAM DORAD FORAM FORAY KORMA DOWAR OMRAH MORAY DOUAR
[13 matches found in total]
```
