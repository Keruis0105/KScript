#ifndef STRLEN_SCALAR_H
#define STRLEN_SCALAR_H

#include <cstddef>
#include <cstdint>
#include <type_traits>
#include <climits>

namespace Backend::String {

    using mask_t = uint64_t;

    template <typename CharT>
    struct strlen_mask {
        static constexpr mask_t kMask01 = []{
            if constexpr(sizeof(CharT) == 1) return 0x0101010101010101ULL;
            if constexpr(sizeof(CharT) == 2) return 0x0001000100010001ULL;
            return 0x0000000100000001ULL;
        }();

        static constexpr mask_t kMask80 = []{
            if constexpr(sizeof(CharT) == 1) return 0x8080808080808080ULL;
            if constexpr(sizeof(CharT) == 2) return 0x8000800080008000ULL;
            return 0x8000000080000000ULL;
        }();
    };

    template<typename MaskT>
    constexpr const MaskT* align_ptr(const void* p) noexcept {
        auto addr = reinterpret_cast<uintptr_t>(p);
        addr &= ~(sizeof(MaskT) - 1);
        return reinterpret_cast<const MaskT*>(addr);
    }

    template <typename CharT>
    inline __attribute__((always_inline, pure)) size_t strlen_scalar(const CharT* __restrict__ str) noexcept {
        const CharT* c = str;

        constexpr mask_t mask01 = strlen_mask<CharT>::kMask01;
        constexpr mask_t mask80 = strlen_mask<CharT>::kMask80;
        constexpr size_t num_chars = sizeof(mask_t)/sizeof(CharT);

        auto* lp = align_ptr<mask_t>(str);
        mask_t va = *lp;
        mask_t vb = ~*lp & mask80;
        lp++;

        if (va - mask01 & vb) {
            for (c = str; c < reinterpret_cast<const CharT*>(lp); ++c) {
                if (*c == 0) return c - str;
            }
        }

        for (;; ++lp) {
            va = *lp;
            vb = ~*lp & mask80;
            if (va - mask01 & vb) {
                c = reinterpret_cast<const CharT*>(lp);
                for (size_t i = 0; i < num_chars; ++i) {
                    if (c[i] == 0) return c - str + i;
                }
            }
        }

        return 0;
    }

}

#endif //STRLEN_SCALAR_H
