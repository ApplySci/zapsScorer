# -*- coding: utf-8 -*-

words = []
doit=True
with open('wordlist.txt') as f: # 
    while doit:
        a = f.readline()
        if a:
            words.append(a[:-1])
        else:
            doit = False

import pickle
with open('wordlist.pickle', 'wb') as g:
    pickle.dump(words, g, protocol=4)