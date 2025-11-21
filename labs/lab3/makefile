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
LDLIBS   := -lmd -lcrypt -pthread  # requires libmd and libcrypt

# --- build ---
all: thread_hash

thread_hash: thread_hash.o
	$(CC) $(LDFLAGS) $^ $(LDLIBS) -o $@

thread_hash.o: thread_hash.c thread_hash.h

# --- housekeeping ---
.PHONY: all clean
clean:
	rm -f thread_hash thread_hash.o
