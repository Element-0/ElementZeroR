// #include <sqlite3>
#include <windows.h>

extern int sqlite3_initialize(void);
extern int sqlite3_shutdown(void);

BOOL WINAPI DllMain(HINSTANCE hinstDLL, DWORD fdwReason, LPVOID lpReserved) {
  switch (fdwReason) {
  case DLL_PROCESS_ATTACH:
    sqlite3_initialize();
    break;
  case DLL_PROCESS_DETACH:
    sqlite3_shutdown();
    break;
  default:
    break;
  }
  return TRUE;
}