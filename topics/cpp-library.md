# C++20 language, library and headers

Which standard facility or MAME helper to use, and which header to include for it, now that MAME builds as C++20 (`eea4b471906`, 2026-04-02). mame-review rules that govern it: T-2 (casts), T-4 (constexpr), T-5 (MAME helpers), T-6 (standard library over C), L-2 (strings), F-3 (includes), C-5, C-6, C-7. None of them covers `<bit>`, `<numbers>`, `std::endian` or `requires`; T-5 still applies alongside these rules.

## TL;DR

- Bit counts and rotates come from `<bit>` (`std::countl_zero`, `std::countl_one`, `std::popcount`, `std::rotl`, `std::rotr`), called on an unsigned argument of the width you mean. `BIT`, `bitswap`, `util::sext` and `util::make_bitmask` are still the rule (T-5).
- Take constants from `<numbers>` (`std::numbers::pi`, `std::numbers::pi_v<float>`). Convert float bit patterns with `u2f`/`f2u` from `corefloat.h`, or with `std::bit_cast`.
- `endianness_t` is now `std::endian`. Keep using `ENDIANNESS_BIG`/`ENDIANNESS_LITTLE` in space configs. Include `endianness.h` for `BYTE_XOR_*` and `util::big_endian_cast`, and `multibyte.h` for `get_u32be` and friends.
- Use `requires` clauses, not `std::enable_if`. Use `static constexpr` class constants, not anonymous enums. Don't do arithmetic that mixes enum types, or an enum and a float.
- Include what you use. `emu.h` no longer provides `sound.h`, `video.h`, `input.h`, `corefloat.h` or `endianness.h`.
- Write text files through `util::owritestream` with `util::stream_format`. Read and write binary NVRAM and media through `util::read`/`write`/`read_at`, which return `[err, actual]`.

## Rules

### Bit operations

**Do**

```cpp
#include <bit>
bool const even = !(std::popcount(m_acc) & 1);                 // m_acc is u8
int const level = 31 - std::countl_zero(u32(m_irq_pending));    // m_irq_pending != 0
u32 const rotated = std::rotr(m_reg, shift);                    // m_reg is u32; any int shift
```

The argument must be an unsigned integer type: not `bool`, not `char`, not signed. Integer promotion turns `u8(x) & 0x0f` into `int`, so wrap the expression (`u32(...)`, T-2) or name the type (`std::rotr<u32>(...)`). The result is counted over the argument's own width. Code that replaces `count_leading_zeros_32(x)` with a `u8` or `u16` `x` must write `std::countl_zero(u32(x))`. The multiply/divide helpers in `eminline.h` (`mulu_32x32_hi`, `mul_64x64`, `divu_64x32_rem`) are still current; `cxx.rst` points to them.

**Legacy forms**: `count_leading_zeros_32/64`, `count_leading_ones_32/64`, `population_count_32/64`, `rotl_32`/`rotr_32`/`rotl_64`/`rotr_64`. All are removed and no longer compile. Also hand-rolled popcount loops or tables, and `(x << n) | (x >> (32 - n))`, which is undefined when `n` is 0 (C-5).
**Since**: `b76d72b20cc` (2026-05-25, Vas Crabb) for counts; `63c2ec0ccfe` (2026-08-03, AJR) for rotates
**Evidence**: [T3] both commits retire the `eminline.h` functions; [T2] `cxx.rst` § MAME-Specific Helpers lost its list in `e0adb59e6ad` and now refers only to `eminline.h` for mul/div; [T2] mame-review T-5, C-5; [T5] 15 files added in the last year use `<bit>` functions and none uses a removed helper. Deviation: only 5 of them include `<bit>` themselves; the rest get it through `emu.h` → `emucore.h`, which F-3 doesn't allow.
**Key symbols**: `std::countl_zero`, `std::countl_one`, `std::popcount`, `std::rotr`, `mulu_32x32_hi`

### Numeric constants and float helpers

**Do**

```cpp
#include "corefloat.h"
#include <cmath>
#include <numbers>
float const w = 2.0F * std::numbers::pi_v<float> * freq;
float const f = u2f(m_fpr[n]);                                  // u32 bits → float; f2u, u2d, d2u
double const u = std::cos(DEGREE_TO_RADIAN<double>(s_phase[i] + m_tint));   // int argument
```

`DEGREE_TO_RADIAN` and `RADIAN_TO_DEGREE` deduce `T` from the argument and use `std::numbers::pi_v<T>`, so an integer argument needs `<double>`. `double` code uses plain `std::numbers::pi`. `std::numbers` has no 1/√2 constant; write `std::numbers::sqrt2 / 2`. For other same-size type punning, use `std::bit_cast`. `corefloat.h` also provides `fpmod1` and `fmaprange`.

**Legacy forms**: `M_PI`, `M_SQRT2` and other `M_*` macros. They aren't standard C++, and `emucore.h` no longer defines a fallback. Also a local `#define PI 3.14159…`, `union { float f; u32 u; }` punning, and `*(float *)&x`. `u2f`/`f2u`/`DEGREE_TO_RADIAN` keep their names but used to come from `emu.h`; they now need `corefloat.h`.
**Since**: `bdf56c6ae80` (2026-05-29, AJR); `afd3f3da405` (2026-05-31, AJR) created `corefloat.h`; `f624932c2be` (2026-06-28) added `fpmod1` and `fmaprange`
**Evidence**: [T1] `src/lib/util/corefloat.h`: `constexpr` `u2f`…`d2u` on `std::bit_cast`; [T3] `bdf56c6ae80` replaced `M_PI` across `src/emu` and `src/devices`; [T2] mame-review T-4; [T5] files added in the last year: no `M_PI`; all 5 that use `std::numbers` include `<numbers>`
**Key symbols**: `u2f`, `f2u`, `u2d`, `d2u`, `DEGREE_TO_RADIAN`, `RADIAN_TO_DEGREE`, `fpmod1`, `fmaprange`

### Endianness and multibyte data

**Do**

```cpp
#include "endianness.h"   // util::big_endian_cast, util::little_endian_cast, BYTE_XOR_*, BYTE4_XOR_*
#include "multibyte.h"    // get_u16le, get_u32be, put_u32be, …
, m_program_config("program", ENDIANNESS_BIG, 16, 24)   // constructor: space configs keep the constants
u8 mydev_device::vram_r(offs_t offset) { return util::big_endian_cast<u8 const>(m_vram.get())[offset]; } // m_vram: unique_ptr<u16 []>
u32 const size = get_u32be(&header[4]);
```

`endianness_t` is an alias for `std::endian`. `ENDIANNESS_LITTLE`, `ENDIANNESS_BIG` and `ENDIANNESS_NATIVE` remain as constants of that type and are still what the space-config and `memory_access` code uses. `endianness_t` lost its save privilege, so `save_item` of one no longer compiles. Treat it as configuration, not state. Host-order checks are `if constexpr (std::endian::native == std::endian::little)` (or `ENDIANNESS_NATIVE`).

**Legacy forms**: `util::endianness::little`/`big`/`native`; `#ifdef LSB_FIRST` in device code (22 files on master); `PAIR`/`PAIR16` register unions in old CPU cores; `BYTE_XOR_LE` and friends reached through `emu.h` (they need `endianness.h` since `afd3f3da405`); `(buf[0] << 8) | buf[1]` (T-5); one buffer read as both `u8 *` and `u16 *` (C-5).
**Since**: `afd3f3da405` (2026-05-31, AJR); `multibyte.h` established (`5353a8df14d`, 2023-09-14)
**Evidence**: [T1] `src/emu/emucore.h` `using endianness_t = std::endian` plus the three constants; [T1] `src/lib/util/endianness.h` `static_assert` rejecting mixed-endian hosts; [T3] `afd3f3da405` removed `ALLOW_SAVE_TYPE_AND_VECTOR(endianness_t)`; [T2] mame-review T-5, C-5; [T5] 109 files added in the last year use `ENDIANNESS_*`, and 1 (`sgi/ip2.cpp`) passes `std::endian::big` as a template argument
**Key symbols**: `endianness_t`, `ENDIANNESS_NATIVE`, `BYTE_XOR_LE`, `big_endian_cast`, `little_endian_cast`, `get_u32be`, `put_u32be`

### Templates and constants under C++20

**Do**

```cpp
template <bool HasIdPage>
class mychip_device : public device_t
{
public:
	void set_id_page(int state) requires HasIdPage;   // only exists when HasIdPage
private:
	static constexpr unsigned FIFO_DEPTH = 16;      // not enum { FIFO_DEPTH = 16 };
};
```

An `enable_if` overload pair becomes two overloads with `requires X` and `requires (!X)` (`eeprom28.h` `storage_offset`); `std::enable_if` stays only for partial specialisation. C++20 deprecates arithmetic and comparison between two different enum types, or between an enum and a floating-point value. It also deprecates `++`, `--` and compound assignment on a `volatile`. These are warnings, which C-6 makes blocking. Make enum arithmetic explicit with `underlying_value(e)` (`std::to_underlying` is C++23 and unavailable). A `u8"…"` literal is `char8_t const *`; hold it in `auto` or `std::array`. `util::string_format` and friends accept it.

**Legacy forms**: `std::enable_if_t<…>` return types or defaulted template parameters (35 lines left in `src/devices` and `src/mame`); in-class `enum { FILTER_LENGTH = 64 };`; anonymous enums that mix bit numbers and masks and are used in arithmetic; `const char *s = u8"…"`.
**Since**: `b55ba81d2a4` (2026-03-29) and `b946df69fcc` (2026-05-29), both Vas Crabb
**Evidence**: [T3] `b946df69fcc` "Replaced most uses of enable_if with requires clauses… enable_if is still used for partial specialisation"; [T3] `b55ba81d2a4` converted `spkrdev.h`/`lc7535.h` enums to `static constexpr` and separated enum-enum and enum-float arithmetic; [T1] `src/lib/util/strformat.h` `launder_string` for `char8_t`; [T2] mame-review T-4, C-6; [T5] no `enable_if` in files added in the last year; `machine/eeprom28.h` (tidied by Vas Crabb, `d01a9db4135`) uses member `requires`
**Key symbols**: `underlying_value`, `enum_value`

### Headers emu.h no longer provides

**Do**

```cpp
#include "sound.h"          // machine().sound()        — src/emu group
#include "corefloat.h"      // u2f, DEGREE_TO_RADIAN    — src/lib/util group
#include "endianness.h"     // BYTE_XOR_*, util::big_endian_cast
#include "multibyte.h"      // get_u32be (never in emu.h)
```

Each goes in its F-3 group, sorted; so do `video.h` (`machine().video()`), `ioprocsstream.h` and every standard header you use (`<bit>`, `<numbers>`, `<cmath>`, `<algorithm>`). `input.h` (`machine().input()`) is for debug keys only, which `5193d37fa8b` discourages ("emulation code shouldn't be using it for anything besides debugging features, and even then it's not great"). `emucore.h` happens to include `<bit>` and `<cmath>`; F-3 still requires you to name them.

**Legacy forms**: calling `machine().sound()`, `machine().video()` or `machine().input()` with only `emu.h` included (fails to compile); a stray `#include "input.h"` with no input use (`bus/msx/ctrl/dual_joyport.cpp`, a T5 deviation).
**Since**: `5193d37fa8b` (2026-06-06, Vas Crabb) for `input.h`; `afd3f3da405` (2026-05-31) for `endianness.h`/`corefloat.h`; `6deb9130b69` (2026-07-30, AJR) for `sound.h`/`video.h`
**Evidence**: [T3] those three commits (`6deb9130b69` added `sound.h` to 43 files and `video.h` to 14); [T2] mame-review F-3, C-6
**Key symbols**: `sound_manager`, `video_manager`, `input_manager`

### Strings and file I/O

**Do**

```cpp
#include "ioprocsstream.h"
#include <locale>

emu_file file(m_dump_path, OPEN_FLAG_WRITE | OPEN_FLAG_CREATE | OPEN_FLAG_CREATE_PATHS);
if (!file.open(util::string_format("%s.txt", m_name)))
{
	util::owritestream str(file);
	str.imbue(std::locale::classic());
	util::stream_format(str, "PC=%08X SR=%04X\n", m_pc, m_sr);
	str << std::flush;
}
// in nvram_read(util::read_stream &file)
auto const [err, actual] = util::read(file, m_data.get(), m_size);
return !err && (actual == m_size);
```

`owritestream` translates line endings and writes UTF-8. Imbue the classic locale so numbers ignore the user's locale. For image devices, call `util::read`/`read_at(image_core_file(), …)` rather than `fread`/`fwrite`. The runtime floor is libstdc++/libc++ 11, which has no `std::format`, so use `util::string_format`. For building strings, see L-2.

**Legacy forms**: `file.puts(...)` and `file.printf(...)` on `emu_file`/`core_file` (removed); `fopen`/`fprintf` debug dumps; `size_t actual; file.read(buf, len, actual)`; `fread(...)` in image devices; `sprintf` into a `char` buffer (L-2).
**Since**: `1615b8551a3` (2024-02-25, Vas Crabb) for the `util::read` wrappers; `4bb0fa2bbc7` (2026-09-05, Vas Crabb) for `owritestream`
**Evidence**: [T1] `src/emu/diimage.h` above `fread`/`fwrite`: "TODO: move away from using these… FIXME: don't swallow errors"; [T1] `ioprocsstream.h` says "These classes are preliminary and may change substantially"; [T3] `4bb0fa2bbc7` converted `williams/midtunit_v.cpp`; [T2] `docs/source/initialsetup/compilingmame.rst` (GCC 11 / libstdc++ 11 floor); [T2] mame-review L-2, C-7; [T5] files added in the last year: no `sprintf`, 25 use `string_format`; [T2] `docs/source/initialsetup/compilingmame.rst` — runtime floor libstdc++ 11 / libc++ 11
**Key symbols**: `owritestream`, `stream_format`, `string_format`, `read_at`, `image_core_file`, `nvram_read`

## Superseded

- `cxx.rst` § MAME-Specific Helpers' advice that `count_leading_zeros_32/64`, `population_count_32/64`, `rotl/rotr_32/64` etc. were "strongly preferred" in performance-critical code: superseded by *Bit operations* in `b76d72b20cc` and `63c2ec0ccfe`; the text was removed in `e0adb59e6ad`.
- `util::endianness`, a saveable `endianness_t`, `emucore.h`'s `#ifndef M_PI` fallback and its union-based `u2f`/`f2u`: superseded by `std::endian`, `std::numbers` and `corefloat.h` in `afd3f3da405`. `emu_file::puts`/`printf`: superseded by `util::owritestream` in `4bb0fa2bbc7`.

## Examples

- `src/devices/cpu/palm/palm.cpp` @ `8089ec90d35`: `<bit>` in its own standard-library group, and `7 - std::countl_one(...)` on a `u8` read, counting within 8 bits. Deviation: `//#define VERBOSE (LOG_GENERAL)` instead of `#define VERBOSE (0)`.
- `src/devices/video/tea1002.cpp` @ `afd3f3da405`: includes `corefloat.h` for `DEGREE_TO_RADIAN<double>`, with the explicit type that an `int` argument needs. Deviation: unqualified `cos`/`sin`, with `<cmath>` reached only through `corefloat.h` (F-3).
