#ifndef FIND_CHAR_SCALAR_H
#define FIND_CHAR_SCALAR_H

#include <cstdint>

namespace Backend::String::Find {
    template <typename T>
    concept char_like =
        sizeof(T) == 1 || sizeof(T) == 2 || sizeof(T) == 4;

    template <char_like CharT>
    struct strlen_mask {
        using mask_t = uint64_t;

        static constexpr mask_t lane_bits = sizeof(CharT) * 8;

        static constexpr mask_t kMask01 =
            mask_t(-1) / ((mask_t(1) << lane_bits) - 1);

        static constexpr mask_t kMask80 =
            kMask01 << (lane_bits - 1);
    };

    template <char_like CharT>
    constexpr inline CharT* aligned_ptr(const CharT* p) noexcept {
        return reinterpret_cast<CharT*>(
            reinterpret_cast<uintptr_t>(p) & ~(sizeof(uint64_t)-1)
        );
    }

    template <char_like CharT>
    constexpr inline bool has_char(uint64_t word, CharT c) noexcept {
        constexpr uint64_t mask01 = strlen_mask<CharT>::kMask01;
        constexpr uint64_t mask80 = strlen_mask<CharT>::kMask80;
        uint64_t c_mask = mask01 * static_cast<uint64_t>(c);
        return ((word ^ c_mask) - mask01) & (~(word ^ c_mask) & mask80);
    }

    template <char_like CharT>
    [[nodiscard]] inline __attribute__((always_inline))
    size_t find_char_scalar(const CharT* ptr, uint64_t length, CharT target) noexcept {
        const CharT* p = ptr;
        CharT* lp = aligned_ptr(p);
        union alignas(16) U16 {
            uint64_t word[2];
        } words;
        __builtin_memcpy(&words, lp, sizeof(words));
        const size_t lane_off = p - lp;
        words.word[0] |= uint64_t(-1) >>
                (64 - lane_off * strlen_mask<CharT>::lane_bits);
        constexpr size_t lanes = 8 / sizeof(CharT);
        constexpr size_t block_lanes = 16 / sizeof(CharT);
        const CharT* end = ptr + length;
        while (lp + 16 <= end) {
            if (has_char<CharT>(words.word[0], target)) {
                for (size_t i = 0; i < lanes; ++i)
                    if (lp[i] == target) return lp + i - p;
            }
            if (has_char<CharT>(words.word[1], target)) {
                for (size_t i = 0; i < lanes; ++i)
                    if (lp[i + lanes] == target) return lp + i + lanes - p;
            }
            lp += block_lanes;
            __builtin_memcpy(&words, lp, sizeof(words));
        }
        while (lp < end) {
            if (*lp == target) return lp - p;
            ++lp;   
        }
        return size_t(-1);
    }
} 


#endif