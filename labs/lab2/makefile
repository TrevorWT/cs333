CC=gcc
CFLAGS=-std=c17 -O2 -Wall -Wextra -Wshadow -Wunreachable-code -Wredundant-decls \
       -Wmissing-declarations -Wold-style-definition -Wmissing-prototypes \
       -Wdeclaration-after-statement -Wno-return-local-addr -Wunsafe-loop-optimizations \
       -Wuninitialized -Werror
LDLIBS=-lmd
# add e.g. ARVIK_INC=~rchaney/Classes/cs333/Labs/Lab2
# and then CPPFLAGS+=-I$(ARVIK_INC)

all: arvik-md4
arvik-md4: arvik-md4.o
clean:
	rm -f arvik-md4 arvik-md4.o
