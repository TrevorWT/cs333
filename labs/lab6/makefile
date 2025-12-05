CC = gcc
CFLAGS = -Wall -Wshadow -Wunreachable-code -Wredundant-decls -Wmissing-declarations -Wold-style-definition -Wmissing-prototypes -Wdeclaration-after-statement -Werror -Wno-return-local-addr -Wunsafe-loop-optimizations -Wuninitialized

TARGETS = rockem_server rockem_client
OBJS_SERVER = rockem_server.o
OBJS_CLIENT = rockem_client.o

all: $(TARGETS)

rockem_server: $(OBJS_SERVER)
	$(CC) $(CFLAGS) -o rockem_server $(OBJS_SERVER) -lpthread

rockem_client: $(OBJS_CLIENT)
	$(CC) $(CFLAGS) -o rockem_client $(OBJS_CLIENT) -lpthread

rockem_server.o: rockem_server.c rockem_hdr.h
	$(CC) $(CFLAGS) -c rockem_server.c

rockem_client.o: rockem_client.c rockem_hdr.h
	$(CC) $(CFLAGS) -c rockem_client.c

clean:
	rm -f $(TARGETS) $(OBJS_SERVER) $(OBJS_CLIENT) *~
