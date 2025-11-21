#define _POSIX_C_SOURCE 199309L
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
    char *threadHash;
    char **dict;
    size_t dictCount;
    FILE *outFile;
    pthread_mutex_t *outMutex;

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
    thread_data_t *allThreadData;
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
    if (data->allThreadData) free(data->allThreadData);
    if (data->passwords) free(data->passwords);
    if (data->dictBuffer) free(data->dictBuffer);
    if (data->hashes) free(data->hashes);
    if (data->hashBuffer) free(data->hashBuffer);
}

void* checkPasswords(void* arg) {
    thread_data_t* tdata = (thread_data_t*)arg;
    struct crypt_data data;
    char *result = NULL;
    struct timespec start, end;
    int found = 0;
    memset(&data, 0, sizeof(data));

    tdata->total = 1;
    tdata->failed = 0;

    clock_gettime(CLOCK_MONOTONIC, &start);
    identifyHashType(tdata->threadHash, tdata);

    for (size_t i = 0; i < tdata->dictCount; i++) {
        result = crypt_rn(tdata->dict[i], tdata->threadHash, &data, sizeof(data));
        if (result == NULL) {
            continue;
        }
        if (strcmp(result, tdata->threadHash) == 0) {
            pthread_mutex_lock(tdata->outMutex);
            fprintf(tdata->outFile, "cracked  %s  %s\n", tdata->dict[i], tdata->threadHash);
            pthread_mutex_unlock(tdata->outMutex);
            found = 1;
            break;
        }
    }

    if (!found) {
        pthread_mutex_lock(tdata->outMutex);
        fprintf(tdata->outFile, "*** failed to crack  %s\n", tdata->threadHash);
        pthread_mutex_unlock(tdata->outMutex);
        tdata->failed++;
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
    size_t batchSize = 0;
    size_t hashSize, dictSize;
    size_t hashCount, dictCount;
    FILE *hashFile = NULL;
    FILE *dictFile = NULL;
    FILE *outFile = NULL;
    pthread_t *threads;
    thread_data_t *threadData;
    thread_data_t *allThreadData;
    pthread_mutex_t outMutex = PTHREAD_MUTEX_INITIALIZER;
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
            if (threadCount < 1 || threadCount > 40) threadCount = 1;
        }
        else if (opt == 'v') verbose = 1;
        else if (opt == 'n') setpriority(PRIO_PROCESS, 0, 10) ;
        else if (opt == 'h') {
            printf("./thread_hash ...\n");
            printf("Options: i:o:d:hvt:n\n");
            printf("        -i file         hash file name (required)\n");
            printf("        -o file         output file name (default stdout)\n");
            printf("        -d file         dictionary file name (required)\n");
            printf("        -t #            number of threads to create (default == 1)\n");
            printf("        -n              renice to 10\n");
            printf("        -v              enable verbose mode\n");
            printf("        -h              helpful text\n");
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

    allThreadData = malloc(threadCount * sizeof(thread_data_t));
    if (!allThreadData) {
        fprintf(stderr, "Error: failed to allocate memory for thread summary data\n");
        cleanup(&cleanupData);
        return 1;
    }
    cleanupData.allThreadData = allThreadData;

    memset(allThreadData, 0, threadCount * sizeof(thread_data_t));

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

    while (currHash < hashCount) {
        int ret;
        batchSize = threadCount;
        if (hashCount - currHash < threadCount) {
            batchSize = hashCount - currHash;
        }

        for (size_t i = 0; i < batchSize; i++) {
            memset(&threadData[i], 0, sizeof(thread_data_t));
            threadData[i].threadId = i;
            threadData[i].threadHash = hashes[currHash];
            threadData[i].dict = passwords;
            threadData[i].dictCount = dictCount;
            threadData[i].outFile = outFile;
            threadData[i].outMutex = &outMutex;

            ret = pthread_create(&threads[i], NULL, checkPasswords, &threadData[i]);
            if (ret != 0) {
                fprintf(stderr, "Error creating thread %zu: %s\n", i, strerror(ret));
                exit(1);
            }
            currHash++;
        }

        for (size_t i = 0; i < batchSize; i++) {
            ret = pthread_join(threads[i], NULL);
            if (ret != 0) {
                fprintf(stderr, "Error joining thread %zu: %s\n", i, strerror(ret));
                exit(1);
            }
            if (allThreadData[i].timeSec < threadData[i].timeSec) allThreadData[i].timeSec = threadData[i].timeSec;

            allThreadData[i].desCount += threadData[i].desCount;
            allThreadData[i].ntCount += threadData[i].ntCount;
            allThreadData[i].md5Count += threadData[i].md5Count;
            allThreadData[i].sha256Count += threadData[i].sha256Count;
            allThreadData[i].sha512Count += threadData[i].sha512Count;
            allThreadData[i].yescryptCount += threadData[i].yescryptCount;
            allThreadData[i].gostYescryptCount += threadData[i].gostYescryptCount;
            allThreadData[i].bcryptCount += threadData[i].bcryptCount;
            allThreadData[i].total += threadData[i].total;
            allThreadData[i].failed += threadData[i].failed;
            allThreadData[i].threadId = i;
        }
    }

    for (size_t i = 0; i < threadCount; i++) {
        fprintf(stderr, "thread: %2d  %7.2f sec              DES: %5d               NT: %5d              MD5: %5d           SHA256: %5d           SHA512: %5d         YESCRYPT: %5d    GOST_YESCRYPT: %5d           BCRYPT: %5d  total: %8d  failed: %8d\n",
            allThreadData[i].threadId,
            allThreadData[i].timeSec,
            allThreadData[i].desCount,
            allThreadData[i].ntCount,
            allThreadData[i].md5Count,
            allThreadData[i].sha256Count,
            allThreadData[i].sha512Count,
            allThreadData[i].yescryptCount,
            allThreadData[i].gostYescryptCount,
            allThreadData[i].bcryptCount,
            allThreadData[i].total,
            allThreadData[i].failed
        );

        if (allThreadData[i].timeSec > totalTime) totalTime = allThreadData[i].timeSec;
        totalDes += allThreadData[i].desCount;
        totalNt += allThreadData[i].ntCount;
        totalMd5 += allThreadData[i].md5Count;
        totalSha256 += allThreadData[i].sha256Count;
        totalSha512 += allThreadData[i].sha512Count;
        totalYescrypt += allThreadData[i].yescryptCount;
        totalGost += allThreadData[i].gostYescryptCount;
        totalBcrypt += allThreadData[i].bcryptCount;
        totalHashes += allThreadData[i].total;
        totalFailed += allThreadData[i].failed;
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
