/* examples/param_getopt.c
 * Concise getopt() example for parsing -v and -n <num>
 */

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

int main(int argc, char *argv[]) {
  int opt;
  int verbose = 0;
  int num = 1;

  while ((opt = getopt(argc, argv, "vn:h")) != -1) {
    switch (opt) {
    case 'v':
      verbose++;
      break;
    case 'n':
      num = atoi(optarg);
      break;
    case 'h':
    default:
      fprintf(stderr, "Usage: %s [-v] [-n num] [args...]\n", argv[0]);
      return (opt == 'h') ? 0 : 1;
    }
  }

  for (int i = optind; i < argc; ++i)
    printf("arg: %s\n", argv[i]);

  printf("verbose = %d\nnum = %d\n", verbose, num);
  return 0;
}
