#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <getopt.h>

static char* readFileToBuffer(FILE *input, size_t *outSize);
static char** splitIntoLines(char *buffer, size_t *lineCount);


static char* readFileToBuffer(FILE *input, size_t *outSize) {
    long length;
    char *buffer;
    size_t n;

    if (!input) return NULL;

    if (fseek(input, 0, SEEK_END) != 0) return NULL;
    length = ftell(input);
    if (length < 0) return NULL;
    if (fseek(input, 0, SEEK_SET) != 0) return NULL;

    buffer = malloc((size_t)length + 1);
    if (!buffer) return NULL;

    n = fread(buffer, 1, (size_t)length, input);
    if (n != (size_t)length && ferror(input)) {
        free(buffer);
        return NULL;
    }

    buffer[n] = '\0';
    if (outSize) *outSize = n;
    return buffer;
}

static char** splitIntoLines(char *buffer, size_t *lineCount) {
    size_t count = 0;
    size_t capacity = 16;
    char** lines = malloc(capacity * sizeof(char*));
    char** temp = NULL;
    char * line = NULL;

    if (!lines) return NULL;

    line = strtok(buffer, "\n");
    while (line != NULL) {
        if (line[0] != '\0') {
            if (count >= capacity) {
                capacity *= 2;
                temp = realloc(lines, capacity * sizeof(char*));
                if (!temp) {
                    free(lines);
                    return NULL;
                }
                lines = temp;
            }
            lines[count++] = line;
        }
        line = strtok(NULL, "\n");
    }

    *lineCount = count;
    return lines;
}

int main(int argc, char **argv) {
    char *hash = NULL;
    char *dict = NULL;
    char *buffer = NULL;
    char **myLines = NULL; // testing
    int opt;
    size_t size;
    size_t count;
    FILE *inputFile = NULL;
    FILE *dictFile = NULL;

    while ((opt = getopt(argc, argv, "i:d:")) != -1) {
        if (opt == 'i') hash = optarg;
        else if (opt == 'd') dict = optarg;
    }

    inputFile = fopen(hash, "r");
    dictFile = fopen(dict, "r");

    if (!inputFile) {
        fprintf(stderr, "Error opening input file: %s\n", hash);
        return 1;
    }

    buffer = readFileToBuffer(inputFile, &size);
    fclose(inputFile);

    printf("Buffer size: %zu bytes\n", size);
    printf("Buffer content:\n%s\n", buffer);

    buffer = readFileToBuffer(dictFile, &size);
    fclose(dictFile);

    printf("Buffer size: %zu bytes\n", size);
    printf("Buffer content:\n%s\n", buffer);


    myLines = splitIntoLines(buffer, &count);
    printf("%s\n", myLines[0]);  // First line
    printf("%s\n", myLines[1]);

    free(buffer);
    free(myLines);
    return 0;


}
