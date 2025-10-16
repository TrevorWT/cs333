#include <ctype.h>
#include <getopt.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/stat.h>
#include <fcntl.h>

enum { ASCII_MIN = 32, ASCII_MAX = 126, ASCII_RANGE = 95 };

int main(void) {
    const char *key = "!\"#$";
    int key_len = 0;
    char buf[4096];
    ssize_t n;

    while (key[key_len] != '\0') ++key_len;

    while ((n = read(STDIN_FILENO, buf, sizeof buf)) > 0) {
        for (ssize_t i = 0; i < n; ++i) {
            unsigned char c = (unsigned char)buf[i];
            if (c < ASCII_MIN || c > ASCII_MAX) continue;

            if (c >= ASCII_MIN && c <= ASCII_MAX && key_len > 0) {
                unsigned char kch = (unsigned char)key[i % key_len];
                int shift = (int)kch - ASCII_MIN;
                int off = (int)c - ASCII_MIN;
                off = (off + shift) % ASCII_RANGE;
                buf[i] = (char)(ASCII_MIN + off);
            }
        }
        write(STDOUT_FILENO, buf, (size_t)n);
    }
    return 0;
}




















 // shift only alphabetic characters
            // if (c >= 'a' && c <= 'z') {
            //     c = 'a' + ((c - 'a' + shift) % 26);
            // } else if (c >= 'A' && c <= 'Z') {
            //     c = 'A' + ((c - 'A' + shift) % 26);
            // }



            // if (c >= 'a' && c <= 'z') {
            //     c = 'z' - (('z' - c + (shift % 26)) % 26);
            // } else if (c >= 'A' && c <= 'Z') {
            //     c = 'Z' - (('Z' - c + (shift % 26)) % 26);
            // }