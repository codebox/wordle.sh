import string, functools

with open('words.txt', 'r') as f:
    counts=dict.fromkeys(string.ascii_lowercase, 0)
    for line in f.readlines():
        for c in list(line.strip()):
            counts[c] += 1

def score_word(word):
    return functools.reduce(lambda a,c: a+counts[c], set(list(word)), 0)

words_with_scores=[]
with open('words.txt', 'r') as f:
    for line in f.readlines():
        word = line.strip()
        words_with_scores.append((word, score_word(word)))

words_with_scores.sort(key=lambda t: t[1])
for word in words_with_scores:
	print(word[0])