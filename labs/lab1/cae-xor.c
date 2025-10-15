#include <ctype.h>
#include <getopt.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

static void usage(const char *prog) {
  fprintf(stderr,
          "Usage: %s [-e|-d] [-c <str>] [-x <str>] [-h]\n"
          "  -e           encrypt plain text\n"
          "  -d           decrypt cipher text\n"
          "  -c [str]     encrytion string for ceasar cipher\n"
          "  -x [str]     encrytion string for xor encryption\n"
          "  -h           show this help\n",
          prog);
}

int main(int argc, char *argv[]) {
  int opt;

  while ((opt = getopt(argc, argv, "edc:x:h")) != -1) {
    switch (opt) {
    case 'e':
      break;
    case 'd':
      break;
    case 'c':
        if (optarg == NULL) {
        fprintf(stderr, "option -c requires an argument\n");
        usage(argv[0]);
        return 1;
      }
      for (size_t i = 0; optarg[i] != '\0'; ++i) {
        printf("%c\n", optarg[i]);
      }
      break;
    case 'x':
      printf("optarg = %s\n", optarg);
      break;
    case 'h':
      usage(argv[0]);
      return 0;
    default:
      usage(argv[0]);
      return 1;
    }
  }

  return 0;
}