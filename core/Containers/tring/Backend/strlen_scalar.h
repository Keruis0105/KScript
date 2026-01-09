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

    template <typename CharT>
    constexpr inline const uint64_t* aligned_ptr(const CharT* p) noexcept {
        return reinterpret_cast<const uint64_t*>(
            reinterpret_cast<uintptr_t>(p) & ~(sizeof(uint64_t)-1)
        );
    }

    template <typename CharT>
    inline bool has_zero(uint64_t word) noexcept {
        constexpr uint64_t mask01 = strlen_mask<CharT>::kMask01;
        constexpr uint64_t mask80 = strlen_mask<CharT>::kMask80;
        return (word - mask01) & (~word & mask80);
    }

    template <typename CharT>
    [[nodiscard]] inline __attribute__((always_inline)) size_t strlen_scalar(const CharT* str) noexcept {
        const CharT* p = str;
        while (true) {
            auto* lp = aligned_ptr(p);
            uint64_t word = *lp;
            if (has_zero<CharT>(word)) {
                for (size_t i = 0; i < 8 / sizeof(CharT); ++i) {
                    if (p[i] == CharT(0)) return p - str + i;
                }
            }
            p += 8 / sizeof(CharT);
        }
    }
}

#endif