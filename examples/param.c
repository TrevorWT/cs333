/* param.c - minimal example for argc/argv and very small option parse */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main(int argc, char **argv) {
  int verbose = 0;
  int num = 1; /* default */

  for (int i = 1; i < argc; ++i) {
    if (strcmp(argv[i], "-v") == 0) {
      verbose++;
    } else if (strcmp(argv[i], "-n") == 0) {
      if (i + 1 < argc) {
        num = atoi(argv[++i]);
      } else {
        fprintf(stderr, "error: -n requires a number\n");
        return 1;
      }
    } else if (strcmp(argv[i], "-h") == 0) {
      printf("Usage: %s [-v] [-n num] [args...]\n", argv[0]);
      return 0;
    } else {
      printf("arg: %s\n", argv[i]);
    }
  }

  printf("verbose = %d\n", verbose);
  printf("num = %d\n", num);

  return 0;
}
