# Input ports

Writing `INPUT_PORTS_START` blocks (`src/emu/ioport.h`, `src/emu/inpttype.h`) and the code that reads them. mame-review rules that govern it: I-1 (input types, matrix reads), I-2 (DIP switches), I-3 (keyboards), I-4 (the system macro that names the block), C-1 (side effects in reads), D-1 (port finders).

## TL;DR

- Name port-field callbacks with `FUNC()`: `PORT_CUSTOM_MEMBER(FUNC(cls::fn))`, `PORT_READ_LINE_DEVICE_MEMBER("screen", FUNC(screen_device::vblank))`, `PORT_CHANGED_MEMBER(DEVICE_SELF, FUNC(cls::fn), param)`. A custom input is a plain `ioport_value fn()` with no side effects.
- Use the current types: `IPT_TILT`, `IPT_DOOR` (with `PORT_TOGGLE`), `IPT_SERVICE1`. Don't write `PORT_OPTIONAL`, `PORT_ROTATED`, `PORT_VBLANK` or `PORT_RESET`.
- Write coinage as `DEF_STR( 1C_10C )`/`10C_1C`/`1C_20C`/`1C_25C`/`1C_50C`/`1C_100C`, never as the literal text. `PORT_DIPLOCATION` needs a switch name and numbers from 1.
- Name musical-keyboard keys with `PORT_GM_C4`… or `PORT_GM_NOTE(n)`. In natural-keyboard keys, `PORT_CHAR()` skips a shift state and `PORT_CHAR(0)` is NUL.
- Read ports through `required_ioport`/`_array` finders or `.portr(m_port)`. A matrix read ANDs together every selected row (I-1), and ports can be read from `machine_reset()` on, but not in `machine_start()`.

## Rules

### Port-field callbacks

**Do**

```cpp
	ioport_value dsw_r() { return m_dsw_latch; }      // public: the port block calls it
	int hopper_r() { return m_hopper_out; }           // read-line: only bit 0 is used
	DECLARE_INPUT_CHANGED_MEMBER(coin_inserted) { m_maincpu->set_input_line(INPUT_LINE_NMI, newval ? ASSERT_LINE : CLEAR_LINE); }

INPUT_PORTS_START( mysys )
	PORT_START("IN0")
	PORT_BIT( 0x01, IP_ACTIVE_HIGH, IPT_COIN1 )  PORT_CHANGED_MEMBER(DEVICE_SELF, FUNC(mysys_state::coin_inserted), 0)
	PORT_BIT( 0x02, IP_ACTIVE_LOW,  IPT_CUSTOM ) PORT_READ_LINE_MEMBER(FUNC(mysys_state::hopper_r))
	PORT_BIT( 0x04, IP_ACTIVE_HIGH, IPT_CUSTOM ) PORT_READ_LINE_DEVICE_MEMBER("screen", FUNC(screen_device::vblank))
	PORT_BIT( 0xf8, IP_ACTIVE_HIGH, IPT_CUSTOM ) PORT_CUSTOM_MEMBER(FUNC(mysys_state::dsw_r))   // value is shifted into the mask
INPUT_PORTS_END
```

The block goes in the INPUT column of the system macro (I-4), or a device returns it from `ioport_constructor device_input_ports() const override` as `INPUT_PORTS_NAME(mydev)`. `IPT_OUTPUT` bits with `PORT_WRITE_LINE_MEMBER` / `PORT_WRITE_LINE_DEVICE_MEMBER` route a CPU port's output callback to a device line (`src/mame/casio/ctk2000.cpp`). The core reads every port once per frame (`ioport_manager::frame_update`), so a custom or read-line function must change nothing. Vas Crabb's revert `571f3d4b723` (2026-05-15) says "If a custom input member has side effects, it's broken. Use a read callback of some kind… instead." That is stricter than C-1, which allows a side effect guarded by `side_effects_disabled()`. `INPUT_CHANGED_MEMBER` handlers are input events, not reads, so they may change state.

**Legacy forms**: `PORT_CUSTOM_MEMBER(cls, fn)`, `PORT_READ_LINE_DEVICE_MEMBER("tag", cls, fn)`, `PORT_CHANGED_MEMBER(DEVICE_SELF, cls, fn, 0)`, `PORT_CROSSHAIR_MAPPER(fn)`. These took separate class and member arguments, and they stopped compiling at `5f4e3730d9d` (2024-10-18, Vas Crabb, 927 files). `CUSTOM_INPUT_MEMBER(fn)`/`DECLARE_CUSTOM_INPUT_MEMBER(fn)` became a plain `ioport_value fn()` in `dc26fcd1bb2` (2024-09-16). `PORT_VBLANK("screen")`/`PORT_HBLANK` were removed in `076147c601a` (2024-12-04) and are spelled out as above.
**Since**: `5f4e3730d9d` (2024-10-18)
**Evidence**: [T1] `src/emu/ioport.h` `PORT_*_MEMBER_IMPL(_device, _funcptr, _name)` and `ioport_field_read_delegate = device_delegate<ioport_value ()>`; [T1] `src/emu/ioport.cpp` `frame_update()` calls `port->read()` for every port; [T3] `571f3d4b723`; [T2] mame-review C-1; [T5] files added in the last year: `PORT_CHANGED_MEMBER` in 36, `PORT_READ_LINE_*MEMBER` in 22, all with `FUNC()`
**Key symbols**: `PORT_CUSTOM_MEMBER`, `PORT_CUSTOM_DEVICE_MEMBER`, `PORT_READ_LINE_MEMBER`, `PORT_READ_LINE_DEVICE_MEMBER`, `PORT_CHANGED_MEMBER`, `PORT_WRITE_LINE_MEMBER`, `PORT_CROSSHAIR_MAPPER_MEMBER`, `INPUT_CHANGED_MEMBER`, `DECLARE_INPUT_CHANGED_MEMBER`, `device_input_ports`, `INPUT_PORTS_NAME`

### Input types and field flags

**Do**

```cpp
	PORT_START("IN1")
	PORT_BIT( 0x01, IP_ACTIVE_LOW, IPT_COIN1 ) PORT_IMPULSE(2)
	PORT_BIT( 0x02, IP_ACTIVE_LOW, IPT_SERVICE1 )           // attendant/reserve key
	PORT_BIT( 0x04, IP_ACTIVE_LOW, IPT_GAMBLE_KEYIN )
	PORT_BIT( 0x08, IP_ACTIVE_LOW, IPT_GAMBLE_BOOK )
	PORT_BIT( 0x10, IP_ACTIVE_LOW, IPT_DOOR ) PORT_TOGGLE   // doors latch
	PORT_BIT( 0x20, IP_ACTIVE_LOW, IPT_TILT )
	PORT_BIT( 0xc0, IP_ACTIVE_LOW, IPT_UNUSED )
```

I-1 covers which type to choose. This rule only tracks the types that changed. Several doors share `IPT_DOOR` and are told apart by `PORT_NAME("Main door")`, `PORT_NAME("Cashbox door")` and so on (`src/mame/acorn/aristmk5.cpp`).

**Legacy forms**: `IPT_TILT1`…`IPT_TILT4` became `IPT_TILT`, and `IPT_GAMBLE_DOOR`/`IPT_INTERLOCK` became `IPT_DOOR`, in `879bcb8b8cb` (2026-02-03, hap, 54 files). `IPT_GAMBLE_SERVICE` became `IPT_SERVICE1` in `237d736a310` (2026-03-22). `PORT_OPTIONAL` was removed in `20a61a456e9` (2025-09-22) as "poorly defined". `PORT_ROTATED` was removed in `bd303b15dcf` (2025-09-25). `PORT_RESET` on relative analog fields is `[[deprecated("… manage counter state explicitly")]]` (`c378ea08709`, 2021-11-25) and is still used in `src/devices/bus/coleco/controller/sac.cpp`.
**Since**: `879bcb8b8cb` (2026-02-03)
**Evidence**: [T1] `src/emu/inpttype.h` (no `IPT_TILT1`, `IPT_GAMBLE_DOOR`, `IPT_INTERLOCK` or `IPT_GAMBLE_SERVICE`); [T1] `src/emu/ioport.h` `field_set_analog_reset` `[[deprecated]]`; [T1] `src/emu/validity.cpp` rejects `IPT_INVALID` ("use IPT_OTHER instead") and UI types in drivers; [T2] mame-review I-1
**Key symbols**: `IPT_TILT`, `IPT_DOOR`, `IPT_SERVICE1`, `IPT_GAMBLE_KEYIN`, `IPT_GAMBLE_BOOK`, `IPT_CUSTOM`, `IPT_OUTPUT`, `PORT_TOGGLE`, `PORT_IMPULSE`, `PORT_RESET`

### DIP switches and coinage

**Do**

```cpp
	PORT_START("DSW1")
	PORT_DIPNAME( 0x03, 0x03, DEF_STR( Coin_A ) )        PORT_DIPLOCATION("SW1:1,2")
	PORT_DIPSETTING(    0x00, DEF_STR( 2C_1C ) )
	PORT_DIPSETTING(    0x03, DEF_STR( 1C_1C ) )
	PORT_DIPSETTING(    0x02, DEF_STR( 1C_10C ) )
	PORT_DIPSETTING(    0x01, DEF_STR( 1C_100C ) )
	PORT_DIPUNKNOWN_DIPLOC( 0x04, 0x04, "SW1:3" )
	PORT_SERVICE_DIPLOC(    0x08, IP_ACTIVE_LOW, "SW1:4" )
	PORT_DIPNAME( 0x10, 0x10, DEF_STR( Demo_Sounds ) )   PORT_DIPLOCATION("SW1:!5")   // ! = active high
	PORT_DIPSETTING(    0x00, DEF_STR( Off ) )
	PORT_DIPSETTING(    0x10, DEF_STR( On ) )
```

Naming, ordering and `Unknown`/`Unused` follow I-2. The coinage strings run from `10C_1C` to `1C_100C`. Ratios that are commented out in `ioport.h`, such as `1C_15C`, stay literal. `-validate` fails a literal that matches a default string ("Must use DEF_STR"). It also fails a location with an empty switch name or a number below 1, or one whose switch count doesn't match the mask's bits.

**Legacy forms**: `"1 Coin/10 Credits"`, `"10 Coins/1 Credit"` and `"1 Coin/100 Credits"` as literals, replaced in 87 files by `0fb8763322f` (2025-07-07, hap). `PORT_DIPLOCATION(":1")` or `"SW1:0"` passed validation before `fc41ef0c9a7` (2024-10-05, Vas Crabb).
**Since**: `0fb8763322f` (2025-07-07)
**Evidence**: [T1] `src/emu/ioport.h` `input_string_index` (`__input_string_coinage_start`…`_end`); [T1] `src/emu/ioport.cpp` `ioport_field::expand_diplocation`; [T1] `src/emu/validity.cpp` `get_defstr_index`; [T2] mame-review I-2; [T5] 36 of the 52 files added in the last year that have `PORT_DIPNAME` also use `PORT_DIPLOCATION`
**Key symbols**: `DEF_STR`, `INPUT_STRING_1C_10C`, `INPUT_STRING_10C_1C`, `INPUT_STRING_1C_100C`, `PORT_DIPLOCATION`, `PORT_DIPUNKNOWN_DIPLOC`, `PORT_SERVICE_DIPLOC`, `PORT_CONFNAME`, `PORT_CONFSETTING`

### Musical and natural keyboards

**Do**

```cpp
	PORT_START("KO1")   // synth key matrix
	PORT_BIT( 0x01, IP_ACTIVE_LOW, IPT_OTHER ) PORT_GM_C4        // named "C4" automatically
	PORT_BIT( 0x02, IP_ACTIVE_LOW, IPT_OTHER ) PORT_GM_CS4       // "C4#"
	PORT_BIT( 0x04, IP_ACTIVE_LOW, IPT_OTHER ) PORT_GM_NOTE(62)  // D4, MIDI note number

	PORT_START("ROW0")  // computer keyboard
	PORT_BIT( 0x01, IP_ACTIVE_LOW, IPT_KEYBOARD ) PORT_CODE(KEYCODE_E) PORT_CHAR('E') PORT_CHAR() PORT_CHAR(0x05)    // nothing on Shift
	PORT_BIT( 0x02, IP_ACTIVE_LOW, IPT_KEYBOARD ) PORT_CODE(KEYCODE_2) PORT_CHAR('2') PORT_CHAR('@') PORT_CHAR(0)    // Ctrl-@ is NUL
	PORT_BIT( 0x04, IP_ACTIVE_LOW, IPT_KEYBOARD ) PORT_CODE(KEYCODE_LSHIFT) PORT_CODE(KEYCODE_RSHIFT) PORT_CHAR(UCHAR_SHIFT_1)
	PORT_BIT( 0x08, IP_ACTIVE_LOW, IPT_KEYBOARD ) PORT_CODE(KEYCODE_LCONTROL) PORT_CHAR(UCHAR_SHIFT_2)          // named "Ctrl"
```

`PORT_GM_*` only sets the field name, from `A0` (note 21) to `C8` (note 108), and the full MIDI range is available through `PORT_GM_NOTE`. Each `PORT_CHAR` fills the next shift state: unshifted, then `UCHAR_SHIFT_1`, then `UCHAR_SHIFT_2`. Key types, keycodes and character spelling follow I-3.

**Legacy forms**: `PORT_NAME("C4")` / `PORT_NAME("F3#")` per key, replaced in `ded2280e3fc` (2024-10-04, O. Galibert). Code from before `43d61833e4a` (2024-12-04, AJR) wrote no shifted entry at all or a dummy code, because `PORT_CHAR()` was illegal and `0` was reserved. `PORT_NAME(u_UMLAUT " " U_UMLAUT)` and similar accented-letter macros became `u8"ü Ü"` in `66103142647` (2023-12-22, hap). `UTF8_LEFT`/`UTF8_UP`/… still exist in `src/lib/util/utf8.h` (64 files), while I-3 prefers `u8"↑" // ↑`.
**Since**: `ded2280e3fc` (2024-10-04); `43d61833e4a` (2024-12-04)
**Evidence**: [T1] `src/emu/ioport.h` `PORT_GM_A0`…`PORT_GM_C8` and comments marking the 49-, 61-, 76- and 88-key ranges; [T1] `src/emu/ioport.cpp` `field_add_char`, `input_gm_notes_names`; [T2] mame-review I-3; [T5] 13 of the 17 files that use `PORT_GM_*` put it on `IPT_OTHER`. The two BBC userport cards use `IPT_KEYBOARD` plus a `PORT_CODE`, so the keys can be played from the PC keyboard, and `ensoniq/esq1.cpp` also uses `IPT_KEYBOARD`. `ensoniq/esqpanel.cpp` uses `IPT_PADDLE` for velocity-sensitive keys
**Key symbols**: `PORT_GM_NOTE`, `PORT_GM_C4`, `PORT_CHAR`, `UCHAR_SHIFT_1`, `UCHAR_SHIFT_2`, `UCHAR_MAMEKEY`

### Reading ports from code

**Do**

```cpp
	required_ioport_array<8> m_keys;   // m_keys(*this, "ROW%u", 0U)
	required_ioport m_dsw;
void mysys_state::io_map(address_map &map)
{
	map(0x00, 0x00).portr(m_dsw);
	map(0x01, 0x01).r(FUNC(mysys_state::keys_r));
}

u8 mysys_state::keys_r()
{
	u8 data = 0xff;
	for (unsigned i = 0; i < m_keys.size(); i++)
		if (!BIT(m_kbd_select, i))     // every selected row, not just the first
			data &= m_keys[i]->read();
	return data;
}
```

Finders follow D-1 and [object-finders](object-finders.md). `ioport_port::read()` throws "Input ports cannot be read at init time!" until settings have loaded, which happens after `machine_start()`. So read configuration ports in `machine_reset()` or in handlers. To hand a port to a device callback, use `set_ioport(m_port)`, or `set_ioport("TAG")` when nothing else uses the port.

**Legacy forms**: `ioport("IN0")->read()` in handlers (D-1); `.portr("IN0")` (accepted, and still in 1120 files against 24 that use the finder form added in `471b1261c1c`, 2024-10-13); a `switch` on the select value that returns one row (I-1).
**Since**: established; `.portr(finder)` since `471b1261c1c`
**Evidence**: [T1] `src/emu/addrmap.h` `portr(ioport_finder<req> &)`; [T1] `src/emu/ioport.cpp` `ioport_port::read` `safe_to_read()`; [T2] mame-review I-1, D-1; [T5] new files use `required_ioport` in 110 files and `.portr(m_…)` in none
**Key symbols**: `required_ioport`, `required_ioport_array`, `portr`, `set_ioport`, `safe_to_read`

## Superseded

Each rule's **Legacy forms** lists the removals with their hashes: class-and-member port callbacks (`5f4e3730d9d`), `CUSTOM_INPUT_MEMBER` (`dc26fcd1bb2`), `PORT_VBLANK`/`PORT_HBLANK` (`076147c601a`), `PORT_OPTIONAL` (`20a61a456e9`), `PORT_ROTATED` (`bd303b15dcf`), `IPT_TILT1..4`/`IPT_GAMBLE_DOOR`/`IPT_INTERLOCK` (`879bcb8b8cb`), `IPT_GAMBLE_SERVICE` (`237d736a310`).

## Examples

- `src/mame/casio/sk1.cpp` @ `f11e04e317d` — Vas Crabb's file: `PORT_GM_*` on a key matrix, `PORT_CUSTOM_MEMBER(FUNC(…))` on plain `ioport_value` members, and templated `PORT_CHANGED_MEMBER` handlers that turn slide switches into keys. Deviation: it is a skeleton with no CPU, so nothing reads the matrix.
- `src/mame/videogames/video21.cpp` @ `774a180df2b` — hap's gambling driver: `IPT_DOOR`, `IPT_GAMBLE_*`, `DEF_STR( 1C_10C )`, `PORT_READ_LINE_MEMBER` and the spelled-out vblank read, with `.portr("IN41")` in the map. Deviations from I-2: unknown switches are named `"41b0"` and not `DEF_STR( Unknown )`, no `PORT_DIPLOCATION`, and coinage is listed most generous first.
