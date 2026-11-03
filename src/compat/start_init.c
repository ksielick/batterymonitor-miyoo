/* The init and fini functions start.S hands to __libc_start_main@GLIBC_2.4: glibc 2.28 calls
 * them instead of running the executable's constructors and destructors itself.
 * From tyrquake-miyoo (miyoo/standalone/tqrun.c, tqrun_init / tqrun_fini). */
#include <stddef.h>

extern void (*__preinit_array_start[])(int, char **, char **);
extern void (*__preinit_array_end[])(int, char **, char **);
extern void (*__init_array_start[])(int, char **, char **);
extern void (*__init_array_end[])(int, char **, char **);
extern void (*__fini_array_start[])(void);
extern void (*__fini_array_end[])(void);

void miyoo_start_init(int argc, char **argv, char **envp)
{
   size_t i;
   for (i = 0; i < (size_t)(__preinit_array_end - __preinit_array_start); i++)
      __preinit_array_start[i](argc, argv, envp);
   for (i = 0; i < (size_t)(__init_array_end - __init_array_start); i++)
      __init_array_start[i](argc, argv, envp);
}

void miyoo_start_fini(void)
{
   size_t i = __fini_array_end - __fini_array_start;
   while (i-- > 0)
      __fini_array_start[i]();
}
