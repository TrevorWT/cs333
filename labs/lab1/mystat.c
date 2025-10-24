#include <limits.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <unistd.h>
#include <grp.h>
#include <pwd.h>
#include <sys/stat.h>
#include <sys/sysmacros.h>

int main(int argc, char **argv) {

  // info
  struct stat sb;
  struct passwd *pw;
  struct group *gr;

  //mode
  char mode_str[11];
  char permission_chars[] = "rwxrwxrwx";
  mode_t permission_bits[] = {
    S_IRUSR, S_IWUSR, S_IXUSR, // User: read, write, execute
    S_IRGRP, S_IWGRP, S_IXGRP, // Group: read, write, execute
    S_IROTH, S_IWOTH, S_IXOTH  // Other: read, write, execute
  };

  // time
  char buffer[100];

  if (argc <= 1) {
    printf("Usage: ./mystat <filename1> ... <filenameN>\n");
    return 0;
  }

  for (int i = 1; i < argc; i++) {
    if (lstat(argv[i], &sb) == -1) {
      fprintf(stderr, "*** Failed to stat file '%s', skipping.\n",argv[i]);
      fprintf(stderr,"***  File '%s', does not exist or we done have access.\n",argv[i]);
      fprintf(stderr,"*** Could not stat file: No such file or directory.\n");

    } else {
      printf("File: %s\n", argv[i]);
      printf("  %-26s", "File type:");

      switch (sb.st_mode & S_IFMT) {
      case S_IFBLK:
        mode_str[0] = 'b';
        printf("block device\n");
        break;
      case S_IFCHR:
        mode_str[0] = 'c';
        printf("character device\n");
        break;
      case S_IFDIR:
        mode_str[0] = 'd';
        printf("directory\n");
        break;
      case S_IFIFO:
        mode_str[0] = 'p';
        printf("FIFO/pipe\n");
        break;
      case S_IFREG:
        mode_str[0] = '-';
        printf("regular file\n");
        break;
      case S_IFSOCK:
        mode_str[0] = 's';
        printf("socket\n");
        break;
      case S_IFLNK:
        char link_target[PATH_MAX];
        char resolved_target[PATH_MAX];
        ssize_t len = readlink(argv[i], link_target, sizeof(link_target) - 1);
        mode_str[0] = 'l';
        if (len != -1) link_target[len] = '\0';
        if (realpath(link_target, resolved_target) != NULL) printf("Symbolic link -> %s\n", link_target);
        else printf("Symbolic link - with dangling destination\n");
        break;
      }

      // mode
      for (int j = 0; j < 9; j++) mode_str[j + 1] = (sb.st_mode & permission_bits[j]) ? permission_chars[j] : '-';
      mode_str[10] = '\0';

      if (sb.st_mode & S_ISUID) mode_str[3] = (mode_str[3]=='x') ? 's' : 'S';
      if (sb.st_mode & S_ISGID) mode_str[6] = (mode_str[6]=='x') ? 's' : 'S';
      if (sb.st_mode & S_ISVTX) mode_str[9] = (mode_str[9]=='x') ? 't' : 'T';

      // info
      pw = getpwuid(sb.st_uid);
      gr = getgrgid(sb.st_gid);

      printf("  %-26s%lu\n", "Device ID number:", (unsigned long)sb.st_dev);
      printf("  %-26s%ju\n", "I-node number:", (uintmax_t)sb.st_ino);
      printf("  %-26s%-18s(%03jo in octal)\n", "Mode:", mode_str, (uintmax_t)(sb.st_mode & 0777));
      printf("  %-26s%ju\n", "Link count:", (uintmax_t)sb.st_nlink);
      printf("  %-26s%-18s(UID = %ju)\n", "Owner Id:", pw->pw_name, (uintmax_t)sb.st_uid);
      printf("  %-26s%-18s(GID = %ju)\n", "Group Id:", gr->gr_name, (uintmax_t)sb.st_gid);
      printf("  %-26s%jd bytes\n", "Preferred I/O block size:", (intmax_t)sb.st_blksize);
      printf("  %-26s%jd bytes\n", "File size:", (intmax_t)sb.st_size);
      printf("  %-26s%jd\n", "Blocks allocated:", (intmax_t)sb.st_blocks);

      // Time

      printf("  Last file access: ");
      printf("%8s%10ld (seconds since the epoch)\n", "", (long)sb.st_atime);

      printf("  Last file modification: ");
      printf("%2s%10ld (seconds since the epoch)\n", "", (long)sb.st_mtime);

      printf("  Last status change: ");
      printf("%6s%10ld (seconds since the epoch)\n", "", (long)sb.st_ctime);


      strftime(buffer, sizeof(buffer), "%Y-%m-%d %H:%M:%S %z (%Z) %a (local)", localtime(&sb.st_atime));
        printf("  %-26s%s\n", "Last file access:", buffer);

      strftime(buffer, sizeof(buffer), "%Y-%m-%d %H:%M:%S %z (%Z) %a (local)", localtime(&sb.st_mtime));
        printf("  %-26s%s\n", "Last file modification:", buffer);

      strftime(buffer, sizeof(buffer), "%Y-%m-%d %H:%M:%S %z (%Z) %a (local)", localtime(&sb.st_ctime));
        printf("  %-26s%s\n", "Last status change:", buffer);

      strftime(buffer, sizeof(buffer), "%Y-%m-%d %H:%M:%S %z (%Z) %a (GMT)", gmtime(&sb.st_atime));
        printf("  %-26s%s\n", "Last file access:", buffer);

      strftime(buffer, sizeof(buffer), "%Y-%m-%d %H:%M:%S %z (%Z) %a (GMT)", gmtime(&sb.st_mtime));
        printf("  %-26s%s\n", "Last file modification:", buffer);

      strftime(buffer, sizeof(buffer), "%Y-%m-%d %H:%M:%S %z (%Z) %a (GMT)", gmtime(&sb.st_ctime));
        printf("  %-26s%s\n", "Last status change:", buffer);

    }
  }
  return 0;
}