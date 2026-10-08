---
name: mame-practice
description: Current MAME coding practice — the modern API and idiom for each driver/device concern, plus the legacy forms still found in old code. Use when writing or modifying MAME driver or device code (src/mame, src/devices).
---

# MAME current practice

The writing companion to the **mame-review** skill. mame-review holds the rules a review applies, by ID (`C-2`, `D-6`, `L-1`) in `~/.claude/skills/mame-review/` (`RULES.md`, `STYLE.md`, `SYSTEMS.md`); the topics here add working snippets, the legacy forms found in old code, since-when history, and APIs mame-review doesn't cover. When a topic cites a rule ID you need the detail of, read that rule.

Each topic file opens with a TL;DR; read past it only for the rule you are applying.

## Policy

- **New files**: current practice throughout.
- **Existing files**: new code uses current practice wherever it can sit beside the surrounding old style. Converting existing legacy code is a separate commit, made only when the user asks.
- **Legacy forms** listed in topics are for recognizing old code; write the **Do** form.
- **Debugger side effects**: every read handler, and everything it reaches, computes its value and applies state changes only under `!machine().side_effects_disabled()` — mame-review C-1.

## Topics

- [logging](topics/logging.md) — `logmacro.h` channels, handler messages, logging from interface mixins
- [timers](topics/timers.md) — `emu_timer` allocation/arming/reset, durations and counter readback, `synchronize`, scanline `timer_device`
- [sound-streams](topics/sound-streams.md) — `device_sound_interface`, the 2025 `sound_stream_update` API, stream updates, sample rates, speakers and routing
- [address-maps](topics/address-maps.md) — map entries and handler forms, `memory_view`, banks, shares and run-time installs, device maps and `memory_access`, `offs_t` width
- [interrupts-devcb](topics/interrupts-devcb.md) — declaring and binding devcb, CPU input lines without `HOLD_LINE`, acknowledge-callback vectors, input mergers and latches
- [object-finders](topics/object-finders.md) — finder members and arrays, finders in machine config and maps, outward-pointing finders and `lookup()`, self-resolving output finders, `device_resolve_objects()`
- [save-states](topics/save-states.md) — `save_item`/`STRUCT_MEMBER`/`save_pointer`, enums, what saves itself, `device_post_load`, mixins, `SAVE_UNSUPPORTED`

## Before a PR

Run `/mame-review` in a fresh session. The PR description names the AI model and version used (MAME's contributing guidelines, § Use of AI; mame-review S-1).

## Freshness

Verified through master `ab1bc044b6d` (2026-10-06) and mame-review `442b673` (2026-09-30). Where code on your branch is newer, the `src/emu` headers win.
