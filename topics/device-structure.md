# Device and driver structure

The skeleton of a device class, a slot and a driver state class (`src/emu/device.h`, `driver.h`, `dislot.h`). mame-review rules that govern it: D-3 (layout), D-5 (constructors), D-2 (`ATTR_COLD`), D-4 (virtuals), D-11 (drivers), C-3 (start/reset), D-10 (device generality), F-4 (anonymous namespace), N-3 (naming).

## TL;DR

- Give every device a public `(machine_config const &, char const *tag, device_t *owner, u32 clock)` constructor whose fourth argument is the clock. Convenience constructors delegate to it; protected base constructors take no default arguments.
- Put `DECLARE_DEVICE_TYPE` after the class in the header and `DEFINE_DEVICE_TYPE` after the includes in the .cpp. A class declared only in a .cpp goes in `namespace {`, with `DEFINE_DEVICE_TYPE_PRIVATE` after the namespace closes.
- In a slot's convenience constructor, call `set_options(std::forward<T>(opts), dflt, fixed)`. A slot that clocks its cards takes a clock with no default.
- In a state class, override `machine_start`/`machine_reset`/`video_start`. `driver_device` marks `device_start`, `device_reset_after_children`, `device_add_mconfig`, `device_rom_region` and `device_input_ports` `final`.
- Check your work with `mame -validate` and no pattern. Only that form constructs every device type.

## Rules

### Device class and constructors

**Do**
```cpp
// acme_xy100.h, inside the include guard, after #include "cpu/mcs48/mcs48.h"
class acme_xy100_device : public device_t
{
public:
	static constexpr feature_type imperfect_features() { return feature::TIMING; }
	acme_xy100_device(machine_config const &mconfig, char const *tag, device_t *owner, u32 clock);
	auto irq_cb() { return m_irq_cb.bind(); }
	void reset_w(int state);

protected:
	acme_xy100_device(machine_config const &mconfig, device_type type, char const *tag, device_t *owner, u32 clock, u8 fifo_depth);
	// device_t implementation
	virtual tiny_rom_entry const *device_rom_region() const override ATTR_COLD;
	virtual void device_add_mconfig(machine_config &config) override ATTR_COLD;
	virtual void device_start() override ATTR_COLD;
	virtual void device_reset() override ATTR_COLD;

private:
	required_device<i8049_device> m_mcu;
	devcb_write_line m_irq_cb;
	u8 const m_fifo_depth;
};

DECLARE_DEVICE_TYPE(ACME_XY100, acme_xy100_device)

// acme_xy100.cpp, after the includes and logmacro.h
DEFINE_DEVICE_TYPE(ACME_XY100, acme_xy100_device, "acme_xy100", "Acme XY100 keyboard controller")

acme_xy100_device::acme_xy100_device(machine_config const &mconfig, char const *tag, device_t *owner, u32 clock) :
	acme_xy100_device(mconfig, ACME_XY100, tag, owner, clock, 4)
{
}
acme_xy100_device::acme_xy100_device(machine_config const &mconfig, device_type type, char const *tag, device_t *owner, u32 clock, u8 fifo_depth) :
	device_t(mconfig, type, tag, owner, clock),
	m_mcu(*this, "mcu"),
	m_irq_cb(*this),
	m_fifo_depth(fifo_depth)
{
}
ROM_START(acme_xy100)
	ROM_REGION(0x800, "mcu", 0)
	ROM_LOAD("xy100.ic1", 0x000, 0x800, NO_DUMP)
ROM_END
tiny_rom_entry const *acme_xy100_device::device_rom_region() const { return ROM_NAME(acme_xy100); }
void acme_xy100_device::device_add_mconfig(machine_config &config)
{
	I8049(config, m_mcu, DERIVED_CLOCK(1, 1));
}
```

In the public section, put the feature flags first, then constructors, configuration setters and callbacks, then live-signal handlers and any device map the host installs (D-3). A variant has its own public standard constructor that delegates to the protected one: `acme_xy101_device(…) : acme_xy100_device(mconfig, ACME_XY101, tag, owner, clock, 16)`. `device_input_ports()` returns `INPUT_PORTS_NAME(x)`. `ROM_START` is already `static`, but `INPUT_PORTS_START` defines an external function, so write `static INPUT_PORTS_START` or put it in `namespace {`; new files: 26 `static`, 21 in a namespace, 5 bare. A class that no other file names (slot cards, sub-devices) goes inside `namespace {` in the .cpp. After the namespace closes, `DEFINE_DEVICE_TYPE_PRIVATE(ACME_EXP_XY, device_acme_exp_card_interface, acme_xy_card_device, "acme_exp_xy", "Acme XY card")` registers it, and the header holds only `DECLARE_DEVICE_TYPE(ACME_EXP_XY, device_acme_exp_card_interface)` (F-4, D-10).

`-listxml`, `-validate` and `-romident` construct every device through `create_device`, which calls `DeviceClass(mconfig, tag, owner, clock)`. The fourth argument must therefore be the clock. `fca00cace9e` (2026-06-03, Vas Crabb, 269 files) fixed devices that broke this: `deco_rmc3_device(…, u32 entries)` read the clock as its entry count, and NB1413M3, the C352 in `vgmplay` and `nanoreseau` were passed a variant, a divider or an ID where the clock goes. The same commit removed defaults from protected constructors ("error-prone and leads to bugs"; `nanoreseau` silently lost its `no_id`). It also removed `clock = 0` from devices that need a clock and from slots that clock their cards ("If you're disabling a device by setting the clock to zero … you should be explicit about that"). Clock-less devices keep `u32 clock = 0`. `mame -validate` with no pattern builds every type with clock 0 and checks that short names are at most 32 characters of `[a-z0-9_]`, that short and full names are unique, and that each device reports the type it was built as. `-validate <pattern>` checks only the matching systems and skips these device-type checks.

**Legacy forms**: `const device_type FOO = device_creator<foo_device>;` (gone in `0f0d39ef815`, 2017-05-07); `machine_config_constructor device_mconfig_additions()` with `MACHINE_CONFIG_FRAGMENT` (gone in `89524dd10e3`, 2017-05-22); protected `(…, u32 clock = 0)` / `(…, int variant = 0)` constructors; the `// device-level overrides` label (54 files added in the last year still use it, against 64 with `// device_t implementation` — D-3 rejects it); overrides without `ATTR_COLD` (12 new files, against 357 with it — D-2); a card class in a header that only its own .cpp includes (F-4).
**Since**: `0f0d39ef815` (2017-05-07, type macros); `57fd28d36a0` (2018-04-28, `_PRIVATE`); `fca00cace9e` (2026-06-03, constructor rules — mame-review D-5 has the clock default but not the protected-default or fourth-argument clauses)
**Evidence**: [T1] `src/emu/device.h` `create_device`, `DEFINE_DEVICE_TYPE` Doxygen (short-name limits, global uniqueness), `DEFINE_DEVICE_TYPE_PRIVATE` `static_assert(std::is_convertible_v<Class &, Base &>)`; [T1] `src/emu/validity.cpp` `validate_device_types`; [T2] `commandline-all.rst` § -validate; [T2] mame-review D-2, D-3, D-4, D-5, F-4, N-3; [T3] the `fca00cace9e` message; [T5] new files: 258 `DEFINE_DEVICE_TYPE`, 56 `_PRIVATE`
**Key symbols**: `DECLARE_DEVICE_TYPE`, `DEFINE_DEVICE_TYPE`, `DEFINE_DEVICE_TYPE_PRIVATE`, `create_device`, `validate_device_types`, `feature_type`, `imperfect_features`, `unemulated_features`, `emulation_flags`, `device_rom_region`, `device_add_mconfig`, `device_input_ports`, `DERIVED_CLOCK`

### Slots and card lists

**Do**
```cpp
class acme_exp_slot_device : public device_t, public device_single_card_slot_interface<device_acme_exp_card_interface>
{
public:
	template <typename T>
	acme_exp_slot_device(machine_config const &mconfig, char const *tag, device_t *owner, u32 clock, T &&opts, char const *dflt, bool fixed = false) :
		acme_exp_slot_device(mconfig, tag, owner, clock)
	{
		set_options(std::forward<T>(opts), dflt, fixed);
	}
	acme_exp_slot_device(machine_config const &mconfig, char const *tag, device_t *owner, u32 clock);
	// protected: device_t implementation
};
// host; cards.h declares void acme_exp_cards(device_slot_interface &device) ATTR_COLD;
ACME_EXP_SLOT(config, "exp", 16_MHz_XTAL / 4, acme_exp_cards, nullptr);
```

The card list calls `device.option_add("name", TYPE)`. A slot that supplies no clock leaves `clock` out and delegates with `0` (`rs232_port_device`). A slot that passes its input clock on delegates with `DERIVED_CLOCK(1, 1)` (`zorro2_slot_device`).

**Legacy forms**: `option_reset(); opts(*this); set_default_option(dflt); set_fixed(false);` — still in a few slot headers, including `bus/zbi/zbi.h` (added 2026-08, after the change) and `bus/xerox820/dbslot.h`; `SLOT_INTERFACE_START` … `SLOT_INTERFACE_END`, removed in `32a73f450da` (2018-05-04).
**Since**: `237d736a310` (2026-03-22, Vas Crabb)
**Evidence**: [T1] `src/emu/dislot.h` `set_options` Doxygen; [T5] 261 `set_options(std::forward` calls in `src/devices`
**Key symbols**: `set_options`, `device_single_card_slot_interface`, `option_add`

### Driver state class

**Do**
```cpp
namespace {
class acme_state : public driver_device
{
public:
	acme_state(machine_config const &mconfig, device_type type, char const *tag) :
		driver_device(mconfig, type, tag),
		m_maincpu(*this, "maincpu")
	{ }
	void acme(machine_config &config) ATTR_COLD;

protected:
	virtual void machine_start() override ATTR_COLD;
	virtual void machine_reset() override ATTR_COLD;
	required_device<z80_device> m_maincpu;

private:
	void mem_map(address_map &map) ATTR_COLD;
	u8 m_latch = 0;
};

// member definitions, INPUT_PORTS_START(acme), ROM_START(acme)
} // anonymous namespace

SYST(1984, acme, 0, 0, acme, acme, acme_state, empty_init, "Acme", "Acme 1", MACHINE_NOT_WORKING)
```

`driver_device::device_start` waits for every child, runs `init_*`, then calls `machine_start`, `sound_start` and `video_start`. `device_reset_after_children` calls `machine_reset`, `sound_reset` and `video_reset`. An override in a derived state class calls the base (C-3). Because the constructor is inline, in-class initialisers are allowed (the D-5 exception).

**Legacy forms**: state classes that override `device_start()` and call `driver_device::device_start()`, or that override `device_reset_after_children()`. These no longer compile; `5ccf74d3c1f` rewrote the ones in coco, zaurus, softbox and jornada. `driver_start()`/`driver_reset()` (removed in `f11e04e317d`). `DECLARE_MACHINE_START`/`MACHINE_START_MEMBER`/`MCFG_MACHINE_START_OVERRIDE` and their `MACHINE_RESET`/`VIDEO_START` forms are still in `driver.h` (D-11): 89 files use the member macros and 58 the override macro, but none of the 157 state-class files added in the last year does.
**Since**: `5ccf74d3c1f` (2026-05-24, Vas Crabb: "too much opportunity for confusion if these are overridden further down the tree"); `f11e04e317d` (2026-09-24: "leftovers from the pre-device world"); both postdate mame-review
**Evidence**: [T1] `src/emu/driver.h` `override final`; [T2] mame-review D-11, C-3, F-4; [T5] 153 of the 157 new files open `namespace {`. Deviation: `device_reset()` is not final, and 7 state classes override it. `apple/maccatalyst.cpp` and `apple/macpdm.cpp` (arbee) do so to act before the children reset; otherwise use `machine_reset`.
**Key symbols**: `driver_device`, `machine_start`, `machine_reset`, `video_start`, `sound_start`, `video_reset`, `sound_reset`, `empty_init`, `SYST`

## Superseded

- State-class `device_start`/`device_reset_after_children` overrides → `machine_start`/`machine_reset` (`5ccf74d3c1f`); `driver_start`/`driver_reset` → the same (`f11e04e317d`); slot `option_reset(); opts(*this); …` → `set_options` (`237d736a310`).

## Examples

- `src/devices/bus/a2kbd/kb200.cpp` @ `f4f6f34f2a8` (Vas Crabb) — a private card in `namespace {`, with the `device_add_mconfig`, `device_rom_region` and `device_input_ports` overrides, registered by `DEFINE_DEVICE_TYPE_PRIVATE`. Deviations: its maps lack `ATTR_COLD` (D-2), and `static INPUT_PORTS_START` inside the namespace is redundant (F-4 Nit).
- `src/mame/altos/altos8000.cpp` @ `98eecf09f82` (AJR) — a state class with an inline constructor and `machine_start`/`machine_reset`, and slots filled from card lists (`RS232_PORT(config, "cons", default_rs232_devices, "terminal")`). Deviation: `static` tables inside the namespace (F-4 Nit).
