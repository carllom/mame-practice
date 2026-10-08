# Object finders

Reaching devices, I/O ports, ROM regions, memory shares, banks and outputs through finder members (`src/emu/devfind.h`, `src/emu/output.ipp`). mame-review rules that govern it: D-1 (the finder rule), D-10 (devices reach outside only through configurable finders), D-8 (indexed finder arrays).

## TL;DR

- Make every device, port, region, share, bank and output the class uses a finder member, initialised in the constructor with `(*this, "tag")` or `(*this, "FMT%u", start)`. Handlers dereference the finders and never look up tags (D-1).
- Create devices through their finder, as in `Z80(config, m_maincpu, …)`. When nothing outside configuration needs the device, write `auto &x(DEVICE(config, "tag", …))` and add no member.
- In a device whose target lives outside it, construct the finder with `finder_base::DUMMY_TAG` and add a `template <typename T>` setter. The host passes its own finder to that setter (D-10).
- Declare output finders, initialise them and assign to them. They have resolved themselves since `f4f6f34f2a8` (2026-06-02), and `resolve()` no longer exists.
- During configuration, reach a finder's target with `m_x.lookup()`. Wiring that must exist before any `device_start` goes in `device_resolve_objects()`.

## Rules

### Declare and initialise finders

**Do**

```cpp
mysys_state(machine_config const &mconfig, device_type type, char const *tag) :
	driver_device(mconfig, type, tag),
	m_maincpu(*this, "maincpu"),
	m_ppi(*this, "ppi%u", 0U),
	m_dsw(*this, "DSW%u", 1U),            // DSW1, DSW2; still indexed [0], [1]
	m_rom(*this, "maincpu"),
	m_vram(*this, "vram"),
	m_cram(*this, "cram", 0x400, ENDIANNESS_LITTLE),
	m_rombank(*this, "rombank")
{ }
required_device<z80_device> m_maincpu;
required_device_array<i8255_device, 2> m_ppi;
required_ioport_array<2> m_dsw;
required_region_ptr<u8> m_rom;
required_shared_ptr<u8> m_vram;            // RAM declared in the map with .share(m_vram)
memory_share_creator<u8> m_cram;           // finds the share, or creates it at this size
memory_bank_creator m_rombank;             // or required_memory_bank if the map declares it
```

Finders are resolved before any `device_start` or `machine_start`, so from then on they work like pointers (`m_dsw[0]->read()`, `m_rom[addr]`, `m_rombank->set_entry(n)`). You can also format array tags with `%X` or `%c`, or give a brace list of tags. Extra constructor arguments go after the start index and apply to every element. Finders don't copy their tags, so pass literals. Use `optional_*` with `found()` / `read_safe(def)` only for hardware that is really optional (D-1).

**Legacy forms**: `ioport("IN0")->read()`, `membank("bank1")->set_entry(n)`, `memregion("gfx1")->base()`, `memshare("x")->ptr()` and `subdevice<T>("x")` called in handlers. D-1 allows these as one-time lookups in start or init, and new code still does that (`memregion("maincpu")->base()` in `src/devices/bus/qbus/bk_altpro.cpp`). `machine().device<T>(":maincpu")` has been `[[deprecated]]` since `09ed2579253` (2018-05-20). A `switch` over numbered tags should be a finder array (D-8).
**Since**: established. Finders have been resolved before `device_start` since `d5ac7c11cfd` (2017-10-28).
**Evidence**: [T2] `object_finders.rst` § Finding resources, § Object finder arrays; [T1] `src/emu/machine.h` `device<>` is `[[deprecated("absolute tag lookup; use subdevice or finder instead")]]`; [T2] mame-review D-1, D-8; [T5] among the 555 files added in the last year that still exist on master, `required_device<` appears in 120 files and `ioport("` / `membank("` / `machine().device<` in none. One deviation: `src/devices/bus/pc98_cbus/fdd_2dd.cpp` calls `m_fdc->subdevice<floppy_connector>("0")` inside `ctrl_w`.
**Key symbols**: `required_device`, `optional_device`, `required_device_array`, `required_ioport`, `required_ioport_array`, `required_region_ptr`, `required_shared_ptr`, `memory_share_creator`, `required_memory_bank`, `memory_bank_creator`, `found`, `read_safe`

### Use finders in machine configuration and address maps

**Do**

```cpp
void mysys_state::mysys(machine_config &config)
{
	Z80(config, m_maincpu, 4_MHz_XTAL);

	I8255(config, m_ppi[0]);
	m_ppi[0]->in_pa_callback().set_ioport(m_dsw[0]);

	auto &ppi2(I8255(config, "ppi2"));     // no member: nothing outside config touches it
	ppi2.in_pb_callback().set_ioport(m_dsw[1]);
}

void mysys_state::mem_map(address_map &map)
{
	map(0x4000, 0x7fff).bankr(m_rombank);
	map(0x8000, 0x87ff).ram().share(m_vram);
}
```

A device-type call returns `DeviceClass &`. Once you pass `m_x` to that call, `m_x->` works for the rest of the same configuration function, as long as the finder's base is `this`. Its address-map overloads assert that the finder belongs to the map's device. Configure banks in start, for example `m_rombank->configure_entries(0, 4, &m_rom[0x10000], 0x4000)`.

**Legacy forms**: `MCFG_DEVICE_ADD("maincpu", Z80, XTAL)` and `MCFG_*` setters, removed in `b6ce2e16d86` (2019-07-02); `.share("vram")`, `.bankr("bank1")` and `.set("tag", FUNC(…))` with string tags (D-1); `config.device_remove()` in place of a derived configuration (D-1).
**Since**: established
**Evidence**: [T2] `object_finders.rst` § Finding resources (a finder is usable as a pointer in configuration only when its base is the device being configured); [T1] `src/emu/addrmap.h` `share()`/`bankr()` finder overloads `assert(&target.first == &m_devbase)`; [T5] across master, `auto &x(DEVICE(config, …))` appears 312 times and `auto &x = DEVICE(config, …)` 60 times
**Key symbols**: `finder_target`, `set_ioport`

### Point a device's finders outside itself

**Do**

```cpp
template <typename T> void set_cpu_tag(T &&tag) { m_cpu.set_tag(std::forward<T>(tag)); }
template <typename T> void set_rom_tag(T &&tag) { m_rom.set_tag(std::forward<T>(tag)); }
required_device<cpu_device> m_cpu;       // m_cpu(*this, finder_base::DUMMY_TAG)
required_region_ptr<u8> m_rom;           // m_rom(*this, finder_base::DUMMY_TAG)

// host machine configuration
MYDEV(config, m_mydev, 0);
m_mydev->set_cpu_tag(m_maincpu);     // another finder: takes its base and tag
m_mydev->set_rom_tag("gfx");         // C string: relative to the device being configured
```

`DUMMY_TAG` never resolves, so a missing setter call fails validation. Besides a C string or another finder, a device finder also accepts a device reference, often `*this`. You can add a convenience constructor that takes `T &&` and forwards it to the setter (see `h8500_intc.h`). During configuration, `m_cpu.lookup()` returns the current target before resolution.

**Legacy forms**: `static void static_set_cpu_tag(device_t &device, const char *tag)` paired with an `MCFG_` macro; an absolute `":maincpu"` or a parent `"^ram"` tag inside a device (D-10, Blocking); `isabus.first.subdevice<isa16_device>(isabus.second)` built from `finder_target()` (`src/devices/machine/i82378zb_sio.cpp`), which `m_isabus.lookup()` replaces.
**Since**: established; `lookup()` since `58fed9839ff` (2023-06-12)
**Evidence**: [T2] `object_finders.rst` § Connections between devices; [T1] `src/emu/devfind.h` `finder_base::DUMMY_TAG` ("Dummy tag always treated as not found"), `device_finder::lookup`; [T2] mame-review D-10; [T5] `finder_base::DUMMY_TAG` appears in 22 of the files added in the last year; `set_x_tag(T &&)` and `set_x(T &&tag)` setter names are about equally common (138 vs 132 on master)
**Key symbols**: `DUMMY_TAG`, `set_tag`, `lookup`, `DEVICE_SELF`

### Output finders

**Do**

```cpp
output_finder<8> m_digits;       // m_digits(*this, "digit%u", 0U)
output_finder<4, 8> m_lamps;     // m_lamps(*this, "lamp%u_%u", 0U, 0U)
output_finder<> m_led_run;       // m_led_run(*this, "led_run")

void mysys_state::lamps_w(offs_t offset, u8 data)
{
	for (unsigned i = 0; i < 8; i++)
		m_lamps[offset & 3][i] = BIT(data, i);
}
```

Since `f4f6f34f2a8`, outputs are created during object resolution, so no `resolve()` call is needed. The constructor can also take a static array of names with the same dimensions as the finder. `set_name()` / `set_names()` rename outputs during configuration, relative to the device being configured. Names aren't copied, so they must outlive resolution. Since `5193d37fa8b` (2026-06-06), names are scoped to the owning device. Validation rejects names that are empty, start with `:`, `^` or `.`, or contain characters outside printable ASCII. An assignment sends a notification only when the value changes. Reading the finder (`operator s32`) returns the current value.

**Legacy forms**: `m_leds.resolve();` in `machine_start`/`device_start`, which no longer compiles; `output().set_value("led0", x)` / `get_value`, removed in `f4f6f34f2a8`; `output().set_led_value(n, x)` and `set_lamp_value`, removed in `2beba4ce73f` (2018-05-20); device-unique name prefixes added only to avoid global name clashes.
**Since**: `e6e9ef439c2` (2017-07-29, N-dimensional finders); self-resolving since `f4f6f34f2a8`; device-scoped names since `5193d37fa8b`
**Evidence**: [T2] `object_finders.rst` § Output finders, rewritten in `cbe97600edb` (2026-06-07) to drop the `resolve()` step, the claim that names are global and the claim that targets can't change; [T1] `src/emu/output.ipp` `output_finder` has a private `findit` override and no public `resolve`; [T3] `f4f6f34f2a8` "Made output finders participate in object resolution… They no longer need to be manually resolved"
**Key symbols**: `output_finder`, `set_name`, `set_names`

### `device_resolve_objects()`

**Do**

```cpp
void mybus_slot_device::device_resolve_objects()
{
	device_mybus_card_interface *const card = get_card_device();
	if (card)
		card->set_bus(*m_bus);
}
```

MAME calls this after every finder has resolved and before any device starts. Use it for cross-device pointers and for state a peer reads in its own `device_start`. Any other work belongs in `device_start`.

**Since**: `d5ac7c11cfd` (2017-10-28)
**Evidence**: [T1] `src/emu/device.h` doc comment on `device_resolve_objects` ("called after all registered automatic object finders are resolved"); [T5] 8 of the files added in the last year override it, mostly slot-to-card wiring
**Key symbols**: `device_resolve_objects`, `get_card_device`

## Superseded

- Output finders: manual `resolve()` in start, global names and `output().set_value`/`get_value` were replaced by automatic resolution (`f4f6f34f2a8`) and device-scoped names (`5193d37fa8b`).
- `MCFG_DEVICE_ADD` and `static_set_*` tag setters were replaced by device-type calls and `set_*_tag` members; `b6ce2e16d86` (2019) finished the job.

## Examples

- `src/devices/bus/a2kbd/am100kbd.cpp` @ `d2f5ed351dd` (AJR) shows device, ioport-array and output finders on a device, with `I8039(config, m_kbdmcu, …)` and no `resolve()`. Deviation: `key_matrix_r` loops to a literal `11` where it should use `m_keys.size()`.
- `src/devices/cpu/h8500/h8500_intc.h` @ `63a8a30002f` (arbee, tidied by Vas Crabb) shows a `finder_base::DUMMY_TAG` device finder and a convenience constructor that forwards a tag-like `T &&`; the host instantiates it with `H8500_INTC(config, m_intc, *this)` in `h8510.cpp`.
