#include "strset_scalar.h"

template void Backend::String::strset_scalar<char8_t>(char8_t*, char8_t, uint64_t);
template void Backend::String::strset_scalar<char16_t>(char16_t*, char16_t, uint64_t);
template void Backend::String::strset_scalar<char32_t>(char32_t*, char32_t, uint64_t);

extern "C" void void strset_u8(char8_t* d, char8_t c, uint64_t l) { return Backend::String::strset_scalar<char8_t>(d, c, l); }
extern "C" void void strset_u16(char16_t* d, char16_t c, uint64_t l) { return Backend::String::strset_scalar<char16_t>(d, c, l); }
extern "C" void void strset_u32(char32_t* d, char32_t c, uint64_t l) { return Backend::String::strset_scalar<char32_t>(d, c, l); }