#include "strlen_scalar.h"

template size_t Backend::String::strlen_scalar<char>(const char*);
template size_t Backend::String::strlen_scalar<wchar_t>(const wchar_t*);
template size_t Backend::String::strlen_scalar<char32_t>(const char32_t*);

extern "C" size_t strlen_u8(const char* s) { return Backend::String::strlen_scalar<char>(s); }
extern "C" size_t strlen_u16(const wchar_t* s) { return Backend::String::strlen_scalar<wchar_t>(s); }
extern "C" size_t strlen_u32(const char32_t* s) { return Backend::String::strlen_scalar<char32_t>(s); }