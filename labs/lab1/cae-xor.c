#include <ctype.h>
#include <getopt.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

static void usage(const char *prog) {
  fprintf(stderr,
          "Usage: %s [-u] [-m message]\n"
          "  -e           encrypt plain text\n"
          "  -d           decrypt cipher text\n"
          "  -c [str]     encrytion string for ceasar cipher\n"
          "  -x [str]     encrytion string for xor encryption\n"
          "  -h           show this help\n",
          prog);
}

int main(int argc, char *argv[]) {
  int opt;
  const char *msg = "Hello, world";
  int uppercase = 0;

  while ((opt = getopt(argc, argv, "m:uh")) != -1) {
    switch (opt) {
    case 'm':
      msg = optarg;
      break;
    case 'u':
      uppercase = 1;
      break;
    case 'h':
      usage(argv[0]);
      return 0;
    default:
      usage(argv[0]);
      return 1;
    }
  }

  if (uppercase) {
    char *buf = strdup(msg);
    if (!buf) {
      perror("strdup");
      return 1;
    }
    for (char *p = buf; *p; ++p)
      *p = (char)toupper((unsigned char)*p);
    printf("%s\n", buf);
    free(buf);
  } else {
    printf("%s\n", msg);
  }

  return 0;
}
