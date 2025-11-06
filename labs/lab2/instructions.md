# CS333 Lab 2 – arvik‑md4 (AI‑Agent Guide)

## Project Overview
Implement `arvik-md4`, a UNIX archive utility using **low-level file I/O** (`open`, `read`, `write`, `lseek`, etc.). Must interoperate byte‑for‑byte with the instructor’s implementation.

## CLI Syntax
```
arvik-md4 <options> [-f archive-file] [member [...]]
```

## Options and Required Behaviors
### -c  (Create)
- Add listed `member` files to the archive.
- If no members: create archive containing only `ARVIK_TAG`.
- If `-f` not given: write archive to **stdout**.
- If archive **does not exist**: create with mode **0664** (`-rw-rw-r--`), respecting `umask` or correcting with `fchmod()`.
- If archive **exists**: **overwrite contents**, **preserve existing permissions**.
- With `-v`: print one line per added member.

### -x  (Extract)
- Default input is **stdin** if `-f` not provided.
- Extract **all** members; overwrite existing files.
- Restore **permissions (mode)** and **mtime** (`st_mtim`) from archive.
- **Ownership is not restored** (files owned by the current user).
- With `-v`: print one line per extracted member.

### -t  (Table of Contents)
- Default input is **stdin** if `-f` not provided.
- Output format must **exactly** match the instructor’s (`spaces vs tabs matter`).
- With `-v`: **long** table; otherwise **short** table.

### -f <filename>
- Specifies the archive file. Without `-f`, use **stdin/stdout** depending on action.

### -h
- Print help text that **exactly matches** the instructor’s help.

### -V  (Validate)
- Validate MD4 for header and data of each member (HEX string, no `0x`).
- If `-f` not provided: read from **stdin**.

### Invalid Inputs and Exit Codes
- Invalid CLI option → exit **INVALID_CMD_OPTION**.
- Archive must begin with **ARVIK_TAG**; otherwise print error and exit **BAD_TAG** (no further processing).

## Archive Format
Each archive:
1. Begins with the exact **ARVIK_TAG** line.
2. For each member:
   - **Header**: `arvik_header_t` (name, date, uid, gid, mode, size, terminator).
   - **Data**: raw file bytes.
   - **Footer**: `arvik_footer_t` (MD4 of header, MD4 of data, terminator). Checksums are stored as **hex strings** (no `0x`).

## Implementation Rules
- **MUST use**: `open()`, `read()`, `write()`, `close()`, `lseek()` for archive I/O.
- **MUST NOT use**: `fopen()`, `fscanf()`, `fprintf()` or `fgets()` for archive I/O (use `printf()/fprintf()` only for terminal output like `-v` or `-t`).
- Use `stat()/fstat()` for metadata; `fchmod()` for permissions; `futimens()` for timestamps.
- Use `getopt()` for option parsing; do **not** perform file I/O inside the `getopt()` loop—only configure behavior.
- Output for `-t` must match instructor’s **exactly** (tabs for indentation; spaces for alignment).

## Build and Tooling
- **Compiler flags (no warnings allowed)**:
  ```
  -std=c17 -O2
  -Wall -Wextra -Wshadow -Wunreachable-code -Wredundant-decls
  -Wmissing-declarations -Wold-style-definition
  -Wmissing-prototypes -Wdeclaration-after-statement
  -Wno-return-local-addr -Wunsafe-loop-optimizations
  -Wuninitialized -Werror
  ```
- **Link** with `-lmd` for MD4.
- **Valgrind** must be clean (no leaks, no invalid accesses). Violations or compiler warnings incur penalties.

## Makefile (required targets)
- `all` – build everything (default).
- `arvik-md4` – final binary; depends on `arvik-md4.o`.
- `arvik-md4.o` – compiles `arvik-md4.c`.
- `clean` – removes binaries, `.o`, editor chaff.
Expected usage:
```
make clean
make clean all
```

## Submission
Submit a single `tar.gz` on Canvas containing **exactly**:
```
arvik-md4.c
Makefile
```
No subdirectories.

## Recommended Development Plan
1. Author Makefile (with CFLAGS and `-lmd`).
2. Study `arvik.h` (`arvik_header_t` / `arvik_footer_t`, `ARVIK_TAG`).
3. Implement `getopt()` configuration; stub actions.
4. Implement `-h`, `-v`, then `-f` handling (stdin/stdout fallback).
5. Implement `-c` (write `ARVIK_TAG` first; set/keep perms per rules; compute MD4s).
6. Implement `-t` and `-tv` (exact formatting).
7. Implement `-x` (restore mode and mtime, not ownership).
8. Implement `-V` (MD4 checks).
9. Test with instructor archives (`diff`, `md5sum`), and sample files; verify valgrind.

## Suggested Libraries / Headers
- `<unistd.h>` – `read`, `write`, `lseek`, `close`, `getopt`.
- `<fcntl.h>` – `open`, flags.
- `<sys/stat.h>` / `<sys/types.h>` – `stat`, modes.
- `<time.h>` – `strftime("%b %e %R %Y")`, `localtime`.
- `<errno.h>` / `<stdio.h>` – `perror`, `printf`, `fprintf`.
- `<string.h>` – `memcpy`, `memset`, `strncpy`, `strlen`, `memcmp`, `strchr`.
- `<stdlib.h>` – `exit`, `strtol`.
- **libmd** – MD4 (`-lmd`).

## Testing Utilities
- `diff` for text file comparisons.
- `md5sum` for binary integrity checks.
- `cat` an archive to visualize structure during debugging.

## Final Checks
- Compiles with zero warnings/errors using required flags.
- Exact output formatting for `-t` and exact interop with instructor’s tool.
- Clean Valgrind.
- Correct stdin/stdout behavior when `-f` is omitted.
- Proper exit codes for invalid options and bad ARVIK_TAG.
