#include "strcpy_scalar.h"

template void Backend::String::strcpy_scalar<char8_t, true>(char8_t*, const char8_t*, size_t);
template void Backend::String::strcpy_scalar<char16_t, true>(char16_t*, const char16_t*, size_t);
template void Backend::String::strcpy_scalar<char32_t, true>(char32_t*, const char32_t*, size_t);
template void Backend::String::strcpy_scalar<char8_t, false>(char8_t*, const char8_t*, size_t);
template void Backend::String::strcpy_scalar<char16_t, false>(char16_t*, const char16_t*, size_t);
template void Backend::String::strcpy_scalar<char32_t, false>(char32_t*, const char32_t*, size_t);


extern "C" void strcpy_u8(char8_t* d, const char8_t* s, size_t c) { Backend::String::strcpy_scalar<char8_t, true>(d, s, c); }
extern "C" void strcpy_u16(char16_t* d, const char16_t* s, size_t c) { Backend::String::strcpy_scalar<char16_t, true>(d, s, c); }
extern "C" void strcpy_u32(char32_t* d, const char32_t* s, size_t c) { Backend::String::strcpy_scalar<char32_t, true>(d, s, c); }
extern "C" void strmove_u8(char8_t* d, const char8_t* s, size_t c) { Backend::String::strcpy_scalar<char8_t, false>(d, s, c); }
extern "C" void strmove_u16(char16_t* d, const char16_t* s, size_t c) { Backend::String::strcpy_scalar<char16_t, false>(d, s, c); }
extern "C" void strmove_u32(char32_t* d, const char32_t* s, size_t c) { Backend::String::strcpy_scalar<char32_t, false>(d, s, c); }