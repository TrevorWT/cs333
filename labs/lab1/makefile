CC = gcc
DEBUG = -g
DEFINES =
CFLAGS = $(DEBUG) -Wall -Wextra -Wshadow -Wunreachable-code -Wredundant-decls \
		-Wmissing-declarations -Wold-style-definition -Wmissing-prototypes \
		-Wdeclaration-after-statement -Wno-return-local-addr -Wunsafe-loop-optimizations \
		-Wuninitialized -Werror $(DEFINES)

PROG1 = cae-xor
PROG2 = mystat
PROG2 = test
PROGS = $(PROG1) $(PROG2) $(PROG3)
INCLUDES =

.PHONY: all clean

all: $(PROGS)

$(PROG1): $(PROG1).o
	$(CC) $(CFLAGS) -o $@ $^

$(PROG1).o: $(PROG1).c $(INCLUDES)
	$(CC) $(CFLAGS) -c $<

$(PROG2): $(PROG2).o
	$(CC) $(CFLAGS) -o $@ $^

$(PROG2).o: $(PROG2).c $(INCLUDES)
	$(CC) $(CFLAGS) -c $<

$(PROG3): $(PROG3).o
	$(CC) $(CFLAGS) -o $@ $^

$(PROG3).o: $(PROG3).c $(INCLUDES)
	$(CC) $(CFLAGS) -c $<




clean:
	rm -f $(PROGS) *.o *~ \#*

tar:
	tar cvfa ${LOGNAME}_lab1.tar.gz *.[ch] [mM]akefil