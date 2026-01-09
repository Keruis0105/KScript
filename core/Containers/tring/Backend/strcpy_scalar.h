#ifndef STRCPY_SCALAR_H
#define STRCPY_SCALAR_H

#include <cstdint>

namespace Backend::String {

    enum class Direction { 
        Forward, 
        Backward 
    };

    template<typename CharT, Direction dir>
    inline void copy_bytes(char* d, const char* s, size_t length) noexcept {
        if (length == 0) return;

        if constexpr (dir == Direction::Backward) {
            d += length;
            s += length;
        }

        size_t head_bytes = length;
        if ((reinterpret_cast<uintptr_t>(d) | reinterpret_cast<uintptr_t>(s)) & 7) {
            if (length >= 8 && ((reinterpret_cast<uintptr_t>(d) ^ reinterpret_cast<uintptr_t>(s)) & 7) == 0)
                head_bytes = 8 - (reinterpret_cast<uintptr_t>(d) & 7);
            length -= head_bytes;

            if constexpr (dir == Direction::Forward) {
                while (head_bytes--) *d++ = *s++;
            } else {
                while (head_bytes--) *--d = *--s;
            }
        }

        size_t word_count = length / 8;
        while (word_count--) {
            if constexpr (dir == Direction::Forward) {
                *reinterpret_cast<uint64_t*>(d) = *reinterpret_cast<const uint64_t*>(s);
                d += 8; s += 8;
            } else {
                d -= 8; s -= 8;
                *reinterpret_cast<uint64_t*>(d) = *reinterpret_cast<const uint64_t*>(s);
            }
        }

        size_t tail_bytes = length & 7;
        if constexpr (dir == Direction::Forward) {
            while (tail_bytes--) *d++ = *s++;
        } else {
            while (tail_bytes--) *--d = *--s;
        }
    }

    template <typename CharT, bool NonOverlapping = true>
    inline __attribute__((always_inline)) void strcpy_scalar(CharT* dest, const CharT* src, size_t length) noexcept {
        if (length == 0 || dest == src) return;

        if constexpr (NonOverlapping) {
            copy_bytes<char, Direction::Forward>(reinterpret_cast<char*>(dest),
                             reinterpret_cast<const char*>(src),
                             length * sizeof(CharT)
                            );
        } else {
            if (dest < src) {
                copy_bytes<char, Direction::Forward>(reinterpret_cast<char*>(dest),
                             reinterpret_cast<const char*>(src),
                             length * sizeof(CharT)
                             );
            } else {
                copy_bytes<char, Direction::Backward>(reinterpret_cast<char*>(dest),
                             reinterpret_cast<const char*>(src),
                             length * sizeof(CharT)
                             );
            }
        }
    }
};


#endif //STRCPY_SCALAR_H
