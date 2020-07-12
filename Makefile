CC=gcc
CFLAGS=-O -Wall -g -lpthread -lcrypto

all: wfp

wfp: src/external/crc32c/crc32c.c src/winnowing.c 
	 $(CC) $(CFLAGS) -c src/winnowing.c 

clean:
	rm -f *.o

distclean: clean

