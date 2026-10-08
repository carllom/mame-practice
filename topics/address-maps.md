# Address maps and memory views

Address map entries, handler signatures, run-time mapping (views, banks, shares, `install_*`), and the `offs_t` width. Device maps, space configs, fast access, `device_rom_interface`, wait states and taps are in [memory-spaces](memory-spaces.md). mame-review rules that govern it: D-6 (the memory rule), D-1 (finders in maps), C-3 (installs and `configure_entries` in start), C-5 (`mem_mask`), D-2 (`ATTR_COLD` on maps).

## TL;DR

- Write each entry as range, `.mirror()`, `.umask*()` at full width, `.cswidth()`, then the handler; give handlers the narrowest signature and `offs_t` offsets.
- Switch mappings at run time with `memory_view` (`select()`/`disable()`); use a `memory_bank` (`configure_entries`/`set_entry`) for a plain window onto a region.
- Install what configuration fixes (RAM size, cartridge present) once in `machine_start`.
- Keep addresses in `offs_t`, everything else in fixed-width types, and never pass `offs_t` through C varargs: the 64-bit migration has started.

## Rules

### Map entries, handlers and lambdas

**Do**

```cpp
void mysys_state::main_map(address_map &map)
{
	map(0x20'0000, 0x20'001f).mirror(0x00'ffe0).umask16(0x00ff).rw(m_duart, FUNC(mc68681_device::read), FUNC(mc68681_device::write));
	map(0x30'0000, 0x30'0001).w(FUNC(mysys_state::control_w));
	map(0x30'0002, 0x30'0003).lr16(NAME([this] () -> u16 { return m_irq ? 0x8000 : 0; }));
}

void mysys_state::control_w(offs_t offset, u16 data, u16 mem_mask) { COMBINE_DATA(&m_control); }
```

Handler forms run from `(space, offset, mem_mask)` down to `()`/`(data)`; none is `(data, mem_mask)`, so a write that honours `mem_mask` (C-5) keeps `offset`. Lambdas (`lr8`…`lr64`, `lw…`, `lrw…(r, "r_name", w, "w_name")`) accept the same forms, named by `NAME(…)` or a trailing string.

**Legacy forms**: `ADDRESS_MAP_START`/`AM_RANGE(…) AM_READWRITE(…)`; `READ8_MEMBER(x)`/`DECLARE_WRITE16_MEMBER(x)` with implicit `space, offset, mem_mask`; name-first `.lr8("name", [this](…) {…})`; `.rw(…).umask16(0x00ff)` (addressing after the handler); `umask32(0xff)` (replicated to `0x00ff'00ff`); `u32 offset` parameters.
**Since**: member-function maps `c5219643162` (2018-02-01); `AM_` macros removed `9ac8320ccce` (2018-04-21); narrow forms `639c9b85fc2` (2018-08-02); `READ8_MEMBER` retired `57cf17dc52b` (2020-06-18); lambda name last `f81fbdb8d43` (2019-10-26)
**Evidence**: [T1] `src/emu/emumem.h` — `read8_delegate` … `write64smo_delegate` define the forms; [T1] `src/emu/addrmap.h` — `lr8(T &&read, const char *name)`; [T2] `memory.rst` §4.3.1, §4.3.3, §4.4.4 (narrow umask replicates); §4.4.5 shows `.cselect(…)` but the method is `cswidth`; [T2] mame-review D-6, C-5; [T5] new files write umask full width 178:28 and put addressing first about 2:1 (303:154 entries; `src/mame/akai/s3000.cpp` appends it); deviation: only 75 of 643 read lambdas declare `-> uNN`, which D-6 asks for
**Key symbols**: `umask16`, `umask32`, `umask64`, `cswidth`, `mirror`, `COMBINE_DATA`, `lr8`, `lw8`, `lrw8`, `read8smo_delegate`

### Switch mappings with `memory_view`

**Do**

```cpp
memory_view m_ipl_view;                       // member; constructor: m_ipl_view(*this, "ipl_view")

map(0x0000, 0xffff).ram();                    // in mem_map
map(0x0000, 0xffff).view(m_ipl_view);
m_ipl_view[0](0x0000, 0x03ff).mirror(0xdc00).rom().region("ipl", 0);

void mysys_state::machine_reset() { m_ipl_view.select(0); }
void mysys_state::ipl_disable_w(u8 data) { m_ipl_view.disable(); }
```

A view starts disabled (the map underneath shows through), saves its own state, and `select()` of an unconfigured slot is fatal. Only `.mirror()` may qualify the `.view()` entry; a view is placed once. A view entry also takes `install_*` calls (`m_view[0].install_ram(…)`). `m_view.exists()` tells whether the view was placed in a map (`1949b85c815`, 2024-08-14).

**Legacy forms**: `address_map_bank_device` (`bankdev.h`, `ADDRESS_MAP_BANK`, `set_bank()`); several `membank("bankN")` switched together (rewritten in `19e538c2834`); uninstalling and reinstalling handlers to swap an overlay.
**Since**: `574daf4e49e` (2020-11-12)
**Evidence**: [T1] `src/emu/emumem_mview.cpp` — `memory_view::select`, `register_state`; [T2] `memory.rst` §3.4, §4.6, §5.10; [T2] mame-review D-6; [T5] 28 new files use views; deviation: 5 still add `address_map_bank_device` (`src/mame/akai/s900.cpp`, `src/mame/misc/wren.cpp`)
**Key symbols**: `memory_view`, `memory_view_entry`, `select`, `disable`, `install_view`, `exists`

### Banks for windows onto a region

**Do**

```cpp
required_memory_bank m_rombank;               // created by the map entry; constructor: m_rombank(*this, "rombank")
map(0x4000, 0x7fff).bankr(m_rombank);
void mysys_state::machine_start() { m_rombank->configure_entries(0, 4, memregion("banked")->base(), 0x4000); }
void mysys_state::bank_w(u8 data) { m_rombank->set_entry(data & 3); }
```

Use `memory_bank_creator` when no map entry names the bank (`install_read_bank` at start). Banks save themselves. ROM is `bankr`, never `bankrw` (D-6).

**Legacy forms**: `membank("bank1")->…` in handlers (D-1); `.bankrw("bank1")` by tag; `set_base()` on every switch; `AM_ROMBANK`.
**Since**: `memory_bank_creator` `b8c338858a1` (2020-11-02)
**Evidence**: [T1] `src/emu/devfind.h` — `memory_bank_creator` "Creates a memory bank or finds an existing one instantiated via an address map"; [T2] `memory.rst` §3.2; [T2] mame-review D-6, D-1, C-3; [T5] 13 new files use `required_memory_bank`, 5 `memory_bank_creator`; every `->set_base(` in new files (17 files) is `nvram_device::set_base`, a different API
**Key symbols**: `memory_bank_creator`, `required_memory_bank`, `configure_entries`, `set_entry`, `bankr`

### Shares and run-time installs

**Do**

```cpp
required_shared_ptr<u16> m_vram;              // m_vram(*this, "vram"): created by .share() below
memory_share_creator<u8> m_sram;              // m_sram(*this, "sram", 0x2000, ENDIANNESS_LITTLE): sized to the part

map(0x20'0000, 0x20'7fff).ram().share(m_vram);
void mysys_state::machine_start()
{
	address_space &program = m_maincpu->space(AS_PROGRAM);
	program.install_ram(0x0000, m_ram->size() - 1, m_ram->pointer());    // ram_device: user-selectable size
	program.install_ram(0x30'0000, 0x30'1fff, m_sram.target());
	if (m_cart->exists())
		program.install_read_handler(0x8000, 0xbfff, emu::rw_delegate(m_cart, FUNC(generic_slot_device::read_rom)));
}
```

**Legacy forms**: `std::make_unique<u8[]>` plus `save_pointer` for CPU-visible RAM; `install_read_handler(…, read8_delegate(*this, FUNC(x)))` (still common); `read8_delegate(FUNC(x), this)`; `install_*` in `machine_reset` or `init_*` (C-3, D-11).
**Since**: `memory_share_creator` `b8c338858a1` (2020-11-02); `emu::rw_delegate` `c4a9a22eb19` (2023-04-11)
**Evidence**: [T1] `src/emu/emumem.h` — `emu::rw_delegate` overload taking a `device_finder`; [T2] `memory.rst` §3.1, §5; [T2] mame-review D-6, C-3, D-1; [T5] 37 new files use `memory_share_creator`; `emu::rw_delegate` (15 files) and explicit `readN_delegate(…)` (11+) are about even
**Key symbols**: `memory_share_creator`, `required_shared_ptr`, `install_ram`, `install_read_handler`, `rw_delegate`

### `offs_t` width

**Do**

```cpp
void external_write(offs_t address, u32 data);                 // a bus address: offs_t
LOGMASKED(LOG_BUS, "%s: read %08x\n", machine().describe_context(), offset);   // type-safe, not printf
auto const idx = bitswap<4>(unsigned(offset), 8, 5, 2, 1);     // narrow explicitly
if (a == std::clamp<offs_t>(a, 0xf0'0000, 0xf0'0fff))
```

`offs_t` is still `u32` on master; `5446223573f` began the move to 64 bits (PR #15295, open). What breaks: `printf`/`sscanf("%x", &addr)` varargs, brace-init narrowing (`unsigned i{offset}`), `std::min`/`std::clamp` mixing `offs_t` with `u32`. Lengths and counts get fixed widths (`u32 length`), not `offs_t`.

**Legacy forms**: `uint32_t address` for bus addresses; `printf("%08x", m_maincpu->pc())`; `verboselog(…)` built on `vsprintf`.
**Since**: `5446223573f` (2026-07-21) — after mame-review's snapshot, which doesn't mention it
**Evidence**: [T1] `src/emu/emumem.h` — "offsets and addresses are 32-bit (for now...)"; [T3] `5446223573f` (Vas Crabb, Ryan Holtz) — `std::clamp<offs_t>` in `jaguar.cpp`, `unsigned(offset)` in `funworld.cpp`, `offs_t` → `uint32_t` for a length in `hp9845_optrom.cpp`, `printf` → `util::stream_format`/`LOGMASKED`
**Key symbols**: `offs_t`

## Superseded

- `address_map_bank_device` for software-switched maps — superseded by `memory_view` in `574daf4e49e`.
- `AM_RANGE`/`ADDRESS_MAP_START` — superseded by member-function maps in `c5219643162`, removed in `9ac8320ccce`.
- `READ8_MEMBER`/`DECLARE_READ8_MEMBER` — superseded by narrow handler forms in `639c9b85fc2`, removed in `57cf17dc52b`.

## Examples

- `src/mame/altos/altos8000.cpp` @ `98eecf09f82` — boot ROM overlay as a view: `select(0)` in `machine_reset`, `disable()` from a port write.
- `src/mame/sgi/ip2.cpp` @ `afd3f3da405` — `memory_share_creator`, two views (one placed by `install_view` at first reset), `memory_access<…>::specific`, `.m()` submaps, `emu::rw_delegate`; deviations: `.m(…).mirror(…)` puts addressing after the handler, several read lambdas lack `-> uNN`, `.share("nvram")` uses a tag.
