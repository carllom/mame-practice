# Save states

Registering device and driver state with the save system, rebuilding derived state after load, and declaring incomplete support. mame-review rules that govern it: C-2 (the save-state rule), C-3 (register in start), C-8 (`MACHINE_SUPPORTS_SAVE` tells the truth), T-6 (`make_unique_clear` buffers).

## TL;DR

- Register everything in `device_start`/`machine_start` with `save_item(NAME(m_x))` — one call covers a scalar, a C array, a 2-D array, a `std::array` or an `attotime`.
- Arrays of structs: one `save_item(STRUCT_MEMBER(m_arr, field))` per field, no index loops.
- Saved enums: `enum class x : u8`, plus `ALLOW_SAVE_TYPE(cls::x);` at file scope in the .cpp.
- Rebuild derived state (pointers, caches, dynamic mappings) in a `device_post_load()` override, not `register_postload`.
- A device that can't save yet returns `flags::SAVE_UNSUPPORTED` from `emulation_flags()`; systems using it lose `MACHINE_SUPPORTS_SAVE`.

## Rules

### Registering state

**Do**

```cpp
struct channel { u16 addr; u8 vol[2]; bool active; };  // in the class
u8 m_regs[4][16];
channel m_ch[8];  attotime m_last_edge;

void mydev_device::device_start()
{
	save_item(NAME(m_regs));                // 2-D array: one entry
	save_item(STRUCT_MEMBER(m_ch, addr));
	save_item(STRUCT_MEMBER(m_ch, vol));    // array members work too
	save_item(STRUCT_MEMBER(m_ch, active));
	save_item(NAME(m_last_edge));           // attotime (and arrays of it)
}
```

What C-2 lists stays in force: every live member, explicitly sized types (`int` members are Tidy), no saved containers. A device that throws `device_missing_dependencies` must throw it before its first `save_item`, or the restarted `device_start` registers twice. A duplicate name is a fatal error when registration closes. A lone struct is saved field by field (`save_item(NAME(m_blitter.x))`), because only atoms are accepted.

**Legacy forms**: `for (int i ...) save_item(NAME(m_ch[i].addr), i);` (Vas Crabb replaced these with `STRUCT_MEMBER` in `ed77088c171`); `save_item(m_x, "m_x")` written out where `NAME` would do; `state_save_register_global(machine, x)` / `state_save_register_item(machine, "mod", tag, 0, x)` (removed by `0894a05722b`, 2015-04-23); a driver calling `machine().save().save_item(...)`, which registers under `global` rather than the device (`src/mame/gaelco/gaelco3d_v.cpp`); attotime arrays saved element by element (before `9b582574922`).
**Since**: `STRUCT_MEMBER`: `e6b4cdb3527` (2019-12-09), including n-dimensional arrays and array members; attotime arrays: `9b582574922` (2020-09-14)
**Evidence**: [T1] `src/emu/save.h` — `array_unwrap` recurses through C arrays and `std::array`, the `is_atom` constraint, attotime specialisations; [T1] `src/emu/save.cpp` `save_memory` — throws once registration is closed; [T1] `src/emu/device.h` `device_start` — "This is the correct place to register for save states"; [T2] mame-review C-2, C-3; [T5] new files: `STRUCT_MEMBER` in 14 files, index loops in 2 (`nscsi_hle.cpp`, `matsushita/wsa1_tonegen.cpp`)
**Key symbols**: `save_item`, `NAME`, `STRUCT_MEMBER`, `attotime`

### Enums

**Do**

```cpp
// mydev.h, inside the class
enum class phase : u8 { IDLE, COMMAND, DATA };
phase m_phase;

// mydev.cpp, after DEFINE_DEVICE_TYPE
ALLOW_SAVE_TYPE(mydev_device::phase);
```

`ALLOW_SAVE_TYPE` specialises `save_manager::is_atom`, so it sits at namespace scope; it works for a private enum. Without it `save_item(NAME(m_phase))` fails the constraint at compile time.

**Legacy forms**: `int m_state` holding enum values; `typedef enum { ... } state_t;` (no fixed underlying type); `ALLOW_SAVE_TYPE_AND_ARRAY` (renamed `ALLOW_SAVE_TYPE_AND_VECTOR` in `9b582574922`). Both `ALLOW_SAVE_TYPE(x);` and `ALLOW_SAVE_TYPE(x)` compile; on master the first is more common, 92:24.
**Since**: established (`ALLOW_SAVE_TYPE` predates `543fa08fd0f`, 2011)
**Evidence**: [T1] `src/emu/save.h` — `ALLOW_SAVE_TYPE` doc: "specific enum types that have fixed width integer types as their storage classes"; [T2] mame-review C-2; [T5] 7 new files use it
**Key symbols**: `ALLOW_SAVE_TYPE`, `ALLOW_SAVE_TYPE_AND_VECTOR`

### Heap buffers and bitmaps

**Do**

```cpp
static constexpr unsigned FIFO_SIZE = 4096;
std::unique_ptr<u16 []> m_fifo;
bitmap_rgb32 m_page;    // the printed page is emulated state

m_fifo = make_unique_clear<u16 []>(FIFO_SIZE);
save_pointer(NAME(m_fifo), FIFO_SIZE);          // count in elements
save_pointer(STRUCT_MEMBER(m_voices, pos), m_voice_count);  // unique_ptr<voice []>
m_page.allocate(PAGE_W, PAGE_H);
save_item(NAME(m_page));
```

Registration records the address, so allocate first and never reallocate or resize afterwards. Memory a CPU sees belongs in a `memory_share_creator`, which saves itself (mame-review D-6), not `make_unique` plus `save_pointer`. Only save a bitmap whose contents are state that can't be redrawn from saved data; a screen-sized render cache stays out (C-2).

**Legacy forms**: `m_buf = new u8[size];` or `std::vector` resized in start, then `save_pointer(m_buf, "buf", size)` (T-6); `save_pointer(NAME(m_buf.get()), n)` (the `.get()` is redundant since `b3afc83bde1`).
**Since**: `std::unique_ptr` overload `b3afc83bde1` (2018-06-17, AJR); `STRUCT_MEMBER` with `save_pointer` `d27918db8c5` (2019-12-09)
**Evidence**: [T1] `src/emu/save.h` — `save_pointer` overload for `const std::unique_ptr<ItemType []> &`, `save_item` overloads for `bitmap_ind8/16/32` and `bitmap_rgb32`; [T1] `src/emu/device.h` `save_item` — a `std::vector` "must not be resized after being registered" (a fixed vector compiles, but T-6 and C-2 still want `unique_ptr`); [T2] mame-review C-2, T-6, D-6
**Key symbols**: `save_pointer`, `make_unique_clear`, `memory_share_creator`

### What saves itself, and rebuilding the rest

**Do**

```cpp
void mydev_device::device_post_load()
{
	m_rom_ptr = &m_rom[m_rom_page << 14];   // derived from saved m_rom_page
	update_map();                           // dynamic installs aren't saved
}
```

Already saved without registration: `emu_timer`s (state is saved, so allocate them in start), memory banks (current entry), memory views (selected slot, refreshed after load), memory shares and `.ram()` map entries, `output_finder` values, the device clock, a CPU's own registers and the execute state, screen timing, palettes, and every child device. Not saved: memory regions, handlers installed at run time, and pointers. Declare the override `virtual void device_post_load() override ATTR_COLD;`; a derived class calls its base (C-3).

**Legacy forms**: `machine().save().register_postload(save_prepost_delegate(FUNC(cls::fn), this));` in `device_start`/`machine_start`. AJR (`1f7ff8fd9a3`, `da117d528ba`) and Vas Crabb (`97b67170277`, 77 overrides added) converted these; it still appears in new code (`src/mame/apple/civic.cpp`, `src/mame/bfm/bfm_cobra3.cpp`). `register_postload` is still right for non-device objects (`memory_view`, managers).
**Since**: `device_post_load` established (in `device.h` by `cd1c840ba49`, 2011); register_postload conversions from 2018
**Evidence**: [T1] `src/emu/device.h` `device_post_load` — "update or invalidate caches, or de-serialise pointers"; [T1] `src/emu/schedule.cpp`, `emumem.cpp` (`memory_bank`, `allocate_memory`), `emumem_mview.cpp`, `output.cpp`, `diexec.cpp` register their own state; [T2] `docs/source/techspecs/memory.rst` — shares saved, regions not, dynamic mappings "have to be rebuilt after state load"; [T2] mame-review C-2, C-3; [T5] new files: `device_post_load` in 23, `register_postload` in 3 (master: 145 vs 49)
**Key symbols**: `device_post_load`, `device_pre_save`, `register_postload`, `save_prepost_delegate`

### Saving from an interface mixin

**Do**

```cpp
void device_mybus_card_interface::interface_post_start()
{
	device().save_item(NAME(m_irq_state));
}
```

Rebuild derived state in `interface_post_load()`, which runs before the device's `device_post_load()`. Register in `interface_post_start`, not `interface_pre_start`, which may run more than once. Names share the host device's namespace, so a mixin member can't reuse a name the device saves. A plain helper object holding a `device_t &` registers through it, passing an `index` when there are several instances.

**Legacy forms**: `device().machine().save().save_item(...)` (registers globally, not under the device).
**Since**: established (`diexec.cpp` uses `device().save_item(STRUCT_MEMBER(...))` since `d27918db8c5`)
**Evidence**: [T1] `src/emu/device.h` `interface_pre_start` — "It's simpler to register for save states when #interface_post_start is called"; [T1] `src/emu/diexec.cpp`, `diserial.cpp`, `dipalette.cpp` `interface_post_start`
**Key symbols**: `interface_post_start`, `interface_post_load`, `device_interface`

### Declaring incomplete support

**Do**

```cpp
class mydev_device : public device_t
{
public:
	static constexpr flags_type emulation_flags() { return flags::SAVE_UNSUPPORTED; }
	// constructor and the rest follow
```

A system without `MACHINE_SUPPORTS_SAVE` is itself `SAVE_UNSUPPORTED` (`game_driver::emulation_flags`). `-validate` reports a system that claims `MACHINE_SUPPORTS_SAVE` while containing a `SAVE_UNSUPPORTED` device; slot cards and their children are exempt. At run time any such device, cards included, disables autosave and adds "not officially supported" to the save/load message. A device with `device_execute_interface` that registers nothing is a fatal error unless flagged. Placement at the very top of the class: mame-review D-3.

**Legacy forms**: leaving the device unflagged and relying only on the system omitting `MACHINE_SUPPORTS_SAVE`; commented-out `save_item`s (C-2).
**Since**: `f0e38cbe5be` (2025-05-01, Vas Crabb; first user `mc6852.h`)
**Evidence**: [T1] `src/emu/device.h` `device_flags::SAVE_UNSUPPORTED`; [T1] `src/emu/gamedrv.h` `MACHINE_SUPPORTS_SAVE` — "All devices in the system supports save states"; [T1] `src/emu/validity.cpp`, `save.cpp`, `machine.cpp`, `device.cpp` (`device_t::start`); [T2] mame-review C-2, C-8; [T5] 11 device types on master, 5 in new files
**Key symbols**: `SAVE_UNSUPPORTED`, `emulation_flags`, `flags_type`, `MACHINE_SUPPORTS_SAVE`

## Superseded

- `state_save_register_*` functions, superseded by `device_t::save_item` and removed in `0894a05722b` (2015-04-23).
- Index loops over arrays of structs, superseded by `STRUCT_MEMBER` in `e6b4cdb3527` (2019-12-09); `ALLOW_SAVE_TYPE_AND_ARRAY`, renamed `ALLOW_SAVE_TYPE_AND_VECTOR` in `9b582574922` (2020-09-14).
- `register_postload` from devices and drivers, superseded by `device_post_load` (conversions `1f7ff8fd9a3` 2018, `97b67170277` 2019).

## Examples

- `src/mame/igs/igs011_video.cpp` @ `5193d37fa8b` — Vas Crabb-tidied device: layer and priority RAM are `memory_share_creator`s (no registration), scalars by `NAME`, and `device_post_load` re-installs a dynamic protection mapping.
- `src/mame/apple/mesh.cpp` @ `f7440868a3e` — R. Belmont: `enum class sequence_state : u8` with `ALLOW_SAVE_TYPE`, timer allocated in start and not registered, C array by `NAME`; deviation: saves `int` line-state members (C-2 Tidy).
