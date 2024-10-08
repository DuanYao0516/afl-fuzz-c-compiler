import os
import random

fileNames = os.listdir(r'./testsuite')
sum = len(fileNames)
correct = 0.0
miss = 0

def writeLog():
    with open('testLog.txt', 'a') as tf:
                tf.write(file + '\n')
                tf.close()

for file in fileNames:
    openFile = "./testsuite/" + file
    with open(openFile, 'r') as f:  
        corpus = f.read()
        f.close()

    corpusLen = len(corpus)
    command = "./lexer < ./testsuite/" + file + " > output.txt " + \
        str(random.randint(0, corpusLen-1)) + ' ' +  str(0)
    os.system(command)
    with open('output.txt', 'r') as f:
        allcontent = f.read()
        if('asdfghjkl' in allcontent):
            miss += 1
            correct += 1
            # writeLog()
            f.close()
            continue
        f.seek(0)
        content = f.readlines()
        try:
            pos = content[1][5:-1]
            origin = content[2][8:-1]
        except IndexError:
            f.close()
            miss += 1
            writeLog()
            continue
        f.close()

    # print(pos, origin)
    pos = int(pos)
    originLen = len(origin)
    actualStr = corpus[pos:pos+originLen].lstrip().rstrip()
    # print(actualStr)
    # print(actualStr == origin)
    if(origin == actualStr):
        correct += 1
        
# print('ACC: %d' % (correct / sum * 100))
print('miss: {}'.format(miss))
print('ACC: {}%'.format(correct / sum * 100))