# Simple Makefile for local header.h + libmd
# Usage: make        # build arvik-md4
#        make clean  # remove build artifacts

CC       := gcc
CFLAGS   := -std=c17 -O2 -Wall -Wextra -Wshadow -Wunreachable-code \
            -Wredundant-decls -Wmissing-declarations -Wold-style-definition \
            -Wmissing-prototypes -Wdeclaration-after-statement \
            -Wno-return-local-addr -Wunsafe-loop-optimizations \
            -Wuninitialized -Werror
CPPFLAGS :=            # local header.h is in the same folder
LDFLAGS  :=
LDLIBS   := -lmd       # requires libmd (install: sudo apt install libmd-dev)

# --- build ---
all: arvik-md4

arvik-md4: arvik-md4.o
	$(CC) $(LDFLAGS) $^ $(LDLIBS) -o $@

arvik-md4.o: arvik-md4.c arvik.h

# --- housekeeping ---
.PHONY: all clean
clean:
	rm -f arvik-md4 arvik-md4.o
