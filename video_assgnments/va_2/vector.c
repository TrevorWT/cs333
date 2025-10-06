// gcc -g -Wall -o vector vector.c
// gcc -g -Wall -DNOISY_DEBUG -o vector vector.c

#include <stdio.h> // printf
#include <stdlib.h> // exit status
#include <unistd.h> // getopt
#include <string.h> // string functions

#define OPTIONS "i:o:vh" // command line arguments: (i)nclude file, (o)utput file, (v)erbode, (h)elp

#ifndef FALSE
#define FALSE 0
#endif // FALSE

#ifndef TRUE
#define TRUE 1
#endif // TRUE

#define BUF_SIZE 50000 // input buffer size (bytes)
#define DELIMITER " ()\n" // input delimiter characters

// NOISY_DEBUG macro
#ifdef NOISY_DEBUG
#define NOISY_DEBUG_PRINT fprintf(stderr, "%s %s %i\n", __FILE__, __func__, __LINE__)
#else // NOISY_DEBUG
#define NOISY_DEBUG_PRINT
#endif// NOISY_DEBUG


// point structure
typedef struct point_s {
    int x;
    int y;
    int value;
} point_t;

static int is_verbose = FALSE; // verbose flag
point_t *read_data(FILE *, int *);
void output_data(FILE *, point_t *, int);
int sort_by_value_asc(const void *, const void *);


int main(int argc, char *argv[]) {
    FILE *ifile = stdin;
    FILE *ofile = stdout;
    int num_elements = 0;
    point_t *vector = NULL;

    {
        int opt = 0;

        NOISY_DEBUG_PRINT;
        while ((opt = getopt(argc, argv, OPTIONS)) != -1) {
            switch (opt) {
            case 'i':
                ifile = fopen(optarg, "r");
                if (ifile == NULL ) {
                    perror("open of input file failed");
                    exit(EXIT_FAILURE);
                }
                break;
            case 'o':
                ofile = fopen(optarg, "w");
                if (ofile == NULL ) {
                    perror("open of output file failed");
                    exit(EXIT_FAILURE);
                }
                break;
            case 'v':
                is_verbose = !is_verbose;
                break;
            case 'h':
                printf("get help");
                exit(EXIT_SUCCESS);
                break;
            default:
                break;
            }
        }
        NOISY_DEBUG_PRINT;
    }

    vector = read_data(ifile, &num_elements);
    NOISY_DEBUG_PRINT;

    if (is_verbose) { fprintf(stderr, "input file processed\n"); }
    output_data(ofile, vector, num_elements);
    NOISY_DEBUG_PRINT;

    if (is_verbose) { fprintf(stderr, "soring by ascending value\n"); }
    qsort(vector, num_elements, sizeof(point_t), sort_by_value_asc);
    NOISY_DEBUG_PRINT;

    fprintf(ofile, "---\n");
    output_data(ofile, vector, num_elements);
    NOISY_DEBUG_PRINT;

    free(vector);
    if (ifile != stdin) { fclose(ifile); }
    if (ofile != stdout) { fclose(ofile); }

    NOISY_DEBUG_PRINT;
    return(EXIT_SUCCESS);
}

point_t *read_data(FILE *ifile, int *num_elements) {
    int ni = 0;
    point_t *vector = NULL;
    char buffer[BUF_SIZE] = {0};

    NOISY_DEBUG_PRINT;
    while(fgets(buffer, BUF_SIZE, ifile) != NULL) {
        char *token = NULL;

        // (0,0,9)(0,1,8)(0,2,7)...
        token = strtok(buffer, DELIMITER);
        while (token) {
            point_t point = {0,0,0};
            int result = 0;

            result = sscanf(token, "%i,%i,%i", &point.x, &point.y, &point.value);
            if (result != 3) {
                fprintf(stderr, "bad parse of input data %i %s\n", result, token);
                exit(EXIT_FAILURE);
            }
            vector = realloc(vector, (ni + 1) * sizeof(point_t));
            vector[ni] = point;
            ++ni;
            token = strtok(NULL, DELIMITER);
        }

    }
    if (is_verbose) { fprintf(stderr, "%i points read from input\n", ni); }

    *num_elements = ni;
    NOISY_DEBUG_PRINT;

    return vector;
}

void output_data(FILE *ofile, point_t *vector, int num_elements) {
    int x = 0;

    NOISY_DEBUG_PRINT;
    for(int i = 0; i < num_elements; ++i) {
        if(vector[i].x != x) { fprintf(ofile, "\n"); }
        fprintf(ofile, "(%i,%i,%i)", vector[i].x, vector[i].y, vector[i].value);
        x = vector[i].x;
    }
    fprintf(ofile, "\n");
    if (is_verbose) { fprintf(stderr, "%i points in output\n", num_elements); }
    NOISY_DEBUG_PRINT;
}

int sort_by_value_asc(const void *v1, const void *v2) {
    point_t *point1 = (point_t *) v1;
    point_t *point2 = (point_t *) v2;

    if (point1->value == point2->value) { return 0; }
    return (point1->value < point2->value ? -1 : 1);
}