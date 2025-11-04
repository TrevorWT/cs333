// R Jesse Chaney
// rchaney@pdx.edu

#pragma once

#ifndef _ARVIK_H
# define _ARVIK_H

# define ARVIK_TAG   "#<arvik4>\n" // String that begins an arvik file.
# define ARVIK_TERM  "$\n"         // String in end of each arvik header and footer.
# define ARVIK_NAME_TERM '<'       // Char at end of file name.

# define ARVIK_NAME_LEN 30
# define ARVIK_DATE_LEN 14
# define ARVIK_UID_LEN  6
# define ARVIK_GID_LEN  6
# define ARVIK_MODE_LEN 8
# define ARVIK_SIZE_LEN 12
# define ARVIK_TERM_LEN 2

typedef struct arvik_header_s {
	char arvik_name[ARVIK_NAME_LEN];          // Member file name, sometimes < terminated.
	char arvik_date[ARVIK_DATE_LEN];          // File date, decimal seconds since Epoch.
	char arvik_uid[ARVIK_UID_LEN];            // User ID, in ASCII decimal.
	char arvik_gid[ARVIK_GID_LEN];            // Group ID, in ASCII decimal.
	char arvik_mode[ARVIK_MODE_LEN];          // File mode, in ASCII octal.
	char arvik_size[ARVIK_SIZE_LEN];          // File size, in ASCII decimal.
	char arvik_term[ARVIK_TERM_LEN];          // Always contains ARVIK_TERM.
} arvik_header_t;

typedef struct arvik_footer_s {
	char md4sum_header[MD4_DIGEST_LENGTH * 2];
	char md4sum_data[MD4_DIGEST_LENGTH * 2];
	char arvik_term[ARVIK_TERM_LEN];          // Always contains ARVIK_TERM.
} arvik_footer_t;

# define ARVIK_OPTIONS "cxtvVf:h"
// -c       Create an archive file
// -x       Extract from an archive file
// -t       Table of contents of an archive
// -v       Verbose or long table of contents
// -V       Validate data with footer crc value
// -f name  Name of the archive file
// -h       Helpful info on options

typedef enum {
    ACTION_NONE = 0
    , ACTION_CREATE
    , ACTION_EXTRACT
    , ACTION_TOC
	, ACTION_VALIDATE
} var_action_t;

// exit values
# define INVALID_CMD_OPTION 2
# define NO_ARCHIVE_NAME    3
# define NO_ACTION_GIVEN    4
# define EXTRACT_FAIL       5
# define CREATE_FAIL        6
# define TOC_FAIL           7
# define BAD_TAG            8
# define READ_FAIL          9
# define MD4_ERROR         10

# ifndef MIN
#  define MIN(_A,_B) (((_A) < (_B)) ? (_A) : (_B))
# endif // MIN

#endif // _ARVIK_H
