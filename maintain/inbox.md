# Inbox

Findings with no topic yet. Each: one line of practice, evidence (tier + hash), and the topic it might belong to.

## Practice

- `device_delegate` (unlike devcb) still needs `resolve()`/`resolve_safe()` — every `.resolve()` in a file added in the last year is on a delegate. [T1] `src/emu/devdelegate.h`. → delegates topic
- `attotime` members go straight into `save_item`; a counter's start time is the usual live state to save. [T1] `src/emu/save.h`. → save-states
- `set_periodic_int`, `INTERRUPT_GEN_MEMBER`, `irqN_line_hold` are not `[[deprecated]]` (885 + 597 uses on master) though mame-review C-9 effectively forbids them in new code. → watch for a core deprecation

- `nvram_device::set_base(ptr, size)` in start (17 files added in the last year) — distinct from the `memory_bank::set_base` D-6 forbids; needs coverage. → nvram / address-maps
- `5446223573f` (Vas Crabb) replaced ad-hoc `printf` with `util::stream_format(std::cout/std::cerr, …)` in next.cpp, vboy.cpp, viper.cpp, stic.cpp — check against mame-review L-1, which bans `std::cout` in `src/devices`/`src/mame`. → logging
- C-3's "one-shot install at first reset guarded by a flag" exception has a real example: `src/mame/sgi/ip2.cpp` installs a view at first reset because the slave address comes from a DIP switch. → address-maps example

- **ROM definitions**: `ROM_OPTIONAL` is `[[deprecated]]` (`e6bc966bed6`, 2026-02-03); `romentry.h` macros are now `constexpr` with unchanged spelling. T1 backing for mame-review I-5.
- **Video — tilemaps and palette**: row+column scroll together (`6b335b5475a`); custom scrolling via `set_blitter_callback` / `TILE_BLITTER_MEMBER` (`78f4e7c3ee6`); `TILE_LINE_DISABLED` removed — clip with cliprect; `enable_hilights()` → `enable_highlights()` and the palette saves its own shadow/highlight state (`72251989ad8`); `DRAWMODE_SHADOW_PRI` (`fe086b54cd0`). → video topic
- **Layouts** (data files): elements/groups must precede use, views no longer processed last (`0480c0384e2`); `align="3"` stretches text (`42e4078725d`); text uses the artwork font, leave room for wide fonts (`3b565c05d0f`). [T2] `layout_files.rst`.
- **DRC/UML**: `uml_instructions.rst` is now a full reference (2025-09..2026-02); `UML_BFXU/BFXS/DBFXU/DBFXS` (`8a74b97658c`) replace shift+mask; `UML_CALLHc(block, cond, handle)` order; no HASH in invariant blocks. → CPU-core topic

- **Floppy controllers**: `write_start`/`write_flux_change`/`write_flush`/`write_end` replace `write_flux(...)` (`c690a9ed43f`, 38 controllers; `floppy.rst`).
- **Layouts**: `<reel>` components removed (`e509909bd59`); reels are elements with `yscroll`/`xscroll` (`e28f04501d7`, 348 files).
- **CPU cores**: `state_add(index, string_format(...), data)` without `.c_str()` (`8089ec90d35`); UML `CALLC` takes a single `T *`/`T &` (`1f7fa43c3d2`).

- **System flags**: `MACHINE_IS_SKELETON[_MECHANICAL]` removed (`7a755b7d73f`) — write `MACHINE_NO_SOUND | MACHINE_NOT_WORKING`; `MACHINE_CLICKABLE_ARTWORK` removed (`4980f881393`) — pointers follow the layout, `<view showpointers>` overrides.
- **CPU cores** (more): `execute_input_lines()`/`execute_burn()` overrides removed (`b8889905639`, `608499617a3`); `debugger_wait_hook()` in wait-type instructions (`b1181f86023`); interruptible cores override `cpu_is_interruptible()` and check `access_to_be_redone()` (`cpu_device.rst` §3).
- **Palette/gfx helpers**: formats `GRBx_444`, `xBGR_333_nibble`; `palette_device::read32_ext/write32_ext`; `GFXDECODE_DEVICE_REVERSEBITS`. → video topic
- **ROM definitions** (more): `ROM_COPY` source tags resolve relative to the device owning the `ROM_START` (`f16cd0249f1`).
- **Device-specific interfaces**: RTCs implement `rtc_clock_updated(...)`/`rtc_battery_backed()`, `set_current_time` is no longer virtual (`d66d88b1ab0`); network devices keep their own MAC and filter addresses, `set_promisc`/`get_mac` removed (`d98993d7ff9`, `9058810fe26`); `pcat_base_state` constructor `[[deprecated]]` — build PCs from chipset devices (`e4f44632c7a`).
- **Layouts** (more): `clickthrough`, `showpointers`; script hooks `element:set_draw_callback`, `view:set_pointer_updated_callback`; sandbox gains `emu.bitmap_*`, enumerators, `math` (`layout_script.rst`).
- Since-hash for mame-review D-2: mass `ATTR_COLD` migration `48933ef893c` (2024-09-26, ~2975 files).

- `set_ioport("TAG")` with a string in machine config (35 new files) — fine only under D-1's configuration-time exception; a finder is preferred. → object-finders / interrupts-devcb
- `IPT_OUTPUT` + `PORT_WRITE_LINE_*MEMBER` routes a CPU port output to a device line (`casio/ctk2000.cpp`). → interrupts-devcb
- `DEVICE_INPUT_DEFAULTS_*` / `set_option_device_input_defaults` (slot input defaults) uncovered. → slots topic
- Coinage order: `validity.cpp` `validate_dip_settings` seems to flag descending coinage, yet master has descending lists (`btime.cpp`, `video21.cpp`) and CI runs `-validate` — unresolved; input-ports leaves order to mame-review I-2.

- Image devices: `diimage.h` marks `fread`/`fwrite`/`fseek`/`length` wrappers for removal — use `util::read`/`read_at` on `image_core_file()` (`cpc_rom.cpp`, `ql/rom.cpp` already do). → image-devices topic
- mame-review T-6 recommends `std::ranges` algorithms; the runtime floor (libc++ 11) may lack many. Unverified. → rb6502/mame-ai-tips if confirmed

- **Video — tilemaps, gfx, palette** (remaining after screens): `gfx_element::decode_all()` (`9119c7237a9`), tilemap blitter callback, `enable_highlights`, `DRAWMODE_SHADOW_PRI`, palette formats `GRBx_444`/`xBGR_333_nibble`, `read32_ext`. → tilemaps/gfx topic

## Upstream candidates (not practice; for the user to report or fix)

- mame-review D-7 grep `\? ASSERT_LINE : CLEAR_LINE` also matches correct `set_input_line(..., x ? ASSERT_LINE : CLEAR_LINE)` (`7d7fa772eb5`, `object_finders.rst`). → rb6502/mame-ai-tips
- `src/emu/sound.h` header comment still describes the pre-2025 `read_stream_view`/`write_stream_view` API. → mamedev docs fix
- `src/devices/bus/coco/coco_multi.cpp` marks `sound_stream_update` `ATTR_COLD` (breaks D-2).
- 2026-06 vector conversions (e.g. `652fbfedba8` berzerk) moved the vector into an ack callback but kept `HOLD_LINE` — half the C-9 job.
- Likely bug: `src/mame/bfm/bfm_bda.h` `set_port_val` calls `m_brightness.set_names("vfdduty", ...)` with no `%u`, and `bfm_bda.cpp` constructs it as `"vfduty%u"`; `bfm_gu96x8m_k657c2.cpp` uses `"vfdduty%u"`.
- `object_finders.rst` on master: a truncated sentence ("an array of strings with the same dimensions…,"), a trailing comma in the qvt70 example, and the mmd2 example still declares an unneeded `machine_start()`.
- mame-review D-1 could mention `device_finder::lookup()` (`58fed9839ff`) for reaching a target during configuration. → rb6502/mame-ai-tips
- `src/devices/bus/pc98_cbus/fdd_2dd.cpp` calls `subdevice<floppy_connector>("0")` in handlers (D-1); `i82378zb_sio.cpp`/`i82426ex_ib.cpp` build `subdevice<>(finder_target())` where `lookup()` would do.
- A device with `device_execute_interface` that registers no save state is fatal at start unless it returns `flags::SAVE_UNSUPPORTED` (`src/emu/device.cpp` `device_t::start`; why `mipsx`, `ti990_10` carry the flag). → CPU-core topic
- Helper objects that aren't devices or mixins (`mpeg_demux.cpp`, `mpeg_video.cpp`) register through a `device_t &` with explicit prefixed names plus an index. → save-states, if it recurs
- `memory.rst` §4.4.5 shows `.cselect(16/32/64)`; the method is `cswidth()`.
- `casio/ctk2000.cpp` `lcd_r()` calls `hd44780_device::db_r()` from `PORT_CUSTOM_MEMBER` — check `db_r` for side effects (571f3d4b723: custom inputs with side effects are broken).
- `bus/msx/ctrl/dual_joyport.cpp` includes `input.h` without using it (L-3).
- `src/mame/williams/midtview.ipp` uses `SCREEN(config, "debugscreen", SCREEN_TYPE_RASTER)` under `#if DEBUG_MIDTUNIT_BLITTER` — fails to compile when enabled.
- `src/devices/machine/pxa255.cpp` TODO names `SCREEN_TYPE_LCD`; changing an LCD's visarea with `configure()` changes its aspect.
- mame-review D-12 grep `set_refresh_hz` should exempt `VECTOR`/`SCREEN_SVG` (and unknown-timing LCDs). → rb6502/mame-ai-tips
- Legacy slot boilerplate still in `bus/zbi/zbi.h` (added 2026-08) and `bus/xerox820/dbslot.h` — convert to `set_options`.
- D-4/D-3 deviations in recent maintainer code: `bus/adb/adb.h` `virtual ~adb_connector() = default;` in the header; `machine/s35180.h` inline virtual bodies; `machine/te7774.h` public `device_start` and the "device-level overrides" label.
- mame-review gaps: F-4 doesn't say where `INPUT_PORTS_START` goes in a public device's .cpp (new files: 26 `static`, 21 namespace, 5 bare); D-5 doesn't say whether a non-zero crystal default clock (`s35180` 32'768) is fine. → rb6502/mame-ai-tips
