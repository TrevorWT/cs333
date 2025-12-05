#define _XOPEN_SOURCE 700
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <getopt.h>
#include <crypt.h>
#include <pthread.h>
#include <time.h>
#include <sys/resource.h>
#include <errno.h>
#include <unistd.h>

typedef struct {
    int threadId;
    char **hashes;
    size_t *currentHash;
    size_t hashCount;
    char **dict;
    size_t dictCount;
    FILE *outFile;
    pthread_mutex_t *outMutex;
    pthread_mutex_t *workMutex;

    double timeSec;
    int total;
    int failed;
    int desCount;
    int ntCount;
    int md5Count;
    int sha256Count;
    int sha512Count;
    int yescryptCount;
    int gostYescryptCount;
    int bcryptCount;
} thread_data_t;

typedef struct {
    pthread_t *threads;
    thread_data_t *threadData;
    char *hashBuffer;
    char *dictBuffer;
    char **hashes;
    char **passwords;
} cleanup_data_t;

static char* readFileToBuffer(FILE *input, size_t *outSize);
static char** splitIntoLines(char *buffer, size_t *lineCount);
static void identifyHashType(const char* hash, thread_data_t* data);
static void cleanup(cleanup_data_t *data);
void* checkPasswords(void* arg);

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

static void identifyHashType(const char* hash, thread_data_t* data) {
    if (strncmp(hash, "$1$", 3) == 0) data->md5Count++;
    else if (strncmp(hash, "$2", 2) == 0 || strncmp(hash, "$2b$", 4) == 0) data->bcryptCount++;
    else if (strncmp(hash, "$5$", 3) == 0) data->sha256Count++;
    else if (strncmp(hash, "$6$", 3) == 0) data->sha512Count++;
    else if (strncmp(hash, "$y$", 3) == 0) data->yescryptCount++;
    else if (strncmp(hash, "$gy$", 4) == 0) data->gostYescryptCount++;
    else if (strlen(hash) == 13) data->desCount++;
    else if (strncmp(hash, "$3$", 3) == 0) data->ntCount++;
}

static void cleanup(cleanup_data_t *data) {
    if (data->threads) free(data->threads);
    if (data->threadData) free(data->threadData);
    if (data->passwords) free(data->passwords);
    if (data->dictBuffer) free(data->dictBuffer);
    if (data->hashes) free(data->hashes);
    if (data->hashBuffer) free(data->hashBuffer);
}

void* checkPasswords(void* arg) {
    thread_data_t* tdata = (thread_data_t*)arg;
    struct crypt_data cryptData;
    char *result = NULL;
    struct timespec start, end;
    size_t myHashIndex;
    char *currentHashStr;
    int wordsHashed;
    int found;

    memset(&cryptData, 0, sizeof(cryptData));
    tdata->total = 0;
    tdata->failed = 0;

    clock_gettime(CLOCK_MONOTONIC, &start);

    /* Dynamic load balancing: each thread grabs the next available hash */
    while (1) {
        pthread_mutex_lock(tdata->workMutex);
        if (*(tdata->currentHash) >= tdata->hashCount) {
            pthread_mutex_unlock(tdata->workMutex);
            break;
        }
        myHashIndex = *(tdata->currentHash);
        (*(tdata->currentHash))++;
        pthread_mutex_unlock(tdata->workMutex);

        currentHashStr = tdata->hashes[myHashIndex];
        identifyHashType(currentHashStr, tdata);
        found = 0;
        wordsHashed = 0;

        /* Try each dictionary word against this hash */
        for (size_t i = 0; i < tdata->dictCount; i++) {
            result = crypt_rn(tdata->dict[i], currentHashStr, &cryptData, sizeof(cryptData));
            wordsHashed++;
            if (result == NULL) {
                continue;
            }
            if (strcmp(result, currentHashStr) == 0) {
                pthread_mutex_lock(tdata->outMutex);
                fprintf(tdata->outFile, "cracked  %s  %s\n", tdata->dict[i], currentHashStr);
                pthread_mutex_unlock(tdata->outMutex);
                found = 1;
                break;
            }
        }

        /* Count this hash as processed */
        tdata->total++;

        if (!found) {
            pthread_mutex_lock(tdata->outMutex);
            fprintf(tdata->outFile, "*** failed to crack  %s\n", currentHashStr);
            pthread_mutex_unlock(tdata->outMutex);
            tdata->failed++;
        }
    }

    clock_gettime(CLOCK_MONOTONIC, &end);
    tdata->timeSec = (end.tv_sec - start.tv_sec) + (end.tv_nsec - start.tv_nsec) / 1e9;

    return NULL;
}

int main(int argc, char **argv) {
    char *hash = NULL;
    char *dict = NULL;
    char *outputFile = NULL;
    char *hashBuffer = NULL;
    char *dictBuffer = NULL;
    char **hashes = NULL;
    char ** passwords = NULL;
    int opt;
    size_t threadCount = 1;
    size_t currHash = 0;
    size_t hashSize, dictSize;
    size_t hashCount, dictCount;
    FILE *hashFile = NULL;
    FILE *dictFile = NULL;
    FILE *outFile = NULL;
    pthread_t *threads;
    thread_data_t *threadData;
    pthread_mutex_t outMutex = PTHREAD_MUTEX_INITIALIZER;
    pthread_mutex_t workMutex = PTHREAD_MUTEX_INITIALIZER;
    cleanup_data_t cleanupData = {0};

    double totalTime = 0;
    int totalDes = 0, totalNt = 0, totalMd5 = 0, totalSha256 = 0;
    int totalSha512 = 0, totalYescrypt = 0, totalGost = 0, totalBcrypt = 0;
    int totalHashes = 0, totalFailed = 0;
    int verbose = 0;

    while ((opt = getopt(argc, argv, "i:o:d:hvt:n")) != -1) {
        if (opt == 'i') hash = optarg;
        else if (opt == 'o') outputFile = optarg;
        else if (opt == 'd') dict = optarg;
        else if (opt == 't') {
            threadCount = atoi(optarg);
            if (threadCount < 1 || threadCount > 120) threadCount = 1;
        }
        else if (opt == 'v') verbose = 1;
        else if (opt == 'n') { int ret = nice(10); (void)ret; }
        else if (opt == 'h') {
            fprintf(stderr, "./thread_hash ...\n");
            fprintf(stderr, "Options: i:o:d:hvt:n\n");
            fprintf(stderr, "        -i file         hash file name (required)\n");
            fprintf(stderr, "        -o file         output file name (default stdout)\n");
            fprintf(stderr, "        -d file         dictionary file name (required)\n");
            fprintf(stderr, "        -t #            number of threads to create (default == 1)\n");
            fprintf(stderr, "        -n              renice to 10\n");
            fprintf(stderr, "        -v              enable verbose mode\n");
            fprintf(stderr, "        -h              helpful text\n");
            return 0;
        }
    }

    if (!dict) {
        fprintf(stderr, "must give name for dictionary input file with -d filename\n");
        return 1;
    } else if (!hash) {
        fprintf(stderr, "must give name for hashed password input file with -i filename\n");
        return 1;
    }

    threads = malloc(threadCount * sizeof(pthread_t));
    if (!threads) {
        fprintf(stderr, "Error: failed to allocate memory for threads\n");
        return 1;
    }
    cleanupData.threads = threads;

    threadData = malloc(threadCount * sizeof(thread_data_t));
    if (!threadData) {
        fprintf(stderr, "Error: failed to allocate memory for thread data\n");
        cleanup(&cleanupData);
        return 1;
    }
    cleanupData.threadData = threadData;

    hashFile = fopen(hash, "r");
    dictFile = fopen(dict, "r");

    if (!hashFile || !dictFile) {
        fprintf(stderr, "failed to open input file\n");
        cleanup(&cleanupData);
        return 1;
    }

    hashBuffer = readFileToBuffer(hashFile, &hashSize);
    fclose(hashFile);
    if (!hashBuffer) {
        fprintf(stderr, "Error: failed to read hash file\n");
        cleanup(&cleanupData);
        return 1;
    }
    cleanupData.hashBuffer = hashBuffer;

    dictBuffer = readFileToBuffer(dictFile, &dictSize);
    fclose(dictFile);
    if (!dictBuffer) {
        fprintf(stderr, "Error: failed to read dictionary file\n");
        cleanup(&cleanupData);
        return 1;
    }
    cleanupData.dictBuffer = dictBuffer;

    passwords = splitIntoLines(dictBuffer, &dictCount);
    if (!passwords) {
        fprintf(stderr, "Error: failed to parse dictionary file\n");
        cleanup(&cleanupData);
        return 1;
    }
    cleanupData.passwords = passwords;

    hashes = splitIntoLines(hashBuffer, &hashCount);
    if (!hashes) {
        fprintf(stderr, "Error: failed to parse hash file\n");
        cleanup(&cleanupData);
        return 1;
    }
    cleanupData.hashes = hashes;

    if (outputFile) {
        outFile = fopen(outputFile, "w");
        if (!outFile) {
            fprintf(stderr, "Error opening output file: %s\n", outputFile);
            cleanup(&cleanupData);
            return 1;
        }
    } else {
        outFile = stdout;
    }

    if (verbose) {
        fprintf(stderr, "Configuration:\n");
        fprintf(stderr, "  Threads:    %zu\n", threadCount);
        fprintf(stderr, "  Hashes:     %zu\n", hashCount);
        fprintf(stderr, "  Dictionary: %zu passwords\n", dictCount);
        fprintf(stderr, "  Hash file:  %s\n", hash);
        fprintf(stderr, "  Dict file:  %s\n\n", dict);
    }

    /* Create threads once - they will dynamically pull work */
    currHash = 0;

    for (size_t i = 0; i < threadCount; i++) {
        int ret;
        memset(&threadData[i], 0, sizeof(thread_data_t));
        threadData[i].threadId = i;
        threadData[i].hashes = hashes;
        threadData[i].currentHash = &currHash;
        threadData[i].hashCount = hashCount;
        threadData[i].dict = passwords;
        threadData[i].dictCount = dictCount;
        threadData[i].outFile = outFile;
        threadData[i].outMutex = &outMutex;
        threadData[i].workMutex = &workMutex;

        ret = pthread_create(&threads[i], NULL, checkPasswords, &threadData[i]);
        if (ret != 0) {
            fprintf(stderr, "Error creating thread %zu: %s\n", i, strerror(ret));
            exit(1);
        }
    }

    /* Wait for all threads to complete */
    for (size_t i = 0; i < threadCount; i++) {
        int ret = pthread_join(threads[i], NULL);
        if (ret != 0) {
            fprintf(stderr, "Error joining thread %zu: %s\n", i, strerror(ret));
            exit(1);
        }
    }

    pthread_mutex_destroy(&workMutex);

    /* Print per-thread statistics */
    for (size_t i = 0; i < threadCount; i++) {
        fprintf(stderr, "thread: %2d  %7.2f sec              DES: %5d               NT: %5d              MD5: %5d           SHA256: %5d           SHA512: %5d         YESCRYPT: %5d    GOST_YESCRYPT: %5d           BCRYPT: %5d  total: %8d  failed: %8d\n",
            threadData[i].threadId,
            threadData[i].timeSec,
            threadData[i].desCount,
            threadData[i].ntCount,
            threadData[i].md5Count,
            threadData[i].sha256Count,
            threadData[i].sha512Count,
            threadData[i].yescryptCount,
            threadData[i].gostYescryptCount,
            threadData[i].bcryptCount,
            threadData[i].total,
            threadData[i].failed
        );

        if (threadData[i].timeSec > totalTime) totalTime = threadData[i].timeSec;
        totalDes += threadData[i].desCount;
        totalNt += threadData[i].ntCount;
        totalMd5 += threadData[i].md5Count;
        totalSha256 += threadData[i].sha256Count;
        totalSha512 += threadData[i].sha512Count;
        totalYescrypt += threadData[i].yescryptCount;
        totalGost += threadData[i].gostYescryptCount;
        totalBcrypt += threadData[i].bcryptCount;
        totalHashes += threadData[i].total;
        totalFailed += threadData[i].failed;
    }

    fprintf(stderr, "total:  %2zu  %7.2f sec              DES: %5d               NT: %5d              MD5: %5d           SHA256: %5d           SHA512: %5d         YESCRYPT: %5d    GOST_YESCRYPT: %5d           BCRYPT: %5d  total: %8d  failed: %8d\n",
        threadCount,
        totalTime,
        totalDes,
        totalNt,
        totalMd5,
        totalSha256,
        totalSha512,
        totalYescrypt,
        totalGost,
        totalBcrypt,
        totalHashes,
        totalFailed
    );

    if (outputFile && outFile) {
        fclose(outFile);
    }

    pthread_mutex_destroy(&outMutex);

    cleanup(&cleanupData);
    return 0;
}
