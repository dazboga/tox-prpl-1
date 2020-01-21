
#include <windows.h>
#include <time.h>

#define __time32_t time_t

__time32_t _time32( __time32_t *destTime )
{
	return (__time32_t) time( (time_t *) destTime);
}

int __ms_vsnprintf(char *buffer, size_t count, const char *format, va_list argptr )
{
	return _vsnprintf(buffer, count, format, argptr);
}

/*static HMODULE advapi32 = NULL;
typedef BOOLEAN(*SystemFunction036_Func)(PVOID,ULONG);
static SystemFunction036_Func _SystemFunction036;

BOOLEAN SystemFunction036(PVOID RandomBuffer, ULONG RandomBufferLength) {

	if (advapi32 == NULL) {
		advapi32 = LoadLibraryW (L"advapi32.dll");
		_SystemFunction036 = (SystemFunction036_Func)GetProcAddress (advapi32,"SystemFunction036");
	}
	
	return _SystemFunction036(RandomBuffer, RandomBufferLength);
}*/