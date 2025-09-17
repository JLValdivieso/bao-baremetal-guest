

#include <core.h>
#include <plat.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/errno.h>

#include <spinlock.h>
#include <uart.h>
#include <cpu.h>
#include <fences.h>
#include <wfi.h>

#ifdef __CHERI_PURE_CAPABILITY__
#include <arch/cheri/cheri.h>
#include <arch/cheri/cheri_utils.h>
#endif

extern size_t _heap_base_sym;

int _read(int file, char *ptr, int len)
{
    int i;
    for (i = 0; i < len; ++i)
    {
        ptr[i] = uart_getchar();
    }

    return len;
}

int _write(int file, char *ptr, int len)
{
    int i;
    for (i = 0; i < len; ++i)
    {
        if (ptr[i] == '\n')
        {
            uart_putc('\r');
        }
        uart_putc(ptr[i]);
    }

    return len;
}

int _lseek(int file, int ptr, int dir)
{
    errno = ESPIPE;
    return -1;
}

int _close(int file)
{
    return -1;
}

int _fstat(int file, struct stat *st)
{
    st->st_mode = S_IFCHR;
    return 0;
}

int _isatty(int fd)
{
    errno = ENOTTY;
    return 0;
}

void* _sbrk(int increment)
{
#ifdef __CHERI_PURE_CAPABILITY__
    char* heap_end = (char*) cheri_build_data_cap(_heap_base_sym, ((MEM_BASE + MEM_SIZE) - (size_t) _heap_base_sym), CHERI_DATA_PERMS);
#else
    static char* heap_end = (char*)_heap_base_sym;
#endif
    char* current_heap_end = heap_end;
    heap_end += increment;
    return current_heap_end;
}

void _exit(int return_value)
{
    fence_ord();
    while (1) {
        wfi();
    }
}

int _getpid(void)
{
  return 1;
}

int _kill(int pid, int sig)
{
    errno = EINVAL;
    return -1;
}

extern void arch_init();
extern int main();

static bool init_done = false;
static spinlock_t init_lock = SPINLOCK_INITVAL;

__attribute__((weak))
void _init(){

    spin_lock(&init_lock);
    if(!init_done) {
        init_done = true;
        uart_init();
    }
    spin_unlock(&init_lock);
    
    arch_init();

    int ret = main();
    _exit(ret);
}

