# Timers

Scheduling future events in devices and drivers: `emu_timer`, `timer_device`, `synchronize`, and `attotime` durations. mame-review rules that govern it: C-3 (timers allocated in start), C-10 (synchronize; no per-tick timers), C-2 (timers save themselves), D-8 (`clocks_to_attotime`). mame-review has no dedicated timer rule; this topic carries the API.

## TL;DR

- Allocate every `emu_timer` in `device_start`/`machine_start` with `timer_alloc(FUNC(cls::cb), this)`. Arm it with `adjust(delay, param, period)` and put it in its hardware reset state in `device_reset`, usually `adjust(attotime::never)`.
- Don't `save_item` a timer (C-2), but do save the state your callback and readback depend on, such as a start `attotime`.
- Derive counter values from `remaining()`/`elapsed()` and schedule only the next event (overflow, compare match). Never fire a timer on every tick (C-10).
- Pass data between CPUs with `machine().scheduler().synchronize(timer_expired_delegate(FUNC(cls::cb), this), data)` and change state inside the callback (C-10).
- Turn device clocks into durations with `clocks_to_attotime(n)` (D-8). Other durations: `attotime::from_hz/from_usec/from_ticks`.
- Use `timer_device` (`TIMER(config, ...)`) for scanline timers in drivers. Use `emu_timer` for everything a device schedules itself.

## Rules

### emu_timer: allocate in start, arm with adjust, reset in reset

**Do**

```cpp
// mydev.h, private:
	TIMER_CALLBACK_MEMBER(count_expired);
	devcb_write_line m_irq_cb;
	emu_timer *m_count_timer;
	u8 m_status;

// mydev.cpp
void mydev_device::device_start()
{
	m_count_timer = timer_alloc(FUNC(mydev_device::count_expired), this);

	save_item(NAME(m_status)); // no save_item for the timer
}

void mydev_device::device_reset()
{
	m_count_timer->adjust(attotime::never); // the core never touches timers on reset
	m_status = 0;
}

void mydev_device::count_w(u8 data)
{
	m_count_timer->adjust(clocks_to_attotime(u64(data) * 16), data); // one-shot, param = data
}

TIMER_CALLBACK_MEMBER(mydev_device::count_expired) // void count_expired(s32 param)
{
	m_status |= 0x80;
	m_irq_cb(ASSERT_LINE);
}
```

`timer_alloc` registers the timer's state for saving, so it throws after start ("Attempt to register save state entry after state registration is closed!"). The save name is the `FUNC()` callback name plus allocation order. Because of this, a timer pool allocated in a loop works, and renaming a callback invalidates old save states. The core does not cancel pending timers on a soft reset, so `device_reset` must re-arm or stop each one. One `emu_timer` holds one pending expiry, and `adjust` replaces it. For overlapping delayed events, allocate a pool (`emu_timer *m_collision_timer[128]` in `exidy.cpp`). Registration after start has been fatal for every system since `334ec12e004` (2024-02-25).

**Legacy forms**: `machine().scheduler().timer_alloc(timer_expired_delegate(FUNC(cls::cb), this))` (still valid, but verbose); `timer_alloc(TIMER_ID)` with a `device_timer(emu_timer &, device_timer_id, int[, void *])` override switching on `id`; `TIMER_CALLBACK_MEMBER` bodies that use `ptr`; `TIMER_CALLBACK(name)` free functions taking `running_machine &machine`, which were superseded by `TIMER_CALLBACK_MEMBER` (introduced in `ef6f5d0a52b`, 2012; conversion finished in `8ea9ff6a7af`, 2016).
**Since**: `timer_alloc(FUNC(...), this)` helper and removal of `device_timer`/IDs in `1bc5484698b` (2022-06-04); the `void *ptr` parameter was removed in `ca79d71af4b` (2022-01-26, AJR); callback and `synchronize` param `int` → `s32` in `c401273bdab` (2023-12-11, hap)
**Evidence**: [T1] `src/emu/schedule.h` — `TIMER_CALLBACK_MEMBER(name)` is `void name(s32 param)`; `adjust(attotime start_delay, s32 param = 0, const attotime &periodicity = attotime::never)`; [T1] `src/emu/device.h` `interface_post_start` — "the appropriate place to allocate resources like timers"; [T1] `src/emu/schedule.cpp` `emu_timer::init` calls `register_save`, and `running_machine::soft_reset` only calls reset notifiers; [T2] mame-review C-3 (grep flags `timer_alloc` in `_reset()`), C-2; [T5] 89 of the 1073 source files added in the last year call `timer_alloc(`; 1 uses the long scheduler form
**Key symbols**: `emu_timer`, `timer_alloc`, `TIMER_CALLBACK_MEMBER`, `timer_expired_delegate`, `adjust`

### Durations, periodic timers and counter readback

**Do**

```cpp
void mytmr_device::start_counting() // stop with adjust(attotime::never) after latching m_count = count()
{
	attotime const period = clocks_to_attotime(u64(m_reload + 1) * 16); // this device's clock (D-8)
	m_tick_timer->adjust(clocks_to_attotime(u64(m_count + 1) * 16), 0, period); // first, param, period
}

u8 mytmr_device::count() const
{
	if (!BIT(m_control, 0))
		return m_count;
	return u8(attotime_to_clocks(m_tick_timer->remaining()) / 16); // no per-tick callback (C-10)
}

// other durations: attotime::from_hz(60), attotime::from_usec(500), attotime::from_ticks(n, 1_MHz_XTAL)
```

`adjust` always sets the timer enabled, even with `attotime::never`. To learn whether a timer is armed, test `expire().is_never()` or your own control bit, not `enabled()`. `enable(false)` pauses the timer and keeps its expiry; `enable(true)` resumes it, firing at once if that expiry has passed. `emu_timer::reset(d)` is `adjust(d, param(), period())` and keeps the param and the period. `timer_device::reset()`, by contrast, clears both. When the clock changes, a timer that is counting must be re-armed in `device_clock_changed()`. A timer that should free-run regardless of reset (an RTC tick) can be armed once in `device_start`, as in `a2clock.cpp`. Inside a CPU core, use `cycles_to_attotime`/`attotime_to_cycles` when cycles differ from clocks. `from_hz` has `u32`, `int`, `double` and `XTAL` overloads; `from_hz(0)` returns `attotime::never`.

**Legacy forms**: a periodic timer at the counter's input clock that decrements `m_count` in its callback; `adjust(attotime::zero)` from inside its own callback (C-10 flags both); `attotime::from_hz(clock()) * n` or `attotime::from_ticks(n, clock())` in place of `clocks_to_attotime(n)` (D-8).
**Since**: established
**Evidence**: [T1] `src/emu/schedule.cpp` `emu_timer::adjust` sets `m_enabled = true` unconditionally; [T1] `schedule.h` `reset(const attotime &duration = attotime::never)`; [T1] `src/emu/device.h` `clocks_to_attotime(u64) const noexcept`; [T1] `src/emu/attotime.h` `from_hz`, `from_ticks`, `as_ticks`, `is_never`; [T2] mame-review C-10 ("Per-tick internal events come off the execute loop"), D-8; [T5] `sh7014_wdt.cpp` and `a2clock.cpp` read their counts from `machine().time()` and `remaining()`; new files: 5 use `clocks_to_attotime`, 1 uses `attotime::from_hz(clock())`
**Key symbols**: `enable`, `enabled`, `remaining`, `expire`, `device_clock_changed`, `clocks_to_attotime`, `attotime_to_clocks`, `cycles_to_attotime`, `from_hz`, `from_ticks`

### Cross-CPU handoff: synchronize

**Do**

```cpp
void mystate::main_to_sub_w(u8 data)
{
	machine().scheduler().synchronize(timer_expired_delegate(FUNC(mystate::main_to_sub_sync), this), data);
}

TIMER_CALLBACK_MEMBER(mystate::main_to_sub_sync)
{
	m_main_to_sub = u8(param);
	m_subcpu->set_input_line(INPUT_LINE_IRQ0, ASSERT_LINE);
}
```

The param is an `s32`. Wider data has to be stashed in a member before the call. If the hardware is a latch, use `generic_latch_8_device` instead, because it already synchronizes (C-10, D-8). For handshakes that poll tightly, raise interleave around the exchange with `machine().scheduler().perfect_quantum(attotime::from_usec(n))`, or for the whole run with `config.set_perfect_quantum(m_maincpu)` / `config.set_maximum_quantum(...)`.

**Legacy forms**: `synchronize(TIMER_ID, param)` on `device_t`; a bare `machine().scheduler().synchronize();` followed by assignments (a race, C-10); `machine().scheduler().boost_interleave(...)`.
**Since**: `device_t::synchronize` removed in `1bc5484698b` (2022-06-04); `boost_interleave` replaced by `perfect_quantum` in `184f4dcfa2c` (2022-09-02, hap)
**Evidence**: [T1] `schedule.h` `synchronize(timer_expired_delegate callback = timer_expired_delegate(), s32 param = 0)`; [T2] mame-review C-10; [T5] `gen_latch.cpp` `generic_latch_8_device::write`
**Key symbols**: `synchronize`, `perfect_quantum`, `set_perfect_quantum`, `set_maximum_quantum`

### timer_device: scanline timers in drivers

**Do**

```cpp
// state class, private; the driver includes "machine/timer.h"
	TIMER_DEVICE_CALLBACK_MEMBER(scanline);
// machine config
	TIMER(config, "scantimer").configure_scanline(FUNC(mystate::scanline), m_screen, 0, 1);

TIMER_DEVICE_CALLBACK_MEMBER(mystate::scanline) // void scanline(timer_device &timer, s32 param)
{
	int const vpos = param;
	if (vpos == 240)
		m_maincpu->set_input_line(INPUT_LINE_IRQ0, ASSERT_LINE);
}
```

`configure_scanline` has no direct `emu_timer` equivalent and is what `timer_device` is for. `configure_periodic(FUNC(cb), attotime::from_hz(n))` in a driver config is also current. For a one-shot or a timer the code re-arms itself, especially inside a device, prefer `emu_timer` over `TIMER(...).configure_generic(...)`. On reset, a generic `timer_device` is not cancelled, and calling `adjust` on a periodic or scanline one is a fatal error.

**Legacy forms**: `MCFG_TIMER_DRIVER_ADD_SCANLINE("scantimer", state, cb, "screen", 0, 1)`, `MCFG_TIMER_DRIVER_ADD_PERIODIC`; `TIMER_DEVICE_CALLBACK_MEMBER` bodies using `ptr`.
**Since**: MCFG macros removed in `53d99d41900` (2019-01-21); `void *ptr` removed in `ca79d71af4b` (2022-01-26)
**Evidence**: [T1] `src/devices/machine/timer.h` `configure_scanline`, `adjust` → `fatalerror("Cannot adjust a non-generic timer.\n")`; `timer.cpp` `device_reset` arms only periodic/scanline types; [T5] conversion commits `f08c9ac5426`, `0636e54bb60` (hap), `797a9b62c0c`, `bde9868d112` (angelosa) replace generic `timer_device`s with `emu_timer`; [T5] new files: 20 use `TIMER(config`, with 7 scanline, 13 periodic and 19 generic instances among them. Observation, not a T1–T4 deviation: 6 new device files still use `configure_generic` (5 under `src/devices`, e.g. `generalplus_gpl951xx_soc.cpp`, `i7110.cpp`, plus `src/mame/atari/pofo_asic.cpp`)
**Key symbols**: `timer_device`, `TIMER`, `TIMER_DEVICE_CALLBACK_MEMBER`, `configure_scanline`, `configure_periodic`, `configure_generic`

## Superseded

- Anonymous `machine().scheduler().timer_set(delay, timer_expired_delegate(...), param)`: `[[deprecated]]` in `1bc5484698b` (2022-06-04) and superseded by an allocated `emu_timer`. While an anonymous timer is pending, `device_scheduler::can_save` refuses to save ("Failed save state attempt due to anonymous timers"). Three files on master still call it: `dec/rx01.cpp`, `miltonbradley/vectrex_v.cpp`, `sega/turbo_a.cpp`. None of the files added in the last year do. Other superseded forms (`device_timer`/IDs, `TIMER_CALLBACK`, MCFG timer macros) are listed under each rule's **Legacy forms**.

## Examples

- `src/devices/cpu/sh/sh7014_wdt.cpp` @ `107486997ae`: a one-shot overflow timer allocated in start and set to `never` in reset. It reads the counter back from a saved `m_count_time` and `machine().time()`, not from per-tick callbacks. Deviation: it uses `attotime::from_ticks(..., clock())` where D-8 wants `clocks_to_attotime`.
- `src/mame/atari/atarisy2.cpp` @ `774a180df2b`: `configure_scanline` with a screen finder, `synchronize` with the written data as param (`delayed_int_enable_w`), and `perfect_quantum` from a latch's data-pending callback. Deviation: `FUNC(...),this)` spacing.
