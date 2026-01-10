#ifndef STRLEN_SCALAR_H
#define STRLEN_SCALAR_H

#include <cstdint>

namespace Backend::String {
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
    constexpr inline bool has_zero(uint64_t word) noexcept {
        constexpr uint64_t mask01 = strlen_mask<CharT>::kMask01;
        constexpr uint64_t mask80 = strlen_mask<CharT>::kMask80;
        return (word - mask01) & (~word & mask80);
    }

    template <char_like CharT>
    [[nodiscard]] inline __attribute__((always_inline))
    size_t strlen_scalar(const CharT* str) noexcept {
        const CharT* p = str;
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
        while (true) {
            if (has_zero<CharT>(words.word[0])) {
                for (size_t i = 0; i < lanes; ++i)
                    if (lp[i] == CharT(0)) return lp + i - p;
            }
            if (has_zero<CharT>(words.word[1])) {
                for (size_t i = 0; i < lanes; ++i)
                    if (lp[i + lanes] == CharT(0)) return lp + i + lanes - p;
            }
            lp += block_lanes;
            __builtin_memcpy(&words, lp, sizeof(words));
        }
    }
}

#endif