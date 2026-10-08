# Inbox

Findings with no topic yet. Each: one line of practice, evidence (tier + hash), and the topic it might belong to.

## Practice

- `device_delegate` (unlike devcb) still needs `resolve()`/`resolve_safe()` — every `.resolve()` in a file added in the last year is on a delegate. [T1] `src/emu/devdelegate.h`. → delegates topic
- Beam-position events: schedule with `screen.time_until_pos(v, h)`; vblank IRQs via `screen_vblank().set_inputline(...)` rather than `set_vblank_int`. [T5] `exidy.cpp`. → video topic
- `attotime` members go straight into `save_item`; a counter's start time is the usual live state to save. [T1] `src/emu/save.h`. → save-states
- `set_periodic_int`, `INTERRUPT_GEN_MEMBER`, `irqN_line_hold` are not `[[deprecated]]` (885 + 597 uses on master) though mame-review C-9 effectively forbids them in new code. → watch for a core deprecation

- `nvram_device::set_base(ptr, size)` in start (17 files added in the last year) — distinct from the `memory_bank::set_base` D-6 forbids; needs coverage. → nvram / address-maps
- `5446223573f` (Vas Crabb) replaced ad-hoc `printf` with `util::stream_format(std::cout/std::cerr, …)` in next.cpp, vboy.cpp, viper.cpp, stic.cpp — check against mame-review L-1, which bans `std::cout` in `src/devices`/`src/mame`. → logging
- C-3's "one-shot install at first reset guarded by a flag" exception has a real example: `src/mame/sgi/ip2.cpp` installs a view at first reset because the slave address comes from a DIP switch. → address-maps example

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
