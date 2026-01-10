#ifndef STRSET_SCALAR_H
#define STRSET_SCALAR_H

#include <cstdint>
#include <iostream>

namespace Backend::String {
    template <typename T>
    concept char_like =
        sizeof(T) == 1 || sizeof(T) == 2 || sizeof(T) == 4;

    template <char_like CharT>
    struct strset_mask {
        using mask_t = uint64_t;

        static constexpr mask_t lane_bits = sizeof(CharT) * 8;

        static constexpr mask_t kMask01 = 
            mask_t(-1) / ((mask_t(1) << lane_bits) - 1);

        static constexpr const mask_t broadcast(CharT c) noexcept {
            return static_cast<uint64_t>(c) * kMask01;
        }
    };

    template <char_like CharT>
    constexpr inline bool is_aligned(const CharT* p) noexcept {
        return (reinterpret_cast<uintptr_t>(p) & (sizeof(uint64_t) - 1)) == 0;
    }

    template <char_like CharT>
    constexpr inline size_t chars_to_align(const CharT* p) noexcept {
        constexpr size_t word_bytes = sizeof(uint64_t);
        uintptr_t addr = reinterpret_cast<uintptr_t>(p);
        size_t mis = addr & (word_bytes - 1);
        if (mis == 0) return 0;

        size_t bytes = word_bytes - mis;
        return (bytes + sizeof(CharT) - 1) / sizeof(CharT);
    }

    template <char_like CharT>
    constexpr inline bool is_properly_aligned(const CharT* p) noexcept {
        uintptr_t addr = reinterpret_cast<uintptr_t>(p);
        return (addr % sizeof(CharT)) == 0;
    }

    template <char_like CharT>
    inline __attribute__((always_inline))
    void strset_scalar(CharT* dest, CharT c, uint64_t length) noexcept {
        CharT* p = dest;

        constexpr size_t min_bulk_chars = (4 * sizeof(uint64_t)) / sizeof(CharT);

        if (length < min_bulk_chars || !is_properly_aligned(p)) 
            goto tail_only;

        if (!is_aligned(p)) {
            size_t align_fill = chars_to_align(dest);
            length -= align_fill;
            while (align_fill--) *p++ = c;
        }

        {
            using mask_t = typename strset_mask<CharT>::mask_t;
            constexpr size_t chars_per_word = sizeof(mask_t) / sizeof(CharT);
            constexpr size_t chars_per_block = chars_per_word * 2;

            mask_t word = strset_mask<CharT>::broadcast(c);
            union alignas(16) U16 {
                mask_t word[2];
            } words {word, word};
            
            size_t num_blocks = length / chars_per_block;
            length %= chars_per_block;
            while (num_blocks--) {
                __builtin_memcpy(p, &words, sizeof(words));
                p += chars_per_block;
            }
            
            size_t num_words = length / chars_per_word;
            length %= chars_per_word;
            while (num_words--) {
                __builtin_memcpy(p, &word, sizeof(word));
                p += chars_per_word;
            }
        }

        tail_only:
            while (length--) *p++ = c;        
    }
}


#endif //STRSET_SCALAR_H
