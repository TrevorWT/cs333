#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <errno.h>
#include <getopt.h>

enum { ASCII_MIN = 32, ASCII_MAX = 126, ASCII_RANGE = 95 };

static size_t cae_pos = 0;  // persists across reads (Caesar key position)
static size_t xor_pos = 0;  // persists across reads (XOR key position)

// mode: +1 for encode (shift forward), -1 for decode (shift backward)
static inline void caesar_apply(unsigned char *buf, ssize_t n,const char *key, int mode) {
    size_t klen = key ? strlen(key) : 0; // if key is NULL, length is 0
    if (klen == 0) return;

    for (ssize_t i = 0; i < n; ++i) {
        unsigned char c = buf[i];
        int shift;
        int off;

        if (c < ASCII_MIN || c > ASCII_MAX) continue; // skip non-printables

        shift = ((unsigned char)key[cae_pos % klen]) - ASCII_MIN;
        off = (int)c - ASCII_MIN;
        off = (off + mode * shift + ASCII_RANGE) % ASCII_RANGE;
        buf[i] = (unsigned char)(ASCII_MIN + off);
        cae_pos++; // advance only when we transformed a printable
    }
}

static inline void xor_apply(unsigned char *buf, ssize_t n, const char *key) {
    size_t klen = key ? strlen(key) : 0; // if key is NULL, length is 0
    if (klen == 0) return;

    for (ssize_t i = 0; i < n; ++i) {
        buf[i] ^= (unsigned char)key[xor_pos % klen];
        xor_pos++; // advance on every byte
    }
}

static void process_stream(const char *cae_key, const char *xor_key, int encode) {
    unsigned char buf[4096];
    ssize_t n;
    ssize_t w;

    while ((n = read(STDIN_FILENO, buf, sizeof buf)) > 0) {
        if (encode == 1) {                 // ENCODE: Caesar -> XOR
            caesar_apply(buf, n, cae_key, +1);
            xor_apply(buf, n, xor_key);
        } else {                      // DECODE: XOR -> Caesar
            xor_apply(buf, n, xor_key);
            caesar_apply(buf, n, cae_key, -1);
        }
        w = write(STDOUT_FILENO, buf, (size_t)n);
        if (w != n) { perror("write"); exit(1); }
    }
    if (n < 0) { perror("read"); exit(1); }
}

static void usage(const char *prog) {
    fprintf(stderr,
        "Usage: %s [-e|-d] [-c CAEKEY] [-x XORKEY]\n"
        "  -e            Encode (Caesar then XOR)\n"
        "  -d            Decode (XOR then Caesar)\n"
        "  -c CAEKEY     Caesar key (printable-ASCII); omit to skip Caesar\n"
        "  -x XORKEY     XOR key (any bytes ok); omit to skip XOR\n"
        "Reads from stdin, writes to stdout.\n", prog);
}

int main(int argc, char **argv) {
    const char *cae_key = NULL;
    const char *xor_key = NULL;
    int encode = 1;   // 1 = encode, 0 = decode

    int opt;
    while ((opt = getopt(argc, argv, "edc:x:h")) != -1) {
        switch (opt) {
            case 'e': encode = 1; break;
            case 'd': encode = 0; break;
            case 'c': cae_key = optarg; break;
            case 'x': xor_key = optarg; break;
            case 'h': usage(argv[0]); return (opt == 'h') ? 0 : 2;
        }
    }

    process_stream(cae_key, xor_key, encode);
    return 0;
}
