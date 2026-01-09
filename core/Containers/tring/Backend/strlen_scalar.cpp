#include "strlen_scalar.h"

template size_t Backend::String::strlen_scalar<char8_t>(const char8_t*);
template size_t Backend::String::strlen_scalar<char16_t>(const char16_t*);
template size_t Backend::String::strlen_scalar<char32_t>(const char32_t*);

extern "C" size_t strlen_u8(const char8_t* s) { return Backend::String::strlen_scalar<char8_t>(s); }
extern "C" size_t strlen_u16(const char16_t* s) { return Backend::String::strlen_scalar<char16_t>(s); }
extern "C" size_t strlen_u32(const char32_t* s) { return Backend::String::strlen_scalar<char32_t>(s); }