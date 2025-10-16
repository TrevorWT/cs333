#include <ctype.h>
#include <fcntl.h>
#include <getopt.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <unistd.h>

enum { ASCII_MIN = 32, ASCII_MAX = 126, ASCII_RANGE = 95 };

int main(int argc, char *argv[]) {
  int opt;
  const char *cea_key = "";
  int cea_key_len = 0;
  int mode = 1; // 1 - encrypt, -1 - decrypt
  char buf[4096];
  ssize_t n;

  printf("cea_key = %s\n", cea_key);
  while ((opt = getopt(argc, argv, "edc:x:h")) != -1) {
    switch (opt) {
    case 'e':
      mode = 1;
      break;
    case 'd':
      mode = -1;
      break;
    case 'c':
      cea_key = optarg;
      printf("cea_key = %s\n", cea_key);
      break;
    case 'x':
      break;
    case 'h':
      return 0;
    default:
      return 1;
    }
  }

  while (cea_key[cea_key_len] != '\0')
    ++cea_key_len;

  while ((n = read(STDIN_FILENO, buf, sizeof buf)) > 0) {
    unsigned char kch;
    int shift, off;
    for (ssize_t i = 0; i < n; ++i) {
      unsigned char c = (unsigned char)buf[i];

      if (c < ASCII_MIN || c > ASCII_MAX || cea_key_len == 0)
        continue;

      kch = (unsigned char)cea_key[i % cea_key_len];
      shift = (int)kch - ASCII_MIN;
      off = (int)c - ASCII_MIN;
      off = (off + mode * shift + ASCII_RANGE) % ASCII_RANGE;
      buf[i] = (char)(ASCII_MIN + off);
    }
    write(STDOUT_FILENO, buf, (size_t)n);
  }
  return 0;
}
