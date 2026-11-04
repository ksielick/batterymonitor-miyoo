/* stat() and stat64() became real symbols in glibc 2.33; the Miyoo's glibc 2.28 only has __xstat and __xstat64.
 * Linked with -Wl,--wrap=stat64 -Wl,--wrap=stat */
#define _LARGEFILE64_SOURCE 1
#include <sys/stat.h>

extern int __xstat64(int ver, const char *path, struct stat64 *buf);
__asm__(".symver __xstat64,__xstat64@GLIBC_2.4");

int __wrap_stat64(const char *path, struct stat64 *buf)
{
	return __xstat64(3, path, buf); /* _STAT_VER_LINUX */
}

extern int __xstat(int ver, const char *path, struct stat *buf);
__asm__(".symver __xstat,__xstat@GLIBC_2.4");

int __wrap_stat(const char *path, struct stat *buf)
{
	return __xstat(3, path, buf); /* _STAT_VER_LINUX */
}

/* -nostartfiles drops crtbegin.o's __dso_handle, which atexit() needs (batmon uses it) */
void *__dso_handle __attribute__((visibility("hidden"))) = &__dso_handle;
