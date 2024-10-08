CC = gcc
# CFLAGS = -Wall -Wextra -Wpedantic

TARGET = lexer

SRCS = lex.yy.c
TEST = hello.txt
OUTPUT = output.txt
TESTSCRIPT = lexer_test.py

all: $(TARGET)

$(TARGET): $(SRCS)
	$(CC) $(CFLAGS) $^ -o $@

lex.yy.c: lexer.l
	flex $<

clean:
	rm -f $(TARGET) $(SRCS)

run:
	./lexer < $(TEST) > $(OUTPUT)

test:
	python $(TESTSCRIPT)

.PHONY: all clean run test
