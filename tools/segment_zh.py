import sys
import jieba

for line in sys.stdin.readlines():
    line = line.rstrip('\n')
    print(' '.join(jieba.cut(line)))