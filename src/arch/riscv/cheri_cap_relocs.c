#include <cheri_init_globals.h>
#include <stdint.h>

void * root_data_cap = (void *)(intcap_t) -1;
void * root_code_cap = (void *)(intcap_t) -1;
void * null_cap = (void *)(intcap_t) 0;

void cheri_init_caps_reloc(void* data_cap, void* code_cap) {
  cheri_init_globals_3(data_cap, code_cap, data_cap);
  root_data_cap = data_cap;
  root_code_cap = code_cap;
}