#!/bin/sh
# generates all permutations of the string 'line' (only sigle digit numbers e.g. 123 = 1, 2, 3)
line=$1
python3 -c "from itertools import permutations as p; line = str($line); print('\n'.join([' '.join(item) for item in p(line[:])]))"
