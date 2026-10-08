# Logging

Debug and diagnostic output in drivers and devices via `logmacro.h`. mame-review rules that govern it: L-1 (the logging rule), C-1 (log lines in read handlers).

## TL;DR

- Channels `(1U << n)` from bit 1, `VERBOSE (0)`, `logmacro.h` last; ship with any `LOG_OUTPUT_FUNC` commented out (L-1 makes a live one Blocking).
- Handler messages start with `machine().describe_context()`.
- A log line in a read handler sits under `!machine().side_effects_disabled()`.
- `LOG`/`LOGMASKED` work directly in device interface mixins since `4f44364b25e` (2026-08-27) — no `LOG_OUTPUT_FUNC` workaround.
- Rare unimplemented/illegal conditions: unconditional `logerror`. User-facing diagnostics: `osd_printf_verbose`.

## Rules

### Channel setup

**Do**

```cpp
#include "emu.h"
#include "mydev.h"
// ... every other header

#define LOG_REGS (1U << 1)
#define LOG_DMA  (1U << 2)

#define VERBOSE (0)
//#define LOG_OUTPUT_FUNC osd_printf_info
#include "logmacro.h"

#define LOGREGS(...) LOGMASKED(LOG_REGS, __VA_ARGS__)
#define LOGDMA(...)  LOGMASKED(LOG_DMA, __VA_ARGS__)
```

To debug locally, change the line to `#define VERBOSE (LOG_GENERAL | LOG_REGS)`; set it back before committing.

**Legacy forms**: `#define LOG(x) do { if (VERBOSE) logerror x; } while (0)` called as `LOG(("..."))`; `#define LOG 0` with `if (LOG) logerror(...)`; `verboselog(...)`; masks written `(1 << 1U)` (as in the `cxx.rst` example); a live `#define LOG_OUTPUT_FUNC osd_printf_info` next to `VERBOSE (0)` — some maintainers check that in (`src/mame/apple/psc.cpp`), but L-1 flags it.
**Since**: established (`19a91227487`, 2017-01-20)
**Evidence**: [T1] `src/emu/logmacro.h` — `#error` unless included once, after `emu.h` and all other headers; [T2] `cxx.rst` § Logging; [T2] mame-review L-1; [T5] files added in the last year use `(1U << n)` about 10:1 over `(1 << n)`; [T5] deviation: `src/devices/machine/nscsi_hle.cpp` ships `VERBOSE (LOG_UNSUPPORTED)` — L-1 would flag it
**Key symbols**: `LOGMASKED`, `LOG_GENERAL`, `VERBOSE`, `LOG_OUTPUT_FUNC`

### Handler messages

**Do**

```cpp
u8 mydev_device::status_r()
{
	u8 const data = m_status;
	if (!machine().side_effects_disabled())
	{
		LOGREGS("%s: status_r %02x\n", machine().describe_context(), data);
		m_status &= ~STATUS_IRQ;
	}
	return data;
}
```

`logerror` already prefixes the device tag; `describe_context()` adds the accessing device and its PC.

**Legacy forms**: `logerror("%s: ...", tag(), ...)` (duplicates the prefix); `LOG("%s", string_format(...).c_str())`.
**Since**: established
**Evidence**: [T2] `cxx.rst` § Logging — `describe_context()` includes the PC when the device implements `device_state_interface`; [T2] mame-review L-1, C-1 (a read whose only side effect is logging is Tidy)
**Key symbols**: `describe_context`, `side_effects_disabled`

### Logging from interface mixins

**Do**

```cpp
// in a device_interface subclass (e.g. adb_hle_host_interface)
LOGMASKED(LOG_DATA, "%s: rx %02x\n", device().machine().describe_context(), data);
```

`LOG_OUTPUT_FUNC` dispatches to `this->logerror(...)` or, failing that, `this->device().logerror(...)`.

**Legacy forms**: `#define LOG_OUTPUT_FUNC device().logerror` before the include; direct `device().logerror(...)` calls in place of `LOG`. The first still appears in code added after the change (`src/devices/machine/adbhost.cpp`, 2026-09).
**Since**: `4f44364b25e` (2026-08-27) — after mame-review's snapshot, which doesn't mention it
**Evidence**: [T1] `src/emu/logmacro.h` — `emu::detail::dispatch_logerror`; [T3] commit `4f44364b25e` "LOG: automatically dispatch to logerror() or device().logerror()"
**Key symbols**: `dispatch_logerror`

### Packet and buffer dumps

**Do**

```cpp
#define LOG_PACKETS (1U << 3)
// in a device_network_interface device
if (VERBOSE & LOG_PACKETS)
	log_bytes(buf, length);
```

`log_bytes` writes through `device().logerror`, eight bytes per line. The `VERBOSE & mask` test is how a helper that isn't `LOG` joins a channel — distinct from the bare `if (VERBOSE)` around `LOG`/`logerror` that L-1 flags; all four migrated devices use it.

**Legacy forms**: a private `dump_bytes(u8 *buf, int length)` hex dumper per device (still in `scsihle.cpp`).
**Since**: `f7731929a75` (2025-09-12, Patrick Mackinlay; four NICs migrated)
**Evidence**: [T1] `src/emu/dinetwork.h` `log_bytes(const u8 *buf, int len)`; [T3] `f7731929a75`; [T2] mame-review L-1 (logging generally; this helper not covered)
**Key symbols**: `log_bytes`, `device_network_interface`

## Superseded

None yet.

## Examples

- `src/devices/machine/nscsi_hle.cpp` @ `9f7f9ecd214` — named channels, `LOG` for general plus `LOGMASKED` for detail; deviation: ships with one channel enabled.
- `src/devices/machine/atahle.cpp` @ `5458892b8ec` — wrapper macros and logging from a mixin via `device().machine().describe_context()`; deviation: live `LOG_OUTPUT_FUNC osd_printf_info`.
