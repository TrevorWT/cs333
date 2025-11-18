#include <stdio.h>
#include <stdlib.h>
#include <getopt.h>

int main(int argc, char **argv) {
    char *infile = NULL;
    char *dictfile = NULL;
    int opt;

    while ((opt = getopt(argc, argv, "i:d:")) != -1) {
        if (opt == 'i') infile = optarg;
        else if (opt == 'd') dictfile = optarg;
    }

    return 0;
}