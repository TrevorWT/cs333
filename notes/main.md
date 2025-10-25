# Notes

~rchaney/Classes/cs333/VideoAssignments
~rchaney/Classes/cs333/Labs

## Compile C code
    gcc -Wall file.c -o ../target/outputName

## Compress file
### Create
    tar cvfa ${LOGNAME}_name.tar.gz *.[ch]

### Validate
    tar tvfa ${LOGNAME}_name.tar.gz

## New libraries
### gmp
    Compilation flag: -lgmp
    #include <gmp.h>
    Allows for new number variables that are arbetrary length.

## Preprocessing
    4 stages of compilation in C
        1. Preprocessing
        2. Compilation
        3. Assembly
        4. Linking

    4 segments of a C program
        1. Text segment (code)
        2. Data segment (global and static variables)
        3. Heap segment (dynamic memory)
        4. Stack segment (local variables and function call management)

## C macros

- Header guard — use: `#ifndef MYHEADER_H` / `#define MYHEADER_H` ... `#endif`
- STATIC_ASSERT — use: `_Static_assert(cond, "message")`
- STRINGIFY / TOSTRING — use: `TOSTRING(__LINE__)` (two-step `#define`)
- CONCAT — use: `CONCAT(a, b)` or `UNIQUE_NAME(x)` (via `##`)
- ARRAY_SIZE — use: `ARRAY_SIZE(arr)` (static arrays only)
- UNUSED — use: `UNUSED(x)` to silence unused warnings
- LIKELY / UNLIKELY — use: `if (LIKELY(cond))` (compiler hint)
- MIN / MAX — use: `MIN(a, b)` / `MAX(a, b)`
- CONTAINER_OF — use: `container_of(ptr, struct_type, member)`
- DPRINT / DEBUG — use: `DPRINT("fmt", ...)` (enable with `-DDEBUG`)

- assert()

## Get files
### Symbolic links
ln -s ~rchaney/Classes/cs333/VideoAssignments/data/v?.txt .
### Copying
cp -L ~rchaney/Classes/cs333/VideoAssignments/data/v?.txt .
