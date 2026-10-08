# Screens

Video outputs in machine config and devices: raster/LCD `SCREEN`, `VECTOR`, `SCREEN_SVG`, timing, update callbacks, vblank and beam events, mid-frame and run-time changes. mame-review rules that govern it: D-12 (the video rule, written before the 2026 screen split), C-3 (`configure()` for run-time timing), D-7 (vblank callback binding).

## TL;DR

- Pick the device: `SCREEN(config, m_screen)` for raster, add `.set_lcd()` for an LCD, `VECTOR(config, m_vector)` for vector, `SCREEN_SVG(config, tag)` for SVG artwork. `SCREEN_TYPE_*` is gone (`774a180df2b`, 2026-07-24).
- Raster timing is `set_raw(clock, htotal, hbend, hbstart, vtotal, vbend, vbstart)` from the master clock (D-12). `set_refresh_hz` is for LCDs with unknown timing and is the only option on `VECTOR`/`SCREEN_SVG`.
- `screen_update` draws only inside `cliprect` and changes no state. Give a `bitmap_ind16` screen `set_palette(m_palette)`.
- Vblank interrupts: `screen_vblank().set_inputline(...)` or `.set(FUNC(...))`, not `set_vblank_int`. Beam-position events: `emu_timer` armed with `time_until_pos(v, h)`.
- Before a mid-frame video state change, call `update_partial(vpos())` (per-line) or `update_now()` (per-pixel). Change timing at run time with `screen().configure(w, h, visarea, attotime)` (C-3).

## Rules

### Choose the video output device

**Do**

```cpp
#include "screen.h"      // SCREEN; "vector.h" for VECTOR, "screen_svg.h" for SCREEN_SVG
SCREEN(config, m_screen).set_lcd();          // square pixels, LCD shader sliders
m_screen->set_refresh_hz(60);
m_screen->set_size(160, 160);
m_screen->set_visarea_full();
m_screen->set_screen_update(FUNC(mystate::screen_update));
VECTOR(config, m_vector);                    // required_device<vector_device> m_vector;
m_vector->set_refresh_hz(40);
m_vector->set_visarea(512, 1536, 608, 1440);
m_vector->set_vector_update(FUNC(mystate::vector_update));
// void mystate::vector_update(vector_device &vector): vector.clear_list(); then vector.add_point(x, y, color, intensity) per point
screen_svg_device &mask(SCREEN_SVG(config, "mask")); // artwork from region "mask"
mask.set_refresh_hz(60);
mask.set_size(919, 1080);
```

All three implement `device_video_output_interface` (`divo.h`: `set_orientation`, `container()`, `frame_period()`). An SVG screen lights shapes whose ids match output names; its optional `set_screen_svg_update` callback (`void (screen_svg_device &)`) runs before each render to refresh those outputs. A vector device fires `screen_vblank` as a 1-then-0 pulse. Bind a handler to it, not a CPU line.

**Legacy forms**: `SCREEN(config, "screen", SCREEN_TYPE_RASTER)` / `SCREEN_TYPE_LCD` / `SCREEN_TYPE_SVG` (plus `set_visarea_full()` on SVG); `VECTOR(config, "vector")` beside a `SCREEN_TYPE_VECTOR` screen with `set_screen_update("vector", FUNC(vector_device::screen_update))`; `#include "video/vector.h"`; `screen.set_type(...)`; `screen_type()`; `MCFG_SCREEN_ADD`.
**Since**: `774a180df2b` (2026-07-24, O. Galibert, 2497 files)
**Evidence**: [T1] `src/emu/screen.h` `set_lcd()`/`set_raster()`; [T1] `src/emu/vector.h`, `src/emu/screen_svg.h`, `src/emu/divo.h`; [T3] `screen.cpp` `physical_aspect` (LCD defaults to square pixels, raster to 4:3); [T5] 31 of 1037 files added in the last year use `set_lcd()`, none use `SCREEN_TYPE_*`
**Key symbols**: `SCREEN`, `VECTOR`, `SCREEN_SVG`, `set_lcd`, `set_raster`, `set_vector_update`, `add_point`, `clear_list`, `set_screen_svg_update`, `set_svg_region`, `device_video_output_interface`

### Raster timing, update callback and palette

**Do**

```cpp
static constexpr XTAL MASTER_CLOCK = 12.096_MHz_XTAL;
SCREEN(config, m_screen);
m_screen->set_raw(MASTER_CLOCK / 2, 384, 0, 256, 262, 0, 240);
m_screen->set_screen_update(FUNC(mystate::screen_update));
m_screen->set_palette(m_palette);
m_screen->screen_vblank().set_inputline(m_maincpu, INPUT_LINE_NMI);
PALETTE(config, m_palette, palette_device::BGR_222);   // 64 entries
u32 mystate::screen_update(screen_device &screen, bitmap_ind16 &bitmap, const rectangle &cliprect)
{
	bitmap.fill(m_palette->black_pen(), cliprect);
	m_bg_tilemap->draw(screen, bitmap, cliprect, 0, 0);
	return 0;
}
```

The rules for `cliprect`, pens and state are in D-12. Validation fails if a `bitmap_ind16` screen has no palette. It warns if a `bitmap_rgb32` screen has one. The line from `screen_vblank().set_inputline` follows the vblank level, high for the whole blanking period. If the hardware latches the IRQ until it is acknowledged, bind `.set(FUNC(mystate::vblank_w))` with `void vblank_w(int state)`, assert on `state`, and clear on acknowledge (see the interrupts-devcb topic).

**Legacy forms**: `set_refresh_hz(60)` + `set_vblank_time(ATTOSECONDS_IN_USEC(2500))` + `set_size`/`set_visarea` on a raster screen whose timing is known; `m_maincpu->set_vblank_int("screen", FUNC(x::irq0_line_hold))` (interrupts-devcb); `SCREEN_UPDATE_IND16(name)`.
**Since**: established. `PALETTE(..., palette_device::BGR_222)` since `741da632a54` (2026-06-22).
**Evidence**: [T1] `screen.h` — `set_refresh_hz` doc comment: "For raster displays, please use #set_raw"; [T3] `screen.cpp` `device_validity_check`; [T2] mame-review D-12, D-7. D-12's grep `set_refresh_hz` false-flags `VECTOR`, `SCREEN_SVG` and LCDs with unknown timing. The split (`774a180df2b`, T3) gave those devices `set_refresh_hz` and no `set_raw`, so the grep is wrong for them, not the code. [T5] deviation: in files added in the last year, 42 use `set_raw` and 37 use `set_refresh_hz` on a raster screen (mostly skeletons and splits from old drivers, e.g. `metro/blzntrnd.cpp`). 8 still use `set_vblank_int`, against 19 that use `screen_vblank()`.
**Key symbols**: `set_raw`, `set_refresh_hz`, `set_vblank_time`, `set_screen_update`, `screen_vblank`, `set_palette`, `set_no_palette`, `BGR_222`, `set_vblank_int`

### Beam-position events and mid-frame changes

**Do**

```cpp
// machine_reset: m_line_timer->adjust(m_screen->time_until_pos(0));
TIMER_CALLBACK_MEMBER(mystate::line_cb)
{
	int const next = (param + 64) & 0xff;
	m_maincpu->set_input_line(0, ASSERT_LINE);           // cleared by the ack
	m_line_timer->adjust(m_screen->time_until_pos(next), next);
}
void mystate::scroll_w(u8 data)
{
	m_screen->update_partial(m_screen->vpos());   // latched per line: finish this line first
	// or m_screen->update_now();                 // takes effect mid-line, at the beam pixel
	m_scrollx = data;
}
```

`time_until_pos` never returns zero; at the target position it returns a full frame, so re-arming from the callback is safe. `update_partial(v)` renders up to and including line `v`. `update_partial(v, h)` and `update_now()` render up to, but not including, the beam pixel. Each returns `true` if it rendered anything. It returns `false` when the frame is skipped, the screen isn't live, or the beam hasn't moved.

**Legacy forms**: `void update_now()` (line granularity before 2026-04); a `TIMER(config, ...).configure_scanline(...)` that only counts lines to fire one event (timers topic).
**Since**: `56ea076a1fd` (2026-04-23, hap) — `update_partial(vpos, hpos)` and `bool update_now()`
**Evidence**: [T1] `screen.h` `update_partial`, `update_now`, `time_until_pos`; [T3] `screen.cpp` `update_partial(int vpos, int hpos)` comment "up to (but not including!)"; [T2] mame-review D-12 (partial update before mid-frame changes)
**Key symbols**: `time_until_pos`, `time_until_vblank_start`, `update_partial`, `update_now`, `vpos`, `hpos`

### Run-time timing and device defaults

**Do**

```cpp
void mydev_device::device_config_complete()   // device_video_interface
{
	if (!has_screen())
		return;
	if (!screen().has_screen_update())
		screen().set_screen_update(*this, FUNC(mydev_device::screen_update));
	if (!screen().has_been_setup())
		screen().set_raw(clock(), 342, 0, 256, 262, 0, 192);
}
void mydev_device::recalc_timing()   // from a register write, never set_raw (C-3)
{
	rectangle const visarea(0, m_hdisp - 1, 0, m_vdisp - 1);
	screen().configure(m_htotal, m_vtotal, visarea, attotime::from_ticks(m_htotal * m_vtotal, clock()));
}
```

If the host already set timing with `set_raw`, `set_refresh` or `set_refresh_hz`, `has_been_setup()` is true and the device keeps those values.

**Legacy forms**: `configure(w, h, visarea, HZ_TO_ATTOSECONDS(rate))` or `refresh.as_attoseconds()`; `screen().refresh_attoseconds()`; `set_refresh(attoseconds_t)`; `if (!screen().configured())` as the default-timing test.
**Since**: `4873b416e7e` (2026-08-04, O. Galibert) for the `attotime` frame period; `ad09989a8c3` (2026-08-15, O. Galibert) for `has_been_setup()`, applied to 11 devices
**Evidence**: [T1] `screen.h` `configure(int, int, const rectangle &, attotime)`, `set_refresh(attotime)`, `has_been_setup()`; [T3] `divideo.cpp` — "device_config_complete may now do whatever it needs to with the screen"; [T2] mame-review C-3; [T5] 4 new files call `configure()`, all with `attotime`
**Key symbols**: `configure`, `has_been_setup`, `has_screen_update`, `set_refresh`, `frame_period`, `device_video_interface`, `from_ticks`

### Tilemap scroll helper

**Do**

```cpp
m_bg_tilemap->set_scrollx(m_scrollx);                       // every scroll row
m_fg_tilemap->set_scrollx(y, m_rowscroll[y]);               // one row, after set_scroll_rows(n) in start
```

**Legacy forms**: `set_scrollx(0, v)` on a single-row tilemap (still correct); a loop that writes the same value to every row.
**Since**: `dde7a2021e4` (2026-03-19, hap). Before it, single-argument `set_scrollx(v)`/`set_scrolly(v)` set only row/column 0.
**Evidence**: [T1] `src/emu/tilemap.h` `set_scrollx(int value)` → `std::fill_n(m_rowscroll...)`
**Key symbols**: `set_scrollx`, `set_scrolly`, `set_scroll_rows`, `set_scroll_cols`

## Superseded

- `SCREEN(config, tag, SCREEN_TYPE_*)`, `screen_type_enum`, and vector or SVG drawing through a `screen_device`: superseded by "Choose the video output device" in `774a180df2b`.
- Frame period as `attoseconds_t` (`configure(..., attoseconds_t)`, `refresh_attoseconds()`): superseded by "Run-time timing" in `4873b416e7e`.
- `screen().configured()` as the "host gave no timing" test: superseded by `has_been_setup()` in `ad09989a8c3`.

## Examples

- `src/mame/atari/flyball.cpp` @ `774a180df2b` — `set_raw` from an XTAL constant, `set_palette`, `screen_vblank().set_inputline` to NMI, and `time_until_pos` timers. Deviations: `mark_all_dirty()` every frame in `screen_update` instead of per-tile dirtying (D-12) and `ioport("...")` lookups in a timer callback (D-1).
- `src/mame/apple/civic.cpp` @ `57018adb9d8` (arbee) — `configure(..., attotime::from_ticks(htotal * vtotal, pixclock))` on mode change and a vblank timer re-armed with `time_until_pos`. Deviations: `screen_update` loops over the full height instead of `cliprect` (D-12), `m_irq(ASSERT_LINE)` on a devcb (D-7), and `time_until_pos(480, 0)` hard-codes the visible height.
