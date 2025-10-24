#include <limits.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/stat.h>
#include <sys/sysmacros.h>
#include <time.h>
#include <unistd.h>
#include <pwd.h>
#include <grp.h>

int main(int argc, char **argv) {
  struct stat sb;
  struct passwd *pw;
  struct group *gr;
  char str[11];

  char permission_chars[] = "rwxrwxrwx";
  mode_t permission_bits[] = {
    S_IRUSR, S_IWUSR, S_IXUSR,  // User: read, write, execute
    S_IRGRP, S_IWGRP, S_IXGRP,  // Group: read, write, execute
    S_IROTH, S_IWOTH, S_IXOTH   // Other: read, write, execute
  };

  if (argc <= 1) {
    printf("Usage: ./mystat <filename1> ... <filenameN>\n");
    return 0;
  }

  for (int i = 1; i < argc; i++) {
    if (lstat(argv[i], &sb) == -1) {
        fprintf(stderr, "*** Failed to stat file '%s', skipping.\n",
        argv[i]);
        fprintf(stderr,
        "***  File '%s', does not exist or we done have access.\n",
        argv[i]);
        fprintf(stderr,
        "*** Could not stat file: No such file or directory.\n");
    } else {

      printf("File: %s\n", argv[i]);

      printf("  File type:                ");

      switch (sb.st_mode & S_IFMT) {
        case S_IFBLK:
          str[0] = 'b';
          printf("block device\n");
          break;
        case S_IFCHR:
          str[0] = 'c';
          printf("character device\n");
          break;
        case S_IFDIR:
          str[0] = 'd';
          printf("directory\n");
          break;
        case S_IFIFO:
          str[0] = 'p';
          printf("FIFO/pipe\n");
          break;
        case S_IFREG:
          str[0] = '-';
          printf("regular file\n");
          break;
        case S_IFSOCK:
          str[0] = 's';
          printf("socket\n");
          break;
        case S_IFLNK:
          char link_target[PATH_MAX];
          char resolved_target[PATH_MAX];
          ssize_t len = readlink(argv[i], link_target, sizeof(link_target) - 1);
          str[0] = 'l';
          if (len != -1) { link_target[len] = '\0'; }
          if (realpath(link_target, resolved_target) != NULL) { printf("Symbolic link -> %s\n", resolved_target); }
          else { printf("Symbolic link - with dangling destination\n"); }
          break;
        default:
          str[0] = '?';
          printf("unknown?\n");
          break;
      }

      for (int j = 0; j < 9; j++) { str[j + 1] = (sb.st_mode & permission_bits[j]) ? permission_chars[j] : '-'; }
      str[10] = '\0';

      pw = getpwuid(sb.st_uid);
      gr = getgrgid(sb.st_gid);

      printf("  %-26s%lu\n", "Device ID number:", (unsigned long)sb.st_dev);
      printf("  %-26s%ju\n", "I-node number:", (uintmax_t)sb.st_ino);
      printf("  %-26s%-18s(%jo in octal)\n", "Mode:", str, (uintmax_t)(sb.st_mode & 0777));
      printf("  %-26s%ju\n", "Link count:", (uintmax_t)sb.st_nlink);
      printf("  %-26s%-18s(UID = %ju)\n", "Owner Id:", pw->pw_name, (uintmax_t)sb.st_uid);
      printf("  %-26s%-18s(GID = %ju)\n", "Group Id:", gr->gr_name, (uintmax_t)sb.st_gid);
      printf("  Preferred I/O block size: %jd bytes\n",(intmax_t)sb.st_blksize);
      printf("  File size:                %jd bytes\n",(intmax_t)sb.st_size);
      printf("  Blocks allocated:         %jd\n", (intmax_t)sb.st_blocks);


      printf("  Last file access:         %s", ctime(&sb.st_atime));
      printf("  Last file modification:   %s", ctime(&sb.st_mtime));
      printf("  Last status change:       %s", ctime(&sb.st_ctime));

      printf("  Last file access:         %s", ctime(&sb.st_atime));
      printf("  Last file modification:   %s", ctime(&sb.st_mtime));
      printf("  Last status change:       %s", ctime(&sb.st_ctime));


      printf("  Last file access:         %s", ctime(&sb.st_atime));
      printf("  Last file modification:   %s", ctime(&sb.st_mtime));
      printf("  Last status change:       %s", ctime(&sb.st_ctime));


    }
  }
  return 0;
}