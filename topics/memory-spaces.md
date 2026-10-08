# Memory spaces

Device address spaces and access beyond plain map entries: device maps, space configs, fast access, `device_rom_interface`, MMU logical spaces, wait states and bus contention, and taps. Map entries themselves are in [address-maps](address-maps.md). mame-review rules that govern it: D-6 (the memory rule), D-2 (`ATTR_COLD` on maps and `memory_space_config()`), D-13 (expose spaces debuggers need).

## TL;DR

- Export register blocks as a device map and let the host install it with `.m(m_dev, FUNC(dev::map))`.
- Declare spaces in `memory_space_config()` returning a `space_config_vector`; cache `memory_access<…>::specific`/`cache` in start for hot paths.
- A chip that fetches samples or data from ROM derives from `device_rom_interface<…>` and reads with `read_byte()`/`read_word()`.
- Model wait states with `.before_time`/`.before_delay`/`.after_delay` on the map entry; a handler that pulls WAIT asserts the line and calls `retry_access()`.
- Observe accesses without replacing the handler with `install_read_tap`/`install_write_tap`.

## Rules

### Device maps, device spaces and fast access

**Do**

```cpp
map(0x00c0, 0x00c7).m(m_fdc, FUNC(upd72069_device::map));     // host installs the device's register map
address_space_config m_ram_config;            // m_ram_config("ram", ENDIANNESS_LITTLE, 16, 24, -1)
memory_access<24, 1, -1, ENDIANNESS_LITTLE>::specific m_ram;   // addr bits, log2 bytes, shift, endian
device_memory_interface::space_config_vector l6009_device::memory_space_config() const
{ return space_config_vector { std::make_pair(AS_ROM, &m_rom_config), std::make_pair(AS_RAM, &m_ram_config) }; }
void l6009_device::device_start() { space(AS_RAM).specific(m_ram); space(AS_ROM).cache(m_rom); }
```

From `src/devices/sound/l6009.cpp`. `specific()`/`cache()` check the parameters against the space config at start. The host attaches a map with `set_addrmap(AS_…, &host::map)`; `has_configured_map()` tests an optional space; `remove_addrmap(AS_…)` drops one inherited from a base configuration. A CPU behind an MMU also overrides `memory_logical_space_config()` and resolves addresses in `memory_translate(spacenum, intention, address, target_space)`, so the debugger works in logical addresses (first user: `m68000_device`).

**Legacy forms**: each host listing a device's registers one by one; `DEVICE_ADDRESS_MAP_START`; `memory_space_config(address_spacenum spacenum)` returning one config per call (before 2017); `space(AS_PROGRAM).read_word(…)` in a hot path (D-6); pointer-returning `space.cache<0, 0, ENDIANNESS_LITTLE>()` before `22513fb6fe2`; `set_addrmap(AS_IO, address_map_constructor())` to drop a map.
**Since**: `space_config_vector` `536b2153d99` (2017-07-10); `memory_access` `22513fb6fe2` (2020-05-25); logical spaces `63a40168225` (committed 2026-01-07, O. Galibert); `remove_addrmap` `db1e21d2dcf` (2026-04-29, hap)
**Evidence**: [T1] `src/emu/dimemory.h` — `space_config_vector`, `has_configured_map`, `remove_addrmap`, `memory_logical_space_config`; [T1] `src/emu/emumem.h` — `struct memory_access`, `check_parameters`; [T2] `device_memory_interface.rst`; `memory.rst` §4.3.9; [T2] mame-review D-6, D-2; [T5] 17 new files use `memory_access`
**Key symbols**: `memory_space_config`, `space_config_vector`, `address_space_config`, `set_addrmap`, `remove_addrmap`, `memory_access`, `memory_logical_space_config`, `memory_translate`, `specific`, `cache`

### ROM-reading devices: `device_rom_interface`

**Do**

```cpp
class mysnd_device : public device_t, public device_sound_interface, public device_rom_interface<22>   // 22 address bits, 8-bit data
// sample fetch: u8 const s = read_byte(m_addr);
// host machine config, one of:
	MYSND(config, m_snd, 16.9344_MHz_XTAL);                    // ROM region named after the device (default)
	m_snd->set_device_rom_tag("samples");                      // a differently named region
	m_snd->set_map(&mysys_state::snd_rom_map);                 // an address map (banked or mirrored ROM)
	m_snd->set_space(DEVICE_SELF, AS_DATA);                    // an existing space of another device
```

Bank switching goes through `set_rom_bank(n)`; override `rom_bank_pre_change()` to bring a stream up to date first (see sound-streams).

**Legacy forms**: `required_region_ptr<u8>` plus manual masking in each chip; per-chip `set_rom_tag`-style setters.
**Since**: established; `set_space` `6bccd589c1a` (2024-03-18, O. Galibert)
**Evidence**: [T1] `src/emu/dirom.h` — `template<int AddrWidth, int DataWidth = 0, int AddrShift = 0, endianness_t Endian = ENDIANNESS_LITTLE> class device_rom_interface`, `set_map`, `set_device_rom_tag`, `set_space`, `read_byte`, `read_word`, `set_rom_bank`, `rom_bank_pre_change`; [T5] 50 files derive from it, e.g. `src/devices/sound/gew.h`
**Key symbols**: `device_rom_interface`, `set_device_rom_tag`, `set_space`, `read_byte`, `read_word`, `set_rom_bank`, `rom_bank_pre_change`

### Wait states and bus contention

**Do**

```cpp
// 68000 peripheral on VPA/E: synchronise to the E clock, then add the cycle cost
map(0xe8'0000, 0xef'ffff).before_time(m_maincpu, FUNC(m68000_device::vpa_sync)).after_delay(m_maincpu, FUNC(m68000_device::vpa_after))
	.rw(FUNC(mac128_state::mac_via_r), FUNC(mac128_state::mac_via_w));

// a device that pulls WAIT until it is ready
if (!ready)
{
	m_maincpu->set_input_line(Z80_INPUT_LINE_WAIT, ASSERT_LINE);
	m_maincpu->retry_access();          // the access is repeated once WAIT is released
	return 0;
}
```

The map handlers (`before_time(offs_t, u64 current_time)` returning the access time, `before_delay(offs_t)` and `after_delay(offs_t)` returning cycles) work only on interruptible cores (`cpu_is_interruptible()`: m68000, h8, the 6502 family). At run time: `install_readwrite_before_time(start, end, ws_time_delegate(…))`. `retry_access()` is for a WAIT line; `defer_access()` is for an access that waits on an external event, such as a latch a timer fills. `cpu_device.rst` warns that a retry nobody releases livelocks.

**Legacy forms**: `defer_access()` for WAIT-line stalls (converted in `b7a20d44933`: `savant.cpp`, `docastle_m.cpp`); `m_maincpu->adjust_icount(-n)` in handlers (73 files in `src/mame`).
**Since**: contention docs `793de967753` (2024-05-14, O. Galibert); `retry_access` `b7a20d44933` (2024-11-16, hap), documented in `5e63771946a`
**Evidence**: [T1] `src/emu/addrmap.h` — `before_time`, `before_delay`, `after_delay`; [T1] `src/emu/devcpu.h` — `cpu_is_interruptible`, `access_before_time`, `defer_access`, `retry_access`; [T2] `memory.rst` §3.5, §4.5; `cpu_device.rst` §3.4; [T5] `mac128.cpp`, `atarist.cpp` (map); `stmmu.cpp`, `sixtrak.cpp` (run time); `lux10828.cpp`, `cbmiec.cpp` (`retry_access`); [T2] `memory.rst` §4 lists `.contention()` last in the chain, but in-tree users put it before the handler; mame-review: not covered
**Key symbols**: `before_time`, `before_delay`, `after_delay`, `ws_time_delegate`, `retry_access`, `defer_access`, `cpu_is_interruptible`, `vpa_sync`, `vpa_after`

### Taps

**Do**

```cpp
memory_passthrough_handler m_tap;                 // member, so it can be removed later
void mysys_state::machine_start()
{
	m_tap = m_maincpu->space(AS_PROGRAM).install_read_tap(0x0000, 0xffff, "opcode_tap",
			[this] (offs_t offset, u8 &data, u8 mem_mask) {   // u8 for an 8-bit space if (!machine().side_effects_disabled()) m_last = data; },
			&m_tap);
}
```

A tap observes (and may modify `data`) without replacing the handler. `m_tap.remove()` drops it. Installing a handler over the range later loses the tap, so reinstall from an address-space change notifier where that happens. Install taps in `machine_start` (C-3; [T4] #16352 flagged an `install_read_tap` placed elsewhere in `mitchell.cpp`).

**Legacy forms**: replacing a handler with a wrapper that calls the original.
**Since**: documented in `793de967753` (2024-05-14); the API is older
**Evidence**: [T1] `src/emu/emumem.h` — `install_read_tap`, `install_write_tap`, `install_readwrite_tap`, `memory_passthrough_handler::remove`; [T2] `memory.rst` §5.11; [T5] 114 files install taps (`acorn/aa310.cpp`, `acorn/accomm.cpp`)
**Key symbols**: `install_read_tap`, `install_write_tap`, `install_readwrite_tap`, `memory_passthrough_handler`

## Superseded

- `defer_access()` for WAIT lines — superseded by `retry_access()` in `b7a20d44933`.

## Examples

- `src/mame/apple/mac128.cpp` @ `0de3f3e47eb` — VPA contention on the VIA range in all three map variants.
- `src/devices/bus/abcbus/lux10828.cpp` @ `832778ed63c` — `fdc_wait()` asserts `Z80_INPUT_LINE_WAIT` and calls `retry_access()` until the FDC raises INTRQ or DRQ.
