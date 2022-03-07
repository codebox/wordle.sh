import string, functools

with open('words.txt', 'r') as f:
    counts=dict.fromkeys(string.ascii_lowercase, 0)
    for line in f.readlines():
        for c in list(line.strip()):
            counts[c] += 1

def score_word(word):
    functools.reduce(lambda c: counts[c], set(list(word)), 0)

with open('words.txt', 'r') as f:
    for line in f.readlines():
        word = line.strip()
        print(word, score_word(word))