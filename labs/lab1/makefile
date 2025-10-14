CC = gcc
DEBUG = -g
DEFINES =
CFLAGS = $(DEBUG) -Wall -Wextra -Wshadow -Wunreachable-code -Wredundant-decls \
		-Wmissing-declarations -Wold-style-definition -Wmissing-prototypes \
		-Wdeclaration-after-statement -Wno-return-local-addr -Wunsafe-loop-optimizations \
		-Wuninitialized -Werror $(DEFINES)

PROG1 = main
PROG2 =
PROG3 =
PROG4 =
PROGS = $(PROG1) $(PROG2) $(PROG3) $(PROG4)
INCLUDES =

all: $(PROGS)

$(PROG1): $(PROG1).o
	$(CC) $(CFLAGS) -o $@ $^

$(PROG1).o: $(PROG1).c $(INCLUDES)
	$(CC) $(CFLAGS) -c $<

clean cls:
	rm -f $(PROGS) *.o *~ \#*

tar:
	tar cvfa ${LOGNAME}_lab1.tar.gz *.[ch] [mM]akefil