# Interrupts and devcb

Device callbacks (`devcb_*`), their binding in machine configuration, CPU input lines and interrupt vectors. mame-review rules that govern it: D-7 (the signals rule), C-9 (no `HOLD_LINE` fakes), C-10 (latches synchronise), D-10 (devices drive callbacks, not the host CPU).

## TL;DR

- Declare `devcb_write_line m_irq_cb;`, construct it `m_irq_cb(*this)` (reads also take a default value), expose `auto irq_cb() { return m_irq_cb.bind(); }`; never call `resolve()` on a devcb.
- Fire a line callback with 0/1 when the output changes; keep `ASSERT_LINE`/`CLEAR_LINE` for `set_input_line` (D-7).
- Wire in config: `.set_inputline(m_maincpu, INPUT_LINE_IRQ0)`, `.set_ioport`, `.set_constant`, `.bit(n)`, `.invert()`, `.append(...)`; merge sources with `INPUT_MERGER_*`.
- Supply vectors from `set_irq_acknowledge_callback(FUNC(...))` returning the vector from an `IRQ_CALLBACK_MEMBER`; `set_input_line_and_vector` is `[[deprecated]]`.
- Model the acknowledge: assert, then clear in the ack callback or the device's status read — not `HOLD_LINE` (C-9).

## Rules

### Declaring callbacks in a device

**Do**

```cpp
// mydev.h
	auto irq_cb() { return m_irq_cb.bind(); }
	auto in_pa_cb() { return m_in_pa_cb.bind(); }
	template <unsigned N> auto out_p_cb() { return m_out_p_cb[N].bind(); }
	void strobe_w(int state);  // input lines take int state, never bool/u8
private:
	void update_irq();
	devcb_write_line m_irq_cb;
	devcb_read8 m_in_pa_cb;
	devcb_write_line::array<4> m_out_p_cb;
	u8 m_status, m_enable;
	bool m_irq;

// mydev.cpp — constructor initialisers
	, m_irq_cb(*this)
	, m_in_pa_cb(*this, 0xff)    // value returned while unbound
	, m_out_p_cb(*this)

void mydev_device::update_irq()
{
	bool const irq = m_status & m_enable;
	if (irq != m_irq)
	{
		m_irq = irq;
		m_irq_cb(irq ? 1 : 0);
	}
}
```

Callbacks resolve themselves (they are object finders now): no `resolve()` in `device_start`, and calling an unbound one is safe — a write does nothing, a read returns the constructor's default. Accessor suffixes `_cb()`, `_callback()` and `_handler()` all occur (new files: 74 / 89 / 12); match the device family. Per D-10 a device raises `m_irq_cb`, never holds a finder to the host CPU and calls its `set_input_line`.

Optional pins: the device tests `if (!m_in_pa_cb.isunset())` and otherwise does what the chip does with the pin unwired; leave such a callback unbound (D-7). `.set_nop()` (write side only) makes `isunset()` false and replaces an earlier binding, such as one inherited from a base configuration; `.remove()` clears one.

**Legacy forms**: `m_irq_cb.resolve_safe()` / `.resolve()` / `resolve_all_safe()` in `device_start`; `isnull()`; `devcb_read8 m_cb;` built with only `(*this)`; `m_irq1_cb`, `m_irq2_cb` numbered members (D-7); `DECLARE_WRITE_LINE_MEMBER(foo_w)` / `WRITE_LINE_MEMBER` (removed `9f661e567c4`, 2023-05-31); devcb2 `template <class Object> devcb_base &set_irq_callback(Object &&cb)` and `MCFG_*_CB(WRITELINE(...))`; `m_irq_cb(ASSERT_LINE)` (still in 11 files added in the last year — deviation from D-7).
**Since**: `c3fb11c2c98` (2018-07-07, devcb3, `bind()`); `601034c8d71` (2020-02-05, `::array<N>`); `e9c1f4a42a6` (2023-06-17, no `resolve()`, read defaults required, `isnull()` → `isunset()`)
**Evidence**: [T1] `src/emu/devcb.h` — `devcb_read::findit`/`devcb_write::findit` install the default when nothing is bound; `isunset()`; `binder::set_nop()` installs a `nop_creator`; [T3] `e9c1f4a42a6` (Vas Crabb); [T2] mame-review D-7, D-10; [T5] remaining `.resolve()`/`.resolve_safe()` calls in new files are all on `device_delegate`s, not devcb
**Key symbols**: `devcb_write_line`, `devcb_read_line`, `devcb_read8`, `devcb_write8`, `devcb_write16`, `bind`, `findit`, `isunset`, `set_nop`, `remove`

### Binding in machine configuration

**Do**

```cpp
	PIC8259(config, m_pic);
	m_pic->out_int_callback().set_inputline(m_maincpu, 0);
	I8255(config, m_ppi);
	m_ppi->in_pa_callback().set_ioport("DSW");
	m_ppi->in_pb_callback().set_constant(0xff);
	m_ppi->out_pc_callback().set(m_earom, FUNC(er1400_device::data_w)).bit(6).invert();
	m_ppi->out_pc_callback().append(m_irqs, FUNC(input_merger_device::in_w<1>)).bit(7);
```

`.set_inputline(cpu, line)` passes the 0/1 value as the line state. The three-argument form `.set_inputline(cpu, line, ASSERT_LINE)` only writes that value when the input is non-zero — a set-only flip-flop that something else (an ack callback) clears. `.set_constant` is read-side only. Configuration is the only place to bind; signal writes belong in start/reset (mame-review C-3).
**Legacy forms**: trampolines like `void irq_w(int state) { m_maincpu->set_input_line(0, state ? ASSERT_LINE : CLEAR_LINE); }`; empty lambdas `.set([] (int state) { })` (D-7); `.set_inputline(m_maincpu, 1, HOLD_LINE)` (still added in new code: `src/mame/namco/funcube.cpp`; C-9).
**Since**: `c3fb11c2c98` (2018-07-07)
**Evidence**: [T1] `src/emu/devcb.h` — `inputline_builder` calls `exec.set_input_line(linenum, data)`; `latched_inputline_builder` only `if (data) exec.set_input_line(linenum, value)`; [T2] mame-review D-7
**Key symbols**: `set_inputline`, `set_ioport`, `set_constant`, `append`, `bit`, `invert`, `rshift`, `set_membank`, `set_output`

### CPU input lines, not `HOLD_LINE`

**Do**

```cpp
	m_maincpu->set_input_line(INPUT_LINE_NMI, ASSERT_LINE);   // later CLEAR_LINE
	m_subcpu->set_input_line(INPUT_LINE_RESET, BIT(data, 4) ? CLEAR_LINE : ASSERT_LINE);
	m_audiocpu->pulse_input_line(INPUT_LINE_NMI, attotime::zero);  // edge-triggered lines only
```

`HOLD_LINE` asserts the line and has the core clear it in `standard_irq_callback`; that only works for cores that call it, and it hides the real acknowledge (a status read, an IORQ-cleared flip-flop, an EOI). C-9 flags it. `pulse_input_line` with zero width throws `emu_fatalerror` on a level-triggered line.
**Legacy forms**: `set_input_line(0, HOLD_LINE)` (956 occurrences on master; 6 new files, mostly code split from older drivers); `set_vblank_int("screen", FUNC(x::irq0_line_hold))`, `set_periodic_int(...)`, `INTERRUPT_GEN_MEMBER`, `nmi_line_pulse` (`src/emu/driver.h`; 14 new files) — replace with `screen_vblank().set_inputline(...)` or a timer, plus a real clear.
**Since**: established
**Evidence**: [T1] `src/emu/diexec.h` — `line_state`: `HOLD_LINE // hold interrupt line until acknowledged`; [T1] `src/emu/diexec.cpp` `default_irq_callback`, `pulse_input_line`; [T2] mame-review C-9; [T2] `object_finders.rst` — `set_input_line(INPUT_LINE_RESET, ... ? CLEAR_LINE : ASSERT_LINE)`
**Key symbols**: `set_input_line`, `ASSERT_LINE`, `CLEAR_LINE`, `HOLD_LINE`, `pulse_input_line`, `INPUT_LINE_NMI`, `INPUT_LINE_RESET`, `INPUT_LINE_IRQ0`

### Interrupt vectors from the acknowledge callback

**Do**

```cpp
	IRQ_CALLBACK_MEMBER(irq_ack);  // int irq_ack(device_t &device, int irqline)
IRQ_CALLBACK_MEMBER(v100_state::irq_ack)
{
	m_maincpu->set_input_line(0, CLEAR_LINE);   // INTA clears the request
	return (m_picu->a_r() << 1) | 0xf0;          // vector on the bus
}
	m_maincpu->set_irq_acknowledge_callback(FUNC(v100_state::irq_ack));
	m_picu->int_wr_callback().set_inputline(m_maincpu, 0, ASSERT_LINE);
	// or a vectoring device: set_irq_acknowledge_callback(m_pic, FUNC(pic8259_device::inta_cb))
```

Compute the vector at acknowledge time from the pending sources, so priorities and masks apply when the CPU takes it. Z80 RST vectors from discrete logic come from `RST_NEG_BUFFER`/`RST_POS_BUFFER` (`machine/rstbuf.h`, `rst28_w` + `inta_cb`). Z80 code in IM 1 needs no vector at all.
**Legacy forms**: `set_input_line_and_vector(0, HOLD_LINE, 0xd7)`, `set_input_line_vector(line, vec)` (124 occurrences left on master, none in files added in the last year); `IRQ_CALLBACK_MEMBER` that only returns a constant while the line is still `HOLD_LINE` (the mechanical form of the 2026-06 conversions, e.g. `652fbfedba8`).
**Since**: `85a96b3844f` (2026-06-29) deprecated the vector setters; `set_irq_acknowledge_callback` established (`3e73b779d0f`, 2013-01-31, delegates)
**Evidence**: [T1] `src/emu/diexec.h` — `[[deprecated("set_input_line_and_vector is deprecated; use set_irq_acknowledge_callback instead")]]`; [T3] `7d7fa772eb5` (O. Galibert, segas32: level line plus vector chosen in the ack callback); `4f52feda4c7` (saturn_scu: `HOLD_LINE` replaced by assert + clear in `irq_ack_cb` — deviation: the SCU still drives `m_hostcpu` directly instead of an IRQ devcb, D-10)
**Key symbols**: `set_irq_acknowledge_callback`, `IRQ_CALLBACK_MEMBER`, `device_irq_acknowledge_delegate`, `standard_irq_callback`, `inta_cb`, `rst_neg_buffer_device`, `set_input_line_and_vector`, `set_input_line_vector`

### Combining sources; latches

**Do**

```cpp
	INPUT_MERGER_ANY_HIGH(config, m_soundirq).output_handler().set_inputline(m_audiocpu, INPUT_LINE_IRQ0);
	m_ym2203->irq_handler().set(m_soundirq, FUNC(input_merger_device::in_w<0>));
	m_ym3526->irq_handler().set(m_soundirq, FUNC(input_merger_device::in_w<1>));

	GENERIC_LATCH_8(config, m_soundlatch).data_pending_callback().set_inputline(m_audiocpu, INPUT_LINE_NMI);
```

Two callbacks bound to one input line overwrite each other (D-7); use `INPUT_MERGER_ANY_HIGH`/`ALL_HIGH`/`ANY_LOW`/`ALL_LOW`. `in_w<N>` synchronises like the latch does (C-10); `in_r<N>` reads an input back. A latch whose pending flag is cleared by the CPU reading it needs nothing else; `set_separate_acknowledge(true)` + `acknowledge_w` when a separate write clears it.
**Legacy forms**: per-source `m_irq_a`, `m_irq_b` flags OR-ed in a driver `update_irq()` (fine when the hardware has a real register; otherwise D-8); `soundlatch_w` that writes a member and calls `set_input_line(0, HOLD_LINE)` (C-9, C-10).
**Since**: established
**Evidence**: [T1] `src/devices/machine/input_merger.h` — `in_w` posts through `scheduler().synchronize`; [T2] mame-review D-7, D-8, C-10
**Key symbols**: `input_merger_device`, `INPUT_MERGER_ANY_HIGH`, `INPUT_MERGER_ALL_HIGH`, `output_handler`, `in_w`, `data_pending_callback`, `set_separate_acknowledge`, `generic_latch_8_device`

## Superseded

- `set_input_line_and_vector` / `set_input_line_vector` — superseded by `set_irq_acknowledge_callback` in `85a96b3844f` (2026-06-29).
- `devcb.resolve()` / `resolve_safe()` / `isnull()` — superseded by self-resolving callbacks and `isunset()` in `e9c1f4a42a6` (2023-06-17).
- `(DECLARE_)WRITE_LINE_MEMBER` / `READ_LINE_MEMBER` — superseded by plain `void f(int state)` / `int f()` in `9f661e567c4` (2023-05-31).

## Examples

- `src/devices/machine/am9517a.h` @ `9a2cf2453e1` — `bind()` accessors, `template <unsigned C>` accessors over `devcb_read8::array<4>` / `devcb_write_line::array<4>`, read defaults in the `.cpp` constructor.
- `src/mame/visual/v100.cpp` @ `774a180df2b` — latched `set_inputline(..., ASSERT_LINE)` cleared in an `IRQ_CALLBACK_MEMBER` that returns the vector, `INPUT_MERGER_ALL_HIGH`, `.append(...).bit(7)`, `.bit(6).invert()`; deviation: binds the merger by tag string `"acts"` instead of a finder.
