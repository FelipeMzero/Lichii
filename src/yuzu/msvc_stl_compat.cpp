// SPDX-FileCopyrightText: Copyright 2026 Lichii Project
// SPDX-License-Identifier: GPL-3.0-or-later

#ifdef _MSC_VER

#include <algorithm>
#include <cstdint>
#include <utility>

extern "C" {

// 1. __std_rotate: Rotates raw memory range [_First, _Last) around _Mid
void __stdcall __std_rotate(void* first, void* mid, void* last) noexcept {
    if (!first || !mid || !last || first == mid || mid == last) {
        return;
    }
    auto* f = static_cast<char*>(first);
    auto* m = static_cast<char*>(mid);
    auto* l = static_cast<char*>(last);
    std::rotate(f, m, l);
}

// 2. __std_unique_8: Removes consecutive duplicates in 8-byte element range
void* __stdcall __std_unique_8(void* first, void* last) noexcept {
    if (!first || !last || first == last) {
        return first;
    }
    auto* f = static_cast<uint64_t*>(first);
    auto* l = static_cast<uint64_t*>(last);
    return std::unique(f, l);
}

// 3. __std_unique_4: Removes consecutive duplicates in 4-byte element range
void* __stdcall __std_unique_4(void* first, void* last) noexcept {
    if (!first || !last || first == last) {
        return first;
    }
    auto* f = static_cast<uint32_t*>(first);
    auto* l = static_cast<uint32_t*>(last);
    return std::unique(f, l);
}

// 4. __std_replace_copy_1: Replace copy for 1-byte elements
void __stdcall __std_replace_copy_1(const void* first, const void* last, void* dest,
                                   uint8_t old_val, uint8_t new_val) noexcept {
    if (!first || !last || !dest || first == last) {
        return;
    }
    const auto* f = static_cast<const uint8_t*>(first);
    const auto* l = static_cast<const uint8_t*>(last);
    auto* d = static_cast<uint8_t*>(dest);
    std::replace_copy(f, l, d, old_val, new_val);
}

// 5. __std_replace_copy_2: Replace copy for 2-byte elements
void __stdcall __std_replace_copy_2(const void* first, const void* last, void* dest,
                                   uint16_t old_val, uint16_t new_val) noexcept {
    if (!first || !last || !dest || first == last) {
        return;
    }
    const auto* f = static_cast<const uint16_t*>(first);
    const auto* l = static_cast<const uint16_t*>(last);
    auto* d = static_cast<uint16_t*>(dest);
    std::replace_copy(f, l, d, old_val, new_val);
}

// 6. __std_minmax_element_2u: Minmax element for unsigned 16-bit elements
struct MinMaxResult2u {
    const void* min_ptr;
    const void* max_ptr;
};

MinMaxResult2u __stdcall __std_minmax_element_2u(const void* first, const void* last) noexcept {
    if (!first || !last || first == last) {
        return {first, first};
    }
    const auto* f = static_cast<const uint16_t*>(first);
    const auto* l = static_cast<const uint16_t*>(last);
    const auto res = std::minmax_element(f, l);
    return {res.first, res.second};
}

} // extern "C"

#endif // _MSC_VER
