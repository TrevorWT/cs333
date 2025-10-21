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
  const char *cae_key = "";
  int cae_key_len = 0;
  int mode = 1; // 1 - encrypt, -1 - decrypt
  char buf[4096];
  ssize_t n;

  while ((opt = getopt(argc, argv, "edc:x:h")) != -1) {
    switch (opt) {
    case 'e':
      mode = 1;
      break;
    case 'd':
      mode = -1;
      break;
    case 'c':
      cae_key = optarg;
      break;
    case 'x':
      break;
    case 'h':
      return 0;
    default:
      return 1;
    }
  }

  while (cae_key[cae_key_len] != '\0')
    ++cae_key_len;

  while ((n = read(STDIN_FILENO, buf, sizeof buf)) > 0) {
    unsigned char key_char;
    int shift, offset;
    int key_pos = 0;

    for (ssize_t i = 0; i < n; ++i) {
      unsigned char c = (unsigned char)buf[i];

      if (c < ASCII_MIN || c > ASCII_MAX || cae_key_len == 0){
        key_pos = 0;
        continue;
    }

      key_char = (unsigned char)cae_key[key_pos % cae_key_len];
      key_pos++;
      shift = (int)key_char - ASCII_MIN;
      offset = (int)c - ASCII_MIN;
      offset = (offset + mode * shift + ASCII_RANGE) % ASCII_RANGE;
      buf[i] = (char)(ASCII_MIN + offset);
    }
    write(STDOUT_FILENO, buf, (size_t)n);

  }
  return 0;
}
