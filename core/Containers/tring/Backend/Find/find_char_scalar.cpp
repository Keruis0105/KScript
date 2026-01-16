#include "find_char_scalar.h"

template size_t Backend::String::Find::find_char_scalar<char8_t>(const char8_t*, uint64_t, char8_t);
template size_t Backend::String::Find::find_char_scalar<char16_t>(const char16_t*, uint64_t, char16_t);
template size_t Backend::String::Find::find_char_scalar<char32_t>(const char32_t*, uint64_t, char32_t);

extern "C" size_t find_char_u8(const char8_t* ptr, uint64_t length, char8_t target) { Backend::String::Find::find_char_scalar<char8_t>(ptr, length, target); }
extern "C" size_t find_char_u16(const char16_t* ptr, uint64_t length, char16_t target) { Backend::String::Find::find_char_scalar<char16_t>(ptr, length, target); }
extern "C" size_t find_char_u32(const char32_t* ptr, uint64_t length, char32_t target) { Backend::String::Find::find_char_scalar<char32_t>(ptr, length, target); }